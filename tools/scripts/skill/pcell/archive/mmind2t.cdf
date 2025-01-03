
/****************************************************/
 LIBRARY = "hyperion4_s22" 
 CELL    = "mmind2t"
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
        ?name           "model"
        ?prompt         "Model Name"
        ?defValue       "nport"
        ?type           "string"
        ?display        "nil"
        ?editable       "nil"
        ?callback       ""
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "interp"
        ?prompt         "Interpolation"
        ?defValue       "spline"
        ?type           "string"
        ?display        "nil"
        ?editable       "nil"
        ?callback       ""
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "file"
        ?prompt         "Sparameter File"
        ?defValue       "/nfs/pdx/disks/dcti_disk0036/work_x22a/template_de2/jmarulan/myDocs/hyperion/hyperion3/sparameters/ind_5w_20x_20y_5ts_5tl_21x1r2m2u1_tttt.s2p"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       ""
        ?parseAsCEL     "yes"
    )    
    cdfCreateParam( cdfId
        ?name           "filename"
        ?prompt         "FileBaseName"
        ?defValue       "ind_5w_20x_20y_5ts_5tl_21x1r2m2u1_tttt.s2p"
        ?type           "string"
        ?display        "t"
        ?editable       "nil"
        ?callback       ""
        ?parseAsCEL     "yes"
    )    
    cdfCreateParam( cdfId
        ?name           "topLayer"
        ?prompt         "topLayer"
        ?defValue       "m8"
        ?type           "string"	
        ?display        "nil"
        ?editable       "nil"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "w"
        ?prompt         "Width"
        ?units          "lengthMetric"
        ?defValue       "5u"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(intel22IndPCellCoreHyp4() 'fixIndParamsCB) list(\"w\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "dx"
        ?prompt         "DiameterX"
        ?units          "lengthMetric"
        ?defValue       "20u"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(intel22IndPCellCoreHyp4() 'fixIndParamsCB) list(\"dx\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "dy"
        ?prompt         "DiameterY"
        ?units          "lengthMetric"
        ?defValue       "20u"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(intel22IndPCellCoreHyp4() 'fixIndParamsCB) list(\"dy\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )    
    cdfCreateParam( cdfId
        ?name           "tl"
        ?prompt         "Terminal Length"
        ?units          "lengthMetric"
        ?defValue       "5u"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(intel22IndPCellCoreHyp4() 'fixIndParamsCB) list(\"tl\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "ts"
        ?prompt         "Terminal Space"
        ?units          "lengthMetric"
        ?defValue       "5u"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(intel22IndPCellCoreHyp4() 'fixIndParamsCB) list(\"ts\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "indType"
        ?prompt         "Inductor Shape"
        ?defValue       "oct"
        ?type           "radio"
	?choices        list("rec" "oct")	
        ?display        "t"
        ?editable       "t"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "fill"
        ?prompt         "Fill M7/M8"
        ?defValue       nil
        ?type           "boolean"
        ?display        "t"
        ?editable       "t"
    )
    ;;; Simulator Information
    cdfId->simInfo = list( nil )
    cdfId->simInfo->ams = '( nil
        isPrimitive       ""
        extraTerminals    ""
        propMapping       ""
        termMapping       ""
        termOrder         ""
        componentName     ""
        excludeParameters ""
        arrayParameters   ""
        stringParameters  ""
        referenceParameters ""
        enumParameters    ""
        instParameters    ""
        otherParameters   ""
        netlistProcedure  ""
    )
    cdfId->simInfo->auCdl = '( nil
        dollarEqualParams ""
        dollarParams      ""
        modelName         ""
        namePrefix        ""
        propMapping       ""
        termOrder         ""
        componentName     ""
        instParameters    ""
        otherParameters   ""
        netlistProcedure  ""
    )
    cdfId->simInfo->auLvs = '( nil
        namePrefix        ""
        permuteRule       ""
        propMapping       ""
        deviceTerminals   ""
        termOrder         ""
        componentName     ""
        instParameters    ""
        otherParameters   ""
        netlistProcedure  ""
    )
    cdfId->simInfo->hspiceD = '( nil
        opParamExprList   ""
        optParamExprList  ""
        propMapping       ""
        termMapping       ""
        termOrder         ""
        namePrefix        ""
        componentName     ""
        instParameters    ""
        otherParameters   ""
        netlistProcedure  ""
    )
    cdfId->simInfo->spectre = '( nil
        modelParamExprList nil
        optParamExprList  nil
        opParamExprList   nil
        stringParameters  nil
        propMapping       nil
        termMapping       (nil p \:1 n \:2 gnd \:3)
        termOrder         (p gnd n gnd)
        componentName     model
        instParameters    (file interp)
        otherParameters   nil
        netlistProcedure  nil
    )

    ;;; Properties
    cdfId->formInitProc            = ""
    cdfId->doneProc                = ""
    cdfId->buttonFieldWidth        = 410
    cdfId->fieldHeight             = 35
    cdfId->fieldWidth              = 410
    cdfId->promptWidth             = 120
    cdfId->paramDisplayMode        = "parameter"
    cdfId->paramLabelSet           = "indShape w dx dy ts tl"
    cdfSaveCDF( cdfId )
)
