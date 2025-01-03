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
 procedure: adPrintLibViews
 Created by Mauricio Marulanda
 Purpose: Creates a csv in your work area with cellName,layout,symbol,auCdl,spectre,hspiceD.
 ---------------------------------------------------------------------------*/
procedure( adPrintLibContent(libName @optional (outFileName nil))
let( ( tempLst (viewNames list("layout" "symbol" "auCdl" "spectre" "hspiceD" "schematic" )) topCells outStr outFile)
  unless(member(libName ddGetLibList()~>name) error("Please pass a valid library name")   )
  outStr = strcat("category,cellName," buildString(viewNames ",") ",cellType\n")
  topCells = adCCSFindTopCellsInLib(libName)
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
 procedure: adWhoUsesMe
 Created by Mauricio Marulanda
 Purpose: Find who uses this cell in the library and return list
 ---------------------------------------------------------------------------*/
procedure( adWhoUsesMe(cellName libName @optional (view "layout") )
let( ( cv (outLst list()) cells )
  unless(member(libName ddGetLibList()~>name) error("Please pass a valid library name")   ) ;  outStr = strcat("cellName,viewName\n")
  cells = ddGetObj(libName)~>cells~>name
;  cells = setof(ii cells not(pcreMatchp("(^d86)|(ind)|(^d85)" ii)))
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


;find all cells use in libName from srcLib
procedure(getLibTree(libName srcLib @key (pattern ".*"))
let( (cv cells (hashTable makeTable(gensym())) done)
  unless(and(cells=ddGetObj(libName)~>cells ddGetObj(srcLib)) error("Bad Libs %s %s" libName srcLib) )
  done = length(setof(ii cells~>name pcreMatchp(pattern ii)))
  foreach(cellName setof(ii cells~>name pcreMatchp(pattern ii))
    cv = dbOpenCellViewByType(libName cellName "layout")
    when(cv
      hashTable[cellName] = simplifyTree(adRemoveLast(findTree(cv list())) srcLib)
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
  (pcreMatchp("thmd|bgd|tmd" cellName) "TMDIODE")
  (pcreMatchp("var" cellName) "VARACTOR")
  (pcreMatchp("dcp" cellName) "DECAP")
  (pcreMatchp("mim" cellName) "MIM")
  (pcreMatchp("ind" cellName) "INDUCTOR")
  (pcreMatchp("dpd|gnc" cellName) "GNAC")
  (pcreMatchp("cpr|tcn|tfr" cellName) "RES")
  (pcreMatchp("esd|trdtoul|scr" cellName) "ESD")
  (pcreMatchp("mfc" cellName) "MFC")
  (pcreMatchp("_n|_p" cellName) "TRANSISTOR")
  (pcreMatchp("_edn|_edp" cellName) "EDMOS")  
  (pcreMatchp("aqa" cellName) "HALO")
  (t "UNKNOWN")
))

/*---------------------------------------------------------------------------
 procedure: adFindPinLocsForLib
 Purpose: Create a list with pin description
 ---------------------------------------------------------------------------*/
procedure(adFindPinLocsForLib(libName @optional (reportFile "symbolPinLocs.csv"))
let( (cv dpl pinStr (result list()) (cols 0) headerStr outFile)
  unless(ddGetObj(libName) error("Library does not exist"))
  foreach(cellDd ddGetObj(libName)~>cells
    when(member("symbol" cellDd~>views~>name)
      cv = dbOpenCellViewByType(libName cellDd~>name "symbol")
      when(cv 
        dpl = adFindPinLocs(cv) 
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

procedure(adFindPinLocs(cv)
let( ((dpl gensym()) )
  foreach(ii cv~>terminals
    putprop(dpl centerBox(caar(ii~>pins~>figs)~>bBox) ii~>name) );foreach
dpl));procedure

/*---------------------------------------------------------------------------
 procedure: adRemovePhantomTerminal
 Purpose: Remove Phantom terminals
 ---------------------------------------------------------------------------*/
procedure( adRemovePhantomTerminals(libName csv @key (autoCO nil))
let( (csvLst (lay "layout") cv tgt phantom)
  ;read the csv as dictionary if not a list 
  csvLst = (if type(csv)=='list csv adReadCsv(csv)~>cellName)
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

procedure( adDelCells(libName cellRegExp)
let( (cmd lst)
  lst = setof(ii ddGetObj(libName)~>cells~>name pcreMatchp(cellRegExp ii))
  cmd = buildString(foreach(mapcar ii lst strcat(ddGetObj(libName)~>readPath "/" ii)))
  cmd = strcat("rm -rf " cmd)
  system(cmd)
  printf("Deleted %s\n" buildString(lst "\n"))
t))

procedure( adCheckIn(lib cell view @optional (hier nil))
let( (cv test results tree)
  when(ddGetObj(lib cell view)
   test = ddCheckin(ddGetObj(lib cell view))
   when(not(test) results = tconc(results list(lib cell view))) );when
  ;check in hierarchy
  when(hier
    cv = dbOpenCellViewByType(lib cell view)
    tree = findTree(cv list())
    foreach(ii tree 
      when(ddGetObj(car(ii) cadr(ii) view) 
        test = ddCheckin(ddGetObj(car(ii) cadr(ii) view)) 
        when(not(test) results = tconc(results list(car(ii) cadr(ii) view))))
    ); foreach
   dbClose(cv) );when 
car(results) ))

procedure(adFlatAllInstFromLib(cv flatLib) ;flatten cells by one level from specified library(regex)
let( ()
;find the tree and go for each cell could go here, go for each cell except the scratch ones
  foreach(ii setof(ii cv~>instances pcreMatchp(flatLib ii~>libName))
    dbFlattenInst(ii 1 t nil nil nil nil nil t))
  when(setof(ii cv~>instances pcreMatchp(flatLib ii~>libName)) adFlatAllInstFromLib(cv flatLib))
));let proc
