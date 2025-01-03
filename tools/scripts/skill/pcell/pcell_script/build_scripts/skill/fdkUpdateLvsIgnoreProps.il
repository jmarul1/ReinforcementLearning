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

putd( 'fdkUpdateLvsIgnoreProps nil )
procedure(

  fdkUpdateLvsIgnoreProps(
    LIBRARY
  @key
    (write_flag nil)
  )

let((old_ctl_set_vars error_flag libdd)

  when( !null(write_flag)
    old_ctl_set_vars = ddAutoCtlGetVars()
  )

  hiResetAbort()

  when( null(libdd = ddGetObj(LIBRARY))
    error_flag = fprintf(stderr "Couldn't get id for library %L\n" LIBRARY)
  )
  
  foreach( celldd libdd->cells
  when( !hiCheckAbort()
  when( ddGetObj(nil nil "layout" "master.tag" celldd)
  let((cvId)
    when( !null(cvId = dbOpenCellViewByType(libdd->name celldd->name "layout"))
    when( !dbCheckParamCell(cvId)
    let((propId)
      if( ddGetObj(nil nil "symbol" "master.tag" celldd) || ddGetObj(nil nil "schematic" "master.tag" celldd)
      then cond(
             ( null(propId = dbFindProp(cvId "lvsIgnore"))
               printf("No lvsIgnore property, no changes necessary for cell view %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
             )
             ( null(write_flag) && (propId->value == "FALSE")
               warn("Cell view %s/%s/%s has lvsIgnore property, but its value is %L\n" cvId->libName cvId->cellName cvId->viewName propId->value)
             )
             ( null(write_flag) && (propId->value == "TRUE")
               error_flag = fprintf(stderr "Cell view %s/%s/%s has lvsIgnore property with value %L\n" cvId->libName cvId->cellName cvId->viewName propId->value)
             )
             ( !(dbReopen(cvId "a") && dbOpenHier(cvId 1))
               error_flag = fprintf(stderr "Couldn't reopen cell view %s/%s/%s for updating\n" cvId->libName cvId->cellName cvId->viewName)
             )
             ( null(propId = dbFindProp(cvId "lvsIgnore"))
               error_flag = fprintf(stderr "Couldn't get writable id for lvsIgnore propId in cell view %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
             )
             ( !dbDeleteObject(propId)
               fprintf(tsderr "Couldn't remove lvsIgnore propId from cell view %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
             )
             ( !dbSave(cvId)
               error_flag = fprintf(stderr "Couldn't save updated cell view %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
             )
             ( t printf("Removed lvsIgnore property from cell view %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName) )
             )
      else cond(
             ( !null(propId = dbFindProp(cvId "lvsIgnore")) && (propId->value == "TRUE")
               printf("lvsIgnore property already set to %L, no changes necessary for cell view %s/%s/%s\n" propId->value cvId->libName cvId->cellName cvId->viewName)
             )
             ( null(write_flag) && !null(propId) && (propId->value == "FALSE")
               error_flag = fprintf(stderr "Cell view %s/%s/%s has lvsIgnore property with value %L\n" cvId->libName cvId->cellName cvId->viewName propId->value)
             )
             ( null(write_flag)
               error_flag = fprintf(stderr "Cell view %s/%s/%s has no lvsIgnore property\n" cvId->libName cvId->cellName cvId->viewName)
             )
             ( !(dbReopen(cvId "a") && dbOpenHier(cvId 1))
               error_flag = fprintf(stderr "Couldn't reopen cell view %s/%s/%s for updating\n" cvId->libName cvId->cellName cvId->viewName)
             )
             ( null(propId = dbReplaceProp(cvId "lvsIgnore" 'boolean "TRUE"))
               error_flag = fprintf(stderr "Couldn't set lvsIgnore property in cell view %s/%s/%s to \"TRUE\"\n" cvId->libName cvId->cellName cvId->viewName)
             )
             ( !dbSave(cvId)
               error_flag = fprintf(stderr "Couldn't save updated cell view %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
             )
             ( t printf("Set lvsIgnore property in cell view %s/%s/%s to %L\n" cvId->libName cvId->cellName cvId->viewName propId->value) )
           )

      )
      dbClose(cvId)
    )))
  ))))

  hiResetAbort()

  when( !null(old_ctl_set_vars)
    apply( 'ddAutoCtlSetVars old_ctl_set_vars )
  )

error_flag))
