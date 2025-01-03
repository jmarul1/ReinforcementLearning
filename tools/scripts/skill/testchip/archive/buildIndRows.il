procedure( adGetPrBoundary(cv)
 boundary = cv~>prBoundary && car(setof(ll cv~>lpps ll == list("chkBoundary" "boundary"))) )

procedure( adBuildPadrow(cv rowDims)
let( (sigPdCv gndPdCv pdXY (count 1))
  padOffset = 53.136:26.112
  sigPd = list("prim74d7" "tc1padind_rf_s")
  gndPd = list("prim74d7" "tc1padind_rf_g")
  padPitch = 101.121
  rowDims = 2147.472:101.184
  rowHeight = 3
  ; get the signals cv
  sigPdCv = dbOpenCellViewByType(car(sigPd) cadr(sigPd) "layout")
  gndPdCv = dbOpenCellViewByType(car(gndPd) cadr(gndPd) "layout")  
  ; Calculate pad number of g/s/g
  pdXY = adGetPrBoundary(sigPdCv)
  ; place pads
  while(car(padOffset) < car(rowDims)-padPitch 
    dbCreateInst(cv gndPdCv sprintf(nil "gnd_%d" pcFix(count)) padOffset "R0")
    padOffset = rodAddToX(padOffset padPitch) 
    dbCreateInst(cv sigPdCv sprintf(nil "sig_%d" pcFix(count)) padOffset "R0") 
    padOffset = rodAddToX(padOffset padPitch) count=count+1 )
  dbCreateInst(cv gndPdCv sprintf(nil "gnd_%d" pcFix(count)) padOffset "R0")  
  ; draw the boundaries
  rowBox = list(0:0 car(rowDims):rowHeight*cadr(rowDims))
  dbCreateRect(cv list("chkBoundary" "boundary") rowBox)  
  dbCreateRect(cv list("testRow" "boundary") rowBox)
t
))

procedure( adBuildFiller(cv rowDims fillerCells)
let( ()
  fillPd = list("indvrx74e74d7_x74d_lay" "e87lindfilefbasqn4hlx_1p296_x74d")
  botPd = list("indvrx74e74d7_x74d_lay" "e87lindfilefbasqn4hlx_1p296_x74d")
  fillInd = list("indvrx74e74d7_x74d_lay" "e87lindfilefbasqn4hlx")
  botPdToEtest = list("indvrx74e74d7_x74d_lay" "e87lindfilefbasqn4hlx_1p296_x74d")
  topPdToFillInd = list("indvrx74e74d7_x74d_lay" "e87lindfilefbasqn4hlx_1p296_x74d")
  fillIndToEtest = list("indvrx74e74d7_x74d_lay" "e87lindfilefbasqn4hlx_1p296_x74d")
  etest = list("indvrx74e74d7_x74d_lay" "e87lindfilefbasqn4hlx_1p296_x74d")
  etestToFillIndLeft = list("indvrx74e74d7_x74d_lay" "e87lindfilefbasqn4hlx_1p296_x74d")
  etestToFillIndRight = list("indvrx74e74d7_x74d_lay" "e87lindfilefbasqn4hlx_1p296_x74d")
  ; create ring of ETest
  ccv = dbOpenCellViewByType(car(etest) cadr(etest) "layout")
  xy = adGetPrBoundary(ccv)
  dbCreateSimpleMosaic(cv ccv nil 0:0 "R0" 1 num car(x) cadr(y))

))
