procedure( adFillBBox(cv fcv space @key (layers list()) (cvTgt nil) (approx "ceiling") )
let( ()
  adInstFillCustomLayout(cv fcv space ?layers layers ?chkBox enterBox ?cvTgt cvTgt ?approx approx)
))

procedure( adGetChkBoundary(cv)
let( (box layers shape )
  layers = cv~>lpps
  layers = setof(ll layers (ll~>layerName == "chkBoundary" && ll~>purpose == "boundary"))
  layers = car(layers)
  shape = layers~>shapes
  shape =  cv~>prBoundary || car(shape) || cv
  box = shape~>bBox
box))

procedure(adInstFillCustomLayout(cv fcv space @key (layers list()) (chkBox nil) (cvTgt nil) (approx "ceiling")) ;cv fillCvId Spacing
let( (X Y cols rows orig cBox box decision elems)
  layers = layers || setof(ii fcv~>lpps ii~>purpose == "drawing")~>layerName
  X = adGetWH(adGetChkBoundary(fcv)) Y = cadr(X) X = car(X) ;; calculate the square sizes
  chkBox = chkBox||adGetChkBoundary(cv)  ;; get the boundaries
  cvTgt = if(dbValidP(cvTgt) cvTgt cv)
  if(approx == "floor" then
    cols = floor( (caadr(chkBox)-caar(chkBox))/X )  ;; get the cols
    rows = floor( (cadadr(chkBox)-cadar(chkBox))/Y ) ;; get the rows  
  else 
    cols = ceiling( (caadr(chkBox)-caar(chkBox))/X )  ;; get the cols
    rows = ceiling( (cadadr(chkBox)-cadar(chkBox))/Y ) ;; get the rows
  )  
  for(rr 0 rows-1  ;; start filling from bottom left using produce overlaps selectively
    orig = rodAddPoints(car(chkBox) 0:rr*Y)
    for(cc 0 cols-1
      box = list(orig rodAddPoints(orig X:Y)) cBox = list(rodSubPoints(car(box) space:space) rodAddPoints(cadr(box) space:space))
      decision = t ;; make the decision
      foreach(layer layers when(decision && (dbProduceOverlap(cv cBox 32 list(layer "drawing")) || dbLayerBlockageQuery(cv layer cBox 0 32)) decision=nil) )
      when(decision 
        if(fcv~>objType == "mosaic" dbCopyFig(fcv cvTgt list(orig "R0" 1)) dbCreateInst(cvTgt fcv nil orig "R0") ) );when
      orig = rodAddPoints(orig X:0) );for
    );for
t))

procedure(adSelectToRemove(cv layer spc instName)
let( (mtls1 mtls2 instances total lst)
  lst = setof(ii cv~>shapes ii~>layerName == layer)
  mtls1 = dbLayerTile(cv list(layer "keepGenAway") lst)
  mtls2 = dbLayerSize(cv list(layer "keepGenAway") mtls1 spc)
  instances = setof(ii cv~>instances ii~>master~>cellName == instName)
  foreach(ii instances 
    when(dbProduceOverlap(cv ii~>bBox 32 list(layer "keepGenAway")) total = tconc(total ii)  )
  )  
  mapc('dbDeleteObject mtls1)   mapc('dbDeleteObject mtls2) 
  mapc('dbDeleteObject car(total))
t
))

procedure(adRectFillBox(cv layer box minWH minSpcXY @key (density nil) (grid 0.001))
let( (pitchX pitchY cols rows orig dBox cBox ovlSpc x y spc)
  x = car(minWH) y = cadr(minWH)  
  when(density spc = max( (-density*(x+y) + (density*(density*x**2 - 2*density*x*y + density*y**2 + 4*x*y))**0.5)/(2*density)  -(density*(x + y) + (density*(density*x**2 - 2*density*x*y + density*y**2 + 4*x*y))**0.5)/(2*density))
               spc = round(spc/grid)*grid   
	       minSpcXY = max(car(minSpcXY) spc):max(cadr(minSpcXY) spc) )
  pitchX = x+car(minSpcXY)  pitchY = y+cadr(minSpcXY)  ovlSpc = rodAddPoints(minSpcXY -grid:-grid)
  cols = floor( (rightEdge(box)-leftEdge(box)-x)/pitchX) + 1
  rows = floor( (topEdge(box)-bottomEdge(box)-y)/pitchY) + 1
  for(rr 0 rows-1 for(cc 0 cols-1 ;; start filling from bottom left using produce overlaps selectively
    orig = rodAddPoints(car(box) cc*pitchX:rr*pitchY)
    ; make the decision
    dBox = list(orig rodAddPoints(orig x:y)) cBox = list(rodSubPoints(car(dBox) ovlSpc) rodAddPoints(cadr(dBox) ovlSpc))
    unless( dbProduceOverlap(cv cBox 32 list(layer "drawing")) || dbProduceOverlap(cv cBox 32 list(layer "keepGenAway")) 
      dbCreateRect(cv list(layer "drawing") dBox) ); unless
  )); for ;for
t))

procedure(adGrowMetal(cv metal @key (grow 0))
let( (lst)
  lst = setof(ii cv~>shapes ii~>layerName == metal)
  newLst = dbLayerTile(cv metal lst)
  dbLayerSize(cv list(metal "keepGenAway") newLst grow)
  mapc('dbDeleteObject newLst)
t  
))
