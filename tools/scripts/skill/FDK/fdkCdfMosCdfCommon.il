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

procedure( fdkCdf_mos_common_cdf( LIBRARY CELL )
    let( ( lChoices cdfId cellId FDK_CDF_DUMP idStyleDisplay 
      defaultShieldLayer shieldLayerChoices oatype)  
        
        printf( "Loading CDF for %s...\n" CELL)
        oatype = getShellEnvVar("FDK_OALIB_TYPE")
        ;; Get cellid to use fdkGetProp for prop bag access.
        unless( cellId = ddGetObj( LIBRARY CELL )
            error( "Could not get cell %s." CELL )
        )
        
        
  ;; Get L selection choices
        lChoices =  fdkGetProp(cellId "gateLength" ?string t)
        
        when( cdfId = cdfGetBaseCellCDF( cellId )
            cdfDeleteCDF( cdfId )
        )
        cdfId  = cdfCreateBaseCellCDF( cellId )
        

        ;; Get L selection choices
        lChoices =  fdkGetProp(cellId "gateLength" ?string t)

    ;; Get nwell style choices
    ;;nwellStyleChoices = fdkGetProp(cellId "nwellStyleChoices" ?string t)

        if( fdkGetProp(cellId "enableIdStyle") == t then
            idStyleDisplay = "(fdkIsLayout)"
        else
            idStyleDisplay = "nil"
        )
       
            defaultShieldLayer= fdkGetProp(cellId "defaults:shieldLayer" ?string t)
 
            shieldLayerChoices= fdkGetProp(cellId "shieldLayerChoices" ?string t)
       
        
        
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;; PARAMETERS 
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
               
        cdfCreateParam( cdfId
                ?name           "model"
                ?prompt         "Model Name (model)"
                ?defValue       (fdkGetProp cellId "model" ?string t)
                ?type           "string"
                ?display        "t"
                ?editable       "nil"
                )
         when( !rexMatchp("_s$", CELL)
             cdfCreateParam( cdfId
                ?name           "device"
                ?prompt         "Device Type"
                ?defValue       (fdkGetProp cellId "deviceType" ?string t)
                ?type           "string"
                ?display        "nil"
                ?editable       "nil"
                )
         )

        cdfCreateParam( cdfId
                ?name           "weff"
                ?prompt         "Effective Width (weff=w*nf)"
                ?defValue       (fdkGetProp cellId "defaults:w" ?string t)
                ?type           "string"
                ?display        "t"
                ?editable       "nil"
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                )
        
        
        cdfCreateParam( cdfId
                ?name           "wSelect"
                ?prompt         "Width Selection (w)"
                ?units          "lengthMetric"
                ?defValue       (fdkGetProp cellId "defaults:w" ?string t)
                ?type           "cyclic"
                ?choices        (append1 (fdkGetProp cellId "wChoices" ?string t ) "other")
                ?parseAsNumber  "no"
                ?parseAsCEL     "yes"
                ;?display        "(fdkWSelectDisplay)"
                ?callback       "(fdkCdfWidthSelectCB)"
                )
        
        
        cdfCreateParam( cdfId
                ?name           "w"
                ?prompt         "Width (w)"
                ?units          "lengthMetric"
                ?defValue       (fdkGetProp cellId "defaults:w" ?string t)
                ?type           "string"
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                ?display        "(!(fdkIsChoiceMember cdfgData->w->value \"wSelect\"))"
                ?editable       "t"
                ?callback       "(fdkCdfWidthCB)"
                )

    
        cdfCreateParam( cdfId
                ?name           "lSelect"
                ?prompt         "Length Selection (l)"
                ?units          "lengthMetric"
                ?defValue       (fdkGetProp cellId "defaults:l" ?string t)
                ?type           "cyclic"
                ?choices        (append1 lChoices "other")
                ?parseAsNumber  "no"
                ?parseAsCEL     "yes"
                ;?display        "(fdkLSelectDisplay)"
                ?callback       "(fdkCdfLengthSelectCB)"
                )

         
        cdfCreateParam( cdfId
                ?name           "l"
                ?prompt         "Length (l)"
                ?units          "lengthMetric"
                ?defValue       (fdkGetProp cellId "defaults:l" ?string t)
                ?type           "string"
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                ?display        "(!(fdkIsChoiceMember cdfgData->l->value \"lSelect\"))"
                ?editable       "nil"
                ?callback       "(fdkCdfMosCB)"
                )
        
        
        cdfCreateParam( cdfId
                ?name           "nf"
                ?prompt         "Number of Fingers (nf)"
                ?defValue       (sprintf nil "%d" (fdkGetProp cellId "defaults:nf"))
                ?type           "string"
                ?display        "t"
                ?editable       "(!(fdkCdfIsStackMos))"
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                ?callback       "(fdkCdfMosCB)"
                )
     
        cdfCreateParam( cdfId
                ?name           "nfsub"
                ?prompt         "Number of sub-fingers (nfsub)"
                ?defValue       (sprintf nil "%d" (fdkGetProp cellId "defaults:nfsub"))
                ?type           "string"
                ?display        (if rexMatchp("_s$" CELL) "nil" "(fdkAllowNfsub)")
                ?editable       "t"
                ?parseAsNumber  "yes"
                ?callback       "(fdkCdfNfsubCB)"
                        )
    
        cdfCreateParam( cdfId
                ?name           "m"
                ?prompt         "Multiplier (m)"
                ?defValue       (sprintf nil "%d" (fdkGetProp cellId "defaults:m"))
                ?type           "string"
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                ?display        "(!(fdkIsLayout))"
                ?editable       "t"
                ?callback       "(fdkCdfMosCB)"
                )
         
        cdfCreateParam( cdfId
                ?name           "meff"
                ?prompt         "Effective Multiplier (meff=m*nf)"
                ?defValue       (sprintf nil "%d" ((fdkGetProp cellId "defaults:nf")*(fdkGetProp cellId "defaults:m")))
                ?type           "string"
                ?display        "nil"
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                )
        
        cdfCreateParam( cdfId
                ?name           "endcapExtT"
                ?prompt         "Poly EndCap Ext Top"
                ?defValue       (fdkGetProp cellId "defaults:endcapExt" ?string t)
                ?type           "string"
                ?display        "nil"
                ?parseAsNumber  "no"
                ?parseAsCEL     "no"
                ?callback       "(fdkCdfMosCB)"
                )

     
        when( rexMatchp("_s$", CELL)
           cdfCreateParam( cdfId
                ?name           "stack"
                ?prompt         "Stack"
                ?defValue       "2"
                ?type           "string"
                ?display        "(fdkCdfIsStackMos)"
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                ?callback       "(fdkCdfStackMosCB)"
                )
            cdfCreateParam( cdfId
                ?name           "stackSourceEndcaps"
                ?prompt         "Shared Source Endcaps"
                ?defValue       (fdkGetProp cellId "defaults:stackSourceEndcaps" ?string t)
                ?type           "string"
                ?parseAsCEL     "yes"
                ?parseAsNumber  "yes"
                ?display        (if rexMatchp("_s$" CELL)  "(!(fdkIsLayout))" "nil")
                ?editable       (if rexMatchp("_s$" CELL)  "(!(fdkIsLayout))" "nil")
                ?callback       "(fdkCdfStackMosCB)"
                )
        cdfCreateParam( cdfId
                ?name           "stackDrainEndcaps"
                ?prompt         "Shared Drain Endcaps"
                ?defValue       (fdkGetProp cellId "defaults:stackDrainEndcaps" ?string t)
                ?type           "string"
                ?parseAsCEL     "yes"
                ?parseAsNumber  "yes"
                ?display        (if rexMatchp("_s$" CELL)  "(!(fdkIsLayout))" "nil")
                ?editable       (if rexMatchp("_s$" CELL)  "(!(fdkIsLayout))" "nil")
                ?callback       "(fdkCdfStackMosCB)"
                )
        )


  
        cdfCreateParam( cdfId
                ?name           "endcapExtB"
                ?prompt         "Poly EndCap Ext Bottom"
                ?defValue       (fdkGetProp cellId "defaults:endcapExt" ?string t)
                ?type           "string"
                ?display        "nil"
                ?parseAsNumber  "no"
                ?parseAsCEL     "no"
                ?callback       "(fdkCdfMosCB)"
                )
        
        
        cdfCreateParam( cdfId
                ?name           "dcExtT"
                ?prompt         "Top TCN Extension/Cut-back"
                ?defValue       (fdkGetProp cellId "defaults:diffconExt" ?string t)
                ?type           "string"
                ?display        "nil"
                ?parseAsNumber  "no"
                ?parseAsCEL     "no"
                ?callback       "(fdkCdfMosCB)"
                )

        cdfCreateParam( cdfId
                ?name           "dcExtB"
                ?prompt         "Bottom TCN Extension/Cut-back"
                ?defValue       (fdkGetProp cellId "defaults:diffconExt" ?string t)
                ?type           "string"
                ?display        "nil"
                ?parseAsNumber  "no"
                ?parseAsCEL     "no"
                ?callback       "(fdkCdfMosCB)"
                )

        cdfCreateParam( cdfId
                ?name           "leftAbut"
                ?prompt         "Left Abutment Setting"
                ?defValue       "noAbut"
                ?type           "string"
                ?display        "nil"
                ?parseAsNumber  "no"
                ?parseAsCEL     "no"
                )

        cdfCreateParam( cdfId
                ?name           "rightAbut"
                ?prompt         "Right Abutment Setting"
                ?defValue       "noAbut"
                ?type           "string"
                ?display        "nil"
                ?parseAsNumber  "no"
                ?parseAsCEL     "no"
                )
        
        cdfCreateParam( cdfId
                ?name           "leftShield"
                ?prompt         "Left Shield Layer"
                ?defValue       defaultShieldLayer
                ?type           "cyclic"
                ?choices        shieldLayerChoices
                ?parseAsNumber  "no"
                ?parseAsCEL     "no"
                ?display        "(fdkIsLayout)"
                ?editable       "t"
                ?callback       "(fdkCdfMosCB)"
                )
    
        cdfCreateParam( cdfId
                ?name           "rightShield"
                ?prompt         "Right Shield Layer"
                ?defValue       defaultShieldLayer
                ?type           "cyclic"
                ?choices        shieldLayerChoices
                ?parseAsNumber  "no"
                ?parseAsCEL     "no"
                ?display        "(fdkIsLayout)"
                ?editable       "t"
                ?callback       "(fdkCdfMosCB)"
                )
          
       if(nequal((fdkGetProp cellId "gatePitch") "UR") then
          cdfCreateParam( cdfId
                ?name           "shieldL"
                ?prompt         "Shield Length"
                ?units          "lengthMetric"
                ?defValue       (fdkGetProp cellId "defaults:shieldL" ?string t)
                ?choices        lChoices
                ?type           "cyclic"
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                ?display        "(fdkIsLayout)"
                ?editable       "t"
                ?callback       "(fdkCdfMosCB)"
                )
       else
           cdfCreateParam( cdfId
                ?name           "shieldLLeft"
                ?prompt         "Shield Length(Left)"
                ?units          "lengthMetric"
                ?defValue       (fdkGetProp cellId "defaults:shieldL" ?string t)
                ?choices        lChoices
                ?type           "cyclic"
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                ?display        "(fdkShieldPolyDisplay \"left\")"
                ?editable       "t"
                ?callback       "(fdkCdfMosCB)"
                )
           cdfCreateParam( cdfId
                ?name           "shieldLRight"
                ?prompt         "Shield Length(Right)"
                ?units          "lengthMetric"
                ?defValue       (fdkGetProp cellId "defaults:shieldL" ?string t)
                ?choices        lChoices
                ?type           "cyclic"
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                ?display        "(fdkShieldPolyDisplay \"right\")"
                ?editable       "t"
                ?callback       "(fdkCdfMosCB)"
                )
        )
        cdfCreateParam( cdfId
                ?name           "shieldPolyEndcapT"
                ?prompt         "Shield Poly EndCap Ext Top"
                ?defValue       (fdkGetProp cellId "defaults:shieldPolyEndcap" ?string t)
                ?type           "string"
                ?display        "nil"
                ?parseAsNumber  "no"
                ?parseAsCEL     "no"
                ?callback       "(fdkCdfMosCB)"
                )

        cdfCreateParam( cdfId
                ?name           "shieldPolyEndcapB"
                ?prompt         "Shield Poly EndCap Ext Bottom"
                ?defValue       (fdkGetProp cellId "defaults:shieldPolyEndcap" ?string t)
                ?type           "string"
                ?display        "nil"
                ?parseAsNumber  "no"
                ?parseAsCEL     "no"
                ?callback       "(fdkCdfMosCB)"
                )

        cdfCreateParam( cdfId
                ?name           "matchShieldPolyExt"
                ?prompt         "Match Shield Poly Extension?"
                ?defValue       nil
                ?type           "boolean"
                ?parseAsNumber  "no"
                ?parseAsCEL     "no"
                ?display        "(fdkIsLayout)"
                ?editable       "t"
                ?callback       "(fdkCdfMosCB)"
                )
       

        cdfCreateParam( cdfId
                ?name           "idStyle"
                ?prompt         "ID Layer Style"
                ?defValue       (fdkGetProp cellId "defaults:idStyle" ?string t)
                ?type           "cyclic"
                ?choices        (fdkGetProp cellId "idStyleChoices" ?string t )
                ?parseAsNumber  "no"
                ?parseAsCEL     "no"
                ?display        idStyleDisplay
                ?editable       "t"
                ?callback       "(fdkCdfMosCB)"
                )
        
        cdfCreateParam( cdfId
                ?name           "enableStretchHandles"
                ?prompt         "Enable Stretch Handles?"
                ?defValue       t
                ?type           "boolean"
                ?display        "nil"
                ?parseAsNumber  "no"
                ?parseAsCEL     "no"
                ?editable       "t"
                )
        
        if( rexMatchp("^[np]sr", CELL) then
          cdfCreateParam( cdfId
                    ?name           "swapSD"
                    ?prompt         "Swap Source/Drain?"
                    ?defValue       nil
                    ?type           "boolean"
                    ?parseAsNumber  "no"
                    ?parseAsCEL     "no"
                    ?display        "nil"
                    ?editable       "nil"
          )
        else
          cdfCreateParam( cdfId
                    ?name           "swapSD"
                    ?prompt         "Swap Source/Drain?"
                    ?defValue       nil
                    ?type           "boolean"
                    ?parseAsNumber  "no"
                    ?parseAsCEL     "no"
                    ;?display        (if rexMatchp("_s$" CELL) "nil" "(!(fdkIsLayout))")
                    ?display        (if rexMatchp("_s$" CELL) "nil" "(fdkCdfDisplaySwapSd)")
                    ?editable       "t"
                    ?callback       "(fdkCdfMosCB)"
          )
       )
          
          
        
        cdfCreateParam( cdfId
            ?name           "sharedSourceEndcaps"
            ?prompt         "Shared Source Endcaps"
            ?defValue       (fdkGetProp cellId "defaults:sharedSourceEndcaps" ?string t)
            ?type           "string"
            ?parseAsNumber  "yes"
            ?parseAsCEL     "no"
            ?display        (if rexMatchp("_s$" CELL) "nil" "(!(fdkIsLayout))")
            ?editable       "t"
            ?callback       "(fdkCdfMosCB)"
            )
        cdfCreateParam( cdfId
            ?name           "sharedDrainEndcaps"
            ?prompt         "Shared Drain Endcaps"
            ?defValue        (fdkGetProp cellId "defaults:sharedDrainEndcaps" ?string t)
            ?type           "string"
            ?parseAsNumber  "yes"
            ?parseAsCEL     "no"
            ?display        (if rexMatchp("_s$" CELL) "nil" "(!(fdkIsLayout))")
            ?editable       "t"
            ?callback       "(fdkCdfMosCB)"
            )
       
        cdfCreateParam( cdfId
            ?name           "totalSourceEndcaps"
            ?prompt         "Total Source Endcaps"
            ?defValue       (fdkGetProp cellId "defaults:totalSourceEndcaps" ?string t)
            ?type           "string"
            ?parseAsNumber  "yes"
            ?parseAsCEL     "no"
            ?display        "(!(fdkIsLayout))"
            ?editable        "nil"

            )
        cdfCreateParam( cdfId
            ?name           "totalDrainEndcaps"
            ?prompt         "Total Drain Endcaps"
            ?defValue       (fdkGetProp cellId "defaults:totalDrainEndcaps" ?string t)
            ?type           "string"
            ?parseAsNumber  "yes"
            ?parseAsCEL     "no"
            ?display        "(!(fdkIsLayout))"
            ?editable       "nil"

            )
        
        cdfCreateParam( cdfId
                ?name           "as"
                ?prompt         "Area of Source (as)"
                ?defValue       (fdkGetProp cellId "defaults:as" ?string t)
                ?type           "string"
                ?parseAsCEL     "yes"
                ?parseAsNumber  "yes"
                ?display        (if rexMatchp("_s$" CELL) "nil" "(!(fdkIsLayout))")
                ?editable       "nil"
                )

        cdfCreateParam( cdfId
                ?name           "ad"
                ?prompt         "Area of Drain (ad)"
                ?defValue       (fdkGetProp cellId "defaults:ad" ?string t)
                ?type           "string"
                ?parseAsCEL     "yes"
                ?parseAsNumber  "yes"
                ?display        (if rexMatchp("_s$" CELL) "nil" "(!(fdkIsLayout))")
                ?editable       "nil"
                )
             
        cdfCreateParam( cdfId
                ?name           "ps"
                ?prompt         "Perimeter of Source(ps)"
                ?defValue       (fdkGetProp cellId "defaults:ps" ?string t)
                ?type           "string"
                ?parseAsCEL     "yes"
                ?parseAsNumber  "yes"
                ?display        (if rexMatchp("_s$" CELL) "nil" "(!(fdkIsLayout))")
                ?editable       "nil"
                )
                      
        cdfCreateParam( cdfId
                ?name           "pd"
                ?prompt         "Perimeter of Drain(pd)"
                ?defValue       (fdkGetProp cellId "defaults:pd" ?string t)
                ?type           "string"
                ?parseAsCEL     "yes"
                ?parseAsNumber  "yes"
                ?display        (if rexMatchp("_s$" CELL) "nil" "(!(fdkIsLayout))")
                ?editable       "nil"
                )
  
        cdfCreateParam( cdfId
                ?name           "pes"
                ?prompt         "Source Poly Edge(pes)"
                ?defValue       (fdkGetProp cellId "defaults:pes" ?string t)
                ?type           "string"
                ?display        (if rexMatchp("_s$" CELL) "nil" "(!(fdkIsLayout))")
                ?editable       "nil"
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                )
        cdfCreateParam( cdfId
                ?name           "ped"
                ?prompt         "Drain Poly Edge(ped)"
                ?defValue       (fdkGetProp cellId "defaults:ped" ?string t)
                ?type           "string"
                ?display        (if rexMatchp("_s$" CELL) "nil" "(!(fdkIsLayout))")
                ?editable       "nil"
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                )        
        
		when(fdkGetProp(cellId "nwellStyleChoices" ?string t)
			cdfCreateParam( cdfId
				?name			"nwellStyle"
                                ?prompt			"Nwell Style"
                                ?defValue               (fdkGetProp cellId "defaults:nwellStyle" ?string t)
                                ?type			"cyclic"
                                ?choices                fdkGetProp(cellId "nwellStyleChoices" ?string t)
                                ?display		"(!(fdkIsBulkEnabled)) && (fdkIsLayout)"
                                ?editable		"t"
			)
                        cdfCreateParam( cdfId
				?name			"nwellStyleBulkEnabled"
                                ?prompt			"Nwell Style"
                                ?defValue               (fdkGetProp cellId "defaults:nwellStyleBulkEnabled" ?string t)
                                ?type			"cyclic"
                                ?choices                fdkGetProp(cellId "nwellStyleChoicesBulkEnabled" ?string t)
                                ?display		"(fdkIsBulkEnabled) && (fdkIsLayout)"
                                ?editable		"t"
                                ?callback               "(fdkCdfMosCB)"
			)
		)
                cdfCreateParam( cdfId
                ?name           "isoNested"
                ?prompt         "Iso/Nested parameter options"
                ?defValue       (fdkGetProp cellId "defaults:isoNestedValue" ?string t)
                ?choices        (fdkGetProp cellId "defaults:isoNestedChoices" ?string t)
                ?type           "radio"
                ?display        (if rexMatchp("_s$" CELL) "nil" "(!(fdkIsLayout))")
                ?editable       "t"
                ?parseAsNumber  "no"
                ?parseAsCEL     "no"
                ?callback       "(fdkSetIsoNestedDefValues)"
                )


        cdfCreateParam( cdfId
                ?name           "sndn"
                ?prompt         "      sndn (# fingers)"
                ?defValue       (fdkGetProp cellId "defaults:sndn" ?string t)
                ?type           "string"
                ?display        (if rexMatchp("_s$" CELL) "nil" "(!(fdkIsLayout))")
                ?editable       (if rexMatchp("_s$" CELL) "nil" "(fdkIsoNestDisp)")
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                ?callback       "fdkMosUserDefIsoNested()"
                )

        cdfCreateParam( cdfId
                ?name           "sidi"
                ?prompt         "      sidi (# fingers)"
                ?defValue       (fdkGetProp cellId "defaults:sidi" ?string t)
                ?type           "string"
                ?display        (if rexMatchp("_s$" CELL) "nil" "(!(fdkIsLayout))")
                ?editable       (if rexMatchp("_s$" CELL) "nil" "(fdkIsoNestDisp)")
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                ?callback       "fdkMosUserDefIsoNested()"
                )
        cdfCreateParam( cdfId
                ?name           "sndi"
                ?prompt         "      sndi (# fingers)"
                ?defValue       (fdkGetProp cellId "defaults:sndi" ?string t)
                ?type           "string"
                ?display        (if rexMatchp("_s$" CELL) "nil" "(!(fdkIsLayout))")
                ?editable       (if rexMatchp("_s$" CELL) "nil" "(fdkIsoNestDisp)")
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                ?callback       "fdkMosUserDefIsoNested()"
                )
        cdfCreateParam( cdfId
                ?name           "sidn"
                ?prompt         "      sidn (# fingers)"
                ?defValue       (fdkGetProp cellId "defaults:sidn" ?string t)
                ?type           "string"
                ?display        (if rexMatchp("_s$" CELL) "nil" "(!(fdkIsLayout))")
                ?editable       (if rexMatchp("_s$" CELL) "nil" "(fdkIsoNestDisp)")
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                ?callback       "fdkMosUserDefIsoNested()"
                )
       
        cdfCreateParam( cdfId
                ?name           "iNSumCheck"
                ?prompt         "    Sum = # fingers ?"
                ?defValue       ""
                ?type           "string"
                ?display        (if rexMatchp("_s$" CELL) "nil" "(fdkIsoNestDisp)")
                ?editable       "nil"
                ?parseAsNumber  "no"
                ?parseAsCEL     "no"
                )
        cdfCreateParam( cdfId
                ?name           "sndnEff"
                ?prompt         "sndnEff"
                ?defValue       ""
                ?type           "string"
                ?display        "nil"
                ?editable       "t"
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                )
        cdfCreateParam( cdfId
                ?name           "sidiEff"
                ?prompt         "sidiEff"
                ?defValue       ""
                ?type           "string"
                ?display        "nil"
                ?editable       "t"
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                )
        cdfCreateParam( cdfId
                ?name           "sndiEff"
                ?prompt         "sndiEff"
                ?defValue       ""
                ?type           "string"
                ?display        "nil"
                ?editable       "t"
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                )
        cdfCreateParam( cdfId
                ?name           "sidnEff"
                ?prompt         "sndnEff"
                ?defValue       ""
                ?type           "string"
                ?display        "nil"
                ?editable       "t"
                ?parseAsNumber  "yes"
                ?parseAsCEL     "yes"
                )
        cdfCreateParam( cdfId
                ?name           "diffUnderPoly"
                ?prompt         "diffUnderPoly"
                ?defValue       t
                ?type           "boolean"
                ?display        "nil"
                ?editable       "nil"
                ?parseAsNumber  "no"
                ?parseAsCEL     "no"
                ) 
  /*       
        cdfCreateParam( cdfId
                ?name           "deviceID"
                ?prompt         "Enable dummy layer?"
                ?defValue       nil
                ?type           "boolean"
                ?display        "(fdkIsLayout)"
                ?editable       "(fdkIsLayout)"
                ?parseAsNumber  "no"
                ?parseAsCEL     "no"
                )
*/
        ;;; Simulator Information
        cdfId->simInfo = list( nil )

        ;;; when not a stacked mos, we need these simInfo properties.
        if(!rexMatchp("_s$", CELL)
        then
            when(equal(oatype "pycell") 
                cdfId->simInfo->sdl = '( nil
                      instParameters   (model weff wSelect w lSelect l nf nfsub swapSD)
                      ;instParametersToIgnore (leftAbut rightAbut endcapExtT endcapExtB dcExtT dcExtB leftShield rightShield shieldL shieldPolyEndcapT shieldPolyEndcapB ftiEndcapT ftiEndcapB matchShieldPolyExt idStyle nwellStyle sharedSourceEndcaps sharedDrainEndcaps totalSourceEndcaps totalDrainEndcaps as ad ps pd pes ped isoNested sndn sidi sndi sidn sndf sidf sfdi sfdf sfdn iNSumCheck sndnEff sidiEff sndiEff sidnEff sndfEff sidfEff sfdiEff sfdfEff sfdnEff dummyGate m meff)
                      ;permuteRule "(p s d)"
                     
                )
            )
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
                         instParameters    nil
                         otherParameters   nil
                         )
          cdfId->simInfo->auCdl = '( nil
                         netlistProcedure "_ansCdlSubcktCall"
                         propMapping       (nil m meff L l W w)
                         instParameters    (model W L m nwell_net)
                         ;componentName    "nmos"
                         termOrder         (d g s b)
                         namePrefix      "M"
                         )
          cdfId->simInfo->hspiceD = '( nil
                       optParamExprList  nil
                       propMapping      (nil w weff sndi sndiEff sidn sidnEff sndn sndnEff sidi sidiEff)
                       termOrder         (d g s b)
                       termMapping (nil d \,d g \,g s \,s b \,b)
                       namePrefix        "M"
                       componentName     "mos"
                       instParameters    (w l m as ad ps pd pes ped nf llx lly parsrc sndi sidn sndn sidi shrs shrd  delvth dtemp)
                       otherParameters   nil
                     )
           cdfId->simInfo->spectre = (list  nil
                      'modelParamExprList nil
                      'optParamExprList  nil
                      'opParamExprList   nil
                      'stringParameters  nil
                      'propMapping       '(nil w weff sndi sndiEff sidn sidnEff sndn sndnEff sidi sidiEff )
                      'termMapping       (list nil 'd '\:d 'g '\:g 's '\:s 'b '\:b)
                      'termOrder         (list 'd 'g 's 'b)
                      'componentName     nil
                      'instParameters    '(w l m as ad ps pd pes ped nf llx lly parsrc sndi sidn sndn sidi shrs shrd delvth dtemp)
                      'otherParameters   '(model)
                      )
        else
        if(!rexMatchp("3t_s$", CELL)
        then
          cdfId->simInfo->ams     = '( nil termOrder nil)
          cdfId->simInfo->auCdl   = '( nil termOrder (d g s b))
          cdfId->simInfo->hspiceD = '( nil termOrder (d g s b))
          cdfId->simInfo->spectre = '( nil termOrder (d g s b))
          cdfId->simInfo->lynx    = '( nil termOrder (d g s b))
        else
          cdfId ->simInfo->ams    = '( nil termOrder nil)
          cdfId->simInfo->auCdl   = '( nil termOrder (d g s))
          cdfId->simInfo->hspiceD = '( nil termOrder (d g s))
          cdfId->simInfo->spectre = '( nil termOrder (d g s))
        )
 
        );;; not stacked mos
       
 

        ;;; Properties
        cdfId->formInitProc            = ""
        cdfId->doneProc                = ""
        cdfId->buttonFieldWidth        = 340
        cdfId->fieldHeight             = 35
        cdfId->fieldWidth              = 350
        cdfId->promptWidth             = 175
        cdfId->instNameType            = "schematic"
        cdfId->instDisplayMode         = "instName"
        cdfId->netNameType             = "schematic"
        cdfId->termSimType             = "DC"
        cdfId->termDisplayMode         = "none"
        cdfId->opPointLabelSet         = "vth id vds vgs vdsat gds"
        cdfId->termDisplayMode         = "voltage"
        cdfId->paramSimType            = "DC"
        cdfId->paramDisplayMode        = "parameter"
        if( rexMatchp("_s$", CELL) then
            cdfId->paramLabelSet           = "w l nf m stack"
        else
            cdfId->paramLabelSet           = "w l nf m"
        )
        cdfSaveCDF( cdfId )

           
        when((and (boundp 'FDK_CDF_DUMP) FDK_CDF_DUMP)
            cdfDump(LIBRARY (strcat LIBRARY "_" CELL ".cdf") ?cellName CELL)
        )

  ) ;; let 
)

