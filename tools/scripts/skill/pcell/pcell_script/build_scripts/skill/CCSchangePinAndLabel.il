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

putd( 'CCSSearchAndReplaceElemInList nil )
procedure(CCSSearchAndReplaceElemInList(toBeSearchElem toBeReplaceElem mylist)
   foreach(mapcar elem mylist
     if(elem==toBeSearchElem toBeReplaceElem elem)
   ) ;foreach
 ) ;procedure

putd( 'CCSchangePinAndLabel nil )
procedure(
  
  CCSchangePinAndLabel(
    oldName
    newName
  @optional
    (cv geGetEditCellView())
  )

let((oldTerm newTerm oldNet newNet)

  ;;; copy all of the figures associated
  ;;; with the old term & net name, to the new term & net
  ;;; delete the old objects when they're not necessary anymore
  when( null(oldTerm = dbFindTermByName(cv oldName))
    error(sprintf(nil "Couldn't find terminal %L object in cell view %s/%s/%s" oldName cv->libName cv->cellName cv->viewName))
  )

  when( null(newNet = dbMakeNet(cv newName))
    error(sprintf(nil "Couldn't get new net %L object in cell view %s/%s/%s" newName cv->libName cv->cellName cv->viewName))
  )
  when( null(newTerm = dbFindTermByName(cv newName))
    when( null(newTerm = dbCreateTerm(newNet newName oldTerm->direction))
      error(sprintf(nil "Couldn't create new term %L object in cell view %s/%s/%s" newName cv->libName cv->cellName cv->viewName))
    )
  )

  foreach( pinId oldTerm->pins
    foreach( figId pinId->figs
      dbCreatePin(newNet figId nil newTerm)
    )
    dbDeleteObject(pinId)
  )
  dbDeleteObject(oldTerm)
  
  printf("Changed term %L to term %L for cell view %s/%s/%s\n" oldName newName cv->libName cv->cellName cv->viewName)

  when( null(oldNet = dbFindNetByName(cv oldName))
    error(sprintf(nil "Couldn't find net %L object in cell view %s/%s/%s" oldName cv->libName cv->cellName cv->viewName))
  )

  when( null(newNet = dbMakeNet(cv newName))
    error(sprintf(nil "Couldn't get new net %L object in cell view %s/%s/%s" newName cv->libName cv->cellName cv->viewName))
  )

  foreach( fig oldNet->figs
    dbSubFigFromNet(fig)
    dbAddFigToNet(fig newNet)
  )
  
  dbDeleteObject(oldNet)

  printf("Changed net %L to net %L for cell view %s/%s/%s\n" oldName newName cv->libName cv->cellName cv->viewName)

  ;;; change any label objects
  let((lbls)
    when( dtpr(lbls = setof(fig cv->shapes (fig->objType == "label") && (fig->theLabel == oldName)))
      printf("Changing %L labels from text %L to %L...\n" length(lbls) oldName newName)
      lbls~>theLabel = newName
    )
    when( dtpr(lbls = setof(fig cv->shapes (fig->objType == "label") && (fig->theLabel != newName) && (lowerCase(fig->theLabel) == lowerCase(oldName))))
    let((lbltab)
      lbltab = makeTable('LabelTab 0)
      foreach( lbl lbls lbltab[lbl->theLabel]++ )
      foreach( key lbltab printf("Found %d labels with different case %L\n" lbltab[key] key) )
    ))
    when( dtpr(lbls = setof(fig cv->shapes (fig->objType == "label") && rexMatchp(sprintf(nil "\"%s\"" oldName) fig->theLabel)))
      while( dtpr(lbls)
      let((lbl)
        lbl = car(lbls)
        lbls = cdr(lbls)
        when( rexMatchp(sprintf(nil "\"%s\"" oldName) lbl->theLabel)
        let((new_theLabel)
          new_theLabel = rexReplace(lbl->theLabel sprintf(nil "\"%s\"" newName) 0)
          printf("Changing %L label from %L to %L...\n" lbl->lpp lbl->theLabel new_theLabel)
          lbl->theLabel = new_theLabel
        ))
      ))
    )
    when( dtpr(lbls = setof(fig cv->shapes (fig->objType == "label") && (fig->theLabel != newName) && rexMatchp(sprintf(nil "\"%s\"" lowerCase(oldName)) lowerCase(fig->theLabel))))
    let((lbltab)
      lbltab = makeTable('LabelTab 0)
      foreach( lbl lbls lbltab[lbl->theLabel]++ )
      foreach( key lbltab printf("Found %d labels with different case %L\n" lbltab[key] key) )
    ))
  )

  ;;; Change the value of the portOrder cell view property (if it exists)
  when( !null(cv->portOrder)
  let((new_portOrder terms)
    new_portOrder = foreach( mapcar s cv->portOrder if( (s == oldName) newName s ) )
    when( cv->portOrder != new_portOrder
      printf("Changing portOrder cell view prop value from %L to %L\n" cv->portOrder new_portOrder)
      cv->portOrder = new_portOrder
    )
    when( dtpr(terms = setof(term cv->portOrder (term != newName) && (lowerCase(term) == lowerCase(oldName))))
      printf("portOrder prop contains different case term names: %L\n" terms)
    )
  ))

))
