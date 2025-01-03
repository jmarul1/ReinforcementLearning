;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Intel Top Secret, Intel Proprietary                                      ;;
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
procedure( fdkCdfPrintBlank(level)
    let( (i)      
        i=0
        while(i<=level
            fprintf(stderr " ")
            i=i+1
        )
    )
)

procedure( fdkCdfPrintParams(@optional key (levelLimit 0) (level 0))
    let( (i value )
        fdkCdfPrintBlank(level)
        if(dbIsId(key) || type(key)== "ddCellType" || type(key)=='ddCellType then
            fprintf(stderr "%L~>" key)
            value=key~>??
            if(listp(value) then 
                lastnewkey=""
                foreach(element value
                    if(symbolp(element) then
                        lastnewkey=element
                    else
                        if(listp(element) then
                            if(dbIsId(car(element)) then
                                if(level==levelLimit then
                                    fprintf(stderr "%L: level limit reached...no additional digging.\n" lastnewkey)
                                else
                                    fprintf(stderr "%L:\n" lastnewkey) 
                                    foreach(dbId element
                                        fdkCdfPrintParams(dbId levelLimit level+1)
                                    )
                                )
                            else
                                fprintf(stderr "%L:%L\n" lastnewkey element) 
                                fdkCdfPrintBlank(level)
                            )
                        else
                            fprintf(stderr "%L:%L\n" lastnewkey element)
                            fdkCdfPrintBlank(level)
                        )
                    )
                )
            else
                if(stringp(value) then
                    fprintf(stderr "%L\n" value)
                )
            )
        else
           fprintf(stderr ">>>%L\n" key ) 
        )
        t
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       Subroutine fdkCdfGenericCB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure( fdkCdfGenericCB(@optional param format min max grid offset caller )
    ;; cdfId is provided as an argument when this callback is
    ;; called during instance creation.  It is not provided when
    ;; an existing component is updated using the properties form
    ;; (in this case the global cdfgData variable is used).
    let( ((cdfId caller||cdfgData) paramId tmpValue (scaleUm2m 1e-6) (scalem2Um 1e+6) (scaleUm2n 1e+3) paramIdValue)

        if( symbolp( param) then
            param = symbolToString(param)
        )
        if( symbolp( format) then
            format = symbolToString(format)
        )
        paramId=evalstring(strcat("cdfId~>" param))
        paramIdValue = paramId~>value
        ;fprintf(stderr "for param %L grid is %L and offset is %L\n" param grid offset)

        ;; check/reset param based on format
        cond(
            (format == "int" 
                if( fdkCmp(paramIdValue "<" min) then
                    warn( "%s Value %L is less than minimum of %L.  Setting result to %L\n" paramId~>name paramIdValue min min)
                    paramId->value=min
                )
                if( fdkCmp(paramIdValue ">" max) then
                    warn( "%s Value %L is greater than maximum of %L.  Setting result to %L\n" paramId~>name paramIdValue max max)
                    paramId->value=max
                )
                if( (grid != nil) then
                    paramId->value=fix(fdkSnapGrid(grid (paramId->value - offset)) + offset)
                )
            )
            (format == "float"
                if( fdkCmp(paramIdValue "<" min grid) then
                    warn( "%s Value %L is less than minimum of %L.  Setting result to %L\n" paramId~>name paramIdValue min min)
                    paramId->value=min
                )
                if( fdkCmp(paramIdValue ">" max grid) then
                    warn( "%s Value %L is greater than maximum of %L.  Setting result to %L\n" paramId~>name paramIdValue max max)
                    paramId->value=max
                )
                if( (grid != nil) then
                    paramId->value=fdkSnapGrid(grid paramId->value)
                    paramId->value=fdkSnapGrid(grid (paramId->value - offset)) + offset
                )
            )
            (format == "boolean"
                if( ( paramId->value != t &&  paramId->value != nil) then
                    warn( "%s Value %L not a boolean.  Setting result to %L\n" paramId~>name paramIdValue paramId->defValue)
                    paramId->value=paramId->defValue
                )
            )
            (format == "stringInt"
                paramId->value= fdkAelEval(
                    ?entry paramId~>value
                    ?minimum min
                    ?maximum max
                    ?default paramId~>defValue
                    ?grid grid
                    ?offset offset
                    ?visualFormat "%d"
                    ?noVar t
                    ?noBlank t
                    ?msgGrid t
                    ?desc paramId~>name
                )
            )
            (format == "stringFloat"
                paramId->value= fdkAelEval(
                    ?entry paramId~>value
                    ?minimum min
                    ?maximum max
                    ?default paramId~>defValue
                    ?grid grid
                    ?offset offset
                    ?visualFormat "%L"
                    ?noVar t
                    ?noBlank t
                    ?msgGrid t
                    ?msgSuff t
                    ?desc paramId~>name
                )
            )
            (format == "stringEmptyOK"
                paramId->value= fdkAelEval(
                    ?entry  paramId~>value
                    ?minimum nil
                    ?maximum nil
                    ?default paramId~>defValue
                    ?grid nil
                    ?visualFormat "%L"
                    ?noVar nil
                    ?noBlank nil
                    ?desc paramId~>name
                )
            )
            (format == "string"
                paramId->value= fdkAelEval(
                    ?entry  paramId~>value
                    ?minimum nil
                    ?maximum nil
                    ?default paramId~>defValue
                    ?grid nil
                    ?visualFormat "%L"
                    ?noVar nil
                    ?noBlank t
                    ?desc paramId~>name
                )
            )
            (t
                if( (format != "cyclic" && format != "radio" && format != "button") then
                    ; Need to add additional checks for other UNIT styles
                    if( (format == "lengthMetric") then
                        tmpValue=sprintf(nil "%L" fdkProcessString(paramId~>value))
                        format = fdkStringGetFormat(paramId~>value)
                        if((format!= "u" && format!= "n" && format!= "m") then
                            if(numberp(atof(tmpValue)) then
                                tmpValue = atof(tmpValue)*scalem2Um
                                tmpValue=sprintf(nil "%L" tmpValue)
                            )
                        )
                    else
                        tmpValue=paramIdValue
                    )
                    if(tmpValue == "nil" then
                        tmpValue=paramIdValue
                    ) 
                
                    tmpValue = atof( fdkAelEval(
                        ?entry  tmpValue
                        ?minimum min
                        ?maximum max
                        ?default fdkProcessString(paramId~>defValue)
                        ?grid grid
                        ?offset offset 
                        ?visualFormat "%L"
                        ?noVar t
                        ?noBlank t
                        ?msgGrid t
                        ?msgSuff t
                        ?desc paramId~>name
                        ?snapType  "up"
                    ))
                    if(fdkCmp(tmpValue "<" 1.0) then
                        tmpValue = scaleUm2n * tmpValue
                        tmpValue = sprintf( nil "%.1fn" tmpValue)
                    else
                        tmpValue = sprintf( nil "%.4fu" tmpValue)
                    )
                    paramId->value = tmpValue
                )
            )
        )
        ;; end of check/reset param based on format
        paramId->value
     )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       Subroutine fdkCdfDefaultsCB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure( fdkCdfDefaultsCB(@optional param format min max grid caller )
    ;; cdfId is provided as an argument when this callback is
    ;; called during instance creation.  It is not provided when
    ;; an existing component is updated using the properties form
    ;; (in this case the global cdfgData variable is used).
    let( ((cdfId caller||cdfgData) paramId)
        ;;loop through each param and return value to defValue
        foreach( paramId cdfId~>parameters
            paramId->value=paramId~>defValue
        )
        ;;no need to send this param to defValue as it will be one of the params being changed.
        t
     )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       Subroutine fdkCdfNull
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure( fdkCdfNull( )

    ; A pass-through procedure used for CDF spec parameters
    ;   which do not need the generic callback or any other
    ;   post-processing.
    ;
    ; For example, the stretch handle-only extension parameters
    ;   for the tap uses fdkCdfNull as its callback function.

    let((return)
        return = ""
        return
    )
)
