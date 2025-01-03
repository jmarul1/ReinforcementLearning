;;
;; (load "pckBuildMFCTestCase.il")
;;
;;
/*

(pckBuildMFCArray "fdk71pxprimtemplate" "b8xmfca0hva5" "pvrott_px" "b8xmfca0hva5" ?yflip "y" )

*/

(defun pckBuildMFCArray (source_lib source_cell tlib tcell @key (arx 3) (ary 3) (drx 0.0) (dry 0.0) (cell_suf "_3x3") (xflip "y") (yflip "n"))
  (let (x y cv tcv wx wy i j orient)
	(unless  (setq cv (dbOpenCellViewByType source_lib source_cell "layout"))
	  (pckDebug "pckBuildMFCArray" (sprintf nil "Cannot open cell %L %L" source_lib source_cell))
	  (exit)
	  )
	(setq tcell (strcat tcell cell_suf))
	(unless  (setq tcv (dbOpenCellViewByType tlib tcell "layout" "maskLayout" "w"))
	  (pckDebug "pckBuildMFCArray" (sprintf nil "Cannot open cell %L %L" tlib tcell))
	  (exit)
	  )

	(setq wx (plus drx (car (trBBoxDims (getSGq cv "bBox")))))
	(setq wy (plus dry (cadr (trBBoxDims (getSGq cv "bBox")))))
	(unless (and wx wy)
	  (pckDebug "pckBuildMFCArray" (sprintf nil "BBox dimensions of %L %L cannot be used in their form: %L %L" source_lib source_cell wx wy)))
	(for j 1 ary
		 (for i 1 arx
				(setq orient "R0")
				(case yflip
				  ("n"
				   (case (oddp j)
					 (nil (setq orient "MX"))
					 (t (setq orient "R0"))
					 )
				   )
				  ("y"
				   (cond
					((and (oddp i) (oddp j)) ;; 1.1
					 (setq orient "R0")
					 )
					((and (evenp i) (oddp j)) ;; 2.1
					 (setq orient "MY")
					 )
					((and (oddp i) (evenp j)) ;; 1.2
					 (setq orient "MX")
					 )
					((and (evenp i) (evenp j)) ;; 2.2
					 (setq orient "R180")
					 )
					)
				   )
				  )
				(dbCreateInst tcv cv
                     (get_pname (concat "mfc_inst." i "." j))
                     (list 0.0 0.0) orient)
				(fprintf stdout "%d %d %f %f\n" i j
						 (sub1 i) *wx
						 (sub1 j) *wy)
				(when (or (nequal i 1) (nequal j 1))
				  (case i
					(1
					 (rodAlign ?alignObj
						  (rodGetObj (get_pname (concat "mfc_inst." i "." j)) tcv)
						  ?alignHandle "lowerLeft"
						  ?refObj
						  (rodGetObj
						   (get_pname (concat "mfc_inst." i "." (sub1 j))) tcv)
						  ?refHandle "upperLeft"
						  ?xSep 0.0
						  ?ySep dry
						  )
					 )
					(t
					 (rodAlign ?alignObj
						  (rodGetObj (get_pname (concat "mfc_inst." i "." j)) tcv)
						  ?alignHandle "lowerLeft"
						  ?refObj
						  (rodGetObj
						   (get_pname (concat "mfc_inst." (sub1 i) "." j)) tcv)
						  ?refHandle "lowerRight"
						  ?xSep drx
						  ?ySep 0.0
						  )
					 )
					)
				  )
				;; (rodAlign ?alignObj
				;; 		  (rodGetObj (get_pname (concat "mfc_inst." i "." j)) tcv)
				;; 		  ?alignHandle "lowerLeft"
				;; 		  ?refPoint (list (sub1 i) *wx
				;; 						  (sub1 j) *wy )
				;; 		  )
			  )
		 )
	(dbClose cv)
	(dbSave tcv)
	(dbClose tcv)
	t
   )
  )
(defun pckLabelReplace (lib cell @key (data_suf "") )
  (let (cv)
	(setq cv (dbOpenCellViewByType lib cell "layout" "maskLayout" "a"))
	(setq shape_l (setof x cv~>shapes
						 (and
						  (equal x~>objType "rect")						  
						  )))
	(setq label_l (setof x cv~>shapes
						 (and
						  (equal x~>objType "label")						  
						  )))
	(foreach label label_l
			 (setq shape
				   (car
					(setof x cv~>shapes
						   (and
							(equal x~>objType "rect")
							(or (equal x~>lpp label~>lpp)
								(and
								 (equal x~>layerName label~>layerName)
								 (member x~>purpose (list "pin" "drawing")))
								)
							(equal (car x~>bBox) label~>xy)
							))))
			 (if shape
				 (progn
				   (dbSetq label (trBBoxCenter shape~>bBox ) "xy")
				   ;;
				   ;; adjust height
				   (when (greaterp
						  (cadr (trBBoxCenter shape~>bBox))
						  (car (trBBoxCenter shape~>bBox)))
					 (dbSetq  label "R90" "orient")
					 )
				   
				   (while (or
						   (equal
							(pckFindBBoxInsideZone (list label~>bBox) shape~>bBox) nil)
						   (equal label~>height 0.002))
					 (dbSetq label (difference label~>height 0.001) "height"))			 
			 
				   )
			   (progn
				 (pckDebug "pckLabelReplace"
						   (sprintf nil "Cannot find source rectangle for shape %L" label~>??)) 
				 )			   
			   )			 
			 )
	;;
	;;
	(dbSave cv)
	;; (foreach point (pckFlattenList cv~>bBox)
	;; 		 (unless (pckCheckGrid point (pckGetProcessInfo "XSNAP_SPACING"))
	;; 		   (pckError "pckLabelReplace" (sprintf nil "bBox is off grid: %L" cv~>bBox))
	;; 		   )
	;; 		 )

	
	(dbClose cv)
	)
  )
