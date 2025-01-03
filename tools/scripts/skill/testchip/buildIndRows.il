;##############################################################################
;# Intel Top Secret                                                           #
;##############################################################################
;Report bugs to Mauricio Marulanda
load("/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/skill/cdsinit")
;;;; MAIN SCRIPT
procedure( adBuildIndRows(tgtLib csvCatalog specCsvFile)
let( (rowNameNoH rowH padLoc shExt libCell dpl catalog)
  ;; read the catalog and specCsvFile as dpl tables
  dpl = adTCVariables(specCsvFile) catalog = adReadIndCatalog(csvCatalog)
  ;; build the rows
  foreach(rowTpl catalog~>?
    rowNameNoH = pcreReplace(pcreCompile("_\\d+x$") rowTpl "" 0 ) 
    rowH = pcFix(cdfParseFloatString(catalog[rowTpl]["rowH"]))  padLoc = catalog[rowTpl]["padLoc"]  shExt = cdfParseFloatString(catalog[rowTpl]["shExt"])
    duts = catalog[rowTpl]["duts"]
    ;; build empty row
    libCell = adBeginIndRow(tgtLib rowNameNoH rowH padLoc shExt specCsvFile nil)
    ;; place the duts
    adPlaceDuts(car(libCell) cadr(libCell) duts rowH padLoc specCsvFile)
    ;; fill with the top layers
    adAddTopFill(car(libCell) cadr(libCell) specCsvFile)
    printf("Created ROW %s : %s\n" car(libCell) cadr(libCell) )  
  ); foreach
t))

;;;; BUILD EMPTY ROW
procedure( adBeginIndRow(lib rowName rowH padLoc shieldExt specCsvFile @optional (printl t)) ; library rowName rowHeight (bottom top both) (gndunder leads) spec
let( (pad tp0fill fill rowCv dpl)
  rowName = sprintf(nil "%s_%dx" rowName pcFix(rowH))
  ;; property bag
  dpl = adTCVariables(specCsvFile)
  ;; build padrow name_padrow to pass HCK
  pad = dbOpenCellViewByType(lib strcat(rowName "_padrow") "layout" "maskLayout" "w")
  adBuildPadRow(pad rowH padLoc dpl)
  ;; build fill name_filler and name_fill to pass HCK 
  tp0fill = dbOpenCellViewByType(lib strcat(rowName "_filler") "layout" "maskLayout" "w")
  adAddEdgeFill(tp0fill rowH dpl)
  ;; build the row fill
  fill = dbOpenCellViewByType(lib strcat(rowName "_fill") "layout" "maskLayout" "w")
  adBuildFiller(fill rowH padLoc shieldExt dpl)
  ;; place at the top
  rowCv = dbOpenCellViewByType(lib rowName "layout" "maskLayout" "w")
  dbCreateInst(rowCv pad "padrow" 0:0 "R0") dbCreateInst(rowCv fill "customFiller" 0:0 "R0") dbCreateInst(rowCv tp0fill "tp0Filler" 0:0 "R0")
  ;; place the top polygon layers to pass HCK
  bBox = list(0:0 car(dpl~>rowSize):cadr(dpl~>rowSize)*rowH)
  dbCreateRect(rowCv list("testRowMod" "boundary") adReSizeBBox(bBox -1m:-1m -1m:-1m)) dbCreateRect(rowCv list("chkBoundary" "boundary") bBox) dbCreatePRBoundary(rowCv adListBBox(bBox))
  ;; add to category and prBoundary
  cat = ddCatOpen(ddGetObj(lib) rowName "a")
  foreach(cv list(pad fill tp0fill rowCv) ddCatAddItem(cat cv~>cellName "cell")) ddCatSave(cat) ddCatClose(cat)
  ;; close all
  mapc('dbSave list(rowCv pad fill tp0fill))  mapc('dbPurge list(rowCv pad fill tp0fill)); filler remove;;;;;;;;;
  when(printl println(sprintf(nil "... Finished building empty %s : %s" lib rowName)))
list(lib rowName)
))

