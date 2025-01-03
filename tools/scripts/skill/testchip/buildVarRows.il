;##############################################################################
;# Intel Top Secret                                                           #
;##############################################################################
;Report bugs to Mauricio Marulanda

load("/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/skill/cdsinit")
load("/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/skill/testchip/buildIndRows.il")
;;;; MAIN SCRIPT
procedure( adBuildVarRows(tgtLib csvCatalog specCsvFile)
let( (rowNameNoH rowH duts libCell dpl catalog)
  ;; read the catalog and specCsvFile as dpl tables
  dpl = adTCVariables(specCsvFile) catalog = adReadVarCatalog(csvCatalog)
  ;; build the rows
  foreach(rowTpl catalog~>?
    rowNameNoH = pcreReplace(pcreCompile("_\\d+x$") rowTpl "" 0 ) 
    rowH = pcFix(cdfParseFloatString(catalog[rowTpl]["rowH"]))
    ;; build empty row
    libCell = adBeginVarRow(tgtLib rowNameNoH rowH specCsvFile nil)
    ;; place the duts
    duts = catalog[rowTpl]["duts"]    
    adPlaceVarDuts(car(libCell) cadr(libCell) duts rowH specCsvFile)
    ;; fill with the top layers
    adAddTopFill(car(libCell) cadr(libCell) specCsvFile)
    printf("Created ROW %s : %s\n" car(libCell) cadr(libCell) )  
  ); foreach
t))

;;;; BUILD EMPTY ROW
procedure( adBeginVarRow(lib rowName rowH specCsvFile @optional (printl t)) ; library rowName rowHeight (bottom top both) (gndunder leads) spec
let( (pad tp0fill fill rowCv dpl)
  rowName = sprintf(nil "%s_%dx" rowName pcFix(rowH))
  ;; property bag
  dpl = adTCVariables(specCsvFile)
  ;; build padrow name_padrow to pass HCK
  pad = dbOpenCellViewByType(lib strcat(rowName "_padrow") "layout" "maskLayout" "w")
  adBuildVarPadRow(pad rowH dpl)
  ;; build fill name_filler and name_fill to pass HCK 
  tp0fill = dbOpenCellViewByType(lib strcat(rowName "_filler") "layout" "maskLayout" "w")
  adAddEdgeFill(tp0fill rowH dpl)
  ;; build the row fill
  fill = dbOpenCellViewByType(lib strcat(rowName "_fill") "layout" "maskLayout" "w") 
  adBuildVarFiller(fill rowH dpl)
  ;; place at the top
  rowCv = dbOpenCellViewByType(lib rowName "layout" "maskLayout" "w")
  dbCreateInst(rowCv pad "padrow" 0:0 "R0") dbCreateInst(rowCv fill "customFiller" 0:0 "R0")  dbCreateInst(rowCv tp0fill "tp0Filler" 0:0 "R0")
  ;; place the top polygon layers to pass HCK
  bBox = list(0:0 car(dpl~>rowSize):cadr(dpl~>rowSize)*rowH)
  dbCreateRect(rowCv list("testRowMod" "boundary") adReSizeBBox(bBox -1m:-1m -1m:-1m)) dbCreateRect(rowCv list("chkBoundary" "boundary") bBox) dbCreatePRBoundary(rowCv adListBBox(bBox))
  ;; add to category and prBoundary
  cat = ddCatOpen(ddGetObj(lib) rowName "a")
  foreach(cv list(pad fill tp0fill rowCv) ddCatAddItem(cat cv~>cellName "cell")) ddCatSave(cat) ddCatClose(cat)
  ;; close all
  mapc('dbSave list(rowCv pad fill tp0fill))  mapc('dbPurge list(rowCv pad fill tp0fill )); filler remove;;;;;;;;;
  when(printl println(sprintf(nil "... Finished building empty %s : %s" lib rowName)))
list(lib rowName)
))

;;;;; BUILD THE FILLER
procedure( adBuildVarFiller(cv rowH dpl)
let( (ulCv llCv urCv lrCv leftCv topCv rightCv botCv bBox etestOffset dutFill)
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
  bBox = adFillAroundVarPads(cv rowH bBox dpl)  
  ;; place fillers where the duts are
  adFillOnVarDuts(cv bBox dpl)  
t))

