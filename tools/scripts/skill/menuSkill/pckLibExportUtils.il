;;Description        : Scripts to generate GDS files (output is in Pandora format) - top cell only
;;Return Value       : t/nil.
;;Bugs/Limitatiions  : Please report any issue to the author.
;;   Skill code to create GDS file
;;  Example:
;;     (pckStreamAllTemplates  (list (ddGetObj "dfd")) ?data_suf "drc" ?debug "no")
;;     (pckStreamAllTemplates  (list (ddGetObj "rkalim_p63")) ?data_suf myDir ?debug "no" ?stm_options "-hierDepth 0")
;;
;; (load "pckLibExportUtils.il")
;;
;; find . -maxdepth 2 -name "*.sum" -mtime -1 | xargs grep -li dirty | awk -F./ '{print $2 ".trcstd.icvlvs.cmp"}'
;; (pckCdlNetlistAllTemplates (list (ddGetObj "fdk71pxesd")) ?data_suf "dot2_lvs_basic" ?debug "no" )
;;
(defun pckStreamAllTemplates (lib_list
							  @key
							  (data_suf "")
							  (debug "yes")
							  (pandoraDir (strcat (getShellEnvVar "FDK_WORK") "/pandora/data"))
							  (create_lay "yes")
							  (cell_list nil)
							  (crisp "no")
							  (stm_options "")
							  )
  "Create stream files in pandora directory for list of libraries"
  ;;
  ;; lib_list: (ddGetLibList) (list (ddGetObj "fdk71pxprimtemplate"))
  ;; (list (ddGetObj "fdk71pxprimtemplate") (ddGetObj "fdk71pxesd"))
  ;; (list (ddGetObj "fdk71pxdfd") (ddgetObj "fdk71pxtapeout"))
  ;; (pckCdlNetlistAllTemplates (list (ddGetObj "fdk71pxesd")) ?data_suf "dot2_lvs_basic" ?debug "no" )
  (let (libs )
	(fprintf stdout "Pandora directory - %s\n" pandoraDir)
	(when (nequal data_suf "")
	  (setq pandoraDir (strcat pandoraDir "/" data_suf) )
	  )
	(unless (isDir pandoraDir)
	  (sh (strcat "mkdir -p " pandoraDir)))
	(foreach lib lib_list ;;libs
			 (setq i 0)
			 (foreach cell (dbGetq lib "cells")
					  (fprintf stdout ">>>> Processing cell # %d - %s. %d to go." i cell~>name
							   (difference  (length (dbGetq lib "cells") )
								   i))			 

					  (when (and  (member "layout" (dbAllCellViews lib cell~>name))
								  (or
								   (equal cell_list nil)
								   (and (nequal cell_list nil)
										(member cell~>name cell_list))))
						;;(dbOpenCellViewByType lib~>name cell~>name "layout")
						(fprintf stdout "Layout view exists for %L:%L\n" lib~>name cell~>name)
						(unless (isDir (strcat pandoraDir "/" lib~>name "/" cell~>name))
						  (sh (strcat "mkdir -p " (strcat pandoraDir "/" lib~>name "/" cell~>name "/cdl")))
						  (sh (strcat "mkdir -p " (strcat pandoraDir "/" lib~>name "/" cell~>name "/gds")))
						  )
						(fprintf stdout "Running %L %L  %L\n" lib~>name cell~>name
								 (strcat pandoraDir "/" lib~>name "/" cell~>name "/cdl/"))
						(when (equal debug "no")
						  (when (equal create_lay "yes")
							;;(sh (strcat "rm " (strcat pandoraDir "/" lib~>name "/" cell~>name "/" cell~>name ".stm")))
							;; (sh (strcat "ln -s "
							;; 			  (strcat
							;; 			   (getShellEnvVar "FDK_WORK") "/pandora/data/dot1/" lib~>name "/" cell~>name "/" cell~>name ".stm")
							;; 			  " "
							;; 			  (strcat pandoraDir "/" lib~>name "/" cell~>name "/" cell~>name ".stm")
							;; 			  ))
							;;
							;; rkalim: previous author does not fully support stm_options.  Supported it only for crisp.
                                                        ;; now we need to support for all
                                                        ;;
                                                        (if (equal crisp "yes") then
                                                            (setq mystm_options2  "-case upper  ")
                                                         else
                                                             (setq mystm_options2 "")
                                                         )
                                                        (if (nequal stm_options "") then
                                                             (setq mystm_options  (concat mystm_options2 stm_options))
                                                         else
                                                             (setq mystm_options mystm_options2)
                                                         )

							
							(pckStreamOut  lib~>name cell~>name "layout"
								  (getShellEnvVar "PDSSTM")
								  (strcat pandoraDir "/" lib~>name "/" cell~>name "/gds/" cell~>name ".gds")
								  ?stm_options mystm_options)
						  )
						)
					  (setq i (add1 i))
					)
			 )
	t
	)
  )
)