;;;;;; PLACE DUTS
procedure(adPlaceDuts(libName cellName duts rowH padLoc specCsvFile)
let( (cv dpl dutCv dutPoints point inst (dutLoc "") (dutPerRow 5) cat)
  cv = dbOpenCellViewByType(libName cellName "layout" "maskLayout" "a")   cat = ddCatOpen(ddGetObj(libName) cellName "a")  
  dpl = adTCVariables(specCsvFile) 
  ii = 0 dutPoints = list(nil)
  ; dutPoints
  foreach(dd '(duta dutb dutc dutd dute dutf dutg duth duti dutj) 
    dutPoints = append(dutPoints list(dd rodAddToX(dpl~>dutOrigin ii*dpl~>dutPitch))) ii+=1 
    when(ii==dutPerRow ii=0) );foreach    
  ; place the duts
  foreach(dut duts
    dutCv = dbOpenCellViewByType(car(dut) cadr(dut) "layout") ddCatAddItem(cat dutCv~>cellName "cell")
    point = get(dutPoints nth(2 dut)) 
    when(padLoc=="both" dutLoc = "b")
    when(member(padLoc list("bottom" "both")) inst = dbCreateInst(cv dutCv strcat(nth(2 dut) dutLoc) point "R0") 
                                              adAddBlockages(cv parseString(dpl~>rowBlockages) dbTransformBBox(adGetChkBoundary(dutCv) inst~>transform) nil) 
					      adAddBlockages(cv parseString(dpl~>indLayers) dbTransformBBox(adGetChkBoundary(dutCv) inst~>transform) ) )
    when(padLoc=="both" dutLoc = "t")
    point = dbTransformPoint(point list(0:rowH*cadr(dpl~>rowSize) "MX" 1))
    when(member(padLoc list("top"    "both")) inst = dbCreateInst(cv dutCv strcat(nth(2 dut) dutLoc) point "MX")
                                              adAddBlockages(cv parseString(dpl~>rowBlockages) dbTransformBBox(adGetChkBoundary(dutCv) inst~>transform) nil) 
    				              adAddBlockages(cv parseString(dpl~>indLayers) dbTransformBBox(adGetChkBoundary(dutCv) inst~>transform) ) ) 
   );foreach
  dbSave(cv) dbClose(cv) ddCatSave(cat) ddCatClose(cat)
t))

;;;;; PLACE top inductor Fill
procedure( adAddTopFill(lib rowName specCsvFile)
let( (box boxWH cv cvTgt etestOffset space)
  dpl = adTCVariables(specCsvFile)
  cv = dbOpenCellViewByType(lib rowName "layout")  cvTgt = dbOpenCellViewByType(lib strcat(rowName "_fill") "layout" "maskLayout" "a")
  etestOffset = adGetEtestOffset(dpl)
  box = adReSizeBBox(adGetChkBoundary(cv) -car(etestOffset):-cadr(etestOffset) -car(etestOffset):-cadr(etestOffset))
  foreach(fill setof(ii dpl~>? pcreMatchp("topFill\\d+" ii))
    space = cdfParseFloatString(caddr(get(dpl fill))||0)  fill = dbOpenCellViewByType(car(get(dpl fill)) cadr(get(dpl fill)) "layout") 
    adInstFillCustomLayout(cv fill space ?cvTgt cvTgt ?chkBox box ?approx "floor")  dbClose(fill) );  adInstFillCustomLayout(cv fill 0 ?cvTgt cvTgt ?layers list("gmb") ?chkBox box ?approx "floor")    dbClose(fill)
  when(dpl~>diffChk adDrawDiffChk(cvTgt))
  dbClose(cv) dbSave(cvTgt) dbClose(cvTgt)
t))

