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
;;   fdkFillLib.il
;;
;; Description:
;;   File to store procedures shared by several virtuoso fill utilities.
;;   
;;
;; Globals:
;;   None set.
;;
;; Requires:
;;
;; Provides key procedures:
;;  1  (defun fdkRemoveTemporaryDBobjects (objs "l")
;;         returns t on success, nil on failure
;;  2  (defun fdkPromoteHierShapesOnLPPs
;;        (cv bBox lpps @key (types '("donut" "ellipse" "path" "pathSeg" "polygon"
;;                                   "rect"))
;;                               (hierDepth 0) "dlllg")
;;         returns list of promoted shapes on success, nil on failure
;;
;; BUGS:
;;
;; ENHANCEMENTS:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkSortCellSizes
;;
;; Description:
;;   Gets the cell bounding box sizes and sorts cell view ID list from
;;   largest to smallest.
;;
;; Inputs:
;;   - cvs: A list of cell view IDs
;;   - x_or_y: Either 'x or 'y to indicate the dimension to consider when
;;     sorting.
;;
;; Returns:
;;    A list of cell view ID's sorted from largest to smallest.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkSortCellSizes (cvs x_or_y)
  (sort (copy cvs) (lambda (a b)
		     (let ((da (fdkGetBBoxDim a~>prBoundary~>bBox x_or_y))
			   (db (fdkGetBBoxDim b~>prBoundary~>bBox x_or_y)))
		       ;; Reverse sort
		       (fdk_is_gt da db)))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkIsLPPspec
;;
;; Description:
;;   Determines if the argument is a Virtuoso layer-purpose specifier.
;;
;; Inputs:
;;   - spec: the supposed layer-purpose specifier.
;;
;; Returns:
;;   A non-nil value is returned if the argument is a layer-purpose
;;   specifier.  Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkIsLPPspec (spec "g")
  (cond
    ;; The spec is a list that has exactly one element and that element is
    ;; not a list.
    ((listp spec) && (car spec) && (not (cdr spec)) && (not (listp (car spec)))
      ;; Determine if the item is a layer specifier.
      (fdkIsLayerOrPurposeSpec (car spec))
    )

    ;; The spec is a list that has exactly two elements, neither of which
    ;; is itself a list.
    ((listp spec) && (cdr spec) && (not (cddr spec)) &&
     (not (listp (car spec))) && (not (listp (cadr spec)))
      ;; Determine if the items are layer and purpose specifiers.
      (fdkIsLayerOrPurposeSpec (car spec)) &&
      (fdkIsLayerOrPurposeSpec (cadr spec))
    )

    ;; Determine if the item is a layer specification.
    (t (fdkIsLayerOrPurposeSpec spec))
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkIsLayerOrPurposeSpec
;;
;; Description:
;;   Determines if the argument specifies a Virtuoso layer or purpose.
;;
;; Inputs:
;;   - spec: the supposed layer or purpose specifier.
;;
;; Returns:
;;   A non-nil value is returned if the argument is a layer or purpose
;;   specifier.  Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkIsLayerOrPurposeSpec (spec "g")
  (cond
    ;; The spec is an integer (a layer or purpose number).  Assume that
    ;; it represents an actual layer or purpose number.
    ((fixp spec)
      (plusp spec)
    )

    ;; The spec is a string (a layer or purpose name).  Assume that it
    ;; represents an actual layer name.
    ((stringp spec)
      (not (blankstrp spec))
    )

    ;; The spec is a symbol (a layer or purpose name).  Assume that it
    ;; represents an actual layer name.
    ((symbolp spec)
      t
    )

    ;; Anything else is not a layer or purpose specification.
    (t nil)
  )
)

(defun
  fdkLeftEdge
  (
    box
  "l"
  )
  (xCoord (lowerLeft box))
)

(defun
  fdkRightEdge
  (
    box
  "l"
  )
  (xCoord (upperRight box))
)

(defun
  fdkBottomEdge
  (
    box
  "l"
  )
  (yCoord (lowerLeft box))
)

(defun
  fdkTopEdge
  (
    box
  "l"
  )
  (yCoord (upperRight box))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkRectWidth
;;
;; Description:
;;   Determines the width (horizontal distance) occupied by the given
;;   bounding box.
;;
;; Inputs:
;;   - rect: the bounding box of the rectangle in question.
;;
;; Returns:
;;   If a valid bounding box is given, its width is returned.  Otherwise,
;;   nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkRectWidth (rect "l")
  ;; Return the rectangle width.
  (fdkRightEdge rect) - (fdkLeftEdge rect)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkRectLength
;;
;; Description:
;;   Determines the length (vertical distance) occupied by the given
;;   bounding box.
;;
;; Inputs:
;;   - rect: the bounding box of the rectangle in question.
;;
;; Returns:
;;   If a valid bounding box is given, its length is returned.  Otherwise,
;;   nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkRectLength (rect "l")
  ;; Return the rectangle length.
  (fdkTopEdge rect) - (fdkBottomEdge rect)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkIsPoint
;;
;; Description:
;;   Determines if the argument specifies a point.
;;
;; Inputs:
;;   - point: the supposed X and Y coordinates.
;;
;; Returns:
;;   A non-nil value is returned if the argument is a point.  Otherwise,
;;   nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkIsPoint (point "l")
  ;; The point is a 2-element list of numbers.
  point && (cdr point) && (not (cddr point)) &&
  (numberp (car point)) && (numberp (cadr point))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkIsBoundingBox
;;
;; Description:
;;   Determines if the argument specifies a point.
;;
;; Inputs:
;;   - point: the supposed X and Y coordinates.
;;
;; Returns:
;;   A non-nil value is returned if the argument is a point.  Otherwise,
;;   nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkIsBoundingBox (box "l")
  ;; The bounding box is a 2-element list of points, the first represents
  ;; the lower-left corner, the second represents the upper-right corner.
  ;; NOTE: The built-in 'isBBox' function verifies that the given argument
  ;; is a list of 2 points, but does NOT ensure they are ordered as
  ;; lower-left then upper-right AND represent a rectangle with non-zero
  ;; area.
  (isBBox box) &&
  (fdkLess (fdkLeftEdge box) (fdkRightEdge box)) &&
  (fdkLess (fdkBottomEdge box) (fdkTopEdge box))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkZeroAlmostZero
;;
;; Description:
;;   Determines if the given argument is very close to zero.  This is a
;;   weapon used to combat the phenomenon in digital computation known as
;;   "machine epsilon."  See the following web-page (and many others if
;;   you so desire) for a discussion of this topic:
;;
;;     http://en.wikipedia.org/wiki/Machine_epsilon
;;
;; Inputs:
;;   - number: the number in question.
;;
;; Keyword inputs:
;;   - threshold: values smaller than this number are deemed to be
;;     essentially zero.
;;
;; Returns:
;;   The number itself if it is not close enough to zero.  Otherwise, zero
;;   is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
/***
(defun fdkZeroAlmostZero (number @key (threshold 1.0e-10) "nn")
  (if (lessp (abs number) threshold)
  ;; then
    0.0
  ;; else
    number
  )
)
***/
(defmacro
  fdkZeroAlmostZero
  (
    number
  )
  `(if (lessp (abs ,number) 1.0e-10) 0.0 ,number)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkEqual
;;
;; Description:
;;   Determines if two numbers are essentially equal.  See the definition
;;   of 'fdkZeroAlmostZero' for an explanation of "essentially equal".
;;
;; Inputs:
;;   - n1: the first number in question.
;;   - n2: the comparison number.
;;
;; Keyword inputs:
;;   - threshold: values smaller than this number are deemed to be
;;     essentially zero.
;;
;; Returns:
;;   A non-nil value if the two numbers are essentially equal.  Otherwise,
;;   nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkEqual (n1 n2 "nn")
  (zerop (fdkZeroAlmostZero n1 - n2))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkNotEq
;;
;; Description:
;;   Determines if two numbers are essentially not equal.  See the
;;   definition of 'fdkZeroAlmostZero' for an explanation of "essentially
;;   not equal".
;;
;; Inputs:
;;   - n1: the first number in question.
;;   - n2: the comparison number.
;;
;; Keyword inputs:
;;   - threshold: values smaller than this number are deemed to be
;;     essentially zero.
;;
;; Returns:
;;   A non-nil value if the two numbers are essentially not equal.
;;   Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkNotEq (n1 n2 "nn")
  (null (zerop (fdkZeroAlmostZero n1 - n2)))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkGreaterEq
;;
;; Description:
;;   Determines if the first of two numbers is greater than or equal to
;;   the second number.
;;
;; Inputs:
;;   - n1: the first number in question.
;;   - n2: the comparison number.
;;
;; Keyword inputs:
;;   - threshold: values smaller than this number are deemed to be
;;     essentially zero.
;;
;; Returns:
;;   A non-nil value if the first number is greater than or equal to the
;;   second number.  Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkGreaterEq (n1 n2 "nn")
  (null (minusp (fdkZeroAlmostZero n1 - n2)))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkGreater
;;
;; Description:
;;   Determines if the first of two numbers is greater than the second
;;   number.
;;
;; Inputs:
;;   - n1: the first number in question.
;;   - n2: the comparison number.
;;
;; Keyword inputs:
;;   - threshold: values smaller than this number are deemed to be
;;     essentially zero.
;;
;; Returns:
;;   A non-nil value if the first number is greater than the second
;;   number.  Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkGreater (n1 n2 "nn")
  (minusp (fdkZeroAlmostZero n2 - n1))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkLessEq
;;
;; Description:
;;   Determines if the first of two numbers is less than or equal to
;;   the second number.
;;
;; Inputs:
;;   - n1: the first number in question.
;;   - n2: the comparison number.
;;
;; Keyword inputs:
;;   - threshold: values smaller than this number are deemed to be
;;     essentially zero.
;;
;; Returns:
;;   A non-nil value if the first number is less than or equal to the
;;   second number.  Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkLessEq (n1 n2 "nn")
  (null (minusp (fdkZeroAlmostZero n2 - n1)))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkLess
;;
;; Description:
;;   Determines if the first of two numbers is less than the second
;;   number.
;;
;; Inputs:
;;   - n1: the first number in question.
;;   - n2: the comparison number.
;;
;; Keyword inputs:
;;   - threshold: values smaller than this number are deemed to be
;;     essentially zero.
;;
;; Returns:
;;   A non-nil value if the first number is less than the second number.
;;   Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkLess (n1 n2 "nn")
  (minusp (fdkZeroAlmostZero n1 - n2))
)

(defun
  fdkEqualPoints
  (
    pt1
    pt2
  )
  (eq pt1 pt2) ||
  ((fdkEqual (xCoord pt1) (xCoord pt2)) &&
   (fdkEqual (yCoord pt1) (yCoord pt2)))
)

(defun
  fdkEqualBoundingBoxes
  (
    b1
    b2
  "ll"
  )
  (eq b1 b2) ||
  ((fdkEqualPoints (lowerLeft b1) (lowerLeft b2)) &&
   (fdkEqualPoints (upperRight b1) (upperRight b2)))
)

(defun
  fdkBoundingBoxUpperLeft
  (
    box
  "l"
  )
  (fdkLeftEdge box):(fdkTopEdge box)
)

(defun
  fdkBoundingBoxLowerRight
  (
    box
  "l"
  )
  (fdkRightEdge box):(fdkBottomEdge box)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkPointInBoundingBox
;;
;; Description:
;;   Determines if a point resides within the given bounding box.
;;
;; Inputs:
;;   - point: the point in question (a list of lower-left and upper-right
;;     points).
;;   - box: the bounding box (a list of 2 points).
;;
;; Returns:
;;   A non-nil value if the point resides within the given bounding box.
;;   Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkPointInBoundingBox (point box "ll")
  (prog (x y)
/***  Remove some defensive programming in favor of performance.
    ;; Qualify the point.
    (unless (fdkIsPoint point)
      (warn "fdkPointInBoundingBox: improper point: %L" point)
      (return nil)
    )

    ;; Qualify the bounding box.
    (unless (fdkIsBoundingBox box)
      (warn "fdkPointInBoundingBox: improper bounding box: %L" box)
      (return nil)
    )
***/
    ;; Derive certain data from the input parameters.
    (setq x (xCoord point))
    (setq y (yCoord point))

    ;; Return a non-nil value if the point resides within the bounding box.
    (return
      (not
        (or
          (fdkLess x (fdkLeftEdge box))
          (fdkGreater x (fdkRightEdge box))
          (fdkLess y (fdkBottomEdge box))
          (fdkGreater y (fdkTopEdge box))
        )
      )
    )
  )
)

(defun
  fdkMergeBoundingBoxes
  (
    box1
    box2
  "ll"
  )
;;;  (unless (fdkIsBoundingBox box1) && (fdkIsBoundingBox box2)
;;;    (warn "fdkMergeBoundingBoxes: improper bounding boxes.")
;;;  )

  ;; Create a new bounding box from the extents of the two source bounding
  ;; boxes.
  (list
    ;; New lower-left corner.
    (min (fdkLeftEdge box1) (fdkLeftEdge box2)):
    (min (fdkBottomEdge box1) (fdkBottomEdge box2))

    ;; New upper-right corner.
    (max (fdkRightEdge box1) (fdkRightEdge box2)):(max (fdkTopEdge box1) (fdkTopEdge box2))
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkBoundingBoxContainsBoundingBox
;;
;; Description:
;;   Determines if the first bounding box completely contains the second
;;   bounding box.
;;
;; Inputs:
;;   - box1: the first bounding box (a list of lower-left and upper-right
;;     points).
;;   - box2: the second bounding box (a list of lower-left and upper-right
;;     points).
;;
;; Returns:
;;   A non-nil value if the the first bounding box completely contains the
;;   second bounding box.  Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun
  fdkBoundingBoxContainsBoundingBox
  (
    box1
    box2
  "ll"
  )
;;;  (unless (fdkIsBoundingBox box1) && (fdkIsBoundingBox box2)
;;;    (warn "fdkBoundingBoxContainsBoundingBox: improper bounding boxes.")
;;;  )
  (fdkPointInBoundingBox (lowerLeft box2) box1) &&
  (fdkPointInBoundingBox (upperRight box2) box1)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkBoundingBoxesIntersect
;;
;; Description:
;;   Determines if 2 bounding boxes touch or overlap.
;;
;; Inputs:
;;   - box1: the first bounding box (a list of lower-left and upper-right
;;     points).
;;   - box2: the second bounding box (a list of lower-left and upper-right
;;     points).
;;
;; Returns:
;;   A non-nil value if the given bounding boxes touch or overlap.
;;   Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkBoundingBoxesIntersect (box1 box2 "ll")
  ;; Return a non-nil value if the given bounding boxes touch or overlap.
  (not
    ;; Determine if one bounding box is entirely outside the other.
    (or
      ;; Left side of box1 is to the right of box2.
      (fdkGreater (fdkLeftEdge box1) (fdkRightEdge box2))

      ;; Right side of box1 is to the left of box2.
      (fdkLess (fdkRightEdge box1) (fdkLeftEdge box2))

      ;; Bottom of box1 is above the top of box2.
      (fdkGreater (fdkBottomEdge box1) (fdkTopEdge box2))

      ;; Top of box1 is below the bottom of box2.
      (fdkLess (fdkTopEdge box1) (fdkBottomEdge box2))
    )
  )
)
/***
;; This is a deprecated function.
(defun fdkStretchRect (rect deltas "ll")
  (prog ()
    ;; Qualify the rectangle.
    (unless (fdkIsBoundingBox rect)
      (warn "fdkStretchRect: malformed rectangle: %L" rect)
      (return nil)
    )

    ;; Qualify the delta list.  The format of the delta list is:
    ;;
    ;;   (deltaLeft deltaRight deltaTop deltaBottom)
    ;;
    (unless (cdddr deltas) && (not (cddddr deltas)) &&
            (forall item deltas (numberp item))
      (warn "fdkStretchRect: malformed delta list: %L" deltas)
      (return nil)
    )

    ;; Modify the rectangle as specified by the delta list.
    ;; NOTE:  The stretch may result in a zero-area rectangle -- the
    ;; calling function must detect and handle this condition.
    (return
      (list (rodAddPoints (lowerLeft rect) (car deltas):(cadddr deltas))
            (rodAddPoints (upperRight rect) (cadr deltas):(caddr deltas)))
    )
  )
)
***/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkStretchBoundingBox
;;
;; Description:
;;   Resizes a bounding box based on a set of edge delta values.  NOTE:
;;   The bounding box is not modified if the operation would result in a
;;   zero-area rectangle.
;;
;; Inputs:
;;   - bBox: the boudning box in question.
;;   - deltas: a DPL with one or more of the following fields and values:
;;     . deltaLeft: amount to move the left edge horizontally.
;;     . deltaRight: amount to move the right edge horizontally.
;;     . deltaTop: amount to move the top edge vertically.
;;     . deltaBottom: amount to move the bottom edge vertically.
;;
;; Returns:
;;   If the input bounding box is valid, a bounding box with its edges
;;   appropriately adjusted is returned.  Otherwise, nil is returned.
;;   NOTE:  The stretch may result in a zero-area bounding box -- the
;;   calling function must detect and handle this condition.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkStretchBoundingBox (bBox deltas "ll")
    ;; The deltas reside in a DPL with these possible fields:
    ;;
    ;;   deltaLeft
    ;;   deltaRight
    ;;   deltaTop
    ;;   deltaBottom
    ;;
    ;; Modify the bounding box as specified by the deltas.
    ;; NOTE:  The stretch may result in a zero-area bounding box -- the
    ;; calling function must detect and handle this condition.
    (list
        (rodAddPoints
          (lowerLeft bBox)
          (((numberp deltas->deltaLeft) && deltas->deltaLeft) || 0.0):
          (((numberp deltas->deltaBottom) && deltas->deltaBottom) || 0.0))
        (rodAddPoints
          (upperRight bBox)
          (((numberp deltas->deltaRight) && deltas->deltaRight) || 0.0):
          (((numberp deltas->deltaTop) && deltas->deltaTop) || 0.0))
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkStretchRectangles
;;
;; Description:
;;   Resizes a list of rectangle database objects based on a set of edge
;;   delta values.  NOTE:  The rectangle is not modified if the operation
;;   would result in a zero-area bounding box.
;;
;; Inputs:
;;   - rectangles: a list of rectangle database objects.
;;   - deltas: a DPL with one or more of the following fields and values:
;;     . deltaLeft: amount to move the left edge horizontally.
;;     . deltaRight: amount to move the right edge horizontally.
;;     . deltaTop: amount to move the top edge vertically.
;;     . deltaBottom: amount to move the bottom edge vertically.
;;
;; Returns:
;;   The list of input rectangles, some or all of which are now modified
;;   by the specified amounts.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkStretchRectangles (rectangles deltas "ll")
  (prog (bBox)
    ;; Qualify the set of rectangles.
    (unless (forall rect rectangles
                    (dbobjectp rect) && (rect~>objType == "rect"))
      (warn "fdkStretchRectangles: improper rectangle list.")
      (return nil)
    )

    ;; Return the modified rectangles.
    (return
      (foreach rect rectangles
        bBox = (fdkStretchBoundingBox rect~>bBox deltas)
        (when (fdkIsBoundingBox bBox)
          rect~>bBox = bBox
        )
      )
    )
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkBoundingBoxToPointList
;;
;; Description:
;;   Converts a bounding box (list of lower-left and upper-right points) to
;;   a point list containing the lower-left, upper-left, upper-right, and
;;   lower-right points (in that order) of the rectangular region.
;;
;; Inputs:
;;   - bBox: the target bounding box (a list of lower-left and upper-right
;;     points).
;;
;; Returns:
;;   A list of points is returned if successful.  Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun
  fdkBoundingBoxToPointList
  (
    bBox
  "l"
  )
  (fdkIsBoundingBox bBox) &&
  (list (lowerLeft bBox) (fdkBoundingBoxUpperLeft bBox)
        (upperRight bBox) (fdkBoundingBoxLowerRight bBox))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkPointListToBoundingBox
;;
;; Description:
;;   Determines the bounding box of the smallest rectangular region
;;   containing the polygon specified by the given point list.
;;
;; Inputs:
;;   - points: the list of points comprising the target polygon.
;;
;; Returns:
;;   A bounding box is returned if successful.  Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun
  fdkPointListToBoundingBox
  (
    points
  "l"
  )
  (let (minX minY maxX maxY x y)
    (setq maxX (setq minX (xCoord (car points))))
    (setq maxY (setq minY (yCoord (car points))))
    (foreach point points
      (setq x (xCoord point))
      (setq y (yCoord point))
      (fdkLess x minX) && (setq minX x)
      (fdkLess y minY) && (setq minY y)
      (fdkGreater x maxX) && (setq maxX x)
      (fdkGreater y maxY) && (setq maxY y)
    )

    (list minX:minY maxX:maxY)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkPromoteHierShapesOnLPPs
;;
;; Description:
;;   Creates new shapes in the given cellview that represent shapes within
;;   or touching a given rectangular region.  The represented shapes may be
;;   either at the current level of hierarchy or at levels below.
;;
;; Inputs:
;;   - cv: the target cellview which must be editable.
;;   - bBox: the bounding box of the region in the cellview that will be
;;     considered.
;;   - lpps: a list of layer-purpose specifiers that will be searched for
;;     candidate shapes.
;;
;; Keyword inputs:
;;   - types: a list of Virtuoso database object types that will be
;;     considered for the search.
;;   - toPurpose: a string identifying the target purpose for each promoted
;;     shape.  If not specified, "drawing" is used.
;;   - hierDepth: the number of levels into the hierarchy below the current
;;     cellview that will be searched for shapes.  By default, this
;;     argument is 0 which causes only the given cellview to be searched.
;;   - addToNet: when non-nil, each level-zero shape is added to the net
;;     associated with the source shape.
;;
;; Returns:
;;   A list of new shapes in the current cellview.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkPromoteHierShapesOnLPPs
  (
    cv
    bBox
    lpps
  @key
    (types       '("donut" "ellipse" "path" "pathSeg" "polygon" "rect"))
    (toPurpose   "drawing")
    (hierDepth   0)
    (destCV      nil)
    (addToNet    nil)
    (includeLayerBlockages  nil)
  "dllltgggg"
  )
  (prog (shapes overlapData hierInfo shape stop item layerNames)
    ;; Qualify the cellview.
    (unless (cv~>objType == "cellView")
      (warn "fdkPromoteHierShapesOnLPPs: improper cellview: %L"
            cv)
      (return nil)
    )

    ;; Qualify the destination cellview if one was provided.
    (if destCV && !((dbobjectp destCV) && (destCV~>objType == "cellView"))
    then
      (setq destCV nil)
    else
      t
/*** ##################
      (when destCV~>mode == "r"
        (warn "fdkPromoteHierShapesOnLPPs: read-only destination cellview: %s %s %s"
              destCV~>libName destCV~>cellName destCV~>viewName)

        ;; We're done.
        (return nil)
      )
***/
    )

    ;; If no destination cellview was provided, the source cellview must
    ;; not be read-only.
/***  #####################
    (when !destCV && (cv~>mode == "r")
      (warn "fdkPromoteHierShapesOnLPPs: read-only cellview: %s %s %s"
            cv~>libName cv~>cellName cv~>viewName)

      ;; We're done.
      (return nil)
    )
***/
    ;; Qualify the region.
    (unless (fdkIsBoundingBox bBox)
      (warn "fdkPromoteHierShapesOnLPPs: improper bounding box: %L" bBox)
      (return nil)
    )

    ;; Qualify the LPPs.  Each must be of the form:
    ;; ("<layerName>" "<purpose>")
    (unless (forall lpp lpps (fdkIsLPPspec lpp) && (stringp (car lpp)) &&
                             (stringp (cadr lpp)))
      (warn "fdkPromoteHierShapesOnLPPs: improper LPPs: %L" lpps)
      (return nil)
    )

    ;; Qualify the hierarchy depth.
    (unless ((fixp hierDepth) && (not (minusp hierDepth))) ||
            ((listp hierDepth) && (fixp (car hierDepth)) &&
             (fixp (cadr hierDepth)) && (plusp (car hierDepth)) &&
             (plusp (cadr hierDepth)) &&
             ((car hierDepth) <= (cadr hierDepth)))
      (warn "fdkPromoteHierShapesOnLPPs: improper hierarchy depth: %L"
            hierDepth)
      (return nil)
    )

    ;; If layer blockage objects are requested, add them to the object
    ;; type list.  NOTE:  We do this for the sake of backward compatiblity.
    includeLayerBlockages && (setq types (cons "layerBlockage" types))

    (setq stop hierDepth)
    (listp hierDepth) && (setq stop (cadr hierDepth))

    ;; Qualify the destination purpose.
    (unless (fdkIsLayerOrPurposeSpec toPurpose)
      (warn "fdkPromoteHierShapesOnLPPs: improper destination purpose: %L"
            toPurpose)
      (return nil)
    )

    ;; Disable garbage collection during the overlapping shape derivation
    ;; as a means of improving performance.
    ;; NOTE:  Garbage collection MUST be ENABLED as soon as the operation
    ;; completes.
    gcdisable = t

    ;; Determine the shapes on the LPPs of interest within, overlapping, or
    ;; touching the given bounding box anywhere within the specified
    ;; hierarchy depth.
    ;; NOTE:  The final 't' argument to 'dbGetTrueOverlaps' enables
    ;; reporting of row and column information for shapes that are part
    ;; of mosiac instances.
    (foreach lpp lpps
      ;; Get information for normal shapes.
      (setq overlapData
            (nconc overlapData (dbGetTrueOverlaps cv bBox lpp hierDepth t)))
    )

    ;; If layer blockage information was requested...
    (when (member "layerBlockage" types)
      ;; Form a list of unique layer names present in the LPPs.
      (foreach lpp lpps
        (member (car lpp) layerNames) || (push (car lpp) layerNames)
      )

      ;; Process each layer name.
      (foreach layerName layerNames
        ;; Get information for layer blockages.
        (foreach info (dbLayerBlockageQuery cv layerName bBox 0 stop)
          (if (listp info) && (car info)
          then
            ;; Convert the hierarchy information returned from the layer
            ;; blockage query into the nested list format similar to that
            ;; returned by the 'db.*Overlaps' functions.
            (setq info (reverse info))

            (setq item (list (cadr info) (car info)))

            (foreach x (cddr info)
              (setq item (cons x (list item)))
            )
          else
            (setq item info)
          )

          ;; Add the hierarchy information for this layer blockage.
          (setq overlapData (cons item overlapData))
        )
      )
    )

    ;; Enable garbage collection.
    gcdisable = nil

    ;; Convert the overlap data into manageable information.
    (setq hierInfo (foreach mapcar o overlapData (fdkDeriveHierShapeInfo o)))

    ;; Process the set of interesting shapes appearing on the target LPPs.
    (foreach info (setof i hierInfo (member i->object~>objType types))
      ;; Copy the shape into the current cellview.
      (setq shape (dbCopyFig info->object destCV || cv info->transform))
      (unless shape
        (warn "fdkPromoteHierShapesOnLPPs: shape copy failed.")
        (return nil)
      )

      ;; Move the shape to the target purpose if necessary.
      (unless (shape~>purpose == toPurpose) &&
              (shape~>objType != "layerBlockage")
        shape~>lpp = list(shape~>layerName || shape~>layer toPurpose)
      )

      ;; If requested, add the new shape to the source shape's net.
      (when !destCV && addToNet && (dbobjectp info->object~>net) &&
            (info->object~>net~>cellView == cv)
        ;; Add the shape to its source object's net.
        (unless (dbAddFigToNet shape info->object~>net)
          (warn "fdkPromoteHierShapesOnLPPs: failed to add shape '%L' to net: %s"
                shape info->object~>net~>name)
          (return nil)
        )
      )

      ;; Add this shape to the promoted shape list.
      (push shape shapes)
    )

    ;; Return the promoted shapes.
    (return shapes)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkDeriveHierShapeInfo
;;
;; Description:
;;   Converts data returned from 'dbGetTrueOverlaps' into information that
;;   can be used to replicate a shape at an arbitrary level of hierarchy
;;   into the top-level cellview.
;;
;; Inputs:
;;   - data: a database object or a list of information returned from
;;     'dbGetTrueOverlaps'.
;;
;; Returns:
;;   A SKILL DPL containing the following fields and values:
;;   - hierarchy: an embeded list of instances (as returned by the SKILL
;;     'dbGetTrueOverlaps' API) within which the shape was found starting
;;     with the instance at the highest level of hierarchy.  This field
;;     is nil when the shape was found at level zero.
;;   - object: the shape itself.
;;   - transform: the orientation and location of the shape in the top-level
;;     cellview.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkDeriveHierShapeInfo (data "g")
  (prog (hierarchy transform inst) ;;;;mosaic row col
    ;; The shape is at level-zero.
    (when (dbobjectp data)
      (return (list nil 'hierarchy nil 'object data 'transform nil))
    )

    ;; Qualify the overlap information.
    (unless data && (listp data) &&
            ((dbobjectp (car data)) ||
            ((listp (car data)) && (dbobjectp (caar data))) ||
            ((listp (caar data)) && (dbobjectp (caaar data))))
      (return nil)
    )

    ;; Get the instance containing the shape.
    (unless (setq inst (car data))
      (return nil)
    )

    ;; Get the transform.
    (setq transform (fdkGetShapeTransformFromHierInfo inst))
/***** NOTE:  dbGetInstTransform is broken in the current Virtuoso release
       (IC6.1.5-64b.500.12).  Therefore, we call our own hierarchy transform
       calculation function which is slower but accurate.
    (if (isCallable 'dbGetInstTransform)
    ;;then
      ;; Get the (mostly) complete transform.
      (setq transform (dbGetInstTransform inst))
    ;;else
      ;; Get the initial transform.
      (setq transform (fdkGetShapeTransformFromHierInfo inst))
    )

    ;; If this instance is a mosaic instance, get the true instance and the
    ;; row and column from the mosaic information.
    (listp inst) && (dbobjectp (car inst)) && (setq row (cadr inst)) &&
    (setq col (caddr inst)) && (setq mosaic (car inst))
*****/
    ;; Establish the hiearchy data.
    (setq hierarchy data)

    ;; Get the remaining shape information.  NOTE: Now handling different
    ;; format returned from 'dbLayerBlockageQuery'.
    (setq data (cadr data))

    ;; Step through the remaining transform data.
    (while data && (listp data)
      ;; Get the containing instance.
      (setq inst (car data))

      ;; Apply this transform to the current transform.
      (setq transform
            (dbConcatTransform (fdkGetShapeTransformFromHierInfo inst)
                               transform)
      )

      ;; Move to the next level of hierarchy.
      (setq data (cadr data))
    )

    ;; The data is a list of information describing a shape within a mosaic
    ;; instance.  Compute and return the shape's transform from within the
    ;; mosaic.
/*****
    mosaic &&
    (setq
      transform
      (dbConcatTransform
        (list mosaic~>xy "R0" 1.0)
        transform
;;;        (list col*mosaic~>uX:row*mosaic~>uY "R0" 1.0)
;;;        (cons (mapcar 'minus (car transform)) (cdr transform))
      )
    )
*****/
/****
    (setq
      transform
      (dbConcatTransform
        (list (rodAddPoints mosaic~>xy col*mosaic~>uX:row*mosaic~>uY)
              "R0" 1.0)

        (dbConcatTransform
          (dbConcatTransform
            (list (mapcar 'minus mosaic~>xy) "R0" 1.0)

            (list 0.0:0.0 (car mosaic~>tileArray) 1.0)
          )

          (list mosaic~>xy "R0" 1.0)
        )
      )
    )
*****/
/****  col*mosaic~>uX:row*mosaic~>uY)
    (setq transform
          (dbConcatTransform transform
                             (list col*mosaic~>uX:row*mosaic~>uY "R0" 1.0)))
****/
/*******
    (setq
      transform
      (dbConcatTransform
        (list col*inst~>uX:row*inst~>uY "R0" 1.0)
        (list inst~>xy (car inst~>tileArray) 1.0)
      )
    )
    (setq
      transform
      (dbConcatTransform transform (list col*inst~>uX:row*inst~>uY "R0" 1.0))
    )
    (setq
      transform
      (dbConcatTransform
        transform
        (dbConcatTransform
          (list col*inst~>uX:row*inst~>uY "R0" 1.0)
          (list inst~>xy (car inst~>tileArray) 1.0)
        )
      )
    )
*******/
    ;; Return a DPL containing the derived object information.
    (return (list nil 'hierarchy hierarchy 'object data 'transform transform))
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkGetShapeTransformFromHierInfo
;;
;; Description:
;;   Determines the transform (orientation and location) information from
;;   data returned by 'dbGetTrueOverlaps'.
;;
;; Inputs:
;;   - data: a database object or a list of information returned from
;;     'dbGetTrueOverlaps'.
;;
;; Returns:
;;   A Virtuoso transform list (a location point, an orientation string,
;;   and a magnification number -- in that order).
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkGetShapeTransformFromHierInfo (data "g")
  (let (mosaic row col)
    ;; The format of the data depends upon the instance type.
    (cond
      ;; The data is an instance.
      ((dbobjectp data) && (data~>objType == "inst")
        ;; Return the instance's transform information.
        data~>transform
      )

      ;; The data is a standard via or custom via.
      ((dbobjectp data) &&
       ((data~>objType == "stdVia") || (data~>objType == "customVia"))
        ;; Return the via's origin and orientation as its transform.
        (list data~>origin data~>orient 1.0)
      )

      ;; The data is a mosaic.
      ((dbobjectp data) && (data~>objType == "mosaic")
        ;; Return the mosaic's location and orientation.
        (list data~>mosaic~>xy (car data~>mosaic~>tileArray) 1.0)
      )

      ;; The data is a list of information describing a shape within a
      ;; mosaic instance.
      ((listp data) && ((car data)~>objType == "mosaic")
        (setq mosaic (car data))
        (setq row (cadr data))
        (setq col (caddr data))

        ;; Compute and return the shape's transform from within the mosaic.
        (dbConcatTransform
          (list col*mosaic~>uX:row*mosaic~>uY "R0" 1.0)
          (list mosaic~>xy (car mosaic~>tileArray) 1.0)
        )
      )

      (t
        (warn "fdkGetShapeTransformFromHierInfo: unrecognized instance info: %L"
              data)
        ;; Return a default (and likely incorrect) transform.
        '((0.0 0.0) "R0" 1.0)
      )
    )
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkRemoveTemporaryDBobjects
;;
;; Description:
;;   Deletes a list of database objects from their respective cellview.
;;
;; Inputs:
;;   - objs: a list of database objects.
;;
;; Returns:
;;   If successful, a non-nil value is returned.  Otherwise, nil is
;;   returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkRemoveTemporaryDBobjects (objs "l")
  (prog (fails total)
    ;; Bail out if we have nothing to do.
    (unless objs
      (return nil)
    )

    ;; Initialize the counters.
    (setq fails 0)
    (setq total 0)

    ;; Qualify the list of objects.
    (when (exists obj objs !(dbobjectp obj))
      (warn "fdkRemoveTemporaryDBobjects: improper object list.")
      (return nil)
    )

    ;; Remove temporary shapes.
    (foreach obj objs
      ;; Increment the total counter.
      ++total

      ;; Attempt to remove the object and remember if unsuccessful.
      (when (dbValidP obj) && !(dbDeleteObject obj)
        ;; Don't need Virtuoso's built-in complaint here.
        (getWarn)

        ;; Increment the failure counter.
        ++fails
      )
    )

    ;; Issue a single complaint if one or more objects was not removed.
    (unless (zerop fails)
      (warn "fdkRemoveTemporaryDBobjects: failed to remove %d of %d objects."
            fails total)
      (return nil)
    )

    ;; Return success of the operation.
    (return t)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; Function: 
;;   fdkDeleteObjects
;; 
;; Description:
;;   This function deletes the objects in the supplied list
;;
;; Inputs:
;;   object - list of DB objects to delete
;;
;; Returns: t
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkDeleteObjects ( objects "l")
  (foreach obj objects          
    ;;;;(when (dbIsId obj) && !(dbDeleteObject)...)
    (unless (dbDeleteObject obj)
      (warn "fdkDeleteObjects: delete object failed: %L" obj)
    )
  )
  t
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; Function: 
;;   fdkDeleteTableObjects
;; 
;; Description:
;;   Delete the objects in the tables passed in
;;
;; Inputs:
;;   tableList - List of tables to process
;;
;; Returns: t
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkDeleteTableObjects ( tableList "l")
  (foreach table tableList
    (foreach dbId table
      (when (dbValidP dbId) (dbDeleteObject dbId))
    ) ;; foreach
  ) ;; foreach
  t
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; Function: 
;;   fdkSelectObjects
;; 
;; Description:
;;   Select the objects in the supplied list
;;
;; Inputs:
;;   object - list of DB objects to be selected
;;
;; Returns: t
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkSelectObjects ( objects "l")
  (foreach obj objects
    ;; Select the object.
    (geSelectObject obj)
  )
  t
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkAddShapesToNet
;;
;; Description:
;;   Adds each shape in the input list to the specified net.
;;
;; Inputs:
;;   - shapes: a list of database objects.
;;   - netName: the name of the net to which the shapes will be assigned.
;;
;; Returns:
;;   If successful, the list of input shapes is returned.  Otherwise, nil
;;   is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkAddShapesToNet (shapes netName "lt")
  (prog (net)
    ;; Qualify the shapes.
    (unless (forall shape shapes dbobjectp(shape))
      (warn "fdkAddShapesToNet: improper shape list.")
      (return nil)
    )

    ;; Qualify the net name.
    (when (blankstrp netName)
      (warn "fdkAddShapesToNet: improper net name.")
      (return nil)
    )

    ;; Attempt to associate each shape with the named net.
    (foreach shape shapes
      ;; Determine if the net exists in this cellview.
      (unless (setq net (dbFindNetByName shape~>cellView netName))
        ;; Attempt to create the net.
        (setq net (dbCreateNet shape~>cellView netName))
        (unless net
          (warn "fdkAddShapesToNet: '%s' net creation failed: %s %s %s"
                netName shape~>cellView~>libName shape~>cellView~>cellName
                shape~>cellView~>viewName)
          (return nil)
        )
      )
 
      ;; Add the shape to the net.
      (unless (dbAddFigToNet shape net)
        (warn "fdkAddShapesToNet: failed to add shape '%L' to net: %s"
              shape netName)
        (return nil)
      )

      ;; Add the "sticky net" property to the net so it will be retained in
      ;; Virtuoso-XL.
      (unless (dbReplaceProp shape "lxStickyNet" 'boolean t)
        (warn "fdkAddShapesToNet: failed to add VXL sticky net property to shape: %L"
              shape)
        (return nil)
      )
    )
    
    ;; Success.
    (return shapes)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkShapeToRectangles
;;
;; Description:
;;   Creates one or more rectangles from a single input shape.  If the
;;   shape contains non-orthogonal edges, certain portions of the shape
;;   will be represented by rectangular approximations.  If successful,
;;   this function always creates one or more new shapes in the input
;;   shape's cellview and on the input shape's LPP.
;;
;; Inputs:
;;   - shape: a shape database object.  NOTE:  The shape's cellview must
;;     be writable.
;;
;; Returns:
;;   If successful, a list of rectangle shapes representing the input shape
;;   is returned.  Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkShapeToRectangles (shape "d")
  (prog (rectangles shapes newShape mfgGrid)
    ;; The input database object must be a shape.
    (unless shape~>isShape
      (warn "fdkShapeToRectangles: not a shape: %L" shape)
      (return nil)
    )

    ;; The shape's cellview must be writable.
    (unless shape~>cellView~>mode != "r"
      (warn "fdkShapeToRectangles: cellview is read-only: %L" shape~>cellView)
      (return nil)
    )

    ;; Convert a label into a single, very small rectangle.
    (when shape~>objType == "label"
      ;; Get the technology's manufacturing grid.
      (setq
        mfgGrid
        (techGetMfgGridResolution (techGetTechFile (shape~>cellView))) ||
        0.001
      )

      ;; Create a tiny rectangle at the label's anchor point.  We do this
      ;; because only the label's anchor point is used to establish the
      ;; presence of the label from the perspective of connectivity rather
      ;; than the label's entire bounding box.
      (return
        (list (dbCreateRect shape~>cellView shape~>lpp
                            (list (rodAddPoints shape~>xy -mfgGrid:-mfgGrid)
                                  (rodAddPoints shape~>xy mfgGrid:mfgGrid))))
      )
    )

    ;; Convert certain shapes directly into a single rectangle.
    (when shape~>objType == "dot"
      (return (list (dbCreateRect shape~>cellView shape~>lpp shape~>bBox)))
    )
/***
    ;; Bail out if the work-horse function is unavailable.
    (unless (isCallable 'leConvertShapeToPolygon)
      (warn "fdkShapeToRectangles: cannot call: leConvertShapeToPolygon")
      (return nil)
    )

    ;; Create a copy of the target shape.
    (setq newShape (dbCopyShape shape shape~>cellView))
    (unless newShape
      (warn "fdkShapeToRectangles: shape copy failed: %L" shape)
      (return nil)
    )

    ;; Convert the shape to a polygon.
    (unless (leConvertShapeToPolygon newShape)
      (warn "fdkShapeToRectangles: converting shape to polygon failed: %L"
            newShape)
      (return nil)
    )
***/
    ;; Create rectangles and/or vertical-sided trapezoids from the
    ;; polygon.
;;    (setq shapes (dbLayerTile shape~>cellView shape~>lpp (list newShape)))
    (setq shapes (dbLayerTile shape~>cellView shape~>lpp (list shape)))
/***
    ;; Remove the shape copy.
    (unless (dbDeleteObject newShape)
      (warn "fdkShapeToRectangles: shape copy removal failed: %L" newShape)
      (return nil)
    )
***/
    ;; Get the resulting rectangles.
    (setq rectangles (setof s shapes s~>objType == "rect"))

    ;; Approximate non-rectangles.
    (foreach nonRect (setof s shapes s~>objType != "rect")
      ;; Create a rectangle to approximate the shape.
      (setq newShape (dbCreateRect shape~>cellView shape~>lpp nonRect~>bBox))
      (unless newShape
        (warn "fdkShapeToRectangles: rectangle creation failed: %L" shape)
        (return nil)
      )

      ;; Add the shape to the list of rectangles.
      (push newShape rectangles)

      ;; Remove the non-rectangular shape.
      (unless (dbDeleteObject nonRect)
        (warn "fdkShapeToRectangles: non-rectangle removal failed: %L" nonRect)
        (return nil)
      )
    )

    ;; Return the rectangles.
    (return rectangles)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkShapeGetOverlappingShapeInfo
;;
;; Description:
;;   Determines the set of shapes overlapping the given input shape.  
;;
;; Inputs:
;;   - shape: a shape database object.  NOTE:  The shape's cellview must
;;     be modifiable.
;;
;; Keyword inputs:
;;   - lpps: a list of target layer-purpose pairs.  When nil, shapes on
;;     all LPPs are considered.  Otherwise, only shapes on LPPs in this
;;     list are considered.  NOTE:  Each item in the list must be an LPP
;;     (a 2-element list of layer name and purpose strings) rather than
;;     just a layer name.
;;   - hierDepth: The number of hierarchy levels below the current level
;;     to search for overlapping shapes.
;;
;; Returns:
;;   If successful and if the input shape is overlapped by one or more
;;   shapes, a list of overlapping shape information is returned.  The
;;   information is in the format returned by 'fdkDeriveHierShapeInfo' --
;;   see the documentation of that function for more information.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkShapeGetOverlappingShapeInfo
  (
    shape
  @key
    (lpps       nil)
    (hierDepth  0)
  "dlx"
  )
  (prog ()
    ;; The input database object must be a shape.
    (unless shape~>isShape
      (warn "fdkShapeGetOverlappingShapeInfo: not a shape: %L" shape)
      (return nil)
    )

    ;; When appropriate, qualify the LPPs.  Each must be of the form:
    ;; ("<layerName>" "<purpose>")
    (when lpps
      (unless (forall lpp lpps (fdkIsLPPspec lpp) && (stringp (car lpp)) &&
                               (stringp (cadr lpp)))
        (warn "fdkShapeGetOverlappingShapeInfo: improper LPPs: %L" lpps)
        (return nil)
      )
    )

    ;; Return information for overlapping shapes on the appropriate LPPs.
    (return
      (setof o (fdkShapeGetOverlappingObjectInfo shape ?hierDepth hierDepth)
               o->object~>isShape && (!lpps || (member o->object~>lpp lpps)))
    )
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkShapeGetOverlappingObjectInfo
;;
;; Description:
;;   Determines the set of objects overlapping the given input shape.  
;;
;; Inputs:
;;   - shape: a shape database object.  NOTE:  The shape's cellview must
;;     be modifiable.
;;
;; Keyword inputs:
;;   - hierDepth: The number of hierarchy levels below the current level
;;     to search for overlapping shapes.
;;
;; Returns:
;;   If successful and if the input shape is overlapped by one or more
;;   objects, a list of overlapping object information is returned.  The
;;   information is in the format returned by 'fdkDeriveHierShapeInfo' --
;;   see the documentation of that function for more information.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkShapeGetOverlappingObjectInfo
  (
    shape
  @key
    (hierDepth  0)
  "dx"
  )
  (prog (rectangles overlapInfo overlaps)
    ;; The input database object must be a shape.
    (unless shape~>isShape
      (warn "fdkShapeGetOverlappingObjectInfo: not a shape: %L" shape)
      (return nil)
    )

    ;; Adjust the hierarchy depth if necessary.
    (cond
      ((minusp hierDepth)
        (setq hierDepth 0)
      )
      (hierDepth > (dbGetMaxHierDepth)
        (setq hierDepth (dbGetMaxHierDepth))
      )
    )

    ;; Get the set of rectangles representing the region occupied by this
    ;; shape.
    (setq rectangles (fdkShapeToRectangles shape))

    ;; Determine the set of shapes overlapping or touching the rectangles
    ;; representing the input shape.
    (foreach rect rectangles
      ;; Get information regarding objects overlapping or touching this
      ;; rectangle.
      (setq
        overlaps
        (foreach mapcar i (dbGetTrueOverlaps shape~>cellView
                                             rect~>bBox t 0:hierDepth t)
          (fdkDeriveHierShapeInfo i)
        )
      )

      ;; Filter uninteresting objects.
      (setq
        overlapInfo
        (nconc
          (setof o overlaps (o->object != shape) &&
                            !(member o->object rectangles) &&
                            !(member o overlapInfo))
          overlapInfo
        )
      )
    )

    ;; Remove the rectangles representing the input shape.
    (unless (forall r rectangles (dbDeleteObject r))
      (warn "fdkShapeGetOverlappingObjectInfo: temporary shape removal failed.")
      (return nil)
    )

    ;; Return the overlapping shape information.
    (return overlapInfo)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkShapeGetConnectedShapeInfo
;;
;; Description:
;;   Determines the set of shapes electrically connected to the given
;;   input shape.  
;;
;; Inputs:
;;   - shape: a shape database object.  NOTE:  The shape's cellview must
;;     be writable.
;;
;; Keyword inputs:
;;   - hierDepth: The number of hierarchy levels below the current level
;;     to search for overlapping shapes.
;;   - purpose: The purpose on which connectivity shapes reside.  If a list
;;     of strings is provided, each named purpose is considered.
;;   - box: The bounding box within which the shape search is contained. NOTE:
;;     Any shape coincident with or partially overlapping this bounding box is
;;     included in the search.
;;   - visited: A table of shapes already considered in the search.
;;   - techConn: A table of connectivity information for the given process.
;;
;; Returns:
;;   A table of electrically connected shape information is returned.  The
;;   key of each table entry is a shape occurrence comprised of a list of
;;   the shape in question optionally followed by the hierarchy of
;;   instances within which it resides (if the shape was found below the
;;   current cellview).  The value of each table entry is in the format
;;   returned by 'fdkDeriveHierShapeInfo' -- see the documentation of that
;;   function for a description of this DPL.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkShapeGetConnectedShapeInfo
  (
    shape
  @key
    (hierDepth  0)
    (purpose    "drawing")
    (box        nil)
    (visited    nil)
    (techConn   nil)
  "dxglgg"
  )
  (prog (connectedInfo shapes currentShape tech layerUp layerDown layers
         overlapInfo currentInfo cv interesting purposes)
    ;; The input database object must be a shape.
    (unless shape~>isShape
      (warn "fdkShapeGetConnectedShapeInfo: not a shape: %L" shape)
      (return nil)
    )

    ;; Get the shape's cellview.
    (setq cv shape~>cellView)

    ;; The shape's cellview must be writable.
    (unless cv~>mode != "r"
      (warn "fdkShapeGetConnectedShapeInfo: cellview is read-only: %L" cv)
      (return nil)
    )

    ;; Qualify the purpose or purpose list.  Must be a single, non-empty
    ;; string or a list of non-empty strings containing at least one element.
    (unless ((stringp purpose) && !(blankstrp purpose)) ||
            ((listp purpose) && (car purpose) &&
             (forall p purpose (stringp p) && !(blankstrp p)))
      (warn "fdkShapeGetConnectedShapeInfo: improper purpose or purpose list: %L"
            purpose)
      (return nil)
    )

    ;; If a single purpose was specified, convert it to a one-element list.
    (when (stringp purpose)
      (setq purposes (list purpose))
    )

    ;; If no layer connectivity information was specified..
    (unless (tablep techConn)
      ;; Get the technology associated with this shape.
      (setq tech (techGetTechFile cv))
      (unless tech
        (warn "fdkShapeGetConnectedShapeInfo: shape technology retrieval failed: %L"
              shape)
        (return nil)
      )

      ;; Get the interconnect information associated with this technology.
      (setq techConn (fdkGetTechInterconnectTable tech))
      (unless techConn
        (warn "fdkShapeGetConnectedShapeInfo: no connectivity information for technology: %L"
              tech)
        (return nil)
      )
    )

    ;  If a region was given...
    (when box
      ;  Qualify the bounding box.
      (unless (fdkIsBoundingBox box)
        (warn "fdkShapeGetConnectedShapeInfo: improper bounding box: %L" box)
        (return nil)
      )
    )

    ;; Ignore this shape if it is not on an interconnect layer.
;;    unless (fdkIsLayerInterconnect shape~>layerName techConn)
    (unless techConn[shape~>layerName]
;;      (warn "fdkShapeGetConnectedShapeInfo: shape is not interconnect: %L"
;;            shape)
      (return nil)
    )

    ;; Create a table for the connected shapes.
    (setq connectedInfo (makeTable "connected" nil))
    (unless connectedInfo
      (warn "fdkShapeGetConnectedShapeInfo: connected shape table creation failed.")
      (return nil)
    )
/***  SKILL profiler showed this approach to be slower than using 'member'.
    ;; Create a table for shapes on the to-be-visited stack.
    (setq onStack (makeTable "onStack" nil))
    (unless onStack
      (warn "fdkShapeGetConnectedShapeInfo: on-stack table creation failed.")
      (return nil)
    )
***/
    ;; Adjust the hierarchy depth if necessary.
    (cond
      ((minusp hierDepth)
        (setq hierDepth 0)
      )
      (hierDepth > (dbGetMaxHierDepth)
        (setq hierDepth (dbGetMaxHierDepth))
      )
    )

    ;; Initialize the stack of shapes to follow.
    (setq shapes (list (list nil 'object shape)))
/***  SKILL profiler showed this approach to be slower than using 'member'.
    ;; Add this initial shape to the on-stack table.
    onStack[(car shapes)] = (car shapes)
***/
    ;; Find shapes connected to those in the shape stack.
    (while shapes
      ;; Pop the shape stack.
      (setq currentInfo (pop shapes))
/***  SKILL profiler showed this approach to be slower than using 'member'.
      ;; Remove this shape from the on-stack table.
      (remove currentInfo onStack)
***/
      (prog ()
        ;; Ignore certain shapes.
        (currentInfo->object~>objType == "label") && (return nil)
        (currentInfo->object~>objType == "textDisplay") && (return nil)

        ;; Bail out if this shape occurrence has been visited...
        !(tablep visited) ||
        ((tablep visited) &&
         !visited[(cons currentInfo->object currentInfo->hierarchy)]) ||
        (return nil)

        ;; If a bounding box was specified for the search, determine if the
        ;; shape's bounding box touches or overlaps the region.
        !box ||
        (box &&
          (fdkBoundingBoxesIntersect
            dbTransformBBox(currentInfo->object~>bBox currentInfo->transform ||
                                                      '((0.0 0.0) "R0" 1.0))
            box)) || (return nil)

        ;; Get the upwardly adjacent interconnect layer (if any).
        (setq
          layerUp
          (fdkGetInterconnectLayerUp currentInfo->object~>layerName techConn)
        )

        ;; Get the downwardly adjacent interconnect layer (if any).
        (setq
          layerDown
          (fdkGetInterconnectLayerDown currentInfo->object~>layerName techConn)
        )

        ;; Bail out if this shape is not involved in connectivity.
        layerUp || layerDown || (return nil)

        ;; Initialize the search layer list with this shape's LPP.
        (setq layers (list currentInfo->object~>lpp))

        ;; If appropriate, add this layer to the search layers.
        (when layerUp
          (foreach purpose2 purposes
            (setq layers (cons (list layerUp purpose2) layers))
          )
        )

        ;; If appropriate, add this layer to the search layers.
        (when layerDown
          (foreach purpose2 purposes
            (setq layers (cons (list layerDown purpose2) layers))
          )
        )
;;pprint(layers) newline()
        ;; Get or promote the current shape.
        (if currentInfo->hierarchy
        then
          ;; Promote the shape from hierarchy.
          (setq
            currentShape
            (dbCopyShape currentInfo->object cv currentInfo->transform)
          )
          (unless currentShape
            (warn "fdkShapeGetConnectedShapeInfo: shape copy failed: %L"
                  currentInfo->object)
            (return nil)
          )

          ;; Remove any children that may have followed this promoted shape.
          ;; For example, a shape with an attached label will create an
          ;; extraneous label in the current cellview when the shape is
          ;; promoted.
          (foreach c currentShape~>children
            (unless (dbDeleteObject c)
              (warn "fdkShapeGetConnectedShapeInfo: removal of shape child failed: %L"
                    currentShape)
              (return nil)
            )
          )
        else
          ;; Use the level-zero shape.
          (setq currentShape currentInfo->object)
        )

        ;; Mark this shape occurrence as visited by registering its
        ;; hierarchical path.  NOTE:  For performance reasons, the shape ID
        ;; appears first in this list followed by instances from the current
        ;; level of hierarchy and below to the one containing the shape.
        connectedInfo[(cons currentInfo->object
                            currentInfo->hierarchy)] = currentInfo

        ;; Find shapes on the vertically adjacent layers overlapping the
        ;; current shape.
        (setq
          overlapInfo
          (fdkShapeGetOverlappingShapeInfo
            currentShape
            ?lpps layers
            ?hierDepth hierDepth
          )
        )

        ;; If overlapping shapes were found, push them on the stack if they
        ;; are not already scheduled to be visited.
        (when overlapInfo
          ;; Reject the shape if it is scheduled to be visited or has been
          ;; visited.
          (setq interesting
               (setof i overlapInfo
                      !((member i shapes) ||
                        connectedInfo[(cons i->object i->hierarchy)])))
/***  SKILL profiler showed this approach to be slower than using 'member'.
          ;; Reject the shape if it is scheduled to be visited or has been
          ;; visited.
          (setq interesting
               (setof i overlapInfo
                      !(onStack[i] ||
                        connectedInfo[(cons i->object i->hierarchy)])))

          ;; Add the insteresting shape information to the on-stack table.
          (foreach i interesting onStack[i] = i)
***/
          ;; Add the insteresting shape info to the stack.
          (setq shapes (nconc interesting shapes))
        )

        ;; If we promoted a shape we should remove it now.
        (when currentInfo->hierarchy
          (unless (dbDeleteObject currentShape)
            (warn "fdkShapeGetConnectedShapeInfo: shape removal failed: %L"
                  currentShape)
            (return nil)
          )
        )

        (return t)
      )
    )

    ;; Return the table of connected shape information.
    (return connectedInfo)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkGetInterconnectLayerUp
;;
;; Description:
;;   Fetches the layer name for the interconnect layer that is immediately
;;   above the named layer within the given technology interconnect table.
;;
;; Inputs:
;;   - layerName: the target layer name.
;;   - techConn: the technology interconnect database (a SKILL table).
;;
;; Returns:
;;   If successful, the name of the layer above the given layer is returned.
;;   returned.  Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkGetInterconnectLayerUp
  (
    layerName
    techConn
  "to"
  )
  (let (layerIndex)
    ;; Get the index of the target layer.
    (setq layerIndex techConn[layerName])

    ;; Return the name of the upwardly adjacent layer or nil if no such
    ;; layer exists.
    (fixp layerIndex) && techConn[layerIndex + 1]
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkGetInterconnectLayerDown
;;
;; Description:
;;   Fetches the layer name for the interconnect layer that is immediately
;;   below the named layer within the given technology interconnect table.
;;
;; Inputs:
;;   - layerName: the target layer name.
;;   - techConn: the technology interconnect database (a SKILL table).
;;
;; Returns:
;;   If successful, the name of the layer below the given layer is returned.
;;   Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkGetInterconnectLayerDown
  (
    layerName
    techConn
  "to"
  )
  (let (layerIndex)
    ;; Get the index of the target layer.
    (setq layerIndex techConn[layerName])

    ;; Return the name of the downwardly adjacent layer or nil if no such
    ;; layer exists.
    (fixp layerIndex) && techConn[layerIndex - 1]
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkGetInterconnectLayerIndex
;;
;; Description:
;;   Finds the zero-based position of the named layer within the given
;;   technology technology interconnect table.
;;
;; Inputs:
;;   - layerName: the target layer name.
;;   - techConn: the technology interconnect database (a SKILL table).
;;
;; Returns:
;;   If successful, an integer representing the named layer's location in
;;   the layer function database is returned.  Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkGetInterconnectLayerIndex
  (
    layerName
    techConn
  "to"
  )
  ;; Return the layer's index or nil if the layer was not found.
  techConn[layerName]
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkGetInterconnectLayerFunction
;;
;; Description:
;;   Fetches the layer function string for the named layer within the
;;   given technology interconnect table.
;;
;; Inputs:
;;   - layerName: the target layer name.
;;   - techConn: the technology interconnect database (a SKILL table).
;;
;; Returns:
;;   If successful, the layer function string for the named layer is
;;   returned.  Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkGetInterconnectLayerFunction
  (
    layerName
    techConn
  "to"
  )
  ;; Return the layer's function or nil if the layer was not found.
  techConn[(list 'function layerName)]
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkIsLayerInterconnect
;;
;; Description:
;;   Determines if the named layer is an interconnect layer within the
;;   given technology interconnect table.
;;
;; Inputs:
;;   - layerName: the target layer name.
;;   - techConn: the technology interconnect database (a SKILL table).
;;
;; Returns:
;;   If the layer exists in the technology's layer function database and
;;   the layer is an interconnect layer, a non-nil value is returned.
;;   Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkIsLayerInterconnect
  (
    layerName
    techConn
  "to"
  )
  techConn[layerName]
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkGetTechInterconnectTable
;;
;; Description:
;;   Creates an association table for interconnect in the given technology.
;;   This table is indexed in three ways:
;;   - By layer name; returns the layer's interconnect index number.
;;   - By layer index number; returns the layer name.
;;   - By a list of '(function "layerName")'; returns the function (either
;;     "cut" or "metal") of the 'layerName' layer.
;;
;; Inputs:
;;   - techConn: the technology interconnect database (a SKILL table).
;;
;; Returns:
;;   If successful, a table of interconnect information for the given
;;   technology is returned.  Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkGetTechInterconnectTable
  (
    tech
  "d"
  )
  (prog (techConn layerFunctions)
    ;; Qualify the technology database.
    (unless tech~>objType == "techFile"
      (warn "fdkGetTechInterconnectTable: improper technology: %L" tech)
      (return nil)
    )

    ;; Get the layer function database associated with the given technology.
    (setq layerFunctions (techGetLayerFunctions tech))
    (unless layerFunctions
      (warn "fdkGetTechInterconnectTable: no layer functions: %L" tech)
      (return nil)
    )

    ;; Get the function for this layer.
    (setq techConn (makeTable "conn" nil))
    (unless techConn
      (warn "fdkGetTechInterconnectTable: table creation failed.")
      (return nil)
    )

    ;; Build the interconnect table.  We are only interested in layers that
    ;; are of type 'cut' or 'metal'.
    (foreach layer (setof i layerFunctions (or ((cadr i) == "li")
                                               ((cadr i) == "metal")
                                               ((cadr i) == "cut")))
      ;; Index this layer by layer name returning the layer number.
      techConn[(car layer)] = (caddr layer)

      ;; Index this layer by layer number returning the layer name.
      techConn[(caddr layer)] = (car layer)

      ;; Index this layer by '(function "layerName")' returning its function..
      techConn[(list 'function (car layer))] = (cadr layer)
    )

    ;; Return the interconnect table.
    (return techConn)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkGetReferencedTechnologies
;;
;; Description:
;;   Derives a list of technologies referenced from the given top-level
;;   technology.  This is useful in methodoligies where Incremental
;;   Technology Database (ITDB) is used.
;;
;; Inputs:
;;   - tech: the top-level technology database.
;;
;; Returns:
;;   If the top-level technology refers to a subordinate technology, the
;;   subordinate technology and any technology it references, and so on,
;;   are returned in a list.  Otherwise, nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(
  fdkGetReferencedTechnologies(
    tech
  "d"
  )
  prog((techs stack ref)
     ;  Qualify the source technology.
    unless(tech~>objType == "techFile"
      warn("fdkGetReferencedTechnologies: improper technology: %L" tech)
      return(nil)
    )

    ;  Initialize the stack with this technology's references.
    stack = tech~>refs

    ;  Search for additional referenced technologies.
    while(stack
      ;  Get the current reference technology.
      ref = pop(stack)

      ;  If this technology has not been visted yet, add it to the list of
      ;  referenced technologies.
      member(ref techs) || push(ref techs)

      ;  If this technology has references...
      when(ref~>refs
        ;  Push them onto the stack.
        stack = append(stack ref~>refs)
      )
    )

    ;  Return he referenced techologies.
    return(techs)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkUnique
;;
;; Description:
;;   Take in a list, and return the list with unique elements only;
;;   with all duplicates removed.
;;
;; Inputs:
;;   - A list.
;;
;; Returns:
;;   The input list with all duplicate elements removed, such that the
;;   returned list contains only unique elements.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(
  fdkUnique(
    thelist
  "l"
  )
  prog((tmptbl)
    ;  Initialize table to store unique list elemments
    (setq tmptbl makeTable('table nil))
    foreach(elem thelist (tmptbl[elem] = t)) 
    (return tmptbl~>?)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkProcessIs1275
;;
;; Description:
;;   Determine if the specified technology is 1275 or not
;;
;; Inputs:
;;   - tech: The tech file object
;;
;; Returns:
;;   t if the technology is marked as 1275
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(
  fdkProcessIs1275(
    tech
  "d"
  )
  let( (processName)
    when( processName = techGetParam(tech "processName")
      rexMatchp("1275" processName)
    )
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkIsWspMode
;;
;; Description:
;;   Wrapper function for ctkIsWspMode which is not defined in 1275.
;;
;; Returns:
;;   t if ctkIsWspMode is not define (as in 1275 we only have WSP mode) or
;;   whatever ctkIsWspMode returns (in 1273).
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure( fdkIsWspMode()
  !isCallable('ctkIsWspMode) || ctkIsWspMode()
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkDisplayProgressBox
;;
;; Description:
;;   Initialize and show a progress dialog box and associate it with the
;;   current (QuickFill) form for further progress updates.
;;
;; Keyword inputs:
;;   - text: The initial label to show.
;;   - totalSteps: The number of steps to reach 100% completion.
;;   - form: (optional) The QuickFill invocation form.
;;
;; Returns:
;;   The progress dialog or nil on failure
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(
  fdkDisplayProgressBox(
  @key
    (text "Command has started. Please wait...")
    (totalSteps 100) 
    (form hiGetCurrentForm())
  "txr"
  )
  prog( (location banner hiSym progressBox)
    unless( hiIsForm(form)
      return()
    )

    ;; Position the progress dialog within the QuickFill form.
    when( location = hiGetFormLocation(form)
      location = list(xCoord(location)+10 yCoord(location)+100)
    )

    ;; Ensure the progress label is long enough for a minimum box width
    sprintf(text "%-90s" text)

    ;; Ensure no old progress box is still displayed
    fdkCancelProgressBox(?form form)

    ;; Display the progress form 
    banner = strcat(form->_formName " Progress")
    hiSym = gensym("fdkProgressBox")
    unless( hiDisplayProgressBox(
              ?name       hiSym
              ?text       text
              ?banner     banner
              ?location   location
              ?totalSteps totalSteps
            )
      return(nil) 
    )

    ;; Use the current form's title as the current command name.
    ;; Associate the progressBox with the current form.
    progressBox = eval(hiSym)
    progressBox->cmdName = form->_formName
    form->progressBox = progressBox

    return(progressBox)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkCancelProgressBox
;;
;; Description:
;;   Cancel the progress box that's associated with the current form.
;;
;; Keyword inputs:
;;   - form: (optional) The (QuickFill) invocation form.
;;
;; Returns:
;;   t if a progress form was found and could be cancelled, nil otherwise
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(
  fdkCancelProgressBox(
  @key
    (form hiGetCurrentForm())
  "r"
  )
  let( (progressBox)
    when( hiIsForm(form) && (progressBox = form->progressBox)
      form->progressBox = nil
      unless( hiIsProgressBoxCancelled(progressBox) 
        hiCancelProgressBox(progressBox)
      )
    )
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkSetProgressAndText
;;
;; Description:
;;   Update the progress box associated with the current form to show progress.
;;   Both the progress step and/or the text can be specified.
;;   If a verbose info text is provided it is printed to the CIW.
;;
;; Keyword inputs:
;;   - step: A number up to the totalStep max of the progress box.
;;   - text: The new label to show in the progress box.
;;   - verbose: Indicate if the progress should be shown or not.
;;   - form: The (QuickFill) invocation form.
;;
;; Returns:
;;   t if progress box was found, nil otherwise
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(
  fdkSetProgressAndText(
  @key
    (step -1)
    (text "")
    verbose
    (form hiGetCurrentForm())
  "ntgr"
  )
  let( (progressBox)
    when( verbose
      ;; Echo the text to the CIW.
      fdkInfo(text form)

      when( hiIsForm(form) && (progressBox = form->progressBox)
        ;; Ensure the progress label is long enough for a minimum box width.
        sprintf(text "%-90s" text)

        when( step >= 0
          ; Ensure the step is an integer.
          hiSetProgress(progressBox round(step))
        )
        unless( blankstrp(text)
          hiSetProgressText(progressBox text)
        )

        t
      ) 
    )
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkInfo
;;
;; Description:
;;   Print the specified text to the CIW and prefix it with the current cmd.
;;
;; Inputs:
;;   - text: The text to print out.
;;   - form: (optional) The (QuickFill) invocation form.
;;
;; Returns:
;;   t if text is not a null string, nil otherwise
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(
  fdkInfo(
    text
  @optional
    (form hiGetCurrentForm())
  "tg"
  )
  let( (cmdName)
    unless( blankstrp(text)
      when( cmdName = fdkGetCurrentCommandName(form)
        text = strcat(cmdName ": " text)
      )

      info(text)
      drain(poport)

      t 
    )
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkWarn
;;
;; Description:
;;   Issue a warning with the provided text and prefix it with the current cmd.
;;
;; Inputs:
;;   - text: The text to print out.
;;   - form: (optional) The (QuickFill) invocation form.
;;
;; Returns:
;;   nil
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(
  fdkWarn(
    text
  @optional
    (form hiGetCurrentForm())
  "tg"
  )
  let( (cmdName)
    unless( blankstrp(text)
      when( cmdName = fdkGetCurrentCommandName(form)
        text = strcat(cmdName ": " text)
      )

      warn(text)
    )
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkGetCurrentCommandName
;;
;; Description:
;;   Get the title from the current progress box or its parent form (if any). 
;;
;; Inputs:
;;   - form: (optional) The (QuickFill) invocation form.
;;
;; Returns:
;;   The title of the current form or nil if no form is currently active.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(
  fdkGetCurrentCommandName(
  @optional
    (form hiGetCurrentForm())
  "g"
  )
  let( (progressBox)
    when( hiIsForm(form)
      progressBox = form->progressBox
      progressBox->cmdName || form->_formName
    )
  )
)