(defun pckCdlNetlistAllTemplates (lib_list @key
										   (data_suf "")
										   (debug "yes")
										   (pandoraDir (strcat (getShellEnvVar "FDK_WORK") "/pandora/data"))
										   (create_sch "yes")
									   (create_lay "yes")
									   (cell_list nil)
										   )
  "Create cdl netlists in pandora directory for list of libraries"
  ;;
  ;; lib_list: (ddGetLibList) (list (ddGetObj "fdk71pxprimtemplate"))
  ;; (list (ddGetObj "fdk71pxprimtemplate") (ddGetObj "fdk71pxesd"))
  ;; (list (ddGetObj "fdk71pxdfd") (ddgetObj "fdk71pxtapeout"))
  ;; (pckCdlNetlistAllTemplates (list (ddGetObj "fdk71pxprimtemplate") (ddGetObj "fdk71pxesd")) ?data_suf "1271.2_0.1" ?debug "no")
  ;; (pckCdlNetlistAllTemplates (list (ddGetObj "fdk71pxesd")) ?data_suf "dot2_lvs_basic" ?debug "no" )
  (let (libs )
	(fprintf stdout "Pandora directory - %s\n" pandoraDir)
	(when (nequal data_suf "")
	  (setq pandoraDir (strcat pandoraDir "/" data_suf) )
	  )
	(unless (isDir pandoraDir)
	  (sh (strcat "mkdir -p " pandoraDir)))
	(foreach lib lib_list ;;libs
			 (setq i 0)
			 (foreach cell (dbGetq lib "cells")
					  (fprintf stdout ">>>> Processing cell # %d - %s. %d to go.\n" i cell~>name
							   (difference  (length (dbGetq lib "cells") )
								   i))			 

					  (when (and (member "schematic" (dbAllCellViews lib cell~>name))
								 (member "layout" (dbAllCellViews lib cell~>name))
								 (or
								  (equal cell_list nil)
								  (member cell~>name cell_list))
								 )
						;;(dbOpenCellViewByType lib~>name cell~>name "layout")
						(fprintf stdout "Schematic view exists for %L:%L\n" lib~>name cell~>name)
												  (unless (isDir (strcat pandoraDir "/" lib~>name "/" cell~>name))
							(sh (strcat "mkdir -p " (strcat pandoraDir "/" lib~>name "/" cell~>name "/cdl")))
							(sh (strcat "mkdir -p " (strcat pandoraDir "/" lib~>name "/" cell~>name "/gds")))
							)
						  (fprintf stdout "Running %L %L  %L\n" lib~>name cell~>name
								   (strcat pandoraDir "/" lib~>name "/" cell~>name "/cdl/"))
						  (when (equal debug "no")
							(when (equal create_lay "yes")
							  (pckStreamOut  lib~>name cell~>name "layout"
											 (getShellEnvVar "PDSSTM")
											 (strcat pandoraDir "/" lib~>name "/" cell~>name "/gds/" cell~>name ".gds")))
							(when (equal create_sch "yes")							
							  (pckMakeQuickCDLNetlist
							   cell~>name
							   lib~>name
							   (strcat pandoraDir "/" lib~>name "/" cell~>name "/cdl")
							   (pckNetlistNameCB cell~>name)
							   )))
						)
					  (setq i (add1 i))
					)
			 )
	t
	)

  )

