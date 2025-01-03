(defun pckIsUpperMetal (layer)
  (if (member layer (list "metal1" "metal2" "metal3" "metal4" "metal5" "metal6" "metal7" "metal8" "RDL"))
	t
	nil))

(defun pckGetDiffGrid ()
  (times 2 (pckLayerInfo nil "minWidthY" "ndiff"))
  )
(defun pckGetHalfDiffGrid ()
  (pckLayerInfo nil "minWidthY" "ndiff")
  )
(defun pckPutOnDiffGrid (float_num)  
    (pckPutOnGrid float_num (pckGetDiffGrid))
    )
(defun pckPutOnPolyGrid (float_num)  
  (pckPutOnGrid float_num (pckGetPolyGrid))
  )
(defun pckLppToStm (lpp)
  "Input a layerPurposePair and the stream layer and data number are returned => l_list"
  (let (port map line output layer purpose stream data)
	(setq port (infile (strcat (getShellEnvVar "ISSRUNSETS") "/PXL/p" (getShellEnvVar "PROCESS_NAME") ".map")))
	(while (setq line (fscanf port "%s %s %d %d" layer purpose stream data))
	  (when (equal line 4)
		(setq map (cons (list stream data) map))
		(setq map (cons (list layer purpose) map))))
	(close port)
	;;(fprintf stdout "map = %L\n" map)
	(cadr (member lpp map))))
(defun pckAddMetalKeepaway (cv lpp leftSize bottomSize rightSize topSize @key (depth (dbGetMaxHierDepth)) (window nil) (lppOut nil))
  "Input CV, lpp and grow dimensions and upsized keepGenAway (or specified lpp) will be drawn = l_list"
  (let (originalShapes designShapes fractShapes outShapes)
	;;Get all shapes which start in the cv - work around for TransShapeHier bug for pCells
	(setq originalShapes (setof x (getSGq cv shapes) (equal (getSGq x lpp) lpp)))
	;;set window from which to get shapes
	(unless window
	  (setq window (getSGq cv bBox)))

	;;set output lpp to associated keepGenAway lpp
	(unless lppOut
	  (setq lppOut (list (car lpp) "keepGenAway")))
	;;Get design shapes
	(setq designShapes (pckGetOverlaps cv window lpp depth ?returnObjList t))
	
	;;Clean up after pckTransShapeHierOverlaps pCell Bug
	;;(foreach shape (setof x (getSGq cv shapes) (equal (getSGq x lpp) lpp)) ;;(getSGq cv shapes)
	;;		 (unless (or
	;;				  (member shape originalShapes)
	;;				  (member shape designShapes))
    ;;          (pckInfo "pckAddMetalKeepaway" (sprintf nil "Deleting shape %L\n" shape~>lpp))
	;;		   (dbDeleteObject shape)))
	
	;;fracture design shapes
	(setq fractShapes (dbLayerTile cv '("background" "drawing") designShapes))
	;;Delete unfracture design shapes--these are not needed anymore
	(foreach shape designShapes
			 (dbDeleteObject shape))
	;;Manipulate bboxes (grow operation)
	(foreach shape fractShapes
             ;;(fprintf stdout "--D-- reshaping object %L\n" shape~>??)
			 (setSGq shape (list
							(rodAddPoints
							 (car (getSGq shape bBox))
							 (list (minus leftSize) (minus bottomSize)))
							(rodAddPoints
							 (cadr (getSGq shape bBox))
							 (list rightSize topSize)))
					 bBox))
	;;merge shapes - basically an aesthetic step
	(setq outShapes (dbLayerOr cv lppOut fractShapes nil 4000))
	;;delete fractured upsized shapes
	(foreach shape fractShapes
			 (dbDeleteObject shape))
	;;return polygons
	outShapes))

(defun pckAddMetalKeepawayBBoxROD ( cv lpp leftSize bottomSize rightSize topSize rodObjName )

(let ( thisBBox)

  thisBBox = list( rodGetObj( rodObjName cv)~>lowerLeft rodGetObj( rodObjName cv)~>upperRight)
  pckAddMetalKeepawayBBox( cv lpp leftSize bottomSize rightSize topSize thisBBox)

) ;; let
) ;; pckAddMetalKeepawayBBox

(defun pckAddMetalKeepawayBBox ( cv lpp leftSize bottomSize rightSize topSize bBox )

(let ( layer ka )

  layer = car( lpp)
  ka = "keepGenAway"
  (if leftSize > pckGetGrid() then
      dbCreateRect( cv list( layer ka) list( car(car(bBox))-leftSize:cadr(car(bBox)) car(car(bBox)):cadr(cadr(bBox))))
  )
  (if bottomSize > pckGetGrid() then
      dbCreateRect( cv list( layer ka) list( car(car(bBox)):cadr(car(bBox))-bottomSize car(cadr(bBox)):cadr(car(bBox))))
  )
  (if rightSize > pckGetGrid() then
      dbCreateRect( cv list( layer ka) list( car(cadr(bBox)):cadr(car(bBox)) car(cadr(bBox))+rightSize:cadr(cadr(bBox))))
  )
  (if topSize > pckGetGrid() then
      dbCreateRect( cv list( layer ka) list( car(car(bBox)):cadr(cadr(bBox)) car(cadr(bBox)):cadr(cadr(bBox))+topSize))
  )


) ;; let
) ;; pckAddMetalKeepawayBBox

