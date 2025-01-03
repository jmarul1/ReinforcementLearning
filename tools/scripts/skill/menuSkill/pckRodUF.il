(defun pckRodUFTextShapeWithLppName (layer purpose textSize offsetX offsetY dbId)
  "Applies label to rect to display LPP name => t"
  (let (label cvId)
	;;Make sure rodObj is not a list
	(when (listp dbId)
	  (setq dbId (car dbId)))
	;;Get cvId from rodObj argument
	(setq cvId (getSGq dbId cellView))
	;;Create label
	(setq label (dbCreateLabel cvId (list layer purpose) (list 0 0) (sprintf nil "%s:%s" layer purpose) "lowerLeft" "R0" "stick" textSize))
	;;Name label
	(setq label (rodNameShape ?name (get_pname (gensym "myLabel"))
							  ?shapeId label 
							  ?permitRename t))
	;;name dbId
	(setq dbId (rodNameShape ?name (get_pname (gensym "myShape"))
							 ?shapeId dbId
							 ?permitRename t))
	;;shrink label height if it is too big
	(when (pckGreaterp (getSGq label width) (getSGq dbId width))
	  (setSGq
	   (getSGq label dbId)
	   (quotient (getSGq (getSGq label dbId) height) 2.0)
	   height))
	;;align label to dbId
	(pckRodAlign ?refObj dbId
				 ?refHandle "lL"
				 ?alignObj label
				 ?alignHandle "lL"
				 ?xSep offsetX
				 ?ySep offsetY)
	;;unName label and dbId
	(rodUnNameShape label)
	(rodUnNameShape dbId)))