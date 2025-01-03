;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Filename: pckLayerFunctions.ils                 Project: TCC
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Copyright Intel Corporation 2010
;;
;; Author: jho4
;;
;; Date: Aug 27 11:51:09 2010
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Functional Description:
;;
;; Functions for layer manipulations
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; (load "pckLayerFunctions.il")


;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FUNCTION: pckLayerGetPyCutShapes
;; DESCRIPTION: Get the poly cut shapes given a window and poly type
;; CALLED BY: 
;; ARGUMENTS: cvId window pyType ?pyWX ?extend_x ?extend_y ?deleteTmpObjs
;; CALLS: 
;; RETURNS: poly cut shapes [l_dbIdList]
;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun pckLayerSetCopy (cvId source_layer target_layer @key (keep_source "no"))
  "Copies all layers in source_layer to target_layer. Optional removal of source layers.
Layer_purpose remains unchanged."
  (when (atom source_layer)
	(setq source_layer (list source_layer))
	)
  (when (atom target_layer)
	(setq target_layer (list target_layer))
	)
  (when
	  (nequal
	   (length source_layer) (length target_layer))
	(pckError "pckLayerSetCopy"
	 		  (sprintf nil "List of source layers %L differs from target layers %L" source_layer target_layer))
	(error (sprintf nil "List of source layers %L differs from target layers %L" source_layer target_layer)) 
	)
  (let (new_shape)
	(for i 0 (sub1 (length source_layer))
		 ;; one day I should write a regression here.
		 (setq shape_list
			   (setof shape
					  (dbGetq cvId "shapes")
					  (equal
					   (dbGetq shape "layerName")
					   (nth i source_layer))))
		 (mapcar
		  (lambda (x)
			(if (equal keep_source "yes")
				(progn 
				  (setq new_shape (dbCopyShape x cvId))
				  (dbSetq new_shape (nth i target_layer) "layerName"))
			  (progn
				(dbSetq x (nth i target_layer) "layerName"))))
		  shape_list)
		 )
	t
	)
  )


(defun pckLayerGetPyCutShapes (cvId window pyType
                               @key (pyWX 0.0) (extend_x 0.0) (extend_y 0.0)
                               (deleteTmpObjs t))
  "Get the poly cut shapes given a window and poly type.
   Results can be used as input parameter (dcFillExcludeList) to polyFrame.
   
   Inputs:
   window - bBox
   pyType - poly type
   ?pyWX - poly CD
   ?extend_x - grow the shape by the amount in X direction
   ?extend_y - grow the shape by the amount in Y direction
   ?deleteTmpObjs - delete temporary objs created by the function

   Example:
   (pckLayerGetPyCutShapes cvId (list (list 0 0) (list 10 10)) \"digital\" ?pyWX 0.04 ?extend_x 0.01 ?extend_y 0.02 ?deleteTmpObjs nil)

   => poly cut shapes [l_dbIdList]"
  (let (windowShape designPyShapes mergedPyShapes pySpaceShapesRaw
                    pySpaceShapesFract pySpaceShapesFractUpsized)
    ;;Create windowshape
    (setq windowShape (dbCreateRect cvId (list "chkBoundary" "boundary") window))
    ;;gather all poly shapes 
    (setq designPyShapes (pckTransShapeHierOverlaps
                          cvId
                          window
                          (list "poly" "drawing")
                          (dbGetMaxHierDepth)
                          ?returnObjList t))
    ;;upsize and merge shapes in OGD
    (setq designPyShapes (pckLayerSize cvId (list "metal1" "scratchDrawing")
                                       designPyShapes 
                                       (quotient (difference (pckASLayerInfo pyType nil "minPitchX" "poly")
                                             (if (pckEQP pyWX 0.0)
                                                 (car (trBBoxDims (getSGq (car designPyShapes) bBox)))
                                                 pyWX)) 2.0)
                                       0.0
                                       ))
    (setq mergedPyShapes (dbLayerOr cvId (list "metal2" "scratchDrawing") designPyShapes))
    (setq pySpaceShapesRaw (dbLayerAndNot cvId (list "metal3" "scratchDrawing")
                                          (list windowShape) mergedPyShapes))
    ;;fracture shapes to make sure they are rectangles
    (setq pySpaceShapesFract (dbLayerTile cvId (list "metal4" "scratchDrawing") pySpaceShapesRaw))
    ;;grow shapes by extend_x and extend_y
    (setq pySpaceShapesFractUpsized (pckLayerSize cvId (list "metal5" "scratchDrawing")
                                                  pySpaceShapesFract extend_x extend_y))
    (when deleteTmpObjs
      (mapcar 'dbDeleteObject (pckFlattenList (list designPyShapes mergedPyShapes pySpaceShapesFract
                                                    pySpaceShapesRaw windowShape)))
      (foreach shape pySpaceShapesFractUpsized
               (setSGq shape (list "background" "drawing") lpp)))
    ;;return l_dbIdList of poly cuts
    pySpaceShapesFractUpsized
    ) ;; let
  )   ;; pckLayerGetPyCutShapes


