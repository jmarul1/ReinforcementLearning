;;
;;   Hierarchy Functions
;;
;;   (load "pckCheckHierProcess.ils")
;;

(procedure (pckViewRefs libName cellName viewName @optional
                              (expandMode 'CCP_EXPAND_COMANAGED))
  (let (spec expanded cellViews cellViewInfo obj ExpandConfig specList)
       (setq obj (ddGetObj libName cellName viewName))
       (setq spec (gdmCreateSpecFromDDID obj))
       (setq expanded
             (cond
              ((ddGetObj libName cellName viewName "pc.db")
               (ccpExpandDesign spec expandMode))
              ((ddGetObj libName cellName viewName "expand.cfg")
               (ccp ExpandConfig spec expandMode))
              (t
               (setq specList (gdmCreateSpecList))
               (gdmAddSpecToSpecList spec specList)
               (ccpExpand specList expandMode))
              ))
       (gdmResetSpecList expanded)
       (while (setq spec (gdmNextFromSpecList expanded))
              (when (and
                     (setq cellViewInfo (gdmInspectSpec spec "LibraryUnix"))
                     (equal (cadddr cellViewInfo) "master.tag"))
                    (rplacd (cddr cellViewInfo) nil)
                    (setq cellViews (cons cellViewInfo cellViews))
                    )
              )
       cellViews
     ) ; Let
) ;  end of function

;;
;;   pckGetHier Gets the hierachy information of cells within a cell library
;;   from a text file and returns the hierachy information in a list of list
;;   The information is also written to a file stored in TCC_HIER_DUMP env
;;

(defun pckGetHier ( @optional infilenam outfilenam viewnam )
  "pckGetHier Gets the hierachy information of cells within a cell library from a text file and returns the hierachy information in a list of list. The information is also written to a file stored in TCC_HIER_DUMP env => l_list"
  (let ( inport indir cnt inline celllib cellnam rep replst outport x 
         rep2 temnam temlib temvw )
  
      ;cnt = 0
      if( infilenam == nil infilenam = "testing.txt" )
      if( outfilenam == nil outfilenam = "res_hier.txt" )
      if( viewnam == nil viewnam = "layout" )
      indir = (getShellEnvVar "TCC_HIER_DUMP")
      inport = infile( strcat( indir "/" infilenam) )
      outport = outfile( strcat( indir "/" outfilenam) "w" )
      (fprintf stdout "%s %s %s %L\n" indir strcat( indir "/" infilenam) strcat( indir "/" outfilenam) outport )
      replst = nil
      (when inport
	(while  (gets inline inport)
	  ;;cnt = cnt + 1
	  inline = parseString( inline)
	  (if (car inline) ;; make sure that we get something not nil
	      (progn
		cellnam = nth( 1 inline)
		celllib = nth( 0 inline)
		;;(fprintf stdout "%L %L\n" celllib cellnam)
		fprintf( outport "Library: %s  Name: %s \n" celllib cellnam  )
		replst = append( replst list( list( celllib cellnam)) )
		rep = pckViewRefs( celllib cellnam viewnam )
		rep2 = list( rep)
		replst = append( replst rep2)
		for( x 0 length( rep)-1
		       cnt =  nth( x rep)
		       temnam = nth( 1 cnt)
		       temlib = nth( 0 cnt)
		       temvw = nth( 2 cnt)
		       fprintf( outport "%s   %s   %s \n" temlib temnam temvw  )
		       )
		)
	    )
          )
	)
      close( outport)
      close( inport)
      replst
      
  ) ; let
) ; end of function

;;
;;   pckGetExtCell gets the hierachy information in a list of list from
;;   pckGetHier and counts the number of common cells within this hierarchy
;;   This functions returns a list of cells found to have counted > 1
;;

(defun pckGetExtCell ( @optional infilenam outfilenam viewnam viewcnt)
"pckGetExtCell gets the hierachy information in a list of list from pckGetHier and counts the number of common cells within this hierarchy. This functions returns a list of cells found to have counted > 1 => l_list"
  (let ( temtable hierlst x tem x2 temval temkey cnt xt temvw temtable2)
      
      if( infilenam == nil infilenam = "testing.txt" )
      if( outfilenam == nil outfilenam = "res_hier.txt" )
      if( viewnam == nil viewnam = "layout" )
      if( viewcnt == nil viewcnt = "layout" )
      temtable = makeTable( "atable1")
      temtable2 = makeTable( "atable1")
      hierlst = pckGetHier( infilenam outfilenam viewnam )
      for( x 1 length( hierlst)-1
         if( mod( x 2) == 1  then
	    tem = nth( x hierlst)
	    for( x2 0 length( tem)-1
               temval = nth( x2 tem)
	       temkey = strcat( nth( 0 temval) "_" nth( 1 temval))
	       temvw = nth( 2 temval)
	       cnt = 0
	       if( length( temtable) == 0 && temvw == viewcnt then
	           temtable[temkey] = 1
	       else
	          (foreach xt temtable
     		      if( xt == temkey && temvw == viewcnt then
		         temtable[xt] = temtable[xt] + 1
			 cnt = 1
	              else
		      )

	          )
	       )
	       if( cnt == 0 && temvw == viewcnt temtable[temkey] = 1 )

            )
	 else
	 )

      )
      (foreach xt temtable
	 if( temtable[xt] > 2 then
	    temtable2[xt] = temtable[xt]
         else
	 )

      )
      temtable2

  ) ; Let
) ; end of function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  pckTransShapeHierOverlaps             Project: TCC
;;
;;  Author: Vincent Rayappa & Greg Waliczek
;;	
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;****f* pckHier/pckTransShapeHierOverlaps
;;
;; FUNCTION
;;
;;  pckTransShapeHierOverlaps 	Transforms shapes within a given window and hier depth to the top and returns a cv
;;				of transformed shapes
;;
;;				returns ==> tempCV
;;
;;				tempCV is where those shapes are stored and should be deleted once the shapes no longer needed.
;;
;;
;;  USAGE
;;
;;  ( pckTransShapeHierOverlaps cv window lpp hierDepth @key userTempCV exclusions mosaicFilter ) ==> tempCV
;;
;;	cv - target cell view
;;	window - objects overlapping this bbox are processed and returned
;;	lpp - layer-purpose pair
;;	hierDepth - int specifying how far to decend into the hierarchy
;;	userTempCV - cellview destination for shapes
;;	exclusions - list of cell names excluded from processing, defaults to nil
;;	mosaicFilter - boolean implementing filter to remove redundancies from mosaic processing, defaults to t
;;
;;  Does not properly handle mosaic of a non-R0 cell!!
;;
;;****
;;
;;
;; (defun pckTransShapeHierOverlaps (cv window lpp depth @key (userTempCV nil) (returnObjList nil) (outLpp nil) (exclusions nil) (mosaicFilter t) (getTrueOverlaps t))
;;   "See pckGetOverlaps."
;;   t)

;; (defun pckGetOverlaps (cv window lpp depth @key (userTempCV nil) (returnObjList nil) (outLpp nil) (exclusions nil) (mosaicFilter t) (getTrueOverlaps t))
;;   "Finds shapes in the hierarchy, transforms them through the hierarchy and draws them at the top level => d_cvId|list_dbId"
;;   t)

;;(let ( )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  pckMosaicInstTransform
;;
;;  calculates transforms for a shape to reflect its location throughout a mosaic
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	(defun pckMosaicInstTransform ( mosaicId )
		( let ( x y row col initialX initialY Mag dx dy orient ll transform tmp )
		    ( setq orient ( car mosaicId~>tileArray ) )
			(case orient
			  ("R0"
			   (setq row mosaicId~>rows)
			   (setq col mosaicId~>columns)
			   (setq dx mosaicId~>uX)
			   (setq dy mosaicId~>uY))
			  ("R90"
			   (setq col mosaicId~>rows)
			   (setq row mosaicId~>columns)
			   (setq dy mosaicId~>uX )
			   (setq dx (minus mosaicId~>uY)))
			  ("R180"
			   (setq row mosaicId~>rows)
			   (setq col mosaicId~>columns)
			   (setq dx (minus mosaicId~>uX))
			   (setq dy (minus mosaicId~>uY)))
			  ("R270"
			   (setq col mosaicId~>rows)
			   (setq row mosaicId~>columns)
			   (setq dy (minus mosaicId~>uX))
			   (setq dx mosaicId~>uY))
			  ("MY"
			   (setq row mosaicId~>rows)
			   (setq col mosaicId~>columns)
			   (setq dx (minus mosaicId~>uX))
			   (setq dy mosaicId~>uY))
			  ("MYR90"
			   (setq col mosaicId~>rows)
			   (setq row mosaicId~>columns)
			   (setq dy (minus mosaicId~>uX))
			   (setq dx (minus mosaicId~>uY)))
			  ("MX"
			   (setq row mosaicId~>rows)
			   (setq col mosaicId~>columns)
			   (setq dx mosaicId~>uX)
			   (setq dy (minus mosaicId~>uY)))
			  ("MXR90"
			   (setq col mosaicId~>rows)
			   (setq row mosaicId~>columns)
			   (setq dy mosaicId~>uX)
			   (setq dx mosaicId~>uY)))

			( setq initialX ( car mosaicId~>xy ) )
			( setq initialY ( cadr mosaicId~>xy ) )
			( setq Mag 1.0 )
			( for c 0 col-1 
				( setq x ( initialX + c * dx ) )
				( for r 0 row-1
					( setq y ( initialY + r * dy ) )
					( setq ll ( list x y) )
					( setq tmp ( list ll orient Mag) )
					( setq transform ( cons tmp transform ) )
				);for
			);for
			transform
		);let
	);defun

(defun explodeMosaicCells (mosaicId tempCV)
  (let (inst tempList)
	(setq inst (dbCreateInst (getSGq mosaicId cellView) (getSGq mosaicId master) nil (list 0 0) "R0" 1))
	(foreach tf (pckMosaicInstTransform mosaicId)
			 (if (equal tf (car (reverse (pckMosaicInstTransform mosaicId))))
			   (setq tempList (cons (dbMoveFig inst tempCV tf) tempList))
			   (setq tempList (cons (dbCopyFig inst tempCV tf) tempList))))
	tempList))
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  transShapeHier
;;
;;  steps through hier returned by dbGetTrueOverlaps and transforms shape to top of hier
;;  mosaicList is needed to filter redundent processing of mosainInsts
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun transShapeHier ( hier shape outLpp tempCV mosaicList mosaicFilter )
  ( let ( bbox trans tempList shapeList tempLib )
	
	(foreach s (pckFlattenList (list shape))
			 (setq shapeList (cons (dbCopyFig s tempCV) shapeList)))
	(foreach s shapeList
			 (setSGq s outLpp lpp))
	( foreach h ( cdr hier )
			  ( setq tempList ( list ) )
			  ( cond
				( h~>objType == "inst"
							 ( foreach s shapeList
									   ( when s
										 ( setq tempList ( cons ( dbMoveFig s tempCV h~>transform ) tempList ) )
										 )
									   )
							 )
				( h~>objType == "mosaic"
							 ( foreach s shapeList
									   ( foreach tf ( pckMosaicInstTransform h )
												 ( when s
												   (if (equal tf (car (reverse ( pckMosaicInstTransform h ))))
													   ( setq tempList ( cons ( dbMoveFig s tempCV tf ) tempList ) )
													 ( setq tempList ( cons ( dbCopyFig s tempCV tf ) tempList ) ))
												   )
												 )
									   )
							 (setq mosaicList (cons hier mosaicList))
							 )
				( t
				  ( fprintf stdout "-E- Ooops...unknown objType: %L\n" h~>objType )
				  ( return nil )
				  )
				)
			  ( setq shapeList tempList )
			  )
	( list shapeList mosaicList )
	);let
  );defun
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  pckTransShapeHierOverlaps
;;
;;  transforms shapes within window and specified hier depth to top of hier.  Function returns a list of 
;;  transformed shapes as well as the temp cell view where they reside.  tempCV should be deleted once the
;;  the transformed shapes in it are no longer needed.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun pckTransShapeHierOverlaps ( cv window lpp depth @key ( userTempCV nil ) ( returnObjList nil ) ( outLpp nil ) ( exclusions nil ) ( mosaicFilter t ) (getTrueOverlaps t))
  ( let ( bboxes objList shape point figId hier objects tempCV mosaicList outTemp tempLib tempName mosaicInstTempList)   
	( if userTempCV
		(if (equal userTempCV cv)
			(setq tempCV cv)
		  (progn
			( setq tempCV userTempCV )
			( setq tempName tempCV~>cellName )
			( setq tempLib tempCV~>libName )))
	  (if returnObjList
		  (setq tempCV cv)
		( progn
		  ( setq tempLib cv~>libName )
		  ( setq tempName ( strcat cv~>cellName "_tf" ) )
		  ( setq tempCV ( dbOpenCellViewByType tempLib tempName "layout" "maskLayout" "w") )
		  ))
	  )
	( unless outLpp
	  (setq outLpp lpp))
	( setq mosaicList ( ncons nil ) )
	(if getTrueOverlaps
		( setq objects ( dbGetTrueOverlaps cv window lpp depth ) )
	  ( setq objects ( dbGetOverlaps cv window lpp depth ) ))
	( foreach obj objects
			  (cond 
			   ( (atom obj) && obj~>isShape && obj~>objType != "label" && lpp
				 (setq objList (cons (dbCopyFig obj tempCV) objList))
				 )
			   ( (atom obj) && obj~>objType != "label" && (not lpp)
				 (setq objList (cons (dbCopyFig obj tempCV) objList))
				 )
			   ( (listp obj) && ( (car obj)~>objType == "inst" || (car obj)~>objType == "mosaic" ) && (not (member "label" (pckFlattenList obj~>objType) ) ) && (not (member (car obj)~>cellName exclusions))
				 ( setq hier ( reverse ( pckFlattenList obj ) ) )
				 ( setq shape ( car hier ) )
				 ( unless (and
						   (member hier mosaicList)
						   mosaicFilter)
				   ( setq outTemp ( transShapeHier hier shape outLpp tempCV mosaicList mosaicFilter ) ))
				 ( setq objList ( cons ( nth 0 outTemp ) objList ) )
				 ( setq mosaicList ( nth 1 outTemp ) )
				 )
			   );cond
			  );foreach
	(unless lpp
	  (setq mosaicInstTempList (setof x (pckFlattenList objList) (equal (getSGq x objType) "mosaic")))
	  (foreach elem mosaicInstTempList
			   (setq objList (cons (explodeMosaicCells elem tempCV) objList)))
	  (mapcar (quote dbDeleteObject) mosaicInstTempList)
	  (setq objList (setof x (pckFlattenList objList) (nequal (getSGq x objType) "mosaic"))))
	(if returnObjList
		(pckFlattenList objList)
	  tempCV)
	);let
  );defun

	;; ;; ( setq pckTransShapeHierOverlaps pckTransShapeHierOverlaps )
	;; (setq pckGetOverlaps pckTransShapeHierOverlaps)
	
;;);let
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; End pckTransShapeHierOverlaps  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  pckHierLayerCheck             Project: TCC
;;
;;  Author: Greg Waliczek
;;	
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;****f* pckHier/pckHierLayerCheck
;;
;; FUNCTION
;;
;;  pckHierLayerCheck  Searches through CV hierarchy and returns a list of cells which contain geometries drawn in 
;;                     the user specified layer(s)
;;
;;				returns ==> '((lib cell) (lib cell) ... )
;;
;;
;;  USAGE
;;
;;  (pckHierLayerCheck cv lppList @optional excludeList)
;;
;;	cv - cell view
;;	lppList - list of lpps for which to search
;;	excludeList - list of cell names to exclude from processing, defaults to nil
;;
;;****
;;
;;
;; (defun pckHierLayerCheck ()
;;   "Searches through CV hierarchy and returns a list of cells which contain geometries drawn in the user specified layer(s) l_list"
;;   t)

