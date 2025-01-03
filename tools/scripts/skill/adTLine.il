procedure( createHyp3TL(fband sweep @key (sim t) (boundary nil))
let( (tl cv params box)
  if(fband == "low"  then 
    tl = "hyperion3_vco_tl_44g" 
    params = list(list("s" "string" "10u") list("wm" "string" "4u") list("lm" "string" "48u")
    list("wt" "string" "4u") list("lt" "string" "14.5u")
    list("wb" "string" "4u") list("lb" "string" "14.5u") )    
  else 
    tl = "hyperion3_vco_tl_54g"
    params = list(list("s" "string" "10u") list("wm" "string" "12u") list("lm" "string" "40u")
    list("wt" "string" "12u") list("lt" "string" "0u")
    list("wb" "string" "12u") list("lb" "string" "0u") )    
    )
  box = list(-64.8:0 64.8:126)
  if(sweep then
    params = adGenTLParams(fband) 
    foreach(pp params
      cv = dbOpenCellViewByType("jmarulan_lib" "temp999" "layout" "maskLayout" "w")
      name = buildHyp3TL(cv pp ?sim t) name = adGetTLName(name) dbClose(cv)
      if(sim then
        cv = dbOpenCellViewByType("jmarulan_lib" name "layout" "maskLayout" "w")
        buildHyp3TL(cv pp ?sim t) prepForSim(cv)
      else
        cv = dbOpenCellViewByType("hyperion3_s22" tl strcat("layout_" name)  "maskLayout" "w")
	buildHyp3TL(cv pp ?boundary box) println(cv~>bBox)
      )
      dbSave(cv) dbClose(cv))
  else
    cv = dbOpenCellViewByType("hyperion3_s22" tl "layout" "maskLayout" "w")
    buildHyp3TL(cv params ?boundary boundary) 
    dbSave(cv) dbClose(cv) )
t))

