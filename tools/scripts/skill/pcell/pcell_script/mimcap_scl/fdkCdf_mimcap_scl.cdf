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

putd( 'fdkCdf_mimcap_scl nil )
procedure(

 fdkCdf_mimcap_scl(LIBRARY CELL)

let((CB celldd cdfId)

  CB = if( rexMatchp("_stk" CELL) "fdkCdf_mimcap_stk_sclCB" "fdkCdf_mimcap_sclCB" )

  ;; Get cellid to use fdkGetProp for propbag access ;; 
  when( !(celldd = ddGetObj(LIBRARY CELL))
    error("Could get cell %s." CELL)
  )

  when( !null(cdfId = cdfGetBaseCellCDF(celldd))
    cdfDeleteCDF(cdfId)
  )

  cdfId  = cdfCreateBaseCellCDF(celldd)
  
  ;;**************************************************
  ;; PARAMETERS ;;                    
  ;;**************************************************
  cdfCreateParam( cdfId
    ?name           "model"
    ?prompt         "Model Name"
    ?defValue       fdkGetProp(celldd "designRules:model" ?string t)
    ?type           "string"
    ?editable       "nil"
  )
  cdfCreateParam( cdfId
    ?name           "voltage"
    ?prompt         "Voltage"
    ?defValue       fdkGetProp(celldd "designRules:voltageValue" ?string t)
    ?choices        fdkGetProp(celldd "designRules:voltageChoices" ?string t)
    ?type           "radio"
    ?parseAsNumber  "no"
    ?parseAsCEL     "no"
    ?callback       sprintf(nil "%s(%L %L cdfgData)" CB LIBRARY CELL)
    ?editable       "nil"
    ?display        "nil"
  )
  cdfCreateParam( cdfId
    ?name           "m"
    ?prompt         "Multiplier"
    ?defValue       fdkGetProp(celldd "designRules:m" ?string t)
    ?type           "string"
    ?parseAsNumber  "yes"
    ?parseAsCEL     "yes"
    ?callback       sprintf(nil "%s(%L %L cdfgData)" CB LIBRARY CELL)
  )
  cdfCreateParam( cdfId
    ?name           "w"
    ?prompt         "Width"
    ?defValue       fdkGetProp(celldd "designRules:minMimWidth" ?string t)
    ?units          "lengthMetric"	
    ?type           "string"
    ?parseAsNumber  "yes"
    ?parseAsCEL     "yes"
    ?callback       sprintf(nil "%s(%L %L cdfgData)" CB LIBRARY CELL)
  )
  cdfCreateParam( cdfId
    ?name           "ldrawn"
    ?prompt         "Ldrawn"
    ?defValue       fdkGetProp(celldd "designRules:minMimLength" ?string t)
    ?units          "lengthMetric"	
    ?type           "string"
    ?parseAsNumber  "yes"
    ?parseAsCEL     "yes"
    ?callback       sprintf(nil "%s(%L %L cdfgData)" CB LIBRARY CELL)
  )
  cdfCreateParam( cdfId
    ?name           "viaOffsetL"
    ?prompt         "Via Offset Left"
    ?defValue       fdkGetProp(celldd "designRules:minViaOffsetL" ?string t)
    ?units          "lengthMetric"
    ?type           "string"
    ;;?display        "(fdkIsLayout)"
    ?parseAsNumber  "yes"
    ?parseAsCEL     "yes"
    ?callback       sprintf(nil "%s(%L %L cdfgData)" CB LIBRARY CELL)
  )
  cdfCreateParam( cdfId
    ?name           "viaOffsetR"
    ?prompt         "Via Offset Right"
    ?defValue       fdkGetProp(celldd "designRules:minViaOffsetR" ?string t)
    ?units          "lengthMetric"
    ?type           "string"
    ?parseAsNumber  "yes"
    ?parseAsCEL     "yes"
    ?callback       sprintf(nil "%s(%L %L cdfgData)" CB LIBRARY CELL) 
    ?editable       if( rexMatchp("_stk" CELL) "nil" "t" )
  )

  ;;**************************************************
  ;; 
  ;; MODEL parameters
  ;;
  ;;**************************************************
  cdfCreateParam( cdfId
    ?name           "l1"
    ?prompt         "l1"
    ?defValue       fdkGetProp(celldd "defaults:minMimL1" ?string t)
    ?type           "string"
    ?display        "nil"
    ?parseAsNumber  "yes"
    ?parseAsCEL     "yes"
    ?callback       sprintf(nil "%s(%L %L cdfgData)" CB LIBRARY CELL)
    ?editable       "nil"
  )
  cdfCreateParam( cdfId
    ?name           "l2"
    ?prompt         "l2"
    ?defValue       fdkGetProp(celldd "defaults:minMimL2" ?string t)
    ?type           "string"
    ?display        "nil"
    ?parseAsNumber  "yes"
    ?parseAsCEL     "yes"
    ?callback       sprintf(nil "%s(%L %L cdfgData)" CB LIBRARY CELL)
    ?editable       "nil"             
  )
  cdfCreateParam( cdfId
    ?name           "l3"
    ?prompt         "l3"
    ?defValue       fdkGetProp(celldd "defaults:minMimL3" ?string t)
    ?type           "string"
    ?display        "nil"
    ?parseAsNumber  "yes"
    ?parseAsCEL     "yes"
    ?callback       sprintf(nil "%s(%L %L cdfgData)" CB LIBRARY CELL)
    ?editable       "nil"             
  )
  cdfCreateParam( cdfId
    ?name           "wh"
    ?prompt         "wh"
    ?defValue       fdkGetProp(celldd "defaults:minWH" ?string t)
    ?type           "string"
    ?display        "nil"
    ?parseAsNumber  "yes"
    ?parseAsCEL     "yes"
    ?callback       sprintf(nil "%s(%L %L cdfgData)" CB LIBRARY CELL)             
    ?editable       "nil"             
  )
  cdfCreateParam( cdfId
    ?name           "lh"
    ?prompt         "lh"
    ?defValue       fdkGetProp(celldd "defaults:minLH" ?string t)
    ?type           "string"
    ?display        "nil"
    ?parseAsNumber  "yes"
    ?parseAsCEL     "yes"
    ?callback       sprintf(nil "%s(%L %L cdfgData)" CB LIBRARY CELL)             
    ?editable       "nil"             
  )
  ;;
  ;; viaType and metType has been disabled for simplicity sake
  cdfCreateParam( cdfId
    ?name           "viaType"
    ?prompt         "Via Type"
    ?defValue       fdkGetProp(celldd "designRules:viaTypeVal" ?string t)
    ?choices        fdkGetProp(celldd "designRules:viaTypeChoices" ?string t)
    ?type           "radio"
    ?parseAsNumber  "no"
    ?parseAsCEL     "no"
    ?callback       sprintf(nil "%s(%L %L cdfgData)" CB LIBRARY CELL)
    ?display        "nil"
    ?editable       "nil"
  )
  cdfCreateParam( cdfId
    ?name           "metType"
    ?prompt         "Metal Type"
    ?defValue       fdkGetProp(celldd "designRules:metType" ?string t)
    ?choices        fdkGetProp(celldd "designRules:metTypeChoices" ?string t)
    ?type           "radio"
    ?parseAsNumber  "no"
    ?parseAsCEL     "no"
    ?display        "nil"
    ?editable       "nil"
  )
  cdfCreateParam( cdfId
    ?name           "Cest"
    ?prompt         "Estimated Cap, Cest"
    ?defValue       fdkGetProp(celldd "designRules:Ceff" ?string t)
    ?units		"capacitance"
    ?type           "string"
    ?parseAsNumber  "yes"
    ?parseAsCEL     "yes"
    ?callback       sprintf(nil "%s(%L %L cdfgData)" CB LIBRARY CELL)
    ?editable       "nil"
  )
  cdfCreateParam( cdfId
    ?name           "Rest"
    ?prompt         "Estimated R, Rest"
    ?defValue       fdkGetProp(celldd "designRules:Reff" ?string t)
    ?units           "resistance"
    ?type           "string"
    ?parseAsNumber  "yes"
    ?parseAsCEL     "yes"
    ?callback       sprintf(nil "%s(%L %L cdfgData)" CB LIBRARY CELL)
    ?editable       "nil"
  )
  cdfCreateParam( cdfId
    ?name           "nh"
    ?prompt         "Number of holes"
    ?defValue       fdkGetProp(celldd "defaults:minNH" ?string t)
    ?type           "string"
    ?display        "nil"
    ?parseAsNumber  "yes"
    ?parseAsCEL     "yes"
    ?callback       sprintf(nil "%s(%L %L cdfgData)" CB LIBRARY CELL) 
    ?editable       "nil"
  )

  ;;; Simulator Information
  cdfId->simInfo = list(nil)

  cdfId->simInfo->ams = '( nil
    isPrimitive       nil
    extraTerminals    nil
    propMapping       nil
    termMapping       nil
    termOrder         nil
    componentName     nil
    excludeParameters nil
    arrayParameters   nil
    stringParameters  nil
    referenceParameters nil
    enumParameters    nil
    instParameters    (m l1 l2 l3 w lh wh nh)
    otherParameters   (model)
  )
  cdfId->simInfo->auCdl = '( nil
    dollarEqualParams nil
    dollarParams      nil
    modelName         ""
    namePrefix        "X"
    propMapping       nil
    termOrder         ("n" "p")
    componentName     nil
    instParameters    (model l1 l2 l3 w lh wh nh m)
    otherParameters   (model)
    netlistProcedure   "_ansCdlSubcktCall"
  )
  cdfId->simInfo->hspiceD =  '( nil
    optParamExprList  nil
    propMapping       (nil m)
    termMapping       (nil n "(FUNCTION mappedRoot(\"^n,isub\"))"
                           p "(FUNCTION mappedRoot(\"^p,isub\"))")
    termOrder         ("n" "p")
    namePrefix        "X"
    componentName     subcircuit
    instParameters    (m l1 l2 l3 w lh wh nh)
    otherParameters   (model)
  )
  cdfId->simInfo->spectre = '( nil
    modelParamExprList nil
    optParamExprList  nil
    opParamExprList   nil
    stringParameters  nil
    propMapping       (nil mult m)
    termMapping       (nil p \:1 n \:2)
    termOrder         ("n" "p")
    componentName     subcircuit
    instParameters    (m l1 l2 l3 w lh wh nh)
    otherParameters   (model)
  )

  ;; Properties
  cdfId->formInitProc            = ""
  if( rexMatchp("_stk" CELL)
  then cdfId->doneProc           = "fdkCdf_mimcap_stk_scl_doneProc"
  else cdfId->doneProc           = "fdkCdf_mimcap_scl_doneProc"
  )
  cdfId->buttonFieldWidth        = 340
  cdfId->fieldHeight             = 35
  cdfId->fieldWidth              = 350
  cdfId->promptWidth             = 175
  cdfId->instNameType            = "schematic"
  cdfId->instDisplayMode         = "instName"
  cdfId->netNameType             = "schematic"
  cdfId->termSimType             = "DC"
  cdfId->termDisplayMode         = "none"
  cdfId->paramSimType            = "DC"
  cdfId->paramDisplayMode        = "parameter"
  cdfId->paramLabelSet           = "w ldrawn Cest"

  ;; Save the CDF
  if( cdfSaveCDF( cdfId )
  then printf("Saved CDF for %s/%s\n" LIBRARY CELL)
  else fprintf(stderr "Couldn't save CDF for %s/%s\n" LIBRARY CELL)
  )

))
