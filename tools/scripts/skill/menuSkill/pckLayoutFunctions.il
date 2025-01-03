;;****h* TCC/pckLayoutFunctions
;; NAME
;; pckLayoutFunctions - collection of TCC auxiliary functions that deal with 
;; layout objects
;;
;; AUTHOR: 
;; Bill Harris, Pavel Rott, 
;;
;; COPYRIGHT 
;;
;; Intel Corporation 2004
;;
;; USAGE
;;
;; load "pckLayoutFunctions.il"
;;
;; KEYWORDS: TCC Project, MOS, DSR
;;****


;;****f* pckLayoutFunctions/pckIsRotated
;;
;; FUNCTION
;;
;; pckIsRotated - Determine if a cell is rotated
;;
;; USAGE
;;
;; pckIsRotated "<cellOrient>" where cellOrient can be cv~>orient
;;
;;****

(defun pckIsRotated ( cellOrient)
  "Determine if a cell is rotated => t|nil"
let( (rotated)

    rotated = (nindex( cellOrient "R90") || nindex( cellOrient "R270"))
    rotated 
)
)

;;****f* pckLayoutFunctions/pckIsMetal
;;
;; FUNCTION
;;
;; pckIsMetal - Determine if layer is one of metal layers
;;
;; USAGE
;;
;; pckIsMetal "<layer name>" 
;;
;;****

(defun pckIsMetal ( layer)
  "Determine if layer is one of metal layers => t|nil"
let( (metal)

    if( nindex( layer "metal") then metal = t else metal = nil)
    metal
) ;; let
) ;; pckIsMetal procedure end 


;;****f* pckLayoutFunctions/pckIsVia
;;
;; FUNCTION
;;
;; pckIsVia - Determine if layer is one of via layers
;;
;; USAGE
;;
;; pckIsVia "<layer name>" 
;;
;;****

(defun pckIsVia ( layer)
  "Determine if layer is one of via layers => t|nil"
  (let (via)

    if( nindex( layer "via") then via = t else via = nil)
    via
	) ;; let

  ) ;; pckIsMetal procedure end 

;;****f* pckLayoutFunctions/pckGetViaRules
;;
;; FUNCTION
;;
;; pckGetViaRules - Obtain X and Y dimensions for via layer
;;
;; USAGE
;;
;; pckGetViaRules "<layer name>" 
;;
;;****

(defun pckGetViaRules ( layer)
  let( (sizeX sizeY)

    sizeX = pckLayerInfo(AUX_LIB "minWidthX" layer)
    sizeY = pckLayerInfo(AUX_LIB "minWidthY" layer)
    list( sizeX sizeY)
	
	)
)

;;****f* pckLayoutFunctions/pckPrintVia
;;
;; FUNCTION
;;
;; pckPrintVia - Create via ona given layer with minimum dimensions (obtained through pckGetViaRules)
;; and drawn is centered at (0 0)
;;
;; USAGE
;;
;; pckPrintVia "<layer name>" 
;;
;;****

(defun pckPrintVia ( layer)
  "Create via ona given layer with minimum dimensions (obtained through pckGetViaRules) and drawn is centered at (0 0) => d_dbId"
let( (viaDims x1 x2 y1 y2)

    viaDims = pckGetViaRules( layer)
    x1 = -pckPutOnGrid(car( viaDims) / 2.0)
    y1 = -pckPutOnGrid(cadr( viaDims) / 2.0)
    x2 = x1 + car( viaDims)
    y2 = y1 + cadr( viaDims)
    dbCreateRect( pcCellView list( layer "drawing") list( x1:y1 x2:y2 ))

)
)
;;****f* pckLayoutFunctions/pckGetMtlRules
;;
;; FUNCTION
;;
;; pckGetMtlRules - Obtain maximum X and Y dimensions for metal layer
;;
;; USAGE
;;
;; pckGetMtlRules "<layer name>" 
;;
;;****


(defun pckGetMtlRules ( layer)
"Obtain maximum X and Y dimensions for metal layer => l_result"
let( (sizeX sizeY)

    sizeX = pckLayerInfo(AUX_LIB "maxWidthX" layer)
    sizeY = pckLayerInfo(AUX_LIB "maxWidthY" layer)
    list( sizeX sizeY)

)
)

;;****f* pckLayoutFunctions/pckGetMtlDiffPolyRules
;;
;; FUNCTION
;;
;; pckGetMtlDiffPolyRules - Obtain maximum X and Y dimensions for metal/diffusion/poly layer
;;
;; USAGE
;;
;; pckGetMtlDiffPolyRules "<whichRule>" "<layer>" 
;;
;;****
(defun pckGetMtlDiffPolyRules ( whichRule layer)
  "Obtain maximum X and Y dimensions for metal/diffusion/poly layer => n_num"
let( (size)

	if( nindex( whichRule "maxWidth") then

	    if( nindex( layer "metal") then

            size = pckLayerInfo(AUX_LIB whichRule layer)

	    else

            ;; For now, use ndiff maxWidth rule for ndiff, pdiff, poly. Techfile
            ;; rules for pdiff broken, and no maxWidth rule for poly.

	        size = pckLayerInfo(AUX_LIB whichRule "ndiff")

        )
	    
	else

        size = pckLayerInfo(AUX_LIB whichRule layer)

    )
    size

)
)


;;****f* pckLayoutFunctions/pckPrintMtl
;;
;; FUNCTION
;;
;; pckPrintMtl - Prints min dim X/Y metal rectangle with CF/BN if needed
;;
;; USAGE
;;
;; pckPrintMtl "<layer>" 
;;
;;****
(defun pckPrintMtl ( layer)
"Prints min dim X/Y metal rectangle with CF/BN if needed => d_dbId"
let( (mtlDims x1 x2 y1 y2 thisInstParams)

    mtlDims = pckGetMtlRules( layer)
    x1 = -pckPutOnGrid(car( mtlDims) / 2.0)
    y1 = -pckPutOnGrid(cadr( mtlDims) / 2.0)
    x2 = x1 + car( mtlDims)
    y2 = y1 + cadr( mtlDims)
    dbCreateRect( pcCellView list( layer "drawing") list( x1:y1 x2:y2 ))

	 if( pckNeedCfTf( layer) then
		 thisInstParams = 
		 list(	 
			  list( "ltX"       "float"  x1 )
			  list( "ltY"       "float"  y1 )
			  list( "rtX"       "float"  x2 )
			  list( "rtY"       "float"  y2 )
			  list( "cfNum"     "int"    0 )
			  list( "layer"     "string" layer )
			  
			  )

		 dbCreateParamInstByMasterName( pcCellView AUX_LIB 
										"tp1auxBananaBox" "layout" nil 0:0
										"R0" 1 thisInstParams) 

	    )
)
)

;;****f* pckLayoutFunctions/pckGetNextMtl
;;
;; FUNCTION
;;
;; pckGetNextMtl - Given a metal layer, return string with name of next higher metal layer
;;
;; USAGE
;;
;; pckGetNextMtl "<metal layer>" 
;;
;;****

(defun pckGetNextMtl ( layer)
"Given a metal layer, return string with name of next higher metal layer => t_string"
let( (layerNum nextLayer)

	 sscanf( layer "metal%d" layerNum)
	 if( layerNum then 
		 sprintf( nextLayer "metal%d" layerNum + 1)
	 else
	     nextLayer = "metal1"
	 )

;     pckDebug( "pckGetNextMtl" sprintf( nil "layer=%s nextLayer=%s"  layer nextLayer ))

	 nextLayer
)
)

;;****f* pckLayoutFunctions/pckGetPrevMtl
;;
;; FUNCTION
;;
;; pckGetPrevMtl - Given a metal layer, return string with name of previous lower metal layer
;;
;; USAGE
;;
;; pckGetPrevMtl "<metal layer>" 
;;
;;****

(defun pckGetPrevMtl ( layer)
  "Given a metal layer, return string with name of previous lower metal layer => t_string"
let( (layerNum prevLayer)

	 sscanf( layer "metal%d" layerNum)
	 if( layerNum > 1 then 
		 sprintf( prevLayer "metal%d" layerNum - 1)
	 else
	     prevLayer = nil
	 )

	 prevLayer
)
)

;;****f* pckLayoutFunctions/pckGetNextVia
;;
;; FUNCTION
;;
;; pckGetNextVia - Given a via layer, return string with name of next higher via layer
;;
;; USAGE
;;
;; pckGetNextVia "<via layer>" 
;;
;;****

(defun pckGetNextVia ( layer)
  "Given a via layer, return string with name of next higher via layer => t_string"
let( (layerNum nextLayer)

	 sscanf( layer "via%d" layerNum)
	 if( layerNum then sprintf( nextLayer "via%d" layerNum + 1))
	 nextLayer
)
)

;;****f* pckLayoutFunctions/pckWhichVia
;;
;; FUNCTION
;;
;; pckWhichVia - Given 2 metal layers, return string with name of the via layer to connect metals.
;;               Metal layers can be in either order, also will return "via0" if one layer not a
;;               metal (such as "diffcon" or "polycon").  Returns lowest possible via if not given 2 
;;               "consecutive" metal layers.
;;               
;;               If the Process ID is 1265, "contact" will be returned in place of "via0".
;;
;; USAGE
;;
;; pckWhichVia "<metal layer>" "< metal layer>"
;; 
;; pckWhichVia( "metal1" "metal2") returns "via1"
;; pckWhichVia( "metal8" "metal7") returns "via7"
;; pckWhichVia( "diffcon" "metal1") returns "via0"
;; pckWhichVia( "metal1" "polycon") returns "via0"
;;
;;****

(defun pckWhichVia ( metalLayer1 metalLayer2)
  "Given 2 metal layers, return string with name of the via layer to connect metals. Metal layers can be in either order, also will return via0 if one layer not a metal (such as diffcon or polycon).  Returns lowest possible via if not given 2 consecutive metal layers. If the Process ID is 1265, contact will be returned in place of via0. => t_string"
(let (layerNum1 layerNum2 viaLayer)

    sscanf( metalLayer1 "metal%d" layerNum1)
	if( ! layerNum1 then layerNum1 = 0) 
    sscanf( metalLayer2 "metal%d" layerNum2)
	if( ! layerNum2 then layerNum2 = 0) 

	sprintf( viaLayer "via%d" min(layerNum1 layerNum2))

	if( pckIs1265() && viaLayer == "via0" then viaLayer = "contact")

	viaLayer

)
)

;;****f* pckLayoutFunctions/pckMtl2via
;;
;; FUNCTION
;;
;; pckMtl2via - Given a metal layer, return string with name of same via layer
;;              If not a valid metal layer ("diffcon", "polycon"), return "via0"
;;
;; USAGE
;;
;; pckMtl2via "<metal layer>" 
;;
;;****
(defun pckMtl2via ( metalLayer)
  "Given a metal layer, return string with name of same via layer. If not a valid metal layer (diffcon, polycon), return via0 => t_string"
(let ( layerNum viaName lablText)

    sscanf( metalLayer "metal%d" layerNum)
	if( layerNum == nil then
		layerNum = 0
	)
    sprintf( viaName "via%d" layerNum)
    
    viaName

) ; let
) ; function