;;(let ()

  (defun pckHierLayerCheck (cv lppList @optional (excludeList nil))
	(let (instHeaderList outList)
	  (setq instHeaderList (pckGetInstHeaders cv excludeList))
	  (foreach header instHeaderList
			   (when (pckGetInstHeaders (getSGq header master) excludeList)
				 (foreach elem (pckHierLayerCheck (getSGq header master) lppList excludeList)
						  (when elem
							(unless (member elem outList)
							  (setq outList (cons elem outList))))))
			   (foreach lpp lppList
						(when (member lpp (list (getSGq (getSGq (getSGq header master) lpps) layerName) (getSGq (getSGq (getSGq header master) lpps) purpose)))
						  (unless (member (list (getSGq cv libName) (getSGq header cellName)) outList)
							(setq outList (cons (list (getSGq header libName) (getSGq header cellName)) outList))))))
	  (foreach lpp lppList
			   (when (member lpp (list (getSGq (getSGq cv lpps) layerName) (getSGq (getSGq cv lpps) purpose)))
				 (unless (member (list (getSGq cv libName) (getSGq cv cellName)) outList)
				   (setq outList (cons (list (getSGq cv libName) (getSGq cv cellName)) outList)))))
	  ;(dbPurge cv)
	  outList))

  (defun pckGetInstHeaders (cv excludeList)
	(let (returnList)
	  (foreach inst (getSGq cv instHeaders)
			   (unless (member (getSGq inst cellName) excludeList)
				 (setq returnList (cons inst returnList))))
	  returnList))

  ;;(setq pckHierLayerCheck pckHierLayerCheck)
;;);let