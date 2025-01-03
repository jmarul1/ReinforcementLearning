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
 procedure: fdkStreamGds
 Created by Mauricio Marulanda
 Purpose: Creates GDS for all cells matching the regular expression cellPatter list given in the optional directory provided.
 ---------------------------------------------------------------------------*/
procedure( fdkStreamGds(library cellPattern @optional (outputDir  nil) (outName nil))
  let( (libId (streamedList list()) )
    libId = ddGetObj(library)
    unless(outputDir outputDir = strcat(getShellEnvVar("FDK_WORK") "/pds/stream") )
    outputDir = simplifyFilename(outputDir)
    unless(isDir(outputDir) sh(strcat("mkdir " outputDir)))
    foreach( iiTarget setof(ii libId->cells rexMatchp(cellPattern ii->name))
      streamedList = append1(streamedList iiTarget->name)
      when(ddGetObj(iiTarget->lib->name iiTarget->name "layout") 
	  makeQuickStream(iiTarget->name iiTarget->lib->name outputDir (if outName outName strcat(iiTarget->name ".gds") ) ) 
      )
    )
    (if streamedList 
      foreach(ii streamedList printf("SUCCESS: gds for %s created\n" ii))
      artError("GDS was not generated, CellPattern does not exist") )
  )
)

/*---------------------------------------------------------------------------
 procedure: fdkStreamCdl
 Created by Mauricio Marulanda
 Purpose: Creates CDL for all cells matching the regular expression cellPattern list given in the optional directory provided.
 ---------------------------------------------------------------------------*/
procedure( fdkStreamCdl(library cellPattern @optional (outputDir  nil) )
  let( (libId (streamedList list()) )
    libId = ddGetObj(library)
    unless(outputDir outputDir = strcat(getShellEnvVar("FDK_WORK") "/netlists/cdl") )
    outputDir = simplifyFilename(outputDir)
    unless(isDir(outputDir) sh(strcat("mkdir " outputDir)) )
    foreach( iiTarget setof(ii libId->cells rexMatchp(cellPattern ii->name))
      streamedList = append1(streamedList iiTarget->name)
      when(ddGetObj(iiTarget->lib->name iiTarget->name "schematic") 
	pckMakeQuickCDLNetlist(iiTarget->name iiTarget->lib->name outputDir (strcat iiTarget->name ".cdl"))
      )
    )
    (if streamedList 
      foreach(ii streamedList printf("SUCCESS: netlist for %s created\n" ii))
      artError("Netlist was not generated, CellPattern does not exist") )
    sh(strcat("cd " outputDir " && rm -r si.env netlist ihnl map"))
  )
)		

/*---------------------------------------------------------------------------
 procedure: fdkStreamForLvs
 Created by Mauricio Marulanda
 Purpose: Creates CDL and GDS for all cells matching the regular expression cellPatter list given in the optional directory provided.
 ---------------------------------------------------------------------------*/
procedure( fdkStreamForLvs(library cellPattern @optional (outputDir  nil) )
  fdkStreamCdl(library cellPattern outputDir)
  fdkStreamGds(library cellPattern outputDir)
)

/*---------------------------------------------------------------------------
 procedure: fdkGetRectArea()
 Created by Mauricio Marulanda
 Purpose: Calculates the area for the list of rectangles given in the layer. No Diagonal lines
 ---------------------------------------------------------------------------*/