;;;;; BUILD THE FILLER
procedure( adBuildFiller(cv rowH padLoc shExt dpl)
let( (ulCv llCv urCv lrCv leftCv topCv rightCv botCv bBox etestOffset)
  ;; open the cells necessary
  ulCv = dbOpenCellViewByType(car(dpl~>ulcEtestToRf) cadr(dpl~>ulcEtestToRf) "layout")   urCv = dbOpenCellViewByType(car(dpl~>urcEtestToRf) cadr(dpl~>urcEtestToRf) "layout")
  llCv = dbOpenCellViewByType(car(dpl~>llcEtestToRf) cadr(dpl~>llcEtestToRf) "layout")   lrCv = dbOpenCellViewByType(car(dpl~>lrcEtestToRf) cadr(dpl~>lrcEtestToRf) "layout")
  leftCv = dbOpenCellViewByType(car(dpl~>lefEtestToRf) cadr(dpl~>lefEtestToRf) "layout") rightCv = dbOpenCellViewByType(car(dpl~>rigEtestToRf) cadr(dpl~>rigEtestToRf) "layout")
  topCv = dbOpenCellViewByType(car(dpl~>topEtestToRf) cadr(dpl~>topEtestToRf) "layout")  botCv =dbOpenCellViewByType(car(dpl~>botEtestToRf) cadr(dpl~>botEtestToRf) "layout")
  ;; get the first BBOX and place the ring of EtestToRF get its size and give new offset
  edgeCv = dbOpenCellViewByType(car(dpl~>etestFill) cadr(dpl~>etestFill) "layout")
  etestOffset = adGetEtestOffset(dpl)
  bBox = list(etestOffset rodSubPoints(car(dpl~>rowSize):rowH*cadr(dpl~>rowSize) etestOffset))
  bBox = adCreateRng(cv bBox llCv ulCv urCv lrCv leftCv rightCv topCv botCv) 
  mapc('dbClose list(ulCv llCv urCv lrCv leftCv topCv rightCv botCv))
  ;; place the fillers around the pads
  bBox = adFillAroundPads(cv rowH bBox padLoc shieldExt dpl)  
  ;; get the second box and place the ring of RFtoInd
  leftCv = dbOpenCellViewByType(car(dpl~>lefRfToInd) cadr(dpl~>lefRfToInd) "layout") rightCv = dbOpenCellViewByType(car(dpl~>rigRfToInd) cadr(dpl~>rigRfToInd) "layout")
  topCv = dbOpenCellViewByType(car(dpl~>topRfToInd) cadr(dpl~>topRfToInd) "layout")  botCv =dbOpenCellViewByType(car(dpl~>botRfToInd) cadr(dpl~>botRfToInd) "layout")
  bBox = adCreateRng(cv bBox leftCv leftCv rightCv rightCv leftCv rightCv topCv botCv) ;llCv ulCv urCv lrCv leftCv RightCv topCv botCv)
  mapc('dbClose list(leftCv rightCv topCv botCv))
  ;; place the Fill
  adFillBaseHdLd(cv bBox padLoc rowH dpl)
t))

;;;;; BUILD AROUND DUTS
procedure( adFillBaseHdLd(cv bBox padLoc rowH dpl)
let( (point effBBox placeFill fillSize)
  placeFill = lambda((effBBox tipo) foreach(baseFill setof(ii dpl~>? pcreMatchp(strcat("base" tipo "Fill\\d+") ii)) baseFill = dbOpenCellViewByType(car(get(dpl baseFill)) cadr(get(dpl baseFill)) "layout")      adPlaceMosaic(cv effBBox baseFill) dbClose(baseFill)) ) 
  fillSize = adGetWH(bBox)
  ; place sides of the DUTs
  effBBox = list(car(bBox) car(dpl~>dutOrigin):topEdge(bBox)) ; left most side
  apply(placeFill list(effBBox "Hd"))
  for(ii 0 3 ; middle
    point = rodAddToX(car(dpl~>dutOrigin)+car(dpl~>dutSize):cadar(bBox) ii*dpl~>dutPitch) effBBox = list(point car(point)+dpl~>dutPitch-car(dpl~>dutSize):topEdge(bBox))
    apply(placeFill list(effBBox "Hd"))  ); for
  effBBox = list(rodAddToX(car(effBBox) dpl~>dutPitch) cadr(bBox)); right most side
  apply(placeFill list(effBBox "Hd"));
  ; place fill under Duts
  for(ii 0 4
    point = car(dpl~>dutOrigin)+ii*dpl~>dutPitch:bottomEdge(bBox) 
    effBBox = list(point car(point)+car(dpl~>dutSize):if(cadr(dpl~>dutOrigin)+cadr(dpl~>dutSize) < topEdge(bBox) cadr(dpl~>dutOrigin)+cadr(dpl~>dutSize) topEdge(bBox)))    
    when(member(padLoc list("both" "bottom")) apply(placeFill list(effBBox "Ld"))) 
    effBBox = dbTransformBBox(effBBox list(0:rowH*cadr(dpl~>rowSize) "MX" 1))
    when(member(padLoc list("both" "top")) apply(placeFill list(effBBox "Ld")))   ); for
  ; place above Duts (bottom for top)
  for(ii 0 4
    point = rodAddPoints(dpl~>dutOrigin ii*dpl~>dutPitch:cadr(dpl~>dutSize)) 
    when(member(padLoc list("bottom" "both")) effBBox = list(point car(point)+car(dpl~>dutSize):if(padLoc=="bottom"  topEdge(bBox) -cadr(point)+rowH*cadr(dpl~>rowSize)) ) )  
    when(padLoc == "top" point = dbTransformPoint(point list(0:rowH*cadr(dpl~>rowSize) "MX" 1)) effBBox =  list(car(point):bottomEdge(bBox) car(point)+car(dpl~>dutSize):cadr(point)) )
    when(topEdge(effBBox)>bottomEdge(effBBox) apply(placeFill list(effBBox "Hd")) )      
  ); for
t))

;;;;; BUILD AROUND PADS
procedure( adFillAroundPads(cv rowH bBox padLoc shExt dpl)
let( (rfFill point rows cols mosaics flip inst padNum)
  flip = lambda((x y) dbTransformPoint(x list(0:rowH*cadr(dpl~>rowSize)+y "MX" 1)))
  rfFill = dbOpenCellViewByType(car(dpl~>rfFill) cadr(dpl~>rfFill) "layout") grid = adGetWH(adGetChkBoundary(rfFill))
  pads = dbOpenCellViewByType(car(dpl~>gndPad) cadr(dpl~>gndPad) "layout") padWH = adGetWH(adGetChkBoundary(pads)) dbClose(pads)
  padNum = adFittingPads(car(dpl~>rowSize)-car(dpl~>padOrigin) dpl~>padPitch car(padWH) "odd")
  ;; bottom lines share the same number of rows
  point = car(bBox)  cols = pcFix((rightEdge(bBox)-leftEdge(bBox))/car(grid))  rows = pcFix((cadr(dpl~>padOrigin)-bottomEdge(bBox))/cadr(grid))
  when(member(padLoc list("bottom" "both")) dbCreateSimpleMosaic(cv rfFill nil point "R0" rows cols cadr(grid) car(grid)) )
  when(member(padLoc list("top" "both")) dbCreateSimpleMosaic(cv rfFill nil apply(flip list(point -cadr(grid)*rows)) "R0" rows cols cadr(grid) car(grid)) )
  ;; left share the same number of rows 
  point = rodAddToY(car(bBox) rows*cadr(grid)) rows = pcFix(cadr(padWH)/cadr(grid))
  cols = pcFix((car(dpl~>padOrigin)-car(point))/car(grid))
  mosaics = tconc(mosaics dbCreateSimpleMosaic(cv rfFill nil point "R0" rows cols cadr(grid) car(grid)) )
  ;; between share the same number of rows
  cols = pcFix((dpl~>padPitch-car(padWH))/car(grid))  point = rodAddToX(dpl~>padOrigin car(padWH)) pp=0
  while(pp<=padNum-2 mosaics = tconc(mosaics dbCreateSimpleMosaic(cv rfFill nil point "R0" rows cols cadr(grid) car(grid))) point=rodAddToX(point dpl~>padPitch) pp+=1)
  ;; right share the same number of rows
  cols = pcFix((xCoord(cadr(bBox))-car(point))/car(grid)) mosaics = tconc(mosaics dbCreateSimpleMosaic(cv rfFill nil point "R0" rows cols cadr(grid) car(grid)))
  ;; copy or move to the top left/between/right fills
  offset = 0:yCoord(apply(flip list(0:cadr(point) -rows*cadr(grid))))-yCoord(point) ; if necessary
  when(padLoc == "top" foreach(mosaic car(mosaics) dbMoveFig(mosaic cv list(offset "R0" 1)) )  )
  when(padLoc == "both" foreach(mosaic car(mosaics) dbCopyFig(mosaic cv list(offset "R0" 1)) )  )
  ;; top lines
  point = caar(bBox):yCoord(point)+rows*cadr(grid) cols = pcFix((rightEdge(bBox)-leftEdge(bBox))/car(grid)) rows = if(shExt > cadr(grid) pcFix(shExt/cadr(grid)) 1)
  mosaics = dbCreateSimpleMosaic(cv rfFill nil point "R0" rows cols cadr(grid) car(grid))
  offset = 0:yCoord(apply(flip list(0:cadr(point) -rows*cadr(grid))))-yCoord(point) ; if necessary
  when(padLoc == "top" inst=dbMoveFig(mosaics cv list(offset "R0" 1)) )  
  when(padLoc == "both" inst=dbCopyFig(mosaics cv list(offset "R0" 1)) )    dbClose(rfFill)
  ;; comput box
  case(padLoc  ("bottom" bBox = list(rodAddToY(point rows*cadr(grid)) cadr(bBox)) )
               ("top"    bBox = list(car(bBox) rightEdge(bBox):cadr(inst~>xy)) )
	       ("both"   bBox = list(rodAddToY(point rows*cadr(grid)) rightEdge(bBox):cadr(inst~>xy)) ) )
bBox))

;;;;; BUILD THE PADROW
procedure( adBuildPadRow(cv rowH padLoc dpl)
let( (gnd sig effCv pad name (padLocName "") (pp 1) (points list()) pads padWH effBox)
  gnd = dbOpenCellViewByType(car(dpl~>gndPad) cadr(dpl~>gndPad) "layout") sig = dbOpenCellViewByType(car(dpl~>sigPad) cadr(dpl~>sigPad) "layout")  pad = list(gnd sig) 
  padWH = adGetWH(adGetChkBoundary(gnd))
  pads = adFittingPads(car(dpl~>rowSize)-car(dpl~>padOrigin) dpl~>padPitch car(padWH) "odd")
  when(member(padLoc list("bottom" "both")) points = append1(points dpl~>padOrigin))
  when(member(padLoc list("top" "both")) points = append1(points rodAddToY(dpl~>padOrigin cadr(dpl~>rowSize)*rowH-2*cadr(dpl~>padOrigin)-cadr(padWH))) )
  ; place the g s g
  foreach(point points
   when(padLoc=="both" padLocName = if(pp==1 "b" "t") )    pp = 1
   while(pp<=pads ; number of pad sets
    name = sprintf(nil "pad%d%s" pp padLocName) effCv = if(oddp(pp) gnd sig) 
    dbCreateInst(cv effCv name point "R0") pointText = rodAddPoints(point centerBox(effCv~>bBox)) 
    effBox = list(point rodAddPoints(point padWH))  adAddBlockages(cv parseString(dpl~>indLayers) effBox) ;; add KORs of Inductor layers to pads minimum
    when(evenp(pp) adAddBlockages(cv parseString(dpl~>rowBlockages) adReSizeBBox(effBox car(padWH)/2:cadr(padWH)/4 car(padWH)/2:cadr(padWH)/4) nil)) ;; add KORS CEs/BUMPs to Signal Pads
    dbCreateLabel(cv list(dpl~>bump "drawing") pointText name "centerCenter" "R0" "stick" 21)   
    dbCreateLabel(cv list("text" "drawing") pointText sprintf(nil "%d" pp) "centerCenter" "R0" "stick" 21)   
    point = rodAddToX(point dpl~>padPitch) pp++))
  dbClose(gnd) dbClose(sig)   
  ; place the weird layers to pass HCK and the halo
  rodCreateRect(?cvId cv ?name "rowBoundary" ?length rowH*cadr(dpl~>rowSize) ?width car(dpl~>rowSize) ?layer list("testRow" "boundary")); 
  when(dpl~>haloLayer && !blankstrp(dpl~>haloLayer) adDrawRing(cv dpl~>haloLayer list(0:0 car(dpl~>rowSize):rowH*cadr(dpl~>rowSize)) car(dpl~>haloSize):cadr(dpl~>haloSize)))
  ; place the gnds
  adGndPadRowConn(cv rowH padLoc padWH dpl)
t))

;; CREATE THE RING FN
procedure( adCreateRng(cv bBox llCv ulCv urCv lrCv leftCv rightCv topCv botCv @key (flatten nil)) ;cornerBotLef cornerTopLef cornerTopRig cornerBotRig left right top bot
let( (point llc ulc urc lrc rows cols mosaics)
  ; place the corners
  point = car(bBox)                                                                         llc = dbCreateInst(cv llCv nil car(bBox) "R0")
  point = rodAddToY(leftEdge(bBox):topEdge(bBox) -cadr(adGetWH(adGetChkBoundary(ulCv))))    ulc = dbCreateInst(cv ulCv nil point "R0")
  point = rodSubPoints(rightEdge(bBox):topEdge(bBox) adGetWH(adGetChkBoundary(urCv)))       urc = dbCreateInst(cv urCv nil point "R0")  
  point = rodAddToX(rightEdge(bBox):bottomEdge(bBox) -car(adGetWH(adGetChkBoundary(lrCv)))) lrc = dbCreateInst(cv lrCv nil point "R0")  
  ; place the lines
  point = rodAddToY(llc~>xy cadr(adGetWH(adGetChkBoundary(llCv)))) grid = adGetWH(adGetChkBoundary(leftCv)) 
  rows = pcFix((yCoord(ulc~>xy)-yCoord(point))/cadr(grid))  tmp = dbCreateSimpleMosaic(cv leftCv nil point "R0" rows 1 cadr(grid) car(grid))  mosaics = tconc(mosaics tmp)
  point = rodAddToX(ulc~>xy car(adGetWH(adGetChkBoundary(ulCv)))) grid = adGetWH(adGetChkBoundary(topCv)) 
  cols = pcFix((xCoord(urc~>xy)-xCoord(point))/car(grid))  tmp = dbCreateSimpleMosaic(cv topCv nil point "R0" 1 cols cadr(grid) car(grid))  mosaics = tconc(mosaics tmp)
  point = rodAddToX(llc~>xy car(adGetWH(adGetChkBoundary(llCv)))) grid = adGetWH(adGetChkBoundary(botCv)) 
  cols = pcFix((xCoord(lrc~>xy)-xCoord(point))/car(grid))  tmp = dbCreateSimpleMosaic(cv botCv nil point "R0" 1 cols cadr(grid) car(grid))  mosaics = tconc(mosaics tmp)
  point = rodAddToY(lrc~>xy cadr(adGetWH(adGetChkBoundary(lrCv)))) grid = adGetWH(adGetChkBoundary(rightCv)) 
  rows = pcFix((yCoord(urc~>xy)-yCoord(point))/cadr(grid))  
  tmp = dbCreateSimpleMosaic(cv rightCv nil point "R0" rows 1 cadr(grid) car(grid)) mosaics = tconc(mosaics tmp)
  ; if flatten
  when(flatten foreach(ii list(llc ulc urc lrc) dbFlattenInst(ii 1)) foreach(ii car(mosaics) dbFlattenInst(ii 2)))
  ; get the final box
  bBox = list(rodAddPoints(llc~>xy adGetWH(adGetChkBoundary(llCv))) urc~>xy)
))

;;;;;;; READ THE CELLS and Variables
procedure( adTCVariables(csv) ; the input changes with technology
let( (dpl tech prop value currentTech numExp)
  numExp = "([+-]?\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?)"
  csv = adReadCsv(csv)
  dpl = gensym() currentTech = car(parseString(getShellEnvVar("DR_PROCESSNAME") || getShellEnvVar("PROJECT") "p"))
  foreach(temp adZip(get(csv nth(0 csv~>?)) get(csv nth(1 csv~>?)) get(csv nth(2 csv~>?))); technology,prop,value
    tech = nth(0 temp) prop = nth(1 temp) value = nth(2 temp)
    when(pcreMatchp("\"(.+)\"" value) value = pcreSubstitute("\\1")) ;remove quotes
    cond(  ; convert numbers and lists
      (pcreMatchp(strcat(numExp ":" numExp) value) value = mapcar('cdfParseFloatString parseString(value ":")))
      (pcreMatchp(strcat("^\\s*" numExp "\\s*$") value) value = cdfParseFloatString(value))
      (pcreMatchp("\\w+:\\w+" value) value = parseString(value ":") ) 
    )
    when(currentTech == tech putprop(dpl value prop)) 
  );foreach
dpl ))

;;;;; DRAW GND CONNECTIONS
procedure( adGndPadRowConn(cv rowH padLoc padWH dpl)
let( (orig layer box rects (spcDown 10) (gndWL 8) (gndMax 12) pads)
  pads = adFittingPads(car(dpl~>rowSize)-car(dpl~>padOrigin) dpl~>padPitch car(padWH) "odd") 
  orig = rodAddToY(dpl~>padOrigin -spcDown-gndWL) layer = car(parseString(dpl~>indLayers))
  box = list(orig rodAddPoints(orig (pads-1)*dpl~>padPitch+car(padWH):gndWL))
  rects = tconc(rects rodCreateRect(?cvId cv ?layer layer ?origin orig ?width (pads-1)*dpl~>padPitch+car(padWH) ?length 8))
  rects = tconc(rects rodCreateRect(?cvId cv ?layer layer ?origin rodAddPoints(dpl~>padOrigin car(padWH)/2.0-gndMax/2.0:-spcDown) 
                ?width gndMax ?length spcDown ?spaceX dpl~>padPitch*2-gndMax ?elementsX pcFix((pads+1)/2.0)))
  foreach(rect adFlattenList(car(rects)) 
    when(padLoc == "top" dbMoveFig(rect~>dbId cv list(0:rowH*cadr(dpl~>rowSize) "MX" 1)))  
    when(padLoc == "both" dbCopyFig(rect~>dbId cv list(0:rowH*cadr(dpl~>rowSize) "MX" 1))) )
))

;;;;;; CREATE TABLE FOR INDUCTOR
procedure(adReadIndCatalog(csv)
let( (rowName dut lib rowH padLoc shExt dutName)
  csv = adReadCsv(csv)  out = gensym() outTable = makeTable(gensym())
  foreach(line adZip(csv~>rowName csv~>dutName csv~>libName csv~>height csv~>padLoc csv~>shieldExt)
    rowName = nth(0 line) dut = nth(1 line) lib = nth(2 line) rowH = nth(3 line) padLoc = nth(4 line) shExt = nth(5 line)
    unless(member(rowName outTable~>?) 
      outTable[rowName] = makeTable(gensym()) ;initialize the row
      foreach(item list("lib" "rowH" "padLoc" "shExt") outTable[rowName][item] = evalstring(item))
      outTable[rowName]["rowH"] = pcreReplace(pcreCompile("x") outTable[rowName]["rowH"] "" 0)
      outTable[rowName]["duts"] = list() );foreach
    pcreMatchp("(dut[a-z])" dut) dutName=pcreSubstitute("\\1")
    outTable[rowName]["duts"] = append1(outTable[rowName]["duts"] list(lib dut dutName))
  );foreach
outTable
))

;;;; PLACE EDGE FILLER
procedure( adAddEdgeFill(cv rowH dpl)
let( (edgeCv bBox)
  edgeCv = dbOpenCellViewByType(car(dpl~>etestFill) cadr(dpl~>etestFill) "layout")
  bBox = list(0:0 car(dpl~>rowSize):rowH*cadr(dpl~>rowSize))
  bBox = adCreateRng(cv bBox edgeCv edgeCv edgeCv edgeCv edgeCv edgeCv edgeCv edgeCv ?flatten t) ;llCv ulCv urCv lrCv leftCv RightCv topCv botCv)
  dbClose(edgeCv)
cv))

;;;; GET Etest Offset
procedure( adGetEtestOffset(dpl)
let( (cv offset)
  cv = dbOpenCellViewByType(car(dpl~>etestFill) cadr(dpl~>etestFill) "layout")
  offset = adGetWH(adGetChkBoundary(cv))
  dbClose(cv)
offset))

;;;; PLACE MOSAIC in BOX 
procedure( adPlaceMosaic(cv box mosCv)
let( (boxWH grid rows cols)
  boxWH = adGetWH(box)
  grid = adGetWH(adGetChkBoundary(mosCv))
  rows = pcFix(cadr(boxWH)/cadr(grid)) cols = pcFix(car(boxWH)/car(grid))
  dbCreateSimpleMosaic(cv mosCv nil car(box) "R0" rows cols cadr(grid) car(grid))
))

;;;;; CREATE BLOCKAGES
procedure( adAddBlockages(cv layers bBox @optional (kor t))
when(adIsBBox(bBox)
  foreach(layer layers
    if(kor dbCreateLayerBlockage(cv layer "routing" adListBBox(bBox))
           dbCreateRect(cv list(layer "keepGenAway") bBox)) )
));proc


;;;;; PADS that can fit multiple of the combo
procedure( adFittingPads(fullW pitch w combo) ; g s g or s s  --> odd or even combo
let( (pads rem)
  pads = floor(1.0*fullW/pitch) ; number of pads with the pitch spacing
  rem = fullW - pads*pitch*1.0 ;; see if one more can fit
  when(rem > w pads++)
  when(combo == "odd" && evenp(pads) pads--)
  when(combo == "even" && oddp(pads) pads--)
pads))