procedure( adGenTLParams(fband)
let( (s wLst lm lbLst lmLst LST)
;  if(fband == "high" then s = "10u" wLst = list("12u") lmLst = list("40u")  lbLst = list("0u" "1u" "2u")
  if(fband == "high" then s = "10u" wLst = list("10u") lmLst = list("42u") lbLst = list("0u" )  
  else                    s = "10u" wLst = list("4u") lmLst = list("48u") lbLst = list("14u" "15u" "16u" ) )
  foreach(lm lmLst
   foreach(w wLst
    foreach(l lbLst
     LST = tconc(LST list(list("s" "string" s) 
                         list("wm" "string" w)  list("wt" "string" w)  list("wb" "string" w) 
                         list("lm" "string" lm) list("lt" "string" l) list("lb" "string" l)))
  )));foreach	 
   LST = list(
    list(list("s" "string" "10u") list("wm" "string" "10u") list("lm" "string" "44u")
     list("wt" "string" "10u") list("lt" "string" "3u")
     list("wb" "string" "10u") list("lb" "string" "3u") )     
    list(list("s" "string" "10u") list("wm" "string" "8u") list("lm" "string" "48u")
     list("wt" "string" "8u") list("lt" "string" "5u")
     list("wb" "string" "8u") list("lb" "string" "5u") )
    list(list("s" "string" "10u") list("wm" "string" "6u") list("lm" "string" "52u")
     list("wt" "string" "6u") list("lt" "string" "7u")
     list("wb" "string" "6u") list("lb" "string" "7u") ) )

LST
))

procedure( buildHyp3TL(cv params @key (sim nil) (boundary nil))
let( (origP origR srcDb inst (gndW 5) cdf gap s lt lm wt wb wm box (bOffset 7.42) temp (height 5.5) )
  origP = 11.88:0 gap = 2*(car(origP)+0.54)
  srcDb = dbOpenCellViewByType("hyperion3_s22" "tline" "layout")
  inst = dbCreateParamInst(cv srcDb "right_tl" origP "R0" 1 params)  adRunCdfCB(inst)  cdf = cdfGetInstCDF(inst)
  s = cdfParseFloatString(cdf~>s~>value)*1M    
  lt = cdfParseFloatString(cdf~>lt~>value)*1M  lm = cdfParseFloatString(cdf~>lm~>value)*1M    lb = cdfParseFloatString(cdf~>lb~>value)*1M
  wt = cdfParseFloatString(cdf~>wt~>value)*1M  wb = cdfParseFloatString(cdf~>wb~>value)*1M    wm = cdfParseFloatString(cdf~>wm~>value)*1M
  dbCopyFig(inst cv list(0:0 "MY" 1))  
  origR = -gap/2.0:0
  ;;; create grounds
  box = list(origR rodAddPoints(origR gap:gndW)) dbCreateRect(cv "m7" box) 
  box = dbTransformBBox(box list(0:3*gndW+4*s+wb+lm+wt "R0" 1)) dbCreateRect(cv "m7" box)
  box = list(rodAddToY(origR 2*gndW+2*s+wb+lm) rodAddPoints(origR gap:3*gndW+2*s+wb+lm)) dbCreateRect(cv "m8" box)   
  dbCreateRect(cv "m7" list(-1:2*gndW+2*s+wb+lm 1:3*gndW+4*s+wb+lm+wm))
  dbCreateVia(cv techFindViaDefByName(techGetTechFile(cv) "via7") 0:2*gndW+2*s+wb+lm+gndW/2 "R0" list(list("cutHeight" 7.4)))
  ;;; create signals
  box = list(rodAddPoints(origR 0:gndW+s) rodAddPoints(origR bOffset:gndW+s+wb)) temp = dbCreateRect(cv "m8" box) dbCopyFig(temp cv list(0:0 "MY" 1))   
  temp = xCoord(cadr(box)):yCoord(centerBox(box)) 
  adPlaceTLPins(cv temp "signals" ?sim sim) 
  box = list(rodAddPoints(origR 0:3*gndW+3*s+wb+lm) rodAddPoints(origR gap:3*gndW+3*s+wb+lm+wm)) dbCreateRect(cv "m8" box)
  ;;; create vdd and gnd pins
  box = list(-5:3*gndW+3*s+wb+lm+wm 5:4*gndW+4*s+wb+lm+wt) dbCreateRect(cv "m8" box)
  adPlaceTLPins(cv car(centerBox(box)):topEdge(box) "ptop" ?sim sim)
  adPlaceTLPins(cv -1*car(origR)+2*gndW+2*s+wm+lb:yCoord(centerBox(cv~>bBox)) "gnd" ?sim sim)    
  ;; add fill, create boundary and remember dimensions
  unless(sim adAddFillM6(cv origP boundary)) ;; finish
  adAddFillM7Mesh(cv rodAddPoints(origR -lb:2*gndW+2*s+wb) lb lm sim)
  dbCreatePRBoundary(cv adListBBox(cv~>bBox)) origP = rodAddPoints(car(cv~>bBox)  height:height)
  foreach(ii '(s lb wb lm wm lt wt)
   dbCreateLabel(cv list("text" "drawing") origP strcat(symbolToString(ii) "=" adNum2Str(eval(ii)) "u") "lowerLeft" "R0" "stick" height)     origP = rodAddToY(origP 2*height) )
inst))

procedure( adAddFillM6(cv orig boundary)
let( (box gap m6 temp)
  boxTgt = if(boundary boundary cv~>bBox) 
  box = cv~>bBox
  m6 = dbOpenCellViewByType("p1222_fillers" "p1222_filler_m6h_ld" "layout")
  gap = ceiling(caadr(boxTgt)/4.32)*4.32 - caadr(box)   cols = pcFix(gap/0.54) rows = pcFix(cadadr(box)/0.63)
  when(cols > 0
   temp = dbCreateSimpleMosaic(cv m6 nil caadr(box):0 "R0" rows cols 0.63 0.54)
   dbCopyFig(temp cv list(0:0 "MY" 1)) )
  box = cv~>bBox
  gap = ceiling(cadadr(boxTgt)/2.52)*2.52 - cadadr(box)   cols = pcFix((caadr(box)-car(orig))/0.54) rows = pcFix(gap/0.63) 
  when(rows > 0
   temp = dbCreateSimpleMosaic(cv m6 nil car(orig):cadadr(box) "R0" rows cols 0.63 0.54)  
   dbCopyFig(temp cv list(0:0 "MY" 1)) dbClose(m6) )
t))

procedure( adAddFillM7Mesh(cv orig lb lm sim)
let( (temp m7 box left)
 when(lb > 0
  if(sim then
    temp = rodCreateRect(?cvId cv ?layer "m7" ?width lb ?length lm ?origin orig)
    dbCopyFig(temp~>dbId cv list(0:0 "MY" 1))
  else 
    m7 = dbOpenCellViewByType("p1222_fillers" "p1222_filler_m7o_mesh" "layout")  orig = rodAddToX(orig 0.54)
    box = list(orig rodAddPoints(orig lb-0.54:lm))
    temp = adGetWH(box) cols = floor(car(temp)/4.32) rows = floor(cadr(temp)/2.52)
    when(cols>0 && rows>0
     left = lm-rows*2.52  
     temp = nil  
     temp = tconc(temp dbCreateSimpleMosaic(cv m7 nil rodAddToY(orig left/2) "R0" rows cols 2.52 4.32))
     temp = tconc(temp rodCreateRect(?cvId cv ?origin orig ?length left/2.0 ?width cols*4.32 ?layer "m7")~>dbId)
     temp = tconc(temp rodCreateRect(?cvId cv ?origin rodAddToY(orig left/2.0+rows*2.52) ?length left/2.0 ?width cols*4.32 ?layer "m7")~>dbId)
     foreach(ii car(temp) dbCopyFig(ii cv list(0:0 "MY" 1))) )
     dbClose(m7)
  ));when
))

procedure( adPlaceTLPins(cv loc tipo @key (sim nil))
let( ()
  case(tipo
  ("signals" 
    loc = if(sim rodAddPoints(loc -0.5:0) rodAddPoints(loc -1:-0.5))
    rodCreateRect(?cvId cv ?origin loc ?width 1 ?length 1 ?layer list("m8" "pin") ?pin t ?netName "nleft" ?pinLabel t ?pinLabelHeight 0.2)
    loc = dbTransformPoint(loc list(-1:0 "MY" 1))
    rodCreateRect(?cvId cv ?origin loc ?width 1 ?length 1 ?layer list("m8" "pin") ?pin t ?netName "nright" ?pinLabel t ?pinLabelHeight 0.2)        )
  ("ptop"
    loc = if(sim rodAddPoints(loc -0.5:0) rodAddPoints(loc -0.5:-1))
    rodCreateRect(?cvId cv ?origin loc ?width 1 ?length 1 ?layer list("m8" "pin") ?pin t ?netName "ptop" ?pinLabel t ?pinLabelHeight 0.2)    )
  ("gnd"
    loc = if(sim rodAddPoints(loc -0.5:0) rodAddPoints(loc -1:-0.5))
    rodCreateRect(?cvId cv ?origin loc ?width 1 ?length 1 ?layer list("m8" "pin") ?pin t ?netName "gnd" ?pinLabel t ?pinLabelHeight 0.2)
    loc = dbTransformPoint(loc list(-1:0 "MY" 1))
    rodCreateRect(?cvId cv ?origin loc ?width 1 ?length 1 ?layer list("m8" "pin") ?pin t ?netName "gnd" ?pinLabel t ?pinLabelHeight 0.2)        ) 
  );case
 
))

procedure( adRunCdfCB(inst)
let( (cdfgData)
  cdfgData = cdfGetInstCDF(inst)
  foreach(pp cdfgData~>parameters
   when(pp~>callback evalstring(pp~>callback)   )
  );foreach
))

procedure( adGetTLName(inst)
let( (cdf)
  cdf = cdfGetInstCDF(inst)
  sprintf(nil "tline_%dw_%dl_%ds" pcFix(cdfParseFloatString(cdf~>wm~>value)*1M) pcFix(cdfParseFloatString(cdf~>l~>value)*2M) 
  pcFix(cdfParseFloatString(cdf~>s~>value)*1M))
))

procedure( prepForSim(cv)
let( ()
  foreach(ii cv~>instances dbFlattenInst(ii 1 t nil nil nil nil nil t))
  mapc('dbDeleteObject setof(ii cv~>instances pcreMatchp("fill" ii~>master~>cellName)))
  mapc('dbDeleteObject setof(jj setof(ii cv~>shapes ii~>purpose == "pin") !jj~>pin))
  foreach(ii cv~>vias dbFlattenInst(ii 1))
))