;;
;; Create COE71 test cases based on available schematics (exist in different library)
;;
/*
newcells = (list "bsxdcaisn2zp10_3x3_array_tr" "bsxdcaisn4zp10_3x3_array_tr" "b8xdcpisn2zp0_3x3_array" "b8xdcpisn4zp0_3x3_array" "b8xdcaiss4zp0_4x3_21_1n1ptap_tr" "b8xvargbnd12f360z_3x3" "b8xvargbnd36f360z_3x3" "b8xvargbnd60f360z_3x3")
(setq cell_list (mapcar (lambda (x) (ddGetObj "coe71testcases" x)) newcells ))

esd_cells = (list "b8xesdd1lc250vertuhvm7" "b8xesdd2lc250vertuhvm7" "b8xesdd2lcvertuhvm7" "b8xesdd1lcvertuhvm7" "b8xesdd1d2lcvertuhvm7" "b8xesdd1d2lcvertuhvm7")
(setq cell_list (mapcar (lambda (x) (ddGetObj "fdk71pxesd" x)) esd_cells ))

esd_cells = (list "b8xesdresgcn" "b8xesdvtolclamptg270ehvpath")
(setq cell_list (mapcar (lambda (x) (ddGetObj "fdk71pxesd" x)) esd_cells ))

esd_cells = (list "b8xesdvtolclamptg270p5uhvcore"	"b8xesdvtolclamptg270uhvcore"	"b8xesdvtolclamptg270ehv"	"b8xesdvtolclamptgmv270ehv"	"b8xesdvtolclamptg270p5uhv"	"b8xesdvtolclamptgmv270ehvcore"	"b8xesdvtolclamptg270ehvcore"	"b8xesdvtolclamptg270uhv" "b8xesdresgcn" "b8xesdresgcnehv" "b8xesdresgcntguhv")

tmd_diode = (list "b8xtmdiode" "b8xtmdiodenod1c" "b8xtmdiode4x10")
(setq cell_list (mapcar (lambda (x) (ddGetObj "fdk71pxesd" x)) tmd_diode ))

*/