;;****f* pckLayoutFunctions/pckViaParams
;;
;; FUNCTION
;;
;; pckViaParams - Given a metal and via layer, return enclosure or coverage rule. Default rule is "minEnclosureEMX"
;;
;; USAGE
;;
;; pckViaParams "metal layer "<via layer>" (optional) "<rule name>" 
;;
;; If metal = via ("metal1" "via1") then via enclosure of "same" metal is returned.
;; If metal != via ("metal2" "via1") then metal enclosure of "lesser" via is returned.
;; You may override default EMX rules by specifying a rule name to get ORT or min rule values. 
;;
;;****
(defun pckViaParams ( metalLayer viaLayer @optional ruleName )
  "Given a metal and via layer, return enclosure or coverage rule. Default rule is minEnclosureEMX => n_float"
(let ( metalNum viaNum ruleValue)

;    pckDebug( "pckViaParams" sprintf( nil "metalLayer=%s viaLayer=%s"  metalLayer viaLayer ))

    if( ruleName == nil then ruleName = "minEnclosureEMX")

    sscanf( metalLayer "metal%d" metalNum)
	if( metalNum == nil then
		metalNum = 0
		ruleName = "minEnclosureX"
	)
    

    if( (viaLayer == "contact") then
        viaNum = 0
    else
        sscanf( viaLayer "via%d" viaNum)
    )
    if( (metalNum == viaNum) then
        ruleValue = pck2LayerInfo(AUX_LIB ruleName viaLayer metalLayer)
    else
        ruleValue = pck2LayerInfo(AUX_LIB ruleName metalLayer viaLayer)
    ) 

    ruleValue

) ; let
) ; function


(defun pckGetMetalNumber ( layer)
"Returns the number part of the metal layer name => x_integer | nil"
(let ( num)
  (if layer (sscanf  layer "metal%d" num))
  num
)
)


(defun pckGetViaNumber ( layer)
"Returns the number part of the via layer name => x_integer | nil"
(let ( num)
  (if layer (sscanf  layer "via%d" num))
  num
)
)

;;****f* pckLayoutFunctions/pckSearchInstHierarchy
;;
;; NAME
;;
;; pckSearchInstHierarchy
;;
;; DESCRIPTION
;;
;; This function searches cellview's hierarchy for a shape and returns top level instance
;; that contains that shape. Useful for identifying instances by their contents (e.g. pads)
;;
;; USAGE
;;
;; (setq shape (car (leSearchHierarchy (geGetEditCellView) (geGetEditCellView)~>bBox 32 "any shape" 
;;							 list( list( "layer" "==" list( "ndiff" "drawing" ) ) ) ) ) )
;; (pckSearchInstHierarchy (geGetEditCellView) shape 0) 
;;
;; SOURCE

(defun pckSearchInstHierarchy (cv shapeId @optional (hl 0) parentId )
  "This function searches cellview's hierarchy for a shape and returns top level instance that contains that shape. Useful for identifying instances by their contents (e.g. pads) => d_dbid"
;;
;;*******

  (let (childview lvl)
	;(fprintf stdout "Available instances are %L\n" cv~>instances~>cellName)
	(setq lvl hl)
	(foreach inst cv~>instances 
			 (when (equal lvl 0)
			   (setq parentId inst) ) ;; to find the parent of the shape
			 (when (setq childview inst~>master)
			   ;(fprintf stdout "Switching to layout master for %L\n" inst~>cellName)
			   (when childview~>instances
				 ;(fprintf stdout "level %d: Descending into cell %L\n" lvl childview~>cellName)
				 (pckSearchInstHierarchy childview shapeId lvl+1 parentId) 
				 ;;(setq lvl lvl-1)
				 )
			   
			   ;(fprintf stdout "Checking shapes in %L %L on level %d\n" childview~>objType childview~>cellName lvl)
			   (if (member shapeId childview~>shapes)
				   (progn
					 (fprintf stdout "FOUND FOUND FOUND !!!! Shape %L found in %L %L\n" shapeId~>cellView inst~>name childview~>cellName )
				 (fprintf stdout "Shape was found in instance %s of %s\n" parentId~>name parentId~>cellName)
				 )
			   )
			 )
			 )
	);; let
  )
;; Transforms all shapes, instances and mosaics within a structure table
;; Usage is the same as dbMoveFig
;;****f* pckLayoutFunctions/pckMoveAll
;;
;; FUNCTION
;;
;;  pckMoveAll - Transforms all shapes, instances and mosaics within a cell view, similar to dbMoveFig
;;
;;  USAGE
;;
;;  pckMoveAll <origin cell view> <destination cell view> <transform list ex. ( list -2:1 "MX" )>
;;
;;****
(defun pckMoveAll (dbObj destCV transformList)
  "Transforms all shapes, instances and mosaics within a cell view, similar to dbMoveFig => t|nil"
	(progn
		(foreach shape dbObj~>shapes
			(dbMoveFig shape destCV transformList))
		(foreach inst (setof inst dbObj~>instances (nequal inst~>objType "mosaicInst"))
			(dbMoveFig inst destCV transformList))
 		(foreach mosaic dbObj~>mosaics
			(dbMoveFig mosaic destCV transformList))))

;;****f* pckLayoutFunctions/pckGetPinInfo
;; FUNCTION
;;
;;  pckGetPinInfo: Find bbox of all pins in a instance in a
;;  layout. Bboxes are transformed so that have the correct reference
;;  for the instance i.e. appropriate shifts/rotations are done to
;;  account for the hierarchy inside the instance.
;;
;; USAGE
;;
;;  (pckGetPinInfo pcellInstance)  
;;
;;  Only parameter is a pcell instance.
;;  
;;  Returns a DPL of bboxes corresponding to pins. The key of the DPL
;;  is the name of the pin and the value is another dpl with keys bbox 
;;  and lpp. bbox contains pin bbox and lpp contains pin layer/purpose.
;;
;;****
(defun pckGetPinInfo (inst)
  "Find bbox of all pins in a instance in a layout. Bboxes are transformed so that have the correct reference for the instance i.e. appropriate shifts/rotations are done to account for the hierarchy inside the instance. => l_dpl"
  (let (masterPin name bbox lpp (pininfo (ncons nil)))
	  (foreach 
	   masterTerm inst~>master~>terminals
	   (setq masterPin (car masterTerm~>pins))
	   (setq name masterPin~>term~>name)
	   (setq bbox (dbTransformBBox masterPin~>fig~>bBox (list inst~>xy inst~>orient)))
	   (setq lpp masterPin~>fig~>lpp)
       ;;changed by Tanmay to enable 1272 ghost-pin routing
       ;;layerPurpose for ghost pin is "ghostDrawing" 
       (setq lpp (list (car lpp) "drawing"))
	   (putprop pininfo (list nil 'bbox bbox 'lpp lpp) name))
	  pininfo))



(defun pckGetBondPadNames ()
"Returns a list of all the tp1 pad names. => l_list"
(let ( len teminfo bondPadNames )

	len = length( BOND_PAD_PARAMS )
	(for i 0 len-1
		teminfo = (nth i (exists x BOND_PAD_PARAMS x->name))->pad_tp1
		bondPadNames = cons( teminfo bondPadNames) 
	)
	bondPadNames

) ;; let
) ;; pckGetBondPadNames

