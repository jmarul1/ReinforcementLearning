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

putd( '_fdkBuildSymPinCoordsTab nil )
procedure(

  _fdkBuildSymPinCoordsTab(libdd)
  
let((coord_tab)

  coord_tab = makeTable('fdkSymPinCoordsTab nil)

  foreach( celldd libdd->cells
  when( !null(ddGetObj(nil nil "symbol" "master.tag" celldd))
  let((cvId tfId grid term_bBoxes)
    cond(
      ( null(cvId = dbOpenCellViewByType(libdd->name celldd->name "symbol"))
        error(sprintf(nil "Couldn't open cell view %s/%s/%s" libdd->name celldd->name "symbol"))
      )
      ( null(tfId = techGetTechFile(cvId))
        error(sprintf(nil "Couldn't get tech file id for %s/%s/%s" cvId->libName cvId->cellName cvId->viewName))
      )
      ( !numberp(grid = techGetMfgGridResolution(tfId))
        error(sprintf(nil "Couldn't get grid resolution for %s/%s/%s" cvId->libName cvId->cellName cvId->viewName))
      )
      ( t let((term_bBoxes)
         foreach( termId cvId->terminals
         let((term_nm bBoxes)
           term_nm = termId->name
           foreach( pinId termId->pins
             foreach( figId pinId->figs
             let((fig_bBox)
               bBoxes = cons(list(nil 'bBox figId->bBox 'lpp figId->lpp) bBoxes)
             ))
           )
           bBoxes = sort(bBoxes
                      lambda((x y)
                      let((xllx xlly yllx ylly)
                        xllx = round(xCoord(lowerLeft(x->bBox))/grid)
                        xlly = round(yCoord(lowerLeft(x->bBox))/grid)
                        yllx = round(xCoord(lowerLeft(y->bBox))/grid)
                        ylly = round(yCoord(lowerLeft(y->bBox))/grid)
                        (xllx < yllx) || ((xllx == yllx) && (yllx < ylly))
                      ))
                    )
           term_bBoxes = cons(cons(term_nm bBoxes) term_bBoxes)
         ))
         when( !dbClose(cvId)
           error(sprintf(nil "Couldn't close cell view id for %s/%s/%s" libdd->name celldd->name "symbol"))
         )
         coord_tab[celldd->name] = term_bBoxes
      ))
    )
  )))

  coord_tab

))

putd( '_fdkWriteSymPinCoordsTab nil )
procedure(

  _fdkWriteSymPinCoordsTab(lib_nm out_fpath coord_tab)

let((oport)

  cond(
    ( !outportp(oport = outfile(out_fpath))
      error(sprintf(nil "Couldn't open %L file for writing" out_fpath))
    )
    ( !fprintf(oport "# Dump of pin bBox coordinates for all cells from library %L\n" lib_nm)
      error(sprintf(nil "Couldn't write header to %L file\n" out_fpath))
    )
    ( !errset(progn(
         foreach( k coord_tab
         let((v)
           v = coord_tab[k]
           foreach( ps v
             fprintf(oport "%L,%L" k car(ps))
             foreach( psi cdr(ps)
               fprintf(oport ",\"%B\"" psi->bBox)
             )
             fprintf(oport "\n")
           )
         ))
       t) t)
      error(sprintf(nil "Couldn't write sym coord tab to %L file\n" out_fpath))
    )
    ( !close(oport)
      error(sprintf(nil "Couldn't finish writing to %L file\n" out_fpath))
    )
  )

))
  
putd( 'fdkDumpSymPinCoordsTab nil )
procedure(

  fdkDumpSymPinCoordsTab(
  @key
    (lib_nm "intel73custom")
    (out_fpath "")
  )

let((libdd coord_tab oport errmsg)

  cond(
    ( null(libdd = ddGetObj(lib_nm))
      sprintf(errmsg "Couldn't get id of lib %L\n" lib_nm)
    )
    ( !errset(setq(coord_tab _fdkBuildSymPinCoordsTab(libdd)) t)
      sprintf(errmsg "Couldn't gather pin coordinate data for lib %L\n" lib_nm)
    )
    ( blankstrp(out_fpath) &&
      !stringp(
         sprintf(out_fpath "%s" ddGetObjWritePath(libdd)) &&
         (out_fpath = (rexMatchp("//*[^/]*$" out_fpath) &&
                       rexReplace(out_fpath "/sym_pin_coords_tab.csv" 0)))
      )
      sprintf(errmsg "Couldn't construct default output fpath\n")
    )
    ( !errset(_fdkWriteSymPinCoordsTab(lib_nm out_fpath coord_tab) t)
      sprintf(errmsg "Couldn't write pin coordinates table to %L file" out_fpath)
    )
    ( t printf("Finished writing to %L file\n" out_fpath) )
  )

  when( stringp(errmsg)
    fprintf(stderr "%s\n" errmsg)
    error(errmsg)
  )

  printf("Finished fdkDumpSymPinCoordsTab\n")

t))

printf("Usage: fdkDumpSymPinCoordsTab [ ?lib_nm \"intel73custom\" ] [ ?out_fpath \"<lib_nm_parent_dir_path>/sym_pin_coords_tab.csv\" ]\n")
