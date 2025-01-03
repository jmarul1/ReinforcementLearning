procedure( adConvertIndToXfmr(libName) ; scan the library for the name convention and create combinations
let( (lib inds temp doM8 wM8 doM7 wM7 (count 0 ))
  lib = ddGetObj(libName)
  inds = setof(ii lib~>cells~>name pcreMatchp("^b88ind__" ii))
  foreach(ii inds ;metal8
    temp = adGetIndDims(ii ?string nil) doM8 = temp~>x   wM8 = temp~>w     ; get do and w for metal8coil
    foreach(jj inds ;metal7
      temp = adGetIndDims(jj ?string nil) doM7 = temp~>x wM7 = temp~>w     ; get do and w for metal7coil
      when(wM7 <= 6 && abs(doM8-doM7) <= 5; match x/y up to 5 microns apart and limit jj (metal7) w up to 6 microns
        foreach(delta list(0 2.5) 
	  adIndToXfmr(lib ii lib jj lib ?delta delta) count=count+1) ; generate the xfmr for each delta
      ); when 
    ));foreachs
printf("Generated %d transformers\n" count)
t))

procedure( adIndToXfmr(libm8 cellm8 libm7 cellm7 tgtLib @key (delta 0))
let( (cellName cv cv1 cv2 shape transf)
  ; open the sources 
  cv1 = dbOpenCellViewByType(libm8 cellm8 "layout" "maskLayout" "a")
  cv2 = dbOpenCellViewByType(libm7 cellm7 "layout" "maskLayout" "a")
  transf = car(cv1~>instances)~>Y*1M/2.0 - car(cv2~>instances)~>Y*1M/2.0 + car(cv2~>instances)~>Y*1M + delta
  transf = list(0:transf "MX" 1) 
  ; get the new name 
  cellName = adIndToXfmrName(cellm8 cellm7 delta) ;  b88xfmr__oct_1n_2p1wm8_2p1wm7_45x_45y_n12p68tl_10ts_0dlt
  cv = dbOpenCellViewByType(tgtLib cellName "layout" "maskLayout" "w")  
  ; get the coils, move one to m7 and flip
  foreach(ii adCleanIndCoil(cv1) shape = dbCopyFig(ii cv) )
  foreach(ii adCleanIndCoil(cv2) shape = dbCopyFig(ii cv transf) shape~>layerName="metal7")
  dbSave(cv) dbClose(cv)
  dbClose(cv1) dbClose(cv2) 
))

procedure( adCleanIndCoil(cv) ;only works for one turn
let( (m8pins m8draw)  
  adFlattenIndPcell(cv)
  mapc('dbDeleteObject setof(ii cv~>shapes !member(ii~>purpose  list("drawing" "pin"))))
  leMergeShapes(cv~>shapes)
  m8pins = setof(ii cv~>shapes ii~>lpp == list("metal8" "pin"))
  m8draw = dbGetOverlaps(cv car(m8pins~>bBox))
  m8draw = setof(ii m8draw ii~>purpose == "drawing")
append(m8pins m8draw)
))

procedure( adIndToXfmrName(name1 name2 delta)
let( (w1 w2 cellName)
  dim1 = adGetIndDims(name1)  dim2 = adGetIndDims(name2)
  w1 = dim1~>w x1 = dim1~>x	w2 = dim2~>w x2 = dim2~>x
  delta = pcreReplace(pcreCompile("\\.") adNum2Str(delta) "p" 0)
  when(w1 && w2  && x1 && x2
    cellName = pcreReplace(pcreCompile("b88ind") name1 "b88xfmr" 0)
    cellName = pcreReplace(pcreCompile("(\\d+(p\\d+)?)w") cellName strcat(w1 "m8w_" w2 "m7w") 0)
    cellName = pcreReplace(pcreCompile("(\\d+(p\\d+)?)x_(\\d+(p\\d+)?)y") cellName strcat(x1 "m8do_" x2 "m7do") 0)
    cellName = pcreReplace(pcreCompile("nfl_r0") cellName strcat(delta "dlt") 0) 
    cellName = pcreReplace(pcreCompile("(\\d+(p\\d+)?)s_") cellName strcat("") 0) )
cellName))

procedure( adGetIndDims(name @key (string t))
let( (nExp dpl value)
  nExp = "(\\d+(p\\d+)?)"  dpl = gensym()
  foreach(dim list("n" "w" "s" "x" "y")
    pcreMatchp(strcat("_" nExp dim "_") name)
    value = pcreSubstitute("\\1")
    when(value && !string value = cdfParseFloatString(pcreReplace(pcreCompile("p") value "." 0)) )
    putprop(dpl value dim) )
dpl))
