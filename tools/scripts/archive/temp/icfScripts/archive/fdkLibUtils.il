/*##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2015, Intel Corporation.  All rights reserved.               #
#                                                                            #
# This is the property of Intel Corporation and may only be utilized         #
# pursuant to a written Restricted Use Nondisclosure Agreement               #
# with Intel Corporation.  It may not be used, reproduced, or                #
# disclosed to others except in accordance with the terms and                #
# conditions of such agreement.                                              #
#                                                                            #
# All products, processes, computer systems, dates, and figures              #
# specified are preliminary based on current expectations, and are           #
# subject to change without notice.                                          #
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> getQAResults.py -h 
##############################################################################
*/
/*---------------------------------------------------------------------------
 procedure: fdkPrintLibViews
 Created by Mauricio Marulanda
 Purpose: Creates a csv in your work area with cellName,layout,symbol,auCdl,spectre,hspiceD.
 ---------------------------------------------------------------------------*/
procedure( fdkPrintLibContent(libName @optional (outFileName nil))
let( ( tempLst (viewNames list("layout" "symbol" "auCdl" "spectre" "hspiceD" "schematic" )) topCells outStr )
  unless(member(libName ddGetLibList()~>name) error("Please pass a valid library name")   )
  outStr = strcat("category,cellName," buildString(viewNames ",") ",cellType\n")
  topCells = fdkCCSFindTopCellsInLib(libName)
  foreach(cell ddGetObj(libName)~>cells
    tempLst = list(getTemplateCat(cell~>name) cell~>name)
    foreach(view viewNames  tempLst=append1(tempLst (if member(view cell~>views~>name) "x" " ") ))
    tempLst = append1(tempLst (if member("layout" cell~>views~>name) (if member(cell~>name topCells) "topCell" "hierarchy") "noLayout") )
    outStr = strcat(outStr sprintf(nil "%s\n" buildString(tempLst ",")))
  ) ;foreach
if(outFileName then 
  outFile = outfile(simplifyFilename(outFileName)) fprintf(outFile "%s" outStr) close(outFile)
else 
  outStr );if
)) ; let ; procedure

/*---------------------------------------------------------------------------
 procedure: fdkWhoUsesMe
 Created by Mauricio Marulanda
 Purpose: Find who uses this cell in the library and return list
 ---------------------------------------------------------------------------*/
procedure( fdkWhoUsesMe(cellName libName @optional (view "layout") )
let( ( cv (outLst list()) cells )
  unless(member(libName ddGetLibList()~>name) error("Please pass a valid library name")   ) ;  outStr = strcat("cellName,viewName\n")
  cells = ddGetObj(libName)~>cells~>name
  cells = setof(ii cells not(pcreMatchp("(^d86)|(ind)|(^d85)" ii)))
  foreach(cc cells
    when(member(view ddGetObj(libName cc)~>views~>name)
      cv = dbOpenCellViewByType(libName cc view)
      when(cv 
        if(member(cellName cv~>instances~>cellName) then
          outLst = append1(outLst cc) )
        dbPurge(cv));when
    );when
  );foreach  
outLst
)) ; let ; procedure

/*---------------------------------------------------------------------------
 procedure: fdkPrintLvqaCoverage
 Created by Mauricio Marulanda
 Purpose: Print coverage in the tgtLib using tgtLvqa
 ---------------------------------------------------------------------------*/
