procedure(fdkGetTmpltCurrentTime()
    prog((timeList date)
        timeList=parseString(getCurrentTime() " :")
        date = strcat(nth(5 timeList) "_" nth(0 timeList) "_" nth(1 timeList) "_" nth(2 timeList) "_" nth(3 timeList) "_" nth(4 timeList))
        return(date)
    )
)

(procedure (fdkCustomTemplateShift_r0d4_to_r0d5 libName @key  (cellNames nil)
                                                  ;(viewNames nil)
                                                  (checkAndSave nil)
						  (logFile  nil)
						  )
  let((lib cells views cellName viewName cv _cellNames _viewNames viewNames templateList dateTime transformedPoint)
    dateTime = fdkGetTmpltCurrentTime()
    if(logFile then
		  logFile = sprintf(nil "./%s_%s" logFile dateTime)  		  		  
    else
		  logFile = sprintf(nil "./outLog_%s" dateTime)                 
		  )
    outLog = outfile(logFile "w")
    templateList = '(
("f86lesdd1ru80aoqnxcnx" (0 -0.375))
("e86lesdd2re8ogdxnxcnx" (0 -0.375))
("f86lesdd2ru80aoqnxcnx" (0 -0.375))
("e8xlmfc6a0n6000xn3unx" (0 -0.188))
("e8xlmfc6b0n6000xn3unx" (0 -0.188))
("f8xlesdclpe4000qnxcnx" (1.125 -0.375))
("e8xlmfc6c0n6000xn3unx" (0 -0.188))
("f8xlesdclpn4000qnxcnx" (1.125 -0.375))
("e8xldcpip0n4000xn3unx" (0 -0.188))
("e8xlgnc000h1000xn1unx" (-0.125 0.75))
("pdecap" (0 -0.188))
("e8xlresdace2tnaxnhunx" (-0.75 -0.313))
("e8xlmfc4c0h4000xn3unx" (0 -0.188))
("e86lesdd1re80aoxnxcnx" (0 -0.375))
("e86lesdd2re80aoxnxcnx" (0 -0.375))
("e86lesdd3re80aoxnxcnx" (0 -0.375))
("e8xlmfc4a0e4000xn3unx" (0 -0.188))
("e8xldcpip0n2000xn3unx" (0 -0.188))
("e8xlmfc4a0n4000xn3unx" (0 -0.188))
("gnac" (-0.125 -0.25))
("f8xlgnc000u1000qt1unx" (-0.125 -0.125))
("e8xlmfc4b0n4000xn3unx" (0 -0.188))
("e86lesdd1re80coxnxcnx" (0 -0.375))
("mfc_s2s" (0 -0.188))
("mfc_s2p" (0 -0.188))
("mfc_s2g" (0 -0.188))
("f8xlesdclpu5000qtxcnx" (1.25 -0.375))
("pdecap_3t" (0 -0.188))
("e8xldcpip0h4000xn3unx" (0 -0.313))
("e86lesdd1re8ogdxnxcnx" (0 -0.375))
("e86lesdd4re80aoxnxcnx" (0 -0.375))
("e8xlmfc4b0e4000xn3unx" (0 -0.188))
("e8xlmfc4c0e4000xn3unx" (0 -0.188))
("f8xlesdclpe4000qtxcnx" (1.125 -0.375))
("rcprw" (0 -0.188))
("e8xlmfc4c0n4000xn3unx" (0 -0.188))
("resmw" (0 -0.438))
("e8xlmfc4a0h4000xn3unx" (0 -0.188))
("e8xlmfc4b0h4000xn3unx" (0 -0.188))
("e86lesdd2re80coxnxcnx" (0 -0.375))    

)
    unless(lib =ddGetObj(libName) error("Library <%s> not exist\n" libName))                   

    if(cellNames then
      _cellNames = list(nil)
      foreach(cellName cellNames
        ;unless(ddGetObj(libName cellName) warn("Missing Cell Lib:%s Cell:%s" libName cellName))
        (if ddGetObj(libName cellName) then
          _cellNames = (tconc _cellNames cellName)
        else
          warn("Cell <%s %s> not exist... skipped" libName cellName)
        )
      )		

      cells = mapcar(lambda((x) (ddGetObj libName x)) (car _cellNames))
    else
      cells = lib~>cells
    )
    viewNames = "schematic"                                 
                                     
    (foreach cell cells
      (if viewNames && (listp viewNames) then
        _viewNames = (setof viewName viewNames (member viewName cell~>views~>name))
                                                     
        views = mapcar(lambda((x) (ddGetObj libName cell~>name x)) _viewNames)
      else
			  views views=cell~>views
      )
                                                  
      foreach(view views
        (if (ddIsObjWritable view) then
          cv = (dbOpenCellViewByType lib cell->name view->name)
          (if (member cv->cellViewType '("schematic")) then
            cv = (dbOpenCellViewByType lib cell~>name view~>name nil "a")
            (if cv then
              (foreach instance (dbGetq cv instances)
                 if(assoc(instance~>cellName templateList) then
                    printf("updating instance %s of cell %s\n" instance~>name cell~>name)
                    printf("transform: %L\n" instance~>transform)
                    transformedPoint = dbTransformPoint(cadr(assoc(instance~>cellName templateList)) list(list(0 0) instance~>orient 1))
                    instance~>xy = list(car(instance~>xy)-xCoord(transformedPoint) cadr(instance~>xy)-yCoord(transformedPoint))
                 )
               ) 
                          
              (if checkAndSave then
                ;Run schematic check and Save
                schCheck(cv)
                dbSave(cv)
                dbClose(cv)
                dbPurge(cv)
              )
                  
            else
              getWarn()
            );if
          ); if cv is sch or layout
        else
          (warn "CellView <%s %s %s> not editable... skipped" lib cell->name view->name)
        ); if view writable

      ) ;foreach view
    ) ;foreach cell
    close(outLog)
  );let
) ; procedure



