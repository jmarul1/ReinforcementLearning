;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; create global FdkSuffixArray
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkSetSuffixArray( ) 
    ; global FdkSuffixArray
    ; only create entries if unbound
    if( !boundp('FdkSuffixArray) then
        FdkSuffixArray = makeTable('FdkSuffixArray)
        FdkSuffixArray["Y"]="e+24"
        FdkSuffixArray["Z"]="e+21"
        FdkSuffixArray["E"]="e+18"
        FdkSuffixArray["P"]="e+15"
        FdkSuffixArray["T"]="e+12"
        FdkSuffixArray["G"]="e+9"
        FdkSuffixArray["M"]="e+6"
        FdkSuffixArray["k"]="e+3"
        FdkSuffixArray["K"]="e+3"
        FdkSuffixArray["h"]="e+2"
        FdkSuffixArray["da"]="e+1"
        FdkSuffixArray["d"]="e-1"
        FdkSuffixArray["c"]="e-2"
        FdkSuffixArray["%"]="e-2"
        FdkSuffixArray["m"]="e-3"
        FdkSuffixArray["u"]="e-6"
        FdkSuffixArray["n"]="e-9"
        FdkSuffixArray["p"]="e-12"
        FdkSuffixArray["f"]="e-15"
        FdkSuffixArray["a"]="e-18"
        FdkSuffixArray["e"]="e-21"
        FdkSuffixArray["y"]="e-24"
    )
    t
) ; end procedure

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       scaleToMicrons
;  Scales number and snaps to grid
;  This is no longer used in fdkGetProp but may still
;  be used in other code, so is retained for that
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkScaleToMicrons( value @key (scale 1.0) (grid  0.001))
    let( (tmp halfGrid)
        if( grid <= 0 then
            tmp = value / scale 
        else
            halfGrid=grid/2.0
            tmp = floor(((value/scale)+halfGrid)/grid)
            tmp = tmp*1.0*grid
        )
    )
) ; end procedure

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       scale
;  Scales number
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkScale( value @key (scale 1.0))
    let( (tmp)
        tmp = value / scale 
    )
) ; end procedure

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       snapToGrid
;  Snaps to grid
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkSnapToGrid( value @key (grid  0.001))
    let( (tmp halfGrid)
        halfGrid=grid/2.0
        tmp = floor((value+halfGrid)/grid)
        tmp = tmp*1.0*grid
    )
) ; end procedure


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkStringGetFormat
;  returns p for pico, n for nanometers, u for microns, m for millimeters
;  "" means any number which is not nanometers or
;   microns, so it's conversion is governed by scale/grid
;  or nil meaning it is not a string or number
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkStringGetFormat(string)
    ;global FdkSuffixArray
    let( (num form)
        if(!stringp(string) then
            nil
        else
            if(!numberp(atof(string)) then
                nil
            else
                ;check for special condition of *e 
                rexCompile("\\(.*\\)\\(e\\)$")
                if( rexExecute(string) then
                    form = rexSubstitute("\\2")
                    num = rexSubstitute("\\1")
                    if( floatp(atof(num)) then
                        fdkSetSuffixArray()
                        if(FdkSuffixArray[form]!='unbound then
                            form
                        else
                            nil
                        )
                    else
                        nil
                    )
                else
                    ;check for e-notation (note *e case not included)
                    rexCompile("^\\([+-]*[0-9.eE+-]+\\)\\(.*\\)$")
                    if( rexExecute(string) then
                        form = rexSubstitute("\\2")
                        if( form != "" then
                            fdkSetSuffixArray()
                            if(FdkSuffixArray[form]!='unbound then
                                form
                            else
                                nil
                            )
                        else
                            form
                        )
                    else
                        nil
                    )
                )
                ;finished checking patterns for e-notation
            )
            ;non-number
        ) 
        ;non-string
    )
) ; end procedure

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkProcessString
;  Converts string to a number if it is a number. If not a number returns nil.
;  If it is a number with recognized suffix it also
;  scales the value to microns and snaps to grid.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkProcessString(string @key (scale nil) (grid -1) (meters nil) )
    ;global FdkSuffixArray
    ;NOTE: scale is here for backwards compability for some pcells. NOT USED.
    let( (format pat ns ret)
        format = fdkStringGetFormat(string)
        cond(
            (format == nil ret=nil         )
            (format == ""  ret=atof(string))
            (t
                pat = sprintf(nil "%s$" format)
                rexCompile(pat)
                ns=rexReplace(string "" 0)
                if(format == "n" && meters==nil then
                    ret=fdkScale(atof(ns) ?scale 1e+3)
                else 
                    if(format == "u" && meters==nil then
                        ret=atof(ns)
                    else
                        if(format == "m" && meters==nil then
                            ret=fdkScale(atof(ns) ?scale 1e-3)
                        else
                             if(format == "p" && meters==nil then
                                ret=fdkScale(atof(ns) ?scale 1e+6)
                             else
                              ;number part gets new suffix and turned into number
                                ns=sprintf(nil "%s%s" ns FdkSuffixArray[format])
                                ret=atof(ns)
                             )
                        )
                    );endifu
                );endifn
            );end cond t
        );end cond
        ;convert grid to non-suffix form if needed
        if(stringp(grid) then
            gformat = fdkStringGetFormat(grid)
            cond(
                (gformat == nil ng=nil         )
                (gformat == ""  ng=atof(grid))
                (t
                    pat = sprintf(nil "%s$" gformat)
                    rexCompile(pat)
                    ng=rexReplace(grid "" 0)
                    ;number part gets new suffix and turned into number
                    ng=sprintf(nil "%s%s" ng FdkSuffixArray[gformat])
                    ng=atof(ng)
                );end cond t
            );end cond
        else
            ng = grid
        )
        ;if a number and snapping enabled, snap it!
        if(ret && numberp(ng) && ng >= 0.0 then
            if(meters==nil then
                if(format=="u" then
                    ng=fdkScale(ng ?scale 1e-6)
                )
                if(format=="n" then
                    ng=fdkScale(ng ?scale 1e-6)
                )
            )
            fdkSnapToGrid(ret ?grid ng)
        else
            ret
        )
    ); end let
) ; end procedure

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkConvertBoolean
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkConvertBoolean(value)
    let(
        (
          return_value
        )
        if(stringp(value) then
            cond(
                (lowerCase(value) == "true"
                    return_value = t
                )
                (lowerCase(value) == "false"
                    return_value = nil
                )
                (lowerCase(value) == "t"
                    return_value = t
                )
                (lowerCase(value) == "nil"
                    return_value = nil
                )
                ( t
                    return_value = value
                )
            )
        else
            if(value == nil then
                return_value = ""
            else
                return_value = value
            )
        )
        return_value
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkStringExternalSpacePurge
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkStringExternalSpacePurge(string)
    rexCompile( "^[ \t]*" )
    string = rexReplace( string "" 1)
    rexCompile( "[ \t]*$" )
    string = rexReplace( string "" 1)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkStringIsInteger
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkStringIsInteger(string)
    let(
        (
            itis
        )
        itis = nil
        if(stringp(string) && rexMatchp("^[+-]*[0-9]+$" string) then
            itis = t
        )
        itis
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkParsePropElements
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkParsePropElements(value @key
                (string nil)
                (meters nil)
                (grid -1)
                                (boundLeft "{")
                                (boundRight "}")
                                (delimiter ","))
    let(
        (
            currChar dataOpen returnData
            currElem valueLength appendChar appendElem
            escapeChar currElemIsList
        )
        if( !rexMatchp("^{[ ]*}$" value) then
        ;not an empty list...so process it!
        ; set initial variable values
        dataOpen = 0    
        currElem = ""
        ;with nconc need to start with a dummy in the list
        returnData = list("OMIT")
        valueLength = strlen(value)

        ; iterate over each character in value and parse based upon
        ; left/right bounding characters and delimiter
        escapeChar = nil
        currElemIsList = nil
        for(charNum 1 valueLength
          appendChar = appendElem = nil
          currChar = symbolToString(getchar(value charNum))
          ;uncomment for debug of progression...
          ;fprintf(stderr "%L>%L" charNum currChar)
          if( !escapeChar then
            ;uncomment for debug of progression...
            ;fprintf(stderr "|")
            cond(
              (currChar == "\\"
                  escapeChar = t
                  appendChar = nil
              )
              (currChar == "\"" || currChar == "'" 
                  appendChar = nil
              ) 
              (currChar == boundLeft
                  if(dataOpen > 0 then
                      appendChar = t
                      if( strlen(currElem) == 0 then
                          ;first char in curElem is boundLeft, so will be a list
                          currElemIsList = t
                              )
                  ) 
                  dataOpen = dataOpen + 1
              ) 
              (currChar == boundRight
                dataOpen = dataOpen - 1 
                if( dataOpen > 0 then
                    appendChar = t
                ) 
                if( dataOpen == 0 then
                    if( charNum != valueLength then
                        error("Improper formatted data - fdkParsePropElements")
                    else
                        if( currElem != "" then
                            appendElem = t
                        )
                    )
                )
              ) 
              (currChar == delimiter && dataOpen == 1 
                appendElem = t
              )
              (t 
                appendChar = t
              )
            )
          else 
            ;don't interpret, just use. If it is normally a boundRight and
            ;begins the curElem
            ;then here it won't later be processed as a list through recursion
            appendChar = t
            escapeChar = nil
            ;uncomment for debug of progression...
            ;fprintf(stderr ":")
          )

          ; append current character to currElem unless it is a leading space
          ; leading spaces can cause a problem for currElem if  first non-space
          ; character is a boundLeft
          if(appendChar then
            if(currChar != " " || strlen(currElem) != 0 then 
                currElem = strcat(currElem currChar)
            )
          )

          ; if a delimiter or the last rightBound, append the current Element
          if(appendElem then 
            ;squeeze out only leading/trailing spaces (should be no leading sp)
            currElem = fdkStringExternalSpacePurge(currElem)
            ;append either the currElem if it can't be a list
            ;....or try to convert it to a list through recursion
            nconc(returnData (list fdkConvertPropValue(
                                        currElem
                                        ?string string
                                        ?aslist currElemIsList
                                        ?meters meters
                                        ?grid grid
                                   )
                              ) 
            )
            ;reset!
            currElem = ""
            currElemIsList = nil
          )
        )
        ;uncomment for debug of progression...
        ;fprintf(stderr "\n")

        ;list element 0 is a dummy, so return only the rest of the list
        cdr(returnData)
    else
        list( )
    ) 
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkConvertPropValue
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkConvertPropValue(value @key (string nil) (aslist t) (meters nil) (grid -1))
    let(
        (
            propValue
        )
        
        ; initiate return value to be a list in case it is needed
        propValue = list()

        ; conditionally parse property value if enclosed in curly braces,
        ; otherwise return the raw value
        if(stringp(value) && rexMatchp("^{.*}$" value) && aslist then
            propValue = fdkParsePropElements(value ?string string ?meters meters ?grid grid)
            ;uncomment to debug parse, also uncomment lines in
            ;fdkParsePropElements!
            ;fprintf(stderr "value=%L produces propValue=%L\n" value propValue)
        else
            if(string then
                cond(
                    (stringp(value) 
                        ;squeeze out only leading/trailing white space
                        propValue = fdkStringExternalSpacePurge(value)
                    )
                    (t
                        ;all should be strings in prop bags....but just in case!
                        cond(
                            (fixp(value) propValue = sprintf(nil "%d" value))
                            (floatp(value) propValue = sprintf(nil "%g" value))
                        )
                    )
                )
            else
                if(stringp(value) then
                    if( fdkStringIsInteger(value) then
                        propValue = atoi(value)
                    else 
                        propValue = fdkProcessString(value ?meters meters ?grid grid)
                        cond(
                            ( floatp(propValue)
                                propValue = propValue
                            )
                            ( stringp(propValue)
                                propValue=fdkStringExternalSpacePurge(propValue)
                            )
                            ( stringp(value)
                                ;propValue = buildString(parseString(value))
                                propValue = fdkStringExternalSpacePurge(value)
                            )
                            ( t
                                propValue = value
                            )
                        )
                    )
                else
                    propValue = value
                )
            )
            propValue = fdkConvertBoolean(propValue)
        )
        propValue
        
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkAppendPropTable
; Recursive.
; pV is table to append. If nil it is the first time this is called.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(
 fdkAppendPropTable(dbId @key (name "") (string nil) (pV nil) (meters nil) (grid -1))
    let(
        (
            idKeyList valueType value (newTableFlag nil)
        )
        if( name == ""  then
            name = "PROPBAG"
            valueType = "hierProp"
        else 
            if(dbIsId(dbId) then
                ;name passed in is not the name of this pair
                name = dbId->name
                valueType = dbId->valueType
            else
                ;this is flat...use the name passed in
                valueType = ""
            )
        )
        if(pV==nil then
            newTableFlag=t
            pV = makeTable(name)
        )
        if( valueType != "hierProp"  then  
            if(dbIsId(dbId) then
                ;hierarchial key to value
                name = dbId->name
                value = dbId->value
            else
                ;flat key to value
                value = dbId
            )
            pV[name]=fdkConvertPropValue(value ?string string ?meters meters ?grid grid)
        else 
            ;this is a hierarchy, so create a sub-table unless a new table
            idKeyList = dbId->prop
            if(newTableFlag then
                foreach( prop idKeyList
                    pV = fdkAppendPropTable(
                        prop
                        ?name name
                        ?string string
                        ?pV pV
                        ?meters meters
                        ?grid grid
                    )
                ) 
            else
                pV[name] = makeTable(name)
                foreach( prop idKeyList
                    pV[name] = fdkAppendPropTable(
                        prop 
                        ?name name
                        ?string string
                        ?pV pV[name]
                        ?meters meters
                        ?grid grid
                    )
                ) 
            )  
        )
        pV
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkPrintEmbeddedList
; prints a list as a series of yaml format items
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(
 fdkPrintEmbeddedList(listV @key (level "  ") )
    ;prints list in yaml format
    let(
        (
            newLevelString tableName tableCalled
        )
        elementCount = 0
        foreach(value listV
            if( tablep( value) then
                tableCalled = sprintf(nil "%L" value)
                tableName = nth(1 parseString(tableCalled ":") )
                fprintf(stderr "%s%d: table:%s\n" level elementCount tableName)
                newLevelString = strcat( level "  ")
                fdkPrintTable(value ?level newLevelString)
            else
                if( listp( value) then
                    fprintf(stderr "%s%d: %L\n" level elementCount value)
                    newLevelString = strcat( level "  ")
                    fdkPrintEmbeddedList(value ?level newLevelString)
                else 
                    fprintf(stderr "%s%d: %L\n" level elementCount value)
                )
            )
            elementCount = elementCount + 1
        )
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkPrintTable
; outputs the property bag in yaml format
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(
 fdkPrintTable(pV @key (level "  ") )
    ;prints table in yaml format
    let(
        (
            newLevelString tableName tableCalled
        )
        if( tablep( pV) then
            tableCalled = sprintf(nil "%L" pV)
            tableName = nth(1 parseString(tableCalled ":") )
            if( strlen(level) == 2 then 
                fprintf(stderr "%s:\n" tableName)
            )
            foreach(element pV
                if( tablep( pV[element]) then
                    fprintf(stderr "%s%L:\n" level element)
                    newLevelString = strcat( level "  ")
                    fdkPrintTable(pV[element] ?level newLevelString)
                else
                    if( listp( pV[element]) then
                        fprintf(stderr "%s%L: %L\n" level element pV[element])
                        newLevelString = strcat( level "  ")
                        fdkPrintEmbeddedList(pV[element] ?level newLevelString)
                    else 
                        fprintf(stderr "%s%L: %L\n" level element pV[element])
                    )
                )
            )
        else
            fprintf(stderr "fdkPrintTable did not get a table but got:%L\n" pV)
        )
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkElementInTable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(
 fdkElementInTable(req pV @key (table 1) (hier 1))
    let(
        (
            itis
        )
        itis = nil
        if( tablep( pV) then
            prog( ()
            foreach( element pV
                ;fprintf(stderr "element:%L pV:%L\n" element pV)
                if( tablep( pV[element]) then
                    if( table != 1 then
                        if( hier == 1 then
                            itis=fdkElementInTable(
                                req 
                                pV[element]
                                ?table table 
                                ?hier hier
                            )
                        )
                    else
                        if( element == req then 
                            itis = t
                            go( breakloop)
                        ) 
                    )
                else
                    if( element == req  then 
                        itis = t
                        go( breakloop)
                    )
                )
            )
            breakloop
            )
        else
            fprintf(stderr "fdkElementInTable did not get a table but got:%L" pV)
        )
        itis
    )
)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; fdkGetProp
; The boolean argument is retained but no longer used
; because boolean was an argument for the original fdkGetProp.
; Currently fdkGetProp will do numeric conversion to meters
; so it can be used as-is in SKILL callbacks which use
; cdfParseFloatString to take string numbers and convert to
; meters.  When callbacks start using microns, meters should
; be nil instead.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(
 fdkGetProp(ddId name @key (string nil) (boolean nil) (meters t) (grid -1))
    let(
        (
            propValue propList
        )
        ; get complete property bag data structure
        unless(propValue = dbOpenBag(ddId "r")
            error("Prop bag doesn't exist for %s/%s" ddId~>lib~>name ddId~>name)
        )
        ; parse requested property string
        propList = parseString(name ":")
        ; get to requested element in property hierarchy
        foreach(eprop propList
            propValue = get(propValue eprop)
        )
        ; convert value
        ; if a dbId returns nil
        ; if boolean returns as a skill boolean
        ; if non-number string returns that string
        ; if a number string but ?string == t, returns a string
        ; if a non-list non-number string returns a string
        ; if a list returns a skill list of such elements
        fdkConvertPropValue(propValue ?string string ?meters meters ?grid grid)
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkGetPropTable
; Returns a table representing either the complete property bag
; for a cell or a subset of the property bag.
; 
; Can get a subset of the proptable by specifying "name"
; The table hierarchy defined by "name" will NOT be included in the table
; Example: x=fdkGetPropTable(cellid ?name "designRules")
;      designRules:device:W=1
;      designRules:device:L=1
;    returns a table:
;        x["device"]["W"] is equal to 1
;        x["device"]["L"] is equal to 1
;
; If "name" leads to a value, a table is returned named "name"
; AND a key "name" pointing to the value.
; Example: mytable = fdkGetPropTable(cellid ?name "minlength")
;   would return mytable and its name is minlength.
;   to get the value it would be necessary to do this:
;   myvalue = mytable["minlength"]
;
; When a value is returned it might be a skill boolean, a
; skill string, or a skill list.
;
; It could also return a number unless ?string == t.  The default
; is that numeric strings are converted to an integer or the number
; in microns.
;
; When ?string==t, then a string number is maintained as that string.
;
; String lists are returned as a SKILL list but if individual elements
; are not lists or booleans they are either converted to numbers if
; numbers or maintained as strings.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(
 fdkGetPropTable(ddId @key (name "") (string nil) (meters nil) (grid -1))
    let(
        (
            propValue prop propList
        )
        ; get complete property bag data structure
        unless(propValue = dbOpenBag(ddId "r")
            error("Prop bag doesn't exist for %s/%s" ddId~>lib~>name ddId~>name)
        )
        ; Walk through "name".  If not defined, pass in an empty string
        ; to recursive function fdkAppendPropTable.
        ; prop will be the name of the table and if prop points to a
        ; scalar value is also the prop key for the table.
        ; propValue is either the scalar value or a dbId indicating a
        ; hierarchy to go into the table.
        propList = parseString(name ":")
        ; get to requested element in property hierarchy
        prop = ""
        foreach(eprop propList
            prop = eprop
            propValue = get(propValue eprop)
        )
        if(propValue == nil then
            propValue
        else 
            ; get all elements as a table or a table with name>value
            fdkAppendPropTable(propValue ?name prop ?string string ?meters meters ?grid grid)
        )
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Outputs the contents of a property bag attached to 
; libName/cellName to either a specified output file or
; standard output
;
; string and meters options may be set that are passed
; into the fdkGetPropTable and fdkGetProp routines
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure(fdkOutputVerifiedPropBagTable(libName cellName 
            @key 
                (table nil)
                (outData list()) 
                (string nil) 
                (meters nil) 
                (grid -1)
                (name "")
                (outFilePath "")
                (outFileName "propBag_il.out")
                (stdout nil)
                (level 0))
    let(
        (
            ddId propTable ignoreList returnData elem fileHandle 
            currElem currOutData fullFileName
        )

        if(!table then
            ;; retrieve property bag information in table format
            unless(ddId = ddGetObj(libName cellName)
                artError("Cellview %L/%L does not exist" libName cellName)
            )
            ;; make sure that for builds the FDK_WORK is used
            if(outFilePath == "" then
                outFilePath=getWorkingDir()
                fdkWorkPath=getShellEnvVar(sprintf(nil "%s%s%s_%s" "F" "D" "K" "WORK"))
                if(fdkWorkPath then
                    if(outFilePath != fdkWorkPath then
                        outFilePath = fdkWorkPath
                    ) 
                )
            )
            propTable = fdkGetPropTable(ddId ?name name ?string string ?meters meters ?grid grid)
        else
            propTable = table
        )

        ;; iterate over each element in the propTable ignoring those elements in
        ;; the ignoreList since they are not actual property bag values
        ignoreList = list("cdfData")

        ;; this variable is a list of strings representing the values of each
        ;; property in the property table which will be iterated over and printed
        ;; to a file when the entire property bag has been traversed
        currOutData = outData

        foreach(elem propTable

            ;; when the current element from the propTable is not in the ignoreList
            ;; or if we are in the function recursively, then we want to process
            ;; the value so we can add it to our output
            when(!member(elem ignoreList) || level != 0
                currElem = propTable[elem]

                ;; if we are at the top level of the hierarchy, then the fully
                ;; resolved property name is the name itself, otherwise, we build
                ;; the hierarchical property name with the : syntax
                if(level == 0 then
                    nextName = elem
                else
                    nextName = sprintf(nil "%s:%s" name elem)
                )

                ;; if we encounter a property that is itself a table, then we
                ;; call the fdkOutputVerifiedPropBagTable function recursively
                if(tablep(currElem) then
                    currOutData = fdkOutputVerifiedPropBagTable(libName cellName 
                        ?table currElem
                        ?string string 
                        ?meters meters 
                        ?grid grid
                        ?name nextName
                        ?outData currOutData
                        ?level level + 1
                    )
                else

                    ;; otherwise we process the value as a list or a scalar value
                    ;; and add the new property name and value to the currOutData structure
                    cond(
                        (listp(currElem) && currElem != nil
                            returnData = fdkProcessPropBagList(currElem)
                        )
                        (t
                            returnData = fdkProcessPropBagValue(currElem)
                        )
                    )
                    returnData = sprintf(nil "%s %s" nextName returnData)
                    currOutData = cons(returnData currOutData)
                )
            )
        )

        ;; if at the top call to fdkOutputVerifiedPropBagTable, print all the 
        ;; accumulated property/value pairs to output file, otherwise return 
        ;; currOutData to recursively called function for further accumulation
        if(level == 0 then

            ;; if standard output option not set, all data should be written to
            ;; the output file
            if(!stdout then

                ;; if file name contains '/', then file name specifies an
                ;; absolute path and outFilePath should not be used
                if(length(parseString(outFileName "/")) > 1 then
                    fullFileName = outFileName
                else
                    fullFileName = sprintf(nil "%s/%s" outFilePath outFileName)
                )

                ;; open output file for writing if possible and write each
                ;; property/value pair of property bag
                ;; (return error if unable to open/write to output file)
                fileHandle = outfile(fullFileName "w")
                if(fileHandle then
                    fprintf(fileHandle "language=skill\n")
                    foreach(elem sort(currOutData nil)
                        fprintf(fileHandle "%s\n" elem)
                    )
                    drain(fileHandle)
                    close(fileHandle)
                    if( name == "" then
                        name = "the top of the property bag"
                    )
                    shell(sprintf(nil "echo \"(language=skill) PropBag starting at %s written to %s\"\n" name fullFileName))
                    t
                else
                    error("fdkOutputVerifiedPropBagTable: ERROR - Invalid path %s" fullFileName)
                )
            else

                ;; standard output option has been selected so output property/value data to the
                ;; current shell instead of the output file
                shell("echo \"language=skill\"\n")
                foreach(elem sort(currOutData nil)
                    shell(sprintf(nil "echo \"%L\"\n" elem)) 
                )
            )
        else
            currOutData
        )
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Walks through each element in a property bag list
; value and returns either the scalar value or
; recursively calls the same function for embedded
; lists
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure(fdkProcessPropBagList(valueList @key (outData "["))
    let(
        (
            currOutData currElem
        )

        ;; iterate over each value in a list and return as a string in the format
        ;; [(name value) ...]
        currOutData = outData
        for(i 0 length(valueList)-1
            currElem = nth(i valueList)

            ;; if a list is embedded inside a list, recursively call the fdkProcessPropBagList
            ;; function to continue to build the final list output structure in the format
            ;; [[(name1 value1) (name2 value2)] [(name3 value3) (name4 value4)]]
            if(listp(currElem) && currElem != nil then
                currOutData = strcat(currOutData "[")
                currOutData = fdkProcessPropBagList(currElem ?outData currOutData)
            else
                currOutData = strcat(currOutData fdkProcessPropBagValue(currElem))
            )
        )
        currOutData = strcat(currOutData "]")
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Returns the combination of scalar value type and
; scalar value for output to file or stdout
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure(fdkProcessPropBagValue(value)
    let(
        (
            returnData boolValue
        )

        ;; process a single value and based upon its type, return a string in the form (type value)
        cond(
            (integerp(value)
                returnData = sprintf(nil "(i %d)" value)
            )
            (floatp(value)
                if(value == 0.0 then
                    returnData = sprintf(nil "(f %s)" "0.0")
                else
                    ;increases precision on some floats to match python
                    returnData = sprintf(nil "%5.7g" value)
                    ;some formats introduce extra spaces, so trim!
                    returnData = fdkStringExternalSpacePurge(returnData)
                    ;return duple as expected
                    returnData = sprintf(nil "(f %s)" returnData)
                )
            )
            (stringp(value)
                returnData = sprintf(nil "(s %s)" value)
            )
            (listp(value)
                if(value == nil then
                    returnData = sprintf(nil "[]")
                else
                    ;this should never happen because only 
                    ;a nil list would get to this proc
                    returnData = sprintf(nil "[ UNEXPECTED]")
                )
            )
            (booleanp(value)
                if(value == t then
                    boolValue = "True"
                else
                    boolValue = "False"
                )
                returnData = sprintf(nil "(b %s)" boolValue)
            )
            (t
                returnData = sprintf(nil "(%L %L)" type(value) value)
            )
        )

        returnData
    )
)
