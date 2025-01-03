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

putd( 'fdkGetM0OverlayCellNameList nil )
procedure(
  
  fdkGetM0OverlayCellNameList(
    libdd
  )

let((error_flag catId cell_names)

  if( null(catId = ddCatFindCat(libdd "m0_overlays" "r"))
  then fprintf(stderr "ERROR: Couldn't open %L category file\n" "m0_overlays")
       error_flag = t
  else foreach( cat_item ddCatGetCatMembers(catId)
         apply( 
           lambda((nm typ)
             if( !member(typ '("cell"))
             then fprintf(stderr "ERROR: Unexpected item %L in %L category\n" nm ddCatGetCatName(catId))
                  error_flag = t
             else when( !member(nm cell_names) cell_names = cons(nm cell_names) )
             )
           )
           cat_item
         )
       )
       ddCatClose(catId)
  )

  when( error_flag err() )

  cell_names

))

putd( 'fdkRemoveLibMc0Shapes nil )
procedure(

  fdkRemoveLibMc0Shapes(
  @key
    ( lib "intel73custom" )
    ( cells nil )
    ( autocheckout nil )
  )

let((old_ctl_vars libdd m0_overlay_cell_names celldd_list)

  when( autocheckout
    old_ctl_vars = ddAutoCtlGetVars()
    ddAutoCtlSetVars(0 0 3 0)
  )

  when( null(libdd = ddGetObj(lib))
    error(sprintf(nil "Couldn't get id for lib %L" lib))
  )

  when( null(m0_overlay_cell_names = fdkGetM0OverlayCellNameList(libdd))
    error(sprintf(nil "Could not find %L category" "m0_overlays"))
  )
  
  when( !dtpr(celldd_list = setof(cdd libdd->cells null(cells) || member(cdd->name cells)))
    error(sprintf(nil "Couldn't get list of cell names for lib %L" lib))
  )

  foreach( celldd celldd_list
    if( member(celldd->name m0_overlay_cell_names)
    then printf("SKIPPED: %s/%s (was in m0_overlays category)\n" libdd->name celldd->name)
    else foreach( viewdd celldd->views
           when( !null(cvId = dbOpenCellViewByType(libdd->name celldd->name viewdd->name))
           let((fig_list)
             when( dtpr(fig_list = setof(figId cvId->shapes member(figId->layerName '("mc0"))))
               printf("MATCH: %s/%s/%s (%L shapes)\n" cvId->libName cvId->cellName cvId->viewName length(fig_list))
               if( !dbReopen(cvId "a")
               then fprintf(stderr "ERROR: Couldn't open cell view %s/%s/%s for editing\n" cvId->libName cvId->cellName cvId->viewName)
                    error_flag = t
               else fig_list = setof(figId cvId->shapes member(figId->layerName '("mc0")))
                    while( dtpr(fig_list)
                      dbDeleteObject(car(fig_list))
                      fig_list = cdr(fig_list)
                    )
                    when( !dbSave(cvId)
                      fprintf(stderr "ERROR: Couldn't save cell view %s/%s/%s data\n"  cvId->libName cvId->cellName cvId->viewName)
                      error_flag = t
                    )

               )
               dbClose(cvId)
             )
           ))
         )
    )
  )
  
  when( autocheckout
    apply( 'ddAutoCtlSetVars old_ctl_vars )
  )

))

fdkRemoveLibMc0Shapes(?lib LIBRARY ?cells CELLNAME ?autocheckout t)