(defun pckCreateCOE71Cases (source_sch target_lib
									   @key
									   (data_suf "")
									   (debug "yes")
									   (extra_list nil)
									   (pandoraDir (strcat (getShellEnvVar "FDK_WORK") "/pandora/data"))
									   (create_sch "yes")
									   (create_lay "yes")
									   )
  "Find all SCH cells in source library. Create cdl & stm files in target pandora library for these cells."
  ;;
  ;; lib_list: (ddGetLibList) (list (ddGetObj "fdk71pxprimtemplate"))
  ;; (pckCreateCOE71Cases "c71pxprocqanonprd_coe71_sch" "coe71testcases" ?data_suf "/coe71" ?debug "no")
  ;; (pckCreateCOE71Cases "c71pxprocqanonprd_coe71_sch" "coe71testcases" ?data_suf "/coe71" ?debug "no"
  ;;                 ?extra_list (list ...))
  ;; 
  (let (libs lib i cell_list)
	(when (nequal data_suf "")
	  (setq pandoraDir (strcat pandoraDir "/" data_suf) )
	  )
	(setq lib (ddGetObj target_lib))
	(fprintf stdout "Pandora directory - %s\n" pandoraDir)
	(unless (isDir pandoraDir)
	  (sh (strcat "mkdir -p " pandoraDir)))
	(setq i 0)
	(if extra_list
		(progn (setq cell_list extra_list))
	  (progn (setq cell_list (dbGetq (ddGetObj source_sch) "cells")))	  
	  )
	(fprintf stdout "%L\n" extra_list~>name)
	(fprintf stdout "%L\n" cell_list~>name)
	(foreach cell cell_list
			 (fprintf stdout ">>>> Processing cell # %d - %s. %d to go.\n" i cell~>name
					  (difference  (length cell_list ) i))			 
			 (when
				 (and (member "schematic" (dbAllCellViews lib cell~>name))
					  (member "layout" (dbAllCellViews lib cell~>name)))
			   ;;(dbOpenCellViewByType lib~>name cell~>name "layout")
			   (fprintf stdout "Schematic and layout views exist for %L:%L\n" lib~>name cell~>name)
			   (unless (isDir (strcat pandoraDir "/" lib~>name "/" cell~>name))
				 (sh (strcat "mkdir -p " (strcat pandoraDir "/" lib~>name "/" cell~>name "/cdl")))
				 (sh (strcat "mkdir -p " (strcat pandoraDir "/" lib~>name "/" cell~>name "/gds")))
				 )
			   (fprintf stdout "Running %L %L  %L\n" lib~>name cell~>name
						(strcat pandoraDir "/" lib~>name "/" cell~>name "/cdl/"))
			   (when (equal debug "no")
				 ;;(sh (strcat "rm " (strcat pandoraDir "/" lib~>name "/" cell~>name "/" cell~>name ".stm")))
				 (when (equal create_lay "yes")
				   (pckStreamOut  lib~>name cell~>name "layout"
								  (getShellEnvVar "PDSSTM")
								  (strcat pandoraDir "/" lib~>name "/" cell~>name "/gds/" cell~>name  ".gds")))
				 (when (equal create_sch "yes")
				   
				   (pckMakeQuickCDLNetlist
					cell~>name
					lib~>name
					;;(strcat (getShellEnvVar "FDK_WORK") "/netlists/cdl")
					(strcat pandoraDir "/" lib~>name "/" cell~>name "/cdl")
					(pckNetlistNameCB cell~>name)
					))
				 )
			   )
			 (setq i (add1 i))
			 )
	t
	)
  )

;;
;; code to get uncategorized cells in a library

(defun pckGetAllCellsPerCategory ()
  
  (setq libs
		(setof ll (ddGetLibList)
			   (and
				(nequal ll~>name "fdk71pxtech")
				(rexMatchp "fdk71px*" ll~>name))))
  (foreach lib libs
		   (foreach cat (ddCatGetLibCats lib)
					(fprintf stdout ">>> %L %L\n" lib~>name cat)
					(when (ddCatFindCat lib cat "r") 
					  (mapcar
					   (lambda (x)
						 (fprintf stdout "%s %s %s\n" lib~>name cat (car x)))
					   (setof x (ddCatGetCatMembers (ddCatFindCat lib cat "r")) (equal "cell" (cadr x)))))
					;;(fprintf stdout "%s %s\n" lib~>name cat)
					)
		   (mapcar (lambda (x) (fprintf stdout "%s Uncategorized %s\n" lib~>name x)) (ddCatGetCellsNotInCat lib))))

(defun pckGetCellWithUpperMetal (lib_list met_list)
  (let (cell_list i)
	(setq cell_list (list))
	(foreach lib lib_list
			 (setq i 0)
			 (foreach cell (dbGetq lib "cells")
					  (fprintf stdout ">>>> Processing cell # %d - %s. %d to go." i cell~>name
							   (difference  (length (dbGetq lib "cells") )
								   i))
					  (when (and (member "layout" (dbAllCellViews lib cell~>name)))
						;;(dbOpenCellViewByType lib~>name cell~>name "layout")
						(fprintf stdout "Layout view exists for %L:%L\n" lib~>name cell~>name)
						(setq cv
							  (dbOpenCellViewByType lib~>name cell~>name "layout"))
						(when
							(and
							 (exists met cv~>layerHeaders~>layer
									 (member met met_list))
							 ;; ignore labels among 
							 (setof shape cv~>shapes
									(and
									 (member shape~>layerName me_list)
									 (nequal shape~>objType "label")))
								 (not (member cv cell_list)))
								   (setq cell_list (cons cv cell_list))
								   (fprintf stdout "Adding cell %s:%s to cell_list\n" lib~>name cell~>name)
								   )
						;;(dbClose cv)
						)
					  (setq i (add1 i))
					  )

			 )
	cell_list
	)
  )
