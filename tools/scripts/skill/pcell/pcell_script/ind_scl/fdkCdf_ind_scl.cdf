;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Intel Top Secret, Intel Proprietary                                      ;;
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

procedure( fdkCdf_ind_scl( LIBRARY CELL) 
  let( (cdfId cellId defaultParams simulatorParamList)

    unless( cellId = ddGetObj( LIBRARY CELL )
      error("Could get cell %s." CELL )
    ) ;; unless
    when( cdfId = cdfGetBaseCellCDF( cellId )
      cdfDeleteCDF( cdfId )
    ) ;; when
    cdfId = cdfCreateBaseCellCDF( cellId )
    printf( "Loading CDF for %s...\n" CELL)
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; PARAMETERS 
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                   
    defaultParams = fdkGetPropTable( cellId ?name "defaults" ?string t)

    cdfCreateParam( cdfId
      ?name           "indShape"
      ?prompt         "Inductor Shape"
      ?type           "radio"
      ?defValue       defaultParams["indShape"]
      ?choices        defaultParams["indShapeChoices"]
      ?parseAsNumber  "no"
      ?parseAsCEL     "no"
      ?callback       "fdkPutIndCktParamsInCDF(cdfgData)"
      ?display        (if lowerCase(CELL) == "indcust_scl" "t" "nil")
      ?editable       (if lowerCase(CELL) == "indcust_scl" "t" "nil"))

    cdfCreateParam( cdfId
        ?name           "m"
        ?prompt         "Multiplier"
        ?defValue       defaultParams["m"] 
        ?type           "string"
        ?callback       "fdkPutIndCktParamsInCDF(cdfgData)"
        ?parseAsNumber  "yes")
        
    cdfCreateParam( cdfId
      ?name           "model"
      ?prompt         "Model"
      ?type           "string"
      ?defValue       defaultParams["model"]
      ?editable	      "nil")

    cdfCreateParam( cdfId
      ?name           "nrturns"
      ?prompt         "Number of Turns"
      ?defValue       defaultParams["nrturns"]
      ?type           "string"
      ?parseAsNumber  "yes"
      ?callback       "fdkPutIndCktParamsInCDF(cdfgData)")

    cdfCreateParam( cdfId
      ?name           "toplayer"
      ?prompt         "Top Metal Layer"
      ?type           "cyclic"
      ?defValue       defaultParams["toplayer"]
      ?choices        defaultParams["toplayerChoices"]
      ?callback       "fdkPutIndCktParamsInCDF(cdfgData)")

    cdfCreateParam( cdfId
      ?name           "innerwx"
      ?prompt         "Inner X Diameter"
      ?defValue       defaultParams["innerwx"]
      ?type           "string"
      ?parseAsNumber  "yes"
      ?units	      "lengthMetric"	 	 
      ?callback       "fdkPutIndCktParamsInCDF(cdfgData)")

    cdfCreateParam( cdfId
      ?name           "innerwy"
      ?prompt         "Inner Y Diameter"
      ?defValue       defaultParams["innerwy"]
      ?type           "string"
      ?parseAsNumber  "yes"
      ?units	      "lengthMetric"	 	 
      ?editable       (if lowerCase(CELL) == "indcust_scl" "t" "nil")
      ?callback       "fdkPutIndCktParamsInCDF(cdfgData)")

    cdfCreateParam( cdfId
      ?name           "coilwx"
      ?prompt         "Coil Width"
      ?defValue       defaultParams["coilwx"]
      ?type           "string"
      ?parseAsNumber  "yes"
      ?units          "lengthMetric"	 
      ?editable       "t"
      ?callback       "fdkPutIndCktParamsInCDF(cdfgData)")

    cdfCreateParam( cdfId
      ?name           "coilspcx"
      ?prompt         "Coil Spacing"
      ?defValue       defaultParams["coilspcx"]
      ?type           "string"
      ?parseAsNumber  "yes"
      ?units          "lengthMetric"
      ?editable       "t"
      ?callback       "fdkPutIndCktParamsInCDF(cdfgData)")

    cdfCreateParam( cdfId
      ?name           "termext"
      ?prompt         "Terminal Extension"
      ?defValue       defaultParams["termext"]
      ?type           "string"
      ?parseAsNumber  "yes"
      ?units          "lengthMetric"	 	 
      ?editable       "t"
      ?callback       "fdkPutIndCktParamsInCDF(cdfgData)")

    cdfCreateParam( cdfId
      ?name           "termspc"
      ?prompt         "Terminal Separation"
      ?defValue       defaultParams["termspc"]
      ?type           "string"
      ?parseAsNumber  "yes"
      ?units          "lengthMetric"	 	 
      ?editable       "t"
      ?callback       "fdkPutIndCktParamsInCDF(cdfgData)")

    cdfCreateParam( cdfId
      ?name           "termside"
      ?prompt         "Terminal Location"
      ?type           "cyclic"
      ?defValue       defaultParams["termside"]
      ?choices        defaultParams["termsideChoices"]
      ?parseAsNumber  "no"
      ?callback       "fdkPutIndCktParamsInCDF(cdfgData)")

    cdfCreateParam( cdfId
      ?name           "centertap"
      ?prompt         "Center Tap"
      ?type           "radio"
      ?defValue       defaultParams["centertap"]
      ?choices        list( "Yes" "No")
      ?parseAsNumber  "no"
      ?parseAsCEL     "no"
      ?display        (if lowerCase(defaultParams["centertapDisplay"]) == "yes" "t" "nil"))
       
    cdfCreateParam( cdfId
      ?name           "adddummyfill"
      ?prompt         "Dummy Fill"
      ?type           "radio"
      ?defValue       "No"
      ?choices        list( "Yes" "No")
      ?parseAsNumber  "no"
      ?parseAsCEL     "no")

    cdfCreateParam( cdfId
      ?name           "solver3d"
      ?prompt         "3D Solver"
      ?type           "radio"
      ?defValue       "No"
      ?choices        list( "Yes" "No")
      ?parseAsNumber  "no"
      ?parseAsCEL     "no"
      ?display        (if lowerCase(CELL) == "indcust_scl" "t" "nil")
      ?editable       (if lowerCase(CELL) == "indcust_scl" "t" "nil"))
      
    cdfCreateParam( cdfId
      ?name           "currentrms"
      ?prompt         "Approx. RMS current (mA)"
      ?defValue       "0"
      ?type           "string"
      ?parseAsNumber  "t"
      ?display        "t"
      ?editable       "nil"
      ?callback       "fdkPutIndCktParamsInCDF(cdfgData)"
     ) ; cdfCreateParam      

;; Approximated peaking Qdiff, Ldiff, peakFreq
       cktParamNameList = list("LdPeak" "QdPeak" "FreqPeak") 
       foreach(skew list("lowQ" "typQ" "highQ")
         foreach(cktParam cktParamNameList 
           cdfCreateParam( cdfId
            ?name           strcat(lowerCase(skew) cktParam)  ;store in the Camel Notation
            ?prompt         strcat("Approx " skew " " cktParam " " (if pcreMatchp("^L" cktParam) "(nH)" (if pcreMatchp("^F" cktParam) "(GHz)" "") ) ) 
            ?defValue       "0"
            ?type           "string"
            ?parseAsNumber  "t"
            ?display        (if lowerCase(skew) == "typq" "t" "nil")
	    ?editable	    "nil"
           ) ; cdfCreateParam
         ) ;for		 
       ) ;foreach

;; Model Parameters
       cktParamNameList = list("Ls1" "L1" "Rs1" "R1" "Cox1" "Rsub1" "Co12" "K12") 
       simulatorParamList = list("m")
       foreach(skew list("lowQ" "typQ" "highQ")
         foreach(cktParam cktParamNameList 
	   simulatorParamList = append1(simulatorParamList strcat(lowerCase(skew) cktParam)) ;store parameters for netlisting 
           cdfCreateParam( cdfId
            ?name           strcat(lowerCase(skew) cktParam) ;store in the Camel Notation
            ?prompt         strcat(skew " " cktParam) 
            ?defValue       "0"
            ?type           "string"
            ?parseAsNumber  "t"	    
            ?display        "nil"
	    ?editable	    "nil"
           ) ; cdfCreateParam
         ) ;for		 
       ) ;foreach
;; end of model pararameters     

    ;;; Simulator Information
    cdfId->simInfo = list( nil )
    cdfId->simInfo->spectre = list( nil
      'instParameters	  simulatorParamList
      'componentName  	  "subcircuit"
      'otherParameters    "(model)"
      'termOrder          parseString(defaultParams["termOrder"])
      'termMapping     	  parseString(defaultParams["spectreTermMap"])  
      )
    cdfId->simInfo->hspiceD = list( nil
      'instParameters     simulatorParamList
      'otherParameters    "(model)"
      'componentName      "subcircuit"
      'termOrder          parseString(defaultParams["termOrder"])
      'namePrefix         "X"
      'termMapping        parseString(defaultParams["hspiceDTermMap"])  
      )
    cdfId->simInfo->auCdl = (list nil
      'componentName      CELL
      'netlistProcedure   "_ansCdlSubcktCall"
      'instParameters     '(toplayer nrturns coilspcx coilwx innerwx innerwy m)
      'namePrefix	  "X"
      'termOrder	  parseString(defaultParams["termOrder"])
      )
    
    ;;; Properties
    cdfId->formInitProc            = "fdkPutIndCktParamsInCDF"
    cdfId->doneProc                = "fdkDoneProcIndCDF"
    cdfId->buttonFieldWidth        = 400
    cdfId->fieldHeight             = 34
    cdfId->fieldWidth              = 400
    cdfId->promptWidth             = 175
    cdfId->paramLabelSet           = "ind"

    cdfSaveCDF( cdfId )
  ) ;; let
)
