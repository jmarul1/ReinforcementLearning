;;****h* TCC/pckRODFunctions
;; NAME
;; pckRODFunctions - collection of general purpose ROD objects.
;;
;; AUTHOR 
;; Pavel Rott
;;
;; COPYRIGHT 
;; Intel Corporation 2004
;;
;; USAGE
;; load "pckRODFunctions.il"
;;
;; KEYWORDS: TCC Project, MOS, DSR
;;****

;;****f* pckRODFunctions/pckGetRodDistX
;;
;; FUNCTION
;;
;; pckGetRodDistX - returns distance in X  between specified handles of 2 objects
;;
;; USAGE
;;
;; (pckGetRodDistX "SomeShape" "ApyFrame/Apy_1/pySeg" ?ctId cv ?firstHandle "lowerLeft" ?secondHandle "upperRight")
;;
;;****
(defun pckGetRodDistX ( firstObj secondObj @key (ctId pcCellView) (firstHandle "centerCenter") (secondHandle "centerCenter"))
  "Returns absolute distance in X between 2 ROD objects. => f_float"
  (abs (difference (rodPointX (get (rodGetObj firstObj ctId) firstHandle))
	 (rodPointX (get (rodGetObj secondObj ctId) secondHandle)))))

;;****f* pckRODFunctions/pckGetRodDistY
;;
;; FUNCTION
;;
;; pckGetRodDistY - returns distance in Y  between specified handles of 2 objects
;;
;; USAGE
;;
;; (pckGetRodDistY "SomeShape" "ApyFrame/Apy_1/pySeg" ?ctId cv ?firstHandle "lowerLeft" ?secondHandle "upperRight")
;;
;;**** 
(defun pckGetRodDistY ( firstObj secondObj @key (ctId pcCellView) (firstHandle "centerCenter") (secondHandle "centerCenter"))
  "Returns absolute distance in Y between 2 ROD objects. => f_float"
  (abs (difference (rodPointY (get (rodGetObj firstObj ctId) firstHandle))
                   (rodPointY (get (rodGetObj secondObj ctId) secondHandle)))))

