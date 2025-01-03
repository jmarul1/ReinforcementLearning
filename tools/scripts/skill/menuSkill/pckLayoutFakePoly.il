;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Filename: pckLayoutFakePoly.il             Project: TCC
;; 
;;  Version: $Id: pckLayoutFakePoly.il.rca 1.1 Fri Dec 10 15:47:48 2010 pvrott Experimental $
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; Copyright Intel Corporation 2004
;;
;; Author: Pavel Rott
;; Keywords: TCC Project
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Functional Description:
;;
;; Creates a fake poly lines in a testrow layout
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; For testing in TCCQA or Production environment:
;; load strcat("/prj/tccdev/work_areas/" getShellEnvVar("USER") "/tccdev/tcc_collateral/skill/pckLayoutFakePoly.il")
;;
;; (load "pckLayoutFakePoly.il")
;;

(defun pckLayoutFakePoly ( libName cellName )
  "Draw fake poly/diffusion grid in a cell view. This function is used in pckLayoutPostProcessing step."
  (let (x (y 0) ctId pyOffset
          (polyWidth (pckLayerInfo MOS_LIB "minWidthX" "poly" ))
          (polyPitch (pckGetPolyGrid))
          (diffGridWidth (pckLayerInfo MOS_LIB "minWidthY" "diffusion" ) )
          (diffGridPitch (pckGetDiffGrid))
          padrow padInfo)

	(setq ctId (dbOpenCellViewByType libName cellName "layout" "maskLayout" "a" ))
	padrow = (getq ctId~>tcc_dpl "PadrowType") ;; padrow type used
	(setq padInfo (pckGetPadInfo libName padrow ))
	;;********************************************************************************
	;;
	;; Start Drawing blya !
	;;
	;;********************************************************************************
	(setq x (pckGetPolyOffset))
	(while ( pckLEQP x padInfo->row_width - polyWidth )
      (dbCreateRect ctId (list "poly" "testRow" ) list(x:y x+polyWidth:y+padInfo->row_height) )
      x = x + polyPitch
      )
    (setq x 0)
    (setq y (pckGetProcessInfo "TR_DIFF_OFFSET"))
    (while ( pckLEQP y padInfo->row_height - diffGridWidth )
      (dbCreateRect ctId (list "diffusion" "testRow" )
                    (list (list 0 y)  (list padInfo->row_width (plus y diffGridWidth))))
      ;;
      ;; drawing diff grid check lines for diffusion edges
      ;; could have run another loop; offsets are caused by keeping everythign
      ;; in single while
      (dbCreateLine ctId (list "diffusion" "testRow" )
                    (list (list 0 (plus y diffGridWidth/2.0)) (list padInfo->row_width (plus y diffGridWidth/2.0)))
                    )      
      (dbCreateLine ctId (list "diffusion" "testRow" )
                    (list
                     (list 0
                           (difference y (pckGetProcessInfo "TR_DIFF_OFFSET")))
                     (list padInfo->row_width
                           (difference y (pckGetProcessInfo "TR_DIFF_OFFSET"))))
                    )
      (setq y (plus y diffGridPitch))
      )

    
	(dbSave ctId)
	(dbClose ctId)
	t
  );; let
);; defun

;; ************************************************************************************
;; Draw fake poly for a single cell - assumption is that cell origin will be on poly grid in the end
;; Only draws up and to right of origin, area to left and below will not get covered in fake poly

(defun pckLayoutFakePolyByCell ( libName cellName )
  (let (x (y 0) ctId pyOffset polyWidth polyPitch height width)
	pyOffset = (pckGetPolyOffset)
	polyPitch = (pckGetPolyGrid)
	polyWidth = (pckLayerInfo MOS_LIB "minWidthX" "poly" )
	ctId = (dbOpenCellViewByType libName cellName "layout" "maskLayout" "a" )

	width = (car (cadr ctId~>bBox))
    height = (cadr (cadr ctId~>bBox))

	;;********************************************************************************
	;;
	;; Start Drawing blya !
	;;
	;;********************************************************************************
    (setq x (pckGetPolyOffset))
	(while (pckLEQP x width - polyWidth )
      (dbCreateRect ctId (list "poly" "testRow" ) (list x:y x+polyWidth:y+height) )
      x = x + polyPitch
      )    
	(dbSave ctId)
	(dbClose ctId)
	t
  );; let
);; defun


