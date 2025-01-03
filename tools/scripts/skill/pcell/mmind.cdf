;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Intel Top Secret                                                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Copyright (C) 2020, Intel Corporation.  All rights reserved.               ;
;                                                                            ;
; This is the property of Intel Corporation and may only be utilized         ;
; pursuant to a written Restricted Use Nondisclosure Agreement               ;
; with Intel Corporation.  It may not be used, reproduced, or                ;
; disclosed to others except in accordance with the terms and                ;
; conditions of such agreement.                                              ;
;                                                                            ;
; All products, processes, computer systems, dates, and figures              ;
; specified are preliminary based on current expectations, and are           ;
; subject to change without notice.                                          ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Author:
;   Mauricio Marulanda
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

let( ( libId cellId cdfId defaults pkg bag)
pkg = mmIndPCellCore() bag = pkg->readPropBag(ddGetObj(libName cellName) ?text t) defaults = bag->defaults 

    unless( cellId = ddGetObj( libName cellName )
        error( "Could not get cell %s." cellName )
    )
    when( cdfId = cdfGetBaseCellCDF( cellId )
        cdfDeleteCDF( cdfId )
    )
    cdfId  = cdfCreateBaseCellCDF( cellId )

    ;;; Parameters
    cdfCreateParam( cdfId
        ?name           "n"
        ?prompt         "Turns"
        ?defValue       defaults->n
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(mmIndPCellCore() 'fixIndParamsCB) list(\"n\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "w"
        ?prompt         "Width"
        ?units          "lengthMetric"
        ?defValue       defaults->w
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(mmIndPCellCore() 'fixIndParamsCB) list(\"w\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "s"
        ?prompt         "Metal Spacing"
        ?units          "lengthMetric"
        ?defValue       defaults->s
        ?type           "string"
        ?display        "apply(get(mmIndPCellCore() 'setParamDisplayCB) list(\"s\" cdfgData))"
        ?editable       "t"
        ?callback       "apply(get(mmIndPCellCore() 'fixIndParamsCB) list(\"s\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "dx"
        ?prompt         "DiameterX"
        ?units          "lengthMetric"
        ?defValue       defaults->dx
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(mmIndPCellCore() 'fixIndParamsCB) list(\"dx\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "dy"
        ?prompt         "DiameterY"
        ?units          "lengthMetric"
        ?defValue       defaults->dy
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(mmIndPCellCore() 'fixIndParamsCB) list(\"dy\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )    
    cdfCreateParam( cdfId
        ?name           "tl"
        ?prompt         "Terminal Length"
        ?units          "lengthMetric"
        ?defValue       defaults->tl
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(mmIndPCellCore() 'fixIndParamsCB) list(\"tl\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "ts"
        ?prompt         "Terminal Space"
        ?units          "lengthMetric"
        ?defValue       defaults->ts
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(mmIndPCellCore() 'fixIndParamsCB) list(\"ts\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "octSym"
        ?prompt         "Octagon Side Ratios"
        ?defValue       defaults->octSym
        ?type           "string"
        ?display        "apply(get(mmIndPCellCore() 'setParamDisplayCB) list(\"octSym\" cdfgData))"
        ?editable       "t"
        ?callback       "apply(get(mmIndPCellCore() 'fixIndParamsCB) list(\"octSym\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "indType"
        ?prompt         "Inductor Shape"
        ?defValue       defaults->indType
        ?type           "radio"
	?choices        list("rec" "oct")	
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(mmIndPCellCore() 'fixIndParamsCB) list(\"indType\" cdfgData))"	
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "fill"
        ?prompt         "Fill TopLayer"
        ?defValue       t
        ?type           "boolean"
        ?display        "nil"
        ?editable       "t"
    )

    ;;; Simulator Information
    cdfId->simInfo = list( nil )
    cdfId->simInfo->auCdl = list( nil
        'propMapping       nil
        'dollarEqualParams nil
        'dollarParams      nil
        'modelName         nil
        'namePrefix        "X"
        'termOrder         if(CT '(p n ct) '(p n))
        'componentName     if(CT 'ind3t 'ind2t)
        'instParameters    '(indType dx dy w n s tl ts octSym)
        'otherParameters   nil
        'netlistProcedure  '_ansCdlSubcktCall
    )

    ;;; Properties
    cdfId->formInitProc            = "mmInitIndPCell" 
    cdfId->doneProc                = ""
    cdfId->buttonFieldWidth        = 410
    cdfId->fieldHeight             = 35
    cdfId->fieldWidth              = 410
    cdfId->promptWidth             = 120
    cdfId->paramDisplayMode        = "parameter"
    cdfId->paramLabelSet           = "indShape n w s dx dy ts tl"
    cdfSaveCDF( cdfId )
)