;;****f* pckRODFunctions/pckAlignedRodArray
;;
;; FUNCTION
;;
;; pckAlignedRodArray - creates an array of ROD rectangles and aligns them; returns rodId of lowerLeft rectangle in array
;;
;; USAGE
;;
;; Default values of args shown below
;;   (pckAlignedRodArray
;;    ?cvId pcCellView
;;    ?layer '("via0" "drawing")
;;    ?name "myROD"
;;    ?width 1.0
;;    ?length 1.0
;;    ?origin 0.0:0.0
;;    ?spaceX 0.0
;;    ?spaceY 0.0
;;    ?elementsX 1
;;    ?elementsY 1
;;    ?fillBBox '(nil))
;;
;;**** 
(defun pckAlignedRodArray (@key (cvId pcCellView) (layer '("via0" "drawing")) (name "myROD") (width 1.0) (length 1.0) (origin '(0.0 0.0)) (spaceX 0.0) (spaceY 0.0) (elementsX 1) (elementsY 1) (fillBBox '(nil)))
  "Creates an array of ROD rectangles and aligns them; returns rodId of lowerLeft rectangle in array => rodId"
  (let ()
    (if (car fillBBox)
        (progn
          (rodCreateRect
           ?cvId cvId
           ?layer layer
           ?name name
           ?width width
           ?length length
           ?spaceX spaceX
           ?spaceY spaceY
           ?fillBBox fillBBox)
          (setq elementsX (pcFix ((xCoord (trBBoxDims fillBBox))+spaceX)/(spaceX+width)))
          (setq elementsY (pcFix ((yCoord (trBBoxDims fillBBox))+spaceY)/(spaceY+width))))
        (rodCreateRect
         ?cvId cvId
         ?layer layer
         ?name name
         ?width width
         ?length length
         ?spaceX spaceX
         ?spaceY spaceY
         ?origin origin
         ?elementsX elementsX
         ?elementsY elementsY))
    (cond 
      ((pckGEQP elementsX 2)
       (for j 1 elementsY
            (for i 2 elementsX
                 (rodAlign
                  ?refObj (if (pckGEQP elementsY 2)
                              (rodGetObj (strcat name (sprintf nil ".%L.%L" i-1 j)) cvId)
                              (rodGetObj (strcat name (sprintf nil ".%L" i-1)) cvId))
                  ?refHandle "lowerRight"
                  ?alignObj (if (pckGEQP elementsY 2)
                                (rodGetObj (strcat name (sprintf nil ".%L.%L" i j)) cvId)
                                (rodGetObj (strcat name (sprintf nil ".%L" i)) cvId))
                  ?alignHandle "lowerLeft"
                  ?xSep spaceX))
            (when (pckGEQP j 2)
              (rodAlign
               ?refObj (rodGetObj (strcat name (sprintf nil ".1.%L" j-1)) cvId)
               ?refHandle "upperLeft"
               ?alignObj (rodGetObj (strcat name (sprintf nil ".1.%L" j)) cvId)
               ?alignHandle "lowerLeft"
               ?ySep spaceY)))
       (if (and (pckGEQP elementsX 2) (pckGEQP elementsY 2))
           (rodGetObj (strcat name ".1.1") cvId)
           (rodGetObj (strcat name ".1") cvId)))
       ((pckGEQP elementsY 2)
        (for i 2 elementsY
             (rodAlign
              ?refObj (rodGetObj (strcat name (sprintf nil ".%L" i-1)) cvId)
              ?refHandle "upperLeft"
              ?alignObj (rodGetObj (strcat name (sprintf nil ".%L" i)) cvId)
              ?alignHandle "lowerLeft"
              ?ySep spaceY))
        (rodGetObj (strcat name ".1") cvId))
       (t
        (rodGetObj name cvId)))))
;;
;; Create a donut based to 2 bboxes

(defun pckRODDrawHole (cvId lpp boxOut boxIn)
  "Creates a torus shape based on 2 bounding box inputs. Returns rodId of right center rectangle. => rodId"
  (rodCreateRect
   ?cvId cvId
   ?layer lpp
   ?bBox (list
		  (car boxOut)
		  (list
		   (xCoord (cadr boxOut))
		   (yCoord (car boxIn))))
   )
  (rodCreateRect
   ?cvId cvId
   ?layer lpp
   ?bBox (list
		  (car boxIn)
		  (list
		   (xCoord (car boxOut))
		   (yCoord (cadr boxIn))))
   )
  (rodCreateRect
   ?cvId cvId
   ?layer lpp
   ?bBox (list
		  (cadr boxOut)
		  (list
		   (xCoord (car boxOut))
		   (yCoord (cadr boxIn))))
   )
  (rodCreateRect
   ?cvId cvId
   ?layer lpp
   ?bBox (list
		  (cadr boxIn)
		  (list
		   (xCoord (cadr boxOut))
		   (yCoord (car boxIn))))
   )

  )
;;****f* pckRODFunctions/pckRodAddNT
;;
;; FUNCTION
;;
;; pckRodAddNT - Creates rod object in "needTermCells" layer that matches line-on-line rod object or
;;      offsets user specified edge for narrow metal. Will only create needTermCell object if the
;;      specified layer requires banana lines.
;;
;; USAGE
;;
;; Default values of args shown below
;;   (pckRodAddNT
;;    ?cvId pcCellView
;;    ??offsetSide "none" - choices are "R" "L" "T" "B"
;;    ?name "myROD"
;;    ?spaceX 0.0
;;    ?spaceY 0.0
;;    ?elementsX 1
;;    ?elementsY 1
;;****
defun( pckRodAddNT (@key (cvId pcCellView) (name "myROD") (offsetSide "none")
                        (elementsX 1) (elementsY 1) (spaceX 0.0 ) (spaceY 0.0 ))
    "Creates duplicate of named rod shape in needTermLayer. Offset side references NT pull-back"               
    (let (x0 y0 x1 y1 bb lyr l w)
        bb = rodGetObj( name cvId )~>dbId~>bBox
        lyr = rodGetObj( name cvId )~>dbId~>layerName
        x0 = caar(bb)
        y0 = cadar(bb)
        x1 = caadr(bb)
        y1 = cadadr(bb)
        w = rodGetObj( name cvId )~>width
        l = rodGetObj( name cvId )~>length
        when(  pckNeedCfTf( lyr) 
            cond( 
                ( zerop( strncmp(offsetSide "R" 1)) || zerop( strncmp( offsetSide "r" 1))
                    x1 = x1 - pckGetBSpullback( pckLayerInfo( nil "minWidthNX" lyr) lyr)
                )
                ( zerop( strncmp( offsetSide "L" 1)) || zerop( strncmp( offsetSide "l" 1))
                    x0 = x0 + pckGetBSpullback( pckLayerInfo( nil "minWidthNX" lyr) lyr)
                )
                (  zerop( strncmp( offsetSide "B" 1)) || zerop( strncmp(offsetSide "b" 1))
                    y0 = y0 + pckGetBSpullback( pckLayerInfo( nil "minWidthNX" lyr) lyr)
                )
                ( zerop( strncmp( offsetSide "T" 1)) || zerop( strncmp(offsetSide "t" 1))
                    y1 = y1 - pckGetBSpullback( pckLayerInfo( nil "minWidthNX" lyr) lyr)
                )
                ( zerop( strncmp( offsetSide "none" 4))
                )
                ( t
                    pckDebug( "pckRodAddNT" sprintf( nil "%L not a valid entry" offsetSide))
                )
            )

            rodCreateRect( ?cvId cvId ?name strcat( name "_NT" ) ?layer list( lyr "needTermCells")
                ?bBox list( x0:y0 x1:y1 )
                ?elementsX elementsX
                ?elementsY elementsY
                ?spaceX spaceX
                ?spaceY spaceY
            )
        ); when    
   t ); let
); end function

;;****f* pckRODFunctions/pckRodAddFUT
;;
;; FUNCTION
;;
;; pckRodAddFUT - Creates rod object in "FeatureUnderTest" layer that matches line-on-line rod object in ?name argument
;;
;; USAGE
;;
;; Default values of args shown below
;;   (pckRodAddNT
;;    ?cvId pcCellView
;;    ?name "myROD"
;;    ?spaceX 0.0
;;    ?spaceY 0.0
;;    ?elementsX 1
;;    ?elementsY 1
;;****
(defun pckRodAddFUT (@key (cvId pcCellView) (name "myROD")
                        (elementsX 1) (elementsY 1) (spaceX 0.0 ) (spaceY 0.0 ))
  "Creates duplicate of named rod shape in FeatureUnderTest. "
    (let ()
        (rodCreateRect ?cvId cvId ?name (strcat name "_FUT") 
            ?layer (list (rodGetObj name cvId )~>dbId~>layerName "FeatureUnderTest")
            ?bBox (rodGetObj name cvId )~>dbId~>bBox
            ?elementsX elementsX
            ?elementsY elementsY
            ?spaceX spaceX
            ?spaceY spaceY
       )
    ); end let
); end function


;;****f* pckRODFunctions/pckMosaicRodAlign
;;
;; FUNCTION
;;
;; pckMosaicRodAlign aligns rod object to reference object imbedded in a mosaic
;;
;; USAGE
;; 
;; Default values of args shown below
;; (pckMosaicRodAlign alignObject refObject
;;      ?row 1 - row of mosaic
;;      ?col 1 - column of mosaic
;;      ?deltaX 0.0 - width in X of unit cell
;;      ?deltaY 0.0 - width in Y of unit cell
;;      ?cvId pcCellView
;;      ?alignHandle "cC"
;;      ?refHandle "cC"
;;      ?xSep 0.0
;;      ?ySep 0.0)
;;      
;;****

(defun pckMosaicRodAlign (alignObject refObject @key  (row 1) (col 1 )
                         
	( deltaX 0.0 ) (deltaY 0.0 )  (cvId pcCellView) (alignHandle "cC") 
	(refHandle "cC") (xSep 0.0) (ySep 0.0))
  "Aligns a rod object to a reference object within a mosaic." 
    (let ()
	(rodAlign ?alignObj (rodGetObj alignObject cvId) ?alignHandle alignHandle
		?refObj (rodGetObj refObject cvId )
		?refHandle refHandle
		?xSep (plus (times (difference col 1) deltaX) xSep)
		?ySep (plus (times (difference row 1) deltaY) ySep))
    ); let
); defun	
	
;;****f* pckRODFunctions/pckMosaicRodPointX
;;
;; FUNCTION
;;
;; pckMosaicRodPointX returns X point of rod object imbedded in a mosaic
;;
;; USAGE
;;
;;  Default values of args shown below
;;  (pckMosaicRodPointX rodObject
;;        ?col 1 - column of mosaic containing rodObject
;;        ?deltaX - width in X of unit cell
;;        ?cvId pcCellView
;;        ?rodPoint "cC" )

(defun pckMosaicRodPointX (rodObject @key  (col 1 ) 
	( deltaX 0 ) (cvId pcCellView) (rodPoint "cC"))
  "Returns X value of point within a ROD mosaic. => f_float"
    (let ()
        (plus (car (get (rodGetObj rodObject cvId) rodPoint)) 
            (times (difference col 1) deltaX))
    ); let
); defun	 

;;****f* pckRODFunctions/pckMosaicRodPointY
;;
;; FUNCTION
;;
;; pckMosaicRodPointY returns Y point of rod object imbedded in a mosaic
;;
;; USAGE
;;
;;  Default values of args shown below
;;  (pckMosaicRodPointY rodObject
;;        ?row 1 - row of mosaic containing rodObject
;;        ?deltaY - width in Y of unit cell
;;        ?cvId pcCellView
;;        ?rodPoint "cC" )


(defun pckMosaicRodPointY (rodObject @key  (row 1)  
	( deltaY 0.0 ) (cvId pcCellView) (rodPoint "cC"))
  "Returns Y value of point within a ROD mosaic. => f_float"
    (let ()
	(plus (cadr (get (rodGetObj rodObject cvId) rodPoint))
            (times (difference row 1) deltaY))
    ); let
); defun

;;****f* pckRODFunctions/pckMosaicRodDistX
;;
;; FUNCTION
;;
;; pckMosaicRodDistX returns distance in X  between two rod objects when one or both are embedded in same or
;;     different mosaics
;;
;; USAGE
;;
;;  Default values of args shown below
;;  (pckMosaicRodDistX rodObject1 rodObject2
;;      ?col1 1 - mosaic column of 1st rodObject
;;      ?col2 1 - mosaic column of 2nd rodObject
;;      ?cvId pcCellView
;;      ?rodPoint1 "cC"
;;      ?rodPoint2 "cC"
;;      ?delta1X - width in X of unit cell in 1st mosaic
;;      ?delta2X - width in X of unit cell in 2st mosaic
;;      )

(defun pckMosaicRodDistX (rodObject1 rodObject2 @key  (col1 1 )
        (col2 1 ) (cvId pcCellView ) (rodPoint1 "cC" ) (rodPoint2 "cC")
	    (delta1X 0.0) (delta2X 0.0))
  "Returns absolute distance in X between 2 points within a mosaic, or a point within a mosaic and a point 
   outside the mosaic. => f_loat"
    (let ( X1 X2)
	(when (equal rodObject2 nil) (setq rodObject2 rodObject1) ;;; only 1 mosiac referenced.
             (setq delta2X delta1X))
	( setq X1 (plus (car (get (rodGetObj rodObject1 cvId) rodPoint1))
	    (times delta1X (difference col1 1))))
    ( setq X2 (plus (car (get (rodGetObj rodObject2 cvId) rodPoint2))
	    (times delta2X (difference col2 1))))
     ( abs (difference X2 X1 ))
    ); let
); defun 	
         
;;****f* pckRODFunctions/pckMosaicRodDistY
;;
;; FUNCTION
;;
;; pckMosaicRodDistY returns distance in Y  between two rod objects when one or both are embedded in same or
;;     different mosaics
;;
;; USAGE
;;
;;  Default values of args shown below
;;  (pckMosaicRodDistY rodObject1 rodObject2
;;      ?row1 1 - mosaic row of 1st rodObject
;;      ?row 1 - mosaic row of 2nd rodObject
;;      ?cvId pcCellView
;;      ?rodPoint1 "cC"
;;      ?rodPoint2 "cC"
;;      ?delta1Y - width in Y of unit cell in 1st mosaic
;;      ?delta2Y - width in Y of unit cell in 2st mosaic
;;      )
    
(defun pckMosaicRodDistY (rodObject1 rodObject2 @key  (row1 1 )
        (row2 1 ) (cvId pcCellView ) (rodPoint1 "cC" ) (rodPoint2 "cC")
	    (delta1Y 0.0) (delta2Y 0.0))
  "Returns absolute distance in Y between 2 points within a mosaic, or a point within a mosaic and a point 
   outside the mosaic. => f_loat"
    (let ( Y1 Y2)
	(when (equal rodObject2 nil ) (setq rodObject2 rodObject1)
             (setq delta2Y delta1Y))
    (when (equal delta2Y 0.0 ) (setq delta2Y delta1Y))         
	( setq Y1 (plus (cadr (get (rodGetObj rodObject1 cvId) rodPoint1))
	    (times delta1Y (difference row1 1))))
    ( setq Y2 (plus (cadr (get (rodGetObj rodObject2 cvId) rodPoint2))
	    (times delta2Y (difference row2 1))))
    (abs ( difference Y2 Y1 ))
    ); let
); defun	


;;****f* pckRODFunctions/pckRodCreatePin
;;
;; FUNCTION
;; Creates pin from rod object
;;
;;
;; USAGE
;;
;;  Default values of args shown below^M
;;  (pckRodCreatePin cv rodName pinName)
;;
;;

(defun pckRodCreatePin ( cv rodName pinName)
  "Creates pin from ROD object"
  (let (layer ll ur)
    layer  = (rodGetObj rodName cv)~>dbId~>layerName
    ll = (rodGetObj rodName cv)~>"lL"
    ur = (rodGetObj rodName cv)~>"uR"
    (pckCreatePin cv pinName layer "drawing" (list ll ur) "inputOutput")
    );; let
  );; defun


;; defun