(defun pckStripLayoutLabels (lib_list)
  (let (cell_list i)
	(setq cell_list (list))
	(foreach lib lib_list
			 (setq i 0)
			 (foreach cell (dbGetq lib "cells")
					  (fprintf stdout ">>>> Processing cell # %d - %s. %d to go." i cell~>name
							   (difference  (length (dbGetq lib "cells") )
								   i))
					  (when (and (member "layout" (dbAllCellViews lib cell~>name)))
						;;(dbOpenCellViewByType lib~>name cell~>name "layout")
						(fprintf stdout "Layout view exists for %L:%L\n" lib~>name cell~>name)
						(setq cv
							  (dbOpenCellViewByType lib~>name cell~>name "layout" "maskLayout" "a"))
						(setq label_list (setof x cv~>shapes (equal x~>objType "label")))
						(foreach obj label_list (dbDeleteObject obj ))
						(dbSave cv)
						(dbClose cv)
						)
					  (setq i (add1 i))
					  )

			 )
	cell_list
	)
  

  )
(defun pckAlignLayoutLabels (lib_list @key (skip_list nil))
  (let ( i)
	
	(foreach lib lib_list
			 (setq i 0)
			 (foreach cell (dbGetq lib "cells")
					  (fprintf stdout ">>>> Processing cell # %d - %s. %d to go." i cell~>name
							   (difference  (length (dbGetq lib "cells") )
								   i))
					  (when (and (member "layout" (dbAllCellViews lib cell~>name))
								 (or
								  (equal skip_list nil)
								  (not (member cell~>name skip_list)))
								 )
						;;(dbOpenCellViewByType lib~>name cell~>name "layout")
						(fprintf stdout "Layout view exists for %L:%L\n" lib~>name cell~>name)
						(pckLabelReplace lib~>name cell~>name )
						)
					  (setq i (add1 i))
					  )

			 )
	;;cell_list
	)
  

  )
  
  
  
/****************************************************************************
 INTEL CONFIDENTIAL. COPYRIGHT © 2012, INTEL CORPORATION ALL RIGHTS RESERVED                         
  UNAUTHORIZED REPRODUCTION/DISTRIBUTION OF PART OR ALL OF THIS CODE 
                          IS STRICTLY PROHIBITED                                    
*****************************************************************************

Author             : Ronald Kalim (ronald.kalim@intel.com>
Date               : Jan 14, 2012
Version            : 0.1  
Application        : Skill
Description        : Scripts to rebind and create derive library (related to unified library)
Return Value       : t/nil.
Bugs/Limitatiions  : Please report any issue to the author.

   Skill code to create derived library.  For example, create fdk71p6tapeout from tapeout.  What it does: 
   a. Create new library (if that library exist, delete it first)
   b. Attach its techlib to fdk71p6tech (for p6)
   c. Copy all cells from tapeout to fdk71p6tapeout 
   d. Rebind cell from prim to fdk71p6prim etc
   e. Run "CheckAndSave" so user could netlist CDL immediately

;; future: target library, remove DMTYPE none


  Example usage: (pckCreateDotSpecificLib "dfd")

Requirement:
 a. Make sure that you run "dbmenu" using type = QA (not dev).  
 b. Use correct dotProcess.  You could not create fdk71p6tapeout if your terminal session uses dot9.  

****************************************************************************/

