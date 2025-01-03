;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; pckFlattenCellview.il
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun pckFlattenCellview ( cv )
  (let ( i x y newInst newCell ) 
    ;;cv = geGetEditCellView()
    ;;setof( inst cv~>instances nequal( inst~>cellName "tp0pad" ) )
    i = 0
    foreach( inst setof( fig cv~>instances nequal( fig~>cellName "tp0pad" ) )
                  printf( "%L %L %L\n" i inst~>name sprintf( nil "%s_%d" cv~>cellName i ) )
                  ;; make a new cell
                  leMakeCell( list(inst) cv~>libName sprintf( nil "%s_%d" cv~>cellName i ) "layout" nil )
                  ;;
                  ;; get into the new cell and flatten pCells
                  newCell = dbOpenCellViewByType(  cv~>libName sprintf( nil "%s_%d" cv~>cellName i ) "layout" "maskLayout" "a" )
                  newInst = car(newCell~>instances );; there should be only one !
                  dbFlattenInst( newInst 20 t )
                  dbSave( newCell )
                  dbClose( newCell )
                  ;;
                  ;; remove pCell instance and place a static cell instead
                  x  = car( car( inst~>bBox ) )
                  y  = cadr( car( inst~>bBox ) )
                  
                  dbDeleteObject( inst )
                  dbCreateInst( cv newCell nil x:y "R0" ) 
                  i = add1( i )
                  )
    dbSave( cv )
    dbClose( cv )
    )
);

(defun pckTestrowFlatten (cv daForm )
  (let (x y i newInst newCell cellName instList )
    instList = (setof inst cv~>instances (and (nequal inst~>cellName "tp0pad" ) 
                                              (rexMatchp strcat("^" daForm->cellPrefix->value)  inst~>cellName)))
    fprintf( stdout "-I- Starting pckTestrowFlatten.\n" )
    fprintf( stdout "-D- pckTestrowFlatten: Instances selected for flattening: %L\n" instList~>name )
    ;;fprintf( stdout "-D- %L %L\n" daForm->?? daForm->cellName->??)
    i=0
    foreach( inst instList
                  cellName = strcat( daForm->cellName->value sprintf(nil "%02d" i) "_f" )
                  fprintf( stdout "-D- pckTestrowFlatten: Creating a new cell %L in %L library\n" cellName daForm->libName->value )
                  leMakeCell( list(inst) daForm->libName->value cellName "layout" nil )
                  newCell = dbOpenCellViewByType( daForm->libName->value cellName "layout" "maskLayout" "a" )
                  newInst = car(newCell~>instances );; there should be only one !
                  dbFlattenInst( newInst 32 t )
                  dbSave( newCell )
                  dbClose( newCell )
                  x  = car( car( inst~>bBox ) )
                  y  = cadr( car( inst~>bBox ) )
                  
                  dbDeleteObject( inst )
                  dbCreateInst( cv newCell nil x:y "R0" ) 
                  i++
                  )
    dbSave(cv)
    )
  )



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;NAME
;;      pckMenuManTestrowFlattenForm
;;
;;SYNOPSIS
;;      pckMenuManTestrowFlattenForm()
;;
;;DESCRIPTION
;;      Creates menu to flatten manually created test rows
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun pckMenuManTestrowFlattenForm ()
  (let ( exceptionList text flattenManForm)

    (setq text ( hiCreateMLTextField
                 ?name 'text
                 ?value "This form starts a script that will flatten all instances of pCells in place\n
in this cellview (except for ones NOT to be flattened as listed below).\n
Make sure you have write access to the library.\n\n
The flow checks for pcells in the hierarchy of each top-level instance.\n
If the instance contains pcells, the top-level cell is replaced by new cell\n
in the testrow's library named <testrowName>_<InstanceName>_<cellName>.\n
The new cell will be flattened. If pcell mosiac arrays are found, the pcell\n 
master will be replaced by a uniquely named new cell in the testrow library\n 
named <testrowName>_<pcellName>_<#########>.  If edits are required, the\n 
flattened top-level instances can be replaced by the original cells, and then\n
edited.\n"
                 ?enableWordWrap t
                 ?editable nil
                 ) 
    )

    (setq exceptionList ( hiCreateStringField
                  ?name 'exceptionList
                  ?prompt "pCells NOT flattened:"
                  ?defValue "tp1padstd tp1padem"
                  ?editable t
                  ) 
    )


    ( setq flattenManForm ( hiCreateAppForm
                     ?name 'flattenManForm
                     ?formTitle "Flatten pCells in Manually Drawn Testrow"
                     ?callback list( "pckMenuManTestrowFlattenOKCB( (geGetEditCellView) flattenManForm  )" )
                     ?fields list( list( text          0:5   600:200) 
                                   list( exceptionList 0:120 600:200 130))
                     ?unmapAfterCB  t
                     ?initialSize  600:280
                     )
    )

    ( hiDisplayForm flattenManForm )
    t
    )
  )