procedure( fdkGetRectArea(rectIds @optional (metal "tm1"))
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
 procedure: fdkRoutePinsOnInsts
 Created by Mauricio Marulanda
 Purpose: Places all the pins in the position of the instances. This is usually done after creating a genFromSource with the pin creation enable.
 ---------------------------------------------------------------------------*/
procedure( fdkRoutePinsOnInsts(cellId)
  let( (topNet instTerm instPinFig topInstPinFig topPinName tSize)
    ;; iterate for each terminal
    foreach(topTerm cellId->terminals
      ; iterate over all the pins for this topTerminal (a terminal might have two pins)
      foreach(topPin topTerm->pins
        topNet = topTerm->net   
        ; iterate over all pins the net belongs to at the top level
        unless(cdr(topNet->instTerms)
          instTerm = car(topNet->instTerms)->term
	  foreach(instPinFig instTerm~>pins~>fig ;list(car(instTerm~>pins~>fig)) ; iterate over all pins the net belongs to at the instance level
	   when(instPinFig
	    ; create a figure for the pin on top of the instance on the top cell location
            topInstPinFig = dbCopyFig(instPinFig cellId car(topNet->instTerms)->inst->transform)
	    ; remove any children
	    mapcar('dbDeleteObject topInstPinFig~>children)
	    ; get the name of the top pin, erase the top pin/shape and attach the top net of the erased pin to the new pin/shape
	    topPinName = topPin->name   
	    dbCreatePin(topNet topInstPinFig) ;topPinName
	    ; make sure the figure is in the pin Layer
	    topInstPinFig->lpp = list(nth(0 topInstPinFig->lpp) "pin")
	    tSize = 0.02*apply('max fdkGetWH(topInstPinFig->bBox))
	    dbCreateLabel(cellId topInstPinFig->lpp centerBox(topInstPinFig->bBox) topPinName "centerCenter" "R0" "stick" tSize) )
	  );foreach instPinFig
	dbDeleteObject(topPin->fig) dbDeleteObject(topPin)
        );unless
      );foreach
    );foreach
));procedure

;Generate from source
procedure(fdkGenLayout(inCellId @key (pins t) (bulk nil))
  let( (outCellId vssLoc)
    schCheck(inCellId)     dbSave(inCellId)    aelPushSignifDigits(15)
    ;envSetVal("layoutXL" "lxEvalCDFCallbacks" 'boolean t)
    outCellId = lxGenFromSource(inCellId ?initCreatePins pins ?initCreateBoundary nil) ;dbClose(inCellId)
    when(pins fdkRoutePinsOnInsts(outCellId))     ;; create pins if any
    when(bulk fdkRemoveAllPins(outCellId bulk) placeLvqaPtap(outCellId bulk) );when text the bulk requested
    dbSave(outCellId)        dbClose(outCellId)
    aelPopSignifDigits()
t));let ;procedure

;place pins on an instance
procedure(fdkSchInstPins(inst @key (suffix nil))
let( (pinName pinLoc pinDb iPin effSuffix)
  unless(iPin = dbOpenCellViewByType("basic" "iopin" "symbol") error(sprintf(nil "could not get basic library")))
  foreach(topTerm inst~>terminals~>term
    effSuffix = (if suffix strcat("_" fdkNum2Str(suffix)) "") 
    pinName = (if pcreMatchp("^v$|^vssx" topTerm~>name) "vss" strcat(topTerm~>name effSuffix))
    pinLoc = dbTransformPoint(centerBox(car(topTerm~>pins)~>fig~>bBox) inst~>transform)
    pinDb = schCreatePin(inst~>cellView iPin pinName "inputOutput" nil pinLoc "R270")      );foreach    
  dbClose(iPin)
t));procedure

procedure(fdkRunDoneProcedure(inst)
  when(and(cdfGetInstCDF(inst) cdfGetInstCDF(inst)~>doneProc)  
    apply(stringToSymbol(cdfGetInstCDF(inst)~>doneProc) list(inst)) );when
);procedure

;remove any pins/shapes/nets associated with pinName
procedure(fdkRemoveAllPins(t_layDb pinName) 
let( (net figs)
  net = car(setof(ii t_layDb~>nets ii~>name == pinName))
  labels = setof(jj setof(ii t_layDb~>shapes ii~>objType=="label") jj~>theLabel==pinName)
  foreach(ddObjs net~>pins when(ddObjs~>figs mapcar('dbDeleteObject ddObjs~>figs))) ;erase all pin shapes
  foreach(ddObjs list(net~>pins labels list(net)) ;erase the pins db, pin texts, and the net
    mapcar(lambda((ff) when(ff dbDeleteObject(ff))) ddObjs) );foreach
t));procedure

;place layout pins everywhere with pinName using effname (only one per instance and not in well body)
procedure(fdkPlacePinOnInsts(cv instPinName @key (effName nil))
let((topNet tgtFig topInstPinFig topNet topPinname topInstPinFig tSize)
  unless(effName effName = instPinName)
  fdkRemoveAllPins(cv instPinName)
  fdkRemoveAllPins(cv effName) ;remove all nets with that name
  tgtNet = dbCreateNet(cv effName);create the net 
  foreach(inst cv~>instances ;find all instances
    topNet = car(setof(ii inst~>instTerms ii~>name == instPinName)); find the effective pin
    tgtFig = car(setof(ii topNet~>term~>pins~>fig ii~>layerName != "wellBody"))  ;find the pin that is not well body
    when(tgtFig 
      topInstPinFig = dbCopyFig(tgtFig cv inst~>transform) ; copy the fig transformed
      mapcar('dbDeleteObject topInstPinFig~>children)
      dbCreatePin(tgtNet topInstPinFig) ;topPinName
      topInstPinFig~>lpp = list(nth(0 topInstPinFig~>lpp) "pin")    ; make sure the figure is in the pin Layer
      tSize = 0.02*apply('max fdkGetWH(topInstPinFig~>bBox))
      dbCreateLabel(cv topInstPinFig~>lpp centerBox(topInstPinFig~>bBox) effName "centerCenter" "R0" "stick" tSize) )
  );foreach
t))

;find if this is the only layer in the layout
procedure(fdkOnlyLayer(csv libName @key (lpp list("mc0" "complement")) (outFile nil) )
let( (cells cv (view "layout") (errStrLst list()) (key "cellName") fout)
  cells = (if type(csv) == 'list csv get(fdkReadCsv(csv) key) )
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
when(cv~>instances ;check for non complement by calling each instance
  foreach(ii cv~>instances errStrLst = isOnlyLayer(ii~>master errStrLst ?lpp lpp) ) )
;check for non complement in cv
when(result=foreach(mapcar ii setof(ii cv~>shapes ii~>lpp!=lpp) car(ii~>lpp))
  result = fdkListToSet(result) 
  errStrLst = append1(errStrLst strcat(cv~>cellName "," buildString(result))) );when
errStrLst);if   ;proc

;check and save
procedure(checkAndSave(cells libName)
let( (cv)
  foreach(cc cells
    cv = dbOpenCellViewByType(libName cc "schematic" "schematic" "a")
    when(cv schCheck(cv) dbSave(cv) dbClose(cv) )
))
);procedure
