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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   fdkCustomLoadReport
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomLoadReport nil )
procedure(

  fdkCustomLoadReport(
    packages_tab
  )

let(()

  printf("***BEGIN fdkCustomLoad REPORT***\n")
  foreach( pack packages_tab
  let((props)
    printf("package %L:\n" pack)
    props = packages_tab[pack]
    for( ix 1 length(props)
      when( evenp(ix)
      let((pname pval)
        pname = nthelem(ix props)
        pval = get(props pname)
        cond(
          ( member(pname '(propbag_tab cmn_il_procs))
            printf("  %L:\n" pname)
            foreach( cn pval
              printf("    %L\n" cn)
            )
          )
          ( length(pval) != 1
            fprintf(stderr "  %L: (ERROR: Multiple matching files detected)\n" pname)
            foreach( fpath pval
              printf("    %L\n" fpath)
            )
          )
          ( t printf("  %L: %L\n" pname pval) )
        )
      ))
    )
  ))
  printf("***END fdkCustomLoad REPORT***\n")

))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   fdkCustomLoadSkillFile
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomLoadSkillFile nil )
procedure(

  fdkCustomLoadSkillFile(
    fpath
  )

let((old_skill_path dirpath error_flag)

  old_skill_path = getSkillPath()

  ;;; add script file's containing directory to head of SKILL path
  when( isDir(dirpath = (rexMatchp("/[^/]*$" fpath) && rexReplace(fpath "" 0)))
    setSkillPath(cons(dirpath old_skill_path))
  )
  
  if( errset(load(fpath) 't)
  then printf("Loaded %L\n" fpath)
  else fprintf(stderr "ERROR: loading %L\n" fpath)
       error_flag = 't
  )

  when( getSkillPath() != old_skill_path
    setSkillPath(old_skill_path)
  )

!error_flag))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   fdkCustomLoadCdfCallbacks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomLoadCdfCallbacks nil )
procedure(

  fdkCustomLoadCdfCallbacks(
    packages_tab LIBRARY
  )

let((error_flag)

  foreach( pack packages_tab
  when( stringp(pack)

    if( length(packages_tab[pack]->cdf_il_procs) > 1
    then fprintf(stderr "ERROR: Multiple SKILL files for pack %L Cdf callback definitions.\n" pack)
         foreach( fpath packages_tab[pack]->cdf_il_procs
           fprintf(stderr "       %L\n" fpath)
         )
         error_flag = 't
    else foreach( fpath packages_tab[pack]->cdf_il_procs
           when( !fdkCustomLoadSkillFile(fpath)
             error_flag = 't
           )
         )
    )

    when( dtpr(packages_tab[pack]->model_sel_gen)
      cond(
        ( length(packages_tab[pack]->model_sel_gen) > 1
          fprintf(stderr "ERROR: Multiple Model Sel gen scripts for pack %L Cdf callback definitions.\n" pack)
          foreach( fpath packages_tab[pack]->model_sel_gen
            fprintf(stderr "       %L\n" fpath)
          )
          error_flag = 't
        )
        ( length(packages_tab[pack]->model_sel_csv) > 1
          fprintf(stderr "ERROR: Multiple Model Sel .csv files for pack %L Cdf callback definitions.\n" pack)
          foreach( fpath packages_tab[pack]->model_sel_csv
            fprintf(stderr "       %L\n" fpath)
          )
          error_flag = 't
        )
        ( t when( !fdkCustomGenAndLoadModelSelCallbacks(
                     car(packages_tab[pack]->model_sel_gen)
                     car(packages_tab[pack]->model_sel_csv)
                   )
              error_flag = 't
            )
        )
      )
    )

  ))

!error_flag))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   fdkCustomLoadPcellCallbacks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomLoadPcellCallbacks nil )
procedure(

  fdkCustomLoadPcellCallbacks(
    packages_tab LIBRARY
  )

let((error_flag)

  foreach( pack packages_tab
  when( stringp(pack)
    if( length(packages_tab[pack]->pcell_il_procs) > 1
    then fprintf(stderr "ERROR: Multiple SKILL files for pack %L Pcell callback definitions.\n" pack)
         foreach( fpath packages_tab[pack]->pcell_il_procs
           fprintf(stderr "       %L\n" fpath)
         )
         error_flag = 't
    else foreach( fpath packages_tab[pack]->pcell_il_procs
           when( !fdkCustomLoadSkillFile(fpath)
             error_flag = 't
           )
         )
    )
  ))

!error_flag))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomLoadUsage nil )
procedure(
  fdkCustomLoadUsage()
  printf("Use to reload SKILL callbacks for CDFs and/or Pcells.\n")
  printf("Usage:\n")
  printf("  fdkCustomLoad(\n")
  printf("  ;One or more of the following keywords:\n")
  printf("    'common                              ;Requests loading of SKILL code from intel73custom package directory.\n")
  printf("    'cdfs                                ;Loads SKILL callbacks for CDFs\n")
  printf("                                         ;(generates model-select code if necessary)\n")
  printf("    'pcells                              ;Loads SKILL callbacks for Pcells\n")
  printf("    'all                                 ;Loads all SKILL callbacks for common + all package names\n")
  printf("                                         ;(generates model-select code if necessary)\n")
  printf("    'report                              ;Dumps list of package names matching ?pack\n")
  printf("    ?pack <name> or ?packs list(<names>) ;Required list of package names\n")
  printf("      or ?packs 'all                     ;Use keyword 'all to load SKILL files associated with all packages\n")
  printf("    [ ?cell <name> or ?cells list(<names>) ]  ;optional filtering list of cell names\n")
  printf("  )\n")
)
newline()
fdkCustomLoadUsage()
newline()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomLoad nil )
procedure(

  fdkCustomLoad(
  @key
    (pack nil) (packs nil)
    (cell nil) (cells nil)
    (LIBRARY "intel73custom")
  @rest
    actions
  )
  
let((cdf_flag pcell_flag report_flag error_flag load_pkgs_tab)

  ;;; listify packs & cells arguments if necessary
  if( member('all list(pack packs))
  then pack = packs = 'all
  else when( !null(pack) && (!stringp(pack) || !blankstrp(pack)) packs = cons(pack packs) )
       when( !null(packs) && !dtpr(packs) packs = list(packs) )
  )
  when( member('all list(cell cells)) cell = cells = nil )
  when( !null(cell) && (!stringp(cell) || !blankstrp(cell)) cells = cons(cell cells) )
  when( !null(cells) && !dtpr(cells) cells = list(cells) )

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;; parse the command line arguments
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if( null(actions)
  then fdkCustomLoadUsage()
  else

    foreach( action actions
      cond(
        ( member(action '(all))
          cdf_flag = pcell_flag = 't
          packs = 'all
        )
        ( member(action '(common))
          when( ((packs != 'all) && !member('common packs))
            packs = cons('common packs)
          )
        )
        ( member(action '(cdf cdfs)) cdf_flag = 't )
        ( member(action '(pcell pcells)) pcell_flag = 't )
        ( action == 'report
          report_flag = 't
        )
        ( t fprintf(stderr "ERROR: Unknown action keyword %L\n" action)
            error_flag = 't )
      )
    )

    cond(
      ( error_flag
        fdkCustomLoadUsage()
      )
      ( (cdf_flag || pcell_flag || report_flag) && null(packs) && null(cells)
        fprintf(stderr "ERROR: ?packs and/or ?cells args must be specified\n")
        fdkCustomLoadUsage()
        error_flag = 't
      )
      ( !tablep(load_pkgs_tab = fdkScanCustomPackagesDir(packs ?LIBRARY LIBRARY ?cells cells)) ||
        (length(load_pkgs_tab) < 1)
        fprintf(stderr "ERROR: Couldn't find args%s%s in packages directory.\n"
          if( !null(packs) sprintf(nil " packs %L" packs) "" )
          if( !null(cells) sprintf(nil " cells %L" cells) "" )
        )
        error_flag = 't
      )

    )
    
  )

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;; Dump the package info in the CIW if 'report argument was specified
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  when( report_flag
    fdkCustomLoadReport(load_pkgs_tab)
  )

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;; Load the 'common routines if requested
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  when( ((packs == 'all) || member('common packs))
    foreach( fpath load_pkgs_tab['common]->cmn_il_procs
      when( !fdkCustomLoadSkillFile(fpath)
        error_flag = 't
      )
    )
  )

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;; Load the selected CDF callbacks
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  when( cdf_flag
    when( !fdkCustomLoadCdfCallbacks(load_pkgs_tab LIBRARY)
      error_flag = 't
    )
  )

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;; Load the selected Pcell callbacks
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  when( pcell_flag
    when( !fdkCustomLoadPcellCallbacks(load_pkgs_tab LIBRARY)
      error_flag = 't
    )
  )

!error_flag))