;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FUNCTION: pckLayerGetHalo
;; DESCRIPTION: 
;; CALLED BY: 
;; ARGUMENTS: cvId window inlpp halo_dims ?deleteTmpObjs 
;; CALLS: 
;; RETURNS: halos shapes [l_dbIdList]
;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun pckLayerGetHalo (cvId window lpp_inList lpp_outList halo_dims
                        @key (inShapes nil) (deleteTmpObjs t))
  "Given a window and list of lpp or given a list of dbIds,
   creates halo shapes in user-defined lpp and dimensions.

   Inputs:
   window - bBox
   lpp_inList - list of lpp for input shapes   
   lpp_outList - list of lpp for output shapes 
   halo_dim - dimension for halo shapes (list left top bot right)
   ?inShapes - a list of dbIds to work on
   ?deleteTmpObjs - delete temporary objs created by the function


   Example:
   (pckLayerGetHalo cvId (list (list 0 0) (list 10 10)) (list (list \"ndiff\" \"drawing\") (list \"pdiff\" \"drawing\"))
                    (list (list \"background\" \"drawing\") (list \"chkBoundary\" \"boundary\"))
                    (list 0.01 0.02 0.01 0.02) ?deleteTmpObjs t)

   => halo shapes in layers of lpp_outList [list of l_dbIdList]"
  (let (windowShape designShapes upsizedShapes haloShapes haloShapesTiled
                    outShapes)
    (if (equal inShapes nil)
        (progn
          ;;Create windowshape
          (setq windowShape (dbCreateRect cvId (list "chkBoundary" "boundary") window))
          ;;get design shapes
          (foreach inlpp lpp_inList
                   (setq designShapes (append (pckTransShapeHierOverlaps
                                               cvId window inlpp
                                               (dbGetMaxHierDepth)
                                               ?returnObjList t)
                                              designShapes))))
        (setq designShapes inShapes))
    (pckDebug "pckLayerGetHalo" (sprintf nil "designShapes:%L" designShapes))
    ;;grow designShapes by halo_dims (list left bot right top) amount
    (foreach shape designShapes
             (setq upsizedShapes (cons (dbCreateRect cvId
                                                     (list "metal1" "scratchDrawing")
                                                     (list
                                                      (rodAddPoints
                                                       (car (getSGq shape bBox))
                                                       (list (minus (nth 0 halo_dims)) (minus (nth 1 halo_dims))))
                                                      (rodAddPoints
                                                       (cadr (getSGq shape bBox))
                                                       (list (nth 2 halo_dims) (nth 3 halo_dims)))))
                                       upsizedShapes)))
    ;; (setq upsizedShapes (pckLayerSize cvId (list "metal1" "scratchDrawing")
;;                                       designShapes halo_x halo_y))
    (pckDebug "pckLayerGetHalo" (sprintf nil "upsizedShapes:%L" upsizedShapes))
    ;;find halo zones by AND NOT of designShapes and upsizedShapes
    (setq haloShapes (dbLayerAndNot cvId (list "metal2" "scratchDrawing")
                                    upsizedShapes designShapes))
    (pckDebug "pckLayerGetHalo" (sprintf nil "haloShapes:%L" haloShapes))
    ;;make sure shapes are rects
    (setq haloShapesTiled (dbLayerTile cvId (list "metal3" "scratchDrawing")
                                       haloShapes))
    (pckDebug "pckLayerGetHalo" (sprintf nil "haloShapesTiled:%L" haloShapesTiled))
    ;;create halo shapes in layers defined by lpp_outList
    (foreach outlpp lpp_outList
             (setq outShapes (cons (dbLayerSize cvId outlpp haloShapesTiled 0.0)
                                   outShapes))
             )
    (pckDebug "pckLayerGetHalo" (sprintf nil "outShapes:%L" outShapes))
    (when deleteTmpObjs
      (mapcar 'dbDeleteObject
              (pckFlattenList (list windowShape designShapes
                                    upsizedShapes haloShapes haloShapesTiled)))
      (foreach shape outShapes
               (setSGq shape (list "background" "drawing") lpp)))
    ;;returen list of l_dbIdList
    outShapes
    ) ;; let
  )   ;; pckLayerGetHalo

;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FUNCTION: pckLayerSplitHorizontal
;; DESCRIPTION: 
;; CALLED BY: pckLayerDrawM1toM5
;; ARGUMENTS: cvId inlpp bbox ?vertical ?dropPreferred ?outlpp ?ignoreOutside 
;; CALLS: 
;; RETURNS: list of 2 l_dbIdList
;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun pckLayerSplitHorizontal (cvId inlpp bbox
                             @key
                             (vertical nil)
                             (dropPreferred nil)
                             (outlpp nil)
                             (ignoreOutside nil))

  "Fracture shapes in inlpp so that they are maximally horizontal 
  (or vertical) and return a list with two sublists. The first
  sub-list contains all the horizontal (or vertical) pieces and the 
  second one contains all the vertical (or horizontal) pieces.

  If ?vertical is set to t, changes the meaning of the of the 
  function and the behavior give in paranthesis above applies.

  If ?dropPreferred is t, drops the preferred direction,
  which is horizontal (vertical if ?vertical is set to t).

  If ?outlpp is t, the result of fracture is written
  out to that layer. Otherwise the result is written out to inlpp.

  If ?ignoreOutside is t, effectively ignores shapes outside
  bbox, even those that are part of shapes that are within bbox.

  Returns two sub-lists: the first one is the list of objects 
  in the preferred direction and the second is the list of objects
  in the non-preferred direction. If ?dropPreferred is set to t 
  then the first sub-list is '()."  
  
  
  (letseq ((objs (dbGetTrueOverlaps cvId bbox inlpp 0))
           (lpp1 (pckGetUnusedLpp cvId))
           (lpp2 (pckGetUnusedLpp cvId lpp1))
           (shapes (dbLayerOr cvId lpp1 objs))
           tiled pref nonpref ret1 ret2 temp1 temp2)
          
          (when ignoreOutside
            (setq temp1 (dbCreateRect cvId (list "chkBoundary" "boundary") bbox))
            (setq temp2 (dbLayerAnd cvId lpp1 (list temp1) shapes))
            (mapcar 'dbDeleteObject shapes)
            (when (dbIsId temp1) (dbDeleteObject temp1))
            (setq shapes temp2))
          
          (unless vertical
            (mapcar (lambda (x) (dbMoveFig x nil (list 0:0 "R90"))) shapes))
          (setq tiled (dbLayerTile cvId lpp2 shapes))
          (progn                
            (setq pref (setof x tiled (pckIsBboxVertical x~>bBox)))
            (setq nonpref (setof x tiled (not (pckIsBboxVertical x~>bBox)))))
          (unless vertical            
            (mapcar (lambda (x) (dbMoveFig x nil (list 0:0 "R270"))) pref)
            (mapcar (lambda (x) (dbMoveFig x nil (list 0:0 "R270"))) nonpref))
          (if outlpp
              (progn 
                (setq ret1 (if dropPreferred
                               '()
                               (dbLayerSize cvId outlpp pref 0)))                         
                (setq ret2 (dbLayerSize cvId outlpp nonpref 0)))
              (progn
                (setq ret1 (if dropPreferred
                               '()
                               (dbLayerSize cvId inlpp pref 0)))
                (setq ret2 (dbLayerSize cvId inlpp nonpref 0))))
          (mapcar 'dbDeleteObject shapes)          
          (mapcar 'dbDeleteObject tiled)
          (mapcar 'dbDeleteObject pref)
          (mapcar 'dbDeleteObject nonpref)
          (list ret1 ret2)))

;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FUNCTION: pckIsBboxVertical
;; DESCRIPTION: 
;; CALLED BY: pckLayerDrawM1toM5
;; ARGUMENTS: bbox
;; CALLS: 
;; RETURNS: t/nil
;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun pckIsBboxVertical (bbox)

  "Retruns t if y-dim of bbox > x-dim of bbox.Returns nil otherwise"

  (let ((dim (trBBoxDims bbox)))
    (greaterp (cadr dim) (car dim))))


;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FUNCTION: pckLayerDrawM1toM5
;; DESCRIPTION: 
;; CALLED BY: 
;; ARGUMENTS: cvId meLayers vaLayers points nmLines skipViaOuterLines
;; CALLS: 
;; RETURNS: t
;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun pckLayerDrawM1ToM5 (cvId meLayers vaLayer points nmLines skipViaOuterLines)

  "Draws multi-layers mesh from M1 to M5.
   mlayer - is the list of metal layers to draw
          - e.g. (list \"metal1\" \"metal2\" \"metal3\")
   vaLayers - is the list of via layers to draw
          - e.g. (list \"via1\" \"via2\")
   points - is the path for the mesh
          - e.g. (list (list 0 0) (list 0 5) (list 5 5) (list 5 10))
   nmLines - the number of metal strips in the path
          - e.g. 5
   skipViaOuterLines - skip drawing via's in the outer most metal lines
                     - t or nil

   This uses the pckDrawBus function to draw meshes. The M4 mesh is
   spaced to be centered over M1-M3.

   Based on ideas from Mr. Johnny Ho.

   Example Usage:

  1) To draw all mesh layers and via layer from M1-M5 and V1-V4 and skip vias
  in the outer lines in the current cellview:

  (pckDrawM1ToM5 (geGetEditCellView) 
                 (list \"metal1\" \"metal2\" \"metal3\" \"metal4\" \"metal5\") 
                 (list \"via1\" \"via2\" \"via3\" \"via4\") 
                 (list (list 0 0) (list 0 5) (list 5 5) (list 5 10)) 5 t)

  2) To draw all mesh layers and via layer from M3&M4 and V3 and skip vias
  in the outer lines in the current cellview:

  (pckDrawM1ToM5 (geGetEditCellView) 
                 (list \"metal3\" \"metal4\") 
                 (list \"via3\") 
                 (list (list 0 0) (list 0 5) (list 5 5) (list 5 10)) 5 t)
  "

  
  (defun drawViaUnderMetal (cview mlayer via_layer pathPoints skipOuterLines meshPlist viaInfo)

    "viaInfo is a list with this information:
                0 - x-dim dimension for PGD line
                1 - y-dim dimension for PGD line
                2 - via edge to edge space
                3 - via space from corner/edge
                4 - via coverage (0 for SA via)"

    (let (skipDim mesh_width extend_path extend_rects extend_bboxes via_regions
                  oneLineSpace)
      (setq oneLineSpace (plus (nth 0 meshPlist) (nth 1 meshPlist)))
      (setq skipDim 
            (if skipOuterLines      
                oneLineSpace
                0.000))
      ;; figure out bboxes for mesh
      (setq mesh_width (plus (times nmLines (nth 0 meshPlist))
                          (times (difference nmLines 1) (nth 1 meshPlist))))
      (setq extend_path (dbCreatePath cview (list "chkBoundary" "boundary")
                                      pathPoints mesh_width))
      (setq extend_rects (dbLayerTile cview (list "chkBoundary" "boundary")
                                      (list (dbConvertPathToPolygon extend_path))))
      (dbDeleteObject extend_path)
      ;;change vertical bboxes by: a)shrinking top/bot to stay away from turns/corners
      ;;                           b) skipping outer lines (if needed)
      ;;change horizontal bboxes by: a) shrink left/right by one cd+space and
      ;;                             b) skipping outer lines (if needed)
      (setq extend_bboxes
            (mapcar 
             (lambda (bbox)
               (let ((clearance (plus mesh_width skipDim)))
                 ;; (printf "clearance = %L\n" clearance)
                 (if (pckIsBboxVertical bbox)
                     (list (list (plus (leftEdge bbox) skipDim)
                                 (plus (bottomEdge bbox) clearance))                 
                           (list (difference (rightEdge bbox) skipDim)
                                 (difference (topEdge bbox) clearance)))
                     (list (list (plus (leftEdge bbox) oneLineSpace)
                                 (plus (bottomEdge bbox) skipDim))                 
                           (list (difference (rightEdge bbox) oneLineSpace)
                                 (difference (topEdge bbox) skipDim))))))
             extend_rects~>bBox))
      (mapcar 'dbDeleteObject extend_rects)   
      ;;place vias
      (mapcar
       (lambda (bbox)
         (dbCreateRect cview (list "chkBoundary" "boundary") bbox)
         (if (pckIsBboxVertical bbox)
             (progn 
               (setq via_regions
                     (cadr (pckLayerSplitHorizontal cview
                                                    (list mlayer "drawing")
                                                    bbox
                                                    ?outlpp (list "chkBoundary" "drawing")
                                                    ?vertical nil
                                                    ?dropPreferred t
                                                    ?ignoreOutside t)))
               (foreach r via_regions~>bBox
                        (rodFillBBoxWithRects
                         ?cvId cview
                         ?layer (list via_layer "drawing")                     
                         ?fillBBox (list (pckShiftPoint (lowerLeft r)
                                                        (nth 4 viaInfo) (nth 3 viaInfo))
                                         (rodAddToY (upperRight r) (minus (nth 3 viaInfo))))
                         ?width (nth 0 viaInfo)
                         ?length (nth 1 viaInfo)
                         ?spaceY (nth 2 viaInfo)
                         ?spaceX 5.000
                         ?gap 'minimum)) ;large # for x-space to ensure 1 col only
               (mapcar 'dbDeleteObject via_regions)) 
             (progn
               (setq via_regions 
                     (cadr  (pckLayerSplitHorizontal cview
                                                     (list mlayer "drawing")
                                                     bbox
                                                     ?outlpp (list "chkBoundary" "boundary")
                                                     ?vertical t
                                                     ?dropPreferred t
                                                     ?ignoreOutside t)))
               (foreach r via_regions~>bBox
                        (rodFillBBoxWithRects
                         ?cvId cview
                         ?layer (list via_layer "drawing")                     
                         ?fillBBox (list (pckShiftPoint (lowerLeft r)
                                                        (nth 3 viaInfo) (nth 4 viaInfo))
                                         (rodAddToX (upperRight r) (minus (nth 3 viaInfo))))
                         ?width (nth 1 viaInfo)
                         ?length (nth 0 viaInfo)
                         ?spaceY 5.000
                         ?spaceX (nth 2 viaInfo)
                         ?gap 'minimum))             
               (mapcar 'dbDeleteObject via_regions))))
       extend_bboxes)))
 
  ;;;
  ;;; draw the metal lines and vias needed
  ;;;
  (let ((mesh_plist_m1234 (pckGetMeshPList "metal4" nil ?isIso t))
        (mesh_plist_m5 (pckGetMeshPList "metal5" nil ?isIso t))
        via123_info via4_info)    
  ;; mesh info. Center M5 lines over M1->M4
    (setq mesh_plist_m1234 (pckGetMeshPList "metal4" nil ?isIso t))
    (setq mesh_plist_m1234 (list (nth 0 mesh_plist_m1234)
                                (nth 1 mesh_plist_m1234)
                                (nth 2 mesh_plist_m1234)
                                (times 2 (nth 3 mesh_plist_m1234))))
    (setq mesh_plist_m5 (pckGetMeshPList "metal5" nil ?isIso t))
  ;;Center M5 over M4
    (setq mesh_plist_m5 (list (nth 0 mesh_plist_m5)
                              (plus (nth 1 mesh_plist_m1234)
                                 (difference (nth 0 mesh_plist_m1234) (nth 0 mesh_plist_m5)))
                              (nth 2 mesh_plist_m5)
                              (times 2 (nth 3 mesh_plist_m5))))
  ;;Draw metal lines needed
    (foreach ml meLayers
             (when (member ml (list "metal1" "metal2" "metal3" "metal4"))               
               (pckDrawBus cvId nmLines ml
                           points
                           ?isIso t
                           ?meshPListH mesh_plist_m1234
                           ?meshPListV mesh_plist_m1234))
             (when (equal ml "metal5")             
               (pckDrawBus cvId nmLines "metal5"
                           points
                           ?isIso t
                           ?meshPListH mesh_plist_m5
                           ?meshPListV mesh_plist_m5)))

  ;;via rules
    (setq via123_info (list (pckLayerInfo nil "minWidthDX" "via2")
                           (pckLayerInfo nil "minWidthDY" "via2")
                           (pckLayerInfo nil "minSpacingY" "via2")                     
                           (max (pck2LayerInfo nil "minEnclosureC2CInt" "via2" "metal3")
                                (pck2LayerInfo nil "minEnclosureC2CExt" "via2" "metal3"))
                           (pck2LayerInfo nil "minEnclosureY" "via2" "metal3")))        
    (setq via4_info (list (pckLayerInfo nil "minWidthCY" "via4")
                          (pckLayerInfo nil "minWidthCX" "via4")
                          (pckLayerInfo nil "minSpacingRLX" "via4")
                          ;;times 1.5 to solve V3_24
                          (times 1.5 (max (pck2LayerInfo nil "minEnclosureX"  "via4" "metal5")
                                          (pck2LayerInfo nil "minEnclosureY"  "via4" "metal5")))
                          0.000))
    (foreach
     vl vaLayer
     (cond ((equal "via1" vl)
            (drawViaUnderMetal cvId "metal2" "via1" points skipViaOuterLines
                               mesh_plist_m1234 via123_info))
           ((equal "via2" vl)
            (drawViaUnderMetal cvId "metal3" "via2" points skipViaOuterLines
                               mesh_plist_m1234 via123_info))
           ((equal "via3" vl)
            (drawViaUnderMetal cvId "metal4" "via3" points skipViaOuterLines
                               mesh_plist_m1234 via123_info))
           ((equal "via4" vl)
            (drawViaUnderMetal cvId "metal5" "via4" points skipViaOuterLines
                               mesh_plist_m5 via4_info))))
    t))



;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FUNCTION: pckLayerDrawVia
;; DESCRIPTION: 
;; CALLED BY: 
;; ARGUMENTS: cvId vaLayer meVertP vaWX vaWY window
;; CALLS: 
;; RETURNS: t
;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun pckLayerDrawVia (cvId vaLayer meVertP vaWX vaWY window)

  "Place Via (V1 to V6) and remove interfering Metal cross-bars"
  
  (defun duplicateObjsInsideWindow (cview lpp qwindow outlpp)
    (let ((scratch (dbOpenCellViewByType cview~>libName
                                         (strcat cview~>cellName "_scv")
                                         "layout" "maskLayout" "w" ))
          copied ext ret)
      ;;make scratch "editable read-only" - oxymoron alert!
      ;;see "Virtuoso Design Environment Adoption Guide, Product Version 6.1.3"
      ;;Chapter #3
      (dbReopen scratch "r")
      (pckTransShapeHierOverlaps cview qwindow lpp
                                 (dbGetMaxHierDepth)
                                 ?userTempCV scratch)
      (setq copied (mapcar (lambda (s) (dbCopyShape s cview)) scratch~>shapes))
      (setq ext (list (dbCreateRect cview (list "chkBoundary" "boundary") qwindow)))
      (setq ret (dbLayerAnd cview outlpp copied ext))
      (mapcar 'dbDeleteObject copied)
      (mapcar 'dbDeleteObject ext)
      (dbClose scratch)
      ret))

  (defun drawViaCenteredOverObj (cview obj viax viay via_lpp) 
    (letseq ((center (trBBoxCenter obj~>bBox))
             ll ur)
            (setq ll (pckShiftPoint
                      center
                      (pckPutOnGrid (minus (quotient viax 2.0)))
                      (pckPutOnGrid (minus (quotient viay 2.0)))))
            (setq ur (pckShiftPoint ll viax viay))            
            (dbCreateRect cview via_lpp (list ll ur))))
  
  

  (letseq ((temp_meTopcp (pckGetUnusedLpp cvId))
           (temp_meBotcp (pckGetUnusedLpp cvId (list temp_meTopcp)))
           (temp_lpp3 (pckGetUnusedLpp cvId (list temp_meTopcp temp_meBotcp)))
           meTop_in_window meBot_in_window via_loc new_window
           (TmeLayer (sprintf nil "metal%d" (add1 (atoi (substring vaLayer 4 1)))))
           (BmeLayer (sprintf nil "metal%d" (atoi (substring vaLayer 4 1)))))
          ;;grow window to avoid via1 to metal2 concave corner violation
          (setq new_window (if meVertP
                               (list (list (leftEdge window)
                                           (difference (bottomEdge window)
                                                       (pck2LayerInfo nil "minEnclosureC2CInt" vaLayer TmeLayer)))
                                     (list (rightEdge window)
                                           (plus (topEdge window)
                                                 (pck2LayerInfo nil "minEnclosureC2CInt" vaLayer TmeLayer))))
                               (list (list (difference (leftEdge window)
                                                       (pck2LayerInfo nil "minEnclosureC2CInt" vaLayer TmeLayer))
                                           (bottomEdge window))
                                     (list (plus (rightEdge window)
                                                 (pck2LayerInfo nil "minEnclosureC2CInt" vaLayer TmeLayer))
                                           (topEdge window)))))
          (duplicateObjsInsideWindow cvId (list TmeLayer "drawing")
                                     window temp_meTopcp)
          (setq meTop_in_window 
                (if meVertP ; drop hori or vert cross-bars as necessary
                    (pckLayerProcessHorizontal cvId temp_meTopcp new_window nil)
                    (pckLayerProcessHorizontal cvId temp_meTopcp new_window t)))
          ;; (printf "meTop_in_window = %L\n" meTop_in_window)
          (duplicateObjsInsideWindow cvId (list BmeLayer "drawing")
                                     window temp_meBotcp)
          (setq meBot_in_window 
                (if meVertP ; drop hori or vert cross-bars as necessary
                    (pckLayerProcessHorizontal cvId temp_meBotcp new_window t)
                    (pckLayerProcessHorizontal cvId temp_meBotcp new_window nil)))
          (printf "meBot_in_window = %L\n" meBot_in_window)
          ;;now re-query the m2/meBot_in_window shapes
          ;;using the return values above does not seem reliable
          ;; (setq meBot_in_window (setof x cvId~>shapes (equal x~>lpp temp_meBotcp)))
;;           (setq meTop_in_window (setof x cvId~>shapes (equal x~>lpp temp_meTopcp)))
          ;;Then AND it together.
          (setq via_loc (dbLayerAnd cvId temp_lpp3 meBot_in_window meTop_in_window))
          ;;draw real vias
          (mapcar (lambda (x)
                    (drawViaCenteredOverObj cvId x vaWX vaWY
                                            (list vaLayer "drawing")))
                  via_loc)
          (mapcar 'dbDeleteObject meBot_in_window)
          (mapcar 'dbDeleteObject meTop_in_window)
          (mapcar 'dbDeleteObject via_loc)
          ;; remove m2 cross-bars
          (if meVertP             
              (pckLayerProcessHorizontal cvId (list TmeLayer "drawing") new_window nil)
              (pckLayerProcessHorizontal cvId (list TmeLayer "drawing") new_window t))          
          t))