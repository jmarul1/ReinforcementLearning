procedure( adGetPinsView(libName cellName viewName)
let( (main cv out)
  main = ddGetObj(libName cellName)
  cv = dbOpenCellViewByType(libName cellName viewName)
  out = cv~>terminals~>name
  dbClose(cv)
out))

procedure( adGetPinsCDF(libName cellName simulation)
let( (main cdfSim out)
  main = ddGetObj(libName cellName)
  cdfSim = cdfGetBaseCellCDF(main)~>simInfo  
  foreach(sim cdfSim->?
    pins = get(get(cdfSim sim) "termOrder")
    when(symbolToString(sim) == simulation
      out = foreach(mapcar pp pins if(stringp(pp) pp symbolToString(pp)) )
    )  
  )
out))

procedure( adGetPinsSchematic(libName cellName simulation)
let( (main out)
  main = ddGetObj(libName cellName)
  cv = dbOpenCellViewByType(libName cellName "schematic")
  when(cv
    inst = car(setof(ii cv~>instances ii~>purpose == "cell"))
    pins = adGetPinsCDF(inst~>libName inst~>cellName simulation)
    foreach(ii pins
      terminal = car(setof(jj inst~>instTerms jj~>name==ii))
      out = tconc(out terminal~>net~>name)
    )
    dbClose(cv)
  )
car(out)
))

procedure( adCheckPins(libName csvFile simulations)
let( (csv sch viw cdf colViews viwOrig cdfOrig)
  cellLst = if(type(csvFile) == 'list csvFile adReadCsv(csvFile)~>cellName)
  foreach(simulation simulations
    colViews = buildString(foreach(mapcar ii list("sch" "cdf" "view") strcat(ii "_" simulation)) ",")
    csv = list(buildString(list("cellName" colViews "status" ) ","))
    foreach(cell cellLst
    ; get the sch, view, cdf
      cond( 
        (member("schematic" ddGetObj(libName cell)~>views~>name) && !member(simulation ddGetObj(libName cell)~>views~>name)
	sch = adGetPinsSchematic(libName cell simulation)
	viw = adGetPinsView(libName cell "symbol")
	cdf = list("empty") 
	viwOrig = append(viw list()) schOrig = append(sch list())  cdfOrig = list("empty")
        rstatus = if(sort(sch nil) == sort(viw nil) "PASS" "FAIL")  )

	(member("schematic" ddGetObj(libName cell)~>views~>name) && member(simulation ddGetObj(libName cell)~>views~>name)
	sch = adGetPinsSchematic(libName cell simulation)
	viw = adGetPinsView(libName cell simulation)
	cdf = adGetPinsCDF(libName cell simulation) 
	viwOrig = append(viw list()) schOrig = append(sch list())  cdfOrig = append(cdf list())
        rstatus = if(schOrig == cdfOrig && sort(sch nil) == sort(viw nil) "PASS" "REVIEW")  )

	(t
	sch = list("empty")
	viw = adGetPinsView(libName cell simulation)
	cdf = adGetPinsCDF(libName cell simulation)	 
	viwOrig = append(viw list()) schOrig = list("empty")  cdfOrig = append(cdf list())
        rstatus = if(sort(cdf nil) == sort(viw nil) "PASS" "REVIEW")  )
	)

      out = buildString(list(cell buildString(schOrig) buildString(cdfOrig) buildString(viwOrig) rstatus) ",")
      csv = append1(csv out)
    )
    fout = outfile(simplifyFilename(strcat("./pins_" simulation ".report")))
    fprintf(fout "%s" buildString(csv "\n"))
    close(fout)
  )
t))

procedure( adCheckPinsLib(libName)
let( (lst viewDpl)
  viewsDpl = gensym()
  lst = ddGetObj(libName)~>cells
  foreach(cell lst
    foreach(view setof(ii cell~>views~>name not(member(ii list("layout" "lnf" "schematic" "symbol" "symbold"))))
      unless(member(stringToSymbol(view) viewsDpl~>?) putprop(viewsDpl nil view) )
      putprop(viewsDpl tconc(get(viewsDpl view) cell~>name) view) 
  ));foreach
  ;run for each view
  foreach(view viewsDpl~>?
    cells = car(get(viewsDpl view))
    adCheckPins(libName cells list(symbolToString(view)))
  )
t))


procedure( adChangeNetsToLowerCase(cv)
let( (newName newNet)
  foreach(oldNet cv~>nets
    newName = lowerCase(oldNet~>name)
    when(newName != oldNet~>name
      foreach(pinFig oldNet~>pins~>fig
        newNet = dbCreateNet(cv newName)      
        child = car(pinFig~>children)
	dbCreatePin(newNet pinFig)
        case(child~>objType
	  ("textDisplay" 
	                 ;newText = dbCreateTextDisplay(pinFig~>net~>term pinFig~>net~>term child~>lpp t child~>xy child~>justify child~>orient child~>font child~>height 	  t nil t nil t "name") 
	                 newText = dbCreateLabel(cv pinFig~>lpp child~>xy newName child~>justify child~>orient child~>font child~>height)
                         leAttachFig(newText pinFig) dbDeleteObject(child) 	  )
          ("label" child~>theLabel = newName) );case	
      ) ;foreach(pinFig
    dbDeleteObject(oldNet) ) ;when
  );foreach
t))

procedure( adChangeNetsToPinLayer(cv)
let( (child newText)
  foreach(net cv~>nets
    foreach(pinFig net~>pins~>fig
      child = car(pinFig~>children)
      case(child~>objType
        ("textDisplay" newText = dbCreateLabel(cv pinFig~>lpp child~>xy net~>name child~>justify child~>orient child~>font child~>height)
                       leAttachFig(newText pinFig) dbDeleteObject(child)  )
        ("label" child~>lpp = pinFig~>lpp) );case	
    ));foreach
t))

procedure( adGetModelPins(modelName modelFile)
let( (fin line values)
  cmd = buildString(list("/nfs/pdx/home/jmarulan/work_area/utils/scripts/getUpfModels.py" modelFile "-model " modelName))
  commandUnixPid = ipcBeginProcess(cmd) ipcWait(commandUnixPid)
;; read the data
  
  parameterList = "" ; initialize
  while( (tempData = ipcReadProcess(commandUnixPid)) != nil parameterList=strcat(parameterList tempData) ) ; while

))
