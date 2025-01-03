;;
;; (load "pckReleaseConfiguration.il")
;;
(defun pxprimtemplate_1271p2_0p2 ()
  (let (cell_list)
	(setq delete_cell_list
		  (list "b8xdcaiss4zp0" "b8xdcaiss4zp0_metal" "b8xdcaiss4zp0cor" "b8xdcaiss4zp0nptap" "b8xdcaiss4zp0nptap_metal" "b8xdcaiss4zp0side" "b8xdcaiss4zp0topbot" "b8xind1p0n_fill_ind1p0n" "b8xind1p0n_ind_tm1rd" "b8xind1p0n_m8_crossover" "b8xind1p0n_m8_crossover_fillm67" "b8xind1p2n_fill" "b8xind1p2n_tm1rd" "b8xind_crossover_fillm67" "b8xind_m8_crossover" "b8xind_tm1rd" "b8xindfillbm5" "b8xindfillbm8d40" "b8xindfillm6" "b8xindfillm7" "b8xindfillm8" "b8xindfillv5" "b8xindfillv6" "b8xindfillv7" "b8xindm9l1p0n" "b8xindm9l1p0n_fill" "b8xindm9l1p0n_ind_m8rd" "b8xindm9l1p0n_m8_crossover" "b8xindm9l1p0n_m8_crossover_fillm67" "b8xindm9l1p2n" "b8xlsndhphs" "b8xrgcndig4legdac" "b8xrgcndig4legdac_base" "bsxdcan4ctg3ppll" "bsxdcan4ctg3ppll_metal" "bsxdcpisn4zp10pll" "bsxdcpisn4zp10pll_metal" "bsxmfcd10uva4cfio"
 ))
	(setq move_cell_list
		  (list "b8pnpthermaldiode3t" "b8xthm5polyvxx" "b8xthm81trc02_hv" "b8xthm81trh02_hv" "b8xthm81trv02_hv" "b8xthmfillvxx" "b8xthmhalocnvxx" ))

	;;
	;;
	
	
	)
  )

(defun pxesd_1271p2_0p2 (libName @key (label "no") (var_del "no"))
  (let (cell_list status)
	(setq delete_cell_list
		  (list "b8xesdd1d2lc250vertuhvm7" "b8xesdd1lc250vertuhvm7" "b8xesdd1lcvertuhvm7" "b8xesdd2lc250vertuhvm7" "b8xesdd2lcvertuhvm7" "b8xesdvtolclampxllehv" "b8xesdvtolclampxllehvpath" "b8xesdvtolclampxllp25ehv" "b8xesdvtolclampxllp25ehvpath" ))
	(setq label_clean_up_list (list "b8xesdvtolclamp2_v" "b8xesdvtolclamp2" "b81esdvtolclamp2" "b81esdpmosclamp_v" "b81esdpmosclamp_core"  "b81esdpmosclamp" "b81esdvtolclamp2_v"))
	(setq label_delete "The variable a80esdclampcap_var should be set")
	(when (equal label "yes")
	  (pckCleanUpLabels libName label_clean_up_list "symbol" label_delete))
	(when (equal var_del "yes")
	  (setq cell_list (list "b8xesdclampcap" "b8xesdclampcaphv"))
	  (pckEsdRemoveSkewVar libName cell_list "schematic" "*")

	  )
	)
  )



