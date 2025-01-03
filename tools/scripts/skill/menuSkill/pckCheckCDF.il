;;
;; (load "pckCheckCDF.il")
;;
;;
(defun pckCheckCDFTermOrder (lb cl )
  (let (cellId cdfId initP auCdlTO spectreTO hspiceTO)
  
	(unless (setq cellId (ddGetObj lb cl))
	  (pckError "Could not get cell %s." CELL))

	;;Create CDF
	(setq cdfId (cdfGetBaseCellCDF cellId))
	(pckInfo "pckCheckCDFTermOrder" (sprintf nil "%L" cdfId~>??))
	(pckInfo "pckInfo" (sprintf nil "initProc - %L" cdfId~>formInitProc))
	(pckInfo "pckInfo" (sprintf nil "Spectre terminals - %L" (getq (getq cdfId~>simInfo "spectre") "termOrder")))
	(pckInfo "pckInfo" (sprintf nil "auCdl terminals - %L" (getq (getq cdfId~>simInfo "auCdl") "termOrder")))
	(pckInfo "pckInfo" (sprintf nil "hspice terminals - %L" (getq (getq cdfId~>simInfo "hspiceD") "termOrder")))
	(when (and (nequal cdfId~>formInitProc nil) (not (fboundp (concat cdfId~>formInitProc))))
		(pckError "pckCheckCDFTermOrder" (sprintf nil "init procedure %L not defined for %s %s" cdfId~>formInitProc lb cl))
		)
	(when (nequal (getq (getq cdfId~>simInfo "auCdl") "termOrder") (getq (getq cdfId~>simInfo "spectre") "termOrder"))
	  (pckError "pckCheckCDFTermOrder" (sprintf nil "auCdk termOrder %L differs from spectre termOrder %L for %s %s"
												(getq (getq cdfId~>simInfo "auCdl") "termOrder")
												(getq (getq cdfId~>simInfo "spectre") "termOrder")
												lb cl
												))
	  )
	(when (nequal (getq (getq cdfId~>simInfo "auCdl") "termOrder") (getq (getq cdfId~>simInfo "hspiceD") "termOrder"))
	  (pckError "pckCheckCDFTermOrder" (sprintf nil "auCdk termOrder %L differs from hspiceD termOrder %L for %s %s"
												(getq (getq cdfId~>simInfo "auCdl") "termOrder")
												(getq (getq cdfId~>simInfo "hspiceD") "termOrder")
												lb cl
												))
	  )
	
	
	)

  )
(defun pckCheckModelName (lb cl)
  (let (cellId cdfId)
	(unless (setq cellId (ddGetObj lb cl))
	  (pckError "Could not get cell %s." cl))
	(setq cdfId (cdfGetBaseCellCDF cellId))
	(if (equal (getq (getq cdfId~>simInfo "auCdl") "modelName") "")
		(progn 
		  (pckError "pckCheckCDFTermOrder" (sprintf nil "model parameter in auCdl of %s %s is empty string." lb cl))
		  cl
		  )
	  (progn
		nil
		)
	  )
	)
  )
(defun pckCheckNetlistProcedureName (lb cl)
  (let (cellId cdfId)
	(unless (setq cellId (ddGetObj lb cl))
	  (pckError "Could not get cell %s." cl))
	(setq cdfId (cdfGetBaseCellCDF cellId))
	(if (and (equal (getq (getq cdfId~>simInfo "auCdl") "netlistProcedure") 'ansCdlCompParamPrim)
			 (equal (getq (getq cdfId~>simInfo "auCdl") "modelName") "")
			 (or  (equal (getq (getq cdfId~>simInfo "auCdl") "instParameters") "")
				  (equal (getq (getq cdfId~>simInfo "auCdl") "instParameters") nil))
			 )
		(progn 
		  (pckError "pckCheckCDFTermOrder" (sprintf nil "netlistProcedure in auCdl of %s %s is ansCdlCompParamPrim." lb cl))
		  cl
		  )
	  (progn
		nil
		)
	  )
	)
  )

(defun pckCheckCDFTermOrderLibs (lib_list)
  ;;
  ;; (pckCheckCDFTermOrderLibs (list (ddGetObj "fdk71pxprimtemplate")))
  (let (i cell (problem_list '()))
	(foreach lib lib_list
			 (setq i 0)
			 (foreach cell (dbGetq (ddGetObj lib) "cells")
					  (fprintf stdout ">>>> Processing cell # %d - %s. %d to go.\n" i cell~>name
							   (difference  (length (dbGetq (ddGetObj lib) "cells") )
											i))
					  ;;(pckCheckCDFTermOrder lib cell~>name)
					  ;;(setq return (pckCheckModelName lib cell~>name))
					  (setq return (pckCheckNetlistProcedureName lib cell~>name))
					  (when return
						(setq problem_list (cons return problem_list)))
					  (setq i (add1 i))
					  )
			 )
	problem_list
	
	))