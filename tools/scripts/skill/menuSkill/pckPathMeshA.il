;; *************************************************************************************
;; * function: pckGetPathsList
;; * description: returns list of segment lengths
;; * called by: multiple functions
;; * arguments: list of points
;; * calls to: none
;; * returns: list of path segments

(defun pckGetPathsList (ptList)

  (let (pathList pathSeg)
    pathList = (list )
    (for i 0 (length ptList)-2
         ;;;check for 0 length segment
         (unless  (and (equal (car (nth i ptList)) (car (nth i+1 ptList)))
                      (equal (cadr (nth i ptList)) (cadr (nth i+1 ptList))) )
            pathSeg = (list (nth i ptList) (nth i+1 ptList))
            pathList = (cons pathSeg pathList)
           )
        
         )
    pathList = (reverse pathList)
    );let
  );defun

;;**************************************************************************************
;; * function: pckGetDirList
;; * description: returns list of integers -1 0 1
;; * called by: 
;; * arguments: list of segments
;; * calls to: none
;; * returns: list of -1 0 and 1  1 = right turns 0 = no turn -1 = left turn
(defun pckGetDirList (segList)
  (let (dirList pair )
	dirList = (list )
  (if (length segList ) == 1
	 (progn
	      pair = (list )
		  pair = (cons 0 pair)
		  pair = (cons 0 pair)
		  dirList = (cons pair dirList)) 

		(progn
		  
	   	(for i 0 (length segList)-1
	      pair = (list )
		 (cond
		   ((and (nth i-1 segList) (nth i+1 segList))  ;;not the first or last segment
			
			(when (car (cadr (nth i segList))) == (car (car (nth i segList)));; vertical
				(if  (car (car (nth i segList))) > (car (car (nth i-1 segList)))
					 pair = (cons -1 pair) ;; left  turn from pevious segment
					 pair = (cons 1 pair);;right  turn from pevious segment
					 )
				(if  (car (cadr (nth i+1 segList))) > (car (cadr (nth i segList)))
					 pair = (cons 1 pair) ;; right  turn from pevious segment
					 pair = (cons -1 pair);;left  turn from pevious segment
					 )
			   )
			
			(when (cadr (car (nth i segList))) == (cadr (cadr (nth i segList)));; its horizontal
				  (if (cadr (car (nth i segList))) > (cadr (car (nth i-1 segList)))
					  pair = (cons 1 pair);; right turn from previous segment
					  pair = (cons -1 pair);; left turn from previous segment
				  )
			      (if (cadr (cadr (nth i+1 segList))) > (cadr (cadr (nth i segList)))
					  pair = (cons -1 pair);; left turn from previous segment
					  pair = (cons 1 pair);; right turn from previous segment
				  )
			)
			pair = (reverse pair)
			dirList = (cons pair dirList)
				);;cond1
		   ( i == 0;;first segment
			  
			pair = (cons 0 pair)
			(when (car (cadr (nth i segList))) == (car (car (nth i segList)));;hvertical
				
				(if  (car (cadr (nth i+1 segList))) > (car (cadr (nth i segList)))
					 pair = (cons 1 pair) ;; right  turn from pevious segment
					 pair = (cons -1 pair);;left  turn from pevious segment
					 )
			   )
			(when (cadr (car (nth i segList))) == (cadr (cadr (nth i segList)));; its horizontal
				  
			      (if (cadr (cadr (nth i+1 segList))) > (cadr (cadr (nth i segList)))
					  pair = (cons -1 pair);; left turn from previous segment
					  pair = (cons 1 pair);; right turn from previous segment
				  )
			)
			
			pair = (reverse pair)
			dirList = (cons pair dirList)
			)
		   (t ;;last segment
			(when (car (cadr (nth i segList))) == (car (car (nth i segList)));;vertical
				(if  (car (car (nth i segList))) > (car (car (nth i-1 segList)))
					 pair = (cons -1 pair) ;; left  turn from pevious segment
					 pair = (cons 1 pair);;right  turn from pevious segment
					 )				
			   )
		    (when (cadr (car (nth i segList))) == (cadr (cadr (nth i segList)));; its horizontal
				  (if (cadr (car (nth i segList))) > (cadr (car (nth i-1 segList)))
					  pair = (cons 1 pair);; right turn from previous segment
					  pair = (cons -1 pair);; left turn from previous segment
				  )			      
			)				
			pair = (cons 0 pair)
			pair = (reverse pair)
			dirList = (cons pair dirList)
			)
		   );; cond
	   	 
		 );; for
    ))
	dirList = (reverse dirList)
	)
  )

