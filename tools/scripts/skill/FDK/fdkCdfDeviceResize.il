procedure(fdkCdfDeviceResize(dimension @key (offX 0.0) (offY 0.0) (refPt "origin") (extraParams list()) (extraParamsFirst nil) (refXParamName nil) (refYParamName nil))
    let(
        (
            inst instList llX llY urX urY userPoint
            designRules cellId (xParamName nil) (yParamName nil)
            xDim yDim totalXDim totalYDim (xParamFormula nil) (yParamFormula nil)
            (xParamMin nil) (xParamMax nil) (yParamMin nil) (yParamMax nil) minXValue maxXValue
            minYValue maxYValue currFormula doX doY (xParamFormat nil) (yParamFormat nil) 
            paramFormat (xParamMinName nil) (xParamMaxName nil) 
            (yParamMinName nil) (yParamMaxName nil)
            msgPrompt allowedOrientList instOrient rotatedOrients offXPropValue offYPropValue 
        )

        ;; initialize constant variables
        rotatedOrients = list("R90" "R270" "MYR90" "MXR90")

        ;; obtain selected set from current cellview (should be device with CDF 
        ;; property form open)
        instList = geGetSelectedSet()

        ;; validate that only one instance or shape is currently selected
        cond(
            (length(instList) == 0
                warn("Device may only be resized after initial device placement.\n")
                inst = nil
            )
            (length(instList) > 1
                warn("Only one instance/shape may be selected when resizing.\n")
                inst = nil
            )
            (t
                inst = car(instList)
                instOrient = nth(1 inst~>transform)
                when(member(instOrient rotatedOrients)
                    warn("Device resize functionality not supported in rotated orientations.\n")
                    inst = nil
                )
            )
        )

        ;; determine which dimensions should be calculated based upon dimension parameter
        cond(
            (lowerCase(dimension) == "x" 
                doX = t
                doY = nil
                msgPrompt = "Select X coordinate for right edge of device"
            )
            (lowerCase(dimension) == "y" 
                doX = nil
                doY = t
                msgPrompt = "Select Y coordinate for top edge of device"
            )
            (lowerCase(dimension) == "xy"
                doX = t
                doY = t
                msgPrompt = "Select X/Y coordinate for top/right edge of device"
            )
            (t
                doX = nil
                doY = nil
                fprintf(stderr "Invalid combination of allowable device resize dimension and instance orientation")
            )
        )

        when(inst
            ;; obtain designRules data structure from selected instance master
            cellId = ddGetObj(inst~>libName inst~>cellName)
            designRules = fdkGetPropTable(cellId ?name "designRules")

	    ;; if offX and/or offY is a number, pass it in as is - otherwise, use
	    ;; fdkGetProp to retrieve necessary value
	    if(floatp(offX) || fixp(offX) then
		offsetX = offX
	    else
		offXPropValue = fdkGetProp(cellId offX)
		offsetX = fdkCdfResizeEvalFormula(offXPropValue nil cellId inst)
	    )
	    if(floatp(offY) || fixp(offY) then
		offsetY = offY
	    else
		offYPropValue = fdkGetProp(cellId offY)
		offsetY = fdkCdfResizeEvalFormula(offYPropValue nil cellId inst)
	    )

            ;; obtain the reference point for the device resize
            cond(
                (refPt == "bbox"
                    llX = caar(inst~>bBox) + offsetX
                    llY = cadar(inst~>bBox) + offsetY
                )
                (refPt == "origin"
                    llX = car(inst~>xy) + offsetX
                    llY = cadr(inst~>xy) + offsetY
                )
                (t
                    fprintf(stderr "Invalid reference point specified.\n")
                    inst = nil
                )
            )

            ;; insure that instance is in a permitted orientation
            allowedOrientList = fdkGetProp(cellId "designRules:deviceResize:allowedOrient")
            when(!member(instOrient allowedOrientList)
                fprintf(stderr "Selected instance is not placed in a permitted orientation.\n")
                inst = nil
            )
        )

        ;; continue with resizing operation if inst is non-nil
        when(inst

            when(doX
                xParamName = refXParamName || designRules["deviceResize"]["param"]["x"]["name"]
                xParamFormula = designRules["deviceResize"]["param"][xParamName]["formula"]
                xParamFormat = designRules["deviceResize"]["param"][xParamName]["format"]
                xParamMinName = designRules["deviceResize"]["param"][xParamName]["min"]
                xParamMin = fdkCdfResizeEvalFormula(xParamMinName nil cellId inst)
                xParamMaxName = designRules["deviceResize"]["param"][xParamName]["max"]
                xParamMax = fdkCdfResizeEvalFormula(xParamMaxName nil cellId inst)
            )

            when(doY
                yParamName = refYParamName || designRules["deviceResize"]["param"]["y"]["name"]
                yParamFormula = designRules["deviceResize"]["param"][yParamName]["formula"]
                yParamFormat = designRules["deviceResize"]["param"][yParamName]["format"]
                yParamMinName = designRules["deviceResize"]["param"][yParamName]["min"]
                yParamMin = fdkCdfResizeEvalFormula(yParamMinName nil cellId inst)
                yParamMaxName = designRules["deviceResize"]["param"][yParamName]["max"]
                yParamMax = fdkCdfResizeEvalFormula(yParamMaxName nil cellId inst)
            )

            ;; request a new point for upper right corner of device
            userPoint = nil
            when(msgPrompt
                userPoint = enterPoint(
                    ?prompts list(msgPrompt)
                )
            )
            
            ;; continue with resizing operation if user has selected a valid point
            when(userPoint
                
                ;; obtain the proposed bounds of new device dimensions
                ;; urX/urY from user selected point
                urX = car(userPoint)
                urY = cadr(userPoint)

                totalXDim = urX - llX
                totalYDim = urY - llY

                ;; depending upon the instance orientation, calcaulated dimension may need
                ;; to be negated to obtain the proper value
                when(member(instOrient list("R180" "MY" "R90" "MYR90"))
                    totalXDim = -totalXDim
                )
                when(member(instOrient list("R180" "MX" "R270" "MYR90"))
                    totalYDim = -totalYDim
                )

                ;; validate that requested device bounds fall within allowable range
                ;; and assign new parameter values

                ;; x dimension 
                when(xParamName && doX
                    xDim = fdkCdfResizeEvalFormula(xParamFormula totalXDim cellId inst)   
                    when(xDim < xParamMin
                        xDim = xParamMin
                        warn("%s: Value \"%L\" is less than minimum of %L. Setting result to %L.\n" xParamName totalXDim xParamMin xParamMin)
                    )
                    when(xDim > xParamMax
                        xDim = xParamMax
                        warn( "%s: Value \"%L\" is greater than maximum of %L. Setting result to %L.\n" xParamName totalXDim xParamMax xParamMax)
                        ;fprintf(stderr "Parameter \"%s\" above maximum value - setting to maximum value of %L.\n" xParamName xParamMax)
                    )
                    when(!extraParamsFirst
                        dbSet(inst sprintf(nil xParamFormat xDim) xParamName)
                    )
                )

                ;; y dimension
                when(yParamName && doY
                    yDim = fdkCdfResizeEvalFormula(yParamFormula totalYDim cellId inst)   
                    when(yDim < yParamMin
                        yDim = yParamMin
                        warn("%s: Value \"%L\" is less than minimum of %L. Setting result to %L.\n" yParamName totalYDim yParamMin yParamMin)
                        ;fprintf(stderr "Parameter \"%s\" below minimum value - setting to minimum value of %L.\n" yParamName yParamMin)
                    )
                    when(yDim > yParamMax
                        yDim = yParamMax
                        warn( "%s: Value \"%L\" is greater than maximum of %L. Setting result to %L.\n" yParamName totalYDim yParamMax yParamMax)
                        ;fprintf(stderr "Parameter \"%s\" above maximum value - setting to maximum value of %L.\n" yParamName yParamMax)
                    )
                    when(!extraParamsFirst
                       dbSet(inst sprintf(nil yParamFormat yDim) yParamName)
                    )
                )

                ;; update extra parameter values based upon formulas in property bag 
                when(doX || doY
                    foreach(param extraParams
                        when(designRules["deviceResize"]["param"][param] != 'unbound
                            currFormula = designRules["deviceResize"]["param"][param]["formula"]
                            paramFormat = designRules["deviceResize"]["param"][param]["format"]
                            when(currFormula && paramFormat
                                newParamValue = fdkCdfResizeEvalFormula(currFormula nil cellId inst
                                    ?xDim xDim ?yDim yDim)
                                dbSet(inst sprintf(nil paramFormat newParamValue) param)
                            )
                        )
                    )
                )

                ;; update x and y params here only if extraParams were updated first
                when(xParamName && doX && extraParamsFirst
                    dbSet(inst sprintf(nil xParamFormat xDim) xParamName)
                )
                when(yParamName && doY && extraParamsFirst
                    dbSet(inst sprintf(nil yParamFormat yDim) yParamName)
                )

                hiRedraw()
            )
        )

        t
    )
)