(defun pckMenuManTestrowFlattenOKCB ( cv formHandle )
  ( let ( exceptionList )

    exceptionList = parseString( formHandle->exceptionList->value " ,") 
    (pckFlattenSynthRow cv exceptionList)

    t

) ;; let
) ;; pckMenuManTestrowFlattenOKCB

;; New function variation for flattening pCells in manually-generated testrows
;; This is needed because the PADS are NOT instances of "tp0pad" but are
;; the manually drawn pads, such as "x4padstd", "x5cpadstd", "x5cpadem", etc.
;; Therefore I need to change the code that excludes the pads.
;; WBH 10-12-2005


(defun pckManSelectInstancesWithExceptions (cv exceptions)
(progn
  (setof i  cv~>instances
		 (and (not (member i~>cellName exceptions))
			  (nequal i~>master~>HCDMesh "yes") 
			  (member (list i~>libName i~>cellName) (pckGetPcellNames cv) ))
		 )
  )
)

(defun pckGetAllInstLibs (cv)
( let ( str lastLib )

    str = ""
    lastLib = ""
    (foreach subcell (dssListHierarchyP cv~>libName cv~>cellName "layout"
                    ?switchList (list "layout")
                    ?switchLibNames (list AUX_LIB MESH_LIB MOS_LIB PAD_LIB MESHOLD_LIB)
                    ?switchLibChoice 'not)

        if( nindex( (nth 0 subcell) "label") == nil && (nth 0 subcell) != lastLib then
            lastLib = (nth 0 subcell)
            str = strcat( str (nth 0 subcell) " ")
        )

    )
    str
) ; let
)

(defun pckManTestrowFlatten (@optional (cv geGetEditCellView()) ( exceptions list("tp0pad" "tp1padstd" "tp1padem") ) )

  (let (instances)

    (pckDebug "pckManTestrowFlatten" "Flattening is now starting...")

    ;; NEW code to include only pcell instances & filter out exceptions
    instances = pckManSelectInstancesWithExceptions( cv exceptions)

    pckDebug( "pckManTestrowFlatten" (sprintf nil "Instances found: %L\n" instances))

    (while instances

	  ;;now flatten everything left over in instances

	  (mapcar 
	   (lambda (x) 
		 (dbFlattenInst x 1 t t t)
		 ) 

	   instances

	   )

	  pckDebug( "pckManTestrowFlatten" (sprintf nil "Number of unflattened pCells left: %L" (pckGetPcellNames cv)))
	  instances = pckManSelectInstancesWithExceptions( cv exceptions)
          
	  )

    (dbSave cv)
    pckDebug( "pckManTestrowFlatten" "Flattening is now completed")

	) ;; let

) ;; pckManTestrowFlatten



(defun pckGetPcellsHier (lib cell)
(let (pcells scv)
    
    (foreach subcell
			 (dssListHierarchyP lib cell "layout"
								?switchList (list "layout")
								;;?switchLibNames ( list AUX_LIB MOS_LIB MESH_LIB MESHOLD_LIB PAD_LIB )
								?switchLibChoice 'not)
         (setq scv (dbOpenCellViewByType (nth 0 subcell) (nth 1 subcell) (nth 2 subcell)))       
         (when (pckGetPcellNames scv)
             (pckInfo "pckGetPcellsHier" (sprintf nil "Subcell %s/%s contains pcells" (nth 0 subcell) (nth 1 subcell)))
             (setq pcells (cons (list (nth 0 subcell) (nth 1 subcell)) pcells))
         )       
         (dbClose scv)
    )
    pcells
)
)

(defun pckMakeLibList  (libNameString)

  (parseString libNameString " ,")

)


(defun pckFlattenPcellsHier (cellLib cell exceptionList)
(let ((pcells (pckGetPcellsHier cellLib cell)) cv copyCv)

    (foreach p pcells
         (pckInfo "pckFlattenPcellsHier" (sprintf nil "Preparing to flatten %s/%s" (nth 0 p) (nth 1 p) ))
         (setq cv (dbOpenCellViewByType (nth 0 p) (nth 1 p)  "layout" "maskLayout" "a"))
         if( cv != nil then
             copyCv = pckCopyCellWithPcells( cv (nth 0 p) strcat( (nth 1 p) "_pcells") )
             if( copyCv != nil then
                 (pckManTestrowFlatten cv exceptionList) 
             else
                 pckWarn("pckFlattenPcellsHier" 
                     sprintf( nil "Copy Failed after 20 tries - %s was NOT flattened!" (nth 0 p)) )
             )
         else
             pckWarn("pckFlattenPcellsHier" 
                 sprintf( nil "Unable to open or check out %s; it was NOT flattened!" (nth 0 p)) )

         )
         (dbSave cv)
         (dbClose cv)
    )
) ; let
)
         


(defun pckCopyCellWithPcells ( cv lib copyName )
( let ( i copyCv saveName)

    copyCv = nil
    i = 1
    saveName = copyName
    while( copyCv == nil && i < 21 ;; Allow for 20 tries
        (dbClose cv)
        copyCv = dbCopyCellView(cv lib copyName "layout" nil nil nil)
        if( copyCv != nil then
            pckInfo("pckCopyCellWithPcells" sprintf(nil "Copying %s to %s ..." cv~>cellName copyName)) 
            dbSave( copyCv)
        else
            i = i + 1
            copyName = sprintf(nil "%s%d" saveName i)
        )
    )

    copyCv

) ; let
)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Filename: pckFlattenParamInst.il             Project: TCC
;; 
;;  Version: $Id: pckFlattenFunctions.il.rca 1.1 Fri Dec 10 15:47:46 2010 pvrott Experimental $
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; Copyright Intel Corporation 2009
;;
;; Author: Bill Harris
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Functional Description:
;;
;; Instance a pCell into a separate cellview and instance that back in to original cellview
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun pckFlattenParamInst (cv cellLib cellName  orient origin params @key (newCellSuffix nil))
  (let (newCv pfCv pfInst newCellName )
    (srandom (times (stringToTime (getCurrentTime)) (ipcGetPid)))
	(if newCellSuffix then
	  (setq newCellName (get_pname (concat cv~>cellName "_" (random) "_" newCellSuffix )))
    else
	  (setq newCellName (get_pname (concat cv~>cellName "_" (random) "_tctgen" )))
    )
	(if (setq newCv (dbOpenCellViewByType  cv~>libName newCellName "layout" "maskLayout" "r"))
		(progn
		  (dbClose newCv)
		  (fprintf stdout "-E- Could not generate unique cell name"))
	    (progn
		  (setq newCv (dbOpenCellViewByType cv~>libName newCellName "layout" "maskLayout" "w"))
		  (setq pfCv (dbOpenCellViewByType cellLib cellName "layout"))
		  (setq pfInst (dbCreateParamInst newCv pfCv nil 0:0 orient 1 params ))
		  (dbFlattenInst pfInst (dbGetMaxHierDepth) t t t)
		  (dbCreateInst cv newCv nil origin orient 1)
		  (dbSave cv)
		  (dbSave newCv)
		  (dbClose newCv)
		  (dbClose pfCv)))
	t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Filename: pckFlattenSynthRow.il           Project: TCC
;; 
;;  Version: $Id: pckFlattenFunctions.il.rca 1.1 Fri Dec 10 15:47:46 2010 pvrott Experimental $
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; Copyright Intel Corporation 2004
;;
;; Author: Vincent Rayappa/ Robert Rice
;; Keywords: TCC Project, Flattening
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Functional Description: per changes by R. Rice Oct 2007
;;
;; Creates hierarchy of uniquely named static cells from pCells in Synthesized rows.
;; The generated static cells are stored  in the row library. If they contain pcell mosaics,
;; the mosaic master cell is replaced by a uniquely named static cell.
;; In scribeline rows all cells are flattened.
;; If row is not synthsized - custom - only top-level instances that contain pcells in
;; their hierarchy will be affected.  Each of these instances will be replaced by a
;; uniquely named static cell. If mosaic pcells are encountered they are replacedby
;; uniquely named static cells, otherwise the hierarchy is flattened 1 level at a time.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; (load "pckFlattenSynthRow.il")
;;
;; (pckFlattenSynthRow cv (list "tp1padstd" "tp1padem"))
;;
;; Flatten pcells only, excluding those pcells given in the exception list
;;
;; Sample Invocation: (pckFlattenSynthRow cv (list "tp0pad" "tp1padstd" "tp1padem"))
;;

(defun pckFlattenSynthRow (cv exceptions @optional (retainCellName nil))
  (let (instances bBox instName instCellName instLibName m1 subm1 newCell newCellName
				  tmpltCellName tmpltCell rowName instId)
	rowName = cv~>cellName
	
	(if cv~>createdBypck == "yes"
	
		(progn ;;row created in TCC
		  (setq instances (pckSelectInstancesWithExceptions cv exceptions))
          (foreach i instances
				   cond(
						((rexMatchp "^SL" (getq cv~>tcc_dpl "PadrowType"))
                         (dbFlattenInst i 32 t t t)
						 )                      
						( i~>cellName == "tp0pad"
									  dbFlattenInst( i 1 t t t)
									  )
                       
						(i~>instHeader~>master~>superMaster~>isParamCell ;; a pcell instance
;;; concatinate row_name_tcc_InstanceName as name of new static cell
						 (if retainCellName
						   (setq tmpltCellName i~>name)
						   (setq tmpltCellName (lowerCase strcat( rowName "_" i~>name ))))
						 (setq tmpltCell (leMakeCell list( i ) cv~>libName tmpltCellName "layout" nil ))
						 (pckSetpckGen cv~>libName tmpltCellName "layout")
						 (dbSave tmpltCell )
						 (dbClose tmpltCell )
						 (setq newCell (dbOpenCellViewByType  cv~>libName tmpltCellName "layout" "maskLayout" "a" ))
						 (pckFlattenCells newCell rowName cv~>libName )
						 (setq instId (dbCreateInst cv newCell nil car( i~>bBox ) "R0" 1 ))   
						 (dbDeleteObject i)
						 (dbSave newCell)
						 (dbClose newCell)
						 (dbSave cv)                    
						 )
						);;cond
				   );; foreach
		  );;progn
		(progn	 ;;custom row
		  (pckInfo "pckFlattenSynthRow" "row not synthesized so custom-row flattening procedure will be used.")
		  instances = (setof i cv~>instances i (not (member i~>cellName exceptions)))
		  (foreach i instances
				   (cond
					 (i~>cellName == "tp0pad"
								  (dbFlattenInst i 1 t t t)
								  )

					 ((pckCheckForPcells i~>master)	;; instance has pcell in hierarchy
					  ;; (fprintf stdout "cell %L has pcells in hierarchy\n" i~>master~>cellName)
					  (if retainCellName
						(setq tmpltCellName i~>name)
						(setq tmpltCellName (lowerCase (strcat rowName "_" i~>name "_" i~>cellName))) )
					  (setq tmpltCell (leMakeCell list( i ) cv~>libName tmpltCellName "layout" nil ))
					  (pckSetpckGen cv~>libName tmpltCellName "layout")
					  (dbSave tmpltCell )
					  (dbClose tmpltCell )
					  (setq newCell (dbOpenCellViewByType  cv~>libName tmpltCellName "layout" "maskLayout" "a" ))
					  (pckFlattenCells newCell rowName cv~>libName )
					  (setq instId (dbCreateInst cv newCell nil car( i~>bBox ) "R0" 1 ))   
					  (dbDeleteObject i)
					  (dbSave newCell)
					  (dbClose newCell)
					  (dbSave cv)                       
					  )
					 ) ;;cond		 		   		 
				   ) ;;foreach
		  )	;;progn        
		)	;;if
	t
	) ;;let
  );; defun

(defun pckSelectInstancesWithExceptions (cv exceptions)
  (if (and (pckGetCdfBaseValue cv~>libName cv~>cellName "PadrowType") 
           (rexMatchp "^SL" (pckGetCdfBaseValue cv~>libName cv~>cellName "PadrowType")))
	  (progn
		(setof i  cv~>instances (and (not (member i~>cellName exceptions))
									 (member (list i~>libName i~>cellName) (pckGetPcellNames cv) ))))                 
      (progn
		(foreach mesh (setof i cv~>instances i i~>cellName == "auxGMesh")
				 (dbFlattenInst mesh 1 t t t) )
        (setof i  cv~>instances (and (not (member i~>cellName exceptions))
                                     (nequal i~>master~>cellName "auxGMesh") 
                                     (member (list i~>libName i~>cellName) (pckGetPcellNames cv) )))
		) ))
;;
;; Figure our the various pcells that have been instanciated in this cv.
;;

(defun pckCheckForPcells (cv )
  (let (x)
	(if (pckGetVariants cv)
		t
		(progn
		  (foreach mcv cv~>instances~>master
				 x =  (pckCheckForPcells mcv))
		  x))
	
	)
  )
(defun pckGetPcellNames (cv)
  (let ((sm (setof x cv~>instHeaders~>master (and x~>isParamCell (not x~>superMaster)))))
    (mapcar (lambda (x) (list x~>libName x~>cellName)) sm)))

(defun pckUpdateFlatInstaceLabels (cv instName instBBox)
  (let (x1 y1 labelId bBox ln )
	;;
	;; Find all labels in the instance to be flattened
	;; rename them by adding instance name to their names
	;; Fit new labels into orginal bboxes by changing font height
	
	(if cv~>shapes 
		(progn 
		  (setq ln (setof x cv~>shapes 
						  (and (rexMatchp x~>objType "label") (pckFindBBoxInsideZone list(x~>bBox) instBBox))))
		  ;;(fprintf stdout "Labels in %s found: %L\n" instName ln~>theLabel)
		  (mapcar 
		   (lambda (x)
			 ;;(fprintf stdout "Processing %L\n" x~>??)
			 (bBox = x~>bBox )
			 (x~>theLabel = ( strcat x~>theLabel "_" instName ) )
			 (while pckFindBBoxInsideZone( list( x~>bBox ) bBox ) == nil
					x~>height =  (max x~>height - 0.01 0.01)
					)
			 )
		   ln
		   )
		  )
	  )
	;;
	;; Do the same for pins
	;;
	(if cv~>terminals
		(progn  
		  ;;(fprintf stdout "Terminals %L Pins %L %L\n" cv~>terminals cv~>terminals~>pins (car cv~>terminals~>pins)~>fig~>bBox)
		  (setq ln (setof x cv~>terminals (pckFindBBoxInsideZone list( (car x~>pins)~>fig~>bBox ) instBBox) ))
		  ;;(fprintf stdout "Terminals in %s found: %L\n" instName ln~>name)
		  (mapcar
		   (lambda (x)
			 ;;(fprintf stdout "Processing %L\n" x~>??)
			 (bBox = (car x~>pins)~>fig~>bBox )
			 (setq  x1 ( car ( trBBoxCenter bBox ) ) )
			 (setq  y1 ( cadr ( trBBoxCenter bBox ) ) )	  
			 ;;(fprintf stdout "Processing %L %L %L\n" bBox x1 y1)
			 (setq labelId 
				   ( dbCreateLabel cv (car x~>pins)~>fig~>lpp x1:y1 
								   (strcat x~>name "_" instName)
								   "centerCenter" "R0" "swedish" cadr( trBBoxDims( bBox ) ) ) )
			 ;;
			 ;; Then update corresponding _net_; it is impossible to do it directly 
			 ;; and we have to use merge method
			 ;; Update terminal's name to match the new label
			 ;;
			 (dbMergeNet (dbMakeNet cv (strcat x~>name "_" instName) ) (dbFindNetByName cv x~>name) )
			 x~>name = (strcat x~>name "_" instName)
			 (while (pckFindBBoxInsideZone list( labelId~>bBox ) bBox ) == nil
					labelId~>height =  (max labelId~>height - 0.01 0.01)
					)
			 )
		   ln
		   )
		  )
	  )
	t)
  )
;;***** pckFlattenCells.il
;;
;; (load "pckFlattenCells.il")
;; cv = geGetWindowCellView()
;; rowLib = "myRow"
;; pckFlattenCells( cv rowName SCRATCH_LIB)
(defun pckFlattenCells ( cv rowName rowLib)
  (let (instList topCellList category instCellList mosaicCellList cellList)
	topCellList = (list cv~>cellName)
;;; instList contains instHeader~>variants data objects
;;; the variants are unique parameter sets for a pcell
;;; <variants>~>instances = instances using the variant master
;;; <variants>~>master = instance master	
	(if instList = pckGetVariants( cv )
		(progn ;; there are pcells at this level
		  category = rowName
		  cellList = ()

		  (foreach mstr instList
				(case car(mstr~>instances~>objType) 
					   ("mosaic"
						 (when (pckCheckForPcells mstr~>master);; only pcell mosaics 
						 (pckInfo "pckFlattenCells" sprintf( nil "processing mosaic cell %L" mstr~>cellName))
						 mosaicCellList = (pckFlattenMosaics mstr rowName rowLib cellList)
						 
						 (when type(mosaicCellList) == 'list
							   mosaicCellList = append(topCellList mosaicCellList)
						 	   )))
					   ("inst"
						 (pckInfo "pckFlattenCells" sprintf( nil "processing inst cell %L" mstr~>cellName)) 
						 instCellList = pckFlattenInsts( cv rowName rowLib cellList)
						 (when type(instCellList) == 'list
							   instCellList = append( topCellList instCellList )
							   )
						 ));;case
			
				   );;foreach
		  (when type(instCellList) == 'list 
				topCellList = append( topCellList instCellList )
				)
		  (when type(mosaicCellList) == 'list
				topCellList = append( topCellList mosaicCellList)
				)
 
		  (pckAddCellsToCat rowLib category topCellList)
		  )		 
 
		(progn	  ;; no pcells at this level, so flatten cell
		  (foreach inst cv~>instances
				   (dbFlattenInst inst 1 t t t)				   
				   ) ;;foreach
	
		  (pckFlattenCells cv rowName rowLib)
		  )			 ;;progn
		)			 ;;if 
       (dbSave cv) 
	)    
  )

(defun pckFlattenInsts ( cv rowName rowLib cellList) 
  (let (newName mcv instId varList inst )
    (when cv varList = pckGetVariants(cv)) 
    (while varList
      (mapcar
	   (lambda (inst)
         (cond
           ( car(inst~>instances)~>objType == "mosaic"
                cellList = pckFlattenMosaics(inst rowName rowLib cellList)
                )
           ((rexMatchp "^aux" inst~>master~>cellName) && inst~>master~>cellName != "auxGMesh" && inst~>master~>cellName != "auxPathMesh"
			;; (fprintf stdout "flattening auxcell %L\n" inst~>master~>cellName)
            (foreach aux inst~>instances
					 dbFlattenInst( aux 32 t t t)
					 )
										
            cellList
            )
           (inst~>master~>pckDoNotFlatten == "yes"			  
										  (pckInfo "pckFlattenInsts" sprintf( nil "processing cell %L" inst~>cellName))
										  newName = pckGetUniqCellName( car(inst~>instances) rowName)
										  ;; create new cellview
										  (pckInfo "pckFlattenInsts" sprintf( nil "Creating static cell %L" newName ))
										  mcv = dbOpenCellViewByType( rowLib newName "layout" "maskLayout" "w")
										  (pckSetpckGen mcv~>libName newName "layout")
										  ;; add to cell list
										  (when !member( newName cellList)
												cellList = cons( newName cellList)
												)
										  (foreach i inst~>master~>instances
												   (dbFlattenInst i 32 t t t))
										  (foreach shape inst~>master~>shapes
												   (dbCopyFig shape mcv) )
										  (dbSave mcv)
										  (foreach i inst~>instances
												   i~>master = mcv)

										  dbClose(mcv)
										  cellList
										  )
           (t
            (dbFlattenInst (car inst~>instances) 1 t t t)										
            cellList
            )
           );;cond
		 );;lambda
	   varList);;mapcar
	  varList = pckGetVariants(cv)
      );;while  
	cellList
    );;let
  );;defun

(defun pckGetVariants ( cv )
    (let ( instList )
        (foreach var cv~>instHeaders~>variants
            (when var~>libName != SCRATCH_LIB
                instList = append( var instList)
            )    
        )
        instList
    )
)    

        
(defun pckFlattenMosaics ( inst rowName rowLib cellList)
  (let (newCell newCellName instId mosaicList )
    mosaicList = inst~>instances
	(foreach  mos mosaicList
			 
			  (pckInfo "pckFlattenMosaics" sprintf( nil "processing mosaic cell %L"  mos~>cellName ))
			  (if  mos~>cellName == "auxGMesh"
				   (progn (pckInfo "pckFlattenMosaics" sprintf( nil "flattening instance %L cell %L"  mos~>name mos~>cellName ))
						  (dbFlattenInst mos 1 t t t)
						  (dbSave inst~>cellView))
             
				   (progn
;;; get unique name for mosaic cell
					 newCellName = (pckGetUniqCellName mos rowName)
					 
					 (pckInfo "pckFlattenMosaics" sprintf( nil "created static mosiac cell %L" newCellName ))
					 newCell = (dbOpenCellViewByType rowLib newCellName "layout" "maskLayout" "w")

					 (pckSetpckGen newCell~>libName newCellName "layout")
;;; add cell name to cell list
					 (when !member( newCellName cellList)
						   cellList = (cons newCellName cellList)
						   )
			
					 (when mos~>master~>instances
			  
					   (foreach i mos~>master~>instances
								(dbFlattenInst i 31 t t t))
					   )

					 (foreach shape mos~>master~>shapes
							  (dbCopyFig shape newCell))
			
					 (pckInfo "pckFlattenMosaics" sprintf( nil "replacing mosaic %L with %L" mos~>master~>cellName newCell~>cellName))
					 (dbSave newCell)
					 mos~>master = newCell
					 (dbSave mos~>cellView)
					 ( dbClose newCell)

					 cellList     )	;;progn
                   
				   ) ;;if 
			  cellList
			  )	
    cellList
	)    
  )
(defun pckGetUniqCellName ( cv rowName )
    (let ( propStr hash cellName )
        propStr = cv~>cellName
        (foreach elem  cv~>prop
            propStr = (strcat propStr elem~>name)
            (if  (type elem~>value) == (type "string")
                propStr = (strcat propStr elem~>value)
                propStr = (strcat propStr sprintf(nil "%L" elem~>value))
            )
        )
		;; (fprintf stdout "propStr = %L" propStr)
        hash = (abs (pckHashString2 propStr ))
        cellName = (lowerCase (sprintf nil "%s_%s_%L" rowName cv~>cellName hash  )) 
    )
)


;;; Creates rowName category if none exists and adds all static cells
;;; Creates rowName category if none exists and adds all static cells
(defun  pckAddCellsToCat ( lib categName categCellList)
  (let ( catId  libId categ result)
	(pckInfo "pckAddCellsToCat" sprintf( nil "Adding %L static cells to category %L of library %L\n"
											 length(categCellList) categName lib))
	libId = ddGetObj( lib )

    (if libId
		(progn
		  catId = ddCatOpenEx( libId categName "a"  1)
		  (foreach cell categCellList
				   result = (ddCatAddItem catId cell "cell")
				   (ddCatSave catId)
				   )
		  (ddCatClose catId)
		  catId = (ddCatOpenEx libId categName "a"  1)
		  (foreach cell categCellList
				   result = (ddCatAddItem catId cell "cell")
				   (ddCatSave catId)
				   )
		  (ddCatClose catId)
		  )
		
        (pckWarn "pckAddCellsToCat" sprintf( nil "Cannot create category %s - Unable to open library %s\n"
												 categName  lib))
		)
	)
  )