;;**************************************************************************************
;; * function: pckDrawBus
;; * description: draws mesh path
;; * called by: 
;; * arguments: cv, number of lines, metal layer, points list, optional @key arguments
;; * calls to: pckGetPathsList, pckGetDirList
;; * returns: list of shapes 
(defun pckDrawBus (cv lines layer pts
				   @key
				   (isIso nil)
				   (isWide nil)
				   ( meshPListH nil )
				   ( meshPListV nil )
                   ( returnShapeList nil)
                   ( addNT  nil)
                   ( isSlottedBus nil)
				   )
  (let (meshType  segList dirList hWidth vWidth hSpc vSpc hBarWidth vBarWidth hHoleLen vHoleLen hPitch vPitch
				  Lpp Plpp busList  h dir	offset0 offset1 bitList  beginBarOffset endBarOffset rectList x y shapeList
				  path pathList hOffset vOffset offset offset2 bgFlag ntFlag ntpb segBBox tileRects)

	;;remove any rod names that may exist in memory, as may occur when pckStartLayout crashes
	;; (foreach rod (rodGetNamedShapes cv) (rodUnNameShape rod))

    (if (and (or layer == "metal1" layer == "metal2" layer == "metal3") addNT)  ntFlag = t ntFlag = nil)
    
	meshType = "N"
	(when isIso meshType = "I")
	(when isWide meshType = "W")
	segList = (pckGetPathsList pts)
	dirList = (pckGetDirList segList)
    (when layer == "background" 
		  layer = "metal1";; for tech file calls - gets deleted at end
		  bgFlag = t)
	(if meshPListH
		(progn
		  hWidth = (nth 0 meshPListH)
          (when ntFlag ntpb = (pckGetBSpullback hWidth layer ))
		  hSpc = (nth 1 meshPListH)
		  hBarWidth = (nth 2 meshPListH)
		  hHoleLen = (nth 3 meshPListH)
		  )
		(progn
		  hWidth = (pckLayerInfo nil (get_pname (concat meshType "H1"))  layer )
          (when ntFlag ntpb = (pckGetBSpullback hWidth layer ))
		  hSpc = (pckLayerInfo nil (get_pname (concat  meshType "H2"))  layer)
		  hBarWidth = (pckLayerInfo nil (get_pname (concat meshType "H3")) layer)
		  hHoleLen = (pckLayerInfo nil (get_pname (concat meshType "H4")) layer)
		  )
		)
  
	(if meshPListV
		(progn
		  vWidth = (nth 0 meshPListV)
          (when ntFlag ntpb = (pckGetBSpullback vWidth layer ))
		  vSpc = (nth 1 meshPListV)
		  vBarWidth = (nth 2 meshPListV)
		  vHoleLen = (nth 3 meshPListV)
		  )
		(progn
		  vWidth = (pckLayerInfo nil (get_pname (concat  meshType "V1" ))  layer )
          (when ntFlag ntpb = (pckGetBSpullback vWidth layer ))
		  vSpc = (pckLayerInfo nil (get_pname (concat  meshType "V2"))  layer)  
		  vBarWidth = (pckLayerInfo nil (get_pname (concat meshType "V3")) layer)  
		  vHoleLen = (pckLayerInfo nil (get_pname (concat meshType "V4")) layer)
		  )
		) 


	hPitch = hWidth + hSpc
	vPitch = vWidth + vSpc
	Lpp = (list layer "drawing")
	Plpp = '("background" "drawing")
    
	shapeList = (list )
	pathList = (list )
 
	
	vOffset = ((lines - 1)*hSpc+lines*hWidth)/2 + (pckLayerInfo AUX_LIB "minHoleY" layer)
    
     ;; 	offset xbar minSegFacing metal1 distance (plus width of vertical bit, else use min hole X)
 	 (if layer == "metal1"
       hOffset = (pckPutOnGrid ((lines - 1)*vSpc+lines*vWidth)/2  + (pckLayerInfo AUX_LIB "unrMinSegmentX" layer)  )    
	   hOffset = ((lines - 1)*vSpc+lines*vWidth)/2 + (pckLayerInfo AUX_LIB "minHoleX" layer)
	 	)
 
  
	(for i 0 (length segList)-1
		 busList = (list )
		 offset = (lines - 1)/2.00
		 (if (car (car (nth i segList))) == (car (cadr (nth i segList)))
			 (progn
			   h = nil
			   offset2 = hWidth/2)
			 (progn
			   h = t
			   offset2 = vWidth/2)	
			 )
		 (if h
			 (if (car (cadr (nth i segList))) > (car (car (nth i segList)))
				 dir = 1
				 dir = -1)
			 (if (cadr (cadr (nth i segList))) > (cadr (car (nth i segList)))
				 dir = 1
				 dir = -1))

		 (if h
			 (progn
			   offset0 = offset * hPitch 
			   offset1 = offset * vPitch 
			   )
			 (progn
			   offset0 =  offset * vPitch
			   offset1 =  offset * hPitch )
			 )
	   
		 (for j 1 lines
			  bitList = (list
						 ?layer Lpp
						 ?width  (if h hWidth vWidth)
						 ?sep  offset0
						 ?beginOffset (offset1*(car (nth i dirList))*dir + (abs offset2*(car (nth i dirList)) )   ) 
						 ?endOffset (offset1*(cadr (nth i dirList))*dir + (abs offset2*(cadr (nth i dirList)))  ) 
						 ?justification "center"					   
						 )
			
			  offset0 = offset0 - (if h hPitch vPitch)
			  offset1 = offset1 - (if h vPitch hPitch)
			  busList = (cons bitList busList)
			

			
			
			  )	;;inner for

	     (cond
		   ( (length segList)-1 == 0
			 endBarOffset = (if h hHoleLen vHoleLen)
			 beginBarOffset = endBarOffset)
		   (i == 0
			  beginBarOffset =  (if h  hHoleLen vHoleLen)
			  endBarOffset = (if h
								 hOffset
								 vOffset
								 )
			  )
		   (i == (length segList)-1
			  
			  beginBarOffset =  (if h
									hOffset
									vOffset
									)
			  
			  endBarOffset = (if h  hHoleLen vHoleLen)
			  
			  )
		   (t
			
			beginBarOffset = (if h						  
								 hOffset
								 vOffset
								 )
			endBarOffset = beginBarOffset
			)
		   )
		 
	  
		 rectList = (list
					 (list 
					  ?layer Lpp
					  ?width (if h (lines - 1)*hSpc+lines*hWidth (lines - 1)*vSpc+lines*vWidth )
					  ?length (if h hBarWidth vBarWidth )                     
					  ?space (if h hHoleLen vHoleLen)
					  ?gap "distribute"
					  ?beginOffset  -beginBarOffset
					  ?endOffset -endBarOffset
					  ))
			
	   
		 path = (rodCreatePath ?cvId cv ?name (get_pname (concat "pckDrawBusSeg." i)) ?layer Plpp ?pts (nth i segList) ?width .01
							   ?offsetSubPath busList
							   ?subRect (if isSlottedBus nil rectList))	   
		 pathList = (cons path pathList)
         segBBox = (pckPathMeshGetSegBBox path~>subShapes)
         
         (when ntFlag
           
           (if layer == "metal2"
               (cond
                 (i == 0 && (car (car (nth i segList))) == (car (cadr (nth i segList))) ;; vertical
                    (if (cadr (car (nth i segList))) < (cadr (cadr (nth i segList))) ;; flush nt layer at bottom
                       segBBox = (pckShiftBbox (pckTransformBbox segBBox 0 -ntpb/2) 0 -ntpb/2)
                       segBBox = (pckShiftBbox (pckTransformBbox segBBox 0 -ntpb/2) 0 ntpb/2)
                        )                    
                    )
                 (i == (length segList)-1 && (car (car (nth i segList))) == (car (cadr (nth i segList))) ; vertical
                    (if (cadr (car (nth i segList))) < (cadr (cadr (nth i segList)));; flush nt layer at top
                       segBBox = (pckShiftBbox (pckTransformBbox segBBox 0 -ntpb/2) 0 ntpb/2)
                       segBBox = (pckShiftBbox (pckTransformBbox segBBox 0 -ntpb/2) 0 -ntpb/2)
                        )
                    )
                 (t
                  segBBox = (pckTransformBbox segBBox 0 -ntpb)
                  )
                 )
               (cond
                 (i == 0 && (cadr (car (nth i segList))) == (cadr (cadr (nth i segList))) ;; horizontal
                    (if (cadr (car (nth i segList))) > (car (car (nth i segList))) ;; flush nt layer left
                       segBBox = (pckShiftBbox (pckTransformBbox segBBox -ntpb/2 0) -ntpb/2 0)
                       segBBox = (pckShiftBbox (pckTransformBbox segBBox -ntpb/2 0) ntpb/2 0)
                        )                    
                    )
                 (i == (length segList)-1 && (cadr (car (nth i segList))) == (cadr (cadr (nth i segList))) ; horizontal
                    (if (car (car (nth i segList))) < (car (cadr (nth i segList)));; flush nt layer at right
                       segBBox = (pckShiftBbox (pckTransformBbox segBBox -ntpb/2 0) ntpb/2 0)
                       segBBox = (pckShiftBbox (pckTransformBbox segBBox -ntpb/2 0) -ntpb/2 0)
                        )
                    )
                 (t
                  segBBox = (pckTransformBbox segBBox -ntpb 0)
                  )
                 )
               
               
               )
           )
         (unless bgFlag
           (when ntFlag (dbCreateRect cv (list layer "needTermCells") segBBox)) 
           )
         ;; (dbCreateRect cv (list layer "needTermCells") segBBox)
		 shapeList = (cons path~>subShapes shapeList)
	  
		 ) ;;outer for
  
	;;convert paths to polygons 
	shapeList = (pckFlattenList shapeList)
    (when returnShapeList
      barShapes = (list )
      (foreach elem (setof x shapeList x && (pckEQP (lines - 1)*vSpc+lines*vWidth (car (trBBoxDims x~>bBox))))
              barShapes = (cons (dbCreateRect cv Lpp elem~>bBox) barShapes)  )
      ) 

      (rodUnNameShape (setof x (rodGetNamedShapes cv ) x && (rexMatchp "pckDrawBusSeg" x~>name)))
     
	tileRects = (dbLayerTile cv Lpp shapeList)
	(foreach elem shapeList
			 (when elem
			   (dbDeleteObject elem)
			   )
			 )
	(when bgFlag
  (foreach shape tileRects shape~>lpp = '("background" "drawing")))
  (when returnShapeList
    x = (setof x tileRects x && (car (trBBoxDims x~>bBox)) > vSpc)
    x = (append barShapes x)
    x = (pckFlattenList (append x tileRects))
    )
  
  ;; x = (pckFlattenList (append x y))  
	) ;;let
  )
(defun pckPathMeshGetSegBBox (shapes)
  (let (x0 x1 y0 y1 x)
    x = (car shapes)~>bBox
    x0 = (car (car x))
    x1 = (car (cadr x))
    y0 = (cadr (car x))
    y1 = (cadr (cadr x))
    shapes = (cdr shapes)
    (foreach box shapes~>bBox
             (when (car (car box)) < x0 x0 = (car (car box)))
             (when (car (cadr box)) > x1 x1 = (car (cadr box)))
             (when (cadr (car box)) < y0 y0 = (cadr (car box)))
             (when (cadr (cadr box)) > y1 y1 = (cadr (cadr box)))
             )
    (list (list x0 y0) (list x1 y1))
    )
  )
