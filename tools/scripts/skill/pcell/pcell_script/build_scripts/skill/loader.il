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

let((SKILL_SCRIPT_LOAD_LIST our_loadpath our_dirpath)

  ;; Specify in order & relative to this loader.il's location
  SKILL_SCRIPT_LOAD_LIST = list(
    "CCSchangePinAndLabel.il"
    "techFuncDeps.il"
    "fdkPropBagDevProcs.il"
    "fdkFindFiles.il"
    "fdkScanCustomPackagesDir.il"
    "fdkCustomGenAndLoadModelSelCallbacks.il"
    "fdkCustomBuild.il"
    "fdkCustomLoad.il"
    "fdkShowHiddenShapes.il"
    "fdkDumpSymPinCoordsTab.il"
    "fdkRemoveLibMc0Shapes.il"
    "fdkUpdateFillLayerBlockages.il"
    "fdkUpdateLvsIgnoreProps.il"
    "fdkUpdateUhvPinLabels.il"
    "fdkUpdateVidLabel.il"
    "fdkUpdateVssPins.il"
  )

  ;; Add version-specific build_scripts loader.il if available
  let((fdk_managed_area d8lib_vers d8lib_skill_loader_fpath)
  when( stringp(fdk_managed_area = getShellEnvVar("FDK_MANAGED_AREA")) &&
        !blankstrp(fdk_managed_area) &&
        stringp(d8lib_vers = getShellEnvVar("D8LIB_VERSION")) &&
        !blankstrp(d8lib_vers) &&
        isReadable(simplifyFilename(sprintf(d8lib_skill_loader_fpath
          "%s/fdk73/oalibs/common/custom/%s/build_scripts/skill/loader.il"
        fdk_managed_area d8lib_vers) t))
    SKILL_SCRIPT_LOAD_LIST = append(SKILL_SCRIPT_LOAD_LIST list(d8lib_skill_loader_fpath))
  ))

  our_loadpath = simplifyFilename(get_filename(piport) t)
  our_dirpath = (rexMatchp("/[^/]*$" our_loadpath) && rexReplace(our_loadpath "" 0))

  foreach( base_fpath SKILL_SCRIPT_LOAD_LIST
  let((abs_fpath exec_dirpath old_skill_path)
    abs_fpath = simplifyFilename(
      if( rexMatchp("^/" base_fpath)
      then base_fpath
      else sprintf(nil "%s/%s" our_dirpath base_fpath)
      )
      t)
    exec_dirpath = (rexMatchp("/[^/]*$" abs_fpath) && rexReplace(abs_fpath "" 0))
    old_skill_path = getSkillPath()
    setSkillPath(cons(exec_dirpath old_skill_path))
    if( errset(load(abs_fpath) t)
    then printf("Loaded %L\n" abs_fpath)
    else fprintf(stderr "ERROR: Couldn't load %L\n" abs_fpath)
    )
    setSkillPath(old_skill_path)
  ))

)
