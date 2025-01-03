
/****************************************************/
 LIBRARY = "hyperion4_s22" 
 CELL    = "mmxfmr"
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
        ?defValue       "/nfs/pdx/disks/dcti_disk0036/work_x22a/template_de2/jmarulan/myDocs/hyperion/hyperion3/sparameters/mmxfmr_oct_1n_2p1m8w_2p1m7w_20m8do_20m7do_5tl_5ts_0dlt_21x1r2m2u1_tttt_1p2_0p1lt.s6p"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       ""
        ?parseAsCEL     "yes"
    )    
    cdfCreateParam( cdfId
        ?name           "filename"
        ?prompt         "FileBaseName"
        ?defValue       "mmxfmr_oct_1n_2p1m8w_2p1m7w_20m8do_20m7do_5tl_5ts_0dlt_21x1r2m2u1_tttt_1p2_0p1lt.s6p"
        ?type           "string"
        ?display        "t"
        ?editable       "nil"
        ?callback       ""
        ?parseAsCEL     "yes"
    )    
    cdfCreateParam( cdfId
        ?name           "priCoil"
        ?prompt         "Primary Coil Layer"
        ?defValue       "m8"
        ?type           "string"	
        ?display        "nil"
        ?editable       "nil"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "secCoil"
        ?prompt         "Secondary Coil Layer"
        ?defValue       "m8"
        ?type           "string"	
        ?display        "nil"
        ?editable       "nil"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "wM8"
        ?prompt         "Metal8 Width"
        ?units          "lengthMetric"
        ?defValue       "2.1u"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(intel22XfmrPCellCoreHyp4() 'fixXfmrParamsCB) list(\"wM8\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "wM7"
        ?prompt         "Metal7 Width"
        ?units          "lengthMetric"
        ?defValue       "2.1u"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(intel22XfmrPCellCoreHyp4() 'fixXfmrParamsCB) list(\"wM7\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "doM8"
        ?prompt         "Diameter Primary"
        ?units          "lengthMetric"
        ?defValue       "20u"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(intel22XfmrPCellCoreHyp4() 'fixXfmrParamsCB) list(\"doM8\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "doM7"
        ?prompt         "Diameter Secondary"
        ?units          "lengthMetric"
        ?defValue       "20u"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(intel22XfmrPCellCoreHyp4() 'fixXfmrParamsCB) list(\"doM7\" cdfgData))"
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
        ?callback       "apply(get(intel22XfmrPCellCoreHyp4() 'fixXfmrParamsCB) list(\"tl\" cdfgData))"
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
        ?callback       "apply(get(intel22XfmrPCellCoreHyp4() 'fixXfmrParamsCB) list(\"ts\" cdfgData))"
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
    cdfCreateParam( cdfId
        ?name           "ext"
        ?prompt         "Fill Extension"
        ?defValue       "0u"
        ?units          "lengthMetric"	
        ?type           "string"
        ?display        "apply(get(intel22XfmrPCellCoreHyp4() 'disXfmrParams) list(\"fill\" cdfgData))"	
        ?editable       "t"
        ?parseAsNumber  "yes"	
        ?parseAsCEL     "yes"
        ?callback       "apply(get(intel22XfmrPCellCoreHyp4() 'fixXfmrParamsCB) list(\"ext\" cdfgData))"	
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
    cdfId->paramLabelSet           = "indShape wM8 wM7 doM8 doM7 ts tl"
    cdfSaveCDF( cdfId )
)
