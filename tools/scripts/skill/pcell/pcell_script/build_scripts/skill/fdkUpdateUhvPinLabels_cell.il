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

defvar( fdkUpdateUhvPinLabels_RCPR_CELL_NAMES '("d8xsrcprtguvm2a_float" "d8xsrcprtguvm2b_float" "d8xsrcprtguvm2c_float" "d8xsrcprtguvm2a" "d8xsrcprtguvm2a_base" "d8xsrcprtguvm2b" "d8xsrcprtguvm2b_base" "d8xsrcprtguvm2c" "d8xsrcprtguvm2c_base") )
defvar( fdkUpdateUhvPinLabels_RTCN_CELL_NAMES '("d8xsrtcnuvm2vtun" "d8xsrtcnuvm2vtun_base" "d8xsrtcnuvm2p5vtun" "d8xsrtcnuvm2p5vtun_base") )

putd( 'fdkUpdateCellViewsUhvPinLabels nil )
procedure(

  fdkUpdateCellViewsUhvPinLabels(ln cn src_regex dest_repl)

let((cvId error_flag)

  foreach( vdd setof(vdd ddGetObj(ln cn)->views ddGetObj(nil nil nil "master.tag" vdd) && !ddGetObj(nil nil nil "text.txt" vdd))
  let((cvId)
    if( null(cvId = dbOpenCellViewByType(ln cn vdd->name))

    then fprintf(stderr "ERROR: Couldn't open cell view %s/%s/%s\n" ln cn vdd->name)
         error_flag = t

    else when( member(cvId->cellViewType '("maskLayout"))
         let((pin_tab pin_list)

           pin_tab = makeTable('fdkUpdateCellViewsUhvPinLabelsPinTab 0)

           foreach( termId cvId->terminals
             when( rexMatchp(src_regex termId->name)
               pin_tab[termId->name]++
             )
           )

           foreach( lblId setof(figId cvId->shapes figId->objType == "label" && cadr(figId->lpp) == "pin")
             when( rexMatchp(src_regex lblId->theLabel)
               pin_tab[lblId->theLabel]++
             )
           )

           if( !dtpr(pin_list = foreach( mapcar pr tableToList(pin_tab) car(pr) ))

           then printf("Skipping cell view %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)

           else if( !dbReopen(cvId "a")

                then fprintf(stderr "ERROR: Couldn't open cell view %s/%s/%s for editing\n" ln cn vdd->name)
                     error_flag = t

                else foreach( oldName pin_list
                     when( rexMatchp(src_regex oldName)
                     let((newName)
                       newName = rexReplace(oldName dest_repl 0)
                       if( dbFindTermByName(cvId oldName)
                       then printf("Found term %L in cell view %s/%s/%s\n" oldName cvId->libName cvId->cellName cvId->viewName)
                            when( !errset(CCSchangePinAndLabel(oldName newName cvId) t)
                              error_flag = t
                            )
                       else let((lbls)
                         lbls = setof(figId cvId->shapes figId->objType == "label" && figId->theLabel == oldName)
                         lbls~>theLabel = newName
                         printf("Changed all %L labels to %L\n" oldName newName)
                       ))
                     )))

                     when( cvId->modifiedButNotSaved
                       if( dbSave(cvId)
                       then printf("Saved cell view %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
                       else fprintf(stderr "ERROR: Couldn't save cell view %s/%s/%s\n" ln cn vdd->name)
                            error_flag = t
                       )
                     )

                )

           )
           
         ))

         dbClose(cvId)
    )
  ))

error_flag))

putd( 'fdkUpdateUhvPinLabels nil )
procedure(

  fdkUpdateUhvPinLabels(
    @key
      (ln "intel73custom")
      (cells append(fdkUpdateUhvPinLabels_RCPR_CELL_NAMES fdkUpdateUhvPinLabels_RTCN_CELL_NAMES))
      (cellname "")
  )
  
let((old_ctl_vars libdd error_flag)

  old_ctl_vars = ddAutoCtlGetVars()
  ddAutoCtlSetVars(0 0 3 0)

  ;if( !ddGetObj(ln nil nil "cdsinfo.tag")
  if( !ddGetObj(ln cellname)
  then fprintf(stderr "ERROR: Invalid lib name %L, cellname %L\n" ln,cellname)
       error_flag = t
  else 
       ;foreach( cn cells
         if( !ddGetObj(ln cellname)
         then fprintf(stderr "ERROR: Invalid lib %L cell name %L\n" ln cellname)
              error_flag = t
         else cond(
                  ( member( cellname fdkUpdateUhvPinLabels_RCPR_CELL_NAMES )
                    when( !fdkUpdateCellViewsUhvPinLabels(ln cellname "_uhv$" "_cpr")
                      error_flag = t
                    )
                  )
                  ( member( cellname fdkUpdateUhvPinLabels_RTCN_CELL_NAMES )
                    when( !fdkUpdateCellViewsUhvPinLabels(ln cellname "_uhv$" "_tcn")
                      error_flag = t
                    )
                  )
                  ( t fprintf(stderr "ERROR: Cell name %L does not match one of predefined RCPR or RCTN cells\n" cellname) )
                )
         )
       ;)
  )
  
  apply( 'ddAutoCtlSetVars old_ctl_vars )

error_flag))

fdkUpdateUhvPinLabels(?ln LIBRARY ?cellname CELLNAME)