;;****f* pckLayoutFunctions/pckNoObstructionsP
;;
;; FUNCTION
;;
;; Check if all the bboxes passed are completely free of lpp. 
;;
;; USAGE
;;
;; (pckNoObstructionsP cv bboxes lpp @optional (includeCoincident nil))
;;
;; If 4th parameter is set to nil (optional default), checks by
;; shrinking bboxes by one grid point, to prevent stuff coincident
;; on bboxes from getting flagged. To make function flag
;; lpp shapes conincident on bboxes, set optional parameter to t.
;;
;; RETURNS
;; 
;; bboxes returned as-is if bboxes are free of obstructions
;; nil if there are obstructions
;;
;; So you can use the result of this function in (when ) (unless ) etc.
;;****
;;
(defun pckNoObstructionsP (cv bboxes lpp @optional (includeCoincident nil) (flagObstruction nil))
  "Check if all the bboxes passed are completely free of lpp. => l_bboxes|nil"
  ;;(pckDebug "pckAutowire" (sprintf nil "pckNoObstructionsP called for bboxes %L and LPP %L." bboxes lpp))
  (let (rdBboxes noOverlaps obj )

    (if boundp('TCC_AUTOWIRE_DEBUG)
        (if TCC_AUTOWIRE_DEBUG flagObstruction = t))

	;;if needed set rdBboxes to be one-grid size smaller than bbox
	(if includeCoincident
		(setq rdBboxes bboxes)
		(setq rdBboxes (mapcar (lambda (x) 
								 (pckPutOnGridBBox
								  (pckTransformBbox x (minus  (pckGetGrid)) (minus  (pckGetGrid)))))
							   bboxes)))
	(setq noOverlaps (mapcar (lambda (x) 
							   (null (dbGetTrueOverlaps cv x lpp (dbGetMaxHierDepth))))
							 rdBboxes))
	(if (apply 'and noOverlaps)
		(progn
		  bboxes)
		(progn
		  (for i 0 (difference (length bboxes) 1)
			   (unless (nth i noOverlaps)
                 (pckWarn "pckAutowire" 
                          (sprintf nil "\n*****************************************************\nDetected obstruction in %L\n*****************************************************" 
                                   (nth i bboxes)))
                 (if flagObstruction then
                     (pckGetOverlaps cv (nth i rdBboxes) lpp (dbGetMaxHierDepth) ?exclusions (pckGetBondPadNames)
                                                  ?returnObjList t ?outLpp list(car( lpp) "scratchDrawing"))
                     obj=rodCreateRect(?cvId cv ?layer list( "marker" "error") ?bBox (nth i bboxes))
                     dbCreateLabel( cv list( "marker" "error") obj~>centerCenter 
                                       "OBSTRUCTION" "centerCenter" "R0"  "roman" 5)
                 )
               ) ;; unless
			   (setq i (plus i 1)))

		  nil))))



;;****f* pckLayoutFunctions/pckWhichQuadrant
;;
;; FUNCTION
;;
;; Determine which quadrant the polygon is in
;; given a vertex of the input polygon as origin reference
;;
;; USAGE
;;
;; (pckWhichQuadrant cv dbId point)
;;
;; RETURNS
;; 
;; 1, 2, 3 or 4 a positive integer indicates where the polygon reside
;;              a negative integer indicates wgere the polygon is not
;;  or
;; 12, 23, 34 ,41, 13, 24
;;
;;****
;;
(defun pckWhichQuadrant (cv dbId point)
  "Determine which quadrant the polygon is in given a vertex of the input polygon as origin reference => n_num"
  (let (t1 t2 t3 t4 (i nil) (ii nil) (iii nil) (iv nil) (grid (pckGetGrid)))
    (setq t1 (rodAddPoints point (list grid grid)))
    (setq t2 (rodAddPoints point (list -grid grid)))
    (setq t3 (rodAddPoints point (list -grid -grid)))
    (setq t4 (rodAddPoints point (list grid -grid)))
    (when (or (equal dbId~>objType "polygon") (equal dbId~>objType "rect"))
          (when (member dbId (dbGetTrueOverlaps cv (list t1 t1)))
            (setq i t))
          (when (member dbId (dbGetTrueOverlaps cv (list t2 t2)))
            (setq ii t))
          (when (member dbId (dbGetTrueOverlaps cv (list t3 t3)))
            (setq iii t))
          (when (member dbId (dbGetTrueOverlaps cv (list t4 t4)))
           (setq iv t)))
    (cond
      ((and i (not ii) (not iii) (not iv)) 1)
      ((and ii iii iv (not i)) -1)
      ((and ii (not i) (not iii) (not iv)) 2)
      ((and i iii iv (not ii)) -2)
      ((and iii (not i) (not ii) (not iv)) 3)
      ((and i ii iv (not iii)) -3)
      ((and iv (not i) (not ii) (not iii)) 4)
      ((and i ii iii (not iv)) -4)
      ((and i ii (not iii) (not iv)) 12)
      ((and ii iii (not i) (not iv)) 23)
      ((and iii iv (not i) (not ii)) 34)
      ((and iv i (not ii) (not iii)) 41)
      ((and i iii (not ii) (not iv)) 13)
      ((and ii iv (not i) (not iii)) 24)
      (t 0))))
       

;;****f* pckLayoutFunctions/pckLayerSize
;;
;; FUNCTION
;;
;; Similar to dbLayerSize but allows different sizing for x and y
;; 
;;
;; USAGE
;;
;; (pckLayerSize cv lpp dbIdList xVal yVal)
;;
;; RETURNS
;; 
;; dbId list of upsized shapes
;;
;;****
;;
(defun pckLayerSize (cv lpp dbIdList xVal yVal)
  "Similar to dbLayerSize but allows different sizing for x and y => d_dbId"
  (let ((tempList nil) (outList nil) (pointListAll nil) pointList p shapePoints)
    (foreach shape dbIdList
             (setq pointList nil)
             (when (or (equal shape~>objType "rect") (equal shape~>objType "polygon"))
               (for i 0 (length (setq shapePoints (if (equal shape~>objType "rect") shape~>bBox shape~>points)))-1
                    (setq p (nth i shapePoints))
                    ;;(fprintf stdout "In point = %L\n" p)
                    (case (pckWhichQuadrant cv shape p)
                      ((1 -3)
                       (setq p (rodAddPoints p -xVal:-yVal)))
                      ((2 -4)
                       (setq p (rodAddPoints p xVal:-yVal)))
                      ((3 -1)
                       (setq p (rodAddPoints p xVal:yVal)))
                      ((4 -2)
                       (setq p (rodAddPoints p -xVal:yVal)))
                      (12
                       (setq p (rodAddPoints p 0.0:-yVal))
                       (if (zerop i)
                           (when (pckEQP (xCoord p) (xCoord (nth (length shapePoints)-1 shapePoints)))
                             (case (pckWhichQuadrant cv shape (nth (length shapePoints)-1 shapePoints))
                               ((1 -2 -3 4)
                                (setq p (rodAddPoints p -xVal:0.0)))
                               ((-1 2 3 -4)
                                (setq p (rodAddPoints p xVal:0.0)))))
                           (when (pckEQP (xCoord p) (xCoord (nth i-1 shapePoints)))
                             (setq p (list (xCoord (nth 0 pointList)) (yCoord p)))))
                       (if (pckEQP i (length shapePoints)-1)
                           (when (pckEQP (xCoord p) (xCoord (nth 0 shapePoints)))
                             (case (pckWhichQuadrant cv shape (xCoord (nth 0 shapePoints)))
                               ((1 -2 -3 4)
                                (setq p (rodAddPoints p -xVal:0.0)))
                               ((-1 2 3 -4)
                                (setq p (rodAddPoints p xVal:0.0)))))
                           (when (pckEQP (xCoord p) (xCoord (nth i+1 shapePoints)))
                             (case (pckWhichQuadrant cv shape (nth i+1 shapePoints))
                               ((1 -2 -3 4)
                                (setq p (rodAddPoints p -xVal:0.0)))
                               ((-1 2 3 -4)
                                (setq p (rodAddPoints p xVal:0.0)))))))
                      (23
                       (setq p (rodAddPoints p xVal:0.0))
                       (if (zerop i)
                           (when (pckEQP (yCoord p) (yCoord (nth (length shapePoints)-1 shapePoints)))
                             (case (pckWhichQuadrant cv shape (nth (length shapePoints)-1 shapePoints))
                               ((1 2 -3 -4)
                                (setq p (rodAddPoints p 0.0:-yVal)))
                               ((-1 -2 3 4)
                                (setq p (rodAddPoints p 0.0:yVal)))))
                           (when (pckEQP (yCoord p) (yCoord (nth i-1 shapePoints)))
                             (setq p (list (xCoord p) (yCoord (nth 0 pointList))))))
                       (if (pckEQP i (length shapePoints)-1)
                           (when (pckEQP (yCoord p) (yCoord (nth 0 shapePoints)))
                             (case (pckWhichQuadrant cv shape (nth 0 shapePoints))
                               ((1 2 -3 -4)
                                (setq p (rodAddPoints p 0.0:-yVal)))
                               ((-1 -2 3 4)
                                (setq p (rodAddPoints p 0.0:yVal)))))
                           (when (pckEQP (yCoord p) (yCoord (nth i+1 shapePoints)))
                             (case (pckWhichQuadrant cv shape (nth i+1 shapePoints))
                               ((1 2 -3 -4)
                                (setq p (rodAddPoints p 0.0:-yVal)))
                               ((-1 -2 3 4)
                                (setq p (rodAddPoints p 0.0:yVal)))))))
                      (34
                       (setq p (rodAddPoints p 0.0:yVal))
                       (if (zerop i)
                           (when (pckEQP (xCoord p) (xCoord (nth (length shapePoints)-1 shapePoints)))
                             (case (pckWhichQuadrant cv shape (nth (length shapePoints)-1 shapePoints))
                               ((1 -2 -3 4)
                                (setq p (rodAddPoints p -xVal:0.0)))
                               ((-1 2 3 -4)
                                (setq p (rodAddPoints p xVal:0.0)))))
                           (when (pckEQP (xCoord p) (xCoord (nth i-1 shapePoints)))
                             (setq p (list (xCoord (nth 0 pointList)) (yCoord p)))))
                       (if (pckEQP i (length shapePoints)-1)
                           (when (pckEQP (xCoord p) (xCoord (nth 0 shapePoints)))
                             (case (pckWhichQuadrant cv shape (xCoord (nth 0 shapePoints)))
                               ((1 -2 -3 4)
                                (setq p (rodAddPoints p -xVal:0.0)))
                               ((-1 2 3 -4)
                                (setq p (rodAddPoints p xVal:0.0)))))
                           (when (pckEQP (xCoord p) (xCoord (nth i+1 shapePoints)))
                             (case (pckWhichQuadrant cv shape (nth i+1 shapePoints))
                               ((1 -2 -3 4)
                                (setq p (rodAddPoints p -xVal:0.0)))
                               ((-1 2 3 -4)
                                (setq p (rodAddPoints p xVal:0.0)))))))
                      (41
                       (setq p (rodAddPoints p -xVal:0.0))
                       (if (zerop i)
                           (when (pckEQP (yCoord p) (yCoord (nth (length shapePoints)-1 shapePoints)))
                             (case (pckWhichQuadrant cv shape (nth (length shapePoints)-1 shapePoints))
                               ((1 2 -3 -4)
                                (setq p (rodAddPoints p 0.0:-yVal)))
                               ((-1 -2 3 4)
                                (setq p (rodAddPoints p 0.0:yVal)))))
                           (when (pckEQP (yCoord p) (yCoord (nth i-1 shapePoints)))
                             (setq p (list (xCoord p) (yCoord (nth 0 pointList))))))
                       (if (pckEQP i (length shapePoints)-1)
                           (when (pckEQP (yCoord p) (yCoord (nth 0 shapePoints)))
                             (case (pckWhichQuadrant cv shape (nth 0 shapePoints))
                               ((1 2 -3 -4)
                                (setq p (rodAddPoints p 0.0:-yVal)))
                               ((-1 -2 3 4)
                                (setq p (rodAddPoints p 0.0:yVal)))))
                           (when (pckEQP (yCoord p) (yCoord (nth i+1 shapePoints)))
                             (case (pckWhichQuadrant cv shape (nth i+1 shapePoints))
                               ((1 2 -3 -4)
                                (setq p (rodAddPoints p 0.0:-yVal)))
                               ((-1 -2 3 4)
                                (setq p (rodAddPoints p 0.0:yVal)))))))
                      (13
                       (pckInfo "pckLayerSize" (sprintf nil "Point %L dropped from shape - quad 13" (nth i shapePoints)))
                       (setq p nil))
                      (24
                       (pckInfo "pckLayerSize" (sprintf nil "Point %L dropped from shape - quad 24" (nth i shapePoints)))
                       (setq p nil))
                      (0
                       (pckInfo "pckLayerSize" (sprintf nil "Point %L dropped from shape - quad 0" (nth i shapePoints)))
                       (setq p nil)))
                    ;;(fprintf stdout "   Out point = %L\n" p)
                    (when p
                      (if pointList
                          (setq pointList (cons p pointList))
                          (setq pointList (list p)))))
               (unless (atom (car pointList))
                 (if pointListAll
                     (setq pointListAll (cons pointList pointListAll))
                     (setq pointListAll (list pointList))))))
    (foreach elem pointListAll
             (unless (atom (car elem))
               (cond
                 ((equal (length elem) 2)
                  (if tempList
                      (setq tempList (cons (dbCreateRect cv lpp elem) tempList))
                      (setq tempList (list (dbCreateRect cv lpp elem)))))
                 ((greaterp (length elem) 2)
                  (if tempList
                      (setq tempList (cons (dbCreatePolygon cv lpp elem) tempList))
                      (setq tempList (list (dbCreatePolygon cv lpp elem)))))
                 (t
                  t))))
    (foreach elem tempList
             (if outList
                 (setq outList (cons (dbLayerAnd cv lpp (list elem) (list elem) 4000) outList))
                 (setq outList (dbLayerAnd cv lpp (list elem) (list elem) 4000)))
             (dbDeleteObject elem))
    (pckFlattenList outList)))

;;****f* pckLayoutFunctions/pckPutPolygonOnGrid
;;
;; FUNCTION
;;
;; Snaps polygon verticies to user defined grid. Option to round
;; up (1), down (-1) or to closest (0) grid point
;; 
;;
;; USAGE
;;
;; (pckPutPolygonOnGrid cv lpp dbIdList xVal yVal @optional (snapType 0))
;;
;; RETURNS
;; 
;; dbId list of grid-snapped shapes
;;
;;****
;;
(defun pckPutPolygonOnGrid (cv lpp dbIdList xGrid yGrid @optional (snapType 0))
  "Snaps polygon verticies to user defined grid. snapType option rounds up (1), down (-1) or to closest (0) grid point => l_dbId"
  (let (quad xUp xDown yUp yDown outPoint pointList point shapePoints (tempList nil) (outList nil))
    (foreach elem dbIdList
             (when (or (equal elem~>objType "rect") (equal elem~>objType "polygon"))
               (setq pointList nil)
               (for i 0 (length (setq shapePoints (if (equal elem~>objType "rect") elem~>bBox elem~>points)))-1
                    (setq point (nth i shapePoints))
                    (setq quad (pckWhichQuadrant cv elem point))
                    (setq xUp (pckPutOnGridCeiling (xCoord point) xGrid))
                    (setq xDown (pckPutOnGridFloor (xCoord point) xGrid))
                    (setq yUp (pckPutOnGridCeiling (yCoord point) yGrid))
                    (setq yDown (pckPutOnGridFloor (yCoord point) yGrid))
                    (case snapType
                      (0
                       (setq outPoint (list
                                       (if (equal
                                            (min
                                             (abs (difference (xCoord point) xUp))
                                             (abs (difference (xCoord point) xDown)))
                                            (abs (difference (xCoord point) xUp)))
                                           xUp
                                           xDown)
                                       (if (equal
                                            (min
                                             (abs (difference (yCoord point) yUp))
                                             (abs (difference (yCoord point) yDown)))
                                            (abs (difference (yCoord point) yUp)))
                                           yUp
                                           yDown))))
                      (1
                       (cond
                         ((or (equal quad -1) (equal quad 3))
                          (setq outPoint (list xUp yUp)))
                         ((or (equal quad -2) (equal quad 4))
                          (setq outPoint (list xDown yUp)))
                         ((or (equal quad -3) (equal quad 1))
                          (setq outPoint (list xDown yDown)))
                         ((or (equal quad -4) (equal quad 2))
                          (setq outPoint (list xUp yDown)))
                         ((equal quad 12)
                          (setq outPoint 0.0:yDown)
                          (if (zerop i)
                              (when (pckEQP (xCoord point) (xCoord (nth (length shapePoints)-1 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth (length shapePoints)-1 shapePoints))
                                  ((1 -2 -3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridFloor (xCoord (nth (length shapePoints)-1 shapePoints)) xGrid):0.0)))
                                  ((-1 2 3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridCeiling (xCoord (nth (length shapePoints)-1 shapePoints)) xGrid):0.0)))))
                              (when (pckEQP (xCoord point) (xCoord (nth i-1 shapePoints)))
                                (setq outPoint (list (xCoord (nth 0 pointList)) (yCoord outPoint)))))
                          (if (pckEQP i (length shapePoints)-1)
                              (when (pckEQP (xCoord point) (xCoord (nth 0 shapePoints)))
                                (case (pckWhichQuadrant cv elem (xCoord (nth 0 shapePoints)))
                                  ((1 -2 -3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridFloor (xCoord (nth 0 shapePoints)) xGrid):0.0)))
                                  ((-1 2 3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridCeiling (xCoord (nth 0 shapePoints)) xGrid):0.0)))))
                              (when (pckEQP (xCoord point) (xCoord (nth i+1 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth i+1 shapePoints))
                                  ((1 -2 -3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridFloor (xCoord (nth i+1 shapePoints) xGrid):0.0)))
                                  ((-1 2 3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridCeiling (xCoord (nth i+1 shapePoints)) xGrid):0.0))))))))
                         ((equal quad 23)
                          (setq outPoint xUp:0.0)
                          (if (zerop i)
                              (when (pckEQP (yCoord point) (yCoord (nth (length shapePoints)-1 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth (length shapePoints)-1 shapePoints))
                                  ((1 2 -3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridFloor (yCoord (nth (length shapePoints)-1 shapePoints)) yGrid))))
                                  ((-1 -2 3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridCeiling (yCoord (nth (length shapePoints)-1 shapePoints)) yGrid))))))
                              (when (pckEQP (yCoord point) (yCoord (nth i-1 shapePoints)))
                                (setq outPoint (list (xCoord outPoint) (yCoord (nth 0 pointList))))))
                          (if (pckEQP i (length shapePoints)-1)
                              (when (pckEQP (yCoord point) (yCoord (nth 0 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth 0 shapePoints))
                                  ((1 2 -3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridFloor (yCoord (nth 0 shapePoints)) yGrid))))
                                  ((-1 -2 3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridCeiling (yCoord (nth 0 shapePoints)) yGrid))))))
                              (when (pckEQP (yCoord point) (yCoord (nth i+1 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth i+1 shapePoints))
                                  ((1 2 -3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridFloor (yCoord (nth i+1 shapePoints)) yGrid))))
                                  ((-1 -2 3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridCeiling (yCoord (nth i+1 shapePoints)) yGrid))))))))
                         ((equal quad 34)
                          (setq outPoint 0.0:yUp)
                          (if (zerop i)
                              (when (pckEQP (xCoord point) (xCoord (nth (length shapePoints)-1 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth (length shapePoints)-1 shapePoints))
                                  ((1 -2 -3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
										  (pckPutOnGridFloor (xCoord (nth (length shapePoints)-1 shapePoints)) xGrid):0.0)))
                                  ((-1 2 3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
										  (pckPutOnGridCeiling (xCoord (nth (length shapePoints)-1 shapePoints)) xGrid):0.0)))))
                              (when (pckEQP (xCoord point) (xCoord (nth i-1 shapePoints)))
                                (setq outPoint (list (xCoord (nth 0 pointList)) (yCoord outPoint)))))
                          (if (pckEQP i (length shapePoints)-1)
                              (when (pckEQP (xCoord point) (xCoord (nth 0 shapePoints)))
                                (case (pckWhichQuadrant cv elem (xCoord (nth 0 shapePoints)))
                                  ((1 -2 -3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridFloor (xCoord (nth 0 shapePoints)) xGrid):0.0)))
                                  ((-1 2 3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridCeiling (xCoord (nth 0 shapePoints)) xGrid):0.0)))))
                              (when (pckEQP (xCoord point) (xCoord (nth i+1 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth i+1 shapePoints))
                                  ((1 -2 -3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridFloor (xCoord (nth i+1 shapePoints)) xGrid):0.0)))
                                  ((-1 2 3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridCeiling (xCoord (nth i+1 shapePoints)) xGrid):0.0)))))))
                         ((equal quad 41)
                          (setq outPoint xDown:0.0)
                          (if (zerop i)
                              (when (pckEQP (yCoord point) (yCoord (nth (length shapePoints)-1 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth (length shapePoints)-1 shapePoints))
                                  ((1 2 -3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridFloor (yCoord (nth (length shapePoints)-1 shapePoints)) yGrid))))
                                  ((-1 -2 3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridCeiling (yCoord (nth (length shapePoints)-1 shapePoints)) yGrid))))))
                              (when (pckEQP (yCoord point) (yCoord (nth i-1 shapePoints)))
                                (setq outPoint (list (xCoord outPoint) (yCoord (nth 0 pointList))))))
                          (if (pckEQP i (length shapePoints)-1)
                              (when (pckEQP (yCoord point) (yCoord (nth 0 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth 0 shapePoints))
                                  ((1 2 -3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridFloor (yCoord (nth 0 shapePoints)) yGrid))))
                                  ((-1 -2 3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridCeiling (yCoord (nth 0 shapePoints)) yGrid))))))
                              (when (pckEQP (yCoord point) (yCoord (nth i+1 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth i+1 shapePoints))
                                  ((1 2 -3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridFloor (yCoord (nth i+1 shapePoints)) yGrid))))
                                  ((-1 -2 3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridCeiling (yCoord (nth i+1 shapePoints)) yGrid))))))))
                         ((equal quad 13)
                          (pckInfo "pckPutPolygonOnGrid" (sprintf nil "Point %L dropped from shape - quad 13" (nth i shapePoints)))
                          (setq outPoint nil))
                         ((equal quad 24)
                          (pckInfo "pckPutPolygonOnGrid" (sprintf nil "Point %L dropped from shape - quad 24" (nth i shapePoints)))
                          (setq outPoint nil))
                         ((equal quad 0)
                          (pckInfo "pckPutPolygonOnGrid" (sprintf nil "Point %L dropped from shape - quad 0" (nth i shapePoints)))
                          (setq outPoint nil))))
                      (-1
                       (cond
                         ((or (equal quad -1) (equal quad 3))
                          (setq outPoint (list xDown yDown)))
                         ((or (equal quad -2) (equal quad 4))
                          (setq outPoint (list xUp yDown)))
                         ((or (equal quad -3) (equal quad 1))
                          (setq outPoint (list xUp yUp)))
                         ((or (equal quad -4) (equal quad 2))
                          (setq outPoint (list xDown yUp)))
                         ((equal quad 12)
                          (setq outPoint 0.0:yUp)
                          (if (zerop i)
                              (when (pckEQP (xCoord point) (xCoord (nth (length shapePoints)-1 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth (length shapePoints)-1 shapePoints))
                                  ((1 -2 -3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridCeiling (xCoord (nth (length shapePoints)-1 shapePoints)) xGrid):0.0)))
                                  ((-1 2 3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridFloor (xCoord (nth (length shapePoints)-1 shapePoints)) xGrid):0.0)))))
                              (when (pckEQP (xCoord point) (xCoord (nth i-1 shapePoints)))
                                (setq outPoint (list (xCoord (nth 0 pointList)) (yCoord outPoint)))))
                          (if (pckEQP i (length shapePoints)-1)
                              (when (pckEQP (xCoord point) (xCoord (nth 0 shapePoints)))
                                (case (pckWhichQuadrant cv elem (xCoord (nth 0 shapePoints)))
                                  ((1 -2 -3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridCeiling (xCoord (nth 0 shapePoints)) xGrid):0.0)))
                                  ((-1 2 3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridFloor (xCoord (nth 0 shapePoints)) xGrid):0.0)))))
                              (when (pckEQP (xCoord point) (xCoord (nth i+1 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth i+1 shapePoints))
                                  ((1 -2 -3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridCeiling (xCoord (nth i+1 shapePoints)) xGrid):0.0)))
                                  ((-1 2 3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridFloor (xCoord (nth i+1 shapePoints)) xGrid):0.0)))))))
                         ((equal quad 23)
                          (setq outPoint xDown:0.0)
                          (if (zerop i)
                              (when (pckEQP (yCoord point) (yCoord (nth (length shapePoints)-1 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth (length shapePoints)-1 shapePoints))
                                  ((1 2 -3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridCeiling (yCoord (nth (length shapePoints)-1 shapePoints)) yGrid))))
                                  ((-1 -2 3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridFloor (yCoord (nth (length shapePoints)-1 shapePoints)) yGrid))))))
                              (when (pckEQP (yCoord point) (yCoord (nth i-1 shapePoints)))
                                (setq outPoint (list (xCoord outPoint) (yCoord (nth 0 pointList))))))
                          (if (pckEQP i (length shapePoints)-1)
                              (when (pckEQP (yCoord point) (yCoord (nth 0 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth 0 shapePoints))
                                  ((1 2 -3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridCeiling (yCoord (nth 0 shapePoints)) yGrid))))
                                  ((-1 -2 3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridFloor (yCoord (nth 0 shapePoints)) yGrid))))))
                              (when (pckEQP (yCoord point) (yCoord (nth i+1 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth i+1 shapePoints))
                                  ((1 2 -3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridCeiling (yCoord (nth i+1 shapePoints)) yGrid))))
                                  ((-1 -2 3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridFloor (yCoord (nth i+1 shapePoints)) yGrid))))))))
                         ((equal quad 34)
                          (setq outPoint 0.0:yDown)
                          (if (zerop i)
                              (when (pckEQP (xCoord point) (xCoord (nth (length shapePoints)-1 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth (length shapePoints)-1 shapePoints))
                                  ((1 -2 -3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridCeiling (xCoord (nth (length shapePoints)-1 shapePoints)) xGrid):0.0)))
                                  ((-1 2 3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridFloor (xCoord (nth (length shapePoints)-1 shapePoints)) xGrid):0.0)))))
                              (when (pckEQP (xCoord point) (xCoord (nth i-1 shapePoints)))
                                (setq outPoint (list (xCoord (nth 0 pointList)) (yCoord outPoint)))))
                          (if (pckEQP i (length shapePoints)-1)
                              (when (pckEQP (xCoord point) (xCoord (nth 0 shapePoints)))
                                (case (pckWhichQuadrant cv elem (xCoord (nth 0 shapePoints)))
                                  ((1 -2 -3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridCeiling (xCoord (nth 0 shapePoints)) xGrid):0.0)))
                                  ((-1 2 3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridFloor (xCoord (nth 0 shapePoints)) xGrid):0.0)))))
                              (when (pckEQP (xCoord point) (xCoord (nth i+1 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth i+1 shapePoints))
                                  ((1 -2 -3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridCeiling (xCoord (nth i+1 shapePoints)) xGrid):0.0)))
                                  ((-1 2 3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          (pckPutOnGridFloor (xCoord (nth i+1 shapePoints)) xGrid):0.0)))))))
                         ((equal quad 41)
                          (setq outPoint xUp:0.0)
                          (if (zerop i)
                              (when (pckEQP (yCoord point) (yCoord (nth (length shapePoints)-1 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth (length shapePoints)-1 shapePoints))
                                  ((1 2 -3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridCeiling (yCoord (nth (length shapePoints)-1 shapePoints)) yGrid))))
                                  ((-1 -2 3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridFloor (yCoord (nth (length shapePoints)-1 shapePoints)) yGrid))))))
                              (when (pckEQP (yCoord point) (yCoord (nth i-1 shapePoints)))
                                (setq outPoint (list (xCoord outPoint) (yCoord (nth 0 pointList))))))
                          (if (pckEQP i (length shapePoints)-1)
                              (when (pckEQP (yCoord point) (yCoord (nth 0 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth 0 shapePoints))
                                  ((1 2 -3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridCeiling (yCoord (nth 0 shapePoints)) yGrid))))
                                  ((-1 -2 3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridFloor (yCoord (nth 0 shapePoints)) yGrid))))))
                              (when (pckEQP (yCoord point) (yCoord (nth i+1 shapePoints)))
                                (case (pckWhichQuadrant cv elem (nth i+1 shapePoints))
                                  ((1 2 -3 -4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridCeiling (yCoord (nth i+1 shapePoints)) yGrid))))
                                  ((-1 -2 3 4)
                                   (setq outPoint
                                         (rodAddPoints
                                          outPoint
                                          0.0:(pckPutOnGridFloor (yCoord (nth i+1 shapePoints)) yGrid))))))))
                         ((equal quad 13)
                          (pckInfo "pckPutPolygonOnGrid" (sprintf nil "Point %L dropped from shape - quad 13" (nth i shapePoints)))
                          (setq outPoint nil))
                         ((equal quad 24)
                          (pckInfo "pckPutPolygonOnGrid" (sprintf nil "Point %L dropped from shape - quad 24" (nth i shapePoints)))
                          (setq outPoint nil))
                         ((equal quad 0)
                          (pckInfo "pckPutPolygonOnGrid" (sprintf nil "Point %L dropped from shape - quad 0" (nth i shapePoints)))
                          (setq outPoint nil)))))
                    (if pointList
                        (setq pointList (cons outPoint pointList))
                        (setq pointList (list outPoint))))
			   ;;remove nil's, if any, from pointList
			   (setq pointList (setof x  pointList (not (null x))))
               (if tempList
                   (setq tempList (cons 
                                  (if (equal elem~>objType "polygon")
                                      (dbCreatePolygon cv lpp pointList)
                                      (dbCreateRect cv lpp pointList))
                                  tempList))
                   (setq tempList (if (equal elem~>objType "polygon")
                                     (list (dbCreatePolygon cv lpp pointList))
                                     (list (dbCreateRect cv lpp pointList)))))))
    (foreach elem tempList
             (if outList
                 (setq outList (cons (dbLayerAnd cv lpp (list elem) (list elem elem) 4000) outList))
                 (setq outList (dbLayerAnd cv lpp (list elem) (list elem) 4000)))
             (dbDeleteObject elem))
    (pckFlattenList outList)))