;;;;;; PLACE DUTS
procedure(adPlaceVarDuts(libName cellName duts rowH specCsvFile)
let( (cv dpl dutCv dutPoint dutLst dutOr inst cat cc rr pads padWH)
  cv = dbOpenCellViewByType(libName cellName "layout" "maskLayout" "a")   cat = ddCatOpen(ddGetObj(libName) cellName "a") 
  dpl = adTCVariables(specCsvFile)  rowH = rowH*cadr(dpl~>rowSize)
  pads = dbOpenCellViewByType(car(dpl~>gndPad) cadr(dpl~>gndPad) "layout") padWH = adGetWH(adGetChkBoundary(pads)) dbClose(pads)
  dutLst = mapcar('caddr duts) dutLst = sort(dutLst nil)   ; sort the duts
  cc=0 rr=0 dutOr=rodAddPoints(dpl~>padOrigin car(padWH):dpl~>padPitchY) 
  foreach(dd dutLst ; go for each
    dutCv = car(setof(ii duts nth(2 ii) == dd)) dutCv = dbOpenCellViewByType(car(dutCv) cadr(dutCv) "layout")  ddCatAddItem(cat dutCv~>cellName "cell");; select dut
    ;; prepare the location and place the dut with blockages
    dutPoint = rodAddPoints(dutOr 2*cc*dpl~>padPitchX:2*rr*dpl~>padPitchY) rr++
    inst = dbCreateInst(cv dutCv dd dutPoint "R0")
    adAddBlockages(cv parseString(dpl~>rowBlockages) dbTransformBBox(adGetChkBoundary(dutCv) inst~>transform) nil) dbClose(dutCv)
    when(rowH < cadr(dutOr)+2*rr*dpl~>padPitchY+cadr(dpl~>dutSize) rr=0 cc++ ) ;reset the rowCount    
  );foreach
  dbSave(cv) dbClose(cv) ddCatSave(cat) ddCatClose(cat)
t))

;;;;; PUT FILLERS WHERE DUTS ARE
procedure( adFillOnVarDuts(cv origBox dpl)
let( (pads padWH dutFill rfFill gndFill effOrig effXX fillBox dutOrigin dutCols dutRows)
  pads = dbOpenCellViewByType(car(dpl~>gndPad) cadr(dpl~>gndPad) "layout") padWH = adGetWH(adGetChkBoundary(pads)) dbClose(pads)
  pads = adFittingPads(car(dpl~>rowSize)-car(dpl~>padOrigin) dpl~>padPitchX car(padWH) "even"):adFittingPads(rowH*cadr(dpl~>rowSize)-cadr(dpl~>padOrigin) dpl~>padPitchY cadr(padWH) "odd")
  dutCols = car(pads)/2  dutRows = (cadr(pads)-1)/2  ;; Cols are in pairs and Rows are GSG 
  rfFill = dbOpenCellViewByType(car(dpl~>rfFill) cadr(dpl~>rfFill) "layout")
  gndFill = dbOpenCellViewByType(car(dpl~>gndFill) cadr(dpl~>gndFill) "layout")
  dutFill = if(dpl~>dutFiller && !blankstrp(dpl~>dutFiller) dbOpenCellViewByType(car(dpl~>dutFiller) cadr(dpl~>dutFiller) "layout") nil)
  effXX = leftEdge(origBox):car(dpl~>padOrigin)+dpl~>padPitchX   dutOrigin = rodAddPoints(dpl~>padOrigin car(padWH):dpl~>padPitchY)
  for(ii 0 dutCols-1
    effOrig = car(origBox) ; reset
    for(jj 0 dutRows
      fillBox = list(effOrig cadr(effXX):cadr(dpl~>padOrigin)+2*jj*dpl~>padPitchY) fillBox = dbTransformBBox(fillBox list(2*ii*dpl~>padPitchX:0 "R0" 1)) ; move the column in x if necessary
      adPlaceMosaic(cv fillBox rfFill) ; place the rffill before ground pads
      fillBox = list(leftEdge(fillBox):topEdge(fillBox) rightEdge(fillBox):topEdge(fillBox)+cadr(padWH))
      adPlaceMosaic(cv fillBox gndFill) ; place the rffill at the ground pads
      fillBox = list(leftEdge(fillBox):topEdge(fillBox) rightEdge(fillBox):cadr(dutOrigin)+2*jj*dpl~>padPitchY)      
      when(jj==dutRows fillBox = list(car(fillBox) rightEdge(fillBox):topEdge(origBox))) ; last row fill to the top
      adPlaceMosaic(cv fillBox rfFill) ; place the rffill after ground pads
      if(dutFill && jj < dutRows then
	fillBox = list(leftEdge(fillBox):topEdge(fillBox) rodAddToY(cadr(fillBox) cadr(padWH)))
	adPlaceMosaic(cv fillBox dutFill)
        effOrig = car(effOrig):topEdge(fillBox)
      else effOrig = car(effOrig):topEdge(fillBox)+cadr(padWH));if
  ));for for
t))

;;;;; BUILD AROUND PADS
procedure( adFillAroundVarPads(cv rowH bBox dpl)
let( (rfFill point rows cols mosaics inst padNum)
  rfFill = dbOpenCellViewByType(car(dpl~>rfFill) cadr(dpl~>rfFill) "layout") grid = adGetWH(adGetChkBoundary(rfFill))
  pads = dbOpenCellViewByType(car(dpl~>gndPad) cadr(dpl~>gndPad) "layout") padWH = adGetWH(adGetChkBoundary(pads)) dbClose(pads)
  padNum = adFittingPads(car(dpl~>rowSize)-car(dpl~>padOrigin) dpl~>padPitchX car(padWH) "even"):adFittingPads(rowH*cadr(dpl~>rowSize)-cadr(dpl~>padOrigin) dpl~>padPitchY cadr(padWH) "odd")
  ;; fill the left side
  point = car(bBox)  rows = pcFix((topEdge(bBox)-bottomEdge(bBox))/cadr(grid))  cols = pcFix((car(dpl~>padOrigin)-leftEdge(bBox))/car(grid))
  dbCreateSimpleMosaic(cv rfFill nil point "R0" rows cols cadr(grid) car(grid))
  ;; fill between the pads
  for(cc 0 car(padNum)-1
    point = car(dpl~>padOrigin)+cc*dpl~>padPitchX:cadar(bBox) rows=pcFix((cadr(dpl~>padOrigin)-bottomEdge(bBox))/cadr(grid)) cols=pcFix(car(padWH)/car(grid))
    dbCreateSimpleMosaic(cv rfFill nil point "R0" rows cols cadr(grid) car(grid))  
    point = rodAddToY(point rows*cadr(grid)+cadr(padWH)) ; prepare the point ready for next 
    rows=pcFix((dpl~>padPitchY-cadr(padWH))/cadr(grid)) ; rows wont change
    for(rr 0 cadr(padNum)-2 ;middle ones
      dbCreateSimpleMosaic(cv rfFill nil point "R0" rows cols cadr(grid) car(grid)) point = rodAddToY(point dpl~>padPitchY) );for
    rows=pcFix((topEdge(bBox)-cadr(point))/cadr(grid)) ;last one
    dbCreateSimpleMosaic(cv rfFill nil point "R0" rows cols cadr(grid) car(grid)) )     
  ;; fill the right side
  point = car(dpl~>padOrigin)+dpl~>padPitchX*(car(padNum)-1)+car(padWH):bottomEdge(bBox)  rows = pcFix((topEdge(bBox)-bottomEdge(bBox))/cadr(grid))  cols = pcFix((rightEdge(bBox)-car(point))/car(grid))
  dbCreateSimpleMosaic(cv rfFill nil point "R0" rows cols cadr(grid) car(grid))
  ;; fill in between pads pads
  point = car(dpl~>padOrigin)+dpl~>padPitchX+car(padWH):bottomEdge(bBox) cols = pcFix((dpl~>padPitchX-car(padWH))/car(grid))
  for(ii 0 car(padNum)/2-2    
    dbCreateSimpleMosaic(cv rfFill nil point "R0" rows cols cadr(grid) car(grid)) point = rodAddToX(point 2*dpl~>padPitchX)  )
  ;; return the box for dut
  bBox = list(car(dpl~>padOrigin)+car(padWH):bottomEdge(bBox) car(dpl~>padOrigin)+dpl~>padPitchX*(car(padNum)-1):topEdge(bBox))
bBox))

;;;;; BUILD THE PADROW
procedure( adBuildVarPadRow(cv rowH dpl)
let( (gnd sig effCv pad name ppy (ppx 1) (points list()) pads padWH effBox)
  gnd = dbOpenCellViewByType(car(dpl~>gndPad) cadr(dpl~>gndPad) "layout") sig = dbOpenCellViewByType(car(dpl~>sigPad) cadr(dpl~>sigPad) "layout")  pad = list(gnd sig) 
  padWH = adGetWH(adGetChkBoundary(gnd))  point = dpl~>padOrigin
  ; figure out number of pads
  pads = adFittingPads(car(dpl~>rowSize)-car(dpl~>padOrigin) dpl~>padPitchX car(padWH) "even"):adFittingPads(rowH*cadr(dpl~>rowSize)-cadr(dpl~>padOrigin) dpl~>padPitchY cadr(padWH) "odd")
  ; move by one column
  while(ppx <= car(pads)
    point = rodAddToX(dpl~>padOrigin (ppx-1)*dpl~>padPitchX) ppy = 1
    ; place the g s g up direction
    while(ppy <= cadr(pads) ; number of pad sets
      name = sprintf(nil "pad_%d_%d" ppy ppx) effCv = if(oddp(ppy) gnd sig) 
      dbCreateInst(cv effCv name point "R0") pointText = rodAddPoints(point centerBox(effCv~>bBox)) 
    effBox = list(point rodAddPoints(point padWH))  adAddBlockages(cv parseString(dpl~>topLayers) effBox) ;; add KORs of top fillers to avoid filling inside 
    when(evenp(ppy) adAddBlockages(cv parseString(dpl~>rowBlockages) adReSizeBBox(effBox car(padWH)/4:cadr(padWH)/2 car(padWH)/4:cadr(padWH)/2) nil)) ;; add KORS CEs/C4s to Signal Pads
      dbCreateLabel(cv list(dpl~>bump "drawing") pointText name "centerCenter" "R0" "stick" 10)   
      dbCreateLabel(cv list("text" "drawing") pointText sprintf(nil "%d" ppy) "centerCenter" "R0" "stick" 21)
      point = rodAddToY(point dpl~>padPitchY) ppy++) ppx++) ;while/while
  dbClose(gnd) dbClose(sig)   
  ; place the weird layers to pass HCK and the halo
  rodCreateRect(?cvId cv ?name "rowBoundary" ?length rowH*cadr(dpl~>rowSize) ?width car(dpl~>rowSize) ?layer list("testRow" "boundary")); 
  ; place the gnds
  adGndVarPadRowConn(cv rowH padWH dpl)
t))

;;;;; DRAW GND CONNECTIONS
procedure( adGndVarPadRowConn(cv rowH padWH dpl)
let( (orig layer rectsL rectsR (spcLeft 10) (gndWL 8) (gndMax 12) pads transf)
  orig = rodAddToX(dpl~>padOrigin -spcLeft-gndWL) layer = car(parseString(dpl~>topLayers))
  pads = adFittingPads(car(dpl~>rowSize)-car(dpl~>padOrigin) dpl~>padPitchX car(padWH) "even"):adFittingPads(rowH*cadr(dpl~>rowSize)-cadr(dpl~>padOrigin) dpl~>padPitchY cadr(padWH) "odd")  
  rectsL = tconc(rectsL rodCreateRect(?cvId cv ?layer layer ?origin orig ?length (cadr(pads)-1)*dpl~>padPitchY+cadr(padWH) ?width 8))
  rectsL = tconc(rectsL rodCreateRect(?cvId cv ?layer layer ?origin rodAddPoints(dpl~>padOrigin -spcLeft:cadr(padWH)/2.0-gndMax/2.0) 
                ?width spcLeft ?length gndMax ?spaceY dpl~>padPitchY*2-gndMax ?elementsY pcFix((cadr(pads)+1)/2.0)))
  foreach(rect adFlattenList(car(rectsL)) ;mirror in MY and copy
    transf = 2*(car(orig)+spcLeft+gndWL)+dpl~>padPitchX+car(padWH)
    rectsR = tconc(rectsR dbCopyFig(rect~>dbId cv list(transf:0 "MY" 1)))   )
  ;Repeat in X
  for(ii 1 car(pads)/2-1
    foreach(rect adFlattenList(car(rectsL)) dbCopyFig(rect~>dbId cv list(ii*2*dpl~>padPitchX:0 "R0" 1)))
    foreach(rect adFlattenList(car(rectsR)) dbCopyFig(rect cv list(ii*2*dpl~>padPitchX:0 "R0" 1)))    
  ); for   
))

;;;;;; CREATE TABLE FOR INDUCTOR
procedure(adReadVarCatalog(csv)
let( (rowName dut lib rowH padLoc dutName)
  csv = adReadCsv(csv)  out = gensym() outTable = makeTable(gensym())
  foreach(line adZip(csv~>rowName csv~>dutName csv~>libName csv~>height)
   rowName = nth(0 line) dut = nth(1 line) lib = nth(2 line) rowH = nth(3 line) 
   unless(blankstrp(rowName)
    unless(member(rowName outTable~>?) 
      outTable[rowName] = makeTable(gensym()) ;initialize the row
      foreach(item list("lib" "rowH") outTable[rowName][item] = evalstring(item))
      outTable[rowName]["rowH"] = pcreReplace(pcreCompile("x") outTable[rowName]["rowH"] "" 0)
      outTable[rowName]["duts"] = list() );foreach
    pcreMatchp("(dut[a-z0-9]+?)_" dut) dutName=pcreSubstitute("\\1")
    outTable[rowName]["duts"] = append1(outTable[rowName]["duts"] list(lib dut dutName))
  ));;unless foreach
outTable
))