procedure(fdkCdfResizeEvalFormula(inFormula totalDimValue cellId inst @key (xDim nil) (yDim nil))
    let(
        (
            (index 1) currChar (openTag nil) paramList currBuffer
            openIndex closeIndex currPropName currStartIndex currEndIndex
            currIndex currPropName currPropValue newFormula returnValue tagType
            currTagType formula
        )

        ;; to-do: validate that formula is formatted correctly, no nested #, $, or @ and
        ;; all substituted values have non-nil values

	;; insure that formula is a string
	if(!stringp(inFormula) then
	    formula = sprintf(nil "%L" inFormula)
	else
	    formula = inFormula
	)

        ;; brackets are for tcl, so for skill use parens
        rexCompile("\\[")
        formula=rexReplace(formula "(" 0)
        rexCompile("\\]")
        formula=rexReplace(formula ")" 0)

        ;; parse each character in formula, extracting values to be replaced
        paramList = list()
        while(index <= strlen(formula)
            currChar = substring(formula index 1)
            if(openTag then
                if(member(currChar list("#" "$" "@")) then
                    openTag = nil
                    closeIndex = index
                    paramList = append(paramList list(list(currBuffer tagType openIndex closeIndex)))
                    tagType = nil
                else
                    currBuffer = strcat(currBuffer currChar)
                )
            else
                when(member(currChar list("#" "$" "@"))
                    openTag = t
                    tagType = currChar
                    openIndex = index
                    currBuffer = ""
                )
            )
            index = index + 1
        )

        ;; iterate through each extracted value, obtain process value from property bag,
        ;; or parameter from instance data
        ;; and substitute the numeric value into the formula
        newFormula = ""
        currIndex = 1
        foreach(elem paramList
            currPropName = nth(0 elem)
            currTagType = nth(1 elem)
            currStartIndex = nth(2 elem)
            currEndIndex = nth(3 elem)

            ;; copy unsubstituted text up until the first property to replace
            while(currIndex < currStartIndex
                newFormula = strcat(newFormula substring(formula currIndex 1))
                currIndex = currIndex + 1
            )

            ;; obtain property value and write it to the new formula representation
            cond(
                (currPropName == "totalAvailDim"
                    newFormula = strcat(newFormula sprintf(nil "%L" totalDimValue))
                )
                (currPropName == "yDim"
                    newFormula = strcat(newFormula sprintf(nil "%L" yDim))
                )
                (currPropName == "xDim"
                    newFormula = strcat(newFormula sprintf(nil "%L" xDim))
                )
                (t
                    cond(
                        (currTagType == "#"
                            currPropValue = fdkGetProp(cellId currPropName ?meters nil)
                        )
                        (currTagType == "$"
                            currPropValue = evalstring(currPropName)
                        )
                        (currTagType == "@"
                            currPropValue = fdkProcessString(dbGet(inst currPropName))
                        )
                    )
                    newFormula = strcat(newFormula sprintf(nil "%L" currPropValue))
                )
            )

            ;; set new currIndex value and continue with next element to process
            currIndex = currEndIndex + 1 
        )

        ;; finish with any unsubstituted content from original formula
        while(currIndex <= strlen(formula)
            newFormula = strcat(newFormula substring(formula currIndex 1))
            currIndex = currIndex + 1
        )
        
        returnValue = evalstring(newFormula)
    )
)
