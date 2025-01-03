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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkCreateCellCDF
;;
;; Description:
;;   Finds a CDF by the library and cell name given, yields the CDF to the
;;   given function and then saves the CDF afterwards.
;;
;; Inputs:
;;   - libName: the library name
;;   - cellName: the cell name
;;   - fn: the function to yield the CDF object to
;;
;; Returns:
;;   t
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkCreateCellCDF (libName cellName fn)
  (let (cellId cdf)
    (if (cellId = (ddGetObj libName cellName))
      ;; Got the cell
      (if (cdf = (or (cdfGetBaseCellCDF cellId) (cdfCreateBaseCellCDF cellId)))
	;; Got the CDF - remove old contents now and repopulate
	(progn
	  (cdfDeleteCDF cdf)
	  cdf  = (cdfCreateBaseCellCDF cellId)
	  (funcall fn cdf)
	  (cdfSaveCDF cdf))
	;; Else, did not get the CDF
	(error "Could not get the CDF for %L/%L\n" libName cellName))
      ;; Else, could not get the cell
      (error "Cannot open cell to edit CDF: %L/%L\n" libName cellName))
    t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkCdfDebug
;;
;; Description:
;;   Prints a debug message if the FDK_CDF_DEBUG global variable is set to
;;   the debug level numerical value (or t for all levels).  Note, fprintf
;;   is called to the stdout port to avoid Pcell evaluation errors that are
;;   seen when printf is used.
;;
;; Inputs:
;;   - level: A numerical value indicating the debug level to print.  A
;;     lower level value will print important debug statements whereas a
;;     higher debug level can be used for more detailed messages that a user
;;     may want to suppress.  Common values are (1-5).
;;   - @rest: The remaining arguments are the same as those that would be
;;     given to printf (e.g. a format string optionally followed by variables
;;     used to fill placeholders in the format string).
;;
;; Returns:
;;   The return value of fprintf which is t.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkCdfDebug (level @rest args)
  (when (and (boundp 'FDK_CDF_DEBUG)
	     (or (FDK_CDF_DEBUG == t)
		 (and (integerp FDK_CDF_DEBUG) (FDK_CDF_DEBUG >= level))))
    (apply 'fprintf (cons stdout args))))

procedure( fdkCdfDisplayDebug()
    let( (display)
        display=nil
        if( boundp('FDK_CDF_DEBUG)
            if( (fixp(FDK_CDF_DEBUG) && (FDK_CDF_DEBUG >= 1)) then
                display=t
            )
        )
        display
    )
)
procedure( fdkNull()
    let( ( )
        t
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkCdfEnforceDefault
;;
;; Description:
;;   Prints a formatted message indicating that a bad CDF value was received
;;   and then sets a variable name to a default value.
;;
;; Inputs:
;;   - wfun: warning function to use (as a symbol; e.g. 'artError).  No
;;     warning is emitted if wfun is set to nil.
;;   - param: the parameter name as a symbol.  A variable by this same name
;;     will be reset to the default value provided.
;;   - value: the current parameter value (for display in the error message)
;;   - default: the default value to apply.  This can be nil in which case
;;     no action will be taken and no error message produced.
;;   - formatstr: a string to display an error message.  This must contain
;;     exactly two %L placeholders for the parameter name and value
;;     respectively.
;;
;; Returns:
;;   The return value of the warning/error message function.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkCdfEnforceDefault (wfun param value default formatstr)
  (let (foo)
  (if default
    (progn
      (setq foo 'param)
      (fdkEmit wfun (strcat formatstr " - setting to default (%L)\n") foo value default)
      (set param default))
    (fdkEmit wfun (strcat formatstr "\n") foo value))
  nil))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkCdfIsPosIntValue
;;
;; Description:
;;   Checks that the value given is a positive integer value.  If not then
;;   a default value is enforced (using fdkCdfEnforceDefault).  The value
;;   given can be a string or an integer.
;;
;; Inputs:
;;   - param: the parameter name as a symbol.  A variable by this same name
;;     will be reset to the default value provided.
;;   - value: the current parameter value.  This can be an integer or a
;;     string formatted as an integer.
;;   - default: the default value to apply.  This can be nil in which case
;;     no action will be taken and no error message produced.
;;   - wfun: warning function to use (as a symbol; e.g. 'artError).  No
;;     warning is emitted if wfun is set to nil.
;;
;; Returns:
;;   t
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkCdfIsPosIntValue (param value default @key (wfun 'artError))
  ;; ---> CHECK: param !~ /^\s*$/ (when string)
  ;; ---> CHECK: param >= 1 (when number)
  (if (not (or (and (stringp value) (fdkCdfStrHasContents param value default ?wfun wfun))
               (and (integerp value) (fdkCdfIsPosInt param value default ?wfun wfun))))
    (fdkCdfEnforceDefault wfun param value default "Unexpected value/type for parameter (%L=%L)")
    t))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkCdfIsPosInt
;;
;; Description:
;;   Checks that the value given is a positive integer value.  If not then
;;   a default value is enforced (using fdkCdfEnforceDefault).  The value
;;   given must be an integer (not a string).  Accordingly, this is more
;;   stringent than fdkCdfIsPosIntValue.;;    
;;
;; Inputs:
;;   - param: the parameter name as a symbol.  A variable by this same name
;;     will be reset to the default value provided.
;;   - value: the current parameter value.  This must be an integer.
;;   - default: the default value to apply.  This can be nil in which case
;;     no action will be taken and no error message produced.
;;   - wfun: warning function to use (as a symbol; e.g. 'artError).  No
;;     warning is emitted if wfun is set to nil.
;;
;; Returns:
;;   t
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkCdfIsPosInt (param value default @key (wfun 'artError))
  (if (not (and (integerp value) (greaterp value 0)))
    (fdkCdfEnforceDefault wfun param value default "Non-positive integer given for parameter (%L=%L)")
    t))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkCdfParseIntString
;;
;; Description:
;;   Parses a string formatted as an integer to an integer value.
;;
;; Inputs:
;;   - str: the string to parse.
;;
;; Returns:
;;   The respective integer value.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkCdfParseIntString (str)
  (let ((value (cdfParseFloatString str)))
    (if (floatp value) (round value) value)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkCdfStrHasContents
;;
;; Description:
;;   Ensures that a string has non-space contents (not an empty string or a
;;   string with just spaces).
;;
;; Inputs:
;;   - param: the parameter name as a symbol.  A variable by this same name
;;     will be reset to the default value provided.
;;   - value: the current parameter value.
;;   - default: the default value to apply.  This can be nil in which case
;;     no action will be taken and no error message produced.
;;   - wfun: warning function to use (as a symbol; e.g. 'artError).  No
;;     warning is emitted if wfun is set to nil.
;;
;; Returns:
;;   t if the string has contents or nil if otherwise.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkCdfStrHasContents (param value default @key (wfun 'artError))
  (if (and (stringp value) (or (equal value "") (rexMatchp "^ +$" value)))
    (fdkCdfEnforceDefault wfun param value default "Empty string given for parameter (%L=%L)")
    t))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkCdfConstructValue
;;
;; Description:
;;   Constructs a string, integer, or floating-point value into a string
;;   value.  In the case of a floating-point value units will be added.
;;
;; Inputs:
;;   - value: the value to convert.
;;
;; Returns:
;;   A string representation of the value.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkCdfConstructValue (value)
  (case (type value)
    (string value)
    (fixnum (sprintf nil "%d" value))
    (flonum
     (let ((absval (abs value)) units norm)
       (setq units (cond
                    ((fdk_is_gt absval 1e24) "Y")
                    ((and (fdk_is_ge absval 1e9)   (fdk_is_le absval 1e12)) "G")
                    ((and (fdk_is_ge absval 1e6)   (fdk_is_le absval 1e9)) "M")
                    ((and (fdk_is_ge absval 1e3)   (fdk_is_le absval 1e6)) "k")
                    ((and (fdk_is_ge absval 1e0)   (fdk_is_le absval 1e3)) "")
                    ((and (fdk_is_le absval 1e0)   (fdk_is_ge absval 1e-3)) "m")
                    ((and (fdk_is_le absval 1e-3)  (fdk_is_ge absval 1e-6)) "u")
                    ((and (fdk_is_le absval 1e-6)  (fdk_is_ge absval 1e-9)) "n")
                    ((and (fdk_is_le absval 1e-9)  (fdk_is_ge absval 1e-12)) "p")
                    (t "")))
       ;;(fdkCdfDebug 99 "Units found for value %L is %L\n" value units)
       ;; If we can do this ourselves, then let's convert it to an integer.
       ;; This is because some numbers (e.g. 1e-4) will add a bunch of
       ;; superfluous trailing zeros.
       (setq norm ((1/(cdfParseFloatString (sprintf nil "1%s" units)))*value))
       (if (lessp (abs norm-(round norm)) 1e-12)
         (sprintf nil "%d%s" (round norm) units)
         (cdfFormatFloatString (sprintf nil "%g" value) units))))
    (t (artError "Value type not supported: %L (%L)" (type value) value))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkCdfParseFloatString
;;
;; Description:
;;   Converts a string into a floating-point equivalent based on
;;   cdfParseFloatString.  If the number is provided without units then it
;;   is assumed to be in nanometers.  Strings are passed through as-is.
;;
;; Inputs:
;;   - fstr: the string value to convert.
;;
;; Keyword Inputs:
;;   - ?grid: an optional grid to snap the floating-point result to.
;;   - ?propName: the property name being converted for display purposes.
;;
;; Returns:
;;   A floating point value in nanometers if conversion happened properly.
;;   If the conversion didn't work or if the value is a variable, then the
;;   string is passed back as-is.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkCdfParseFloatString (fstr @key grid propName)
  (let ((value    (cdfParseFloatString fstr))
	(errpre   (strcat "Error setting parameter"
			  (if propName (sprintf nil " (%L): " propName) ": ")))
	snapValue retval)

    (setq retval
          (cond
           ((integerp value)
            ;; Is an integer - assume in nanometers as-is
            value)
           ((floatp value)
            ;; Is a number
            ;; Convert value in meters to be assumed in nanometer units
            (if (value < 1e-3) (value*1e9) value))
           ((or (stringp value) (null value))
            ;; Just pass the previous value through
            fstr)
           (t 
            ;; Else, is not a number or a string
            (warn (sprintf nil "%sNon-float or string value: %L\n" errpre value)))))

    (when (and grid (numberp retval))
      ;; Snap value to grid if needed
      snapValue = (fdkSnapGrid grid retval)
      (when (fdk_is_ne retval snapValue)
        retval = snapValue))

    retval))


;###################################
; Subroutine: fdkIsLayout
; Description: determines if the current cell is a layout view
; Returns: true if it layout, otherwise returns false
;
; ******* WARNING ********
; Any changes to this subroutines functionality must be duplicated in the cooresponding TCL subroutine
; located at $SYNOPSYS_CUSTOM_SITE/tcl/fdkCdfCommon.il
;###################################
(defun fdkIsLayout ()
 (let ( )
    (geGetEditCellView()~>cellViewType == "maskLayout")
 ) ;; let
)


;###################################
; Subroutine: fdkAllowNfsub
; Description: Determines if nfsub should be displayed. This requires the following:
;      Variable  fdkDisableSubfingering defined and set to non nil
;      AND variable  fdkUnlimitMosWf either not defined or set to nil
; Return: returns "t" on a valid condition to enable nfSub and '0' when nfSub should be disabled
;
; ******* WARNING ********
; Any changes to this subroutines functionality must be duplicated in the cooresponding TCL subroutine
; located at $SYNOPSYS_CUSTOM_SITE/tcl/fdkCdfCommon.il
;###################################
(defun fdkAllowNfsub ()
 (let ()
    (fdkIsLayout)&&boundp('fdkUnlimitMosWf)&&fdkUnlimitMosWf&&(!boundp('fdkDisableSubfingering)||fdkDisableSubfingering==nil)
 ) ;; let
)


;###################################
; Subroutine: fdkIsChoiceMember
; Description: Determines if a value is included in a choice list.
;              This routine is limited. It only supports the cdfListId to be one of two values (wSelect or lSelect).
;              This is because I could not find a way to make this generic in the SKILL routine (this TCL in generic).
; Return:
;    If the value to be tested is "other", then return nil
;    otherwise test value against the choice list
;       return 't' if it exists, else return nil
;
; ******* WARNING ********
; Any changes to this subroutines functionality must be duplicated in the cooresponding TCL subroutine
; located at $SYNOPSYS_CUSTOM_SITE/tcl/fdkCdfCommon.il
;###################################
(defun fdkIsChoiceMember (value cdfListId)
 (let (result)  
   result = nil
   if(cdfListId == "wSelect" then
       if(cdfgData->wSelect->value == "other" then
            result = nil
       else
            result = (member value cdfgData->wSelect->choices)
       )
    else
        if(cdfListId == "lSelect" then
            if(cdfgData->lSelect->value == "other" then
                result = nil
            else
                result = (member value cdfgData->lSelect->choices)
            )
        )
   )
   result
 )  ;;let
)


procedure( _fdlAelNumToString( thing)
    let( ()
      cond(
        (thing && integerp( thing) sprintf(nil "%d" thing))
        (thing && floatp( thing) sprintf(nil "%.15e" thing))
        (t thing)
      )
    )
)

;###################################
; Subroutine: fdkAelEval
; Description: Performs input evaluation and validation for CDF parameters.
; Example:
; fdkAelEval(
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
;
 procedure( fdkAelEval(  @key
        (entry nil)
        (visualFormat "%L")  ; "visually" format as integer or float or string.  Return-value type-checking is done internally.
        (aelSuffix   nil)   ; flag to output in ael suffix notation, if numeric.
        (msgGrid nil)       ; flag to output message when snapping to grid.
        (msgSuff nil)       ; flag to convert numeric values to aelSuffix notation in messages.
        (minimum    nil )   ; minimum value for parameter, if numeric.
        (grid    nil )    ; grid value for parameter, if numeric.
        (offset  0 )    ; offset value for grid of parameter, if numeric.
        (maximum    nil )   ; maximum value for parameter, if numeric.
        (default    nil )   ; default value for parameter.
        (preProc nil) ; symbol of procedure to call before eval on "entry",
        (doneProc   nil) ; symbol of procedure to call after eval, is passed the result of the eval.
        (debug    nil)   ; print error messages.
        (desc     nil)   ; optional description, like parameter name
        (noBlank nil)        ; disallow blank input.
        (noVar nil)        ; disallow non-numeric input.
        (cmpTol fdkFloatTolerance) ; do something like this to override ???
        (snapType "half") ;Gives user an option to snap up or down or half 
        (noreset   nil)   ; flag to prevent values set to default from then being reset again.
        )
    let(
            (env expr reject result retVal descErr 
             formatType entryName entryValue tmpVal resetToDefault
             noPlusEntryValue warnString expr2 env2
            )
            resetToDefault=nil

            ;create temporary function fdkSuf which works differently depending on msgSuff 
            if(msgSuff==t then
                procedure( fdkSuf( value)
                    if(numberp(value) then
                     (aelSuffixNotation (value*1e-6) 6)
                    else
                     value
                    )
                )
            else
                procedure( fdkSuf( value)
                    value
                )
            )

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
            warnString = ""
            formatType = car( reverse( parseString(visualFormat "")))
            reject = !entryValue || (noBlank && stringp(entryValue) && blankstrp(entryValue))
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
               when( offset && stringp( offset)
                    offset = cdfParseFloatString( offset)
                    if((numberp(grid) && not(numberp(offset))) then
                        offset=0
                    )
               )

               ;;; add significant digits beyond the 8 default to prevent rounding
               aelPushSignifDigits(12)
               
               ;; create an environment that will evaluate the input as an expression.
               ;; "o" = evaluate operators (+, -, etc.) when possible
               ;; "c" = do function calls as possible
               ;; "s" = evaluate suffixes like "u" and "f"
               env = aelEnvCreate( "ocs" nil nil)
               expr = aelEnvCompile(env entryValue)
               if( !expr then
                    ; not wrong if \+\d+ (tcl callback has no problem with it)
                    if( rexMatchp("^[ ]*[+]+[0-9]" entryValue) then
                        noPlusEntryValue=entryValue
                        rexCompile("^[ ]*[+]+")
                        noPlusEntryValue=rexReplace(noPlusEntryValue "" 1)
                        ;;new env and new expr needed for 2nd test
                        env2 = aelEnvCreate( "ocs" nil nil)
                        expr2 = aelEnvCompile(env noPlusEntryValue)
                        if( !expr2 then
                            result = nil
                            warnString= sprintf( nil "%sCannot evaluate expression: \"%s\". " descErr entryValue)
                        else
                            ;; execute the compiled expression.
                            result = aelEnvExecute( expr2)
                            aelEnvFreeCompExpr(expr2)
                        ) 
                    else
                        result = nil
                        warnString= sprintf( nil "%sCannot evaluate expression: \"%s\". " descErr entryValue)
                    )
               else
                   ;; execute the compiled expression
                   result = aelEnvExecute( expr)
                   aelEnvFreeCompExpr(expr)
               ) ;if
            else  ;reject it
                result = nil
            )
 
            retVal = nil
            ;; if the compile worked, turn in back into a number.
            ;; if it failed and you provided a default, set it back to the default.
            if( result then
                retVal = cdfParseFloatString(result)
                unless( retVal
                    retVal = result
                )
         
            else
                 when( default
                    warn("%sSetting result to default: %L.\n" warnString fdkSuf(default))
                    retVal = default
                    if( noreset then
                       resetToDefault = t
                    )
                )
            ); if result

            when( (noVar && not(numberp(retVal)) && not(resetToDefault)) 
                 warn( "%sValue %L is non-numeric value.  Setting result to default: %L.\n" descErr result fdkSuf(default))
                 if( noreset then
                    resetToDefault = t
                 )
                 retVal = default
            )

            if( retVal && numberp(retVal) && not(resetToDefault) then
                cond(
                     (minimum && fdkCmp(minimum ">" retVal cmpTol)
                        warn( "%sValue %L is less than minimum of %L.  Setting result to %L.\n" descErr fdkSuf(entry) fdkSuf(minimum) fdkSuf(minimum))
                        retVal = minimum
                     )

                     (maximum && fdkCmp(maximum "<" retVal cmpTol)
                        warn( "%sValue %L is greater than maximum of %L. Setting result to %L.\n" descErr fdkSuf(entry) fdkSuf(maximum) fdkSuf(maximum))
                        retVal = maximum
                     )
                )

                when(grid 
                    tmpVal=retVal
                    retVal = retVal - offset
                    if( snapType == "half" then
                        retVal = fdkSnapGrid(grid retVal)+ offset
                    else
                        if( snapType == "up" then
                            retVal = fdkSnapUpEpsilonGrid(grid retVal)+ offset
                        else
                            retVal = fdkSnapDownEpsilonGrid(grid retVal)+ offset
                        )
                    )    
                    if(msgGrid==t && tmpVal != retVal then
                        warn("%sValue %s-snapped to grid of %L (with offset %L) from %L to %L.\n" descErr snapType fdkSuf(grid) fdkSuf(offset) fdkSuf(tmpVal) fdkSuf(retVal))
                    )
                )

             )
            if(retVal && numberp(retVal) then
                cond(
                    (formatType == "d"  retVal = sprintf( nil visualFormat fix(retVal))) 
                    (aelSuffix retVal = (aelSuffixNotation retVal 6))
                    (t retVal = sprintf( nil visualFormat retVal) ) 
                )
            )

            when( debug
                printf("Final--> %L\n" retVal )
            )

            when( boundp( 'doneProc) && doneProc
                apply(getd(doneProc) list(retVal))
            )
            putd('fdkSuf nil);get rid of temporary function
            aelPopSignifDigits()
            retVal
        ); let
); proc

;###################################
; Subroutine: fdkMod
; Description: Performs Modulo operation used in skill CB for transrings.
;              To be consistent with tcl CBs.
; Example:
; fdkMod(10 2)
; Return: remainder is returned
;

procedure( fdkMod( a b)
    ; proc to calculate modulo function, to be consistent with tcl CB.
    let( (rem)
          rem = mod(a b)
          rem
  )
)

;###################################
; Subroutine: fdkCdfDisplaySwapSd 
; Description: Controls CDF display of swapSD parameter in mos layout cellview
; setenv FDK_LAY_SWAPSD "TRUE" to enable
; Please synch changes with Tcl fdkCdfCommon.tcl library

procedure(fdkCdfDisplaySwapSd()
    let(
        (
            swapSdEnvValue displayValue
        )

        if(fdkIsLayout() then
            swapSdEnvValue = getShellEnvVar("FDK_LAY_SWAPSD")
            if(swapSdEnvValue == "TRUE" then
                displayValue = t
            else
                displayValue = nil
            )

        else
            displayValue = t
        )

        displayValue
    )
)

procedure(fdkCdfDisplayWhenChoices(choiceList)
    let(
        (
        )
        if(listp(choiceList) then
            fprintf(stderr "choiceList |%L| is a list\n" choiceList)
            if(length(choiceList)>1 then
                fprintf(stderr "choiceList |%L| is a long list\n" choiceList)
                "t"
            else
                fprintf(stderr "choiceList |%L| is a short list\n" choiceList)
                "nil"
            )
        else
            if(stringp(choiceList) then
                if(length(list(choiceList))>1 then
                    fprintf(stderr "choiceList |%L| is a long string list\n" choiceList)
                    "t"
                else
                    fprintf(stderr "choiceList |%L| is a short string list\n" choiceList)
                    "nil"
                )
            else
                fprintf(stderr "choiceList |%L| is not a list or string\n" choiceList)
                "nil"
            )
        )
    )
)