;;****f* pckLayoutFunctions/pckSetpckGen
;;
;; FUNCTION
;;
;; When called on a lib/cell/view, adds a cellview-level property to that
;; indicates that this lib/cell/view was generated by TCC. It is expected
;; that pckStartLayout, pckFiller, pckAutotermination, pckFlattenSyncRow
;; will use this function to designate cells as having been generated via
;; TCC.
;;
;; USAGE
;;
;; (pckSetpckGen lib cell view)
;;
;;****


(defun pckSetpckGen (lib cell view)
  "When called on a lib/cell/view, adds a cellview-level property to that indicates that this lib/cell/view was generated by TCC. It is expected that pckStartLayout, pckFiller, pckAutotermination, pckFlattenSyncRow will use this function to designate cells as having been generated via TCC. => t|nil"
  (let (cv)
    (if (ddGetObj lib cell view)
        (progn ;; layout exists
          (if (setq cv (dbOpenCellViewByType lib cell view "maskLayout" "a"))
              (progn ;; design is writable
                (dbSetq cv "yes" createdBypck)
                (pckInfo "pckSetpckGen" (sprintf nil "Successfully tagged cell %s %s %s." lib cell view))
                (dbSave cv)
                (dbClose cv)
                t
                )
              (progn
                (pckError "pckSetpckGen" (sprintf nil "Cell %s %s %s is not writable. Cannot tag it." lib cell view)) 
                nil
                )
              )
          )
        (progn ;; layout does not exist
          (pckError "pckSetpckGen" (sprintf nil "Cell %s %s %s does not exist." lib cell view))
          nil)
        )
    )
  );; pckSetpckGen


