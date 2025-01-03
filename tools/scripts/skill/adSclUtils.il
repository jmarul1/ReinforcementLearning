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

procedure( adCreateSclArrayQa(libName cellName paramCombLst @key (tgtLib strcat(getShellEnvVar("USER") "_lib")) (tgtCell "arraytest") (view "layout") (spacing 1:1)) ;; create a cell with array of scl instances
let( (cv srcDb inst (xOff 0) (yOff 0) (yOffMax 0) (instLst list()) rowMax tgtView fullInstLst )
  tgtView = (if view=="layout" list("layout" "maskLayout") list("schematic" "schematic"))
  unless(srcDb = dbOpenCellViewByType(libName cellName view) error("bad src lib/cell"))   ;;check inputs are valid
  fullInstLst =  (if type(paramCombLst)== 'list paramCombLst adArrayLst(paramCombLst) )  rowMax = pcFix(length(fullInstLst)**0.5)
  cv = dbOpenCellViewByType(tgtLib tgtCell car(tgtView) cadr(tgtView) "w")       
  foreach(paramLst fullInstLst   ;; run for all paramCombLst
    when(inst = dbCreateParamInst(cv srcDb car(paramLst) xOff:yOff "R0" 1  ) instLst = xcons(instLst inst)  ;; place the instance
      adUpdateCdfParamsInInst(inst cdr(paramLst))	;update inst with new name
      ; adSchInstPins(temp ?suffix length(instLst)+1) ;place pins
      adOffsetInstByOrigin(inst); fix the placement, fix the origin by the distance to the lower left corner
      xOff = adArrayOffset(inst yOffMax length(instLst) rowMax spacing) yOff=cadr(xOff) yOffMax=nth(2 xOff) xOff=car(xOff)) ;; prepare placement for possible next iteration
  );foreach
  unless(cv~>prBoundary dbCreatePRBoundary(cv adListBBox(dbComputeBBoxNoNLP(cv))))
  dbSave(cv) dbClose(cv) dbClose(srcDb)
  printf("\nGenerated %d instances\n" length(instLst)) 
t ));; let procedure

procedure( adCreateSclCellQa(libName cellName paramCombLst @key (tgtLib strcat(getShellEnvVar("USER") "_lib")) (view "layout")) ;; create a cell with array of scl instances
let( (cv srcDb inst (xOff 0) (yOff 0) tgtView (tgtCell symbolToString(gensym())) nameDpl (cc 0) (pinDpl nil) cellLst)
  tgtView = (if view=="symbol" list("schematic" "schematic") list("layout" "maskLayout"))
  unless(srcDb = dbOpenCellViewByType(libName cellName (if view=="both" "layout" view)) error("bad src lib/cell"))   ;;check inputs are valid
  foreach(paramLst (if type(paramCombLst)== 'list paramCombLst adArrayLst(paramCombLst) )   ;; run for all paramCombLst
    when(cv = dbOpenCellViewByType(tgtLib tgtCell car(tgtView) cadr(tgtView) "w")  ;use a generic symbol for tgtCell then Purge    
      when(inst = dbCreateParamInst(cv srcDb car(paramLst) xOff:yOff "R0" 1); cdr(paramLst) use default and update one by one
	nameDpl = adUpdateCdfParamsInInst(inst cdr(paramLst))  paramLst = cons(car(paramLst) cadr(nameDpl)) nameDpl = car(nameDpl) ; correct values and get dpl
        nameDpl = adSclName(cellName nameDpl car(paramLst) cellName ) when(view=="both" pinDpl = adRoutePinsOnInsts(cv)) ;place pins
	adDrawPr(cv) dbSave(cv tgtLib nameDpl car(tgtView)) dbPurge(cv) cc++)     	println(nameDpl) 
	cellLst = tconc(cellLst nameDpl)	);when inst cv  
    when(view == "both" adCreateSchCellQa(libName cellName tgtLib nameDpl paramLst pinDpl))
  );foreach
  printf("\nGenerated %d cells\n" cc)
  dbPurge(srcDb)
car(cellLst)));; let procedure

procedure( adCreateSchCellQa(srcLib srcCell tgtLib tgtCell paramLst pinDpl)
let( (cv inst srcDb)
  unless(srcDb = dbOpenCellViewByType(srcLib srcCell "symbol") error("bad src lib/cell"))   ;;check inputs are valid
  cv = dbOpenCellViewByType(tgtLib tgtCell "schematic" "schematic" "w") 
  when(inst = dbCreateParamInst(cv srcDb car(paramLst) xOff:yOff "R0" 1 );cdr(paramLst)) 
    adUpdateCdfParamsInInst(inst cdr(paramLst))
    adRoutePinsOnInsts(cv pinDpl)
    schCheck(cv)  dbSave(cv)  dbClose(cv) )
))

procedure( adArrayOffset(inst yMax count rowMax spacing) ; return the bottom left corner + XwidthOfInstance or reset it to zero + YwidthOfInstance
let( ( xOff yOff grid width height)
  grid = (if inst~>viewName == "layout" car(spacing) cadr(spacing))
  xOff = leftEdge(inst~>bBox) yOff = bottomEdge(inst~>bBox)
  width = adGetWH(inst~>bBox) height = cadr(width)   width = car(width)  
  xOff=xOff+width+grid  yMax = max(yMax yOff+height+grid)
  when(zerop(mod(count rowMax)) xOff=0 yOff=yMax)
list(xOff yOff yMax) ) )

procedure( adArrayLst(csv)
let( (nameK params lst (finalLst list()) tipo value)
  csv = adReadCsv(csv)
  nameK = car(csv~>?)  params = cdr(csv~>?)
  for(line 1 length(get(csv nth(0 params)))-1
    lst = list(nth(line get(csv nameK)))
    lst = append(lst foreach(mapcar pp params 
            tipo = nth(0 get(csv pp))
            value=case(tipo ("float" cdfParseFloatString(nth(line get(csv pp))) ) ("int" pcFix(cdfParseFloatString(nth(line get(csv pp)))))
	                    ("boolean" evalstring(nth(line get(csv pp))) ) (t nth(line get(csv pp))) )
            list(symbolToString(pp) tipo value)   ))
    finalLst = append1(finalLst lst)    );for
finalLst ));proc

procedure( adUpdateCdfParamsInInst(inst paramLst) ;paramLst is list( list("param" "type" "value") ..)
;;; Use to update the parameter with the value in the instance given
let( (cdf cb inputs cdfP (name gensym()) cdfgData)
 foreach(param paramLst
   cdf = cdfGetInstCDF(inst) 
   when(cdfP = cdfFindParamByName(cdf car(param))
     when(not(cdfP~>choices) || member(caddr(param) cdfP~>choices) 
       cdfP~>value = caddr(param)
       when(cdfP~>callback  cdfgData = cdf  evalstring(cdfP~>callback)) )      ;when(and(cdfP~>callback pcreMatchp("(.*)\\((.*)?" cdfP~>callback)) cb = stringToSymbol(pcreSubstitute("\\1")) inputs = pcreSubstitute("\\2") inputs = foreach(mapcar ii parseString(inputs) when(pcreMatchp("(\\w+)" ii) pcreSubstitute("\\1")) )  	 apply(cb inputs) )
     putprop(name cdfP~>value car(param)) ;store the name
 ));when ;foreach
paramLst = foreach(mapcar paramLine paramLst list(nth(0 paramLine) nth(1 paramLine) get(name nth(0 paramLine))) ) ;update param
list(name paramLst) ));let ;procedure

procedure( adSclName(device dpl default @optional (prefix "") )
let( (orderK param (name list()) test mult)
 cond(
   (pcreMatchp("(?<!mm)ind" device) && getShellEnvVar("PROJECT") == "1222" 
      orderK = list("indType:" "n:n" "wth:w" "spc:s" "X:x" "Y:y" "tlen:tl" "tspc:ts" "addFill:fil" "rot:" "addCenterTap:ct" "activeMetal1_45:45m1" "activeMetal2_45:45m2")
      foreach(kk orderK
        param = car(parseString(kk ":")) paramEff = cadr(parseString(kk ":"))
        when(member(stringToSymbol(param) dpl~>?)
	 test = case(param
	        ("indType" substring(get(dpl param) 1 3)) 
	        ("addFill" (if get(dpl param) "fil" "nfl") )
	        ("rot"     get(dpl param))
	        ("addCenterTap" (if get(dpl param) get(dpl "CenterTapOri") nil))
	        ( ("activeMetal1_45" "activeMetal2_45") (if get(dpl param) paramEff nil) )
		("n" strcat(adReplaceStr(adReplaceStr(adNum2Str(get(dpl param)) "\\." "p") "-" "n") paramEff))
	        (t strcat(adReplaceStr(adReplaceStr(adNum2Str(cdfParseFloatString(adAelEval(?entry get(dpl param)))*1M) "\\." "p") "-" "n") paramEff) )
	        );case
	when(test name = append1(name lowerCase(test)))
	));when( foreach
   strcat(prefix "__" buildString(name "_"))
   );inductor
   (pcreMatchp("ind" device)
     orderK = list("indType:" "n:n" "w:w" "s:s" "dx:x" "dy:y" "tl:tl" "ts:ts") prefix = "ind"  
     foreach(kk orderK
       param = car(parseString(kk ":")) paramEff = cadr(parseString(kk ":"))
       when(member(stringToSymbol(param) dpl~>?)
         mult = if(param == "n" 1 1M) 
         test = if(param == "indType" get(dpl param) strcat(adReplaceStr(adNum2Str(cdfParseFloatString(get(dpl param))*mult) "\\." "p") paramEff))
	 name = append1(name lowerCase(test))    ))
     strcat(device "__" buildString(name "_"))
   );mmind  
   (pcreMatchp("mim" device)
     orderK = list("nx" "ny")
     foreach(kk orderK
       when(member(stringToSymbol(kk) dpl~>?) name = append1(name strcat(lowerCase(get(dpl kk)) kk)) ) )
   strcat(prefix "__" buildString(name "_"))
   );mimcap

   (pcreMatchp("mmxfmr" device)
     orderK = list("indType:" "wM8:wm8" "wM7:wm7" "doM8:dom8" "doM7:dom7" "tl:tl" "ts:ts") prefix = "mmxfmr"
     foreach(kk orderK
       param = car(parseString(kk ":")) paramEff = cadr(parseString(kk ":"))
       when(member(stringToSymbol(param) dpl~>?) 
         test = if(param == "indType" get(dpl param) strcat(adReplaceStr(adNum2Str(cdfParseFloatString(get(dpl param))*1M) "\\." "p") paramEff)) 
	 name = append1(name lowerCase(test))    ))
     strcat(prefix "__" buildString(name "_"))     
   )
   (t default)  
 )));cond;let;proc

procedure( adRunCbOnInst(inst)
let( (cdf cb inputs)
  cdf = cdfGetInstCDF(inst)
  foreach(param cdf~>parameters
    when(and(param~>callback pcreMatchp("(.*)\\((.*)?" param~>callback))
      cb = stringToSymbol(pcreSubstitute("\\1")) inputs = pcreSubstitute("\\2")
      inputs = foreach(mapcar ii parseString(inputs) when(pcreMatchp("(\\w+)" ii) pcreSubstitute("\\1")) ) 
      inputs = foreach(mapcar ii inputs if(ii == "cdfgData" cdf ii)) 
      apply(cb inputs));when
  );foreach
));proc

procedure( adOffsetInstByOrigin(inst) ;offset the location to the lowerLeftCorner if that is not the origin
let( (llc)
  llc = car(adGetChkBoundary(inst))
  when(llc != inst~>xy inst~>xy = rodAddPoints(inst~>xy rodSubPoints(inst~>xy llc)))
))  

procedure( adGetPcellErr(inst errName lppErr)
let( (errors)
  errors = setof(ii inst~>master~>shapes and(ii~>objType=="label" ii~>lpp==lppErr))
  errors = setof(ii errors setof(jj ii~>prop jj~>name == errName)) 
))
procedure(adPrintPcellErr(cv @key (fname "pcellQA.csv") (errName "errorDesc") (lppErr list("marker" "error")) )
let( (fout (outStr "instName,error") errorInst)
  foreach(inst cv~>instances
    when(errorInst = adGetPcellErr(inst errName lppErr) sprintf(outStr "%s\n%s,%s" outStr inst~>name car(errorInst~>theLabel)) ) );foreach
  if(fname == "screen" then printf("%s" outStr)
  else fout = outfile(simplifyFilename(fname)) fprintf(fout "%s" outStr) close(fout) )
t))
