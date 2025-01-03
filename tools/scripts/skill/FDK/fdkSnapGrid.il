;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Intel Top Secret                                                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copyright (C) 2009, Intel Corporation.  All rights reserved.             ;;
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
;;
;; Filename:
;;   snapGrid.il
;;
;; Description:
;;   Defines functions relating to snapping a point to a given grid.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdkSnapGrid
;;
;; Description:
;;   Snaps the given point to the nearest given grid value (up or down).
;;
;; Inputs:
;;   - grid: the target grid value to snap (e.g. 0.005)
;;   - point: the point (float number) to snap
;;
;; Returns:
;;   The snapped point (float number)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkSnapGrid (grid point)
  (let\* (
    (fltGrid (float grid))  ; to allow nanometer snapping
    (ptLower (times (floor   (quotient point fltGrid)) fltGrid))
    (ptUpper (times (ceiling (quotient point fltGrid)) fltGrid)))
    (if (fdkCmp (difference ptUpper point) ">" (difference point ptLower))
      ptLower 
      ptUpper
    )
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdkSnapUpGrid
;;
;; Description:
;;   Snaps the given point to the nearest given upper grid value
;;
;; Inputs:
;;   - grid: the target grid value to snap (e.g. 0.005)
;;   - point: the point (float number) to snap
;;
;; Returns:
;;   The snapped point (float number)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkSnapUpGrid (grid point)
  (let (
    (snapResult (fdkSnapGrid grid point)))
  (if (lessp snapResult point) (plus snapResult grid) snapResult))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdkSnapDownGrid
;;
;; Description:
;;   Snaps the given point to the nearest given lower grid value
;;
;; Inputs:
;;   - grid: the target grid value to snap (e.g. 0.005)
;;   - point: the point (float number) to snap
;;
;; Returns:
;;   The snapped point (float number)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkSnapDownGrid (grid point)
  (let (
    (snapResult (fdkSnapGrid grid point)))
  (if (greaterp snapResult point) (difference snapResult grid) snapResult))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdkSnapUpEpsilonGrid
;;
;; Description:
;;   Snaps the given point to the nearest given upper grid value
;; if beyond epsilon, otherwise snaps to lower grid value
;;
;; Inputs:
;;   - grid: the target grid value to snap (e.g. 0.005)
;;   - point: the point (float number) to snap
;;
;; Returns:
;;   The snapped point (float number)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkSnapUpEpsilonGrid (grid point)
  (let (
    (snapResult (fdkSnapDownGrid grid point)))
  (if (greaterp point (plus snapResult fdkFloatTolerance)) (fdkSnapUpGrid grid point) snapResult))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdkSnapDownEpsilonGrid
;;
;; Description:
;;   Snaps the given point to the nearest given lower grid value
;; unless close to epsilon, then snaps up.
;;
;; Inputs:
;;   - grid: the target grid value to snap (e.g. 0.005)
;;   - point: the point (float number) to snap
;;
;; Returns:
;;   The snapped point (float number)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkSnapDownEpsilonGrid (grid point)
  (let (
    (snapResult (fdkSnapUpGrid grid point)))
  (if (lessp point (difference snapResult fdkFloatTolerance)) (fdkSnapDownGrid grid point) snapResult))
)