;; I made this function to implement pckGen tag removal tool.  I did not want to alter the above function so this
;; is basically a copy of the above function that sets the tag to "no" instead of "yes"

(defun pckSetpckGenNo (lib cell view)
  "When called on a lib/cell/view, removes the cellview-level property that indicates that this lib/cell/view was generated by TCC. It is used to un-do the designation of cells as having been generated via TCC. => t|nil"
  (let (cv)
    (if (ddGetObj lib cell view)
        (progn ;; layout exists
          (if (setq cv (dbOpenCellViewByType lib cell view "maskLayout" "a")) && cv~>createdBypck == "yes"
              (progn ;; design is writable
                (dbDeletePropByName cv "createdBypck")
                (pckInfo "pckSetpckGenNo" (sprintf nil "Successfully deleted createdBypck property from cell %s %s %s" 
                                                   lib cell view))
                (dbSave cv)
                (dbClose cv)
                t
                )
              (progn
                (if cv == nil (pckError "pckSetpckGenNo" (sprintf nil "Cell %s %s %s is not writable Cannot tag it." 
                                                                  lib cell view))) 
                nil
                )
              )
          )
        (progn ;; layout does not exist
          (pckError "pckSetpckGenNo" (sprintf nil "Cell %s %s %s does not exist." lib cell view))
          nil)
        )
    )
  );; pckSetpckGenNo

(defun pckSetpckGenNoAll (lib cell view)
  "When called on a lib/cell/view, removes the cellview-level property that indicates that this lib/cell/view was generated by TCC for ALL instanced cells as well as the top level cell. It is used to un-do the designation of cells as having been generated via TCC. => t|nil"
  (let (cv )

    (if (ddGetObj lib cell view)
        (progn ;; layout exists
          (if (setq cv (dbOpenCellViewByType lib cell view "maskLayout" "a"))
              (progn ;; design is writable
                (foreach i cv~>instances
                    (pckSetpckGenNo i~>libName i~>cellName "layout")     
                    )
                (pckSetpckGenNo cv~>libName cv~>cellName "layout")     
                )
              )
          t
          )
        (progn ;; layout does not exist
          (pckError "pckSetpckGenNoAll" (sprintf nil "Cell %s %s %s does not exist." lib cell view))
          nil)
          )
  ) ;; let
) ;; pckSetpckGenNoAll


