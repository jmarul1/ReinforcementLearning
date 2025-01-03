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

procedure( fdkCreateSclArray(csv @optional (libName "nil") (cellName nil))
;;; create a cell with array of scl instances
let( (sch fOut    srcInst temp (xOff 0) (yOff 0) (yOffMax 0) (instLst list()) (grid 0.2) (rowMax 5) (ptapLoc -1:1) )
  ;;check inputs are valid
  unless(ddGetObj(libName) libName = strcat(getShellEnvVar("USER") "_p" getShellEnvVar("FDK_DOTPROC"))) unless(cellName cellName = "arraytest")
  unless(sch = dbOpenCellViewByType(libName cellName "schematic" "schematic" "w") error(sprintf(nil "problems writing to the libName/cellName %s/%s" libName cellName)))
  ;; read the csv, create the outputfile, deal with paramLst
  csv = fdkReadCsv(simplifyFilename(csv)) 
  params = mapcar('symbolToString setof(ii csv~>? !pcreMatchp("cellName|libName" ii)))  row = 0
  ;; run for all cells
  foreach(cc fdkZip(csv~>libName csv~>cellName)
    srcDb = dbOpenCellViewByType(nth(0 cc) nth(1 cc) "symbol")   ;; open the source
    tempLst = buildString(foreach(mapcar pp params  buildString(list(pp nth(row get(csv pp))) ",") ) ",")  ;; get the string of parameters to input
    ;; place the instance
    when(temp = fdkPlaceSclInst(srcDb sch tempLst ?xOff xOff ?yOff yOff)  instLst = append1(instLst temp)      
      fdkSchInstPins(temp ?suffix length(instLst)+1) ;place pins
      ;;prepare placement for possible next iteration
      xOff = caadr(temp~>bBox) yOffMax = max(yOffMax cadadr(temp~>bBox))    
      width = fdkGetWH(temp~>bBox) height = cadr(width)   width = car(width)  
      xOff=xOff+width+grid when(mod(length(instLst) rowMax)==0 xOff=0 yOff=yOffMax+height+grid)
      row+=1 ));when(temp; foreach
;  fdkGenLayout(sch)  ;;add ptap when necessary and place the pin  lay=dbOpenCellViewByType(libName cellName "layout" "maskLayout" "a")  
;  unless(srcCell=="ndecap_s2s" placeLvqaPtap(lay "vss" ?location ptapLoc))
  foreach(jj setof(ii sch~>shapes ii~>objType=="textDisplay") jj~>height=0.05) ; reduce size of the text
  mapcar('dbSave list(sch)) mapcar('dbClose list(sch))
  printf("\nGenerated %d instances in: %s , %s\n" length(instLst) libName cellName)
t ));; let procedure

procedure( fdkTestCB(csv paramLst @optional (fOut "cbTest.csv"))
;fdkTestCB: Uses a csv to test the parameters placed in the callback for the paramLst given
let( (params cells cv srcDb inst (testCell symbolToString(gensym())) value outLst tempLst output fid paramVals header paramStr)
  ;; read the csv, create the outputfile, deal with paramLst
  csv = fdkReadCsv(simplifyFilename(csv))  fOut = simplifyFilename(fOut)
  params = mapcar('symbolToString setof(ii csv~>? !pcreMatchp("cellName|libName" ii)))  row = 0
  when(stringp(paramLst) paramLst = list(paramLst))
  ;; run for all cells
  foreach(cc fdkZip(csv~>libName csv~>cellName)
  ;; open the cell and source
    cv = dbOpenCellViewByType(strcat(getShellEnvVar("USER") "_p" getShellEnvVar("FDK_DOTPROC")) testCell "schematic" "schematic" "w")
    srcDb = dbOpenCellViewByType(nth(0 cc) nth(1 cc) "symbol")
  ;; get the string of parameters to input
    tempLst = buildString(foreach(mapcar pp params  buildString(list(pp nth(row get(csv pp))) ",") ) ",")
    paramStr = buildString(foreach(mapcar pp params nth(row get(csv pp))) ",")
  ;; place the instance
    inst = fdkPlaceSclInst(srcDb cv tempLst)
  ;; get the cdf results and store
    paramVals=foreach(mapcar param paramLst output=cdfFindParamByName(cdfGetInstCDF(inst) param)~>value (if output output "") )
    output = buildString(nconc(cc list(paramStr) paramVals) ",") outLst = append1(outLst output) 
  ;;close the cells        
    dbClose(cv) dbClose(srcDb) row+=1  );foreach(cc
  ;;print the file
  header = strcat("libName,cellName," buildString(append(params paramLst) ","))
  fid=outfile(fOut)  fprintf(fid "%s\n%s" header buildString(outLst "\n"))  close(fid)
fOut));let ;procedure

procedure( fdkUpdateCdfParamInInst(inst param val)
;;; Use to update the parameter with the value in the instance given
let( (cdf cb inputs)
  cdf = cdfGetInstCDF(inst)
  when(param = cdfFindParamByName(cdf param)
    when(or(not(param~>choices) member(val param~>choices)) && stringp(val)
      param~>value = val  
      when(and(param~>callback pcreMatchp("(\\w+)" param~>callback)) 
       cb = stringToSymbol(pcreSubstitute("\\1"))  inputs = fdkCallbackIns(cdf param~>name) 
       apply(cb inputs) ) 
  ));when
));let ;procedure

procedure( fdkPlaceSclInst(srcInst_db tgtCell_db csvParams @key (xOff 0) (yOff 0) (Orientation "R0"))
;;; place an instance db given into a cellview db and update callbacks based on csvParams inputs
let( (inst params (ii 0) test)
; create the instance
 inst = schCreateInst(tgtCell_db srcInst_db symbolToString(gensym()) list(xOff yOff) Orientation)
; update parameters with callbacks
 params = parseString(csvParams ",")
 while(ii<length(params)  
   test = fdkUpdateCdfParamInInst(inst nth(ii params) nth(ii+1 params))
   ii+=2);if/while
inst));procedure

