procedure( adCreatePinOnShape(shape pinName)
let( (cv pinShape nets)
  cv = shape~>cellView    nets = setof(ii cv~>nets ii~>name==pinName)
  pinShape = dbCreateRect(cv list(shape~>layerName "pin") shape~>bBox)
  dbCreatePin((if nets car(nets) dbCreateNet(cv pinName)) pinShape)
t))

procedure( adPointLeftpDb(db1 db2) adPointLeftp(centerBox(db1~>bBox) centerBox(db2~>bBox)))
procedure( adPointLeftp(pt1 pt2) ;compare and give lower x and if equal lower y
let( ( pt1x pt2x pt1y pt2y )
  pt1x = xCoord( pt1 ) pt2x = xCoord( pt2 )
  cond(
    ( pt1x < pt2x t )
    ( pt1x == pt2x pt1y = yCoord( pt1 ) pt2y = yCoord( pt2 ) pt1y < pt2y )
    ( t nil )) ; cond
)) ; procedure

procedure( adPointBottompDb(db1 db2) adPointBottomp(centerBox(db1~>bBox) centerBox(db2~>bBox)))
procedure( adPointBottomp(pt1 pt2) ;compare and give lower y and if equal lower x
let( ( pt1x pt2x pt1y pt2y )
  pt1y = yCoord( pt1 ) pt2y = yCoord( pt2 )
  cond(
    ( pt1y < pt2y t )
    ( pt1y == pt2y pt1x = xCoord( pt1 ) pt2x = xCoord( pt2 ) pt1x < pt2x )
    ( t nil )) ; cond
)) ; procedure

procedure(adRemoveInstsRow(cv duts @key (fillers "x22a_b88xp_indfiller") )
let( ( (rems1 list()) shTile effBox gShapes)
;; flatten all the mosaics
;  foreach(ii mosaicDbs dbFlattenInst(ii 1))
;; run for each dut and select instances
  foreach(tgt duts
;; prepare the box
    effBBox = dbTransformBBox(tgt~>master~>prBoundary~>bBox tgt~>transform)
    effBBox = list(rodAddPoints(car(tgt~>bBox) 3:3)  rodSubPoints(cadr(tgt~>bBox) 3:3))
;; drop layers 
    rems1 = append(rems1 dbGetTrueOverlaps(cv effBBox)) )
  rems1 = setof(ii rems1 (ii~>master && ii~>objType!="mosaic" && pcreMatchp(fillers ii~>master~>cellName)))          
;; choose interconnects
; get the instances of fillers only  
  rems1 = adListToSet(setof(ii rems1 ii))
  geSelectFigs(rems1)
))

procedure(adRemoveInstsDut(cv dut @key (shapes nil) (fillers "x22a_b88xp_indfiller") )
let( ( (rems1 list()) (rems2 list()) effBBox )
  effBBox = list(rodAddPoints(car(dut~>bBox) 1:1)  rodSubPoints(cadr(dut~>bBox) 1:1))
;; drop layers 
  rems1 = dbGetTrueOverlaps(cv effBBox)
  rems1 = setof(ii rems1 (ii~>master && pcreMatchp(fillers ii~>master~>cellName)))          
;; choose interconnects
  foreach(shape shapes
    gShapes = dbLayerSize(cv list(shape~>layerName "drawing") list(shape) 2)
    shTile = dbLayerTile(cv list(shape~>layerName "drawing") gShapes) 
    foreach(tgt shTile rems2 = append(rems2 dbGetTrueOverlaps(cv tgt~>bBox)) )
    mapcar('dbDeleteObject gShapes) mapcar('dbDeleteObject shTile)     )
  rems2 = setof(ii rems2 (ii~>master && ii~>objType!="mosaic" && pcreMatchp(strcat(fillers ".*m8") ii~>master~>cellName)))       
; get the instances of fillers only  
  rems1 = adListToSet(setof(ii append(rems1 rems2) ii))
  geDeselectAllFig(cv)
  geSelectFigs(rems1)
))

procedure(adAddPR(libName)
let( (cells cv)
  cells = ddGetObj(libName)~>cells~>name
  cells = setof(ii cells pcreMatchp("x22ac_ind10_dut" ii))
  foreach(cc cells
    cv = dbOpenCellViewByType(libName cc "layout" "maskLayout" "a")
    box = list(caar(cv~>bBox):0 cadr(cv~>bBox))
    when(cv~>prBoundary dbDeleteObject(cv~>prBoundary))
    dbCreatePRBoundary(cv adListBBox(box))
    dbSave(cv) dbClose(cv)
  )
))

procedure(adFlattenIndPcell(cv)
let( (pcells tgts)
  pcells = list("b88xp_ind2t" "b88xp_ind3t" "b88xp_indrot" "b88xp_indcentertap" "b88xp_indcross" "b88xp_indactiverect" "b88xp_indsquaredonut" "b88xp_indvia")
  tgts = setof(ii cv~>instances member(ii~>master~>cellName pcells))
  when(tgts foreach(ii tgts dbFlattenInst(ii 1 t) )) 
  when(setof(ii cv~>instances member(ii~>master~>cellName pcells)) adFlattenIndPcell(cv))
t))

procedure( addRowDiffCheck(libName cellName)
let( (cv)
  cv = dbOpenCellViewByType(libName cellName "layout2" "maskLayout" "a")
  unless(cv error(sprintf(nil "Could not open cell: %s" cellName)))
  addRowDiffCheck_debug(cv)
  dbSave(cv) dbClose(cv)
t))

procedure( addRowDiffCheck_debug(cv)
let( (temp W H elemH)
  temp = adGetWH(cv~>bBox) W = car(temp) H = cadr(temp) 
  elemH = ceiling((0.0155+H+0.0155)/(0.031+0.059))
  ;;Draw diffcheck
  rodCreateRect(?cvId cv ?layer list("diffCheck" "drawing") ?origin rodAddToY(car(cv~>bBox) -0.0155)
		?width W ?length 0.031 ?spaceY 0.059 ?elementsY elemH)
t))

