fdkTriggerFTCallbacks.il 04/20/12.

/***************************************************************
*                                                              *
*         This procedure gets the date and time in             *
*          particular format                                   *
*                                                              *
***************************************************************/


procedure(fdkGetCurrentTime()
    prog((timeList date)
        timeList=parseString(getCurrentTime() " :")
        date = strcat(nth(5 timeList) "_" nth(0 timeList) "_" nth(1 timeList) "_" nth(2 timeList) "_" nth(3 timeList) "_" nth(4 timeList))
        return(date)
    )
)
/***************************************************************
*                                                              *
*    The variable fdkCallbackPatternsToIgnore is set to be     *
*      a list of patterns against which the callbacks are      *
*      checked. If any of these patterns are matched then      *
*                 the callback is not invoked.                 *
*                                                              *
***************************************************************/

(unless (boundp 'fdkCallbackPatternsToIgnore)
  (setq fdkCallbackPatternsToIgnore
	'("^MYPDKNot_Allowed.*")))

/***************************************************************
*                                                              *
*           (fdkShouldCallbackBeExecuted callback)             *
*                                                              *
*  This checks the callback against all the patterns defined   *
*    in the list fdkCallbackPatternsToIgnore to determine      *
*       whether the callback should be executed or not.        *
*                                                              *
***************************************************************/

(procedure (fdkShouldCallbackBeExecuted callback)
  (forall pattern fdkCallbackPatternsToIgnore
	  (null (rexMatchp pattern callback)))
  )


/*******************************************************************
*                                                                  *
*      (fdkInvokeObjCdfCallbacks cdf @key (debug nil) params       *
*               )                                                  *
*                                                                  *
*      Underlying function which does all the real work. This      *
*is separated from the original function fdkInvokeInstCdfCallbacks *
*    so that this can be called with a completely virtual CDF.     *
*                                                                  *
* Return nil if any callback failed with a SKILL error, t otherwise*
*                                                                  *
*******************************************************************/

(procedure (fdkInvokeObjCdfCallbacks_r0d1_to_r0d2 cdf @key (debug nil) params)
  ;----------------------------------------------------------------------
  ; Make cdfgData and cdfgForm dynamically scoped, to avoid
  ; interfering with any global usage of these variables
  ;----------------------------------------------------------------------
  (let (callback parameters cdfgData cdfgForm (success t))
       ;-----------------------------------------------------------------
       ; Set the cdfgData to be the instance CDF
       ;-----------------------------------------------------------------
       (setq cdfgData cdf)
       (setq cdfgForm nil)
       
       
       ;-----------------------------------------------------------------
       ; Control order of parameter evaluation. If order specified,
       ; just do those, otherwise do all in arbitrary order
       ;-----------------------------------------------------------------
       (if params
	   (setq parameters (foreach mapcar param params
				     (get cdfgData param)))
	   (setq parameters (getq cdfgData parameters))
	   )
       ;-----------------------------------------------------------------
       ; loop through all parameters
       ;-----------------------------------------------------------------
       (foreach param parameters
		(setq callback (getq param callback))
		(when (and callback 
			   (nequal callback "")
			   (fdkShouldCallbackBeExecuted callback))
		      ;(when debug
			    ;(printf "  Invoking callback for '%s': '%s'\n"
				    ;(getq param name) callback))
		      ;--------------------------------------------------
		      ; evaluate the callback
		      ;--------------------------------------------------
		       (unless (errset (evalstring callback) t)
		         (setq success nil)
		       )
		      ))
  success))

/*****************************************************************
*                                                                *
*      (fdkInvokeInstCdfCallbacks instance [?debug debug]        *
*  [?params params] )                                            *
*                                                                *
* Invoke all the parameter callbacks in the CDF for an instance. *
*                                                                *
*                                                                *
*****************************************************************/

(procedure (fdkInvokeInstCdfCallbacks_r0d1_to_r0d2 instance @key (debug nil) params)
				     
  ;----------------------------------------------------------------------
  ; Make cdfgData and cdfgForm dynamically scoped, to avoid
  ; interfering with any global usage of these variables
  ;----------------------------------------------------------------------
  
  (let (cdf success)
       ;(when debug
	 ;(printf "\tInvoking callback for instance '%s' cellName %s\n"
		      ;instance~>name instance~>cellName ))
       ;-----------------------------------------------------------------
       ; Set the cdf to be the instance CDF
       ;-----------------------------------------------------------------
       (setq cdf (cdfGetInstCDF instance))
       
       ;-----------------------------------------------------------------
       ; Return value will be nil if any callbacks had errors
       ;-----------------------------------------------------------------
       success = (fdkInvokeObjCdfCallbacks_r0d1_to_r0d2
	 cdf 
	 ?debug debug ?params params 
	 
	 )
  success ))





/******************************************************************
*                                                                 *
*       (fdkInvokeCdfCallbacks_r0d1_to_r0d2 cellView @key (debug nil)          *
*   (updateCells nil) (params nil) (updatePropList nil) (outLog nil))*
*                                                                 *
*  Invoke the CDF callbacks for all reruired instances in the     *
*  cellView. Returns nil if any callback had a SKILL error,       *
*  otherwise t                                                    *
******************************************************************/

(procedure (fdkInvokeCdfCallbacks_r0d1_to_r0d2 cellView @key (debug nil)
                                 (updateCells nil) 
				 (params nil)
				 (outLog nil)
				 )
	   (let ((success t) 
		 (flagChange 0)
		 
		 libName cellName libCell paramNameValuePre paramNameValuePost paramName param instProps copyProp _tmp_var instUpdateprop dummyProp dummyPropValid)
	     (when debug
	       (printf "Updating instances in cellView '%s' '%s'\n"
		     (dbGetq cellView cellName) (dbGetq cellView viewName)))
	      fprintf(outLog "\nLibrary:%s Cell:%s\n" (dbGetq cellView libName) (dbGetq cellView cellName))
	     (foreach instance (dbGetq cellView instances)
	                    (printf "\t -I- Triggering interconnect callback  for instance %s\n" instance~>name)
			         (unless (fdkInvokeInstCdfCallbacks_r0d1_to_r0d2 instance 
							       ?debug debug
							       ?params params	       
							       )
			      (setq success nil)
			      )
			      
			    )
		  
       success
       )
  ) ; procedure

/***************************************************************
*                                                              *
*       (fdkUpdateProp cellView @key (propList nil))              *
*                                                              *
*  Deletes the specified properties from the CDF               *
***************************************************************/

(procedure (fdkUpdateProp cv @key ( propList nil) 
		       (outLog nil))
  let(( pId dummyProp cdfId  dummyPropId propId isoNestedId iNSumCheckId)
    cdfId = cdfGetInstCDF(cv)
    isoNestedId= cdfFindParamByName(cdfId "isoNested")
    iNSumCheckId= cdfFindParamByName(cdfId "iNSumCheck")
    isoNestedId~>value = "user-defined"
    iNSumCheckId~>value= "Not applicable"  
    foreach( prop propList
        rexCompile("Eff")
        rexExecute(prop)
	dummyProp =rexReplace(prop "" 0)
	dummyPropId= cdfFindParamByName(cdfId dummyProp)
	dummyPropId~>value= "0"
        when( dbGetPropByName( cv prop )                    
	   propId= cdfFindParamByName(cdfId prop)
           dummyPropId~>value = propId~>value
           printf("\t -I- Setting '%s' to value of parameter '%s' for instance %s\n" dummyProp prop cv~>name)
           fprintf(outLog "\tInstance %s Parameter value of %s copied to paramter %s \n" cv~>name prop dummyProp)
	   )
      )
    )
)


/******************************************************************
*                                                                 *
*   (fdkCdfCallbackEntireLib_r0d1_to_r0d2 libName @key (cellNames nil)         *
*                                              (viewNames nil)    *
*                                              (cellsToUpdate nil)*
*					      (params  nil)       *
*                                              (checkSave nil)    *
*					      (updatePropList nil)   *
*                                              (outLog  nil))     *
*                                                                 *
*  Specifies the CellViews whose instances' callbacks need to     *
*  triggered                                                      *        
******************************************************************/

(procedure (fdkCdfCallbackEntireLib_r0d1_to_r0d2 libName @key  (cellNames nil)
                                                  (viewNames nil)
                                                  (cellsToUpdate nil)
                                                  (params  nil)
                                                  (checkSave nil)
						  (outLog  nil)
						  )
  let((lib cells views cellName viewName cv _cellNames _viewNames)
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
          (if (member cv->cellViewType '("schematic" "maskLayout")) then
            cv = (dbOpenCellViewByType lib cell~>name view~>name nil "a")
            (if cv then
              fdkInvokeCdfCallbacks_r0d1_to_r0d2(cv ?debug t ?updateCells cellsToUpdate ?params params  ?outLog outLog)
              (if checkSave then
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
  );let
) ; procedure


/******************************************************************
*                                                                 *
*   (fdkTriggerFTCallbacks_r0d1_to_r0d2 libName @key (cellNames nil)          *
*                                        (viewNames nil)          *
*					 (params  nil)            *
*                                        (checkSave nil))         *
*                                                                 *
*  Triggers callbacks and deletes obsolete properties             *
*   for FT intances                                              *             *                                                                 *
******************************************************************/			      
(procedure (fdkTriggerFTCallbacks_r0d1_to_r0d2 libName @key (cellNames nil)  
                                                (viewNames nil) 
                                                (params    nil) 
                                                (checkAndSave nil)
						(outLog  nil)
						)
	   let(()
               fdkCdfCallbackEntireLib_r0d1_to_r0d2(libName 
				       ?cellNames cellNames  
				       ?viewNames viewNames 
				       ?params params
               ?cellsToUpdate '(("intel75prim" "cint") 
                                ("intel75prim" "rcint")) 
			?checkSave   checkAndSave
		        ?outLog      outLog
				       )
				      ); let
	   ); procedure


(procedure (fdkFTCdfUpdate_r0d1_to_r0d2 libName @key (cellNames nil)                                                                 (checkAndSave nil)
						             (logFile nil)
						)
	   let((dateTime outLog)
               if(dbGetOpenCellViews()
				    foreach(cv dbGetOpenCellViews()
					       if(cv~>modifiedButNotSaved then
									  libName = cv~>libName
									  cellName = cv~>cellName
									  viewName = cv~>viewName
									  error("Lib:%s Cell:%s View:%s modified but not saved. Please save or close all existing designs" libName cellName viewName)
									  else
                                                     
									  dbClose(cv)
									  )
					       )
				    warn("Closed all open cell views that were already saved if there were any")
				    ) 
  
	       dateTime = fdkGetCurrentTime()
               if(logFile then
		  logFile = sprintf(nil "./%s_%s" logFile dateTime)  		  		  else
		  logFile = sprintf(nil "./outLog_%s" dateTime)                 
		  )
	       outLog = outfile(logFile "w")
               fdkTriggerFTCallbacks_r0d1_to_r0d2(libName 
                                      ?cellNames cellNames  
                                      ?viewNames '("schematic") 
                                      ?params '("calcComp")
                                      ?checkAndSave checkAndSave
				      ?outLog outLog
				      )
	       close(outLog)
	       )
)


