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
;;;   fdkCustomBuildReport
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomBuildReport nil )
procedure(

  fdkCustomBuildReport(
    packages_tab
  )

let(()

  printf("***BEGIN fdkCustomBuild REPORT***\n")
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
  printf("***END fdkCustomBuild REPORT***\n")

))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   fdkCustomBuildPropBags
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomBuildPropBags nil )
procedure(

  fdkCustomBuildPropBags(
    packages_tab LIBRARY cells
  )

let((error_flag)

  foreach( pack packages_tab
  when( stringp(pack)
  let((propbag_tab)
    if( null(propbag_tab = packages_tab[pack]->propbag_tab)
    then fprintf(stderr "ERROR: No property bag info recorded for pack %L\n" pack)
         error_flag = t
    else foreach( cn propbag_tab
         when( !cells || member(cn cells)
           when( !errset(fdkCustomDefinePropBag(LIBRARY cn propbag_tab[cn]) t)
             fprintf(stderr "ERROR: Couldn't update lib %L cell %L property bag\n" LIBRARY cn)
             error_flag = t
           )
         ))
    )
  )))

!error_flag))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   fdkCustomBuildCdfs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomBuildCdfs nil )
procedure(

  fdkCustomBuildCdfs(
    packages_tab LIBRARY cells
  )

let((error_flag)

  foreach( pack packages_tab
  when( stringp(pack)
  let((func_sym fpath func propbag_tab)
    cond(
      ( null(packages_tab[pack]->cdf_def_proc)
        fprintf(stderr "ERROR: no CDF definition for pack %L\n" pack)
        error_flag = t
      )
      ( length(packages_tab[pack]->cdf_def_proc) > 1
        fprintf(stderr "ERROR: Multiple SKILL files for pack %L CDF definitions\n" pack)
        foreach( fpath packages_tab[pack]->cdf_def_proc
          fprintf(stderr "       %L\n" fpath)
        )
        error_flag = t
      )
      ( progn(
          func_sym = stringToSymbol(sprintf(nil "fdkCdf_%s" pack))
          putd(func_sym nil)
          !errset(load(fpath = car(packages_tab[pack]->cdf_def_proc)) t)
        )
        fprintf(stderr "ERROR: Couldn't load file %L containing CDF definition procedure\n" fpath)
        error_flag = t
      )
      ( null(func = getd(func_sym))
        fprintf(stderr "ERROR: CDF def proc %L is not available after loading file %L\n" func_sym fpath)
        error_flag = t
      )
      ( null(propbag_tab = packages_tab[pack]->propbag_tab) || (length(propbag_tab) < 1)
        fprintf(stderr "ERROR: No property bag definitions associated with pack %L\n" pack)
        error_flag = t
      )
      ( t
        foreach( cn propbag_tab
        when( !cells || member(cn cells)
          when( !errset(apply(func list(LIBRARY cn)) t)
            fprintf(stderr "ERROR: Couldn't update lib %L cell %L CDF definition\n" LIBRARY cn)
            error_flag = t
          )
        ))
      )
    )
  )))

!error_flag))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   fdkCustomBuildPcells
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomBuildPcells nil )
procedure(

  fdkCustomBuildPcells(
    packages_tab LIBRARY cells
  )

let((error_flag)

  foreach( pack packages_tab
  when( stringp(pack)
  let((func_sym fpath func propbag_tab)
    cond(
      ( null(packages_tab[pack]->pcell_def_proc)
        warn("no Pcell definition for pack %L\n" pack)
      )
      ( length(packages_tab[pack]->pcell_def_proc) > 1
        fprintf(stderr "ERROR: Multiple SKILL files for pack %L Pcell definitions\n" pack)
        foreach( fpath packages_tab[pack]->pcell_def_proc
          fprintf(stderr "       %L\n" fpath)
        )
        error_flag = t
      )
      ( progn(
          func_sym = stringToSymbol(sprintf(nil "fdkPcell_%s" pack))
          putd(func_sym nil)
          !errset(load(fpath = car(packages_tab[pack]->pcell_def_proc)) t)
        )
        fprintf(stderr "ERROR: Couldn't load file %L containing Pcell definition procedure\n" fpath)
        error_flag = t
      )
      ( null(func = getd(func_sym))
        fprintf(stderr "ERROR: Pcell def proc %L is not available after loading file %L\n" func_sym fpath)
        error_flag = t
      )
      ( null(propbag_tab = packages_tab[pack]->propbag_tab) || (length(propbag_tab) < 1)
        fprintf(stderr "ERROR: No property bag definitions associated with pack %L\n" pack)
        error_flag = t
      )
      ( t
        foreach( cn propbag_tab
        when( !cells || member(cn cells)
          when( !errset(apply(func list(LIBRARY cn)) t)
            fprintf(stderr "ERROR: Couldn't update lib %L cell %L Pcell definition\n" LIBRARY cn)
            error_flag = t
          )
        ))
      )
    )
  )))

!error_flag))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomBuildUsage nil )
procedure(
  fdkCustomBuildUsage()
  printf("Use to redefine property bags, CDFs, or Pcell views in master custom library.\n")
  newline()
  printf("Usage:\n")
  newline()
  printf("  fdkCustomBuild(\n")
  printf("  ;One or more of the following keywords:\n")
  printf("    'propbags or 'nopropbags             ;Enables or suppresses building of property bags\n")
  printf("    'cdfs or 'nocdfs                     ;Enables or suppresses building of CDFs\n")
  printf("  ;NOTE: Enabling building of propbags Also enables building of cdfs, and vice versa\n")
  printf("    'pcells or 'nopcells                 ;Enables or suppresses building of Pcell views\n")
  printf("    'all                                 ;Enables building of prop bag, cdfs & Pcell views\n")
  printf("    'autocheckout or 'noautocheckout     ;Temporarily turns auto-checkout on or off\n")
  printf("    'report                              ;Dumps list of package/cell names matching ?pack & ?cell arg specs\n")
  printf("    ?pack <name> or ?packs list(<names>) ;Required list of package names\n")
  printf("      or ?packs 'all                     ;Use keyword 'all to apply build actions to all packages\n")
  printf("    [ ?cell <name> or ?cells list(<names>) ]  ;optional filtering list of cell names\n")
  printf("  )\n")
)
newline()
fdkCustomBuildUsage()
newline()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomBuild nil )
procedure(

  fdkCustomBuild(
  @key
    (pack nil) (packs nil)
    (cell nil) (cells nil)
    (LIBRARY "intel73custom")
  @rest
    actions
  )
  
let((propbag_flag cdf_flag pcell_flag autocheckout_flag report_flag
     error_flag build_pkgs_tab old_ctl_auto_vars)

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
  then fdkCustomBuildUsage()
  else

    foreach( action actions
      cond(
        ( member(action '(propbag propbags)) propbag_flag = cdf_flag = t )
        ( member(action '(nopropbag nopropbags)) propbag_flag = nil )
        ( member(action '(cdf cdfs)) propbag_flag = cdf_flag = t )
        ( member(action '(nocdf nocdfs)) cdf_flag = nil )
        ( member(action '(pcell pcells)) pcell_flag = t )
        ( member(action '(nopcell nopcells)) pcell_flag = nil )
        ( action == 'all  propbag_flag = cdf_flag = pcell_flag = t )
        ( action == 'autocheckout   autocheckout_flag = t )
        ( action == 'noautocheckout autocheckout_flag = nil )
        ( action == 'report         report_flag = t )
        ( t fprintf(stderr "ERROR: Unknown action keyword %L\n" action)
            error_flag = t )
      )
    )

    cond(
      ( error_flag
        fdkCustomBuildUsage()
      )
      ( (propbag_flag || cdf_flag || pcell_flag || report_flag) && null(packs) && null(cells)
        fprintf(stderr "ERROR: ?packs and/or ?cells arg must be specified.\n")
        fdkCustomBuildUsage()
        error_flag = t
      )
      ( !tablep(build_pkgs_tab = fdkScanCustomPackagesDir(packs ?LIBRARY LIBRARY ?cells cells)) ||
        (length(build_pkgs_tab) < 1)
        fprintf(stderr "ERROR: Couldn't find args%s%s in packages directory.\n"
          if( !null(packs) sprintf(nil " packs %L" packs) "" )
          if( !null(cells) sprintf(nil " cells %L" cells) "" )
        )
        error_flag = t
      )

    )

  )

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;; Enable autocheckout if requested
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  old_ctl_auto_vars = ddAutoCtlGetVars()
  if( autocheckout_flag
  then ddAutoCtlSetVars(0 0 3 0)
  else ddAutoCtlSetVars(0 0 0 0)
  )

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;; Dump the package info in the CIW if 'report argument was specified
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  when( !error_flag && report_flag
    fdkCustomBuildReport(build_pkgs_tab)
  )

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;; Make sure any library-common SKILL code is loaded if necesasry
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  when( !error_flag && (propbag_flag || cdf_flag || pcell_flag)
    error_flag = !fdkCustomLoad('common ?LIBRARY LIBRARY)
  )

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;; Apply the loaded property bag info if available
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  when( !error_flag && propbag_flag
    error_flag = !fdkCustomBuildPropBags(build_pkgs_tab LIBRARY cells)
  )

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;; Load the appropriate CDF definition functions & call them
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  when( !error_flag && cdf_flag
  let((selected_packs)
    selected_packs = foreach( mapcar p tableToList(build_pkgs_tab) car(p) )
   error_flag = !fdkCustomLoad('cdfs ?packs selected_packs ?LIBRARY LIBRARY)
    when( !error_flag
      error_flag = !fdkCustomBuildCdfs(build_pkgs_tab LIBRARY cells)
    )
  ))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;; Load the appropriate Pcell definition functions & call them
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  when( !error_flag && pcell_flag
  let((selected_packs)
    selected_packs = foreach( mapcar p tableToList(build_pkgs_tab) car(p) )
    error_flag = !fdkCustomLoad('pcells ?packs selected_packs ?LIBRARY LIBRARY)
    when( !error_flag
      error_flag = !fdkCustomBuildPcells(build_pkgs_tab LIBRARY cells)
    )
  ))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;; Restore autocheckout if it was changed
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  when( old_ctl_auto_vars != ddAutoCtlGetVars()
    apply('ddAutoCtlSetVars old_ctl_auto_vars)
  )

!error_flag))
