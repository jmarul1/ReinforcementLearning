;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Intel Top Secret                                                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copyright (C) 2015, Intel Corporation.  All rights reserved.             ;;
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

printf("\nUsage: fdkCustomImportCellView LIBRARY CELL VIEW1 VIEW2 sourceID\n")
printf("         [ ?src_lib_nm \"intel73custom\" ]\n")
printf("         [ ?src_lib_hier t|nil ]\n")
printf("         [ ?custom_lib_nm \"intel73custom\" ]\n")
putd( 'fdkCustomImportCellView nil )
procedure(
  fdkCustomImportCellView(
    LIBRARY CELL VIEW1 VIEW2
    sourceID ; example: "e8lib:v44732"
  @key
    (src_lib_nm "intel73custom")    ; if lib name embedded in instances from source library
                                    ; isn't the same as LIBRARY
    (src_lib_hier nil)              ; don't copy hierarchically by default
    ;(custom_lib_nm "intel73custom") ; default library name to use for cells targeted to custom library
    (custom_lib_nm "pajgaonk_p6") ; default library name to use for cells targeted to custom library
    "ttttttgtt"
  )

let((
    customDestCnt
    customDestList
    customSrcList
    cv_copy_list
    err_flag
    old_ctl_vars
    import_text_view_list
  )

  when( blankstrp(LIBRARY) || blankstrp(CELL) ||  blankstrp(VIEW1) 
    error("LIBRARY, CELL & VIEW1 arguments must be non-blank")
  )

  when( blankstrp(sourceID)
    error("sourceID argument must be non-blank")
  )
 ;;; build an ordered list of all of the cell views we want to copy from the source library
  cv_copy_list =  ;_fdkCustomGenerateWithinLibHierarchy(LIBRARY CELL VIEW ?src_lib_nm src_lib_nm)
    if( !member(VIEW1 '("data.dm")) && booleanp(src_lib_hier) && src_lib_hier
    then _fdkCustomGenerateWithinLibHierarchy(LIBRARY CELL VIEW1 ?src_lib_nm src_lib_nm)
    else list(list(LIBRARY CELL VIEW1))
    )

 ;;; code to check if cell has import text view and if it exists read it 
  ;prog(()
  ;foreach( view2 ddGetObj(LIBRARY CELL)->views~>name 
  ;  if(member(view2 '("import"))
  ;     then  import_text_view_list = _fdkCustomGenerateWithinLibHierarchy(LIBRARY CELL VIEW1 ?src_lib_nm src_lib_nm)
  ;     if(ddGetObj(LIBRARY CELL view2 "text.txt") then 
  ;       file_path = ddGetObjReadPath(ddGetObj(LIBRARY CELL view2 "text.txt"))
  ;     	 printf("view2 %s\n",view2)
  ;       printf("import_text_view_list %L\n",import_text_view_list)
  ;     ;;; code to read import text view and execute functions mentioned in the import text view
  ;       inPort = infile(file_path)
  ;       while(gets(line inPort)
  ;         printf("line - %s\n",line)
  ;       )
  ;       close(inPort)
  ;       inPort=nil
  ;     )
  ;  return()
  ;  else list(list())
  ;  ) 
  ;)
  ;)

;;
  ;prog(()
  ;foreach( view2 ddGetObj(custom_lib_nm CELL)->views~>name 
  ;  print("custom_lib_nm")
  ;  print(custom_lib_nm)
  ;  if(member(view2 '("import"))
  ;     then  import_text_view_list = _fdkCustomGenerateWithinLibHierarchy(custom_lib_nm CELL VIEW1 ?src_lib_nm src_lib_nm)
  ;     if(ddGetObj(custom_lib_nm CELL view2 "text.txt") then 
  ;       file_path = ddGetObjReadPath(ddGetObj(custom_lib_nm CELL view2 "text.txt"))
  ;     	 printf("view2 %s\n",view2)
  ;       printf("import_text_view_list %L\n",import_text_view_list)
       ;;; code to read import text view and execute functions mentioned in the import text view
  ;       inPort = infile(file_path)
  ;       while(gets(line inPort)
  ;         printf("line - %s\n",line)
  ;      )
  ;       close(inPort)
  ;       inPort=nil
  ;     )
  ;  return()
  ;  else list(list())
  ;  ) 
  ;)
  ;)

  ;  if(import_text_view_list then
  ;    printf("import option chosen and import_text_view_list not empty. import_text_view_list = %L\n",import_text_view_list)
  ;    import_text_view_list ='unbound 
  ;  )

 ;;; code to read import text view and execute functions mentioned in the import text view 
 
 
 ;;; build up the lists we are going to use for copying
  customSrcList = gdmCreateSpecList()
  customDestList = gdmCreateSpecList()
  customDestCnt = 0

  foreach( cv_item cv_copy_list
  apply(
    lambda((src_lib_nm cell_nm src_view_nm)
    let((srcList destList dest_lib_nm) 
    customDestCnt++
    srcList = customSrcList
    destList = customDestList
    dest_lib_nm = custom_lib_nm 

    printf("%s\n", dest_lib_nm)

    dest_view_nm =
        cond(
          ( ddGetObj(LIBRARY cell_nm "symbol" "master.tag") &&
            ddGetObj(LIBRARY cell_nm "symbol1" "master.tag") &&
            member(VIEW '("symbol1"))
            "symbol"
          )
          ( ddGetObj(LIBRARY cell_nm "symbol" "master.tag") &&
            ddGetObj(LIBRARY cell_nm "symbol1" "master.tag") &&
            member(VIEW '("symbol"))
            "symbol1"
          )
          ( t VIEW1 )
        )
      printf("%s\n", dest_view_nm) 
      src = if( member(src_view_nm '("data.dm"))
            then gdmCreateSpec(src_lib_nm cell_nm "" src_view_nm "CDBA")
            else gdmCreateSpec(src_lib_nm cell_nm src_view_nm "" "CDBA")
            )
      printf("%s\n" src)
      gdmAddSpecToSpecList(src srcList)
      dest = if( member(dest_view_nm '("data.dm"))
             then gdmCreateSpec(dest_lib_nm cell_nm "" dest_view_nm "CDBA")
             else gdmCreateSpec(dest_lib_nm cell_nm dest_view_nm "" "CDBA")
             )

      gdmAddSpecToSpecList(dest destList)
      printf("%s\n", dest)
      printf("%s\n", destList)
      printf("%s\n", srcList)
      printf("%s\n", src_view_nm)
     t))
    cv_item
  ))

  ;;; use auto-checkout (but not autocheckin)
    old_ctl_vars = ddAutoCtlGetVars()
  ddAutoCtlSetVars(0 0 3 0)

  when( customDestCnt > 0
    if( !ccpCopy(customSrcList customDestList 't 'CCP_EXPAND_ALL)
    then fprintf(stderr "Copy unsuccessful\n")
         err_flag = t
    else gdmResetSpecList(customDestList)
         while( !null(destSpec = gdmNextFromSpecList(customDestList))
         let((dest)
           dest = gdmInspectSpec(destSpec)
           apply(
             lambda((lib_nm cell_nm view_nm file_nm)
             when( !blankstrp(view_nm || "") && blankstrp(file_nm || "")
             let((cvId)
               if( null(cvId = dbOpenCellViewByType(lib_nm cell_nm view_nm nil "a"))
               then fprintf(stderr "Couldn't open cell view %s/%s/%s for modifying\n" lib_nm cell_nm view_nm)
                    err_flag = 't
               else ;;; add sourceID property
                    when( dbReplaceProp(cvId "sourceID" "string" sourceID)
                      printf("Set sourceID prop for cell view %s/%s/%s to %L\n" cvId->libName cvId->cellName cvId->viewName sourceID)
                    )
                    _fdkCustomRebindCopiedCellViews(
                      LIBRARY src_lib_nm
                      cvId
                      custom_lib_nm
                      custom_lib_nm
)
                    dbPurge(cvId)
               )
             )))
             dest
           )
         ))
    )
  )
apply( 'ddAutoCtlSetVars old_ctl_vars )

  when( err_flag err() )
;*/
))


;;;;;;;;;;;;;;;;;;;;;
putd( '_fdkCustomGenerateWithinLibHierarchy nil )
procedure(

  _fdkCustomGenerateWithinLibHierarchy(
    LIBRARY CELL VIEW
  @key
    (src_lib_nm "intel73custom")
  )

let((cvId cv_list)

  if( null(cvId = dbOpenCellViewByType(LIBRARY CELL VIEW))
  then fprintf(stderr "Couldn't open cell view %s/%s/%s\n" LIBRARY CELL VIEW)
  else
    foreach( instId cvId->instances
      printf("%s\n", instId)
      when( member(instId->libName list(LIBRARY src_lib_nm))
      printf("%s\n", instId->libName)
      let((sub_cv_list)
        sub_cv_list = _fdkCustomGenerateWithinLibHierarchy(
                        LIBRARY instId->cellName instId->viewName
                        ?src_lib_nm src_lib_nm
                      )
        foreach( sub_cv sub_cv_list
          when( !member(sub_cv cv_list)
            cv_list = cons(sub_cv cv_list)
          )
        )
      ))
    )
    dbClose(cvId)
  )

  when( !member(list(LIBRARY CELL VIEW) cv_list)
    cv_list = cons(list(LIBRARY CELL VIEW) cv_list)
  )

  reverse(cv_list)

))


;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( '_fdkCustomRebindCopiedCellViews nil )
procedure(

  _fdkCustomRebindCopiedCellViews(
    LIBRARY src_lib_nm
    cvId
    dest_lib_nm
    custom_lib_nm
  )

let(()

  foreach( instId cvId->instances
  when( member(instId->libName list(LIBRARY src_lib_nm))
  let((master)
    cond(
      ;;; if we find a matching cell view in our current destination library,
      ;;; then rebind to it
      ( (instId->libName != dest_lib_nm) &&
        ddGetObj(dest_lib_nm instId->cellName instId->viewName "master.tag")
        when( null(master = dbOpenCellViewByType(dest_lib_nm instId->cellName instId->viewName))
          error(sprintf(nil "Couldn't get master %s/%s/%s" dest_lib_nm instId->cellName instId->viewName))
        )
      )
      ;;; otherwise, if we find a matching cell view in our current custom library,
      ;;; then rebind to it (won't get here if dest_lib_nm is already set to custom lib name)
      ( (instId->libName != custom_lib_nm) &&
        ddGetObj(custom_lib_nm instId->cellName instId->viewName "master.tag")
        when( null(master = dbOpenCellViewByType(custom_lib_nm instId->cellName instId->viewName))
          error(sprintf(nil "Couldn't get master %s/%s/%s" custom_lib_nm instId->cellName instId->viewName))
        )
      )
    )
    ;;; switch the master if non-null
    when( !null(master)
      instId->master = master
      printf("Changed master of inst %L from %L to %L\n"
             instId->name
             list(src_lib_nm instId->cellName instId->viewName)
             list(master->libName master->cellName master->viewName)
   )
    )
  )))

  ;;; update color info if relevant
;  when( dptHasColorInfo(cvId)
;    if( dptReColor(cvId)
;    then printf("Recolored %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
;    else fprintf(stderr "Couldn't recolor %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
;    )
;  )

  ;;; schematic check-and-save if relevant
  when( member(cvId->cellViewType '("schematic")) && !member(schExtractStatus(cvId) '("clean"))
    if( schCheck(cvId)
    then printf("%s/%s/%s passed schematic check.\n" cvId->libName cvId->cellName cvId->viewName)
    else fprintf(stderr "%s/%s/%s didn't pass schematic check.\n" cvId->libName cvId->cellName cvId->viewName)
    )
  )

  ;;; save if necessary
  when( cvId->modifiedButNotSaved
    if( dbSave(cvId)
    then printf("Saved %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
    else fprintf(stderr "Couldn't save %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
    )
  )

))