(defun lib_1271p9_0p1 ()
  (let (delete_list rename_list)
	(setq delete_list
		  (list
		   (list "fdk71p9primtemplate"
				 (list "b8xdcaiss4zp0_metal" "b8xdcaiss4zp0cor" "b8xdcaiss4zp0nptap_metal" "b8xdcaiss4zp0side" "b8xdcaiss4zp0topbot" "b8xind1p0n_fill_ind1p0n" "b8xind1p0n_m8_crossover" "b8xind1p0n_m8_crossover_fillm67" "b8xind1p2n_fill" "b8xind_crossover_fillm67" "b8xind_m8_crossover" "b8xindfillbm5" "b8xindfillbm8d40" "b8xindfillm6" "b8xindfillm7" "b8xindfillm8" "b8xindfillv5" "b8xindfillv6" "b8xindfillv7" "b8xindm9l1p0n" "b8xindm9l1p0n_fill" "b8xindm9l1p0n_ind_m8rd" "b8xindm9l1p0n_m8_crossover" "b8xindm9l1p0n_m8_crossover_fillm67" "b8xindm9l1p2n" "b8xlsndhphs" "b8xrgcndig4legdac" "b8xrgcndig4legdac_base" "b8xdcaiss4zp0" "b8xdcaiss4zp0nptap" "bsxdcan4ctg3ppll" "bsxdcan4ctg3ppll_metal" "bsxdcpisn4zp10pll" "bsxdcpisn4zp10pll_metal" "bsxmfcd10uva4cfio" "b8xindfillbm5" "b8xindfillbm8d40" "b8xindfillm6" "b8xindfillm7" "b8xindfillm8" "b8xindfillv5" "b8xindfillv6" "b8xindfillv7" "bsxmfca10uva5" "bsxmfca10uvb5" "bsxmfca10uvc5" "bsxmfcd10uva5" "bsxmfcd10uvb5" "bsxmfcd10uvc5" "bsxdcpisn6zp10" "bsxdcpisn6zp10_cor_in" "bsxdcpisn6zp10_cor_out" "bsxdcpisn6zp10_metal" "bsxdcpisn6zp10_side" "bsxdcpisn6zp10_topbot"
)
				 )
		   (list "fdk71p9esd"
				 (list "b8xesdd1lc250vertuhvm5" "b8xesdd1lc250vertuhvm7" "b8xesdd2lc250vertuhvm5" "b8xesdd2lc250vertuhvm7" "b8xesdd1d2lc250vertuhvm5" "b8xesdd1d2lc250vertuhvm7" "b8xesdd1d2x3uhv" "b8xesdd7x3uhv" "b8xesdvtolclamptg270p5uhv" "b8xesdvtolclamptg270p5uhvcore" "b8xesdvtolclamptg270p5uhvfb" "b8xesdvtolclamptg270p5uhvpath" "b8xesdvtolclamptg270uhvcore" "b8xesdvtolclamptg270uhvfb" "b8xesdvtolclamptg270uhvpath" "b8xesdvtolclamptg270uhv" "b8xesdvtolclampxllehv" "b8xesdvtolclampxllehvpath" "b8xesdvtolclampxllp25ehv" "b8xesdvtolclampxllp25ehvpath" "b8xesdresgcntguhv"
)

				 )
		   )
		  )
	(setq rename_list
		  (list
		   (list "fdk71p9primtemplate"
				 (list "b8xmfca0hva5" "b8xmfca0hvb5" "b8xmfca0hvc5" "b8xmfcd0nva6" "b8xmfcd0nvb6" "b8xmfcd0nvc6" "bsxmfcd10nva6lp")
				 (list "b8ymfca0hva5" "b8ymfca0hvb5" "b8ymfca0hvc5" "b8ymfcd0nva6" "b8ymfcd0nvb6" "b8ymfcd0nvc6" "bsymfcd10nva6lp"))))

	;;
	;; process delete cells
	(pckProcessUnmanagedDeleteList delete_list)
	(pckProcessUnmanagedRenameList rename_list)
	(pckRebindLibCells "fdk71p9esd"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p9/scripts/1271.9_0.2_11ww10_rebind.map")
	(pckRebindLibCells "fdk71p9primtemplate"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p9/scripts/1271.9_0.2_11ww10_rebind.map")
	(pckRebindLibCells "fdk71p9tapeout"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p9/scripts/1271.9_0.2_11ww10_rebind.map")
	;;
	;; need to create holding cellls
	;; then get hierarchy & netlist
	(buildHoldingCell "fdk71p9esd" "pvrott_p9" (strcat "fdk71p9esd_holding_11ww12") "schematic" )
	(buildHoldingCell "fdk71p9esd" "pvrott_p9" (strcat "fdk71p9esd_holding_11ww12") "layout" )
	(buildHoldingCell "fdk71p9primtemplate" "pvrott_p9" (strcat "fdk71p9primtemplate_holding_11ww12") "schematic" )
	(buildHoldingCell "fdk71p9primtemplate" "pvrott_p9" (strcat "fdk71p9primtemplate_holding_11ww12") "layout" )
	(buildHoldingCell "fdk71p9tapeout" "pvrott_p9" (strcat "fdk71p9tapeout_holding_11ww12") "schematic" )
	(buildHoldingCell "fdk71p9tapeout" "pvrott_p9" (strcat "fdk71p9tapeout_holding_11ww12") "layout" )
	;; get hierachy from stream files
	;; notice "." before "*" in library name matching expression
	
	(let ( (status (list )))
	  (foreach lib (list "fdk71p9esd" "fdk71p9primtemplate" "fdk71p9tapeout")
			 (unless (pckCheckLibBindings
					  (list lib)
					  "fdk71p9.*"
					  (list "basic" "analogLib")
					  (list "layout" "schematic")
					  )
			   (setq status (cons lib status)))
			 )
	  (when status
		(pckWarn "lib_1271p9_0p1"
				 (sprintf nil "Following libraries have bindings outside of p9 domain: %L" status))
		)
	  )
	(foreach cell
			(list "fdk71p9esd_holding_11ww12"
				  "fdk71p9primtemplate_holding_11ww12"
				  "fdk71p9tapeout_holding_11ww12")
			;;
			;; need to add status checker
			;;
			(pckMakeStreamFileNew
			 (getShellEnvVar "PDSSTM") "pvrott_p9" cell "layout"
			 (strcat (getShellEnvVar "PDSSTM") "/" cell ".gds"))
			(pckMakeQuickNetlist cell "pvrott_p9"
								 (strcat
								  (getShellEnvVar "FDK_WORK") "/netlists/cdl")
								 (strcat cell ".cdl"))
			)

	)
  )

(defun rebinds_1271p4_0p2 (@key step0 step1 step2 step2a step3 step4 step5)
  (when step0
	(dbCreateLib "fdk71p4dfd" "/p/fdk/gwa/pvrott/fdk71/managed/dev/pck_dev_libs/dot4/oalibs/dfd/2011ww12/fdk71p4dfd")
	(dbCreateLib "fdk71p4esd" "/p/fdk/gwa/pvrott/fdk71/managed/dev/pck_dev_libs/dot4/oalibs/esd/2011ww12/fdk71p4esd")
	(dbCreateLib "fdk71p4primtemplate" "/p/fdk/gwa/pvrott/fdk71/managed/dev/pck_dev_libs/dot4/oalibs/primtemplate/2011ww12/fdk71p4primtemplate")
	(dbCreateLib "fdk71p4tapeout" "/p/fdk/gwa/pvrott/fdk71/managed/dev/pck_dev_libs/dot4/oalibs/tapeout/2011ww12/fdk71p4tapeout")
	
	(techBindTechFile (ddGetObj "fdk71p4dfd") "fdk71p4tech")
	(techBindTechFile (ddGetObj "fdk71p4esd") "fdk71p4tech")
	(techBindTechFile (ddGetObj "fdk71p4primtemplate") "fdk71p4tech")
	(techBindTechFile (ddGetObj "fdk71p4tapeout") "fdk71p4tech")

	)
  (when step1
    (pckCopyPxToDotLibrary (list "fdk71pxesd" "fdk71pxprimtemplate" "fdk71pxtapeout" "fdk71pxdfd" )
						   (list "fdk71p4esd" "fdk71p4primtemplate" "fdk71p4tapeout" "fdk71p4dfd" )))

  

  
  (when step2 
	(pckRebindLibCells "fdk71p4esd"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p4/1271.4_11ww14_rebind.map")
	(pckRebindLibCells "fdk71p4primtemplate"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p4/1271.4_11ww14_rebind.map")
	(pckRebindLibCells "fdk71p4tapeout"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p4/1271.4_11ww14_rebind.map")
	(pckRebindLibCells "fdk71p4dfd"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p4/1271.4_11ww14_rebind.map"))

  (when step2a 
	(pckRebindLibCells "fdk71p4esd"
					   (list "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p4/1271.4_11ww14_rebind.map")
	(pckRebindLibCells "fdk71p4primtemplate"
					   (list "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p4/1271.4_11ww14_rebind.map")
	(pckRebindLibCells "fdk71p4tapeout"
					   (list "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p4/1271.4_11ww14_rebind.map")
	(pckRebindLibCells "fdk71p4dfd"
					   (list "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p4/1271.4_11ww14_rebind.map"))
  
  (when step3 
	  (pckCheckLibBindings (list "fdk71p4esd") "fdk71p4.*" (list "basic" "analogLib") (list "layout" "schematic"))
	  (pckCheckLibBindings (list "fdk71p4primtemplate") "fdk71p4.*" (list "basic" "analogLib") (list "layout" "schematic"))
	  (pckCheckLibBindings (list "fdk71p4tapeout") "fdk71p4.*" (list "basic" "analogLib") (list "layout" "schematic"))   
	  (pckCheckLibBindings (list "fdk71p4sram") "fdk71p4.*" (list "basic" "analogLib") (list "layout" "schematic"))   
	  (pckCheckLibBindings (list "fdk71p4dfd") "fdk71p4.*" (list "basic" "analogLib") (list "layout" "schematic")))   
  
  (when step4
	(buildHoldingCell "fdk71p4dfd" "pvrott_p4" (strcat "fdk71p4dfd_holding_11ww12") "schematic" )
	(buildHoldingCell "fdk71p4dfd" "pvrott_p4" (strcat "fdk71p4dfd_holding_11ww12") "layout" )
	(buildHoldingCell "fdk71p4esd" "pvrott_p4" (strcat "fdk71p4esd_holding_11ww12") "schematic" )
	(buildHoldingCell "fdk71p4esd" "pvrott_p4" (strcat "fdk71p4esd_holding_11ww12") "layout" )
	(buildHoldingCell "fdk71p4primtemplate" "pvrott_p4" (strcat "fdk71p4primtemplate_holding_11ww12") "schematic" )
	(buildHoldingCell "fdk71p4primtemplate" "pvrott_p4" (strcat "fdk71p4primtemplate_holding_11ww12") "layout" )
	(buildHoldingCell "fdk71p4tapeout" "pvrott_p4" (strcat "fdk71p4tapeout_holding_11ww12") "schematic" )
	(buildHoldingCell "fdk71p4tapeout" "pvrott_p4" (strcat "fdk71p4tapeout_holding_11ww12") "layout" )
	(buildHoldingCell "fdk71p4sram" "pvrott_p4" (strcat "fdk71p4sram_holding_11ww12") "schematic" )
	(buildHoldingCell "fdk71p4sram" "pvrott_p4" (strcat "fdk71p4sram_holding_11ww12") "layout" ))
  (when step5
	(foreach cell
			(list "fdk71p4esd_holding_11ww12"
				  "fdk71p4primtemplate_holding_11ww12"
				  "fdk71p4tapeout_holding_11ww12"
				  "fdk71p4sram_holding_11ww12"
				  )
			;;
			;; need to add status checker
			;;
			(pckMakeStreamFileNew
			 (getShellEnvVar "PDSSTM") "pvrott_p4" cell "layout"
			 (strcat (getShellEnvVar "PDSSTM") "/" cell ".gds"))
			(pckMakeQuickNetlist cell "pvrott_p4"
								 (strcat
								  (getShellEnvVar "FDK_WORK") "/netlists/cdl")
								 (strcat cell ".cdl"))
			)


	)
  )

(defun rebinds_1271p2_1p0 (@key step0 step1 step2 step_prune step_tapeout_prune step_tapeout_copy step2a step3 step3a step4 step5)
  (when step0
	(dbCreateLib "fdk71p2dfd" "/p/fdk/gwa/pvrott/fdk71/managed/dev/pck_dev_libs/dot2/oalibs/dfd/11ww12/fdk71p2dfd")
	(dbCreateLib "fdk71p2esd" "/p/fdk/gwa/pvrott/fdk71/managed/dev/pck_dev_libs/dot2/oalibs/esd/11ww12/fdk71p2esd")
	(dbCreateLib "fdk71p2primtemplate" "/p/fdk/gwa/pvrott/fdk71/managed/dev/pck_dev_libs/dot2/oalibs/primtemplate/11ww12/fdk71p2primtemplate")
	(dbCreateLib "fdk71p2tapeout" "/p/fdk/gwa/pvrott/fdk71/managed/dev/pck_dev_libs/dot2/oalibs/tapeout/11ww12/fdk71p2tapeout")
	
	(techBindTechFile (ddGetObj "fdk71p2dfd") "fdk71p2tech")
	(techBindTechFile (ddGetObj "fdk71p2esd") "fdk71p2tech")
	(techBindTechFile (ddGetObj "fdk71p2primtemplate") "fdk71p2tech")
	(techBindTechFile (ddGetObj "fdk71p2tapeout") "fdk71p2tech")

	)
  (when step1
    (pckCopyPxToDotLibrary (list "fdk71pxesd" "fdk71pxprimtemplate" "fdk71pxtapeout" "fdk71pxdfd" )
						   (list "fdk71p2esd" "fdk71p2primtemplate" "fdk71p2tapeout" "fdk71p2dfd" )))
  (when step2 
	(pckRebindLibCells "fdk71p2esd"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p2/1271.2_11ww18_rebind.map")
	(pckRebindLibCells "fdk71p2primtemplate"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p2/1271.2_11ww18_rebind.map")
	(pckRebindLibCells "fdk71p2tapeout"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p2/1271.2_11ww18_rebind.map")
	(pckRebindLibCells "fdk71p2dfd"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p2/1271.2_11ww18_rebind.map"))

  (when step2a 
	(pckRebindLibCells "fdk71p2esd"
					   (list "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p2/1271.2_11ww18_rebind.map")
	(pckRebindLibCells "fdk71p2primtemplate"
					   (list "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p2/1271.2_11ww18_rebind.map")
	(pckRebindLibCells "fdk71p2tapeout"
					   (list "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p2/1271.2_11ww18_rebind.map")
	(pckRebindLibCells "fdk71p2dfd"
					   (list "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p2/1271.2_11ww18_rebind.map"))

  (when step_prune
	;;
	;; here we can delete unwanted cells and clean up labels with errorneous information (e.g. in ESD)
	(setq delete_cell_list
		  (list
		   (list "fdk71p2esd"
				 (list "b8xesdd1d2lc250vertuhvm7" "b8xesdd1lc250vertuhvm7" "b8xesdd1lcvertuhvm7" "b8xesdd2lc250vertuhvm7" "b8xesdd2lcvertuhvm7" "b84esdvtolclampxllehv" "b84esdvtolclampxllehvpath" "b84esdvtolclampxllp25ehv" "b84esdvtolclampxllp25ehvpath" ))))
	(setq label_clean_up_list (list "b8xesdvtolclamp2_v" "b8xesdvtolclamp2" "b81esdvtolclamp2" "b81esdpmosclamp_v" "b81esdpmosclamp_core"  "b81esdpmosclamp" "b81esdvtolclamp2_v"))
	(setq label_delete "The variable a80esdclampcap_var should be set")
	;;(pckCleanUpLabels "fdk71p2esd" label_clean_up_list "symbol" label_delete)
	(pckProcessUnmanagedDeleteList delete_cell_list)
	)
  (when step_tapeout_prune
	(setq delete_cell_list
		  (list
		   (list "fdk71p2tapeout"
				 (list "b8xtochn1271crnx0" "b8xtochn1271ogdfillx0" "b8xtochn1271ogdgapx0" "b8xtochn1271ogdiox0" "b8xtochn1271ogdmimx0" "b8xtochn1271pgdfillx0" "b8xtochn1271pgdgapx0" "b8xtochn1271pgdiox0" "b8xtochn1271pgdm8sx0" "b8xtochn1271pgdm8x0" "b8xtochn1271pgdmbesx0" "b8xtochn1271pgdmbex0" "b8xtochn1271pgdmimx0" "b8xtochn1271pgdmt8x0" "b8xtochn1271pgdmtesx0" "b8xtochn1271pgdmtex0" "b8xtodic_isodic" "b8xtoedm1271crnx0" "b8xtoedm1271ogdfillx0" "b8xtoedm1271ogdiox0" "b8xtoedm1271ogdx0" "b8xtoedm1271pgdfillx0" "b8xtoedm1271pgdiox0" "b8xtoedm1271pgdx0" "b8xtoer1271crnx0" "b8xtoer1271ogdx0" "b8xtoer1271ogdx10" "b8xtoer1271ogdx100" "b8xtoer1271ogdx1000" "b8xtoer1271pgdx0" "b8xtoer1271pgdx10" "b8xtoer1271pgdx100" "b8xtoer1271pgdx1000" "b8xtoprs_bxxdnn00nnz02" "b8xtoprs_bxxdnn00nnz05" "b8xtoprs_bxxdnn00nnz08" "b8xtoprs_bxxdnn00nnz16" "b8xtoprs_dic_cont" "b8xtoprs_halolr" "b8xtoprs_halolr_cont" "b8xtoprs_halolr_mfill" "b8xtoprs_halotb" "b8xtoprs_halotb_mfill" "b8xtoprs_i_small" "b8xtoprs_i_small_cont" "b8xtoprs_i_small_m7fill" "b8xtoprs_i_small_marks" "b8xtoprs_i_small_mfill" "b8xtoprs_iso_metalfill" "b8xtoprs_iso_mfill" "b8xtoprs_m7_cont" "b8xtoprs_m7_mfill" "b8xtoprs_metalfill" "b8xtoprs_metalfill_cont" "b8xtoprs_metalfill_mfill" "b8xtoprs_metro_marks" "b8xtoprs_nest_metalfill" "b8xtoprs_tm1_tv1ft" "b8xtoprs_tm1met" "b8xtoprs_tm1met_cont" "b8xtoprs_tm1met_mfill" "b8xtoprs_topfill" "b8xtoprs_tv1ft" "b8xtoprs_tv1ft_cont" "b8xtoprs_tv1ft_mfill" "b8xtoprs_y_small" "b8xtoprs_y_small_cont" "b8xtoprs_y_small_m7fill" "b8xtoprs_y_small_marks" "b8xtoprs_y_small_mfill" "b8libp0_chn_ogdio_minix0" "b8libp0_chn_pgdio_minix0" "b8libp0_edm_ogdio_minix0" "b8libp0_edm_pgdio_minix0" "b8libp0_er_minix0" "b8libp0_eredmchn_ogdio_minix0" "b8libp0_eredmchn_pgdio_minix0" "b8xtodbz1270crnx0" "b8xtodbz1270minix1" "b8xtodbz1270ogdx0" "b8xtodbz1270pgdx0"))))
	(pckProcessUnmanagedDeleteList delete_cell_list)

	)
  (when step_tapeout_copy
	(setq copy_list
		  (list
		   (list "localp2tapeout" "fdk71p2tapeout"
				 (list "b82tochn1271crnx0" "b82tochn1271ogdfillx0" "b82tochn1271ogdgapx0" "b82tochn1271ogdiox0" "b82tochn1271ogdmimx0" "b82tochn1271pgdfillx0" "b82tochn1271pgdgapx0" "b82tochn1271pgdiox0" "b82tochn1271pgdm8sx0" "b82tochn1271pgdm8x0" "b82tochn1271pgdmbesx0" "b82tochn1271pgdmbex0" "b82tochn1271pgdmimx0" "b82tochn1271pgdmt8x0" "b82tochn1271pgdmtesx0" "b82tochn1271pgdmtex0" "b82todic_isodic" "b82toedm1271crnx0" "b82toedm1271ogdfillx0" "b82toedm1271ogdiox0" "b82toedm1271ogdx0" "b82toedm1271pgdfillx0" "b82toedm1271pgdiox0" "b82toedm1271pgdx0" "b82toer1271crnx0" "b82toer1271ogdx0" "b82toer1271ogdx10" "b82toer1271ogdx100" "b82toer1271ogdx1000" "b82toer1271pgdx0" "b82toer1271pgdx10" "b82toer1271pgdx100" "b82toer1271pgdx1000" "b82toprs_bxxdnn00nnz02" "b82toprs_bxxdnn00nnz05" "b82toprs_bxxdnn00nnz08" "b82toprs_bxxdnn00nnz16" "b82toprs_dic_cont" "b82toprs_halolr" "b82toprs_halolr_cont" "b82toprs_halolr_mfill" "b82toprs_halotb" "b82toprs_halotb_mfill" "b82toprs_i_small" "b82toprs_i_small_cont" "b82toprs_i_small_m7fill" "b82toprs_i_small_marks" "b82toprs_i_small_mfill" "b82toprs_iso_metalfill" "b82toprs_iso_mfill" "b82toprs_m7_cont" "b82toprs_m7_mfill" "b82toprs_metalfill" "b82toprs_metalfill_cont" "b82toprs_metalfill_mfill" "b82toprs_metro_marks" "b82toprs_nest_metalfill" "b82toprs_tm1_tv1ft" "b82toprs_tm1met" "b82toprs_tm1met_cont" "b82toprs_tm1met_mfill" "b82toprs_topfill" "b82toprs_tv1ft" "b82toprs_tv1ft_cont" "b82toprs_tv1ft_mfill" "b82toprs_y_small" "b82toprs_y_small_cont" "b82toprs_y_small_m7fill" "b82toprs_y_small_marks" "b82toprs_y_small_mfill" "b8libp2_chn_ogdio_minix0" "b8libp2_chn_pgdio_minix0" "b8libp2_edm_ogdio_minix0" "b8libp2_edm_pgdio_minix0" "b8libp2_er_minix0" "b8libp2_eredmchn_ogdio_minix0" "b8libp2_eredmchn_pgdio_minix0" "b8xtodbz1271crnx0" "b8xtodbz1271minix1" "b8xtodbz1271ogdx0" "b8xtodbz1271pgdx0"))))
	(pckProcessUnmanagedCopyList copy_list)
	)
  
  (when step3 
	  (pckCheckLibBindings (list "fdk71p2esd") "fdk71p2.*" (list "basic" "analogLib") (list "layout" "schematic"))
	  (pckCheckLibBindings (list "fdk71p2primtemplate") "fdk71p2.*" (list "basic" "analogLib") (list "layout" "schematic"))
	  (pckCheckLibBindings (list "fdk71p2tapeout") "fdk71p2.*" (list "basic" "analogLib") (list "layout" "schematic"))   
	  (pckCheckLibBindings (list "fdk71p2sram") "fdk71p2.*" (list "basic" "analogLib") (list "layout" "schematic"))   
	  (pckCheckLibBindings (list "fdk71p2dfd") "fdk71p2.*" (list "basic" "analogLib") (list "layout" "schematic")))   

  (when step3a
	(foreach lib (list "fdk71p2esd" "fdk71p2primtemplate" "fdk71p2tapeout" "fdk71p2sram" "fdk71p2dfd")
			 (pckCheckAndSaveSchLib lib))


	)
  
  (when step4
	(buildHoldingCell "fdk71p2dfd" "pvrott_p2" (strcat "fdk71p2dfd_holding_11ww18") "schematic" )
	(buildHoldingCell "fdk71p2dfd" "pvrott_p2" (strcat "fdk71p2dfd_holding_11ww18") "layout" )
	(buildHoldingCell "fdk71p2esd" "pvrott_p2" (strcat "fdk71p2esd_holding_11ww18") "schematic" )
	(buildHoldingCell "fdk71p2esd" "pvrott_p2" (strcat "fdk71p2esd_holding_11ww18") "layout" )
	(buildHoldingCell "fdk71p2primtemplate" "pvrott_p2" (strcat "fdk71p2primtemplate_holding_11ww18") "schematic" )
	(buildHoldingCell "fdk71p2primtemplate" "pvrott_p2" (strcat "fdk71p2primtemplate_holding_11ww18") "layout" )
	(buildHoldingCell "fdk71p2tapeout" "pvrott_p2" (strcat "fdk71p2tapeout_holding_11ww18") "schematic" )
	(buildHoldingCell "fdk71p2tapeout" "pvrott_p2" (strcat "fdk71p2tapeout_holding_11ww18") "layout" )
	(buildHoldingCell "fdk71p2sram" "pvrott_p2" (strcat "fdk71p2sram_holding_11ww18") "schematic" )
	(buildHoldingCell "fdk71p2sram" "pvrott_p2" (strcat "fdk71p2sram_holding_11ww18") "layout" ))
  (when step5
	(foreach cell
			(list "fdk71p2esd_holding_11ww18"
				  "fdk71p2primtemplate_holding_11ww18"
				  "fdk71p2tapeout_holding_11ww18"
				  "fdk71p2sram_holding_11ww18"
				  )
			;;
			;; need to add status checker
			;;
			(pckMakeStreamFileNew
			 (getShellEnvVar "PDSSTM") "pvrott_p2" cell "layout"
			 (strcat (getShellEnvVar "PDSSTM") "/" cell ".gds"))
			(pckMakeQuickNetlist cell "pvrott_p2"
								 (strcat
								  (getShellEnvVar "FDK_WORK") "/netlists/cdl")
								 (strcat cell ".cdl"))
			)


	)
  (when step6
	(pckCheckInLibrary (list "fdk71p2dfd" "fdk71p2esd" "fdk71p2primtemplate" "fdk71p2tapeout"))
	)
  
  )
;;
;;
;; First ever dot6 release basedon 1271.9_0.1 release. That 1271.9 release was itself based on 11ww08 b8lib release

(defun rebinds_1271p6_0p0 (@key step0 step1 step2 step_prune step2a step3 step4 step5 step6 stepA)
  (when stepA
	(unless (ddgetObj "fdk71p6qatb")
	  (dbCreateLib "fdk71p6qatb" "/p/fdk/gwa/pvrott/fdk71/managed/dev/pck_dev_libs/dot6/oalibs/qatb/fdk71p6qatb"))
	(techBindTechFile (ddGetObj "fdk71p6qatb") "fdk71p6tech")
	(pckCopyPxToDotLibrary (list "fdk71p9qatb")
						   (list "fdk71p6qatb"))
	(pckRebindLibCells "fdk71p6qatb"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p6/1271.6_11ww18_rebind.map")
	(pckCheckLibBindings
	 (list "fdk71p6qatb") "fdk71p6.*" (list "basic" "analogLib") (list "layout" "schematic"))
	(pckCheckInLibrary (list "fdk71p6qatb"))
	)


  (when step0
	(dbCreateLib "fdk71p6dfd" "/p/fdk/gwa/pvrott/fdk71/managed/dev/pck_dev_libs/dot6/oalibs/dfd/11ww08/fdk71p6dfd")
	(dbCreateLib "fdk71p6esd" "/p/fdk/gwa/pvrott/fdk71/managed/dev/pck_dev_libs/dot6/oalibs/esd/11ww08/fdk71p6esd")
	(dbCreateLib "fdk71p6primtemplate" "/p/fdk/gwa/pvrott/fdk71/managed/dev/pck_dev_libs/dot6/oalibs/primtemplate/11ww08/fdk71p6primtemplate")
	(dbCreateLib "fdk71p6tapeout" "/p/fdk/gwa/pvrott/fdk71/managed/dev/pck_dev_libs/dot6/oalibs/tapeout/11ww08/fdk71p6tapeout")
	
	(techBindTechFile (ddGetObj "fdk71p6dfd") "fdk71p6tech")
	(techBindTechFile (ddGetObj "fdk71p6esd") "fdk71p6tech")
	(techBindTechFile (ddGetObj "fdk71p6primtemplate") "fdk71p6tech")
	(techBindTechFile (ddGetObj "fdk71p6tapeout") "fdk71p6tech")

	)

  
  (when step1
    (pckCopyPxToDotLibrary (list "fdk71p9esd" "fdk71p9primtemplate" "fdk71p9tapeout" "fdk71p9dfd" )
						   (list "fdk71p6esd" "fdk71p6primtemplate" "fdk71p6tapeout" "fdk71p6dfd" )))
  (when step2 
	(pckRebindLibCells "fdk71p6esd"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p6/1271.6_11ww18_rebind.map")
	(pckRebindLibCells "fdk71p6primtemplate"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p6/1271.6_11ww18_rebind.map")
	(pckRebindLibCells "fdk71p6tapeout"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p6/1271.6_11ww18_rebind.map")
	(pckRebindLibCells "fdk71p6dfd"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p6/1271.6_11ww18_rebind.map"))

  (when step2a 
	(pckRebindLibCells "fdk71p6esd"
					   (list "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p6/1271.6_11ww18_rebind.map")
	(pckRebindLibCells "fdk71p6primtemplate"
					   (list "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p6/1271.6_11ww18_rebind.map")
	(pckRebindLibCells "fdk71p6tapeout"
					   (list "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p6/1271.6_11ww18_rebind.map")
	(pckRebindLibCells "fdk71p6dfd"
					   (list "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p6/1271.6_11ww18_rebind.map"))

  (when step_prune
	;;
	;; here we can delete unwanted cells and clean up labels with errorneous information (e.g. in ESD)
	(setq delete_cell_list
		  (list
		   (list "fdk71p6esd"
				 (list "b8xesdd1d2lc250vertuhvm7" "b8xesdd1lc250vertuhvm7" "b8xesdd1lcvertuhvm7" "b8xesdd2lc250vertuhvm7" "b8xesdd2lcvertuhvm7" "b84esdvtolclampxllehv" "b84esdvtolclampxllehvpath" "b84esdvtolclampxllp25ehv" "b84esdvtolclampxllp25ehvpath" ))))
	(setq label_clean_up_list (list "b8xesdvtolclamp2_v" "b8xesdvtolclamp2" "b81esdvtolclamp2" "b81esdpmosclamp_v" "b81esdpmosclamp_core"  "b81esdpmosclamp" "b81esdvtolclamp2_v"))
	(setq label_delete "The variable a80esdclampcap_var should be set")
	;;(pckCleanUpLabels "fdk71p2esd" label_clean_up_list "symbol" label_delete)
	(pckProcessUnmanagedDeleteList delete_cell_list)
	)

  
  (when step3 
	  (pckCheckLibBindings (list "fdk71p6esd") "fdk71p6.*" (list "basic" "analogLib") (list "layout" "schematic"))
	  (pckCheckLibBindings (list "fdk71p6primtemplate") "fdk71p6.*" (list "basic" "analogLib") (list "layout" "schematic"))
	  (pckCheckLibBindings (list "fdk71p6tapeout") "fdk71p6.*" (list "basic" "analogLib") (list "layout" "schematic"))   
	  ;;(pckCheckLibBindings (list "fdk71p6sram") "fdk71p6.*" (list "basic" "analogLib") (list "layout" "schematic"))   
	  (pckCheckLibBindings (list "fdk71p6dfd") "fdk71p6.*" (list "basic" "analogLib") (list "layout" "schematic")))   
  
  (when step4
	;; (buildHoldingCell "fdk71p6dfd" "pvrott_p6" (strcat "fdk71p6dfd_holding_11ww18") "schematic" )
	;; (buildHoldingCell "fdk71p6dfd" "pvrott_p6" (strcat "fdk71p6dfd_holding_11ww18") "layout" )
	(buildHoldingCell "fdk71p6esd" "pvrott_p6" (strcat "fdk71p6esd_holding_11ww18") "schematic" )
	(buildHoldingCell "fdk71p6esd" "pvrott_p6" (strcat "fdk71p6esd_holding_11ww18") "layout" )
	(buildHoldingCell "fdk71p6primtemplate" "pvrott_p6" (strcat "fdk71p6primtemplate_holding_11ww18") "schematic" )
	(buildHoldingCell "fdk71p6primtemplate" "pvrott_p6" (strcat "fdk71p6primtemplate_holding_11ww18") "layout" )
	(buildHoldingCell "fdk71p6tapeout" "pvrott_p6" (strcat "fdk71p6tapeout_holding_11ww18") "schematic" )
	(buildHoldingCell "fdk71p6tapeout" "pvrott_p6" (strcat "fdk71p6tapeout_holding_11ww18") "layout" )
	;; (buildHoldingCell "fdk71p6sram" "pvrott_p6" (strcat "fdk71p6sram_holding_11ww18") "schematic" )
	;; (buildHoldingCell "fdk71p6sram" "pvrott_p6" (strcat "fdk71p6sram_holding_11ww18") "layout" )
	)
  (when step5
	(foreach cell
			(list "fdk71p6esd_holding_11ww18"
				  "fdk71p6primtemplate_holding_11ww18"
				  "fdk71p6tapeout_holding_11ww18"
				  ;;"fdk71p6sram_holding_11ww18"
				  )
			;;
			;; need to add status checker
			;;
			(pckMakeStreamFileNew
			 (getShellEnvVar "PDSSTM") "pvrott_p6" cell "layout"
			 (strcat (getShellEnvVar "PDSSTM") "/" cell ".gds"))
			(pckMakeQuickNetlist cell "pvrott_p6"
								 (strcat
								  (getShellEnvVar "FDK_WORK") "/netlists/cdl")
								 (strcat cell ".cdl"))
			)


	)
  (when step6
	(pckCheckInLibrary (list "fdk71p6esd" "fdk71p6primtemplate" "fdk71p6tapeout" "fdk71p6qatb"))
	)
  )

(defun rebinds_1271p9_0p1 ()
  	(pckRebindLibCells "fdk71p9esd"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p9/scripts/1271.9_0.2_11ww10_rebind.map")
	(pckRebindLibCells "fdk71p9primtemplate"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p9/scripts/1271.9_0.2_11ww10_rebind.map")
	(pckRebindLibCells "fdk71p9tapeout"
					   (list "layout" "schematic")
					   "/p/fdk/gwa/pvrott/fdk71/work/p9/scripts/1271.9_0.2_11ww10_rebind.map")
	;;
	;; need to create holding cellls
	;; then get hierarchy & netlist
	(buildHoldingCell "fdk71p9esd" "pvrott_p9" (strcat "fdk71p9esd_holding_11ww12") "schematic" )
	(buildHoldingCell "fdk71p9esd" "pvrott_p9" (strcat "fdk71p9esd_holding_11ww12") "layout" )
	(buildHoldingCell "fdk71p9primtemplate" "pvrott_p9" (strcat "fdk71p9primtemplate_holding_11ww12") "schematic" )
	(buildHoldingCell "fdk71p9primtemplate" "pvrott_p9" (strcat "fdk71p9primtemplate_holding_11ww12") "layout" )
	(buildHoldingCell "fdk71p9tapeout" "pvrott_p9" (strcat "fdk71p9tapeout_holding_11ww12") "schematic" )
	(buildHoldingCell "fdk71p9tapeout" "pvrott_p9" (strcat "fdk71p9tapeout_holding_11ww12") "layout" )
	;;
	;; get hierachy from stream files
	;; notice "." before "*" in library name matching expression
	(pckCheckLibBindings (list "fdk71p9esd") "fdk71p9.*" (list "basic" "analogLib") (list "layout" "schematic"))
	(pckCheckLibBindings (list "fdk71p9primtemplate") "fdk71p9.*" (list "basic" "analogLib") (list "layout" "schematic"))
	(pckCheckLibBindings (list "fdk71p9tapeout") "fdk71p9.*" (list "basic" "analogLib") (list "layout" "schematic"))
	(foreach cell
			(list "fdk71p9esd_holding_11ww12"
				  "fdk71p9primtemplate_holding_11ww12"
				  "fdk71p9tapeout_holding_11ww12")
			;;
			;; need to add status checker
			;;
			(pckMakeStreamFileNew
			 (getShellEnvVar "PDSSTM") "pvrott_p9" cell "layout"
			 (strcat (getShellEnvVar "PDSSTM") "/" cell ".gds"))
			(pckMakeQuickNetlist cell "pvrott_p9"
								 (strcat
								  (getShellEnvVar "FDK_WORK") "/netlists/cdl")
								 (strcat cell ".cdl"))
			)
  )




(defun pckCheckLibBindings (lib_list  wanted_binding ignore_list viewname)
  (let (cv problem_cell)
	(when (atom viewname)
	  (setq viewname (list viewname)))
	(foreach lib lib_list
			 (foreach cell (dbGetq (dbGetq (ddGetObj lib) "cells") "name")
					  (pckInfo "pckCheckLibBindings"
							   (sprintf nil "Processing cell %s %s. Available views - %L"
										lib cell (dbAllCellViews (ddGetObj lib) cell)))					
					  (foreach view viewname
							   (when (member view (dbAllCellViews (ddGetObj lib) cell))
								 (pckInfo "pckCheckLibBindings"
										  (sprintf nil "Opening %s %s %s" lib cell view))
								 (setq cv (dbOpenCellViewByType lib cell view))
								 (setq header_lib_list
									   (dbGetq
										(dbGetq cv "instHeaders")
										"libName"
										))
								 (when header_lib_list 
								   (pckInfo "pckCheckLibBindings" (sprintf nil "header libs: %L" header_lib_list))
								   (setq unwanted_lib
										 (setof lib header_lib_list
												(and
												 (not
												  (rexMatchp wanted_binding lib))
												 (not (member lib ignore_list )))))
								   (when unwanted_lib
									 (pckWarn "pckCheckLibBindings"
											  (sprintf nil "Cellview %s %s %s has binding to %L\n"
													   lib cell view unwanted_lib
													   ))
									 (setq problem_cell
										   (cons
											(list
											 (list lib cell view) unwanted_lib) problem_cell))
									 ))
								 (dbClose cv)
								 )
							   )
					  )
			 )
	problem_cell
	)
  )



(defun pckProcessUnmanagedDeleteList (delete_list)
  "Delete unmanaged cells from list of libraries. Data must be in the form (list (list lib_name (list cells_to_be_removed)) ...)"
  (foreach lib delete_list
		   (setq lib_name (car lib))
		   (fprintf stdout "--I-- Processing library %s\n" lib_name)
		   (foreach cell_name (cadr lib)
					(fprintf stdout "--I-- Processing %s\n" cell_name)
					(if (setq dd_obj (ddGetObj lib_name cell_name))
						(progn
						  (fprintf stdout "--I-- Deleting cell %s from %s." cell_name lib_name)
						  (ddDeleteObj dd_obj)
						  )
					  (progn
						(fprintf stdout "--W-- Cell  %s from %s is on delete list but is missing in library." cell_name lib_name))))
			 )

  )

(defun pckCopyPxToDotLibrary (source_list target_list)
  "Copies source libraries to target libraries"
  (let (source_gdm target_gdm source_lib target_lib)
	;;(fprintf stdout "--D-- %L %L\n" source_list target_list)
	(cond
	 ((equal (car source_list) nil)
	  (fprintf stdout "--I-- source library list is empty. Operation completed.\n"))
	 ((nequal (length source_list) (length target_list))
	  (fprintf stdout "--E-- Source and target library lists have different lengths. Operation aborted.\n"))
	 ((setq source_lib (ddGetObj (car source_list))) ;; library exists
	  (fprintf stdout "--I-- Processing library %s..." (car source_list))
	  (if (setq target_lib (ddGetObj (car target_list)))
		  (fprintf stdout " target lib: %s\n" (car target_list))
		(fprintf stdout "\n--E-- Target lib: %s does not exist. Operation aborted.\n" (car target_list)))

	  (setq source_gdm (gdmCreateSpecList))
	  (setq target_gdm  (gdmCreateSpecList))
	  (gdmAddSpecToSpecList (gdmCreateSpecFromDDID (ddGetObj (car source_list))) source_gdm)	  
	  (gdmAddSpecToSpecList (gdmCreateSpecFromDDID (ddGetObj (car target_list))) target_gdm)
	  (fprintf stdout "--D-- %L %L\n" source_gdm target_gdm)
	  (while (setq nextSpec (gdmNextFromSpecList source_gdm)) 
			 (println (gdmInspectSpec nextSpec "CDBA")))
	  
	  (while (setq nextSpec (gdmNextFromSpecList target_gdm)) 
		(println (gdmInspectSpec nextSpec "CDBA")))
	  
	  
	  (ccpCopy source_gdm target_gdm  t 'CCP_EXPAND_ALL nil nil "" "CDBA" 'CCP_UPDATE_DESTLIB_ONLY)
	  
	  (pckCopyPxToDotLibrary (cdr source_list) (cdr target_list))
	  )))
  )



(defun pckProcessUnmanagedRenameList (rename_list)
  "Renames cells in a library. Uses list with contruction: (list (list lib_name (list cells_to_be_renamed) (list cells_new_names)) ...)"
  (let (cell_name target_cell_name target_gdm target_gdm lib lib_name)	
	(foreach lib rename_list
			 (setq lib_name (car lib))
			 (fprintf stdout "--I-- Processing library %s\n" lib_name)
			 (for i 0 (sub1 (length (cadr lib)))
				  (setq cell_name (nth i (cadr lib)))
				  (setq target_cell_name (nth i (caddr lib))) ;; second list
				  ;; create gdm source spec
				  (setq source_gdm (gdmCreateSpec lib_name cell_name "" "" "CDBA"))
				  (setq target_gdm (gdmCreateSpec lib_name target_cell_name "" "" "CDBA"))
					  
				  (if (and (ddGetObj lib_name cell_name) source_gdm)
					  (progn
						(fprintf stdout "--I-- Renaming cell %s to  %s.\n" cell_name target_cell_name)
						(ccpRename source_gdm target_gdm)
						)
					(progn
					  (fprintf stdout "--W-- GDM object for cell %s in %s could not be created. Rename failed.\n" cell_name lib_name))))
			 ))
  

  )
(defun pckProcessUnmanagedCopyList (copy_list)
  "Copies cells from source to target library. Uses list with contruction: (list (list source_lib target_lib (list cells_to_be_copied)))"
  (let (cell_name target_cell_name target_gdm target_gdm lib lib_name)	
	(foreach lib copy_list
			 (setq source_lib (car lib))
			 (setq target_lib (cadr lib))
			 (fprintf stdout "--I-- Processing source library %s\n" source_lib)
			 (fprintf stdout "--I-- Processing target library %s\n" target_lib)
			 (fprintf stdout "--I-- Processing cells %L\n" (caddr lib))
			 (foreach cell (caddr lib)
					  (setq source_gdm (gdmCreateSpecList))
					  (setq target_gdm  (gdmCreateSpecList))
					  (gdmAddSpecToSpecList (gdmCreateSpec source_lib cell "" "" "CDBA")  source_gdm)	  
					  (gdmAddSpecToSpecList (gdmCreateSpec target_lib cell "" "" "CDBA") target_gdm)
					  
					  (if (and (ddGetObj source_lib cell) source_gdm)
					  (progn
						(fprintf stdout "--I-- Copying cell %s from %s to  %s.\n" cell source_lib target_lib)
						(ccpCopy source_gdm target_gdm t 'CCP_EXPAND_ALL nil nil "" "CDBA" 'CCP_UPDATE_DESTLIB_ONLY)
						)
					(progn
					  (fprintf stdout "--W-- GDM object for cell %s in %s could not be created. Copy failed.\n" cell target_lib))))
			 ))  
  )

(defun pckDeleteCellViewUnderVC (lib cell)
  "Removes tags and deletes/retires cell from the library."
  ;; untag then delete
  (dssTagCellP lib cell ?remove t ?background t )
  (dssDeleteCellP lib cell ?force t ?retire t ?background t)  
  )

(defun pckCleanUpLabels (lib cell_list view  label)
  "Removes labels and text from cells with a particular text"
  (let (cv)
	(foreach cell cell_list
			 (when (member view (dbAllCellViews (ddGetObj lib) cell))
			   (fprintf stdout "-D- Library: %s Cell: %s View: %s\n" lib cell view)
			   
			   (when (pckCheckOutAndLock lib cell view)
				 (setq cv
					   (dbOpenCellViewByType lib cell view "" "a"))
				 (foreach obj (setof x cv~>shapes (or  (equal x~>objType "label")  (equal x~>objType "textDisplay")))
						  (case obj~>objType
							("label"
							 (when (rexMatchp label obj~>theLabel)
							   (fprintf stdout "Removing label %L\n" obj~>theLabel)
							   (dbDeleteObject obj))
							 )
							("textLabel" (fprintf pOut "%s:%L\n" obj~>objType obj~>text)
							 (when (rexMatchp label obj~>text)
							   (fprintf stdout "Removing label %L\n" obj~>text)
							   (dbDeleteObject obj))
							 )
							))
				 (dbSave cv)
				 (dbClose cv))
			   )
			 )
	)
  )

(defun pckCheckAndSaveSchLib (lib)
  "Checks and saves all schematic cells in library"
  (let ((view "schematic"))
	(foreach cell (dbGetq (dbGetq (ddGetObj lib) "cells") "name")
			 (when (member view (dbAllCellViews (ddGetObj lib) cell))
			   (fprintf stdout "-D- Library: %s Cell: %s View: %s\n" lib cell view)			   
			   (when (setq cv (dbOpenCellViewByType lib cell view "" "a"))
				 (schCheck cv)
				 (dbSave cv)
				 (dbClose cv))
			   )
			 ))
  )


(defun pckCheckOutAndLock (lib cell view)
  (dssCheckoutCellViewP lib cell view
						?mode "lock"
						?force "t"
						?silent nil ))
;;
;; DONT USE
;;
;; b8xesdclampcap, b8xesdclampcaphv
;;
(defun pckEsdRemoveSkewVar (lib cell_list view separatore)
  (let (cv cdfid)
	(foreach cell cell_list
			 (when (member view (dbAllCellViews (ddGetObj lib) cell))
			   (fprintf stdout "-D- Library: %s Cell: %s View: %s\n" lib cell view)
			   (setq cv
					   (dbOpenCellViewByType lib cell view "" "a"))
			   (setq inst (setof sh cv~>instances (equal sh~>libName "analogLib")))
			   ;;
			   ;; cdfId = (cdfGetInstCDF inst)
			   ;; cdfId~>c = ??
			   t
			   )
			 )	
	)
  )

(defun pckCheckInLibrary (lib)
  "Checks in a list of libraries."
  (case (car lib)
	  (nil
	   (pckInfo "pckCheckInLibrary" "Check-in operation complete.")
	   )
	  (t
	   (pckInfo "pckCheckInLibrary" (sprintf nil "Checking in library %s." (car lib)))
	   (dssCheckinLibraryP
	   	(car lib)
	   	?force t ;; new
	   	?comment "Initial check-in"
	   	?skip t
	   	?new t
	   	?background nil ;; we want to see what is going on.
	   	?silent nil ;; get some output
	   	)
	   (pckCheckInLibrary (cdr lib)))
	  )
  )
  
  
;; added by rkalim 2012/06/20  
;; This function will copy of one cellview to another cellview
;; example: (pckCopyViewToAnotherViews "rkalim_p6" "interior" "schematic")
(defun pckCopyViewToAnotherViews (libname srcview  tgtview "ttt")
  "Copies source view to source view inside one library"
  (let (cv cellname src dst)
	(if (equal srcview nil)
	  (fprintf stdout "--I-- source view is empty. Operation completed.\n")
	  
	)  ;; end of if equal 	  
	(if (setq cv (ddGetObj libname))
		  (fprintf stdout " Library name is : %s\n" libname)
		  (fprintf stdout "\n--E-- Library  %s does not exist. Operation aborted.\n" libname)
	)  ;; enf of if src_lib
	  
	(fprintf stdout "--I-- Processing library %s..." libname)
	 
        (foreach cv1 cv~>cells
        (setq cellname cv1~>name)
            (foreach cv2 cv1~>views
                (if cv2~>name == srcview 
                then
                   (setq src (dbOpenCellViewByType libname cellname srcview "" "r" nil))
                   (setq dst (dbCopyCellView src libname cellname tgtview "" nil t))
		   (if dst 
	   	   then 
                      (dbSave dst)
                      (dbClose dst)
		   else	
		      (fprintf stdout "---I--      Do not copy for cellname %s because target has %s already\n" cellname tgtview)
		    ) ;; end if dst
                ) ;if
             ) ;foreach 1
        ) ;foreach 2
   )  ;; end of let
) ;; end of defun

