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

putd( '_fdkUpdateVidLabel nil )
procedure(

  _fdkUpdateVidLabel(
    cvId
    vid
    vid_lpp
  )

let((rectId lblId tSize tfId grid)

  ;;; see if there is already one, and only one, VID label
  when( !dbReopen(cvId "a")
    error(sprintf(nil "Couldn't make cell view %s/%/%s editable" cvId->libName cvId->cellName cvId->viewName))
  )

  ;;; Delete any existing l9text shapes
  foreach( obj setof(fig cvId->shapes car(fig->lpp) == car(vid_lpp))
    dbDeleteObject(obj)
  )

  ;;; create a new boundary
  rectId = if( cvId->prBoundary
           then dbCreateRect(cvId vid_lpp cvId->prBoundary->bBox)
           else dbCreateRect(cvId vid_lpp cvId->bBox)
           )
  when( null(rectId)
    error(sprintf(nil "Couldn't create l9text rect shape in cell view %s/%s/%s" cvId->libName cvId->cellName cvId->viewName))
  )

  ;;; Create a VID label right at center of bBox
  tSize = (yCoord(upperRight(cvId->bBox)) - yCoord(lowerLeft(cvId->bBox)))/10.0
  when( null(lblId = dbCreateLabel(cvId vid_lpp centerBox(cvId->bBox) vid "centerCenter" "R0" "stick" tSize))
    error(sprintf(nil "Could't create l9text label in cell view %s/%s/%s" cvId->libName cvId->cellName cvId->viewName))
  )

  ;;; shrink label until it fits in bBox
  tfId = techGetTechFile(cvId)
  grid = techGetMfgGridResolution(tfId)
  while( round(lblId->height/grid) > 5 && (
           leftEdge(lblId) < leftEdge(rectId) || rightEdge(lblId) > rightEdge(rectId) ||
           bottomEdge(lblId) < bottomEdge(rectId) || topEdge(lblId) > topEdge(rectId)
         )
    tSize = max(round(pcFix(tSize/grid) * 0.9)*grid grid)
    warn("theLabel=%L tSize=%L\n" lblId->theLabel tSize)
    lblId->height = tSize
  )

))

putd( 'fdkUpdateVidLabel nil )
procedure(

  fdkUpdateVidLabel(@optional (cvId nil))

let((
    (vid_lpp list("l9text" "drawing"))
    d8lib_vers dessync_vers vid old_vid_lbls old_vid_lbl
  )

  ;;; Make sure we have a valid cvId
  when( null(cvId)
    when( null(cvId = geGetEditCellView())
      error("No editor windows available.")
    )
  )
  when( !member(cvId->cellViewType '("maskLayout"))
    error(sprintf(nil "cell view %s/%s/%s is not a layuot" cvId->libName cvId->cellName cvId->viewName))
  )

  ;;; Get D8LIB_VERSION & DesignSync version values
  when( !stringp(d8lib_vers = getShellEnvVar("D8LIB_VERSION")) || blankstrp(d8lib_vers)
    error("D8LIB_VERSION env var is not defined")
  )
  ; printf("D8LIB_VERSION = %L\n" d8lib_vers)
  when( rexMatchp("\\." d8lib_vers)
    d8lib_vers = rexReplace(d8lib_vers "p" 0)
  )

  when( !stringp(dessync_vers = dssGetViewVersionP(cvId->libName cvId->cellName cvId->viewName ?useCache nil ?quick nil)) || blankstrp(dessync_vers)
    error(sprintf(nil "Couldn't get DesignSync version for cell view %s/%s/%s" cvId->libName cvId->cellName cvId->viewName))
  )
  ; printf("DesigSync version = %L\n" dessync_vers)
  when( (dessync_vers == "Unmanaged")
    dessync_vers = "1.1"
  )
  when( rexMatchp(" ([A-Z])$" dessync_vers)
    dessync_vers = rexReplace(dessync_vers "" 0)  ;;; get rid of fetch mode
  )
  when( rexMatchp("^[^ ]* -> " dessync_vers)
    dessync_vers = rexReplace(dessync_vers "" 0)  ;;; get rid of prev version if locked
  )
  when( rexMatchp("\\." dessync_vers)
    dessync_vers = rexReplace(dessync_vers "p" 0)  ;;; replace dots with p
  )

  ;;; construct new VID
  sprintf(vid "vid_icf_%s_%s_%s" cvId->cellName d8lib_vers dessync_vers)
  
  ;;; Check for existing VID labels
  old_vid_lbls = setof(fig cvId->shapes fig->objType == "label" && fig->lpp == vid_lpp && rexMatchp("^vid_" fig->theLabel))

  ;;; if there is exactly one VID label currently existing,
  ;;; if it already matches what we want,
  ;;; or if the DesSync version is "1p0" (indicating this is first version of this layout for this D8LIB version),
  ;;; and the existing VID matches the AD "vid__1273_" prefix",
  printf("cell view %s/%s/%s: " cvId->libName cvId->cellName cvId->viewName)
  cond(
    ( length(old_vid_lbls) > 1
      printf("%L VID labels\n" length(old_vid_lbls))
    )
    ( null(old_vid_lbls)
      if( (cvId == geGetEditCellView())
      then _fdkUpdateVidLabel(cvId vid vid_lpp)
      else printf("No VID label found\n")
      )
    )
    ( null(old_vid_lbl = car(old_vid_lbls))
      error("*** shouldn't ever happen ***")
    )
    ( rexMatchp("^vid__1273_" old_vid_lbl->theLabel)
      if( (cvId == geGetEditCellView())
      then _fdkUpdateVidLabel(cvId vid vid_lpp)
      else printf("Valid AD VID label %L\n" old_vid_lbl->theLabel)
      )
    )
    ( (old_vid_lbl->theLabel == vid)
      printf("VID label is already set to %L\n" vid)
    )
    ( t
      printf("%L -> %L\n" old_vid_lbl->theLabel vid)
      _fdkUpdateVidLabel(cvId vid vid_lpp)
    )

  )

t))

newline()
printf("Usage: fdkUpdateVidLabel() - Updates VID label for cell view in currently open editor window\n")
printf("Usage: fdkUpdateVidLabel(cvId) - Updates VID label for specified cell view\n")
printf("     Updates VID label value with format vid_icf_<cellname>_<d8libvers>_<dessyncvers>,\n")
printf("     removing any existing VID shapes if necessary.\n")
newline()
