
/****************************************************/
 LIBRARY = "hyperion4_s22" 
 CELL    = "mmmfc_cst"
/****************************************************/

let( ( libId cellId cdfId )
    unless( cellId = ddGetObj( LIBRARY CELL )
        error( "Could not get cell %s." CELL )
    )
    when( cdfId = cdfGetBaseCellCDF( cellId )
        cdfDeleteCDF( cdfId )
    )
    cdfId  = cdfCreateBaseCellCDF( cellId )

    ;;; Parameters
    cdfCreateParam( cdfId
        ?name           "botLayer"
        ?prompt         "botLayer"
        ?defValue       "m1"
        ?type           "radio"
	?choices        list("m1" "m2" "m3" "m4" "m5")	
        ?callback       "apply(get(intel22MfcPCellCore() 'fixMfcParamsCB) list(\"botLayer\" cdfgData))"
        ?display        "t"
        ?editable       "t"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "nx"
        ?prompt         "X-Array"
        ?units          ""
        ?defValue       "1"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(intel22MfcPCellCore() 'fixMfcParamsCB) list(\"nx\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "ny"
        ?prompt         "Y-Array"
        ?units          ""
        ?defValue       "1"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(intel22MfcPCellCore() 'fixMfcParamsCB) list(\"ny\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "cap"
        ?prompt         "Total Capacitance"
        ?units          "capacitance"
        ?defValue       "27.383f"
        ?type           "string"
        ?display        "t"
        ?editable       "nil"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "cellSize"
        ?prompt         "Cell Size OGD(u) x PGD(u)"
        ?units          ""
        ?defValue       "3.24 x 2.52"
        ?type           "string"
        ?display        "t"
        ?editable       "nil"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    
    ;;; Simulator Information
    cdfId->simInfo = list( nil )
    ;;; Properties
    cdfId->formInitProc            = ""
    cdfId->doneProc                = ""
    cdfId->buttonFieldWidth        = 410
    cdfId->fieldHeight             = 35
    cdfId->fieldWidth              = 410
    cdfId->promptWidth             = 120
    cdfId->paramDisplayMode        = "parameter"
    cdfId->paramLabelSet           = "cap nx ny"
    cdfSaveCDF( cdfId )
)
