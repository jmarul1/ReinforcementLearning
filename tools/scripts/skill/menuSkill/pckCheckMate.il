;;
;; (load "pckCheckMate.il")
;; 
;; load strcat("/prj/tccdev/work_areas/" getShellEnvVar("USER") "/tccdev/tcc_collateral/1269/skill/pckCheckMate.il")
;;

(defun pckMenuRunPDSForm ()
  (let (infoLogFile y field_list field_list2 pdsForm pdsFormTabs
		   (infoTestrowChecks
			(hiCreateLabel
			 ?name 'infoTestrowChecks
			 ?labelText "Testrow checks - by Eng Siah"))
		   (infoFillerFlow
			(hiCreateLabel
			 ?name 'infoFillerFlow
			 ?labelText "FE Filler Flow - by Vincent Rayappa"))
		   (infoPDSFlow
			(hiCreateLabel
			 ?name 'infoPDSFlow
			 ?labelText "PDS Flow interface - by Pavel Rott & W. B. Harris"))
		   (boundaryCheck
			(hiCreateBooleanButton
			 ?name 'boundaryCheck
			 ?buttonText "Testrow checks"
			 ?defValue nil
			 ?enabled  t ) )
		   ;; (runFillerFlow
		   ;; 	(hiCreateBooleanButton
		   ;; 	 ?name 'runFillerFlow
		   ;; 	 ?buttonText "FE filler flow"
		   ;; 	 ?defValue nil
		   ;; 	 ;;?callback "pckEnableFillerFlowForm( pdsForm )" ;; everything is done by default now
		   ;; 	 ?enabled  t ) )
		   (runPDSFlow
			(hiCreateBooleanButton
			 ?name 'runPDSFlow
			 ?buttonText "PDS flow"
			 ?defValue t
			 ?callback "pckEnablePDSFlowForm( pdsForm )"
			 ?enabled  t ) )
		   ;; (cn (hiCreateStringField
		   ;; 		?name 'cn
		   ;; 		?prompt "Cell To Fill"
		   ;; 		?defValue (geGetEditCellView)~>cellName
		   ;; 		?editable t))
		   ;; (ln (hiCreateStringField
		   ;; 		?name 'ln
		   ;; 		?prompt "Lib To Fill"
		   ;; 		?defValue (geGetEditCellView)~>libName
		   ;; 		?editable t))
		   ;; (fcns (hiCreateStringField
		   ;; 		?name 'fcns
		   ;; 		?prompt "Filler Cell(s)"
		   ;; 		?defValue "tp0filler01 tp0filler02 tp0filler03"
		   ;; 		?editable nil))
		   ;; (fln (hiCreateStringField
		   ;; 		 ?name 'fln
		   ;; 		 ?prompt "Filler Lib"
		   ;; 		 ?defValue PAD_LIB
		   ;; 	   ?editable nil))
		   ;; (tcn (hiCreateStringField
		   ;; 		 ?name 'tcn
		   ;; 		 ?prompt "Target Cell"
		   ;; 	   ?defValue (strcat ((geGetEditCellView)~>cellName) "_filler01")
		   ;; 	   ?editable nil))
		   ;; (tln (hiCreateStringField
		   ;; 		 ?name 'tln
		   ;; 		 ?prompt "Target Lib"
		   ;; 		 ?defValue (geGetEditCellView)~>libName
		   ;; 		 ?editable nil))
		   ;; (pcn (hiCreateStringField
		   ;; 		 ?name 'pcn
		   ;; 		 ?prompt "Pad Cell"
		   ;; 		 ?defValue "tp1padstd"
		   ;; 		 ?editable t))
		   ;; (pln (hiCreateStringField
		   ;; 		 ?name 'pln
		   ;; 		 ?prompt "Pad Lib"
		   ;; 		 ?defValue PAD_LIB
		   ;; 		 ?editable t))
		   (sep1 hiCreateSeparatorField(?name 'sep1 ) )
		   (sep2 hiCreateSeparatorField(?name 'sep2 ) )
		   (sep3 hiCreateSeparatorField(?name 'sep3 ) )
		   (sep4 hiCreateSeparatorField(?name 'sep4 ) )
		   (sep5 hiCreateSeparatorField(?name 'sep5 ) )
		   (sep6 hiCreateSeparatorField(?name 'sep6 ) )
		   (sep7 hiCreateSeparatorField(?name 'sep7 ) )
		   (sep8 hiCreateSeparatorField(?name 'sep8 ) )
		   (sep9 hiCreateSeparatorField(?name 'sep9 ) )

		   (pdsDataType (hiCreateCyclicField
						 ?name 'pdsDataType
						 ?prompt "Input Format"
						 ?choices list( "OA" "stm" )
						 ?defValue "stm"
						 ?enabled t
						 ))
		   ;; (pdsExplodeFile (hiCreateComboField
		   ;; 					?name 'pdsExplodeFile
		   ;; 					?prompt "Explode List File"
		   ;; 					?value "none"
		   ;; 					?items list("none")
		   ;; 					?enabled t
		   ;; 					))
		   (pdsNetbatchFlow (hiCreateCyclicField
							 ?name 'pdsNetbatchFlow
							 ?prompt "Netbatch"
							 ?choices list("local" "batch" )
							 ?callback "pckCheckMateNetbatchFlowForm( pdsForm )"
							 ?defValue "batch"
							 ?enabled t
							 ))
		   (pdsNetbatchClass ( hiCreateCyclicField
							   ?name 'pdsNetbatchClass
							   ?prompt "Batch Class"
							   ?choices (list "SLES10_EM64T_4G" "SLES10_EM64T_8G")
							   ?defValue "SLES10_EM64T_4G" 
							   ?enabled t
							   ))
		   (pdsNetbatchPool (hiCreateStringField
							 ?name 'pdsNetbatchPool
							 ?prompt "Batch Pool"
							 ?defValue "ch_vp"
							 ?editable t ))
		   (pdsNetbatchQSlot (hiCreateStringField
							  ?name 'pdsNetbatchQSlot
							  ?prompt "Batch QSlot"
							  ?defValue "/ciaf/pck"
							  ?editable t))
		   (traceTopCheck (hiCreateRadioField
						   ?name 'traceTopCheck
						   ?prompt "top check"
						   ?choices (list "check" "nocheck" "mixed" ) 
						   ?value   "check" 
						   ?defValue  "check" 
						   ?enabled  nil ))
		   ;; (runLVSCheck (hiCreateRadioField
		   ;; 				   ?name 'runLVSCheck
		   ;; 				   ?prompt "LVS"
		   ;; 				   ?choices (list "no" "yes" ) 
		   ;; 				   ?value   "no" 
		   ;; 				   ?defValue  "no" 
		   ;; 				   ?enabled  nil ) )
		   
		   (cellName (hiCreateStringField
					  ?name 'cellName
					  ?prompt "Cell"
					  ?defValue (geGetEditCellView)~>cellName
					  ?callback "(pckCheckMateLogFileCB pdsForm)"
					  ?editable t ))
		   (libName ( hiCreateStringField
					  ?name 'libName
					  ?prompt "Library"
					  ?defValue (geGetEditCellView)~>libName
					  ?editable t ))
		   (pdsStartHerculesExplorer 
			(hiCreateBooleanButton
			 ?name 'pdsStartHerculesExplorer
			 ?buttonText "Show PDS results in VUE"
			 ?defValue nil
			 ;;?callback "pckEnableFillerFlowForm( pdsForm )"
			 ?enabled  t ) )
		   (pdsAutotail 
			(hiCreateCyclicField
			 ?name 'pdsAutotail
			 ?prompt "Show PDS output"
			 ?choices list("yes" "no")
			 ?defValue "yes"
			 ;;?callback "pckEnableFillerFlowForm( pdsForm )"
			 ?enabled  t ) )

		  pdsFlowName 
	);; let parameters

	pdsFlowName= (hiCreateCyclicField
				  ?name 'pdsFlowName
				  ?prompt "Flow name"
				  ?choices ( pckGetAvailablePDSFlows (getShellEnvVar "ISSRUNSETS" ) )
				  ?defValue "drcd"
				  ;; callback to enable/disable Trace configuration
				  ?callback "pckPDSFlowNameCBK(pdsForm)"
				  ?enabled t
				  )

	(setq infoLogFile
			(hiCreateStringField
				?name 'infoLogFile
				?prompt "Log File:"
                ;; back to PDS-based env vars
				?defValue (strcat
						   (getShellEnvVar "PDSLOGS")
						   "/"
						   (geGetEditCellView)~>cellName "." pdsFlowName->value ".check_mate.log")
				?editable t
				?callback "(pckCheckMateLogFileCB pdsForm)"
				?enabled t))
	
	(y = 5) 
	(field_list = tconc(field_list 
                        list(sep2 0:y 500:0) ))
	(y = (y+5))
	;;
	;; Object selection
	;;
	(field_list = tconc(field_list 
						list(cellName 0:y 180:30 80) ))
	(field_list = tconc(field_list 
						list(libName 200:y 250:30 80) ))
	(y = (y+35))

	;;
	;; PDS Flow
	;;
	(field_list = tconc(field_list 
						list(pdsFlowName 0:y 248:30 80) ))
	(field_list = tconc(field_list 
						list(pdsDataType 250:y 200:30 80) ))
	(y = (y+25)) ;; 35
	(field_list = tconc(field_list 
						list(pdsNetbatchFlow 0:y 250:30 80) ))
	(y = (y+25)) ;; 35
	;; (field_list = tconc(field_list 
	;; 					list(pdsExplodeFile 0:y 450:30 140) ))
	(y = (y+35))
	(field_list = tconc(field_list 
                        list(sep4 0:y 500:0) ))
	(y = (y+5))
	(field_list = tconc(field_list 
						list(pdsNetbatchClass 0:y 140:30 84) ))
	(y = (y+25)) ;; added
	(field_list = tconc(field_list 
						list(pdsNetbatchPool 0:y 180:30 80) ))
	(field_list = tconc(field_list 
						list(pdsNetbatchQSlot 190:y 160:30 75) ))
	(y = (y+30)) ;; 35
	(field_list = tconc(field_list 
                        list(sep5 0:y 500:0) ))
	(y = (y+5))  ;; 10
	(field_list = tconc(field_list 
                        list(traceTopCheck 0:y 248:30 200) ))
	;; (y = (y+25))
	;; (field_list = tconc(field_list 
    ;;                     list(runLVSCheck 0:y 248:30 200) ))
	(y = (y+25)) ;; 35
	(field_list = tconc(field_list 
                        list(sep9 0:y 500:0) ))
	(y = (y+10))
	(field_list = tconc(field_list 
                        list(pdsStartHerculesExplorer 0:y 248:30 200) ))
	(field_list = tconc(field_list 
                        list(pdsAutotail 250:y 200:30 150) ))
	(y = (y+25)) ;; 35
	(field_list = tconc(field_list 
                        list(sep7 0:y 500:0) ))

	(field_list = car(field_list))
	;;**********************************************************************
	;;
	;; Second Tab
	;;
	;;**********************************************************************
	(y=5)
	(field_list2 = tconc(field_list2 list(sep7 5:y 450:0) ) )
	(y = (y+5))
	(field_list2 = tconc(field_list2 
						 list( infoTestrowChecks 0:y 450:30 ) ))
	(y = (y+35))
	(field_list2 = tconc(field_list2 
						 list( infoFillerFlow 0:y 450:30 ) ))
	(y = (y+35))
	(field_list2 = tconc(field_list2 
						 list( infoPDSFlow 0:y 450:30 ) ))
	(y = (y+35))
	(field_list2 = tconc(field_list2 list(sep8 5:y 550:0) ) )
	(y = (y+5))
	(field_list2 = tconc(field_list2 
						 list( infoLogFile 0:y 450:30 100) ))
	(field_list2 = car(field_list2))


	;;**********************************************************************
	;;
	;;  Initiate Forms
	;;
	;;**********************************************************************
 
	(setq pdsFormTabs ( hiCreateTabField
					 ?name 'pdsFormTabs
					 ?fields list( field_list field_list2)
					 ?tabs list("Configure" "Options")
					 ?tabPlacement 'top
					 ?value 1 ) )

	( setq pdsForm ( hiCreateAppForm
					 ?name 'pdsForm
					 ?formTitle "Welcome to TCC PDS DRC Checker"
					 ?callback list( "pckMenuCheckMateFromOKCB( pdsForm )" )
;;					 ?fields list( sep1  boundaryCheck 
;;										 sep2 cn ln fcns fln tcn tln pcn pln
;;										 sep3 flowName cellName libName )
;;					 ?fields field_list
					 ?fields list( list(pdsFormTabs 0:0 500:280) ) ;; 330
					 ?initialSize t
					 ?unmapAfterCB  t
					 )
		   )
	( hiDisplayForm pdsForm )
	)
  )

(defun pckMenuCheckMateFromOKCB ( daForm ) 
  (let ( ( tabInfo ( daForm->pdsFormTabs->page1)) ( tabInfo2 ( daForm->pdsFormTabs->page2) )
				   logFilePort resultBoundary resultFiller resultPDS 
				   (resultSummary "********** SUMMARY OF TESTROW CHECKING PROCEDURE *************\n" )
				   )
		 ( pckInfo "pckMenuCheckMateFromOKCB" "started." )
		 ( setq logFilePort (outfile tabInfo2->infoLogFile->value ) )
		 ; ( fprintf stdout "This is a bloody wrapper that takes care of ALL checks we want to do with a testrow!\n")
		 ( fprintf stdout "Opening a log file: %s\n" tabInfo2->infoLogFile->value )
		 ; ( fprintf logFilePort "This is a bloody wrapper that takes care of ALL checks we want to do with a testrow!\n")
		 ( fprintf logFilePort "Opening a log file: %s\n" tabInfo2->infoLogFile->value )
		 (if (tabInfo->boundaryCheck->value)
			 (progn
			   (fprintf stdout "Starting testrow boundary check.\n" )
			   (fprintf logFilePort "Starting testrow boundary check.\n" )
										;(resultBoundary = ( errset( pckCheckBoundary )))
			   (pckCheckBoundary tabInfo logFilePort)
			   (fprintf stdout "Starting reserved boundary space check.\n" )
			   (fprintf logFilePort "Starting reserved boundary space check.\n" )
			   (pckCheckFillerSpace  tabInfo logFilePort)
			   )
		   (progn
			 (fprintf stdout "Skipping testrow boundary check.\n" )
			 (fprintf logFilePort "Skipping testrow boundary check.\n" )
			 (resultBoundary = 0)
			 )
		   )
		 (drain logFilePort)
		 (if (tabInfo->runFillerFlow->value)
			 (progn
			   (fprintf stdout "Starting testrow FE filler flow.\n" )
			   (fprintf logFilePort "Starting testrow FE filler flow.\n" )
			   ;;(resultFiller = ( errset( pckCheckFillerSpace )))
			   )
		   (progn
			 (fprintf stdout "Skipping testrow FE filler flow.\n" )
			 (fprintf logFilePort "Skipping testrow FE filler flow.\n" )
			 (resultFiller = 0)
			 )
		   )
		 (drain logFilePort)
		 ;;**********************************************************************
		 ;;
		 ;; PDS analysis
		 ;;
		 ;;**********************************************************************
;;		 (if (tabInfo->runPDSFlow->value) ;; this has been removed from menu items
		 (if t ;; this is now a PDS checker only - so it should always be enabled!
			 (progn
			   (fprintf stdout "\n\n")
			   (fprintf stdout "\n\n******* Starting TCC Design Rule Checker **********\n\nISSRUNSET: %s\n" getShellEnvVar("ISSRUNSETS") )
			   (fprintf stdout "******* PDS Log area: %s\n" getShellEnvVar("PDSLOGS") )
			   (fprintf stdout "******* PDS working area: %s\n" getShellEnvVar("PDSWORKROOT") )
			   (fprintf stdout "******* PDS flow: %s Input format: %s\n" tabInfo->pdsFlowName->value tabInfo->pdsDataType->value)
			   
			   (fprintf logFilePort "\n\n")
			   (fprintf logFilePort "\n\n******* Starting TCC Design Rule Checker **********\n\nISSRUNSET: %s\n" 
                        getShellEnvVar("ISSRUNSETS") )
			   (fprintf logFilePort "******* PDS Log area: %s\n" getShellEnvVar("PDSLOGS") )
			   (fprintf logFilePort "******* PDS working area: %s\n" getShellEnvVar("PDSWORKROOT") )
			   (fprintf logFilePort "******* PDS flow: %s Input format: %s\n" tabInfo->pdsFlowName->value tabInfo->pdsDataType->value)

			   (if (equal tabInfo->pdsNetbatchFlow->value "batch")
				   (progn 
					  (fprintf stdout "******* Running PDS flow in netbatch mode: Class %s Pool: %s QSlot: %s\n"
                               tabInfo->pdsNetbatchClass->value tabInfo->pdsNetbatchPool->value tabInfo->pdsNetbatchQSlot->value ))
					 (fprintf logFilePort "******* Running PDS flow in netbatch mode: Class %s Pool: %s QSlot: %s\n"
                              tabInfo->pdsNetbatchClass->value tabInfo->pdsNetbatchPool->value tabInfo->pdsNetbatchQSlot->value ))
				 (progn 
				   (fprintf stdout "******* Running PDS flow locally.\n" )
				   (fprintf logFilePort "******* Running PDS flow locally.\n" )
				   )
				 (drain logFilePort)
				 (setq resultPDS 
					   (pckStartPDSFlow tabInfo->cellName->value
										?libName tabInfo->libName->value
										?flow tabInfo->pdsFlowName->value
										?inputType tabInfo->pdsDataType->value
										?runMode tabInfo->pdsNetbatchFlow->value
										;;?explode tabInfo->pdsExplodeFile->value
										?nbPool tabInfo->pdsNetbatchPool->value
										?nbClass tabInfo->pdsNetbatchClass->value
										?nbqSlot tabInfo->pdsNetbatchQSlot->value
										?traceTopCheck tabInfo->traceTopCheck->value
										?pdsAutotail tabInfo->pdsAutotail->value
										?gdsName "DEFAULT"
										?port logFilePort
										?postProcessing (if tabInfo->pdsStartHerculesExplorer->value
															(list 'pckCheckMatePostProcessing
																  tabInfo->cellName->value
																  tabInfo->libName->value
																  tabInfo->pdsFlowName->value
																  tabInfo2->infoLogFile->value)
														  t)
										)
					   )
				 )
		   (progn 
			 (fprintf stdout "Skipping PDS check.\n" )
			 (fprintf logFilePort "Skipping PDS check.\n" )
			 ;;
			 ;; In case of PDS run, log file will be closed there.
			 (close logFilePort)
			 (resultPDS = 0))
		   )
		 )
	)


(defun pckCheckMateLogFileCB (daForm)
  (let (( tabInfo1 ( daForm->pdsFormTabs->page1)) ( tabInfo2 ( daForm->pdsFormTabs->page2)) text)
	;;text =  (strcat ( getShellEnvVar "PDSLOGS") "/" tabInfo->cellName->value ".check_mate.log")
	tabInfo2->infoLogFile->value = (strcat ( getShellEnvVar "PDSLOGS") "/" tabInfo1->cellName->value "." tabInfo1->pdsFlowName->value ".check_mate.log")
	)
  )

(defun pckEnableFillerFlowForm ( daForm )
  ;;( pckInfo "pckEnableFillerFlowForm" "started." )
  (let (( tabInfo ( daForm->pdsFormTabs->page1)))
	(if (tabInfo->runFillerFlow->value)
		(progn
		  ;;tabInfo->cn->editable = t
		  ;;tabInfo->ln->editable = t
		  tabInfo->fln->editable = t
		  tabInfo->cn->editable = t
		  tabInfo->pcn->editable = t
		  tabInfo->pln->editable = t
		  );; enable
	  (progn 
		;;tabInfo->cn->editable = nil
		;;tabInfo->ln->editable = nil
		tabInfo->fln->editable = nil
		tabInfo->cn->editable = nil
		tabInfo->pcn->editable = nil
		tabInfo->pln->editable = nil
		);; disable
	  )
	);; let
  );;
(defun pckCheckMateNetbatchFlowForm (daForm )
  ;;(pckInfo "pckCheckMateNetbatchFlowForm" "started." )
  (let (( tabInfo ( daForm->pdsFormTabs->page1)))
	(if (getShellEnvVar "NBQSLOT")
		tabInfo->pdsNetbatchQSlot->value = (getShellEnvVar "NBQSLOT") 
		tabInfo->pdsNetbatchQSlot->value = "/ciaf/pck"
		)
	(if (getShellEnvVar "NBPOOL")
		tabInfo->pdsNetbatchPool->defValue = (getShellEnvVar "NBPOOL") 
		tabInfo->pdsNetbatchPool->defValue = "linux1"
		)


	(if (equal tabInfo->pdsNetbatchFlow->value "batch")
		(progn
		  tabInfo->pdsNetbatchClass->enabled = t
		  tabInfo->pdsNetbatchPool->editable = t
		  tabInfo->pdsNetbatchQSlot->editable = t
		  tabInfo->pdsStartHerculesExplorer->enabled = nil
		  tabInfo->pdsStartHerculesExplorer->value = nil
		  )
	  (progn
		tabInfo->pdsNetbatchClass->enabled = nil
		tabInfo->pdsNetbatchPool->editable = nil
		tabInfo->pdsNetbatchQSlot->editable = nil
		tabInfo->pdsStartHerculesExplorer->enabled = t
		tabInfo->pdsStartHerculesExplorer->value = t
		)
	  )
	);;let
  );;
(defun pckPDSFlowNameCBK (daForm)
  (let (( tabInfo ( daForm->pdsFormTabs->page1)))
	(pckCheckMateLogFileCB daForm)
	(if (rexMatchp "trc" tabInfo->pdsFlowName->value)
		(progn
		  tabInfo->traceTopCheck->enabled = t
		  ;; tabInfo->runLVSCheck->enabled = t
		  )
	  (progn 
		tabInfo->traceTopCheck->enabled = nil
		;; tabInfo->runLVSCheck->enabled = nil
		))
	t
	)
  )


(defun pckEnablePDSFlowForm (daForm )
  (let (( tabInfo ( daForm->pdsFormTabs->page1)))
	(if (tabInfo->runPDSFlow->value)
		(progn 
		  tabInfo->pdsFlowName->enabled = t
		  tabInfo->pdsDataType->enabled = t
		  tabInfo->pdsNetbatchFlow->enabled = t
		  tabInfo->pdsExplodeFile->enabled = t
		  tabInfo->pdsStartHerculesExplorer->enabled = t
		  tabInfo->pdsAutotail->enabled = t
		  ( pckCheckMateNetbatchFlowForm daForm )
		  )
	  (progn 
		tabInfo->pdsFlowName->enabled = nil
		tabInfo->pdsDataType->enabled = nil
		tabInfo->pdsNetbatchFlow->enabled = nil
		;;( pckCheckMateNetbatchFlowForm daForm )
		tabInfo->pdsNetbatchClass->enabled = nil
		tabInfo->pdsNetbatchPool->editable = nil
		tabInfo->pdsNetbatchQSlot->editable = nil
		tabInfo->pdsExplodeFile->enabled = nil
		tabInfo->pdsStartHerculesExplorer->enabled = nil
		tabInfo->pdsAutotail->enabled = nil
		)
	  )
	);; let
  )

;; ********************************************************************************************************************

(defun pckGetAvailableFDKFlows ( runsetDir )
  "Function to fnd all flows defined in FDK runset"
	(let ( fileL (flowName nil) )
	  (setq fileL (setof f (getDirFiles runsetDir) (rexMatchp ".+ev" f)))
	  (setq flowName (mapcar (lambda (st) (car (parseString st "."))) fileL))
	  
	  (sort flowName nil)
	  )
	)

(defun pckGetAvailablePDSFlows ( runsetDir )
  "Function to find all flows defined in LTD AD runset"
  (let ((fileList (list "pds.flows" "pds.flows.dve" "PXL/pypds.flows") )
		fullFileName readPort nextLine (flowName nil))
	(when (equal (getShellEnvVar "PROCESS_NAME") "1273")
		(setq fileList (list "PXL/1273/pypds.flows"))
		)
	
	(foreach fileName fileList
			 (setq fullFileName (strcat runsetDir "/" fileName ) )
			 (if (isFile fullFileName )
				 (progn 
				   (setq readPort (infile fullFileName ) )
				   (when readPort
					 (while (gets nextLine readPort)      
					   ;;(fprintf stdout "-D Line: %s\n" nextLine)
					   (if (rexMatchp "^[a-zA-Z]" nextLine);; avoiding comments
						   (progn 
							 (setq flowName (cons (car (parseString nextLine) ) flowName) )
							 )
						 )
					   )
					 (close readPort)
					 )
				   )
			   )
			 );; foreach
	;; added by rkalim - put complex flows here
	(setq flowName (cons "All73atctapein" (cons "AllDen" (cons "AllDrc" (cons "drcd_pin_check" flowName)))))
	(fprintf stdout "-D- Available flows: %L" flowName)
	
	(sort flowName nil)
	)
  )


;; ********************************************************************************************************************

(defun pckCheckMatePostProcessing (cellName libName pdsFlowName port)
	(let (cmd vueFile result options dirName
              (flowVersion (car (last ( parseString (getShellEnvVar "ISSRUNSETS") "/") ) ) )
              resultList thisWindow )
      
	  (setq port (outfile port "a"))
      ;;
      ;; Massage Hercules run directory a bit
      ;;
      ;;
      ;; Now start Hercules VUE (used to be called Explorer, I'm too lazy to change control variable name)!
      ;;
      (fprintf stdout "***** Starting Hercules VUE.\n" )
      (fprintf port "***** Starting Hercules VUE.\n" )
      
      (sprintf vueFile "%s/%s.%s.py.run_details/%s.vue" 
               getShellEnvVar("PDSLOGS") 
               cellName
               pdsFlowName
               cellName )
      
      (fprintf stdout "***** VUE file: %s\n" vueFile )
      if( isFile( vueFile)
                (progn
                  (setq options (sprintf nil "\"-lay virtuoso -load %s\"" vueFile))                
                  (setq thisWindow (geOpen
                                    ?lib libName 
                                    ?cell cellName 
                                    ?view "layout" 
                                    ?viewType "maskLayout" 
                                    ?mode "r" ))
                  (when (and thisWindow (geIsGraphicalWindow thisWindow))
                      (snpsHvRunVUE options )
                      (snpsHvLaySetWindow thisWindow )                      
                      )
                  )
                (progn 
                  else
                  (fprintf stdout "***** ERROR: Could not find the VUE file!")
                  (fprintf port "***** ERROR: Could not find the VUE file!"))
                );; vue file exists

		  
		  ;; close the log file
		  ;;(fprintf port "***** Postprocessing complete.\n")
          (drain port)
          (drain stdout)
		  (close port)
		  t
	 );; prog 
  );; postProcessPDSFlowRun

