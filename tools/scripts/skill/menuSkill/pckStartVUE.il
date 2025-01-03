;;
;; (load "pckStartVUE.il")
;; Modified 5/5/2011: Balaji Ramasubramanian
;;		Include changes to enable loading XOR VUE files
;;


(defun pckStartVUEMenu ()
(let (startVUEform libName cellName pdsFlowName thisCellView workArea)

    (setq thisCellView (geGetEditCellView hiGetCurrentWindow()))

    (setq libName (hiCreateStringField
                   ?name 'libName
                   ?prompt "Library:"
                   ?defValue thisCellView~>libName
                   ?editable t
                   ) 
          )

    (setq cellName (hiCreateStringField
                     ?name 'cellName
                     ?prompt "Cell Name:"
                     ?defValue thisCellView~>cellName
                     ?editable t
                     ) 
          )


/*	(setq FlowSelector (hiCreateBooleanButton
			?name 'FlowSelector
			?buttonText "Select XOR VUE:"
			?defValue nil
			?callback "{ (pckRedrawStartVUEWindow startVUEform) }"
		)
	)

    (setq pdsFlowName (hiCreateCyclicField
                   ?name 'pdsFlowName
                   ?prompt "Flow Name:"
                   ?choices ( pckGetAvailablePDSFlows ( getShellEnvVar "ISSRUNSETS" ) )
                   ?defValue (if (member "drcd"
                                         (pckGetAvailablePDSFlows (getShellEnvVar "ISSRUNSETS"))
                                         )
                                 "drcd"
                                 (car (pckGetAvailablePDSFlows (getShellEnvVar "ISSRUNSETS")))
                                 )
                   ?enabled t
                   )
	)*/

	(setq workArea ( hiCreateStringField
				  ?name 'workArea
				  ?prompt "Work Area:"
				  ?defValue (strcat (getShellEnvVar "WARD") "/pds/logs/")
				  ?editable t
				  )
		  )

    (setq startVUEform (hiCreateAppForm
                         ?name 'startVUEform
                         ?formTitle "Start VUE"
                         ?callback list( "pckStartVUE( startVUEform )" )
                         ?fields list( libName cellName FlowSelector pdsFlowName workArea )
                         ?unmapAfterCB	t
                         )
          )
    (hiDisplayForm startVUEform )
    t
))      ;; procedure pckStartVUEMenu


(defun pckRedrawStartVUEWindow (form)
(let ()
	(if form->FlowSelector->value (progn
		form->workArea->value = (strcat (getShellEnvVar "FDK_WORK") "/pds/xor/")
		form->pdsFlowName->prompt = "XOR Comparisons:"
		(if (and (isDir form->workArea->value) (nequal 0 (length (setof x (getDirFiles form->workArea->value) (rexMatchp form->cellName->value x))))) (progn
			form->pdsFlowName->choices = (setof x (getDirFiles form->workArea->value) (rexMatchp form->cellName->value x))
			form->pdsFlowName->defValue = (car (setof x (getDirFiles form->workArea->value) (rexMatchp form->cellName->value x)))
			form->pdsFlowName->enabled = t
		) (progn
			form->pdsFlowName->choices = (list "No XOR files")
			form->pdsFlowName->defValue = "No XOR files"
			form->pdsFlowName->enabled = nil
		))
	) (progn
		form->workArea->value = (strcat (getShellEnvVar "FDK_WORK") "/pds/logs/")
		form->pdsFlowName->prompt = "Flow Name:"
		form->pdsFlowName->choices = ( pckGetAvailablePDSFlows ( getShellEnvVar "ISSRUNSETS" ) )
        (if (member "drcd" (pckGetAvailablePDSFlows (getShellEnvVar "ISSRUNSETS"))) (progn 
			form->pdsFlowName->value = "drcd" 
		) (progn
			form->pdsFlowName->value = (car (pckGetAvailablePDSFlows (getShellEnvVar "ISSRUNSETS")))
		))
		form->pdsFlowName->enabled = t
	))
))


(defun pckStartVUE (form)
(let ( thisWindow options vueFile )
    ;(pckInfo "pckStartVUE" "***** Starting Hercules VUE.\n" )
     (progn
	    (if (equal form->FlowSelector->value nil) (progn
	    (sprintf vueFile "%s/%s.%s.icv.run_details/%s.vue" ;; Changed to ICV
                    form->workArea->value
                    form->cellName->value
                    "drcd";form->pdsFlowName->value
                    form->cellName->value )))
      )
    ;(pckInfo "pckStartVUE" (strcat "***** VUE file: " vueFile) )
    (if (isFile vueFile)
        (progn

          (setq options (sprintf nil "\"-lay virtuoso -load %s\"" vueFile))
          (setq thisWindow (hiGetCurrentWindow))

          (when (and thisWindow (geIsGraphicalWindow thisWindow))
                (snpsHvRunVUE options)
                (snpsHvLaySetWindow thisWindow )
              )
          )
        (progn 
          (pckError "pckStartVUE" "***** ERROR: Could not find a VUE file!"))
        ) ;; vue file exists
)) ;; procedure pckStartVUE


