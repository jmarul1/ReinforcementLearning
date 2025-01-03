procedure( getDuts(libName)
let( (cells)
  cells = ddGetObj(libName)~>cells~>name
  cells = setof(ii cells pcreMatchp("_ind0[234]_dut[abcde]" ii))
  setof(ii cells !pcreMatchp("open|short|thru" ii))  
))

procedure( convertThemAll(libName)
  foreach(cell getDuts(libName)
    convertToSim(libName cell)
    convertToSim(libName cell ?nl t)
    )
)
procedure( convertToSim(libName cell @key (nl nil))
let( (src cv test box lst newName)
  src = dbOpenCellViewByType(libName cell "layout")
  newName = (if nl "layoutsimnl" "layoutsim")
  dbCopyCellView(src libName cell newName) dbClose(src)
  cv = dbOpenCellViewByType(libName cell newName "maskLayout" "a")
  test = setof(ii cv~>instances !pcreMatchp("intercon|v15|hun" ii~>master~>cellName))
  mapc('dbDeleteObject test)
  test = setof(ii cv~>instances pcreMatchp("hun" ii~>master~>cellName))
  foreach(ii test ;flatten the fillers and keep only gm1
    box = ii~>bBox  dbFlattenInst(ii 32 t)
    lst = dbGetOverlaps(cv box)
    mapc('dbDeleteObject setof(jj lst member(jj~>layerName list("gm0" "gv0")))) );foreach
  ; remove rest of instances
  foreach(ii cv~>instances dbFlattenInst(ii 32 t))
  mapc('dbDeleteObject setof(ii cv~>shapes !member(ii~>layerName list("gm1" "gm0" "gv0"))))
  if( nl then
    dbCreateRect(cv list("gm1" "pin") list(101.88:52.92 111.88:53.92))
    dbCreateRect(cv list("gm1" "pin") list(127.88:52.92 137.88:53.92))
  else
    dbCreateRect(cv list("gm1" "pin") list(16.5:-3.44 28.5:-2.33))
    dbCreateRect(cv list("gm1" "pin") list(218.1:-3.44 230.1:-2.33)) )
  dbSave(cv) dbPurge(cv)
t))
