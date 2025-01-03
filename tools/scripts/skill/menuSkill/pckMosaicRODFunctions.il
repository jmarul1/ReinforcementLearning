;****h* TCC/pckRODMosaicFunctions
;; NAME
;; pckMosaicRodFunctions - collection of general purpose ROD funtions used on mosaics.
;;
;; AUTHOR
;; Robert Rice
;;
;; COPYRIGHT
;; Intel Corporation 2007
;;
;; USAGE
;; load "pckMosaicRodFunctions.il"
;;
;; KEYWORDS: TCC Project, ROD, Mosaic
;;****

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