procedure(fdkPrintLvqaCoverage(srcLib lvqaLib @optional (reportFile "lvqaReport.csv"))
let( (iiLine dplLvqa mainFlows outFilePrt flowLst effFlowLst (finalDpl gensym()) hashTable dplLvqa)
  hashTable = getLibTree(lvqaLib srcLib) ;contains the testcases with templates in it
  temp = getLvqaConfigs(lvqaLib) 
  dplLvqa = cadr(temp)  ;contains the testcases with qa flows
  mainFlows = car(temp)  reportFile=simplifyFilename(reportFile)
  outFilePrt=outfile(reportFile "w")   rexCompile(",")
  fprintf(outFilePrt strcat(rexReplace(mainFlows ",," 1) "\nCATEGORY,cellName,testCase," buildString(mapcar('lambda((x) car(parseString(x "#"))) cddr(dplLvqa~>?)) ",") "\n"))
  ;for each cell in hashTable find the qa coverage
  foreach(tc hashTable~>? 
    when(member(tc dplLvqa~>TestCase)
      iiLine = lindex(dplLvqa~>TestCase tc) - 1
      ;get the flows for the testcase
      flowLst=list()  category = nth(iiLine dplLvqa~>Category)
      foreach(ii cddr(dplLvqa~>?) flowLst = append1(flowLst nth(iiLine get(dplLvqa ii))) )
      ;put the flows on each subcell of the testcase
      foreach(cell hashTable[tc]
       when(cell
        if(member(stringToSymbol(cell) finalDpl~>?) then effFlowLst=list()   ;merge flows for repeated subcells
	  for(jj 0 length(cadr(get(finalDpl cell)))-1 ;append Xs
	    effFlowLst=append1(effFlowLst strcat(nth(jj cadr(get(finalDpl cell))) nth(jj flowLst))) );for  
	  effFlowLst = list(buildString(list(car(get(finalDpl cell)) tc)) effFlowLst)	  
	else effFlowLst = list(tc flowLst) )
        putprop(finalDpl effFlowLst cell)  );when
      );put the total of flows 
  ) ); when foreach  
  foreach(cell finalDpl~>? fprintf(outFilePrt strcat(getTemplateCat(cell) "," cell "," car(get(finalDpl cell)) "," buildString(cadr(get(finalDpl cell)) ",") "\n") ) );print
  close(outFilePrt) 
reportFile));let proc

procedure(getLvqaConfigs(libName)
let( ( python cmdUnixRead cmdUnixPid tempData (view "layout") (test nil) outStr cells (mainFlows ""))
  unless(member(libName ddGetLibList()~>name) error("Please pass a valid library name")   )
  python = "/p/fdk/gwa/jmarulan/utils/scripts/getQACover.py"
  unless(isFile(python) error("Python script not available") )
  cmdUnixRead = sprintf(nil "unset PYTHONHOME; python %s -lvqa %s -dot %s" python ddGetObj(libName)~>readPath getShellEnvVar("FDK_DOTPROC"))
  cmdUnixPid = ipcBeginProcess(cmdUnixRead)  ipcWait(cmdUnixPid)
  rawStr = "" 
  while( (tempData = ipcReadProcess(cmdUnixPid)) != nil    ;; read the data
    rawStr=strcat(rawStr tempData)  ) ; while
  ;find the first string
  when(pcreMatchp("^(\\s*#\\s*FLOWS.*|\\s*$\\s*flows.*)\\n" rawStr) mainFlows = pcreSubstitute("\\1"))
  list(mainFlows fdkReadCsv(rawStr ?string t))
)) ; let ; procedure

;find all cells use in libName from srcLib
procedure(getLibTree(libName srcLib @key (pattern ".*"))
let( (cells (hashTable makeTable(gensym())) done)
  unless(and(cells=ddGetObj(libName)~>cells ddGetObj(srcLib)) error("Bad Libs %s %s" libName srcLib) )
  done = length(setof(ii cells~>name pcreMatchp(pattern ii)))
  foreach(cellName setof(ii cells~>name pcreMatchp(pattern ii))
    cv = dbOpenCellViewByType(libName cellName "layout")
    when(cv
      hashTable[cellName] = simplifyTree(fdkRemoveLast(findTree(cv list())) srcLib)
      closeme()); when
    printf(":::: INFO :::: Remaining (getLibTree script) %d\n" done--)
    );foreach
    
hashTable));let proc

;find all the parents from a cellName/LibName in srcLib (last element is the cellName)
procedure(findTree(cv tmpLst)
let(( (cellsDb list()) )
  when(cv~>instances 
    ;remove duplicate instances
    foreach(ii cv~>instances unless(member(ii~>master cellsDb) cellsDb=append1(cellsDb ii~>master))   ) ;foreach
    foreach(ii cellsDb tmpLst = findTree(ii tmpLst) );foreach
  );when
  tmpLst = append1(tmpLst list(cv~>libName cv~>cellName) ) ;return
));let proc

procedure(getTemplateCat(cellName)
cond( 
  (pcreMatchp("tmdiode|thmdio|bgdiode|tmdasic" cellName) "TMDIODE")
  (pcreMatchp("^fdk.*(lto|trd)" cellName) "FCC")  
  (pcreMatchp("scl|rfmfc|mimcap" cellName) "SCALABLE")
  (pcreMatchp("rcprw|resw|rtcnw|gnac|mfc_s|decap" cellName) "WRAPPER")
  (pcreMatchp("varg" cellName) "VARACTOR")
  (pcreMatchp("dcp" cellName) "DECAP")
  (pcreMatchp("ind" cellName) "INDUCTOR")
  (pcreMatchp("dpd|gnc" cellName) "GNAC")
  (pcreMatchp("cpr" cellName) "CPR")
  (pcreMatchp("tcn" cellName) "TCN")
  (pcreMatchp("esd|trdtoul" cellName) "ESD")
  (pcreMatchp("mfc" cellName) "MFC")
  (t "UNKNOWN")
))

/*---------------------------------------------------------------------------
 procedure: fdkFindPinLocsForLib
 Purpose: Create a list with pin description
 ---------------------------------------------------------------------------*/
procedure(fdkFindPinLocsForLib(libName @optional (reportFile "symbolPinLocs.csv"))
let( (cv dpl pinStr (result list()) (cols 0) headerStr)
  unless(ddGetObj(libName) error("Library does not exist"))
  foreach(cellDd ddGetObj(libName)~>cells
    when(member("symbol" cellDd~>views~>name)
      cv = dbOpenCellViewByType(libName cellDd~>name "symbol")
      when(cv 
        dpl = fdkFindPinLocs(cv) 
	pinStr = buildString(foreach(mapcar ii dpl~>? strcat(ii "," sprintf(nil "%L" get(dpl ii)))) ",")
	result = append1(result strcat(cellDd~>name "," pinStr))
	cols = max(cols length(dpl~>?))
	dbClose(cv) ));when when
  );foreach
  headerStr = "cellName"
  for(ii 0 cols-1 headerStr = strcat(headerStr ",pinName,loc"))
  result = append(list(headerStr) result)
  outFile=outfile(simplifyFilename(reportFile) "w")
  fprintf(outFile "%s" buildString(result "\n"))
  close(outFile)
simplifyFilename(reportFile)   ));procedure

procedure(fdkFindPinLocs(cv)
let( ((dpl gensym()) )
  foreach(ii cv~>terminals
    putprop(dpl centerBox(caar(ii~>pins~>figs)~>bBox) ii~>name) );foreach
dpl));procedure

/*---------------------------------------------------------------------------
 procedure: fdkRemovePhantomTerminal
 Purpose: Remove Phantom terminals
 ---------------------------------------------------------------------------*/
procedure( fdkRemovePhantomTerminals(libName csv @key (autoCO nil))
let( (csvLst (lay "layout") cv )
  ;read the csv as dictionary if not a list 
  csvLst = (if type(csv)=='list csv fdkReadCsv(csv)~>cellName)
  ;run foreach 
  foreach(cell csvLst
  ;does cell view exist
    when(tgt=ddGetObj(libName cell lay)    
      when( and(ddNeedCheckout(tgt) autoCO) ddCheckout(tgt) ) ;checkout if exist if needed and requested
      cv = dbOpenCellViewByType(libName cell lay "maskLayout" "a")
      when(cv ;it means it can be open and has permissions to write
 	when(phantom = setof(ii cv~>terminals not(ii~>pins))
	  printf("In %s removed: %s\n" cell buildString(phantom~>name))
	  mapcar('dbDeleteObject phantom) dbSave(cv) );when(phantom
        dbClose(cv) );when(cv             
    );when(tgt)  
  );foreach
t));proc

procedure( simplifyTree(lst srcLib)
let( ((outLst list()))
  foreach(ii lst when(car(ii)==srcLib outLst = append1(outLst cadr(ii))) )
outLst));proc

procedure( printLlc(libName @optional (csv "llc.csv"))
let( (cv llc)
  csv = outfile(simplifyFilename(csv))
  fprintf(csv "cellName,(x y)\n")
  foreach(cell ddGetObj(libName)~>cells~>name
    cv = dbOpenCellViewByType(libName cell "layout")
    when(cv 
      llc = car(cv~>bBox)
      fprintf(csv "%s,%L\n" cell llc)
      dbClose(cv)
  ))
  close(csv)  
))
