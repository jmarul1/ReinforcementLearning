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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  fdkScanCustomPackageDir
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkScanCustomPackageDir nil )
procedure(

  fdkScanCustomPackageDir(
    pack_pfx top_dirpath
  )
  
let((fpath_list pkgs_tab)

  pkgs_tab = makeTable('fdkScanCustomPackagesDirTab nil)

  if( !dtpr(fpath_list = fdkFindFiles(top_dirpath
                           ?path_prune_func lambda((p)
                                              isDir(p) && rexMatchp("^\\." car(reverse(parseString(p "/"))))
                                            )
                           ?fname_match_func lambda((fname)
                                               rexMatchp("\\.csv$" fname) ||
                                               rexMatchp("\\.cdf$" fname) ||
                                               rexMatchp("\\.il$" fname) ||
                                               rexMatchp("\\.pc$" fname) ||
                                               rexMatchp("\\.py$" fname) ||
                                               rexMatchp("\\.sh$" fname) ||
                                               rexMatchp("\\.tcl$" fname)
                                             )
                          )
       )

  then fprintf(stderr "ERROR: Couldn't find any package files in directory %L\n" top_dirpath)

  else

    foreach( fpath fpath_list
    let((fname dot pack)

      fname = car(reverse(parseString(fpath "/")))

      check_func = lambda((args)
                   let((pk)
                     pk = fname
                     while( stringp(pk) && dtpr(args)
                       pk = (rexMatchp(car(args) pk) && rexReplace(pk "" 0) )
                       args = cdr(args)
                     )
                     when( stringp(pk) && (pk != fname) &&
                           rexMatchp(sprintf(nil "^%s" pack_pfx) pk)
                       when( !pkgs_tab[pk] pkgs_tab[pk] = list(nil) )
                       pk
                     )
                   ))

      cond(
        ;;; model selection table
        ( stringp(dot = getShellEnvVar("FDK_DOT")) && !blankstrp(dot) &&
          stringp(pack = funcall(check_func list(sprintf(nil "^fdk73p%s_" dot) "\\.csv$")))
          pkgs_tab[pack]->model_sel_csv = cons(fpath pkgs_tab[pack]->model_sel_csv)
        )
        ( stringp(pack = funcall(check_func list("^fdk73px_" "\\.csv$")))
          pkgs_tab[pack]->model_sel_csv = cons(fpath pkgs_tab[pack]->model_sel_csv)
        )
        ;;; model selection gen script
        ( stringp(dot = getShellEnvVar("FDK_DOT")) && !blankstrp(dot) &&
          stringp(pack = funcall(check_func list(sprintf(nil "^fdk73p%s_" dot) "\\.sh$")))
          pkgs_tab[pack]->model_sel_gen = cons(fpath pkgs_tab[pack]->model_sel_gen)
        )
        ( stringp(pack = funcall(check_func list("^fdk73px_" "\\.sh$")))
          pkgs_tab[pack]->model_sel_gen = cons(fpath pkgs_tab[pack]->model_sel_gen)
        )
        ;;; property bag table (needs to be after model selection table match)
        ( stringp(pack = funcall(check_func list("\\.csv$")))
          pkgs_tab[pack]->propbag_csv = cons(fpath pkgs_tab[pack]->propbag_csv)
        )
        ;;; CDF-define procedures
        ( stringp(pack = funcall(check_func list("^fdkCdf_" "\\.cdf$")))
          pkgs_tab[pack]->cdf_def_proc = cons(fpath pkgs_tab[pack]->cdf_def_proc)
        )
        ;;; CDF SKILL callbacks
        ( stringp(pack = funcall(check_func list("^fdkCdf_" "CB\\.il$")))
          pkgs_tab[pack]->cdf_il_procs = cons(fpath pkgs_tab[pack]->cdf_il_procs)
        )
        ;;; CDF Tcl callbacks
        ( stringp(pack = funcall(check_func list("^fdkCdf_" "CB\\.tcl$")))
          pkgs_tab[pack]->cdf_tcl_procs = cons(fpath pkgs_tab[pack]->cdf_tcl_procs)
        )
        ;;; Pcell callbacks
        ( stringp(pack = funcall(check_func list("^fdkPcell_" "CB\\.il$")))
          pkgs_tab[pack]->pcell_il_procs = cons(fpath pkgs_tab[pack]->pcell_il_procs)
        )
        ;;; Pcell-definition procedure
        ( stringp(pack = funcall(check_func list("^fdkPcell_" "\\.pc$")))
          pkgs_tab[pack]->pcell_def_proc = cons(fpath pkgs_tab[pack]->pcell_def_proc)
        )
        ;;; Pycell callbacks
        ( stringp(pack = funcall(check_func list("^fdkPycell_" "CB\\.py$")))
          pkgs_tab[pack]->pycell_py_procs = cons(fpath pkgs_tab[pack]->pycell_py_procs)
        )
        ;;; Pycell-definition procedure
        ( stringp(pack = funcall(check_func list("^fdkPycell_" "\\.py$")))
          pkgs_tab[pack]->pycell_def_proc = cons(fpath pkgs_tab[pack]->pycell_def_proc)
        )
      )

    ))

    foreach( pack pkgs_tab

      cond(

        ( !pkgs_tab[pack]
          fprintf(stderr "ERROR: Did not find any files in packages directory for pack %L\n" pack)
          remove(pack pkgs_tab)
        )

        ( !dtpr(pkgs_tab[pack]->propbag_csv)
          fprintf(stderr "ERROR: Did not find any property bag .csv files associated with pack %L\n" pack)
          fprintf(stderr "ERROR: Other files associated with pack %L:\n" pack)
          foreach( fpath_list  list(
                                 pkgs_tab[pack]->model_sel_csv
                                 pkgs_tab[pack]->model_sel_gen
                                 pkgs_tab[pack]->cdf_def_proc
                                 pkgs_tab[pack]->cdf_il_procs
                                 pkgs_tab[pack]->cdf_tcl_procs
                                 pkgs_tab[pack]->pcell_il_procs
                                 pkgs_tab[pack]->pcell_def_proc
                                 pkgs_tab[pack]->pycell_py_procs
                                 pkgs_tab[pack]->pycell_def_proc
                               )
            foreach( fpath fpath_list
              fprintf(stderr "       %s\n" fpath)
            )
          )
          fprintf(stderr "ERROR: Pack names are case-sensitive - make sure your file & procedure names haev appropriate case.\n")
          remove(pack pkgs_tab)
        )

        ( length(pkgs_tab[pack]->propbag_csv) != 1
          fprintf(stderr "ERROR: Found more than one property bag .csv file associated with pack %L\n" pack)
        )

        ( t

          foreach( propbag_csv pkgs_tab[pack]->propbag_csv
          let((propbag_tab propbag_cell_names)
            if( !tablep(propbag_tab = fdkCustomReadPropBagCsvFile(propbag_csv))
            then fprintf(stderr "ERROR: reading property bag .csv file %L\n" propbag_csv)
            else foreach( cn propbag_tab
                   propbag_cell_names = cons(cn propbag_cell_names)
                 )
                 if( !propbag_cell_names
                 then fprintf(stderr "ERROR: No cell names found in property bag .csv file %L\n" propbag_csv)
                 else pkgs_tab[pack]->propbag_tab = propbag_tab
                 )
            )
          ))

        )

      )

    )

  )

  when( length(pkgs_tab) > 0 pkgs_tab )

))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  fdkScanCustomPackagesDir
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkScanCustomPackagesDir nil )
procedure(

  fdkScanCustomPackagesDir(
    selected_packs
  @key
    (LIBRARY "intel73custom")
    (cells nil)
  )

let((fdk_managed_area packages_dirpath full_pkgs_tab pkgs_tab)

  full_pkgs_tab = makeTable('fdkScanCustomPackagesDirTab nil)

  cond(

    ( !stringp(fdk_managed_area = getShellEnvVar("FDK_MANAGED_AREA")) || blankstrp(fdk_managed_area)
      fprintf(stderr "ERROR: FDK_MANAGED_AREA env var is not defined.\n")
    )

    ( !isDir(packages_dirpath = simplifyFilename(sprintf(nil
         "%s/fdk73/oalibs/common/custom/package" fdk_managed_area
       ) t))
      fprintf(stderr "ERROR: No directory at path %L\n" packages_dirpath)
    )

    ( t foreach( pack getDirFiles(packages_dirpath)
        let((pack_path)
          sprintf(pack_path "%s/%s" packages_dirpath pack)
          when( isDir(pack_path) && !rexMatchp("^\\." pack)
            if( (pack == LIBRARY)
            then let((cmn_il_fpath_list cmn_tcl_fpath_list)
                   when( dtpr(cmn_il_fpath_list = fdkScanForSkillFiles(pack_path))
                     if( !full_pkgs_tab['common]
                     then full_pkgs_tab['common] = list(nil 'cmn_il_procs cmn_il_fpath_list)
                     else full_pkgs_tab['common]->cmn_il_procs = cmn_il_fpath_list
                     )
                   )
                   when( dtpr(cmn_tcl_fpath_list = fdkScanForTclFiles(pack_path))
                     if( !full_pkgs_tab['common]
                     then full_pkgs_tab['common] = list(nil 'cmn_tcl_procs cmn_tcl_fpath_list)
                     else full_pkgs_tab['common]->cmn_tcl_procs = cmn_tcl_fpath_list
                     )
                   )
                 )
            else let((pkgs_tab)
                 when( tablep(pkgs_tab = fdkScanCustomPackageDir(pack pack_path))
                 foreach( pkg_nm pkgs_tab
                 when( !null(pkgs_tab[pkg_nm])
                   full_pkgs_tab[pkg_nm] = pkgs_tab[pkg_nm]
                 ))))
            )
          )
        ))
    )

  )

  pkgs_tab = makeTable('fdkScanCustomPackagesDirTab nil)

  foreach( pkg_nm full_pkgs_tab
    cond(
      ( (selected_packs == 'all) || member(pkg_nm selected_packs)
        pkgs_tab[pkg_nm] = full_pkgs_tab[pkg_nm]
      )
      ( !null(exists(cn full_pkgs_tab[pkg_nm]->propbag_tab member(cn cells)))
        pkgs_tab[pkg_nm] = full_pkgs_tab[pkg_nm]
      )
    )
  )

  when( length(pkgs_tab) > 0 pkgs_tab )

))
