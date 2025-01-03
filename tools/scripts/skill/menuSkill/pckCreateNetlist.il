;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Intel Top Secret                                                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copyright (C) 2013, Intel Corporation.  All rights reserved.             ;;
;;                                                                          ;;
;; This is the property of Intel Corporation and may only be utilized       ;;
;; pursuant to a written Restricted Use Nondisclosure Agreement             ;;
;; with Intel Corporation.  It may not be used, reproduced, or              ;;
;; disclosed to others except in accordance with the terms and              ;;
;; conditions of such agreement.                                            ;;
;;                                                                          ;;
;; All products, processes, computer systems, dates, and figures            ;;
;; specified are preliminary based on current expectations, and are         ;;
;; subject to change without notice.                                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; This tool is used to generate netlist (CDL, Spectre, hspiceD, etc).
;; rkalim 7/30/2013  Added support for new cfdk736_r1.2 kit structure
;;                  depending on kit structure FDK_INST_DIR/models/cdl/core using latest or not
;; rkalim 11/14/2013 Added support for kit pdk736_r1.3.  It uses $INTEL_PDK instead of $FDK_INST_DIR
;;                    

;; $Revision: 1.23 $ $Date: Mon Jul 29 14:27:36 2013 $

;;
;;
;; (load "pckCreateNetlist.il")
;;
;;
(defun pckQuickNetlistGUI (@optional cv)
  (let (CellNameField defLib defCell defPath defNetlistName
					  quickNetlistForm LibNameField PathField NetlistNameField SimulatorField ViewNameField)
	
	(unless cv (setq cv (geGetEditCellView)))

	defLib = cv~>libName
	defCell = cv~>cellName
	(setq defNetlistName (strcat defCell ".cdl"))
	(setq defPath (strcat (getShellEnvVar "FDK_WORK") "/netlists/cdl"))

	(setq  CellNameField
		   (hiCreateStringField
			?name		'CellNameField
			?prompt		"Cell Name:"
			?value      defCell
			?callback   "{ quickNetlistForm->NetlistNameField->value = pckNetlistNameCB( CellNameField->value) }"
			))

	(setq LibNameField (hiCreateStringField
						?name		'LibNameField
						?prompt		"Library Name:"
						?value      defLib
						))

	(setq ViewNameField (hiCreateStringField
						?name		'ViewNameField
						?invisible	t
						?value      cv~>viewName
						))

	(setq SimulatorField (hiCreateRadioField
						?name		'SimulatorField
						?prompt		"Simulator:"
						?choices	(list "cdl" "spectre" "hspiceD" "spice" "all")
						?value		"cdl"
						?callback	(list "{ (pckRedrawQuickNetlistWindow quickNetlistForm)}" "{ (pckRedrawQuickNetlistWindow quickNetlistForm)}" "{ (pckRedrawQuickNetlistWindow quickNetlistForm)}"
										"{ (pckRedrawQuickNetlistWindow quickNetlistForm)}" "{ (pckRedrawQuickNetlistWindow quickNetlistForm)}")
						))

	(setq PathField
		  (hiCreateStringField
		   ?name		'PathField
		   ?prompt		"Netlist File Path:"
		   ?value      defPath
		   ))

	(setq NetlistNameField
		  (hiCreateStringField
		   ?name		'NetlistNameField
		   ?prompt		"Netlist File Name:"
		   ?defValue   defNetlistName
		   ?value      defNetlistName
		   ))

	(setq quickNetlistForm
		  (hiCreateAppForm
		   ?name		'quickNetlistForm
		   ?fields		list('CellNameField
							 'LibNameField
							 'SimulatorField
							 'ViewNameField
							 'PathField
							 'NetlistNameField
							 )
		   ?formTitle	"Quick Netlist File generation"
		   ?callback	"{ pckQuickNetlistCB( quickNetlistForm) }"

		   ))
	(hiDisplayForm 'quickNetlistForm )
))


(defun pckNetlistTypeExtn (simulator)
(let (fileEXTN)
	(setq fileEXTN (list nil 'cdl "cdl" 'spectre "scs" 'hspiceD "hsp" 'spice "sp"))
	(evalstring (strcat "fileEXTN->" simulator))
))

(defun pckRedrawQuickNetlistWindow (formHandle)
(let ()
	(if (nequal formHandle->SimulatorField->value "all") (progn
		formHandle->PathField->value = (strcat (getShellEnvVar "FDK_WORK") "/netlists/" formHandle->SimulatorField->value)
		formHandle->NetlistNameField->value = (strcat formHandle->CellNameField->value "." (pckNetlistTypeExtn formHandle->SimulatorField->value))
		formHandle->PathField->editable = t
		formHandle->NetlistNameField->editable = t
	) (progn
		formHandle->PathField->value = (strcat (getShellEnvVar "FDK_WORK") "/netlists/<all>" )
		formHandle->NetlistNameField->value = (strcat formHandle->CellNameField->value ".<all>")
		formHandle->PathField->editable = nil
		formHandle->NetlistNameField->editable = nil
	))
))

(defun pckCreateNetlistDir (path)
(let ()
	(unless (isDir path) (progn
		(pckInfo "pckQuickNetlistCB" (sprintf nil "Directory %s is not present." path))
		(if (sh (strcat "mkdir " path)) (progn
			(pckInfo "pckQuickNetlistCB" (sprintf nil "Directory %s was created." path))
		)(progn
			(pckInfo "pckQuickNetlistCB" (sprintf nil "Directory %s could not be created." path))
			(error (sprintf nil "Directory %s could not be created." path))
		))
	))
))


(defun checkNetlistStatus (path fname)
(let ()
	(if (isFile (strcat path "/" fname)) (progn
		(pckInfo "pckQuickNetlistCB" (sprintf nil "Netlist %s created." (strcat path "/" fname)))
	) (progn
		(pckInfo "pckQuickNetlistCB" (sprintf nil "Netlist %s generation failed." (strcat path "/" fname)))
	))
))


(defun pckQuickNetlistCB ( formHandle)
(let (sim simuls path fname)
	(if (equal "all" formHandle->SimulatorField->value) (progn
		(setq simuls (list "cdl" "spectre" "hspiceD" "spice"))
	) (progn
		(setq simuls (list formHandle->SimulatorField->value))
	))
	(foreach sim simuls
		(setq path formHandle->PathField->value)
		(setq fname formHandle->NetlistNameField->value)
		(when (rexMatchp "\\(.*\\)<all>" formHandle->PathField->value) (setq path (rexSubstitute (strcat "\\1" sim))))
		(when (rexMatchp "\\(.*\\)<all>" formHandle->NetlistNameField->value) (setq fname (rexSubstitute (strcat "\\1" (pckNetlistTypeExtn sim)))))
		(pckCreateNetlistDir path)
		(if (equal "cdl" sim) (progn
			(pckMakeQuickCDLNetlist formHandle->CellNameField->value formHandle->LibNameField->value path fname)
		) (progn
			(pckMakeQuickADENetlist sim formHandle->CellNameField->value formHandle->LibNameField->value formHandle->ViewNameField->value path fname)
		))
		(checkNetlistStatus path fname)
	)
	t
))


/*
* Functions that actually generate the netlist are grouped below
* One function for each type of netlist will be defined.
*
*/


(defun pckMakeQuickCDLNetlist (cn ln path fn)
(let (syscmd)
	(pckSiEnvTemplate (strcat path "/si.env") cn ln path fn)
	(sprintf syscmd "si %s -batch -command netlist -cdslib %s" path (strcat (getShellEnvVar "FDK_WORK") "/cds.lib"))
	(pckInfo "pckMakeQuickCDLNetlist" (sprintf nil "Running netlist generation: %s" syscmd))
	(system syscmd)
))

(defun pckMakeQuickADENetlist (sim_name cell lib view path fn)
(let (simDir)
	(setq simDir (strcat "/tmp/" (getShellEnvVar "USER") "_simulation"))
	(envSetVal "asimenv.startup" "projectDir" 'string simDir)
	(when (equal "spice" sim_name) (setq sim_name "hspiceD"))
	(simulator (concat sim_name) )
	(design lib cell view)
	(pckInfo "pckMakeQuickADENetlist" (sprintf nil "Running %s netlist generation..." sim_name ))
	(createNetlist ?display nil)
	(sh (strcat "cp " simDir "/" cell "/" sim_name "/" view "/netlist/netlist " path "/" fn))
))


;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;
;;	3 functions to deal with ipcBeginProcess ports
;;
;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


(defun pckCdlNetlistData (cid data)
  t
  )

(defun pckCdlNetlistErr (cid err)
  (printf "Error %L Msg: %s\n" cid err)
  (ipcKillProcess cid) 
  )

(defun pckCdlNetlistTerm (cid exit)
  (printf "CDL Netlisting completed with exit status = %d\n" exit)
  )

;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;
;;	CDL si.env template generation
;;

;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

(defun pckNetlistNameCB (cellName)
  (strcat cellName ".cdl")  
  )


(defun pckSiEnvTemplate (env_file cn ln path fn)
  (let (TMPL text incFile link1 link2 cdlLink)
	;;
	;; Use FDK_CDL_INCLUDE_FILE variable to override
	;; default CDL files coming from FDK_INST_DIR area
	;; Otherwise contents of $FDK_INST_DIR/models/cdl/dot#FDK_DOTPROC
	;; will be used
	(if (getShellEnvVar "FDK_CDL_INCLUDE_FILE") then
		(setq incFile (getShellEnvVar "FDK_CDL_INCLUDE_FILE"))
	else
	;; we have three cases of kit structure here.
	;; if we have $INTEL_PDK then uses $INTEL_PDK/models/cdl/custom
	;; if we have $FDK_INST_DIR/models/cdl/core/latest link => use it
	;; if not, use $FDK_INST_DIR/models/cdl/core
	(if (getShellEnvVar "INTEL_PDK") then
		(setq link0a  (getShellEnvVar "INTEL_PDK"))
		(setq link0b  (strcat (getShellEnvVar "INTEL_PDK") "/models/cdl/custom"))
		
		(if (isDir link0a ) then
		;;(printf "RK0a - found INTEL_PDK %s\n" link0a)
        		(if (isLink link0b ) then
				;;(printf "RK0b - Using link0b %s\n" link0b)
				(setq cdlLink link0b)
			else
				(printf "WARNING - your setup has INTEL_PDK %s but not CDL directory %s \n" link0a link0b)
				(setq cdlLink "INTEL_PDK_models.cdl.custom_notdefined_correctly")
			)  ;; end of if link0b	
		else 
			(printf "WARNING - your setup does not have INTEL_PDK %s  \n" link0a)
			(setq cdlLink "INTEL_PDK_NOT_DEFINED_CORRECTLY")
		) ;; end if link0a
	else
		(setq link1  (strcat (getShellEnvVar "FDK_INST_DIR") "/models/cdl/core/latest"))
		(setq link2  (strcat (getShellEnvVar "FDK_INST_DIR") "/models/cdl/core"))
	        (if (isLink link1 ) then
			;;(printf "RK2 - link1 wins %s \n" link1)
			(setq cdlLink link1)
		else 
			(if (isLink link2) then
				;;(printf "RK3 - link2 wins %s \n" link2)
				(setq cdlLink link2)
			else
				;;(printf "RK5 - no link wins \n")
				(setq cdlLink "FDK_INST_DIR_NOT_DEFINED_CORRECTLY")

			) ;; end if isFile link2
		) ;; end isFile link1
	) ;; end of getShellEnvVar INTEL_PDK

	  ;; This will build incFILE instruction in CDL OUT template
	  ;; using ALL cdl file in models/cdl area
	  (progn
		(setq incFile "")
		(when
			(and
			 (getShellEnvVar "FDK_INST_DIR")
			 (getShellEnvVar "FDK_DOTPROC"))
		  (mapcar (lambda (x)
					(if (isDir x)
						(progn
						  (setq incFile "")
						  (foreach fn
								   (setof f
										  (getDirFiles x)
										  (rexMatchp ".+cdl$" f))

								   (sprintf incFile "%s/%s %s" x fn incFile))						
						  )					
					  (setq incFile "")
					  ))
				  (list cdlLink
				   )
				  ))
		) ;; end progn 
	) ;; end if getShellEnvVar
	
	(setq TMPL (outfile env_file "w"))
	(sprintf text
"simLibName = \"%s\"\n
simCellName = \"%s\"\n
simRunDir = \"%s\"\n
hnlNetlistFileName = \"%s\"\n
incFILE = \"%s\"\n
simViewName = \"schematic\"\n
simSimulator = \"auCdl\"\n
simNotIncremental = nil\n
cdsNetlistingMode = \"Analog\"\n
simReNetlistAll = nil\n
simViewList = '(\"auCdl\" \"schematic\")\n
simStopList = '(\"auCdl\")\n
simNetlistHier = t\n
resistorModel = \"\"\n
shortRES = 2000.0\n
preserveRES = 't\n
checkRESVAL = 't\n
checkRESSIZE = 'nil\n
preserveCAP = 't\n
checkCAPVAL = 't\n
checkCAPAREA = 'nil\n
preserveDIO = 't\n
checkDIOAREA = 't\n
checkDIOPERI = 't\n
checkCAPPERI = 'nil\n
simPrintInhConnAttributes = 'nil\n
checkScale = \"meter\"\n
checkLDD = 'nil\n
pinMAP = 't\n
shrinkFACTOR = 0.0\n
globalPowerSig = \"\"\n
globalGndSig = \"vss VSS\"\n
displayPININFO = 't\n
preserveALL = 't\n
setEQUIV = \"\"\n
"

ln cn path fn incFile)
	(fprintf TMPL "%s\n" text)
	(close TMPL)
	t
	)
  )

