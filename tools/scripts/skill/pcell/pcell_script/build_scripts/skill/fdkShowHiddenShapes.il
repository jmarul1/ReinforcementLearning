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

;
; Author: Kim Flowers (Mr.)
;
; 1) gets triggered when you open a layout window,
; 2) checks the cell view to see if there are any LPPs being used in
;    the cell view which are not valid, and
; 3) if there are, assigns them a display packet which is essentially
;    just a dark gray outline.

; You can tell if the layout view you are working on has these
; invisible objects by looking at the CIW when you open your layout
; view & seeing the message "Enabling LPP (layer purpose)" being
; generated in your CIW.

; The gray outline is actually kind of hard to see unless you disable
; most of the other shapes, but that's what I intended, since these
; are essentially "ghost" shapes.  Let me know if you think they
; should be made more visible.

; NOTE: I could only practically check for "hidden" lpps at the current
; level of hierarchy, so bear that in mind. I figure we really only
; need to now about the ghost shapes when we're editing a specific
; layout view anyway, so it probably won't be that big an issue.

; The LSW entries for your new LPPs will get added at the bottom in
; case you want to manipulate them. As you continue opening layout
; windows, these updates will accumulate in your interface until your
; session's virtual memory gets reset.
;

putd( 'CCSsuppressDispForm nil )
procedure( CCSsuppressDispForm()
  hiRegTimer("hiFormCancel(techSaveDrmForm)" 10)
)

putd( 'fdkShowHiddenShapes nil )
procedure(

  fdkShowHiddenShapes(args)
  
let((cvId tfId)

  when( !null(cvId = geGetEditCellView())
    tfId = techGetTechFile(cvId)
    drSetPacket("display" "invisible_object_packet" "blank" "solid" "winText" "winText" "outline")
    foreach( lpp cvId->lpps
    let((lppair lpId lpattr)
      lppair = list(lpp->layerName lpp->purpose)
      when( null(lpId = techGetLP(tfId lppair))
        lpId = techCreateLP(tfId lppair lpp->layerName)
      )
      lpattr = techGetLPAttr(lpId)
      apply(
        lambda((priority visible selectable contToChgLay dragEnable valid)
          when( null(valid) || (valid == list(nil))
            printf("Enabling LPP %L\n" lppair)
            techSetLPPacketName(lpId "invisible_object_packet")
            techSetLPAttr(lpId list(priority t t nil t t))
            techSetLeLswLayer(tfId lppair)
          )
        )
        lpattr
      )
    ))
  )

))

when( isCallable('deGetAppInfo) && isCallable('regExitBefore) && isCallable('deRegUserTriggers)
let((appInfo)
  appInfo = deGetAppInfo("maskLayout")
  when( !member('fdkShowHiddenShapes appInfo->userPostInstallTrigList)
    regExitBefore('CCSsuppressDispForm)
    deRegUserTriggers("maskLayout" nil nil 'fdkShowHiddenShapes)
  )
))