(let (pckSetpckGenNoForm)

(defun pckSetpckGenNoMenu ()

(let ( rowNameField defRowName
       libNameField defLibName currWindow)

    currWindow = geGetWindowCellView()

	(if currWindow == nil then

        (if boundp( 'pckSetpckGenNoForm) then
            defRowName = pckSetpckGenNoForm->rowNameField->value
            defLibName = pckSetpckGenNoForm->libNameField->value
        else
            defRowName = ""
            defLibName = ""
        )

	else
        defLibName = currWindow~>libName
        defRowName = currWindow~>cellName
	)

    rowNameField = ( hiCreateStringField
                     ?name		'rowNameField
                     ?prompt	"Row/Top Cell Name:"
                     ?value    defRowName
                     )

    libNameField = ( hiCreateStringField
                     ?name		'libNameField
                     ?prompt	"Library Name:"
                     ?value     defLibName
                     )


    pckSetpckGenNoForm = ( hiCreateAppForm
                           ?name		'pckSetpckGenNoForm
                           ?fields	list('rowNameField
                                         'libNameField
                                         )
                           ?formTitle	"Delete createdBypck Property"
                           ?callback	"{ pckSetpckGenNoCB( pckSetpckGenNoForm) }"
                           ?dontBlock t
                           )

    hiDisplayForm( 'pckSetpckGenNoForm )


) ;; let
) ;; pckSetpckGenNoMenu
) ;; let pckSetpckGenNoForm

(defun pckSetpckGenNoCB (form)
(let ()

  (pckSetpckGenNo form->libNameField->value  form->rowNameField->value "layout")


) ;; let
) ;; pckSetpckGenNoCB



;;****f* pckLayoutFunctions/pckGetpckGen
;;
;; FUNCTION
;;
;; Checks whether a lib/cell/view was generated by TCC. Internally
;; leverages information stored by the pckSetpckGen function.
;;
;; USAGE
;;
;; (pckGetpckGen lib cell view)
;;
;;****

(defun pckGetpckGen (lib cell view)
  "Checks whether a lib/cell/view was generated by TCC. Internally leverages information stored by the pckSetpckGen function. => t|nil"
  (let (cv)
    (if (ddGetObj lib cell view)
        (progn ;; layout exists
          (setq cv (dbOpenCellViewByType lib cell view "maskLayout" "r"))
          (if (equal (dbGetq cv createdBypck) "yes") t nil)
          )
        (progn ;; layout does not exist
          (pckError "pckGetpckGen" (sprintf nil "Cell %s %s %s does not exist." lib cell view))
          nil)
        )
    )
  )


(defun pckFindLabel (cv labelText)
(let (labelId)

  labelId = nil
  (if cv~>shapes
      (foreach shape cv~>shapes
               (if shape~>objType == "label"
                   (if shape~>theLabel == labelText 
                       labelId = shape)))
      )
  labelId

) ;; let
) ;; pckFindLabel


;;****f* pckLayoutFunctions/pckSetShare
;;
;; FUNCTION
;;
;; When called on a lib/cell/view, adds a cellview-level property to that
;; indicates that this lib/cell/view was a shared cells between rows. It is expected
;; that TCC DS operation will use this function to designate if cells are shared cells or not. 
;;
;; USAGE
;;
;; (pckSetShare lib cell view)
;;
;;****


(defun pckSetShare (lib cell view)
  "When called on a lib/cell/view, adds a cellview-level property to that indicates that this lib/cell/view was a shared cells between rows. It is expected that TCC DS operation will use this function to designate if cells are shared cells or not. => t|nil"
  (let (cv x y bBox labelId)
    (if (ddGetObj lib cell view)
        (progn ;; layout exists
          (if (setq cv (dbOpenCellViewByType lib cell view "maskLayout" "a"))
              (progn ;; design is writable
                (dbSetq cv "yes" testrowShare)

                (if (pckFindLabel cv "SHARED CELL") == nil then
                    x = car( trBBoxCenter( cv~>bBox ) )
                    y = cadr( trBBoxCenter( cv~>bBox ) )
                    bBox = cv~>bBox
                    labelId = dbCreateLabel( cv list("text" "drawing") x:y "SHARED CELL" "centerCenter" "R0" "roman" 
                                                cadr( trBBoxDims( cv~>bBox ) ) )

                    (while pckFindBBoxInsideZone( list( labelId~>bBox ) bBox ) == nil
                           labelId~>height =  labelId~>height - 0.01
                           )

                    )

                (pckInfo "pckSetShare" (sprintf nil "Successfully tagged cell %s %s %s as SHARED." lib cell view))
                (dbSave cv)
                (dbClose cv)
                t
                )
              (progn
                (pckError "pckSetShare" (sprintf nil "Cell %s %s %s is not writable. Cannot tag it." lib cell view)) 
                nil
                )
              )
          )
        (progn ;; layout does not exist
          (pckError "pckSetShare" (sprintf nil "Cell %s %s %s does not exist." lib cell view))
          nil)
        )
    )
  );; pckSetShare

;;****f* pckLayoutFunctions/pckSetShare
;;
;; FUNCTION
;;
;; When called on a lib/cell/view, adds a cellview-level property to that
;; indicates that this lib/cell/view was a shared cells between rows. It is expected
;; that TCC DS operation will use this function to designate if cells are shared cells or not. 
;;
;; USAGE
;;
;; (pckSetShare lib cell view)
;;
;;****


(defun pckUnSetShare (lib cell view)
  "When called on a lib/cell/view, adds a cellview-level property to that indicates that this lib/cell/view was a shared cells between rows. It is expected that TCC DS operation will use this function to designate if cells are shared cells or not. => t|nil"
  (let (cv labelId)
    (if (ddGetObj lib cell view )
        (progn ;; layout exists
          (if (setq cv (dbOpenCellViewByType lib cell view "maskLayout" "a"))
              (progn ;; design is writable
                (dbDeletePropByName cv "testrowShare")
                labelId = (pckFindLabel cv "SHARED CELL") 
                (if labelId != nil (dbDeleteObject labelId))
                (pckInfo "pckUnSetShare" (sprintf nil "Successfully deleted SHARED property from cell %s %s %s" 
                                                   lib cell view))
                (dbSave cv)
                (dbClose cv)
                t
                )
              (progn
                (pckError "pckUnSetShare" (sprintf nil "Cell %s %s %s is not writable. Cannot change it." lib cell view)) 
                nil
                )
              )
          )
        (progn ;; layout does not exist
          (pckError "pckUnSetShare" (sprintf nil "Cell %s %s %s does not exist." lib cell view))
          nil)
        )
    )
  );; pckUnSetShare


;;****f* pckLayoutFunctions/pckGetShare
;;
;; FUNCTION
;;
;; Checks whether a lib/cell/view was a shared cell. Internally
;; leverages information stored by the pckSetShare function.
;;
;; USAGE
;;
;; (pckGetShare lib cell view)
;;
;;****

(defun pckGetShare (lib cell view)
  "Checks whether a lib/cell/view was a shared cell. Internally leverages information stored by the pckSetShare function. => t|nil"
  (let (cv)
    (if (ddGetObj lib cell view)
        (progn ;; layout exists
          (setq cv (dbOpenCellViewByType lib cell view "maskLayout" "r"))
          (if (equal (dbGetq cv testrowShare) "yes") t nil)
          )
        (progn ;; layout does not exist
          (pckError "pckGetShare" (sprintf nil "Cell %s %s %s does not exist." lib cell view))
          nil)
        )
    )
  )



(let (pckSetShareForm)

(defun pckSetShareMenu ()

(let ( cellNameField defCellName
       libNameField defLibName isSharedField defShared currWindow)

    currWindow = geGetWindowCellView()

	(if currWindow == nil then

        (if boundp( 'pckSetShareForm) then
            defCellName = pckSetShareForm->cellNameField->value
            defLibName = pckSetShareForm->libNameField->value
            (if (pckGetShare defLibName defCellName "layout")
                defShared = "yes"
                defShared = "no"
            )
        else
            defCellName = ""
            defLibName = ""
            defShared = "no"
        )

	else
        defLibName = currWindow~>libName
        defCellName = currWindow~>cellName
        (if (pckGetShare defLibName defCellName "layout")
            defShared = "yes"
            defShared = "no"
        )
	)

    cellNameField = ( hiCreateStringField
                     ?name		'cellNameField
                     ?prompt	"Cell Name:"
                     ?value     defCellName
                     ?callback	"{ pckIsSharedCB( pckSetShareForm) }"
                     )

    libNameField = ( hiCreateStringField
                     ?name		'libNameField
                     ?prompt	"Library Name:"
                     ?value     defLibName
                     ?callback	"{ pckIsSharedCB( pckSetShareForm) }"
                     )

    isSharedField = ( hiCreateCyclicField
                      ?name		'isSharedField
                      ?prompt	"Is this cell shared?"
                      ?choices  list("yes" "no")
                      ?defValue defShared
                      )

    pckSetShareForm = ( hiCreateAppForm
                           ?name		'pckSetShareForm
                           ?fields	list('cellNameField
                                         'libNameField
                                         'isSharedField
                                         )
                           ?formTitle	"Set or Remove cell SHARED Property"
                           ?callback	"{ pckSetShareCB( pckSetShareForm) }"
                           ?dontBlock t
                           )

    hiDisplayForm( 'pckSetShareForm )


) ;; let
) ;; pckSetShareMenu
) ;; let pckSetShareForm

(defun pckSetShareCB (form)
(let ()

  (if (lowerCase form->isSharedField->value) != "yes"
      (pckUnSetShare form->libNameField->value  form->cellNameField->value "layout")
      (pckSetShare form->libNameField->value  form->cellNameField->value "layout"))

) ;; let
) ;; pckSetShareCB

(defun pckIsSharedCB (form)
(let ()

  (if (pckGetShare form->libNameField->value form->cellNameField->value "layout")
      form->isSharedField->value = "yes"
      form->isSharedField->value = "no")

) ;; let
) ;; pckIsSharedCB




;;****f* pckLayoutFunctions/pckTp0CdfDiff
;;
;; FUNCTION
;;
;; reports differences between cdf and tp0 parameter values
;; 
;;
;; USAGE
;;
;; (pckTp0CdfDiff"<path>  )
;;
;; EXAMPLE
;;
;; (pckTp0CdfDiff "CHN/VIA_SRP1/tp0chnvsrp1" )
;;
;;****

(defun pckTp0CdfDiff (Cell)
  "reports differences between cdf and tp0 parameter values => t"
  (let (cdfParams cellParams lib tp0 lib1 cv cellName cellId mismatch)
	tp0 = car(last( parseString( Cell "/")))
	lib = pckGetLibrary(strcat(Cell ".il"))
	lib1 = eval(lib)
	
	cv = dbOpenCellViewByType( lib1 tp0 "layout" "maskLayout" "r")
	cellParams = car(last(cv~>prop~>value))
	cellName = cv~>cellName
	cellId = ddGetObj( cv~>libName cv~>cellName)
	cdfParams = cdfGetCellCDF(cellId)~>parameters
	(foreach cdfParam  cdfParams
			 (foreach cellParam cellParams
					  (when cdfParam~>name == cellParam~>name
							(unless cdfParam~>value == cellParam~>value
									mismatch = t
									(fprintf stdout "cell parameter %L = %L cdf parameter %L = %L\n"
											 cellParam~>name cellParam~>value cdfParam~>name cdfParam~>value))))
			 )
	(dbClose cv)
	(if mismatch
	  (fprintf stdout "Enter: \n(pckTp02Cdf %L ?update t) \n   in CIW to update cdf values to tp0 values\n" Cell)
	  (fprintf stdout "No mismatched parameter values between %L and %L\n" (get_pname (concat tp0 ".il"))  (get_pname (concat tp0 "_cdf.il"))))
	)
  )

;;****f* pckLayoutFunctions/pckTp0CdfDiffCv
;;
;; FUNCTION
;;
;; reports differences between cdf and tp0 parameter values
;; 
;;
;; USAGE
;;
;; (pckTp0CdfDiff" cv  )
;;
;; EXAMPLE
;;
;; (pckTp0CdfDiff cv )
;;
;;****
(defun pckTp0CdfDiffCv (cv)
  "reports differences between cdf and tp0 parameter values => t"
  (let (cdfParams cellParams lib tp0 lib1 cellName cellId mismatch)
    tp0 = cv~>cellName
    lib = cv~>libName
    cellParams = car(last(cv~>prop~>value))
    ;; cellName = cv~>cellName

    cellId = ddGetObj( lib tp0)
    cdfParams = cdfGetCellCDF(cellId)~>parameters
    (foreach cdfParam  cdfParams
             (foreach cellParam cellParams
                      (when cdfParam~>name == cellParam~>name
                            (unless cdfParam~>value == cellParam~>value
                                    mismatch = t
                                    (fprintf stdout "cell parameter %L = %L cdf parameter %L = %L\n"
                                             cellParam~>name cellParam~>value cdfParam~>name cdfParam~>value))))
             )
    (if mismatch
      (fprintf stdout ">>>> WARNING <<<<<  cdf/pcell mismatches found in pcell %L library %L\n" tp0 lib )
      (fprintf stdout "No mismatched parameter values between %L and %L\n" (get_pname (concat tp0 ".il"))  (get_pname (concat tp0 "_cdf.il"))))
    )
  )

;;****f* pckLayoutFunctions/pckTp02Cdf
;;
;; FUNCTION
;;
;; Creates new, or updates existing cdf file based on cell params. Writes < template path>/<pCellName>_cdf.il_new.
;; 
;;
;; USAGE
;;
;; (pckTp02Cdf "<path> ?create t )
;; or 
;; (pckTp02Cdf "<path> ?update t )
;;
;; EXAMPLE
;;
;; (pckTp02Cdf "CHN/VIA_SRP1/tp0chnvsrp1" ?create t )
;;
;;****
defun( pckTp02Cdf (Cell @key (update nil) (create nil))
				  "Creates new, or updates existing cdf file based on cell params. Writes < template path>/<pCellName>_cdf.il_new. => t"
    (let (oldCdf newCdf cdfFile libName reqCdfParamNames  CellParamValue cellId lib lib1 tp0
        IN OUT cv cellParams cdfParams padrowType aprMethod zone process user x myName myEmail
        terms cellName helpUrl templateName cadenceDataBase cadenceLib date year newName 
        category cdfOnly line )
        tp0 = car(last( parseString( Cell "/")))
        lib = pckGetLibrary(strcat(Cell ".il"))
        lib1 = eval(lib)
        cv = dbOpenCellViewByType( lib1 tp0 "layout" "maskLayout" "r")
        terms = buildString(cv~>sigNames ",")
        ;;cellParams = reverse(car(last(cv~>prop~>value)))
        cellParams = car(last(cv~>prop~>value))
		x = (list (car (last cellParams)))
		(foreach prop cellParams
				 x = (cons prop x))
		x = (cdr x)
		cellParams = (reverse x)
        foreach( param cellParams
            when(
                param~>name == "padrow"
                padrowType = param~>value
            )
            when( param~>name == "aprMethod"
                aprMethod = param~>value
            )
            when( param~>name == "zone"
               zone = param~>value
           )
        )
    ;##################################################################################################
    ;#################################### Create new CDF ##############################################
    ;##################################################################################################
        when( create
            newCdf = strcat( Cell "_cdf.il_new")
            cdfFile = strcat( cv~>cellName "_cdf.il")
            OUT = outfile("/tmp/cdf")

            ;;; get info needed for metadata section:

            process = getShellEnvVar("PROCESS_NAME")
            user = getShellEnvVar("USER")
            
            ;;; open ~/.plan if exists to get full name and email address
            if( isReadable( "~/.plan") then
                IN = infile("~/.plan")
                while( gets(line IN)
                    when( rexMatchp("^Name:" line)
                        x = parseString( line )
                        myName = buildString(cdr(x))
                    )
                    when( rexMatchp("^Email:" line)
                        x = parseString( line )
                        myEmail = buildString(cdr(x))
                    )
                )
                close(IN)
            else
                myName = "=> enter your name"
                myEmail = "=> enter your email"
            )    

           ; terms = buildString(cv~>sigNames ",")
            cellName = cv~>cellName
            helpUrl = strcat("\\raea1pub208\tcc_docs\\" "12" getchar(process 3) getchar(process 4) "tc\\" cellName "\\index.htm")
            rexCompile( strcat( "_" tp0 ))              
            templateName = parseString(Cell "/")
            templateName = buildString( templateName "_")
            templateName = rexReplace( templateName "" 1 )
            category = nth( 0 parseString(templateName "_"))
           (if (get_pname (getchar process 4)) == "0"
			   cadenceDataBase = (strcat "X1"  getchar(process 4) "TCC")
			   cadenceDataBase = strcat("X" getchar(process 4) "TCC")
			   )
            
            cadenceLib = strcat("pcells" process "_tccqa_lay")
            date = getCurrentTime()
            year = car(last(parseString(date)))

         ;***********************************************************************
         ;***********************  Print Header ********************************* 
         ;*********************************************************************** 
         
            fprintf( OUT ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n
;;\n
;;  Filename: %L        Project: TCC\n
;;\n
;;  Date:  %L    Autogenerated by pckTp02Cdf\n
;;\n
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n
;;\n
;; Copyright Intel Corporation %L\n
;;\n
;; Author:   %L\n
;;\n
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n
;;\n
;; Functional Description:\n
;;\n
;; CDF variables for %L\n
;;\n
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n" cdfFile
             date year myName cv~>cellName)
            ; dbClose(cv)
             
        rexCompile( "Lay" ) ;;; for parsing padrowType         

         ;***********************************************************************
         ;***********************  Print Metadata section ***********************
         ;***********************************************************************


            fprintf( OUT "\n/*BEGIN_TEMPLATE_METADATA\n
<StructureTemplateSummary>\n
        <TEMPLATENAME>%L</TEMPLATENAME>\n
        <CADENCEDATABASE>%L</CADENCEDATABASE>\n
        <CADENCELIBRARY>%L</CADENCELIBRARY>\n
        <OWNER>AMR\\%L</OWNER>\n
        <OWNEREMAIL>%L</OWNEREMAIL>\n
        <DESCRIPTION>No description</DESCRIPTION>\n
        <HELPURL>%L</HELPURL>\n
        <ASSOCPADROWTEMPLATES>%L</ASSOCPADROWTEMPLATES>\n
        <TAPEOUTLABEL>A</TAPEOUTLABEL>\n
        <TERMINALNAMES>%L</TERMINALNAMES>\n
        <CATEGORY>%L</CATEGORY>\n
        <ZONE>%L</ZONE>\n
        <ZONERESTRICTIONEXPR>(zone LIKE '%L*' )</ZONERESTRICTIONEXPR>\n
        <ORIENTATION>R0</ORIENTATION>\n
        <ORIENTATIONEXPR>(orient='R0')</ORIENTATIONEXPR>\n
        <BUSSING>%L</BUSSING>\n
        <CELLNAME>%L</CELLNAME>\n
</StructureTemplateSummary>\n
END_TEMPLATE_METADATA*/\n\n"
        templateName cadenceDataBase cadenceLib upperCase(user) myEmail helpUrl
        rexReplace(padrowType "" 1) terms category strcat(zone "1") zone upperCase(aprMethod) tp0 ) 

            close(OUT)

            ;;; remove unwanted "s:

            system( "sed 's/\"//g' /tmp/cdf > /tmp/cdf1" )
            OUT = outfile( "/tmp/cdf")
            IN = infile("/tmp/cdf1")
            while( gets( line IN)
                fprintf( OUT "%s" line )
            )
            close(IN)

            fprintf( OUT "(let ( LIBRARY CELL cellId cdfId libID)\n
    LIBRARY = %L\n
    CELL = %L\n\n
    unless( cellId = ddGetObj( LIBRARY CELL  )\n" lib tp0)
            fprintf( OUT "        error( \"Could not get cell %s \") )\n" tp0)
            fprintf( OUT "    when( cdfId = cdfGetBaseCellCDF( cellId )\n
        cdfDeleteCDF( cdfId ) )\n\n
     cdfId  = cdfCreateBaseCellCDF( cellId )\n")
    
            ;;; fill in param section
    
            foreach( param cellParams      
                fprintf( OUT "\n\n\t( cdfCreateParam cdfId\n")
                fprintf( OUT "\t\t\t%-15s %L\n" '?name param~>name)
                fprintf( OUT "\t\t\t%-15s %L\n" '?prompt param~>name)
                fprintf( OUT "\t\t\t%-15s %L\n" '?type param~>valueType)
                fprintf( OUT "\t\t\t%-15s %L\n" '?defValue param~>value )
                fprintf( OUT "\t\t\t%-15s %L\n" '?display  "t" )
                fprintf( OUT "\t\t\t%-15s %L\n" '?storeDefault '"yes" )
                fprintf( OUT "\t\t\t%-15s %L)\n" '?editable "t" )
            )

            ;;; add required cdf params
            reqCdfParamNames = list( "padrow" "kernelAlign" "zoneAlign" "zone" "aprMethod" "frtMethod" )
            foreach( cdfPname reqCdfParamNames
                when( !member( cdfPname cellParams~>name)
                    fprintf( OUT "\n\n\t ;;; Required cdf param you may need to edit!!")
                    fprintf( OUT "\n\t( cdfCreateParam cdfId\n")
                    fprintf( OUT "\t\t\t%-15s %L\n" '?name cdfPname)
                    fprintf( OUT "\t\t\t%-15s %L\n" '?prompt cdfPname)
                    fprintf( OUT "\t\t\t%-15s %L\n" '?type "string")
                    when( cdfPname == "aprMethod" || cdfPname ==  "frtMethod"
                        fprintf( OUT "\t\t\t%-15s %L\n" '?defValue "none")
                    )
                    when( cdfPname == "kernelAlign" || cdfPname == "zoneAlign" ||  cdfPname == "zone"
                        fprintf( OUT "\t\t\t%-15s %L\n" '?defValue "CB")
                    )
                    when( cdfPname == "padrow"
                        fprintf( OUT "\t\t\t%-15s %L\n" '?defValue (TcTGetDefaultPadrow)) ;; was  "ST1M15X2BELay"
                    )    
                    fprintf( OUT "\t\t\t%-15s %L\n" '?display '"t" )
                    fprintf( OUT "\t\t\t%-15s %L\n" '?storeDefault '"yes" )
                    fprintf( OUT "\t\t\t%-15s %L)\n" '?editable '"t" )
                )    
            )   
            close(OUT)
            IN = infile("/tmp/cdf")
            newCdf = strcat( Cell "_cdf.il_new")
            OUT = outfile( newCdf )
            while( gets(line IN)
                fprintf( OUT "%s" line )
            )
        ); when create
        
    ;##################################################################################################
    ;################################ Update existing CDF #############################################
    ;##################################################################################################
        
        when( update
            oldCdf = strcat( Cell "_cdf.il")
                
            ;;;; get metadata section from old cdf and update term names
            
            terms = buildString(cv~>sigNames ",")
            newCdf = strcat( Cell "_cdf.il_new")
            unless( create
                (load oldCdf)
            )    
            IN = infile(oldCdf)
            OUT = outfile("/tmp/cdf2")
            newName = ()
            cdfOnly = ()
            while( gets(line IN) && !rexMatchp("END_TEMPLATE_METADATA" line)
                if( rexMatchp("TERMINALNAMES" line) then
                    fprintf( OUT "\t\t <TERMINALNAMES>%L</TERMINALNAMES>\n" terms )
                else
                    fprintf( OUT "%s" line )
                )     
            )
            fprintf( OUT "END_TEMPLATE_METADATA */\n\n" )
            close(OUT)
            close(IN)

            ;;; remove unwanted "s:
            system( "sed 's/\"//g' /tmp/cdf2 > /tmp/cdf" )
            OUT = outfile(newCdf)
            IN = infile("/tmp/cdf")
            while( gets(line IN)
                fprintf( OUT "%s" line )
            )
            close(IN)
           fprintf( OUT "(let ( LIBRARY CELL cellId cdfId libID)\n
    LIBRARY = %L\n
    CELL = %L\n\n
    unless( cellId = ddGetObj( LIBRARY CELL  )\n" lib tp0)
    fprintf( OUT "         error( \"Could not get cell %s \") )\n" tp0)
    fprintf( OUT "     when( cdfId = cdfGetBaseCellCDF( cellId )\n
        cdfDeleteCDF( cdfId ) )\n\n
     cdfId  = cdfCreateBaseCellCDF( cellId )\n")

            cv = dbOpenCellViewByType( lib1 tp0 "layout" "maskLayout" "r")
            cellId = ddGetObj( cv~>libName cv~>cellName)

            ;;; get params from existing cdf file:
            cdfParams = cdfGetCellCDF(cellId)~>parameters

            ;;; get current params from cellView:
            cellParams = reverse(car(last(cv~>prop~>value)))

            foreach( cdfProp cdfParams
                foreach( cellProp cellParams
                    when( cellProp~>name == cdfProp~>name
					   
					   
                       fprintf( OUT "\n\n\t( cdfCreateParam cdfId\n")
                       fprintf( OUT "\t\t\t%-15s %L\n" '?name cellProp~>name)
                       fprintf( OUT "\t\t\t%-15s %L\n" '?prompt cellProp~>name)
                       fprintf( OUT "\t\t\t%-15s %L\n" '?type cdfProp~>paramType)
                       fprintf( OUT "\t\t\t%-15s %L\n" '?defValue cellProp~>value )
					   (if cdfProp~>display
						   fprintf( OUT "\t\t\t%-15s %L\n" '?display  cdfProp~>display )
						   fprintf( OUT "\t\t\t%-15s %L\n" '?display '"t" )
						   )
                       ;; fprintf( OUT "\t\t\t%-15s %L\n" '?display  cdfProp~>display )
                       fprintf( OUT "\t\t\t%-15s %L\n" '?storeDefault '"yes" )
					   (if cdfProp~>editable
						   fprintf( OUT "\t\t\t%-15s %L )\n" '?editable cdfProp~>editable )
						   fprintf( OUT "\t\t\t%-15s %L )\n" '?editable '"t" )
						   )
                       
                    )
                    when( !member( cellProp~>name cdfParams~>name) && !member( cellProp~>name newName)
                       newName = cons( cellProp~>name newName )
                       fprintf( OUT "\n\n /* new item */\n" )
                       fprintf( OUT "\t( cdfCreateParam cdfId\n")
                       fprintf( OUT "\t\t\t%-15s %L\n" '?name cellProp~>name)
                       fprintf( OUT "\t\t\t%-15s %L\n" '?prompt cellProp~>name)
                       fprintf( OUT "\t\t\t%-15s %L\n" '?type cellProp~>valueType)
                       fprintf( OUT  "\t\t\t%-15s %L\n" '?defValue cellProp~>value )
                       fprintf( OUT "\t\t\t%-15s %L\n" '?display  '"t" )
                       fprintf( OUT "\t\t\t%-15s %L\n" '?storeDefault '"yes" )
                       fprintf( OUT "\t\t\t%-15s %L )\n" '?editable '"t" )
                    )
                    when( !member( cdfProp~>name cellParams~>name)  && !member( cdfProp cdfOnly )
                        cdfOnly = cons( cdfProp cdfOnly )
                    )    

                ); inner foreach
             ); outter foreach
             foreach( cdfProp cdfOnly
                fprintf( OUT "\n\n /* not a tp0 param */\n" )
                fprintf( OUT "\t( cdfCreateParam cdfId\n")
                fprintf( OUT "\t\t\t%-15s %L\n" '?name cdfProp~>name)
                fprintf( OUT "\t\t\t%-15s %L\n" '?prompt cdfProp~>name)
                fprintf( OUT "\t\t\t%-15s %L\n" '?type cdfProp~>paramType )
                fprintf( OUT  "\t\t\t%-15s %L\n" '?defValue cdfProp~>defValue )
                fprintf( OUT "\t\t\t%-15s %L\n" '?display  cdfProp~>display )
                fprintf( OUT "\t\t\t%-15s %L\n" '?storeDefault '"yes" )
                fprintf( OUT "\t\t\t%-15s %L )\n" '?editable cdfProp~>editable )
             )    
          ); when
       fprintf( OUT "  \n\t( cdfSaveCDF cdfId )\n)\n")
       dbClose(cv)
       close(IN)
       close(OUT)
       pckInfo( "pcktp02cdf" sprintf( nil "Review new cdf file %L, and if correct copy to %L" strcat( Cell "_cdf.il_new") strcat( Cell "_cdf.il"))) 
    ); let
); defun    
defun(  pckGetLibrary ( tmplt )
    let( (fh line library retVal)
        rexCompile( "(" )
        if( isReadable(tmplt) then
            fh = infile(tmplt)
            while( gets(line fh)
                when( rexMatchp("ddGetObj" line )
                        library = rexReplace(line " " 1-3)
                        rexCompile( ")" )
                        library = rexReplace(line " " 1-3)
                        if( rexMatchp("list" line)
                            library = nth(2 parseString(library))
                            library = nth(1 parseString(library))
                        )    
                        library = stringToSymbol(library)
                        close(fh)
                )
            )
            retVal = library
        else
            pckError( "tp02cdf" sprintf( nil "File %L is missing or read protected" tmplt))
        )    
    )
) 

;;****f* pckLayoutFunctions/pckHierarchyErrorCheck
;;
;; FUNCTION
;;
;; pckHierarchyErrorCheck - Determine the type of the error and location in the Hierarchy
;;
;; USAGE
;;
;; pckHierarchyErrorCheck "<instance ID>"
;;
;;****

(defun pckHierarchyErrorCheck ( instanceId )
  (setq errShapes (setof shapes instanceId~>master~>shapes (equal "error" shapes~>purpose)))
  (foreach errShape errShapes
   (pckError "pckHierarchyErrorCheck" (sprintf nil "Cell Name %s Failed with  Error: %s " errShape~>cellView~>cellName errShape~>theLabel ))
  );foreach
  (setq errInstances (setof instances instanceId~>master~>instances (member "error" instances~>master~>layerPurposePairs~>purpose)))
  (foreach errInstanceId errInstances
   (pckHierarchyErrorCheck errInstanceId)
  )
  t
)

;;****f* pckLayoutFunctions/pckRefreshCellViews
;;
;; FUNCTION
;;
;; pckRefreshCellViews -Function to refresh the cellview virtual memory( to sync with updates made by different prcoess)
;;
;; USAGE
;; 
;; pckRefreshCellViews (optional) "<time in seconds>"
;;
;; EXAMPLE:
;; ( pckRefreshCellViews )
;;           OR
;; ( pckRefreshCellViews 60 ) -- Refreshes all the opencellviews every minute
;;
;;****

(defun pckRefreshCellViews (@optional sec )

  ;;get all the open cellviews
  (setq allCellViews (dbGetOpenCellViews) )

  ;; Filter cellviews which need refresh
  (setq cellViews (setof allCellViews allCellViews (equal allCellViews~>needRefresh t)))

  (foreach cellView cellViews
    (dbRefreshCellView cellView )
    (pckInfo "pckRefreshCellViews" (sprintf nil "Updated Cellview %s" cellView->cellName ))
  )

  ;;If time is specified for auto refresh, register an event for the time
  (when sec
    (hiRegTimer (sprintf nil "(pckRefreshCellViews %n )" sec ) (times 10 sec ) )
    (pckInfo "pckRefreshCellViews" (sprintf nil "Auto-Update cellViews in %n Seconds" sec) )
  )
  t
)

;;FUNCTION
;;
;;pckGetHierTransform - Function to search and pull the instance transform to the top level 
;;
;;USAGE
;;
;;pckGetHierTransform "<instance name like>" "<toplevel cvid>"
;; 
;;EXAMPLE
;;(pckGetHierTransform "auxpoly*" instId)

(defun pckGetHierTransform (instNameLike cvId )
  (let (hierTransform)
    (setq instances (setof instances cvId~>master~>instances (rexMatchp instNameLike instances~>cellName)))
    (setq hierTransform nil)
    (if instances
        (progn
          (setq instance (car instances))
          (setq hierTransform (dbConcatTransform instance~>transform cvId~>transform))
          );;if progn
      (prog ()
       (foreach instance cvId~>master~>instances
		(setq hierTransform (pckGetHierTransform instNameLike instance))
		(when hierTransform
		  (setq hierTransform (dbConcatTransform hierTransform cvId~>transform ))
          (fprintf stdout ">>> Found cell: %L %L\n" instance~>?? cvId~>??)
		  ;;return and break the loop
		  (return hierTransform)
		  )
		)
       );;else prog
      );;if
    hierTransform
    );;let
);;pckGetHierTransform

;;FUNCTION
;;
;;pckSnapPolyDiffToGrid - Function to search polyFrame and snap to global grid
;;
;;USAGE
;;
;;pckSnapPolyDiffToGrid "<instance id>"
;;
;;EXAMPLE
;;
;;(pckSnapPolyDiffToGrid instId)

(defun pckSnapPolyDiffToGrid (cvId namePattern)
  (let (xsnap ysnap polyPitch diffPitch polyTransform)
    (pckInfo "pckSnapPolyDiffToGrid" "calling pckGetHierTransform elnsvfor polyframe search")
    (setq polyTransform (pckGetHierTransform namePattern cvId ))
    (setq polyPitch (pckGetPolyGrid))
    (setq diffPitch (pckGetHalfDiffGrid))
    (if (and polyTransform polyPitch diffPitch)
        (progn
          (pckInfo "pckSnapPolyDiffToGrid"
                   (sprintf nil "polyFrame Found at %L" (car polyTransform)))
          (setq xsnap (difference
		       (pckPutOnGrid (rodPointX (car polyTransform)) polyPitch)
                       (rodPointX (car polyTransform)))
                     )
          (setq ysnap (difference
		       (pckPutOnGrid (rodPointY (car polyTransform)) diffPitch)
                       (rodPointY (car polyTransform))
                       )
                )
          (pckInfo "pckSnapPolyDiffToGrid" (sprintf nil "Moving Instance %s by X:%f Y:%f" cvId~>cellName xsnap ysnap))
          (dbMoveFig cvId nil (list (list xsnap ysnap) "R0"))
          );;progn
      (progn
        (pckInfo "pckSnapToGrid" "polyFrame Not Found" )
        );;progn
      );;if
    t
    );;let
);;pckSnapPolyDiffToGrid


;;FUNCTION
;;
;;pckSnapFrameToGrid - Function to look for frames and snap them to global grid
;;Priority- 1. polydiffgrid
;;          2. Metalgrid
;;
;;USAGE
;;
;;pckSnapFrameToGrid "<instId>"
;;
;;EXAMPLE
;;
;;(pckSnapFrameToGrid instId)
(defun pckSnapFrameToGrid (cvId)
  (let ()
    (case (pckGetProcessId)
      ;;case - 1
      ( "1272" 
	(pckInfo "pckSnapFrameToGrid"
             "Calling pckSnapPolyDiffToGrid to search and snap poly and diffusion to grid")	
	;;call poly diff Frame
	(pckSnapPolyDiffToGrid cvId "auxPoly*")
	;;TODO metal Frame Snap
	)
      ("1270"
       (pckInfo "pckSnapFrameToGrid"
                "Calling pckSnapPolyDiffToGrid to search and snap poly and diffusion to grid")
       (pckSnapPolyDiffToGrid cvId "auxPolyFrame*")
       )
      ;;case - 2
      ( ("1265" "1266" "1268" "1269" "1271")
	(pckInfo "pckSnapFrameToGrid"
             (sprintf nil "Skipping FrameGrid Snapping for Process %s" (pckGetProcessId)))
	)
      ;;default case
      ( t
	(pckInfo "pckSnapFrameToGrid" "Skipping Frame grid snapping")
	)
      );;case
    t
    );;
);;pckSnapFrameToGrid