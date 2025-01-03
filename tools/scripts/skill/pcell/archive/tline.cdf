
/****************************************************/
 LIBRARY = "hyperion3_s22" 
 CELL    = "tline"
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
        ?defValue       "/nfs/pdx/disks/dcti_disk0036/work_x22a/template_de2/jmarulan/myDocs/hyperion/hyperion3/sparameters/tline_5w_100l_5s_21x1r2m2u1_tttt.s6p"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       ""
        ?parseAsCEL     "yes"
    )    
    cdfCreateParam( cdfId
        ?name           "filename"
        ?prompt         "FileBaseName"
        ?defValue       "tline_10w_100l_5s_21x1r2m2u1_tttt.s6p"
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
        ?name           "botLayer"
        ?prompt         "botLayer"
        ?defValue       "m7"
        ?type           "string"
        ?display        "nil"
        ?editable       "nil"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "s"
        ?prompt         "Space"
        ?units          "lengthMetric"
        ?defValue       "5u"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(intel22TlPCellCore() 'fixTlParamsCB) list(\"s\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "wm"
        ?prompt         "Width Middle"
        ?units          "lengthMetric"
        ?defValue       "10u"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(intel22TlPCellCore() 'fixTlParamsCB) list(\"wm\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "lm"
        ?prompt         "Length Middle"
        ?units          "lengthMetric"
        ?defValue       "100u"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(intel22TlPCellCore() 'fixTlParamsCB) list(\"lm\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "wt"
        ?prompt         "Width Top"
        ?units          "lengthMetric"
        ?defValue       "10u"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(intel22TlPCellCore() 'fixTlParamsCB) list(\"wt\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "lt"
        ?prompt         "Length Top"
        ?units          "lengthMetric"
        ?defValue       "10u"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(intel22TlPCellCore() 'fixTlParamsCB) list(\"lt\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "wb"
        ?prompt         "Width Bottom"
        ?units          "lengthMetric"
        ?defValue       "10u"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(intel22TlPCellCore() 'fixTlParamsCB) list(\"wb\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "lb"
        ?prompt         "Length Bottom"
        ?units          "lengthMetric"
        ?defValue       "10u"
        ?type           "string"
        ?display        "t"
        ?editable       "t"
        ?callback       "apply(get(intel22TlPCellCore() 'fixTlParamsCB) list(\"lb\" cdfgData))"
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
    )
    cdfCreateParam( cdfId
        ?name           "l"
        ?prompt         "Effective Length"
        ?units          "lengthMetric"
        ?defValue       "133.746u"
        ?type           "string"
        ?display        "t"
        ?editable       "nil"
        ?callback       ""
        ?parseAsNumber  "yes"
        ?parseAsCEL     "yes"
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
        termOrder         (gnd gnd gnd gnd p gnd n gnd gnd gnd gnd gnd)
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
    cdfId->paramLabelSet           = "w l s"
    cdfSaveCDF( cdfId )
)
