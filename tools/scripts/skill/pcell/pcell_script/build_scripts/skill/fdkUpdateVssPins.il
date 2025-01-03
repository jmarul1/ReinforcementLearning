;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Intel Top Secret                                                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copyright (C) 2014, Intel Corporation.  All rights reserved.             ;;
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

putd( 'fdkHasBothVssAndVssx nil )
procedure(

  fdkHasBothVssAndVssx(
    lib_nm cell_nm
    vss_name vssx_name
  )

let((has_both_vss_and_vssx)

  when( ddGetObj(lib_nm cell_nm "schematic" "master.tag")
  let((cvId)
    when( !null(cvId = dbOpenCellViewByType(lib_nm cell_nm "schematic"))
      when( member(cvId->cellViewType '("schematic"))
        when( !null(dbFindTermByName(cvId vssx_name)) &&
              (!null(dbFindTermByName(cvId vss_name)) ||
               dtpr(setof(instId cvId->instances member(instId->libName '("basic" "analogLib")) && (instId->cellName == vss_name))))
          has_both_vss_and_vssx = 't
        )
        cond(
          ( schExtractStatus(cvId) == "clean"
            printf("-I- Don't have to check-and-save %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
          )
          ( !dbReopen(cvId "a")
            fprintf(stderr "-E- Couldn't open %s/%s/%s for updating\n" cvId->libName cvId->cellName cvId->viewName)
          )
          ( !schCheck(cvId)
            fprintf(stderr "-E- %s/%s/%s check failed\n" cvId->libName cvId->cellName cvId->viewName)
          )
          ( !dbSave(cvId)
            fprintf(stderr "-E- Couldn't save %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
          )
        )
      )
      dbPurge(cvId)
    )
  ))

  has_both_vss_and_vssx

))

putd( 'fdkUpdateSymbolViewVssPins nil )
procedure(

  fdkUpdateSymbolViewVssPins(LIBRARY CELL vss_name vssx_name)

  foreach( viewdd setof(vdd ddGetObj(LIBRARY CELL)->views
                    ddGetObj(nil nil nil "master.tag" vdd) &&
                    !ddGetObj(nil nil nil "text.txt" vdd)
                  )
  let((cvId)
  
    if( null(cvId = dbOpenCellViewByType(LIBRARY CELL viewdd->name))
    then fprintf(stderr "-E- Couldn't open cell view %s/%s/%s\n" LIBRARY CELL viewdd->name)
    else when( member(cvId->cellViewType '("schematicSymbol"))
         let((vss_term_list)
           when( dtpr(vss_term_list = setof(termId cvId->terminals termId->name == vss_name))
             printf("%s/%s/%s: %d %s terms %L\n" cvId->libName cvId->cellName cvId->viewName length(vss_term_list) vss_name vss_term_list~>name)
             if( null(dbReopen(cvId "a"))
             then fprintf(stderr "Couldn't make cell view %s/%s/%s editable\n" cvId->libName cvId->cellName cvId->viewName)
             else CCSchangePinAndLabel(vss_name vssx_name cvId)
             )
           )
           when( cvId->modifiedButNotSaved
             if( dbSave(cvId)
             then printf("Check-and-saved cell view %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
             else fprintf(stderr "-E- Couldn't check-and-save cell view %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
             )
           )
         ))
         dbPurge(cvId)
    )
  
  ))

)

putd( 'fdkUpdateSchematicViewVssPins nil )
procedure(

  fdkUpdateSchematicViewVssPins(LIBRARY CELL vss_name vssx_name)

  foreach( viewdd setof(vdd ddGetObj(LIBRARY CELL)->views
                    ddGetObj(nil nil nil "master.tag" vdd) &&
                    !ddGetObj(nil nil nil "text.txt" vdd)
                  )
  let((cvId)
  
    if( null(cvId = dbOpenCellViewByType(LIBRARY CELL viewdd->name))
    then fprintf(stderr "-E- Couldn't open cell view %s/%s/%s\n" LIBRARY CELL viewdd->name)
    else when( member(cvId->cellViewType '("schematic"))
         let((vss_term_list vss_gbl_list)
           when( dtpr(vss_term_list = setof(termId cvId->terminals termId->name == vss_name))
             printf("%s/%s/%s: %d %s terms %L\n" cvId->libName cvId->cellName cvId->viewName length(vss_term_list) vss_name vss_term_list~>name)
             if( null(dbReopen(cvId "a"))
             then fprintf(stderr "Couldn't make cell view %s/%s/%s editable\n" cvId->libName cvId->cellName cvId->viewName)
             else CCSchangePinAndLabel(vss_name vssx_name cvId)
             )
           )
           when( dtpr(vss_gbl_list = setof(instId cvId->instances member(instId->libName '("basic" "analogLib")) && instId->cellName == "vss"))
           let((can_update_vss_global)
             printf("%s/%s/%s: %d vss global symbols\n" cvId->libName cvId->cellName cvId->viewName length(vss_gbl_list))
             can_update_vss_global = let((symbol_cvId flag)
                                       when( ddGetObj(LIBRARY CELL "symbol" "master.tag")
                                         symbol_cvId = dbOpenCellViewByType(LIBRARY CELL "symbol")
                                         flag = !null(dbFindTermByName(symbol_cvId vssx_name))
                                         dbClose(symbol_cvId)
                                         flag
                                       )
                                     )
             if( can_update_vss_global
             then if( null(dbReopen(cvId "a"))
                  then fprintf(stderr "Couldn't make cell view %s/%s/%s editable\n" cvId->libName cvId->cellName cvId->viewName)
                  else vss_gbl_list = setof(instId cvId->instances member(instId->libName '("basic" "analogLib")) && instId->cellName == "vss")
                       while( !null(vss_gbl_list)
                       let((instId new_xform new_pin)
                         instId = car(vss_gbl_list)
                         new_xform = dbConcatTransform(instId->transform list(0:0 "R90"))
                         new_pin = schCreatePin(cvId dbOpenCellViewByType("basic" "iopin" "symbolr")
                                     vssx_name "inputOutput" nil instId->xy cadr(new_xform)
                                   )
                         dbDeleteObject(instId)
                         vss_gbl_list = cdr(vss_gbl_list)
                       ))
                  )
             else fprintf(stderr "-E- Need to update vss global in cell view %s/%s/%s, but symbol does not have matching vssx pin.\n" cvId->libName cvId->cellName cvId->viewName)
             )
           ))
           when( cvId->modifiedButNotSaved
             if( schCheck(cvId) && dbSave(cvId)
             then printf("Check-and-saved cell view %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
             else fprintf(stderr "-E- Couldn't check-and-save cell view %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
             )
           )
         ))
         dbPurge(cvId)
    )
  
  ))

)

putd( 'fdkUpdateLayoutViewVssPins nil )
procedure(

  fdkUpdateLayoutViewVssPins(LIBRARY CELL vss_name vssx_name)

  foreach( viewdd setof(vdd ddGetObj(LIBRARY CELL)->views
                    ddGetObj(nil nil nil "master.tag" vdd) &&
                    !ddGetObj(nil nil nil "text.txt" vdd)
                  )
  let((cvId)
  
    if( null(cvId = dbOpenCellViewByType(LIBRARY CELL viewdd->name))
    then fprintf(stderr "-E- Couldn't open cell view %s/%s/%s\n" LIBRARY CELL viewdd->name)
    else when( !cvId->isParamCell && member(cvId->cellViewType '("maskLayout"))
         let((vss_term_list pwellSubIso_lbl_list)
           when( dtpr(vss_term_list = setof(termId cvId->terminals termId->name == vss_name))
             printf("%s/%s/%s: %d %s terms %L\n" cvId->libName cvId->cellName cvId->viewName length(vss_term_list) vss_name vss_term_list~>name)
             if( null(dbReopen(cvId "a"))
             then fprintf(stderr "-E- Couldn't make cell view %s/%s/%s editable\n" cvId->libName cvId->cellName cvId->viewName)
             else CCSchangePinAndLabel(vss_name vssx_name cvId)
             )
             when( ddGetObj(LIBRARY CELL "symbol" "master.tag")
               when( !dtpr(pwellSubIso_lbl_list = setof(figId cvId->shapes figId->objType == "label" && figId->lpp == list("pwellSubIso" "id") && figId->theLabel == vssx_name))
               let((x1 y1 x2 y2 x y)
                 foreach( figId setof(figId cvId->shapes figId->objType != "label")
                   when( null(x1) || leftEdge(figId) < x1 x1 = leftEdge(figId) )
                   when( null(y1) || bottomEdge(figId) < y1 y1 = bottomEdge(figId) )
                   when( null(x2) || rightEdge(figId) > x2 x2 = rightEdge(figId) )
                   when( null(y2) || topEdge(figId) > y2 y2 = topEdge(figId) )
                 )
                 x = min(x2 max(x1 0.0))
                 y = min(y2 max(y1 0.0))
                 if( null(dbReopen(cvId "a"))
                 then fprintf(stderr "Couldn't make cell view %s/%s/%s editable\n" cvId->libName cvId->cellName cvId->viewName)
                 else dbCreateLabel( cvId list("pwellSubIso" "id") x:y vssx_name "lowerLeft" "R0" "stick" 0.01 )
                 )
               ))
             )
           )
           when( cvId->modifiedButNotSaved
             if( dbSave(cvId)
             then printf("Saved cell view %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
             else fprintf(stderr "-E- Couldn't save cell view %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
             )
           )
         ))
         dbPurge(cvId)
    )
  
  ))

)

putd( 'fdkUpdateVssPins nil )
procedure(

  fdkUpdateVssPins(
  @key
    (lib_nm "intel73custom")
    (cells  nil)
    (vss_name "vss")
    (vssx_name "vssx")
    (autocheckout nil)
  )

let((libdd old_ctl_vars)

  when( null(libdd = ddGetObj(lib_nm)) || !ddGetObj(nil nil nil "cdsinfo.tag" libdd)
    error(sprintf(nil "Couldn't get lib %L id" lib_nm))
  )

  when( null(cells)
    cells = libdd->cells~>name
  )
  when( stringp(cells)
    cells = list(cells)
  )
  
  when( autocheckout
    old_ctl_vars = ddAutoCtlGetVars()
    ddAutoCtlSetVars(0 0 3 0)
  )

  foreach( cell_nm cells
    when( !fdkHasBothVssAndVssx(lib_nm cell_nm vss_name vssx_name)
      fdkUpdateSymbolViewVssPins(lib_nm cell_nm vss_name vssx_name)
      fdkUpdateSchematicViewVssPins(lib_nm cell_nm vss_name vssx_name)
      fdkUpdateLayoutViewVssPins(lib_nm cell_nm vss_name vssx_name)
    )
  )
  
  when( autocheckout
    apply( 'ddAutoCtlSetVars old_ctl_vars )
  )

))
