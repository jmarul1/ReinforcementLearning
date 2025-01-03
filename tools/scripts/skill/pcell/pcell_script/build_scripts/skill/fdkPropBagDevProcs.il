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
;;;   fdkCustomReadNextCsvLine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomReadNextCsvLine nil )
procedure(

  fdkCustomReadNextCsvLine(iport)
  
let((c cs w fs escape_flag quote_flag)

  while( !null(c = getc(iport)) && ((c = symbolToString(c)) != "\n")
    cs = cons(c cs)
  )
  cs = reverse(cs)

  while( !null(cs)
    cond(
      ( escape_flag
        w = cons(car(cs) w)
        escape_flag = nil
      )
      ( quote_flag
        case( car(cs)
          ( "\"" if( cadr(cs) == "\""
                 then escape_flag = t
                 else quote_flag = nil
                 )
          )
          ( t w = cons(car(cs) w) )
        )
      )
      ( t   
        case( car(cs)
          ( ","
            w = buildString(reverse(w) "")
            when( rexMatchp("^[ \t]*" w) w = rexReplace(w "" 0) )
            when( rexMatchp("[ \t]*$" w) w = rexReplace(w "" 0) )
            fs = cons(w fs)
            w = nil
          )
          ( "\"" quote_flag = t )
          ( t w = cons(car(cs) w) )
        )
      )
    )
    cs = cdr(cs)
  )
  w = buildString(reverse(w) "")
  when( rexMatchp("^[ \t]*" w) w = rexReplace(w "" 0) )
  when( rexMatchp("[ \t]*$" w) w = rexReplace(w "" 0) )
  fs = cons(w fs)

  when( !null(fs) && !isPortAtEOF(iport)
    reverse(fs)
  )

))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;  fdkCustomReadPropBagCsvFile(csv_fpath)
;;;    Parses a propbag.dir .csv-format configuration file &
;;;    returns its contents as a table using the configuration file's
;;;    column cell names as keys.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomReadPropBagCsvFile nil )
procedure(

  fdkCustomReadPropBagCsvFile(
    csv_fpath
  )
  
let((iport propbag_tab col_hdrs col_hdr_tab fs prop_list error_flag)

  if( !inportp(iport = infile(csv_fpath))

  then fprintf(stderr "ERROR: Couldn't open file '%s' for reading\n" csv_fpath)
       error_flag = t

  else propbag_tab = makeTable('fdkCustomPropBagTab nil)
       if( null(col_hdrs = fdkCustomReadNextCsvLine(iport))
       then fprintf(stderr "ERROR: Couldn't read csv column header names from file '%s'" csv_fpath)
            error_flag = t
       else col_hdr_tab = makeTable('fdkCustomColHdrTab nil)
            for( ix 1 length(col_hdrs)
              col_hdr_tab[nthelem(ix col_hdrs)] = ix
            )
            while( !null(fs = fdkCustomReadNextCsvLine(iport))
              when( !null(car(fs)) && !blankstrp(car(fs))
              let((prop_name propbag_flag)
                prop_name = nthelem(1 fs)
                propbag_flag = nthelem(col_hdr_tab["_propbag_"] fs)
                when( !blankstrp(propbag_flag)
                  for( ix 2 length(col_hdrs)
                  let((cell_name prop_val)
                    cell_name = nthelem(ix col_hdrs)
                    prop_val = nthelem(ix fs)
                    case( cell_name
                      ( ("cell" "_propbag_" "_category_") nil )
                      ( rexMatchp("^p[0-9]$" lowerCase(prop_name)) nil )
                      ( t propbag_tab[cell_name] = cons(list(prop_name prop_val) propbag_tab[cell_name]) )
                    )
                  ))
                )
              ))
            )
       )
       when( !close(iport)
         fprintf(stderr "ERROR: Couldn't finish reading file '%s'" csv_fpath)
         error_flag = t      
       )
  )

  when( !error_flag
    propbag_tab
  )

))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   fdkCustomApplyPropSpec
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomApplyPropSpec nil )
procedure(

  fdkCustomApplyPropSpec(
    parentId
    prop_name
    prop_val
  )

let((prop_name_list)
  if( length(prop_name_list = parseString(prop_name ".")) > 1
  then let((hierPropId)
         when( null(hierPropId = dbFindProp(parentId car(prop_name_list)))
           hierPropId = dbCreateHierProp(parentId car(prop_name_list))
         )
         fdkCustomApplyPropSpec(hierPropId buildString(cdr(prop_name_list) ".") prop_val)
       )
  else dbReplaceProp(parentId prop_name typep(prop_val) prop_val)
  )
))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   fdkCustomDefinePropBag
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomDefinePropBag nil )
procedure(

  fdkCustomDefinePropBag(
    LIBRARY CELL
    prop_list
  )
  
let((celldd bagId error_flag)

  cond(
    ( null(celldd = ddGetObj(LIBRARY CELL))
      fprintf(stderr "ERROR: Couldn't get id for cell %s/%s\n" LIBRARY CELL)
      error_flag = t
    )
    ( null(bagId = dbOpenBag(celldd "a"))
      fprintf(stderr "ERROR: Couldn't open property bag of cell %s/%s for editing\n" LIBRARY CELL)
      error_flag = t
    )
    ( t let((props_to_clean_up)
      when( dtpr(props_to_clean_up = setof(propId bagId->prop (propId->name != "cdfData")))
        foreach( propId props_to_clean_up
          printf("Deleting prop %L from cell %L property bag...\n" propId->name CELL)
          dbDeleteObject(propId)
        )
      )
      foreach( prop_spec prop_list
        printf("Adding property %L value %L to property bag for cell %L\n" car(prop_spec) cadr(prop_spec) CELL)
        apply( 'fdkCustomApplyPropSpec cons(bagId prop_spec) )
      )
      dbReplaceProp(bagId "cell" "string" CELL)
      if( dbSaveBag(bagId)
      then printf("Saved %s/%s property bag\n" LIBRARY CELL)
      else fprintf(stderr "ERROR: Couldn't save property bag for cell %s/%s\n" LIBRARY CELL)
           error_flag = t
      )
      dbPurgeBag(bagId)
    ))
  )

  when( error_flag
    error(sprintf(nil "Could not successfully define property bag for lib/cell %s/%s" LIBRARY CELL))
  )

))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;  fdkCustomLoadPropBagCsvFile(csv_fpath [?lib_name "intel73custom"])
;;;    Parses a propbag.dir .csv-format configuration file &
;;;    and applies its contents to the cells in the specified library
;;;    (default intel73custom)
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'fdkCustomLoadPropBagCsvFile nil )
procedure(

  fdkCustomLoadPropBagCsvFile(csv_fpath @key (lib_name "intel73custom"))
  
let((iport error_flag)

  when( !rexMatchp("^/" csv_fpath) && !rexMatchp("^\\." csv_fpath)
    csv_fpath = simplifyFilename(sprintf(nil "%s/../propbag.dir/%s"
                  ddGetObjReadPath(ddGetObj(lib_name)) csv_fpath) t)
  )

  when( !inportp(iport = infile(csv_fpath))
    error(sprintf(nil "Couldn't open file '%s' for reading" csv_fpath))
  )
  
  when( !errset(let((propbag_tab col_hdrs col_hdr_tab fs prop_list)
          propbag_tab = makeTable('fdkCustomPropBagTab nil)
          when( null(col_hdrs = fdkCustomReadNextCsvLine(iport))
            error(sprintf(nil "Couldn't read csv column header names from file '%s'" csv_fpath))
          )
          col_hdr_tab = makeTable('fdkCustomColHdrTab nil)
          for( ix 1 length(col_hdrs)
            col_hdr_tab[nthelem(ix col_hdrs)] = ix
          )
          while( !null(fs = fdkCustomReadNextCsvLine(iport))
            when( !null(car(fs)) && !blankstrp(car(fs))
            let((prop_name propbag_flag)
              prop_name = nthelem(1 fs)
              propbag_flag = nthelem(col_hdr_tab["_propbag_"] fs)
              when( !blankstrp(propbag_flag)
                for( ix 2 length(col_hdrs)
                let((cell_name prop_val)
                  cell_name = nthelem(ix col_hdrs)
                  prop_val = nthelem(ix fs)
                  case( cell_name
                    ( ("cell" "_propbag_" "_category_") nil )
                    ( t propbag_tab[cell_name] = cons(list(prop_name prop_val) propbag_tab[cell_name]) )
                  )
                ))
              )
            ))
          )
          foreach( cell_name propbag_tab
          let((celldd prop_list bagId)
            when( dtpr(prop_list = setof(
                                     prop_spec propbag_tab[cell_name]
                                     !rexMatchp("^p[0-9]$" lowerCase(car(prop_spec)))
                                   )
                  )
              fdkCustomDefinePropBag(lib_name cell_name prop_list)
            )
          ))
        ) t)
    error_flag = t
  )

  when( !close(iport)
    error(sprintf(nil "Couldn't finish reading file '%s'" csv_fpath))
  )
  
  when( error_flag
    error("fdkCustomLoadPropBagCsvFile unsuccessful")
  )

t))
