;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Intel Top Secret                                                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copyright (C) 2009-2012, Intel Corporation.  All rights reserved.        ;;
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
;;   fdkFloatCompare.il
;;
;; Description:
;;   Provides comparison functions that use a tolerance to check equality.
;;   This helps test for equiality in light of floating point accuracy issues
;;   that are so bothersome in floating point computing applications.
;;
;; Globals:
;;   - fdkFloatTolerance: the tolerance used for equality.  This value
;;     should be small and not be larger than the last significant decimal
;;     place.  For example, when comparing numbers at the nanometer level,
;;     then this value should be at least below 1e-9 (preferably far below it
;;     such as 1e-12).
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; The tolerance used in testing for equality (except for fdkCmp)
; changed to 1e-14 from 1e-13 to accomodate .5 nm.
fdkFloatTolerance = 1e-14

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdk_is_eq
;;
;; Description:
;;   Compares equality of two floating numbers within a given threshold
;;   (from fdkFloatTolerance).
;;
;; Inputs:
;;   - a: The first number to consider
;;   - b: The second number to consider
;;
;; Returns:
;;   t when the delta between a and b is below the fdkFloatTolerance global
;;   threshold variable (nil otherwise).
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdk_is_eq (a b)
  (abs (a - b)) < fdkFloatTolerance)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdk_is_ne
