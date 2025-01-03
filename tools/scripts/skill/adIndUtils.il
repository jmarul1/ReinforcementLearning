
procedure(removeFn(lst) when(lst mapcar('dbDeleteObject lst)) )

procedure(adFlattenInd(cv)
let( (test)
  ;; remove filler instances
  test = setof(ii cv~>instances pcreMatchp("indfile|tp0fill" ii~>cellName))
  removeFn(test)
  when(cv~>instances ;; flatten instances
    foreach(ii cv~>instances dbFlattenInst(ii 1))
    adFlattenInd(cv))
));proc

procedure(adPrepIndForSim(cv inductorLayersToKeep @optional (mtlAreaTh 2) (viaAreaTh 0.2)) 
let( (test )
;; flatten all
  adFlattenInd(cv)
;; remove unwanted shapes and non drawing;  layers = list("metal10" "via10" "metal11" "via11" "tm0" "tv0" "tm1" "tv1" "c4b")
  test = setof(ii cv~>shapes !member(ii~>layerName inductorLayersToKeep) || cadr(ii~>lpp)!="drawing")
  removeFn(test)
;; merge all shapes  rects = leMergeShapes(cv~>shapes)
;; remove shapes with area less than 2 for metals only
  test = setof(ii cv~>shapes  pcreMatchp("metal|tm|c4b" ii~>layerName) && adGetFastRectArea(ii) < mtlAreaTh)
  removeFn(test)
;; remove shapes with area less than 0.2 for vias only
  test = setof(ii cv~>shapes pcreMatchp("via|tv" ii~>layerName) && adGetFastRectArea(ii) < viaAreaTh)
  removeFn(test)  
t))


procedure(adGetRemoveShapes(cv keepDbs layers)
let( ( (keep list()) erase test)
  foreach(keepDb keepDbs keep = append(keep dbGetTrueOverlaps(cv keepDb~>bBox))) ; find layers to keep
  erase = if(type(layers) == 'string && layers == "ALL" cv~>shapes setof(ii cv~>shapes member(ii~>layerName layers))) ; get all the shapes part of layers
  test = foreach(mapcar ii erase when(!member(ii keep) ii)) ; get the shapes not in KEEP
  test = setof(ii test ii)
  geSelectFigs(test)
))

procedure( adGetFastRectArea(rectId)
let( (rWidth rLength)
  rWidth = rightEdge(rectId~>bBox)-leftEdge(rectId~>bBox)
  rLength = topEdge(rectId~>bBox)-bottomEdge(rectId~>bBox)
rWidth*rLength
));;procedure
