;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Intel Top Secret                                                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copyright (C) 2016, Intel Corporation.  All rights reserved.             ;;
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

procedure( _fdlAelNumToString( thing)
    let( ()
      cond(
        (thing && integerp( thing) sprintf(nil "%d" thing))
        (thing && floatp( thing) sprintf(nil "%.15e" thing))
        (t thing)
      )
    )
)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description: Performs input evaluation and validation for CDF parameters.
; Example:
; adAelEval(
;    ?entry "1"  ?visualFormat "%d"
;    ?minimum 1  ?maximum 5
;    ?default 3
;    ?preProc 'mypreproc
;    ?doneProc 'mydoneproc
;    ?debug nil)
; See comments in procedure for argument specs.
; Return:
;    Evaluated parameter, which should evaluate suffixes and functions where it can.
;    otherwise 'nil if it fails for bad syntax.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 procedure( adAelEval(  @key
        (entry nil)
        (visualFormat "%L")  ; "visually" format as integer or float or string.  Return-value type-checking is done internally.
        (aelSuffix   nil)   ; flag to output in ael suffix notation, if numeric.
        (minimum    nil )   ; minimum value for parameter, if numeric.
        (grid    nil )    ; grid value for parameter, if numeric.
        (maximum    nil )   ; maximum value for parameter, if numeric.
        (default    nil )   ; default value for parameter.
        (preProc nil) ; symbol of procedure to call before eval on "entry",
        (doneProc   nil) ; symbol of procedure to call after eval, is passed the result of the eval.
        (debug    nil)   ; print error messages.
        (desc     nil)   ; optional description, like parameter name
        (noBlank nil)        ; disallow blank input.
        (noVar nil)        ; disallow non-numeric input.
        (cmpTol 1e-13) ; do something like this to override ???
        (noreset   nil)   ; flag to prevent values set to default from then being reset again.
        )
    let(
            (env expr reject result retVal descErr formatType entryName entryValue resetToDefault)
            resetToDefault=nil
            if( symbolp( entry) then
                entryValue = symeval( entry)
                unless( desc
                    desc = symbolToString(entry)
                )
            else
                entryValue = entry
            )
            if( desc then
                sprintf(descErr "%s: " desc)
            else
                descErr = ""
            )
            formatType = car( reverse( parseString(visualFormat "")))
            reject = !entryValue || (noBlank && blankstrp(entryValue))
            if( !reject then 
               entryValue = _fdlAelNumToString( entryValue)
               ;; call preproc if we have one.
               when( boundp( 'preProc) && preProc
                   apply(getd(preProc) list(entryValue))
               )
               when( debug
                   printf("\nEntry: \"%s\"\n" entryValue)
               )
               when( maximum && stringp( maximum)
                    maximum = cdfParseFloatString( maximum)
               )
               when( minimum && stringp( minimum)
                    minimum = cdfParseFloatString( minimum)
               )
               when( grid && stringp( grid)
                    grid = cdfParseFloatString( grid)
               )
               ;;; add significant digits beyond the 8 default to prevent rounding
               aelPushSignifDigits(12)
               ;; create an environment that will evaluate the input as an expression.
               ;; "o" = evaluate operators (+, -, etc.) when possible
               ;; "c" = do function calls as possible
               ;; "s" = evaluate suffixes like "u" and "f"
               env = aelEnvCreate( "ocs" nil nil)
 
               ;; this will compile the user entry against our AEL environment
               expr = aelEnvCompile(env entryValue)
               if( !expr then
                   warn("%sError evaluating expression: \"%s\"\n" descErr entryValue)
                   ;; Son, we should set this to result = nil to be consistent.
                   result = nil
               else
                   ;; execute the compiled expression and then free up some memory.
                   result = aelEnvExecute( expr)
                   aelEnvFreeCompExpr(expr)
               ) ;if
            else  ;reject it
                result = nil
            );if
            retVal = nil
            ;; if the compile worked, turn in back into a number.
            ;; if it failed and you provided a default, set it back to the default.
            if( result then
                retVal = cdfParseFloatString(result)
                unless( retVal  retVal = result    )
            else
                 when( default
                    warn("Setting result to default of %L\n" default)
                    retVal = default
                    if( noreset then  resetToDefault = t        )
                );when
            ); if result
            when( (noVar && not(numberp(retVal))) 
                 warn( "%sValue %L is non-numeric value.  Setting result to default: %L\n" descErr result default)
                 if( noreset then resetToDefault = t  )
                 retVal = default)
            when( retVal && numberp(retVal) 
                  cond(
                     (minimum && adCmp(minimum ">" retVal cmpTol) && not(resetToDefault)  warn( "%sValue %L is less than minimum of %L.  Setting result to %L\n" descErr result minimum minimum) retVal = minimum)

                     (maximum && adCmp(maximum "<" retVal cmpTol) && not(resetToDefault)  warn( "%sValue %L is greater than maximum of %L. Setting result to %L\n" descErr result maximum maximum) retVal = maximum)
                 )                                                                                          
                 when(grid retVal = adSnapGrid(grid retVal))
                 cond(
                     (formatType == "d"  retVal = sprintf( nil visualFormat fix(retVal)))                   
                     (aelSuffix retVal = (aelSuffixNotation retVal 6))
                     (t retVal = sprintf( nil visualFormat retVal) )                                        
                 )                                                                                          
             );when                                                                                              
            when( debug  printf("Final--> %L\n" retVal )  )
            when( boundp( 'doneProc) && doneProc  apply(getd(doneProc) list(retVal))   )
	aelPopSignifDigits()
retVal )); proc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Description:
;;   Single function to do a compare using symbols ==, != >= <= > and <.
;;   4th argument is optional--the floating point precision.  If not
;;   defined ('unbound) it will check the current cell for technology.
;;   NOTE: the scale used for this technology value will be in microns 
;;   and NOT meters, so precision with be 1/10th of the smallest process
;;   value in microns.
;;   If no current cell will use adFloatTolerance which is the correct
;;   value when dealing with meters.
;;   Generally it is a good idea to pass in the tolerance number that
;;   matches the scale of f1 and f2.
;;   Returns t if comparison is true (to tolerance) and nil if false.
;; Inputs:
;;   - a and b: The two floating point numbers to compare
;;   - cmp: a string of either ==, != >= <= > or <.
;;   - prec: floating point number to scale of f1 and f2 as a little less then
;;     the smallest number
;; Returns:
;;   t or nil.  If an error, ends as an error with message.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(adCmp(a cmp b @optional prec) 
let( (ceq)
  if(prec == nil then prec=1e-13 )
  if( floatp(prec) && (floatp(a) || fixp(a)) && (fixp(b) || floatp(b))  then
    ceq = (abs(a - b) < prec)
    cond(
      (cmp == "=="  ceq  ) 
      (cmp == "!="  !ceq ) 
      (cmp == ">="  (or ceq (a > b)) ) 
      (cmp == ">"   (if ceq nil (a > b))    )
      (cmp == "<="  (or ceq (a < b))	    ) 
      (cmp == "<"   (if ceq nil (a < b))    )
      (t error("Error: adCmp doesn't understand %L\n" cmp) nil )
    );cond
  else error("Error: adCmp can only compare floating point, not: %L %L %L to precision %L\n" a cmp b prec)
    nil );if
));proc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Description:
;;   Snaps the given point to the nearest given grid value (up or down).
;; Inputs:
;;   - grid: the target grid value to snap (e.g. 0.005)
;;   - point: the point (float number) to snap
;; Returns:
;;   The snapped point (float number)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(adSnapGrid(grid point)
let(( (fltGrid float(grid)) ptLower ptUpper)
  ptLower = floor(point/fltGrid)*fltGrid  
  ptUpper = ceiling(point/fltGrid)*fltGrid
  (if adCmp( (ptUpper-point) ">" (point-ptLower))    ptLower ptUpper  )
));proc