;;
;; Description:
;;   Same as (fdk_is_eq) but checks for inequality.
;;
;; Inputs:
;;   - a: The first number to consider
;;   - b: The second number to consider
;;
;; Returns:
;;   t when the delta between a and b is beyond the fdkFloatTolerance
;;   global threshold variable (nil otherwise).
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdk_is_ne (a b)
  (not (fdk_is_eq a b)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdk_is_gt
;;
;; Description:
;;   Greater-than comparison function considering an equality tolerance.
;;
;; Inputs:
;;   - a: The first number to consider
;;   - b: The second number to consider
;;
;; Returns:
;;   t if a != b using (fdk_is_eq) and a > b; otherwise nil.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdk_is_gt (a b)
  (if (fdk_is_eq a b) nil (a > b)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdk_is_lt
;;
;; Description:
;;   Less-than comparison function considering an equality tolerance.
;;
;; Inputs:
;;   - a: The first number to consider
;;   - b: The second number to consider
;;
;; Returns:
;;   t if a != b using (fdk_is_eq) and a < b; otherwise nil.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdk_is_lt (a b)
  (if (fdk_is_eq a b) nil (a < b)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdk_is_ge
;;
;; Description:
;;   Greater-than-or-equal-to comparison function considering an equality
;;   tolerance.
;;
;; Inputs:
;;   - a: The first number to consider
;;   - b: The second number to consider
;;
;; Returns
;;   t if a == b using (fdk_is_eq) or a > b; otherwise nil.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdk_is_ge (a b)
  (or (fdk_is_eq a b) (a > b)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdk_is_le
;;
;; Description:
;;   Less-than-or-equal-to comparison function considering an equality
;;   tolerance.
;;
;; Inputs:
;;   - a: The first number to consider
;;   - b: The second number to consider
;;
;; Returns:
;;   t if a == b using (fdk_is_eq) or a < b; otherwise nil.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdk_is_le (a b)
  (or (fdk_is_eq a b) (a < b)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdk_are_points_eq
;;
;; Description:
;;   Compares two coordinate points (x/y pair) using the (fdk_is_eq) function.
;;
;; Inputs:
;;   - pt1: A list of an x/y coordinate pair
;;   - pt1: A list of an x/y coordinate pair to compare against pt1
;;
;; Returns:
;;   t if x and y values in pt1 equal pt2 using (fdk_is_eq); otherwise nil.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdk_are_points_eq (pt1 pt2)
  (and (fdk_is_eq (xCoord pt1) (xCoord pt2))
       (fdk_is_eq (yCoord pt1) (yCoord pt2))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdk_are_bboxes_eq
;;
;; Description:
;;   Compares two bounding boxes for equality using (fdk_are_points_eq) on
;;   both lower-left and upper-right coordinate pairs.
;;
;; Inputs:
;;   - bbox1: The first bounding box
;;   - bbox2: The second bounding box to compare against bbox1
;;
;; Returns:
;;   t if the set of coordinate pairs in bbox1 equal bbox2 using (fdk_is_eq);
;;   otherwise nil.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdk_are_bboxes_eq (bbox1 bbox2)
  (and (are_points_eq (car bbox1) (car bbox2))
       (are_points_eq (cadr bbox1) (cadr bbox2))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdk_is_in_range_set
;;
;; Description:
;;   Determines if a float value is within the range of a list of given
;;   float values using (fdk_is_ge) and (fdk_is_le).
;;
;; Inputs:
;;   - val: The value to check
;;   - rangeSet: A set of values the min/max of which will constitute a range
;;
;; Returns:
;;   t if the checked value is within the range of numbers given; otherwise
;;   nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdk_is_in_range_set (val rangeSet)
  (and (fdk_is_ge val (apply 'min rangeSet))
       (fdk_is_le val (apply 'max rangeSet))))

(defun fdk_sort_floats (floats)
  (sort floats 'fdk_is_lt))

;; BUGGY.  Try: (fdk_sort_uniq_floats '(0.6 0.4 0.6))
;; May also want to use tconc/lconc instead of append1 as well
;; 
;; (defun fdk_sort_uniq_floats (floats)
;;   (let ((sortedFloats (sort_floats floats)) uniqFloats this next)
;;     (for i 0 (length floats)-1
;; 	 this = (nth i floats)
;; 	 next = (nth i+1 floats)
;; 	 (when (or (not next)
;; 		   (fdk_is_ne this next))
;; 	   uniqFloats = (append1 uniqFloats this)))
;;     uniqFloats))

;; TODO: document
(defun fdk_uniq_floats (floats)
  (when (and floats (listp floats))
    (let ((uniqFloats (tconc nil nil)))
      ;; Go through each successive sublist
      (foreach float floats
	(when (and (numberp float)
		   (or (null (cadr uniqFloats))
		       (not (fdk_float_member float (cdr (car uniqFloats))))))
	  ;; Is a number and is not on unique list yet
	  (lconc uniqFloats (list float))))
      ;; Return the unique list part of the tconc structure
      (cdr (car uniqFloats)))))

;; TODO: document
(defun fdk_float_member (ref floats)
  (car (setof x floats (fdk_is_eq x ref))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdk_cmp_assoc
;;
;; Description:
;;   Applies the given comparison function (fdk_cmp_fn) to the key against the
;;   first element of each association pair (apairs).  The first association
;;   pair where cmp_fn is true will be returned.  Example:
;;
;;   (fdk_cmp_assoc 'fdk_is_eq 0.2 (list (list 4.0 6.1)
;;                                 (list 0.2 9.2)
;;                                 (list 0.2 0.0)))
;;   => (0.2 9.2)
;;
;; Inputs:
;;   - cmp_fun: The comparison function as a symbol (e.g. 'fdk_is_eq)
;;   - key: The reference value to compare (will be on the left side of the
;;     comparison)
;;   - apairs: The list of association pairs to compare
;;
;; Returns:
;;   t if the checked value is within the range of numbers given; otherwise
;;   nil is returned.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdk_cmp_assoc (cmp_fn key apairs)
  (car (setof x apairs (apply cmp_fn key (list (car x))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdk_snap_to_closest
;;
;; Description:
;;   Takes a reference numerical value and a list of other numerical values.
;;   The value(s) closest to the reference value is returned.  A list value
;;   is returned and may have multiple elements if there are multiple values
;;   equidistant from the reference value.  Note, if a value is repeated in
;;   the list of values given, and if that value is one of the "closest" to
;;   the reference point, then the value could be repeated more than once.
;;   It may be desirable to wrap fdk_uniq_floats around this function.
;;
;;   (fdk_find_all_closest 0.5 (list 0.6 0.9 0.3))
;;   => (0.6)
;;
;;   (fdk_find_all_closest 0.5 (list 0.6 0.9 0.4))
;;   => (0.6 0.4)
;;
;;   (fdk_find_all_closest 0.5 (list 0.6 0.9 0.4 0.6))
;;   => (0.6 0.4 0.6)
;;
;; Inputs:
;;   - ref: The reference value to compare
;;   - values: A list of numerical values to compare against
;;
;; Returns:
;;   A list of values that are closest to the given reference value.  More
;;   than one value will be returned in the list if some points are
;;   equidistant to the reference and/or there are repeated values given.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdk_find_all_closest (ref values)
  (let (closest closestDelta delta)
    (foreach value values
      ;; get delta between the reference and current value
      delta = (abs (ref-value))
      (cond
       ;; Is closestDelta not set or is the current delta < closestDelta?
       ((or (null closestDelta)
	    (fdk_is_lt delta closestDelta))
        closest = (list value)
	closestDelta = delta)
       ;; Is the closestDelta == the current delta?
       ((fdk_is_eq delta closestDelta)
	closest = (cons value closest))))
    ;; Return the list of values
    closest)
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdkCmp
;;
;; Description:
;;   Single function to do a compare using symbols ==, != >= <= > and <.
;;   4th argument is optional--the floating point precision.  If not
;;   defined ('unbound) it will check the current cell for technology.
;;
;;   NOTE: the scale used for this technology value will be in microns 
;;   and NOT meters, so precision with be 1/10th of the smallest process
;;   value in microns.
;;
;;   If no current cell will use fdkFloatTolerance which is the correct
;;   value when dealing with meters.
;;
;;   Generally it is a good idea to pass in the tolerance number that
;;   matches the scale of f1 and f2.
;;
;;   Returns t if comparison is true (to tolerance) and nil if false.
;;
;; Inputs:
;;   - a and b: The two floating point numbers to compare
;;   - cmp: a string of either ==, != >= <= > or <.
;;   - prec: floating point number to scale of f1 and f2 as a little less then
;;     the smallest number
;;
;; Returns:
;;   t or nil.  If an error, ends as an error with message.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkCmp (a cmp b @optional prec) 
    (let (ceq)
        if( prec == nil then
            prec=fdkFloatTolerance
        )
        if( floatp(prec) && 
            (floatp(a) || fixp(a)) &&
            (fixp(b) || floatp(b))  then
            ceq = ((abs (a - b)) < prec)
            cond(
                (cmp == "==" 
                    ceq
                ) 
                (cmp == "!=" 
                    !ceq
                ) 
                (cmp == ">=" 
                    (or ceq (a > b))
                ) 
                (cmp == ">" 
                    (if ceq nil (a > b))
                )
                (cmp == "<=" 
                    (or ceq (a < b))
                ) 
                (cmp == "<" 
                    (if ceq nil (a < b))
                )
                (t 
                    error("Error: fdkCmp doesn't understand %L\n" cmp)
                    nil
                )
            )
        else
            error("Error: fdkCmp can only compare floating point, not: %L %L %L to precision %L\n" a cmp b prec)
            nil
            
        )
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  fdkFindMember will walk through a list and do fdkCmp if val and valList
;;  element is a number...and if success returns the valList element
;;  if no success on any, returns nil. More complicated if cmp is not == and
;;  there are more than 1 hit...then the closest is returned.  For numbers
;;  and non-equal it will serve as a closest value return.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure( fdkFindMember(val valList @key (cmp "=="))
    let( 
        (
            earlyReturn closest matchDelta bestVal lastMatchDelta
            useFdkCmp i continue lenValList
            
        )
        bestVal = nil
        if(cmp == "==" then
            earlyReturn = t
        else
            earlyReturn = nil
            lastMatchDelta = nil
        )
        if(numberp(val) then
            useFdkCmp=t
        else
            useFdkCmp=nil
        )
        ; foreach listVal valList with continue flag...
        i=0
        continue=t
        lenValList=length(valList)
        while(i<lenValList && continue
            listVal=nth(i valList)
            if(numberp(listVal) && useFdkCmp then
                ; use fdkCmp if both are numbers
                if(fdkCmp(val cmp listVal) then
                    if(earlyReturn then
                        ; found an equal, return it immediately
                        bestVal=listVal
                        continue=nil
                    else
                        ;remember the closest match and return when loop ends
                        matchDelta = abs(listVal-val)
                        if(lastMatchDelta ==nil then
                            ;this is the first match, so keep it
                            lastMatchDelta = matchDelta
                            bestVal=listVal
                        else
                            if(fdkCmp(matchDelta "<" lastMatchDelta) then
                                ;listVal is closest (so far) to val, so keep it
                                bestVal=listVal
                                lastMatchDelta = matchDelta
                            )
                        )
                    )
                )
            else
                ;use cond on cmp to do normal comparison
                ;just return the first value
                cond(
                    (cmp == "==" 
                        if(val == listVal then
                            bestVal=listVal
                            continue=nil
                        )
                    ) 
                    (cmp == "!=" 
                        if(val != listVal then
                            bestVal=listVal
                            continue=nil
                        )
                    ) 
                    (cmp == ">=" 
                        if(val >= listVal then
                            bestVal=listVal
                            continue=nil
                        )
                    ) 
                    (cmp == ">" 
                        if(val > listVal then
                            bestVal=listVal
                            continue=nil
                        )
                    )
                    (cmp == "<=" 
                        if(val <= listVal then
                            bestVal=listVal
                            continue=nil
                        )
                    ) 
                    (cmp == "<" 
                        if(val < listVal then
                            bestVal=listVal
                            continue=nil
                        )
                    )
                    (t
                        continue=nil
                        nil
                    )
                )
            )
            i=i+1
        )
        ; return bestVal.  If nil, no match was found
        bestVal
    )
)