(defun pckAddFakePoly (cv form)
  "Draw fake poly/diffusion check in a cell view using dimensions from Draw Poly grid form."
  (let ( x (y 0) pyOffset polyPitch polyWidth
           (diffGridWidth (pckLayerInfo MOS_LIB "minWidthY" "diffusion" ) )
           (diffGridPitch (pckGetDiffGrid))
           )
	(setq pyOffset (pckGetPolyOffset))
	(setq polyPitch (pckGetPolyGrid))
	(setq polyWidth (pckLayerInfo MOS_LIB "minWidthX" "poly"))

	x = pyOffset
	(while ( pckLEQP x form->fakePolyAreaWX->value - polyWidth )
	  ;; 05-17-2005 BUGFIX: Change height (y) to fakePolyAreaWY->value (was X instead, typo!)
	  (dbCreateRect cv list( "poly" "testRow" ) list(x:y x+polyWidth:y+form->fakePolyAreaWY->value) )
	  x = x + polyPitch
	  )
	(setq x 0)
    (setq y (pckGetProcessInfo "TR_DIFF_OFFSET"))
    
    (while (pckLEQP y form->fakePolyAreaWY->value - diffGridWidth )
      (dbCreateRect cv (list "diffusion" "testRow" )
                    (list (list 0 y)  (list form->fakePolyAreaWX->value (plus y diffGridWidth))))
      ;;
      ;; drawing diff grid check lines for diffusion edges
      ;; could have run another loop; offsets are caused by keeping everythign
      ;; in single while
      (dbCreateLine cv (list "diffusion" "testRow" )
                    (list (list 0 (plus y diffGridWidth/2.0)) (list form->fakePolyAreaWX->value (plus y diffGridWidth/2.0)))
                    )      
      (dbCreateLine cv (list "diffusion" "testRow" )
                    (list
                     (list 0
                           (difference y (pckGetProcessInfo "TR_DIFF_OFFSET")))
                     (list form->fakePolyAreaWX->value
                           (difference y (pckGetProcessInfo "TR_DIFF_OFFSET"))))
                    )
      (setq y (plus y diffGridPitch))
      )
	(dbSave cv)
	t
	)
)
(defun pckAddPolyGridBBox (cv)
  (let (x1 x2 y1 y2 x bBox pyOffset polyPitch polyWidth existingFakePoly)
	;;existingPoly = setof( shapes cv~>shapes rexMatchp( ("poly" "testRow") shape~>llp) )

	(unless (equal cv~>mode "r" )
	  existingFakePoly = setof( shape cv~>shapes (and (rexMatchp "testRow" shape~>purpose) (rexMatchp "poly" shape~>layerName) ) ) 
	  foreach( shape existingFakePoly
					 dbDeleteObject( shape ) )
	  
	  pyOffset = pckGetPolyOffset()
	  polyPitch = pckGetPolyGrid()
	  polyWidth = pckLayerInfo( MOS_LIB "minWidthX" "poly" )
	
	
	  if( bBox = cv~>bBox
			   (progn 
				 x1 = xCoord( lowerLeft( bBox ) )
				 x1 = ceiling( x1 / polyPitch ) * polyPitch
				 x2 = xCoord( upperRight( bBox ) )
				 y1 = yCoord( lowerLeft( bBox ) )
				 y2 = yCoord( upperRight( bBox ) ) )
			   (progn 
				 x1 = 0.0
				 x2 = 300*polyPitch
				 y1 = 0.0
				 y2 = 252.0 ) )
	  
	  
	  x = x1 + pyOffset
	  (while ( pckLEQP x x2 - polyWidth )
		dbCreateRect( cv list( "poly" "testRow" ) list(x:y1 x+polyWidth:y2) )
		x = x + polyPitch
		)
	  
	  dbSave(cv)
	  )
	t
	)
  )
;;; pckLayoutFakePoly.il ends here
