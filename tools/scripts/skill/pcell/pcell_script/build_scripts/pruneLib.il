; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
; (C) Copyright Intel Corporation, 2010
; Licensed material -- Program property of Intel Corporation
; All Rights Reserved
;
; This program is the property of Intel Corporation and is furnished
; pursuant to a written license agreement. It may not be used, reproduced,
; or disclosed to others except in accordance with the terms and conditions
; of that agreement.
;
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

ddAutoCtlSetVars(0 0 0 0)   ; Make sure DesignSync doesn't mess things up

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   GLOBALS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
lib_name2dd = makeTable('ValidLibNames nil)
found_cell_views = makeTable('FoundCellViewTab 0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   load_whitelist_config_file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'load_whitelist_config_file nil )
procedure(

  load_whitelist_config_file()
  
let((managed_area_dirpath dot_spec oalib_type fpath iport wlcfg tok)

  when( !stringp(managed_area_dirpath = getShellEnvVar("FDK_MANAGED_AREA")) || blankstrp(managed_area_dirpath)
    error("FDK_MANAGED_AREA env var not defined")
  )
  printf("FDK_MANAGED_AREA=%L\n" managed_area_dirpath)
  when( !stringp(dot_spec = getShellEnvVar("FDK_DOTPROC")) || blankstrp(dot_spec)
    error("FDK_DOTPROC env var not defined")
  )
  printf("FDK_DOTPROC=%L\n" dot_spec)
  when( !stringp(kit_name = getShellEnvVar("KIT_NAME")) || blankstrp(kit_name)
    error("KIT_NAME env var not defined")
  )
  printf("KIT_NAME=%L\n" kit_name)
  when( !stringp(oalib_type = getShellEnvVar("FDK_OALIB_TYPE")) || blankstrp(oalib_type)
    error("FDK_OALIB_TYPE env var not defined")
  )
  printf("FDK_OALIB_TYPE=%L\n" oalib_type)

  cond(
    ( isReadable(sprintf(fpath
        "%s/fdk73/misc/masterSheet/%s/%s_%s_oalib_cellview_whitelist.il.tab"
        managed_area_dirpath dot_spec kit_name oalib_type
      ))
      printf("Identified whitelist file %L\n" fpath)
    )
    ( isReadable(sprintf(fpath
        "%s/fdk73/misc/masterSheet/%s/%s_oalib_cellview_whitelist.il.tab"
        managed_area_dirpath dot_spec kit_name
      ))
      printf("Identified whitelist file %L\n" fpath)
    )
    ( isReadable(sprintf(fpath
        "%s/fdk73/misc/masterSheet/%s/%s_oalib_cellview_whitelist.il.tab"
        managed_area_dirpath dot_spec oalib_type
      ))
      printf("Identified whitelist file %L\n" fpath)
    )
    ( isReadable(sprintf(fpath
        "%s/fdk73/misc/masterSheet/%s/oalib_cellview_whitelist.il.tab"
        managed_area_dirpath dot_spec
      ))
      printf("Identified whitelist file %L\n" fpath)
    )
    ( t error(sprintf(nil
          "Didn't find valid whitelist file in %s/fdk73/misc/masterSheet/%s"
          managed_area_dirpath dot_spec
        ))
    )
  )

  when( !inportp(iport = infile(fpath))
    error(sprintf(nil "Couldn't open file '%s' for reading" fpath))
  )

  when( !errset( while( !null(tok = lineread(iport))
                  when( dtpr(tok)
                    wlcfg = cons(car(tok) wlcfg)
                  )
                )
        t)
    close(iport)
    error(sprintf(nil "Error while parsing whitelist file %L" fpath))
  )

  when( !close(iport)
    error(sprintf(nil "Couldn't close whitelist file %l after reading" fpath))
  )
  
  reverse(wlcfg)

))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   scan_symbol_hierarchy
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'scan_symbol_hierarchy nil )
procedure(

  scan_symbol_hierarchy(
    LIBRARY CELL VIEW
  )

let((cvId)
  when( found_cell_views[list(LIBRARY CELL VIEW)] == 0
  if( !null(cvId = dbOpenCellViewByType(LIBRARY CELL VIEW))
  then found_cell_views[list(cvId->libName cvId->cellName cvId->viewName)]++
       if( member(cvId->cellViewType '("schematicSymbol" "schematic"))
       then foreach( instId cvId->instances
	      if( !instId->master
	      then fprintf(stderr "MISSING_INST_MASTER=%s/%s/%s/%s(%s/%s/%s)\n" cvId->libName cvId->cellName cvId->viewName instId->name instId->libName instId->cellName instId->viewName)
	      else cond(
	             ( lib_name2dd[instId->libName]
	               scan_symbol_hierarchy(instId->libName instId->cellName instId->viewName)
		     )
		     ( !member(instId->libName '("basic" "analogLib" "intel73tech" "intel73prim"))
		       fprintf(stderr "INVALID_INST_MASTER=%s/%s/%s/%s(%s/%s/%s)\n" cvId->libName cvId->cellName cvId->viewName instId->name instId->libName instId->cellName instId->viewName)
		     )
	           )
	      )
	    )
       else fprintf(stderr "UNEXPECTED_CELL_VIEW_TYPE=%s/%s/%s(%s)\n" cvId->libName cvId->cellName cvId->viewName cvId->cellViewType)
       )
       when( !null(cvId) dbClose(cvId) )
  else fprintf(stderr "MISSING_SYMBOL_VIEW=%s/%s/%s\n" LIBRARY CELL VIEW)
  ))
))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   scan_layout_hierarchy
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'scan_layout_hierarchy nil )
procedure(

  scan_layout_hierarchy(
    LIBRARY CELL VIEW
  )
  
let((cvId cdfId)

  if( !null(cvId = dbOpenCellViewByType(LIBRARY CELL VIEW))
  then found_cell_views[list(cvId->libName cvId->cellName cvId->viewName)]++
       if( member(cvId->cellViewType '("maskLayout"))
       then foreach( instId cvId->instances
	      if( !instId->master
	      then fprintf(stderr "MISSING_INST_MASTER=%s/%s/%s/%s(%s/%s/%s)\n" cvId->libName cvId->cellName cvId->viewName instId->name instId->libName instId->cellName instId->viewName)
	      else cond(
	             ( lib_name2dd[instId->libName]
		       scan_layout_hierarchy(instId->libName instId->cellName instId->viewName)
		     )
		     ( !member(instId->libName '("basic" "analogLib" "intel73tech" "intel73prim"))
		       fprintf(stderr "INVALID_INST_MASTER=%s/%s/%s/%s(%s/%s/%s)\n" cvId->libName cvId->cellName cvId->viewName instId->name instId->libName instId->cellName instId->viewName)
		     )
		   )
	      )
	    )
	    ;;; If we are a Pcell & have a model parameter,
	    ;;; then we are probably a template & should walk
	    ;;; the layout hierarchy for all of the model cells as well.
	    ; when( dbCheckParamCell(cvId)
              ;;; Look for model names instantiated by Pcell
              ;;; Currently not enabled
	    ; )
       else fprintf(stderr "UNEXPECTED_CELL_VIEW_TYPE=%s/%s/%s(%s)\n" cvId->libName cvId->cellName cvId->viewName cvId->cellViewType)
       )
       when( !null(cvId) dbClose(cvId) )
  else fprintf(stderr "MISSING_LAYOUT_VIEW=%s/%s\n" LIBRARY CELL)
  )

))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   load_subckt_pin_tab
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'load_subckt_pin_tab nil )
procedure(

  load_subckt_pin_tab(
    fpath_list
  )
  
let((pin_tab)

  pin_tab = makeTable('SubcktPinTab nil)

  foreach( fpath fpath_list
  let((iport)

    if( inportp(iport = infile(fpath))

    then let((process_line li)

           process_line = lambda((s)
			  let((words modelName pin_name_list)
			  when( dtpr(words = setof(w parseString(s) !blankstrp(w)))
			    when( member(lowerCase(car(words)) '("subckt" ".subckt"))
			      when( dtpr(words = cdr(words))
	        		modelName = car(words)
				words = cdr(words)
				while( dtpr(words) && !rexMatchp("=" car(words))
				let((pin_name)
				  pin_name = car(words)
				  when( rexMatchp("[()]" pin_name)
				    pin_name = rexReplace(pin_name "" 0)
				  )
				  pin_name_list = cons(pin_name pin_name_list)
				  words = cdr(words)
				))
				pin_name_list = reverse(pin_name_list)
				pin_tab[modelName] = pin_name_list
                              )
        		    )
			  )))

           li = gets(li iport)
	   let((s)
           while( gets(s iport)
	     if( rexMatchp("^[+]" s)
	     then s = rexReplace(s "" 0)
		  li = strcat(li s)
             else funcall(process_line li)
	          li = s
	     )
	   ))

	   when( stringp(li)
	     funcall(process_line li)
	   )

         )

         when( !close(iport)
	   error(sprintf(nil "Couldn't finish reading '%s'" fpath))
	 )

    else error(sprintf(nil "Couldn't open '%s' for reading" fpath))

    )

  ))
  
  pin_tab

))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   check_cdl_netlisting_stop_view
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cdl_model_pin_tab = 
  let((fpaths fpath_list)
  when( stringp(fpaths = getShellEnvVar("CDL_MODELS_FPATHS"))
    when( dtpr(fpath_list = foreach( mapcar fpath setof(s parseString(fpaths) !blankstrp(s) && isReadable(s)) fpath))
      load_subckt_pin_tab(fpath_list)
    )
  ))

putd( 'check_cdl_netlisting_stop_view nil )
procedure(

  check_cdl_netlisting_stop_view(LIBRARY CELL)

let((cvId cdfId error_flag)

  cond(
    ( null(cvId = dbOpenCellViewByType(LIBRARY CELL "auCdl"))
      fprintf(stderr "MISSING_CDL_VIEW=%s/%s\n" LIBRARY CELL)
      error_flag = t
    )
    ( null(cdfId = cdfGetBaseCellCDF(ddGetObj(LIBRARY CELL)))
      fprintf(stderr "MISSING_BASE_CELL_CDF=%s/%s\n" LIBRARY CELL)
      error_flag = t
    )
    ( null(cdfId->simInfo) || null(cdfId->simInfo->auCdl)
      fprintf(stderr "MISSING_AUCDL_SIMINFO=%s/%s\n" LIBRARY CELL)
      error_flag = t
    )
    ( !boundp('cdl_model_pin_tab) || null(cdl_model_pin_tab)
      nil
    )
    ( t
      foreach( modelName if( null(cdfId->model) list(CELL) cdfId->model->choices )
      let((modelSpec)
      modelSpec = if( modelName != CELL sprintf(nil "%s(%s)" modelName CELL) CELL)
      cond(  
        ( null(cdl_model_pin_tab[modelName])
	  fprintf(stderr "MISSING_CDL_MODEL=%s\n" modelSpec)
          error_flag = t
        )
        ( null(cdfId->simInfo->auCdl->termOrder)
	  fprintf(stderr "MISSING_CDL_TERMORDER=%s\n" modelSpec)
          error_flag = t
        )
        ( (cdfId->simInfo->auCdl->termOrder != cdl_model_pin_tab[modelName])
	  fprintf(stderr "CDL_TERMORDER/MODELPINS_MISMATCH=%s:%L/%L\n" modelSpec
	    cdfId->simInfo->auCdl->termOrder cdl_model_pin_tab[modelName]
	  )
          error_flag = t
        )
      )))
    )
  )
  
  when( !null(cvId)
    when( !error_flag
      found_cell_views[list(cvId->libName cvId->cellName cvId->viewName)]++
    )
    dbClose(cvId)
    cvId = nil
  )

))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   check_hspice_netlisting_stop_view
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
hspice_model_pin_tab = 
  let((fpaths fpath_list)
  when( stringp(fpaths = getShellEnvVar("HSPICE_MODELS_FPATHS"))
    when( dtpr(fpath_list = foreach( mapcar fpath setof(s parseString(fpaths) !blankstrp(s) && isReadable(s)) fpath))
      load_subckt_pin_tab(fpath_list)
    )
  ))

putd( 'check_hspice_netlisting_stop_view nil )
procedure(

  check_hspice_netlisting_stop_view(LIBRARY CELL)

let((cvId cdfId error_flag)

  cond(
    ( null(cvId = dbOpenCellViewByType(LIBRARY CELL "hspiceD"))
      fprintf(stderr "MISSING_HSPICE_VIEW=%s/%s\n" LIBRARY CELL)
      error_flag = t
    )
    ( null(cdfId = cdfGetBaseCellCDF(ddGetObj(LIBRARY CELL)))
      fprintf(stderr "MISSING_BASE_CELL_CDF=%s/%s\n" LIBRARY CELL)
      error_flag = t
    )
    ( null(cdfId->simInfo) || null(cdfId->simInfo->hspiceD)
      fprintf(stderr "MISSING_HSPICE_SIMINFO=%s/%s\n" LIBRARY CELL)
      error_flag = t
    )
    ( !boundp('hspice_model_pin_tab) || null(hspice_model_pin_tab)
      nil
    )
    ( t
      foreach( modelName if( null(cdfId->model) list(CELL) cdfId->model->choices )
      let((modelSpec)
      modelSpec = if( modelName != CELL sprintf(nil "%s(%s)" modelName CELL) CELL)
      cond(  
        ( null(hspice_model_pin_tab[modelName])
	  fprintf(stderr "MISSING_HSPICE_MODEL=%s\n" modelSpec)
          error_flag = t
        )
        ( null(cdfId->simInfo->hspiceD->termOrder)
	  fprintf(stderr "MISSING_HSPICE_TERMORDER=%s\n" modelSpec)
          error_flag = t
        )
        ( (cdfId->simInfo->hspiceD->termOrder != hspice_model_pin_tab[modelName])
	  fprintf(stderr "HSPICE_TERMORDER/MODELPINS_MISMATCH=%s:%L/%L\n" modelSpec
	    cdfId->simInfo->hspiceD->termOrder hspice_model_pin_tab[modelName]
	  )
          error_flag = t
        )
      )))
    )
  )
  
  when( !null(cvId)
    when( !error_flag
      found_cell_views[list(cvId->libName cvId->cellName cvId->viewName)]++
    )
    dbClose(cvId)
    cvId = nil
  )

))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   check_spectre_netlisting_stop_view
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
spectre_model_pin_tab = 
  let((fpaths fpath_list)
  when( stringp(fpaths = getShellEnvVar("SPECTRE_MODELS_FPATHS"))
    when( dtpr(fpath_list = foreach( mapcar fpath setof(s parseString(fpaths) !blankstrp(s) && isReadable(s)) fpath))
      load_subckt_pin_tab(fpath_list)
    )
  ))

putd( 'check_spectre_netlisting_stop_view nil )
procedure(

  check_spectre_netlisting_stop_view(LIBRARY CELL)

let((cvId cdfId error_flag)

  cond(
    ( null(cvId = dbOpenCellViewByType(LIBRARY CELL "spectre"))
      fprintf(stderr "MISSING_SPECTRE_VIEW=%s/%s\n" LIBRARY CELL)
      error_flag = t
    )
    ( null(cdfId = cdfGetBaseCellCDF(ddGetObj(LIBRARY CELL)))
      fprintf(stderr "MISSING_BASE_CELL_CDF=%s/%s\n" LIBRARY CELL)
      error_flag = t
    )
    ( null(cdfId->simInfo) || null(cdfId->simInfo->spectre)
      fprintf(stderr "MISSING_SPECTRE_SIMINFO=%s/%s\n" LIBRARY CELL)
      error_flag = t
    )
    ( !boundp('spectre_model_pin_tab) || null(spectre_model_pin_tab)
      nil
    )
    ( t
      foreach( modelName if( null(cdfId->model) list(CELL) cdfId->model->choices )
      let((modelSpec)
      modelSpec = if( modelName != CELL sprintf(nil "%s(%s)" modelName CELL) CELL)
      cond(  
        ( null(spectre_model_pin_tab[modelName])
	  fprintf(stderr "MISSING_SPECTRE_MODEL=%s\n" modelSpec)
          error_flag = t
        )
        ( null(cdfId->simInfo->spectre->termOrder)
	  fprintf(stderr "MISSING_SPECTRE_TERMORDER=%s\n" modelSpec)
          error_flag = t
        )
        ( (cdfId->simInfo->spectre->termOrder != spectre_model_pin_tab[modelName])
	  fprintf(stderr "SPECTRE_TERMORDER/MODELPINS_MISMATCH=%s:%L/%L\n" modelSpec
	    cdfId->simInfo->spectre->termOrder spectre_model_pin_tab[modelName]
	  )
          error_flag = t
        )
      )))
    )
  )
  
  when( !null(cvId)
    when( !error_flag
      found_cell_views[list(cvId->libName cvId->cellName cvId->viewName)]++
    )
    dbClose(cvId)
    cvId = nil
  )

))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   check_cdl_hierarchy
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'check_cdl_hierarchy nil )
procedure(

  check_cdl_hierarchy(
    LIBRARY CELL
  )
  
let((cvId)

  if( !null(cvId = dbOpenCellViewByType(LIBRARY CELL "auCdl schematic"))
  then found_cell_views[list(cvId->libName cvId->cellName cvId->viewName)]++
       cond(
         ( member(cvId->cellViewType '("schematic"))
	   foreach( instId cvId->instances
	     if( !instId->master
	     then fprintf(stderr "MISSING_INST_MASTER=%s/%s/%s/%s(%s/%s/%s)\n" cvId->libName cvId->cellName cvId->viewName instId->name instId->libName instId->cellName instId->viewName)
	     else scan_symbol_hierarchy(instId->libName instId->cellName instId->viewName)
	          cond(
	            ( lib_name2dd[instId->libName]
	              check_cdl_hierarchy(instId->libName instId->cellName)
		    )
		    ( !member(instId->libName '("basic" "analogLib" "intel73tech" "intel73prim"))
		      fprintf(stderr "INVALID_INST_MASTER=%s/%s/%s/%s(%s/%s/%s)\n" cvId->libName cvId->cellName cvId->viewName instId->name instId->libName instId->cellName instId->viewName)
		    )
	          )
	     )
	   )
	   when( lib_name2dd[cvId->libName]
	     when( cvId->connectivityLastUpdated != dbGetCellViewCounter(cvId)
	       if( dbReopen(cvId "a")
	       then if( schCheck(cvId)
	            then when( !dbSave(cvId)
			   dbPurge(cvId)
			   cvId = nil
			 )
		    else dbPurge(cvId)
			 cvId = nil
		    )
	       else dbPurge(cvId)
	            cvId = nil
               )
	     )
	   )
	 )
	 ( !member(cvId->cellViewType '("schematicSymbol"))
	   fprintf(stderr "UNEXPECTED_CELL_VIEW_TYPE=%s/%s/%s(%s)\n" cvId->libName cvId->cellName cvId->viewName cvId->cellViewType)
	 )
	 ( t check_cdl_netlisting_stop_view(cvId->libName cvId->cellName) )
       )
       when( !null(cvId) dbClose(cvId) )
  else fprintf(stderr "MISSING_CDL_VIEW=%s/%s\n" LIBRARY CELL)
  )

))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   check_hspice_hierarchy
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'check_hspice_hierarchy nil )
procedure(

  check_hspice_hierarchy(
    LIBRARY CELL
  )
  
let((cvId)

  if( !null(cvId = dbOpenCellViewByType(LIBRARY CELL "hspiceD schematic"))
  then found_cell_views[list(cvId->libName cvId->cellName cvId->viewName)]++
       cond(
         ( member(cvId->cellViewType '("schematic"))
	   foreach( instId cvId->instances
	     if( !instId->master
	     then fprintf(stderr "MISSING_INST_MASTER=%s/%s/%s/%s(%s/%s/%s)\n" cvId->libName cvId->cellName cvId->viewName instId->name instId->libName instId->cellName instId->viewName)
	     else scan_symbol_hierarchy(instId->libName instId->cellName instId->viewName)
	          cond(
	            ( lib_name2dd[instId->libName]
	              check_hspice_hierarchy(instId->libName instId->cellName)
		    )
		    ( !member(instId->libName '("basic" "analogLib" "intel73tech" "intel73prim"))
		      fprintf(stderr "INVALID_INST_MASTER=%s/%s/%s/%s(%s/%s/%s)\n" cvId->libName cvId->cellName cvId->viewName instId->name instId->libName instId->cellName instId->viewName)
		    )
	          )
	     )
	   )
	   when( lib_name2dd[cvId->libName]
	     when( cvId->connectivityLastUpdated != dbGetCellViewCounter(cvId)
	       if( dbReopen(cvId "a")
	       then if( schCheck(cvId)
	            then when( !dbSave(cvId)
			   dbPurge(cvId)
			   cvId = nil
			 )
		    else dbPurge(cvId)
			 cvId = nil
		    )
	       else dbPurge(cvId)
	            cvId = nil
               )
	     )
	   )
	 )
	 ( !member(cvId->cellViewType '("schematicSymbol"))
	   fprintf(stderr "UNEXPECTED_CELL_VIEW_TYPE=%s/%s/%s(%s)\n" cvId->libName cvId->cellName cvId->viewName cvId->cellViewType)
	 )
	 ( t check_hspice_netlisting_stop_view(cvId->libName cvId->cellName) )
       )
       when( !null(cvId) dbClose(cvId) )
  else fprintf(stderr "MISSING_HSPICE_VIEW=%s/%s\n" LIBRARY CELL)
  )

))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   check_spectre_hierarchy
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'check_spectre_hierarchy nil )
procedure(

  check_spectre_hierarchy(
    LIBRARY CELL
  )
  
let((cvId)

  if( !null(cvId = dbOpenCellViewByType(LIBRARY CELL "spectre schematic"))
  then found_cell_views[list(cvId->libName cvId->cellName cvId->viewName)]++
       cond(
         ( member(cvId->cellViewType '("schematic"))
	   foreach( instId cvId->instances
	     if( !instId->master
	     then fprintf(stderr "MISSING_INST_MASTER=%s/%s/%s/%s(%s/%s/%s)\n" cvId->libName cvId->cellName cvId->viewName instId->name instId->libName instId->cellName instId->viewName)
	     else scan_symbol_hierarchy(instId->libName instId->cellName instId->viewName)
	          cond(
	            ( lib_name2dd[instId->libName]
	              check_spectre_hierarchy(instId->libName instId->cellName)
		    )
		    ( !member(instId->libName '("basic" "analogLib" "intel73tech" "intel73prim"))
		      fprintf(stderr "INVALID_INST_MASTER=%s/%s/%s/%s(%s/%s/%s)\n" cvId->libName cvId->cellName cvId->viewName instId->name instId->libName instId->cellName instId->viewName)
		    )
	          )
	     )
	   )
	   when( lib_name2dd[cvId->libName]
	     when( cvId->connectivityLastUpdated != dbGetCellViewCounter(cvId)
	       if( dbReopen(cvId "a")
	       then if( schCheck(cvId)
	            then when( !dbSave(cvId)
			   dbPurge(cvId)
			   cvId = nil
			 )
		    else dbPurge(cvId)
			 cvId = nil
		    )
	       else dbPurge(cvId)
	            cvId = nil
               )
	     )
	   )
	 )
	 ( !member(cvId->cellViewType '("schematicSymbol"))
	   fprintf(stderr "UNEXPECTED_CELL_VIEW_TYPE=%s/%s/%s(%s)\n" cvId->libName cvId->cellName cvId->viewName cvId->cellViewType)
	 )
	 ( t check_spectre_netlisting_stop_view(cvId->libName cvId->cellName) )
       )
       when( !null(cvId) dbClose(cvId) )
  else fprintf(stderr "MISSING_SPECTRE_VIEW=%s/%s\n" LIBRARY CELL)
  )

))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   prune_categories
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
category_lib_cell_set = makeTable('CategoryLibCellCnt 0)
putd( 'prune_categories nil )
procedure(

  prune_categories(
    libdd
    ddId
    cat_name
  )
  
let((catdd)

  if( null(catdd = ddCatOpen(ddId cat_name "a"))
  then fprintf(stderr "ERROR: Couldn't open category '%s' for editing.\n" cat_name)
  else printf("Opened category '%s'...\n" cat_name)
       foreach( cat_item ddCatGetCatMembers(catdd)
         apply( 
	   lambda((cat_item_name cat_item_type)
	     case( cat_item_type
	       ( "cell" if( ddGetObj(libdd->name cat_item_name)
                        then category_lib_cell_set[list(libdd->name cat_item_name)]++
                        else if( ddCatSubItem(catdd cat_item_name)
			     then printf("Removed cell '%s' from cateogry '%s'.\n" cat_item_name cat_name)
			     else fprintf(stderr "ERROR: Couldn't remove cell name '%s' from category '%s'.\n" cat_item_name cat_name)
			     )
		        )
	       )
	       ( "category" prune_categories(libdd catdd cat_item_name) )
	       ( t fprintf(stderr "ERROR: Unexpected cat type '%s' in category '%s'.\n" cat_item_type cat_name) )
	     )
	   )
           cat_item
	 )
       )
       if( null(ddCatGetCatMembers(catdd))
       then if( ddCatRemove(catdd)
	    then printf("Removed category '%s'.\n" cat_name)
	    else fprintf(stderr "ERROR: Couldn't remove empty category '%s'.\n" cat_name)
	    )
       else when( !ddCatSave(catdd)
              fprintf(stderr "ERROR: Couldn't save category '%s'.\n" cat_name)
	    )
	    when( !ddCatClose(catdd)
              fprintf(stderr "ERROR: Couldn't close category '%s'.\n" cat_name)
	    )
       )
  )

))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   prune_lib
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'prune_lib nil )
procedure(

  prune_lib()
  
let((wlcfg error_flag)

  ;;; Load the whitelist information
  when( !errset(setq(wlcfg load_whitelist_config_file()) t)
    err()
  )
  
  ;;; Save valid library names from the whitelist info
  foreach( lib_wlspec wlcfg
  let((lib_name libdd)

    cond(

      ( !dtpr(lib_wlspec) ||
        !stringp(lib_name = car(lib_wlspec)) ||
        blankstrp(lib_name)
        fprintf(stderr "ERROR: Syntax error parsing whitelist config file; SKILL token:\n")
        error_flag = t
      )

      ( null(libdd = ddGetObj(lib_name)) ||
        null(ddGetObj(nil nil nil "cdsinfo.tag" libdd))
        fprintf(stderr "ERROR: Couldn't get id for lib %L\n" lib_name)
        error_flag = t
      )
      
      ( !null(lib_name2dd[lib_name])
        fprintf(stderr "ERROR: Library name %L specified more than once in whitelist config file\n" lib_name)
        error_flag = t
      )
      
      ( t lib_name2dd[lib_name] = libdd )

    )

  ))

  when( error_flag
    err()
  )

  ;;; Scan every library and cell mentioned in the whitelist configuration  
  foreach( lib_wlspec wlcfg
  let((lib_name libdd)

    lib_name = car(lib_wlspec)
    libdd = lib_name2dd[lib_name]

    full_cell_name_set = makeTable('FullCellNameSet 0)

    foreach( cell_name lib_wlspec->top_symbol_views full_cell_name_set[cell_name]++ )
    foreach( cell_name lib_wlspec->netlisting_stop_views full_cell_name_set[cell_name]++ )
    foreach( cell_name lib_wlspec->top_schematic_views full_cell_name_set[cell_name]++ )
    foreach( cell_name lib_wlspec->top_layout_views full_cell_name_set[cell_name]++ )

    foreach( cell_name sort(foreach( mapcar l tableToList(full_cell_name_set) car(l) ) nil)

      when( member(cell_name lib_wlspec->top_symbol_views) scan_symbol_hierarchy(lib_name cell_name "symbol") )

      ;;; If we're supposed to have a symbol & netlisting views,
      ;;; and have a schematic view which is not on the top_schematic_views list,
      ;;; then we should have an interior symbol view
      when( member(cell_name lib_wlspec->top_symbol_views) &&
            member(cell_name lib_wlspec->netlisting_stop_views) &&
            !member(cell_name lib_wlspec->top_schematic_views) &&
            ddGetObj(lib_name cell_name "schematic") 
        scan_symbol_hierarchy(lib_name cell_name "interior")
      )

      when( member(cell_name lib_wlspec->top_layout_views) scan_layout_hierarchy(lib_name cell_name "layout") )

      when( member(cell_name lib_wlspec->netlisting_stop_views)
        check_cdl_netlisting_stop_view(lib_name cell_name)
        check_hspice_netlisting_stop_view(lib_name cell_name)
        check_spectre_netlisting_stop_view(lib_name cell_name)
      )

      when( member(cell_name lib_wlspec->top_schematic_views)
        scan_symbol_hierarchy(lib_name cell_name "schematic")
        check_cdl_hierarchy(lib_name cell_name)
        check_hspice_hierarchy(lib_name cell_name)
        check_spectre_hierarchy(lib_name cell_name)
      )

    )

  ))

  when( error_flag
    err()
  )

  ;;; Entering the pruning phase
  foreach( lib_wlspec wlcfg
  let((lib_name libdd)

    lib_name = car(lib_wlspec)
    libdd = lib_name2dd[lib_name]

    ;;; We can finally get around to removing anything we haven't registered
    foreach( cell_name foreach( mapcar celldd libdd->cells celldd->name )

      foreach( view_name foreach( mapcar viewdd ddGetObj(libdd->name cell_name)->views viewdd->name )

        when( found_cell_views[list(libdd->name cell_name view_name)] == 0
          when( ddDeleteObj(ddGetObj(libdd->name cell_name view_name nil nil "a"))
	    printf("Pruned cell view %s/%s/%s\n" libdd->name cell_name view_name)
          ) 
        )

      )

      ; If all of the cell views are gone,
      ; then get rid of the cell itself
      when( !ddGetObj(libdd->name cell_name)->views
        when( ddDeleteObj(ddGetObj(libdd->name cell_name nil nil nil "a"))
          printf("Pruned cell %s/%s\n" libdd->name cell_name)
        )
      )

    )

    ; Prunes any cells where no views exist for that cell,
    ; reports any cells which weren't mentioned somewhere in one of the categories.
    category_lib_cell_set = makeTable('CategoryLibCellCnt 0)
    foreach( cat_name ddCatGetLibCats(libdd)
      prune_categories(libdd libdd cat_name)
    )
    foreach( celldd libdd->cells
      when( category_lib_cell_set[list(libdd->name celldd->name)] == 0
        fprintf(stderr "UNCATEGORIZED_LIB_CELL=%s/%s\n", libdd->name celldd->name)
      )
    )

    ;;; Regenerate all the thumbnails for the library
    when( !hiGenerateThumbnails( ?lib libdd->name )
      fprintf(stderr "THUMBNAIL_GENERATION_ERROR=%s\n" libdd->name)
    )

    ;;; Report any remaining schematic cell views
    ;;; which were not explicitly marked in mastersheet
    foreach( cell_name sort(setof(celldd libdd->cells ddGetObj(nil nil "schematic" nil celldd))~>name nil)
      when( !member(cell_name lib_wlspec->top_schematic_views)
        fprintf(stderr "SCHEMATIC_CELL_VIEW_STILL_EXISTS=%s/%s\n" libdd->name cell_name)
      )
    )

  ))

t))

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;   MAIN
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
when( !errset(prune_lib() t)
  fprintf(stderr "ERROR: %L\n" errset.errset)
  exit(1)
)

exit(0)
