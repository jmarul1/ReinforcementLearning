(defun pckStreamXOR (pth1 pth2 cell1 cell2)
(let (tmplFile of)
	(setShellEnvVar (strcat "XORSTM1=" pth1))
	(setShellEnvVar (strcat "XORSTM2=" pth2))
	(pckInfo "pckStreamXOR" (strcat "Running XOR between " cell1 " and " cell2))
	(setq tmplFile (strcat "/tmp/" (getShellEnvVar "USER") "_xorlist"))
	(setq of (outfile tmplFile "w"))
	(fprintf of "%s,%s" cell1 cell2)
	(close of)
	(sh (strcat "/nfs/ch/disks/ch_ciaf_disk011/pck73/utils/runXOR " tmplFile))
))		


(defun pckXORCells (lib1 cell1 lib2 cell2 @key (vw1 "layout") (vw2 "layout"))
(let (pthg pthch)
	(setq pthg (strcat (getShellEnvVar "FDK_WORK") "/pds/gold/"))
	(setq pthch (strcat (getShellEnvVar "FDK_WORK") "/pds/check/"))
	(pckStreamOut lib1 cell1 vw1 pthg (strcat pthg "/" cell1 ".gds"))
	(pckStreamOut lib2 cell2 vw2 pthch (strcat pthch "/" cell2 ".gds"))
	(pckStreamXOR pthg pthch cell1 cell2)
))

(defun pckXORCellStream (lib1 cell1 pthch cell2 @key (vw1 "layout"))
(let (pthg)
	(setq pthg (strcat (getShellEnvVar "FDK_WORK") "/pds/gold/"))
	(pckStreamOut lib1 cell1 vw1 pthg (strcat pthg cell1 ".gds"))
	(pckStreamXOR pthg pthch cell1 cell2)	
))



(defun pckXORStreamGUI ()
(let (cv srcRadio libName1 cellName1 vwName1 libName2 cellName2 vwName2 formXOR)
	(setq cv (geGetEditCellView (hiGetCurrentWindow)))
	(setq srcRadio (hiCreateRadioField
					?name 'srcRadio
					?prompt "Source:"
					?choices (list "Virtuoso" "Stream")
					?defValue "Virtuoso"
					?callback list("pckRedrawXORForm(formXOR)")    ;(list "(pckRedrawXORForm formXOR)" "(pckRedrawXORForm formXOR)")
				)
	)
	(setq libName1 (hiCreateStringField
					?name 'libName1
					?prompt "Golden Library"
					?value cv~>libName	
					?editable nil
				)
	)
	(setq cellName1 (hiCreateStringField
					?name 'cellName1
					?prompt "Golden Cell"
					?value cv~>cellName	
					?editable nil
				)
	)
	(setq vwName1 (hiCreateStringField
					?name 'vwName1
					?invisible t
					?value cv~>viewName
				)
	)
	(setq libName2 (hiCreateStringField
					?name 'libName2
					?prompt "Check Library"
					?value cv~>libName	
				)
	)
	(setq cellName2 (hiCreateStringField
					?name 'cellName2
					?prompt "Check Cell"
					?value cv~>cellName	
				)
	)
	(setq vwName2 (hiCreateStringField
					?name 'vwName2
					?prompt "Check View"
					?value "layout"
				)
	)
        (setq stmpath (hiCreateStringField
	                                ?name 'stmpath
					?prompt "Stream Path"
					?defValue (getShellEnvVar "PDSSTM")
					?invisible t
				)
	)				
	(setq formXOR (hiCreateAppForm
					?name 'formXOR
					?formTitle "XOR this layout with..."
					?callback (list "(pckXORCellGUICB formXOR)")
					?fields (list srcRadio libName1 cellName1 vwName1 libName2 cellName2 vwName2 stmpath)
					?unmapAfterCB	t
				)
	)
	(hiDisplayForm formXOR)
	t
))


(defun pckRedrawXORForm (form)
(let ()	
        (if (equal form->srcRadio->value "Stream") (progn
	 	form->stmpath->invisible = nil
		form->libName2->invisible = t
		form->cellName2->invisible = nil
		form->cellName2->value = ""
		form->vwName2->invisible = t
		form->stmpath->value = (getShellEnvVar "PDSSTM")
	) 
	
	
	(progn
		form->stmpath->invisible = t
		form->libName2->invisible = nil
		form->libName2->value = ""
		form->cellName2->invisible = nil
		form->vwName2->invisible = nil
	))

))


(defun pckXORCellGUICB (form)
(let ()
	(if (equal form->srcRadio->value "Stream") (progn
		(pckXORCellStream form->libName1->value form->cellName1->value form->stmpath->value form->cellName2->value ?vw1 form->vwName1->value)
	) (progn
		(pckXORCells form->libName1->value form->cellName1->value form->libName2->value form->cellName2->value ?vw1 form->vwName1->value ?vw2 form->vwName2->value)
	))
))