;; function to delete cell based on pattern
(defun pckDeleteCellPattern (lib pattern "tt")
  (let  (cellDDid delViewList)
    cellDDid = ddGetObj(lib)
    (when cellDDid	
       	delList = rexMatchList(pattern cellDDid~>cells~>name)
  	(foreach cname delList
      		ddDeleteObj(ddGetObj(lib cname))
     	) ;; end of foreach
    	printf("\nDeleted the cells %L from %s"   delList lib)
    ); end of when
  );let
); end of defun


;; instead of just create lib and create new cds.lib, this function
;; will create new library and update cds.lib at the specified library
;(defun pckLibCreate (libName cdslibPath)
; 	(prog ( stringValue libDir)
;    		libDir = simplifyFilename(strcat(cdslibPath "/" libName))
;    		cdslibPath = strcat(cdslibPath "/libs.def")
;    		stringValue = simplifyFilename(cdslibPath)
;    		(if !isFile(stringValue) then
;      			(warn "lib.defs file does not exist in %s\n" cdslibPath)
;      			return()
;    		)
;    		ddSetForcedLib(stringValue)
;    		ddCreateLib(libName libDir)
;    		ddSetForcedLib("")
;  	) ;; end of prog
;)  ;; end of defun



(defun pckCreateDotSpecificLib (libName)
  myLibList = (list libName )
  dot = (strcat "p" (getShellEnvVar "FDK_DOTPROC"))
  myLibName = nil
  newPrefix = (strcat "fdk71" dot)
  newBindFile = (strcat  (getShellEnvVar "PCK_CAD") "/common/bind_map/" dot "create.txt")
  newLibName = nil 
  newTechName = nil
  comPat1 = pcreCompile( "px" )
  newBind = pcreReplace( comPat1 "fdk71px.*" dot 0 )

  (printf "===PCK - start working on list of library %L =======================\n" myLibList)
  (foreach oldLibName myLibList
   	(printf "=============================================================\n")
	;; to do check if target library exist, if yes, delete it
	;; RYK: need to create local cds.lib
	newLibName =  (strcat newPrefix oldLibName) 	
	libList=ddGetLibList()~>name
     	(if (member newLibName libList) 
	then
		(printf "PCK: We have existing library %s to be deleted \n" newLibName)
		(ddDeleteObj (ddGetObj newLibName))
	else 
		(printf "PCK: We do not have have existing library %s. Continue ... \n" newLibName)

	)

	newTechName = (buildString (parseString "fdk71pxtech" "px") dot)
	(printf "===PCK - newLibName = %s, newTechName = %s, and newBindFile = %s\n" newLibName newTechName  newBindFile)
	(printf "=============================================================\n")	
	a1 = (ddCreateLib newLibName   (strcat (getShellEnvVar "PWD") "/" newLibName ))
	(ddSetLibUnmanaged a1)
	;; RYK copy category files
	(techBindTechFile (ddGetObj newLibName) newTechName)	
	(printf "===PCK - working to copy library %s = to library %s=\n" oldLibName newLibName)
	
	(pckCopyPxToDotLibrary (list oldLibName) (list newLibName))	
	;; by default, the new library is writable

	;; somehow after  running pckCopyPxToDotLibrary, library is attached to tech again
	;; so we fix it here
        (techBindTechFile (ddGetObj newLibName) newTechName)


	;;(printf "PCK cleanup unnecessary cells =============================================================\n")
	;; regular expression "^b82." will match all cellnames that start with the word 'b82'
	;;(pckDeleteCellPattern newLibName "^b82")
	(printf "PCK rebind=============================================================\n")
	(pckRebindLibCells newLibName (list "schematic" "layout" "interior") newBindFile)
    	;;(printf "PCK checklibbinding=============================================================\n")
	;;not working (pckCheckLibBindings   (list newLibName) newBind (list "basic" "analogLib") (list "layout" "schematic"))

	;; RK do Check and Save
    	(pckCheckAndSaveSchLib  newLibName)
	
	)
  (printf "pckCreateDotSpecificLib run is completed")

)
