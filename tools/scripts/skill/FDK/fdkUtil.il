;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkEmit
;;
;; Description:
;;   Emits a formatted message to the function given.
;;
;; Inputs:
;;   - fun: the function to use when emitting (e.g. 'warn, 'error, 'printf).
;;     If this is set to nil then no action is taken.
;;   - @rest: remaining formatting string and arguments for formatting to
;;     the function given.
;;
;; Returns:
;;   The return value fo calling the passed function.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkEmit (fun @rest args)
  (when fun
    (apply fun args)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkCopyVars
;;
;; Description:
;;   Works off of fdkSetVars to copy a list of variables to another
;;   corresponding set of variables.  This assumes that ?prefix and/or ?suffix
;;   is used.  It is meaningless to use this without using one or the other.
;;
;; Inputs:
;;   - fun: a function (typically lambda) that accepts exactly two arguments:
;;     a variable name (as a symbol) and a variable value.  The return value
;;     from this function is the new value for the variable.
;;   - vars: a list of variables to set.
;;
;; Keyword Inputs:
;;   - ?prefix: an optional prefix for the variable name that is set
;;   - ?suffix: an optional suffix for the variable name that is set
;;
;; Returns:
;;   The list of variable names that were set.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkCopyVars (@rest args)
  (apply 'fdkSetVars (append (list (lambda (var val) val)) args)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkSetVars
;;
;; Description:
;;   Sets many variables to a new value given a function (kind of like mapcar
;;   but a list of variable names is passed instead of values and this also
;;   has a side-effect of resetting the input variable's value).
;;
;; Inputs:
;;   - fun: a function (typically lambda) that accepts exactly two arguments:
;;     a variable name (as a symbol) and a variable value.  The return value
;;     from this function is the new value for the variable.
;;   - vars: a list of variables to set.
;;
;; Keyword Inputs:
;;   - ?prefix: an optional prefix for the variable name that is set
;;   - ?suffix: an optional suffix for the variable name that is set
;;
;; Returns:
;;   The list of variable names that were set.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkSetVars (fun vars @key prefix suffix)
  (let (retvar)
    (mapcar (lambda (var)
              (setq retvar var)
              (when prefix (setq retvar (concat prefix retvar)))
              (when suffix (setq retvar (concat retvar suffix)))
              (set retvar (funcall fun var (symeval var))))
            vars)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function:
;;   fdkLimitIntParamVal
;;
;; Description:
;;   It takes paramValue which should be integer and check if it 
;;   between min and max values. Returns a value which is between 
;;   min and max values.
;;
;; Inputs:
;;   - paramValue : parameter value to check.
;;   - paramPrompt: Prompt for the parameter name to print in messages.
;;
;; optional Inputs:
;;   - minVal : minimum value for the parameter value.
;;   - maxval : maximum value for the parameter value.
;;   - step   : If number should increase in steps.
;;
;; Returns:
;;   parameter value between min and max values.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


procedure( fdkLimitIntParamVal( paramValue paramPrompt @optional minVal maxVal stepVal )
  let(( stepParamVal newParamValue )

    paramValue = round( paramValue )
    cond(
      ( minVal && paramValue < minVal
        artWarn( "Param: %L value is less than minimum, setting to minimum value %L." paramPrompt minVal )
        paramValue = minVal
      )
      ( maxVal && paramValue > maxVal
        artWarn( "Param: %L value is more than maximum, setting to maximum value %L." paramPrompt maxVal )
        paramValue = maxVal
      )
    )
    when( stepVal
        stepParamVal = round( float( paramValue )/float(stepVal) )*stepVal
        unless( paramValue == stepParamVal
          artWarn( "Param: %L value is rounded to nearest multiple of %L to new value %L." paramValue stepVal stepParamVal)
          paramValue = stepParamVal
        )
        cond( 
          ( paramValue < minVal
            newParamValue = paramValue + stepVal
            artWarn( "Param: %L value is less than minimum, rounded to %L." paramValue newParamValue )
            paramValue    = newParamValue
          )
          ( paramValue > maxVal
            newParamValue = paramValue - stepVal
            artWarn( "Param: %L value is more than maximum, rounded to %L." paramValue newParamValue )
            paramValue    = newParamValue
          )
        )
    )
    paramValue
  )
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdkMin
;;
;; Description:
;;   Compares two numbers.
;;
;; Returns:
;;   Smaller of the 2 input values.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure(fdkMin(a b)
  let(
    (result)

    if(fdkCmp(a "<=" b) then
        result = a
    else
        result = b
    )

    result
  )
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdkMax
;;
;; Description:
;;   Compares two numbers.
;;
;; Returns:
;;   Bigger of the 2 input values.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun fdkMax (a b)
  (let (result)
    if( fdkCmp(a ">=" b) then
        result = a
    else
        result = b
     )
     result
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdkMinExpr
;; 
;; Description:
;;   Compares two numbers.
;;   Note - identical to fdkMin.  Added to match Tcl fdkMinExpr.
;;
;; Returns:
;;   Smaller of the 2 input values.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure(fdkMinExpr(a b)
  let(
    (result)

    if(fdkCmp(a "<=" b) then
        result = a
    else
        result = b
    )

    result
  )
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: fdkMaxExpr
;;
;; Description:
;;   Compares two numbers.
;;   Note - identical to fdkMax.  Added to match Tcl fdkMaxExpr.
;;
;; Returns:
;;   Bigger of the 2 input values.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun fdkMaxExpr (a b)
  (let (result)
    if( fdkCmp(a ">=" b) then
        result = a
    else
        result = b
     )
     result
  )
)

