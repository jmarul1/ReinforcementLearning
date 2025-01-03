;##############################################################################
;# Intel Top Secret                                                           #
;##############################################################################
;# Copyright (C) 2015, Intel Corporation.  All rights reserved.               #
;#                                                                            #
;# This is the property of Intel Corporation and may only be utilized         #
;# pursuant to a written Restricted Use Nondisclosure Agreement               #
;# with Intel Corporation.  It may not be used, reproduced, or                #
;# disclosed to others except in accordance with the terms and                #
;# conditions of such agreement.                                              #
;#                                                                            #
;# All products, processes, computer systems, dates, and figures              #
;# specified are preliminary based on current expectations, and are           #
;# subject to change without notice.                                          #
;##############################################################################
;# Author:
;#   Mauricio Marulanda
;##############################################################################

/*---------------------------------------------------------------------------
 procedure: adGetRectArea()
 Created by Mauricio Marulanda
 Purpose: Calculates the area for the list of rectangles given in the layer. No Diagonal lines
 ---------------------------------------------------------------------------*/
procedure( adGetRectArea(rectIds @optional (metal "tm1"))
  let( (rects rWidth rLength (tArea 0))
    unless(type(rectIds) == 'list metal = car(rectIds~>lpp) rectIds = list(rectIds) )
    ; get the rects on the metal
    rects = setof(x rectIds car(x~>lpp)==metal)
    ; merge the rects
    rects = leMergeShapes(rects)
    rects = dbLayerTile(car(rects)~>cellView metal rects)
    foreach(iiRect rects
      rWidth = rightEdge(iiRect~>bBox)-leftEdge(iiRect~>bBox)
      rLength = topEdge(iiRect~>bBox)-bottomEdge(iiRect~>bBox)
      tArea = tArea + rWidth*rLength
    );foreach   
    mapcar('dbDeleteObject rects)
    tArea
));;procedure

/*---------------------------------------------------------------------------
 procedure: closeme()
 Created by Mauricio Marulanda
 Purpose: Closes the data of the list of cells given or all the open ones
 ---------------------------------------------------------------------------*/
procedure( closeme(@optional (cellNames dbGetOpenCellViews()) )
  when(type(cellNames)!='list cellNames=list(cellNames))
  foreach(cv cellNames
    when(stringp(cv) ;case when the cellNames are strings
      cv = car(setof(ii dbGetOpenCellViews() cv==ii~>cellName)));when
    when(dbIsId(cv) printf("Purging %L\n" cv~>cellName) dbPurge(cv)) ) ;foreach
t);;procedure

/*---------------------------------------------------------------------------
 procedure: adRoutePinsOnInsts
 Created by Mauricio Marulanda
 Purpose: Places all the pins in the position of the instances. This is usually done after creating a genFromSource with the pin creation enable for layout.
 ---------------------------------------------------------------------------*/
procedure( adRoutePinsOnInsts(cv @optional (nameMap nil)) ;schematic or layoutAfterGenFromSrc
let( (topNet topFig pinInst tSize (pinDpl gensym()))
  when(cv~>cellViewType != "maskLayout" pinInst = dbOpenCellViewByType("basic" "iopin" "symbol"))
  foreach(inst cv~>instances
    foreach(iiTerm inst~>master~>terminals
      foreach(iiPin iiTerm~>pins ; iterate over all the pins for this topTerminal (a terminal might have two pins)   
        when(iiPin~>fig
	  name = get(nameMap iiTerm~>net~>name) || iiTerm~>net~>name || strcat(iiTerm~>net~>name "_" lowerCase(symbolToString(gensym())))
	  topNet = car(setof(ii cv~>nets name == ii~>name)) putprop(pinDpl name iiTerm~>net~>name)
	  unless(topNet topNet = dbCreateNet(cv name) )
	  topFig = (if cv~>cellViewType == "maskLayout" 
	    dbCreateRect(cv iiPin~>fig~>lpp dbTransformBBox(iiPin~>fig~>bBox inst~>transform))
	    dbCreateInst(cv pinInst symbolToString(gensym()) dbTransformPoint(centerBox(iiPin~>fig~>bBox) inst~>transform) "R0"))
	  dbCreatePin(topNet topFig) );when
  )));foreach;foreach;foreach
  when(cv~>cellViewType == "maskLayout" adAddTxtToNets(cv))
pinDpl));procedure

;Purpose: Generate from source
procedure(adGenLayout(inCellId @key (pins t) (bulk nil))
  let( (outCellId)
    schCheck(inCellId)     dbSave(inCellId)    aelPushSignifDigits(15)
    ;envSetVal("layoutXL" "lxEvalCDFCallbacks" 'boolean t)
    outCellId = lxGenFromSource(inCellId ?initCreatePins pins ?initCreateBoundary nil) ;dbClose(inCellId)
    when(pins adRoutePinsOnInsts(outCellId))     ;; create pins if any
    when(bulk adRemoveAllPins(outCellId bulk) placeLvqaPtap(outCellId bulk) );when text the bulk requested
    dbSave(outCellId)        dbClose(outCellId)
    aelPopSignifDigits()
t));let ;procedure

procedure(adRunDoneProcedure(inst)
  when(and(cdfGetInstCDF(inst) cdfGetInstCDF(inst)~>doneProc)  
    apply(stringToSymbol(cdfGetInstCDF(inst)~>doneProc) list(inst)) );when
);procedure

;remove any pins/shapes/nets associated with pinName
procedure(adRemoveAllPins(t_layDb pinName) 
let( (net labels)
  net = car(setof(ii t_layDb~>nets ii~>name == pinName))
  labels = setof(jj setof(ii t_layDb~>shapes ii~>objType=="label") jj~>theLabel==pinName)
  foreach(ddObjs net~>pins when(ddObjs~>figs mapcar('dbDeleteObject ddObjs~>figs))) ;erase all pin shapes
  foreach(ddObjs list(net~>pins labels list(net)) ;erase the pins db, pin texts, and the net
    mapcar(lambda((ff) when(ff dbDeleteObject(ff))) ddObjs) );foreach
t));procedure

;erase all pins and nets place layout pins everywhere with pinName from instance adding the suffix attached
procedure(adPlacePinOnCvInsts(cv @key (suffix nil))
let((topNet tgtFig bBox netName pinH pinDt)
  foreach(ii cv~>nets~>name adRemoveAllPins(cv ii)) mapc('dbDeleteObject setof(ii cv~>shapes ii~>purpose=="pin"))
  foreach(inst cv~>instances ;find all instances
    foreach(topNet inst~>master~>nets
      tgtFig = car(topNet~>pins)~>fig
      when(tgtFig
        bBox = dbTransformBBox(tgtFig~>bBox inst~>transform)  netName = if(suffix strCat(topNet~>name "_" suffix) topNet~>name)
        pinH = adGetWH(bBox)  pinDt = if(car(pinH)>cadr(pinH) list(cadr(pinH) "R0") list(car(pinH) "R90"))
	rodCreateRect(?cvId cv ?bBox bBox ?layer tgtFig~>lpp ?netName netName ?pin t ?pinLabel t ?pinLabelHeight car(pinDt) ?pinLabelOrient cadr(pinDt)) )
  ))
t))

;find if this is the only layer in the layout
procedure(adOnlyLayer(csv libName @key (lpp list("mc0" "complement")) (outFile nil) )
let( (cells cv (view "layout") (errStrLst list()) (key "cellName") fout)
  cells = (if type(csv) == 'list csv get(adReadCsv(csv) key) )
  foreach(cc cells 
    cv = dbOpenCellViewByType(libName cc view) ;open the cell
    when(cv 
      errStrLst = isOnlyLayer(cv errStrLst ?lpp lpp) dbClose(cv) ) );foreach
if(outFile then fout = outfile(simplifyFilename(outFile)) 
     fprintf(fout "cellName,AddLayers\n%s" buildString(errStrLst "\n")) close(fout)
else printf("%s\n" buildString(errStrLst "\n")) )
));proc

;find if the cv has only the layer asked for
procedure(isOnlyLayer(cv errStrLst @key (lpp list("mc0" "complement")))
let( (result)
 when(cv~>instances ;check for non complement by calling each instance
  foreach(ii cv~>instances errStrLst = isOnlyLayer(ii~>master errStrLst ?lpp lpp) ) )
 ;check for non complement in cv
 when(result=foreach(mapcar ii setof(ii cv~>shapes ii~>lpp!=lpp) car(ii~>lpp))
  result = adListToSet(result) 
  errStrLst = append1(errStrLst strcat(cv~>cellName "," buildString(result))) );when
 errStrLst
)) ;proc

;check and save
procedure(checkAndSave(cells libName)
let( (cv)
  foreach(cc cells
    cv = dbOpenCellViewByType(libName cc "schematic" "schematic" "a")
    when(cv schCheck(cv) dbSave(cv) dbClose(cv) )
))
);procedure

;TECHNOLOGY DEPENDENT
procedure(placeLvqaPtap(d_laydb tapPinName @key (location nil) (libName "intel73lvqa") (cellName "ptap_tld"))
let((ptapMaster ptapInst pinMsFig pinFig tSize netName)
  adRemoveAllPins(d_laydb tapPinName) ;remove any tap names
  ptapMaster = dbOpenCellViewByType(libName cellName "layout")
  unless(location location=adGetWH(ptapMaster~>bBox) location = list(caar(d_laydb~>bBox)-car(location) cadadr(d_laydb~>bBox)+cadr(location)) )
  ptapInst = dbCreateInst(d_laydb ptapMaster symbolToString(gensym()) location "R0")
  foreach(terminal ptapInst~>master~>terminals
    pinMsFig = car(terminal~>pins)~>fig
    pinFig = dbCopyFig(pinMsFig d_laydb ptapInst~>transform)
    pinFig~>lpp = list(car(pinFig~>lpp) "pin")
    netName = car(setof(ii d_laydb~>nets ii~>name==tapPinName))
    dbCreatePin((if netName netName dbCreateNet(d_laydb tapPinName)) pinFig)
    tSize = (topEdge(pinFig~>bBox) - bottomEdge(pinFig~>bBox) )
    dbCreateLabel(d_laydb pinFig~>lpp centerBox(pinFig~>bBox) tapPinName "centerCenter" "R0" "stick" tSize)
  );foreach
  dbClose(ptapMaster)
));let;procedure

procedure( adDrawDiffChk(cv)
let( (llp urp maxY minY minX maxX y (dW 0.031) (dP 0.09))
  llp = car(cv~>bBox)              
  urp = cadr(cv~>bBox)
  minY = min(cadr(urp) cadr(llp))  maxY = max(cadr(urp) cadr(llp))  
  minX = car(llp)                  maxX = car(urp)
  y = -dW/2.0
  while(y < maxY   
    bBox = list(minX:y maxX:(y+dW)) y=y+dP
    dbCreateRect(cv list("diffCheck" "drawing") bBox)
  )
  y = dW/2.0 - dP
  while(y > minY   
    bBox = list(minX:(y-dW) maxX:y) y=y-dP
    dbCreateRect(cv list("diffCheck" "drawing") bBox)
  )
t))

procedure( adDrawPrInLib(libName)
let( (cv (lpp list("chkBoundary" "boundary")) )
  foreach(cell ddGetObj(libName)~>cells~>name
    cv = dbOpenCellViewByType(libName cell "layout" "maskLayout" "a")
    when(cv adDrawPr(cv) dbSave(cv) dbClose(cv) )
  );foreach
t))
procedure( adDrawPr(cv @optional (prb nil))
let( ((lpp list("chkBoundary" "boundary")))
  when(cv && (cv~>shapes || cv~>instances)
    if(and(!getShellEnvVar("PROCESSNAME")=="1276" (getShellEnvVar("TESTCHIP") || getShellEnvVar("SPCKT"))) then
      unless( setof(ii cv~>shapes ii~>lpp == lpp) dbCreateRect(cv lpp dbComputeBBoxNoNLP(cv)) )
      when(prb unless(cv~>prBoundary dbCreatePRBoundary(cv adListBBox(dbComputeBBoxNoNLP(cv))))   )
    else
      unless(cv~>prBoundary dbCreatePRBoundary(cv adListBBox(dbComputeBBoxNoNLP(cv))))  
  ))   
))

procedure( adGetBounds(shapes)
let( (xPoints yPoints xmin xmax ymin ymax temp)
  xPoints = foreach(mapcar ii shapes xCoord(car(ii~>bBox)))
  yPoints = foreach(mapcar ii shapes yCoord(car(ii~>bBox)))
  xPoints = sort(xPoints 'lessp)  xmin = car(xPoints)
  yPoints = sort(yPoints 'lessp)  ymin = car(yPoints)
  xPoints = foreach(mapcar ii shapes xCoord(cadr(ii~>bBox)))
  yPoints = foreach(mapcar ii shapes yCoord(cadr(ii~>bBox)))
  xPoints = sort(xPoints 'lessp)  xmax = car(last(xPoints))
  yPoints = sort(yPoints 'lessp)  ymax = car(last(yPoints))
  list(xmin:ymin xmax:ymax)
))
procedure( adSortLayers(layers)
let( (metals vias topMt topV others sortingMVFn outLst )
  ; get the metals
  metals = setof(ii layers pcreMatchp("^(m[a-z]*)\\d+" ii))   vias = setof(ii layers pcreMatchp("^(v[a-z]*)\\d+" ii))
  topMt = setof(ii layers pcreMatchp("^(tm|gm)\\d+" ii))     topV = setof(ii layers pcreMatchp("^(tv|gv)\\d+" ii))
  others = setof(ii layers !pcreMatchp("^([m|v][a-z]*\\d+|(tm|gm|tv|gv)\\d+)" ii))
  sortingMVFn = lambda( (x y) ;x/y must be of the form metal/via-number
   x = pcreMatchp("(m[a-z]*|v[a-z]*)(\\d+)" x)     x = cdfParseFloatString(pcreSubstitute("\\2"))
   y = pcreMatchp("(m[a-z]*|v[a-z]*)(\\d+)" y)     y = cdfParseFloatString(pcreSubstitute("\\2"))
   y > x)
  outLst = sort(others nil)
  outLst = append(outLst append(sort(metals sortingMVFn) sort(topMt nil)))
  outLst = append(outLst append(sort(vias sortingMVFn) sort(topV nil) ))
outLst 
))

procedure( adDrawRing(cv lpp bBox innerOffset)
let( (x y)
  x = car(innerOffset) y = cadr(innerOffset)
  rect1 = dbCreateRect(cv lpp bBox)  rect2 = dbCreateRect(cv lpp adReSizeBBox(bBox -x:-y -x:-y))
  dbLayerXor(cv lpp list(rect1) list(rect2))
  mapc('dbDeleteObject list(rect1 rect2))
t))


procedure( adProduceBox(cv rectIds spc)
let( (tmpShapes final)
  tmpShapes = dbLayerTile(cv car(rectIds)~>lpp rectIds)
  foreach(box tmpShapes~>bBox final = tconc(final list(rodSubPoints(car(box) spc:spc) rodAddPoints(cadr(box) spc:spc) )) )
  mapc('dbDeleteObject tmpShapes)
car(final) ))

procedure( adHiddenObj(cv location point)
let( (boxObjs)
mapc('dbDeleteObject cv~>markers)
boxObjs = adFlattenList(list(cv~>instances cv~>shapes cv~>blockages cv~>vias cv~>steiners))
case(location 
 ('above setof(ii boxObjs topEdge(ii~>bBox) > point))
 ('below setof(ii boxObjs bottomEdge(ii~>bBox) < point)) 
 ('right setof(ii boxObjs rightEdge(ii~>bBox) > point))
 ('left setof(ii boxObjs leftEdge(ii~>bBox) < point)) 
 (t error("bad location or point or cv")))
))

procedure( adGetPointBack(point orientation wl)
case(orientation
  ("R0" point)
  ("MX" rodAddToY(point yCoord(wl)))
  ("MY" rodAddToX(point xCoord(wl)))
  ("R180" rodAddPoints(point wl))
))

procedure( adTestFillBP(libName cellName tgtLib tgtCell)
let( (cv tgt comb orig count effOrig)
  cv = dbOpenCellViewByType(libName cellName "layout")
  tgt = dbOpenCellViewByType(tgtLib tgtCell "layout" "maskLayout" "w")
  comb = list("R0" "R180" "MX" "MY") orig = 0:0  xy = adGetWH(adGetPrBoundary(cv)~>bBox) count = 0 effOrig = 0:0
  foreach(orient1 comb
    foreach(orient2 comb
      dbCreateInst(tgt cv nil adGetPointBack(orig orient1 xy) orient1) 
      dbCreateLabel(tgt "text" rodAddPoints(orig car(xy)/2:cadr(xy)/2) orient1 "centerCenter" "R0" "stick" 0.2*cadr(xy))
      orig = rodAddToX(orig car(xy))
      dbCreateInst(tgt cv nil adGetPointBack(orig orient2 xy) orient2) count++ 
      dbCreateLabel(tgt "text" rodAddPoints(orig car(xy)/2:cadr(xy)/2) orient2 "centerCenter" "R0" "stick" 0.2*cadr(xy))      
      orig = car(effOrig):yCoord(rodAddToY(orig cadr(xy)))
      when(mod(count (length(comb)**2)/2) == 0 orig = car(orig)+2*car(xy):0 effOrig = orig)
  )) ;;foreachs
  effOrig = orig  count = 0
  foreach(orient1 comb
    foreach(orient2 comb
      dbCreateInst(tgt cv nil adGetPointBack(orig orient1 xy) orient1) count++
      dbCreateLabel(tgt "text" rodAddPoints(orig car(xy)/2:cadr(xy)/2) orient1 "centerCenter" "R0" "stick" 0.2*cadr(xy))
      orig = rodAddToY(orig cadr(xy))
      dbCreateInst(tgt cv nil adGetPointBack(orig orient2 xy) orient2) count++
      dbCreateLabel(tgt "text" rodAddPoints(orig car(xy)/2:cadr(xy)/2) orient2 "centerCenter" "R0" "stick" 0.2*cadr(xy))      
      orig = rodAddToY(orig cadr(xy))
      when(mod(count (length(comb)**2)/2) == 0 orig = xCoord(orig)+car(xy):0)
  )) ;;foreachs
dbSave(tgt) dbClose(cv) dbClose(tgt)
t))

procedure( adIsBBox(bBox)
let( (xy)
  xy = adGetWH(bBox)
  when(car(xy) > 0 && cadr(xy) > 0  t)
))
