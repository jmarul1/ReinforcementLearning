procedure(fdkLibanaGetTmpltCurrentTime()
    prog((timeList date)
        timeList=parseString(getCurrentTime() " :")
        date = strcat(nth(5 timeList) "_" nth(0 timeList) "_" nth(1 timeList) "_" nth(2 timeList) "_" nth(3 timeList) "_" nth(4 timeList))
        return(date)
    )
)

(procedure (fdkLibanaTemplateShift_r0d4_to_r0d5 libName @key  (cellNames nil)
                                                  (revert nil)
                                                  (checkAndSave nil)
						  (logFile  nil)
						  )
  let((lib cells views cellName viewName cv _cellNames _viewNames viewNames templateList dateTime cv_model cv_modelOrg)
    dateTime = fdkGetTmpltCurrentTime()
    if(logFile then
		  logFile = sprintf(nil "./%s_%s" logFile dateTime)  		  		  
    else
		  logFile = sprintf(nil "./outLog_%s" dateTime)                 
		  )
    outLog = outfile(logFile "w")
templateList = '(("n_ts" 0.027000)
("n_tp" 0.027000)
("n_tcx" 0.027000)
("n_thhd" 0.027000)
("n_thfd" 0.027000)
("n_tfhd" 0.027000)
("n_tffd" 0.027000)
("nsvt_ts" 0.027000)
("nsvt_tp" 0.027000)
("nsvt_tcx" 0.027000)
("nsvt_thhd" 0.027000)
("nsvt_thfd" 0.027000)
("nsvt_tfhd" 0.027000)
("nsvt_tffd" 0.027000)
("nhvt_ts" 0.027000)
("nhvt_tp" 0.027000)
("nhvt_thhd" 0.027000)
("nhvt_thfd" 0.027000)
("nhvt_tfhd" 0.027000)
("nhvt_tffd" 0.027000)
("n_tdiff" 0.027000)
("nsvt_tdiff" 0.027000)
("n_ts_h" 0.027000)
("n_tp_h" 0.027000)
("n_thfd_h" 0.027000)
("n_tfhd_h" 0.027000)
("n_tffd_h" 0.027000)
("nsvt_ts_h" 0.027000)
("nsvt_tp_h" 0.027000)
("nsvt_thfd_h" 0.027000)
("nsvt_tfhd_h" 0.027000)
("nsvt_tffd_h" 0.027000)
("nhvt_ts_h" 0.027000)
("nhvt_tp_h" 0.027000)
("nhvt_thfd_h" 0.027000)
("nhvt_tfhd_h" 0.027000)
("nhvt_tffd_h" 0.027000)
("ntg_tc_u" -0.108000)
("ntg_thhd_u" -0.108000)
("ntg_thfd_u" -0.108000)
("ntg_tfhd_u" -0.108000)
("ntg_tffd_u" -0.108000)
("ntg_tc_e" -0.108000)
("ntg_tsl_e" -0.108000)
("ntg_thhd_e" -0.108000)
("ntg_tfhd_e" -0.108000)
("ntg_tffd_e" -0.108000)
("p_ts" 0.027000)
("p_tp" 0.027000)
("p_tcx" 0.027000)
("p_thhd" 0.027000)
("p_thfd" 0.027000)
("p_tfhd" 0.027000)
("p_tffd" 0.027000)
("p_tdiff" 0.027000)
("psvt_tdiff" 0.027000)
("p_ts_h" 0.027000)
("p_tp_h" 0.027000)
("p_thfd_h" 0.027000)
("p_tfhd_h" 0.027000)
("p_tffd_h" 0.027000)
("psvt_ts_h" 0.027000)
("psvt_tp_h" 0.027000)
("psvt_thfd_h" 0.027000)
("psvt_tfhd_h" 0.027000)
("psvt_tffd_h" 0.027000)
("phvt_ts_h" 0.027000)
("phvt_tp_h" 0.027000)
("phvt_thfd_h" 0.027000)
("phvt_tfhd_h" 0.027000)
("phvt_tffd_h" 0.027000)
("psvt_ts" 0.027000)
("psvt_tp" 0.027000)
("psvt_tcx" 0.027000)
("psvt_thhd" 0.027000)
("psvt_thfd" 0.027000)
("psvt_tfhd" 0.027000)
("psvt_tffd" 0.027000)
("phvt_ts" 0.027000)
("phvt_tp" 0.027000)
("phvt_thhd" 0.027000)
("phvt_thfd" 0.027000)
("phvt_tfhd" 0.027000)
("phvt_tffd" 0.027000)
("ptg_tc_u" -0.108000)
("ptg_tsl_e" -0.108000)
("ptg_thhd_u" -0.108000)
("ptg_thfd_u" -0.108000)
("ptg_tfhd_u" -0.108000)
("ptg_tffd_u" -0.108000)
("ptg_tc_e" -0.108000)
("ptg_thhd_e" -0.108000)
("ptg_tfhd_e" -0.108000)
("ptg_tffd_e" -0.108000)
("n_ttap" -0.081000)
("p_ttap" -0.081000)
("n_ttap_h" -0.081000)
("p_ttap_h" -0.081000)
("n_tguard" 0.027000)
("p_tguard" 0.027000)
("trcell_t" 0.027000)
("gnac_t" 0.027000)
("spacer_t" 0.027000)
("ntg_ttap_u" -0.108000)
("ptg_ttap_u" -0.108000)
("ntg_ttap_e" -0.108000)
("ptg_ttap_e" -0.108000)
("ntg_tguard_e" -0.324000)
("ptg_tguard_e" -0.324000))    
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
    viewNames = "layout"                                 
                                     
    (foreach cell cells
      (if viewNames && (listp viewNames) then
;        _viewNames = (list nil)
;        (foreach viewName viewNames
;          (if ddGetObj(libName cell~>name viewName) then
;            _viewNames = (tconc _viewNames viewName)
;          else
;            ;warn("Missing Cellview Lib:%s Cell:%s View:%s" libName cell~>name viewName)
;          )
;        )
;        _viewNames = (car _viewNames)
        _viewNames = (setof viewName viewNames (member viewName cell~>views~>name))
                                                     
        views = mapcar(lambda((x) (ddGetObj libName cell~>name x)) _viewNames)
      else
			  views views=cell~>views
      )
                                                  
      foreach(view views
        (if (ddIsObjWritable view) then
          cv = (dbOpenCellViewByType lib cell->name view->name)
          (if (member cv->cellViewType '("maskLayout")) then
            cv = (dbOpenCellViewByType lib cell~>name view~>name nil "a")
            (if cv then
              (foreach instance (dbGetq cv instances)
                 if(assoc(instance~>cellName templateList) then
                    ;fprintf(outLog "updating instance %s of cell %s\n" instance~>name cell~>name)
                      cv_model = (dbOpenCellViewByType instance~>libName cdfGetInstCDF(instance)~>tmplCell~>value view~>name nil "r")
                      cv_modelOrg = dbTransformPoint(lowerLeft(cv_model~>prBoundary~>bBox)    list(list(0 0) instance~>orient 1))
                      dbClose(cv_model)
                      if(revert then
                         instance~>xy = list(car(instance~>xy)-xCoord(cv_modelOrg) cadr(instance~>xy)-yCoord(cv_modelOrg))
                      else
                         instance~>xy = list(car(instance~>xy)+xCoord(cv_modelOrg) cadr(instance~>xy)+yCoord(cv_modelOrg))
                      )
                 )
               ) 
                          
              (if checkAndSave then
                ;Run schematic check and Save
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



