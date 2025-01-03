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

putd( 'fdkParseStringByTabs nil )
procedure(

  fdkParseStringByTabs(l)
  
let((w ws)

  printf("fdkParseStringByTabs(%L): " l)

  foreach( c parseString(l "")
    if( c == "\t"
    then let((s)
           s = buildString(reverse(w) "")
           ws = cons(s ws)
           w = nil
         )
    else w = cons(c w)
    )
  )
  when( dtpr(w)
  let((s)
    s = buildString(reverse(w) "")
    ws = cons(s ws)
  ))

  printf("%L\n" reverse(ws))

  reverse(ws)

))

putd( 'fdkLoadKorFillTab nil )
procedure(

  fdkLoadKorFillTab(fpath)

let((kor_fill_tab ip l1 hdr_cnt hdr_tab)

  kor_fill_tab = makeTable('KorFillTab nil )

  when( null(inportp(ip = infile(fpath)))
    error(sprintf(nil "Couldn't open infile '%s'" fpath))
  )

  ;;; search for the header line
  hdr_tab = makeTable('fdkKorFillHdrTab nil)
  while( stringp(gets(l1 ip)) && !hdr_tab[1]
  let((ws)
  when( dtpr(ws = fdkParseStringByTabs(l1)) && 
        length(ws) > 3 &&
        (lowerCase(car(ws)) == "category") &&
        (lowerCase(cadr(ws)) == "cell name") &&
        (lowerCase(nth(2 ws)) == "cell description")
    hdr_cnt = length(ws)
    for( i 1 hdr_cnt
    let((s)
      s = nthelem(i ws)
      when( rexMatchp("^[ \t\n]*" s) s = rexReplace(s "" 0) )
      when( rexMatchp("[ \t\n]*$" s) s = rexReplace(s "" 0) )
      hdr_tab[i] = s
    ))
  )))

  if( hdr_tab[1]
  then while( stringp(gets(l1 ip))
       let((ws)
       when( dtpr(ws = fdkParseStringByTabs(l1)) && length(ws) > 3
       let((cn pl)
         pl = list(nil)
         for( i 1 hdr_cnt
         let((s)
           s = if( i <= length(ws) nthelem(i ws) "" )
           when( rexMatchp("^[ \t\n]*" s) s = rexReplace(s "" 0) )
           when( rexMatchp("[ \t\n]*$" s) s = rexReplace(s "" 0) )
           when( rexMatchp("^\"" s) && rexMatchp("\"$" s)
             s = evalstring(s)
           )
           case( lowerCase(hdr_tab[i])
             ( "category"
             let((s)
               pl->category = s
             ))
             ( "cell name"
               cn = s
             )
             ( "cell description"
             let((s)
               pl->description = s
             ))
             ( "diffusion"
               foreach( ln '("pdiff" "ndiff")
                 when( !member(ln pl->layer_list)
                   pl->layer_list = cons(ln pl->layer_list)
                 )
                 when( !blankstrp(s)
                   when( !member(ln pl->blockages)
                     pl->blockages = cons(ln pl->blockages)
                   )
                 )
               )
             )
             ( t let((ln)
               ln = lowerCase(hdr_tab[i])
               when( !member(ln pl->layer_list)
                 pl->layer_list = cons(ln pl->layer_list)
               )
               when( !blankstrp(s)
                 when( !member(ln pl->blockages)
                   pl->blockages = cons(ln pl->blockages)
                 )
               )
             ))
           )
         ))
         pl->layer_list = sort(pl->layer_list nil)
         pl->blockages = sort(pl->blockages nil)
         kor_fill_tab[cn] = pl
       ))))
  else close(ip)
       error(sprintf(nil "Couldn't find header line in file '%s'" fpath))
  )

  when( !close(ip)
    error(sprintf(nil "Couldn't close infile port '%s'" fpath))
  )

  kor_fill_tab

))

putd( 'fdkUpdateCellViewFillLayerBlockage nil )
procedure(

  fdkUpdateCellViewFillLayerBlockage(
    cvId
    ln
    pts
  )

let((blkgs)

  when( dtpr(blkgs = setof(blkg cvId->blockages
                       (blkg->objType == "layerBlockage") &&
                       (blkg->layer == ln) &&
                       (blkg->type == "fill") &&
                       (blkg->points != pts)
                     )
        )
    dbReopen(cvId "a") || error("dbReopen")
    blkgs = setof(blkg cvId->blockages
              (blkg->objType == "layerBlockage") &&
              (blkg->layer == ln) &&
              (blkg->type == "fill") &&
              (blkg->points != pts)
            )
    while( dtpr(blkgs)
    let((blkg)
      blkg = car(blkgs)
      blkgs = cdr(blkgs)
      when( dbDeleteObject(blkg)
        printf("Deleted %L fill blockage object\n" ln)
      )
    ))
  )

  when( null(blkgs = setof(blkg cvId->blockages
                       (blkg->objType == "layerBlockage") &&
                       (blkg->layer == ln) &&
                       (blkg->type == "fill")
                     )
        )
    dbReopen(cvId "a") || error("dbReopen")
    when( dbCreateLayerBlockage(cvId ln "fill" pts)
      printf("Created %L fill blockage\n" ln)
    )
  )

))

putd( 'fdkRemoveCellViewFillLayerBlockage nil )
procedure(

  fdkRemoveCellViewFillLayerBlockage(cvId ln)

let((blkgs)

  when( dtpr(blkgs = setof(blkg cvId->blockages (blkg->objType == "layerBlockage") && (blkg->type == "fill") && (blkg->layer == ln)))
    dbReopen(cvId "a") || error("dbReopen")
    blkgs = setof(blkg cvId->blockages (blkg->objType == "layerBlockage") && (blkg->type == "fill") && (blkg->layer == ln))
    while( blkgs
    let((blkg)
      blkg = car(blkgs)
      blkgs = cdr(blkgs)
      when( dbDeleteObject(blkg)
        printf("Deleted %L fill blockage object\n" ln)
      )
    ))
  )

))

putd( 'fdkUpdateCellViewFillLayerBlockages nil )
procedure(

  fdkUpdateCellViewFillLayerBlockages(
    cvId
    pl
  )

let((old_fill_blkgs bndry pts)

  old_fill_blkgs = sort(foreach(mapcar blkg setof(blkg cvId->blockages blkg->objType == "layerBlockage" && blkg->type == "fill") blkg->layer) nil)

  printf("%s/%s/%s: %L -> %L\n" cvId->libName cvId->cellName cvId->viewName old_fill_blkgs pl->blockages)

  when( null(bndry = cvId->prBoundary)
    error("no prBoundary object")
  )
  
  pts = if( bndry->points
        then bndry->points
        else let((x1 y1 x2 y2)
               x1 = xCoord(lowerLeft(bndry->bBox))
               y1 = yCoord(lowerLeft(bndry->bBox))
               x2 = xCoord(upperRight(bndry->bBox))
               y2 = yCoord(upperRight(bndry->bBox))
               list(x1:y1 x2:y1 x2:y2 x1:y2)
             )
        )

  foreach( ln pl->layer_list
    if( member(ln pl->blockages)
    then fdkUpdateCellViewFillLayerBlockage(cvId ln pts)
    else fdkRemoveCellViewFillLayerBlockage(cvId ln)
    )
  )

))

putd( 'fdkUpdateFillLayerBlockages nil )
procedure(

  fdkUpdateFillLayerBlockages(
  @key
    (korfill_fpath "")
    (lib "intel73custom")
    (cells nil)
  )

let((libdd kor_tab)

  when( blankstrp(korfill_fpath)
    korfill_fpath = simplifyFilename(sprintf(nil "%s/../templates_KORfill.txt" ddGetObjReadPath(ddGetObj(lib))) t)
  )

  when( !isFile(korfill_fpath)
    printf("%L is not a valid file path\n" korfill_fpath)
  )

  when( null(libdd = ddGetObj(lib))
    error(sprintf(nil "Couldn't get id for lib %L" lib))
  )
  
  when( null(cells)
    cells = sort(setof(celldd libdd->cells ddGetObj(nil nil "layout" "master.tag" celldd))~>name nil)
  )

  kor_tab = fdkLoadKorFillTab(korfill_fpath)

  foreach( cn cells
  let((pl cvId)
    when( !null(pl = kor_tab[cn])
      when( !null(cvId = dbOpenCellViewByType(lib cn "layout"))
        if( cvId->isParamCell
        then printf("SKIPPING PCELL %s/%s/%s\n" cvId->libName cvId->cellName cvId->viewName)
        else errset(fdkUpdateCellViewFillLayerBlockages(cvId pl) t)
             when( cvId->modifiedButNotSaved
               dbSave(cvId) || error("dbSave")
             )
        )
        dbPurge(cvId)
      )
    )
  ))

t))
