procedure(fdkGenRingStructureForm(@key (srcLibs list("intel22tech" "intel22prim")))
	let(
		(
			libId libTable cellId cellProp lblWidth fldHeight fldX 
			lblLibrary cycLibrary lblRingCells cycRingCells
			defLibName defRingCells lblBufferSpcX lblBufferSpcY lblInstName
			strBufferSpcX strBufferSpcY strInstName
		)

		;; initialize form constants
		lblWidth = 150
		fldHeight = 30
		fldX = lblWidth + 20

		libTable = makeTable('ringCells nil)

		foreach(lib srcLibs
			libTable[lib] = fdkFindLibRingsBase(lib)
		)

		libList = getq(libTable ?)
		defLibName = car(libList)
		defRingCells = libTable[defLibName] 
		when(!defRingCells
			defRingCells = append(defRingCells list("* No Supported Structures *"))
		)
		defRingCells = sort(defRingCells nil)

		lblLibrary = hiCreateLabel(
			?name 'lblLibrary
			?labelText "Source Library"
		)
		cycLibrary = hiCreateCyclicField(
			?name 'cycLibrary
			?prompt " "
			?choices libList
			?callback "fdkFindLibRings()"
		)
		lblRingCells = hiCreateLabel(
			?name 'lblRingCells
			?labelText "Ring Structures"
		)
		cycRingCells = hiCreateCyclicField(
			?name 'cycRingCells
			?prompt " "
			?choices defRingCells
		)
		lblBufferSpcX = hiCreateLabel(
			?name 'lblBufferSpcX
			?labelText "X Buffer Space (um)"
		)
		strBufferSpcX = hiCreateStringField(
			?name 'strBufferSpcX
			?defValue "0"
		)
		lblBufferSpcY = hiCreateLabel(
			?name 'lblBufferSpcY
			?labelText "Y Buffer Space (um)"
		)
		strBufferSpcY = hiCreateStringField(
			?name 'strBufferSpcY
			?defValue "0"
		)
		lblInstName = hiCreateLabel(
			?name 'lblInstName
			?labelText "Instance Name (Optional)"
		)
		strInstName = hiCreateStringField(
			?name 'strInstName
			?defValue ""
		)

		if(!boundp('ringStructureForm) || !hiIsFormDisplayed(ringStructureForm) then
			hiCreateAppForm(
				?name 'ringStructureForm
				?fields list(
							list(lblLibrary 0:0 lblWidth:fldHeight)
							list(cycLibrary fldX:0 200:fldHeight 0)
							list(lblRingCells 0:40 lblWidth:fldHeight)
							list(cycRingCells fldX:40 200:fldHeight 0)
							list(lblBufferSpcX 0:80 lblWidth:fldHeight)
							list(strBufferSpcX fldX:80 200:fldHeight)
							list(lblBufferSpcY 0:120 lblWidth:fldHeight)
							list(strBufferSpcY fldX:120 200:fldHeight)
							list(lblInstName 0:160 lblWidth:fldHeight)
							list(strInstName fldX:160 200:fldHeight)
						)	
				?buttonLayout list('Empty
								list(concat("Add Ring") 'fdkGenRing)
								list(concat("Close") 'hiFormClose))
				?formTitle "Generate Ring Structure"
				?initialSize t
			)

			hiDisplayForm(ringStructureForm)
			putprop('ringStructureForm 'ringStructureHelp 'hiHelpAction)
		)
	)

	t
)

procedure(ringStructureHelp(objType objName objDetail moreDetail)
	let(
		(
		)
		printf("Ring Structure Generator Macro Help\n")
		printf("===================================\n")
		printf("Description:\n")
		printf("  This macro provides the user with the ability to place supported\n")
		printf("  ring structures around selected devices in the current cellview.\n")
		printf("  Supported cellviews are determined based upon the contents of the \n")
		printf("  property bag.\n")
		printf("Inputs:\n")
		printf("  srcLibs - list of library names from which supported cells should be searched\n")
		printf("Notes:\n")
		printf("  * The libraries available in the Source Library cyclic are based upon\n")
		printf("    the value of the srcLibs input variable.\n")
		printf("  * The cells avaialble in the Ring Structures cyclic are based upon the\n")
		printf("    property bag contents of the cells in the chosen library.\n")
		printf("  * The buffer space fields are used for adding additional space between the\n")
		printf("    selected cells and the chosen ring structure. The space will be evenly\n")
		printf("    distributed so that the selected cells are centered in the ring structure.\n")
		printf("  * The instance name is an optional parameter. If not specified, a suitable name\n")
		printf("    will be created based upon the existing instance names in the active cellview.\n")

		t
	)
)

procedure(fdkFindLibRings()
	let(
		(
			selectedLib ringCells
		)

		selectedLib = ringStructureForm->cycLibrary->value
		ringCells = fdkFindLibRingsBase(selectedLib)
		when(!ringCells
			ringCells = list("* No Supported Structures *")
		)
		ringCells = sort(ringCells nil)
		ringStructureForm->cycRingCells->choices = ringCells
	)
)

procedure(fdkFindLibRingsBase(lib)
	let(
		(
			libId cellList cellId cellProp
		)

		libId = ddGetObj(lib)
		cellList = list()
		when(libId
			foreach(cell libId~>cells
				;; iterate over each cell in current library and add cell to list
				;; if the macroRules property exists in the propBag
				cellId = ddGetObj(lib cell~>name)
				cellProp = fdkGetPropTable(cellId ?name "macroRules" ?string t)
				when(cellProp && cellProp["xDimParam"] && cellProp["yDimParam"]
					cellList = append(cellList list(cell~>name))
				)
			)
		)

		cellList
	)
)

procedure(fdkGenRing(form)
	let(
		(
			spcX spcY (validForm t) (instName nil)
		)

		;; validate form entries are valid
		spcX = cdfParseFloatString(strBufferSpcX->value)
		spcY = cdfParseFloatString(strBufferSpcY->value)

		unless(floatp(spcX) && floatp(spcY)
			error("Buffer spaces must be numeric values")
			validForm = nil
		)

		when(validForm
			when(form->strInstName->value != ""
				instName = ringStructureForm->strInstName->value	
			)
			fdkGenRingStructure(
				form->cycLibrary->value
				form->cycRingCells->value
				?bufferSpcX spcX
				?bufferSpcY spcY
				?instName instName
			)
		)
	)
)

procedure(fdkGenRingStructure(libName cellName 
			@key (bufferSpcX 0) (bufferSpcY 0) (instName nil))
	let(
		(
			cv ddId objects firstObj minX maxX minY maxY xDim yDim ringObj
			minXValue minYValue xDimParam yDimParam xDimBufferProp yDimBufferProp
			maxXValue maxYValue minXProp maxXProp minYProp maxYProp
			xDimFormula yDimFormula xDimValue yDimValue
			xDimOffsetProp yDimOffsetProp xBuffer yBuffer
			instNames lastInstNum llX llY urX urY xOffset yOffset
		)

		;; get current cellview
		unless(cv = geGetEditCellView()
			error("No cellview is active!")
		)

		;; get ddId for ring object
		ddId = ddGetObj(libName cellName)
		ringObj = dbOpenCellViewByType(libName cellName "layout")

		when(cv
			;; get selected components in cellview
			objects = geGetSelectedSet(cv)
			if(objects then
				;; initialize min/max values based upon first element in list
				firstObj = car(objects)
				minX = caar(firstObj~>bBox)
				maxX = caadr(firstObj~>bBox)
				minY = cadar(firstObj~>bBox)
				maxY = cadadr(firstObj~>bBox)

				;; determine bounding box of selected components
				foreach(elem objects
					;; get current element's x and y coordinates
					llX = caar(elem~>bBox)	
					urX = caadr(elem~>bBox)	
					llY = cadar(elem~>bBox)	
					urY = cadadr(elem~>bBox)	

					when(llX < minX
						minX = llX
					)	
					when(urX > maxX
						maxX = urX
					)	
					when(llY < minY
						minY = llY
					)	
					when(urY > maxY
						maxY = urY
					)	
				)

				xDimBufferProp = fdkGetProp(ddId "macroRules:xDimBuffer" ?string t)
				yDimBufferProp = fdkGetProp(ddId "macroRules:yDimBuffer" ?string t)
				xDimOffsetProp = fdkGetProp(ddId "macroRules:offsetX" ?string t)
				yDimOffsetProp = fdkGetProp(ddId "macroRules:offsetY" ?string t)

				xBuffer = fdkSubValueForVariable(xDimBufferProp ddId)
				yBuffer = fdkSubValueForVariable(yDimBufferProp ddId)
				xOffset = fdkSubValueForVariable(xDimOffsetProp ddId)
				yOffset = fdkSubValueForVariable(yDimOffsetProp ddId)

				;; determine the total size that encompasses all selected components
				xDim = maxX - minX + 2 * (xBuffer + bufferSpcX) 
				yDim = maxY - minY + 2 * (yBuffer + bufferSpcY)

				;; retrieve minimum value of x and y dimensions
				minXProp = fdkGetProp(ddId "macroRules:minXProp" ?string t)
				maxXProp = fdkGetProp(ddId "macroRules:maxXProp" ?string t)
				minYProp = fdkGetProp(ddId "macroRules:minYProp" ?string t)
				maxYProp = fdkGetProp(ddId "macroRules:maxYProp" ?string t)
				minXValue = fdkGetProp(ddId minXProp)
				maxXValue = fdkGetProp(ddId maxXProp)
				minYValue = fdkGetProp(ddId minYProp)
				maxYValue = fdkGetProp(ddId maxYProp)

				;; evaluate the formulas for x and y dimension values
				xDimFormula = fdkGetProp(ddId "macroRules:xDimFormula" ?string t)
				yDimFormula = fdkGetProp(ddId "macroRules:yDimFormula" ?string t)
				xDimValue = fdkGenRingParamValue(xDimFormula xDim ddId)
				yDimValue = fdkGenRingParamValue(yDimFormula yDim ddId)

				when(xDimValue < minXValue
					xDimValue = minXValue
				)
				when(yDimValue < minYValue
					yDimValue = minYValue
				)
				when(xDimValue > maxXValue
					xDimValue = maxXValue
				)
				when(yDimValue > maxYValue
					yDimValue = maxYValue
				)

				;; temporary solution to fdkPcStringToMicrons anomaly
				if(xDimValue < 1  then
					xDimValue = sprintf(nil "%Lu" xDimValue / 1e-6)
				else
					xDimValue = sprintf(nil "%L" xDimValue)
				)
				if(yDimValue < 1 then
					yDimValue = sprintf(nil "%Lu" yDimValue / 1e-6)
				else
					yDimValue = sprintf(nil "%L" yDimValue)
				)

				xDimParam = fdkGetProp(ddId "macroRules:xDimParam" ?string t)
				yDimParam = fdkGetProp(ddId "macroRules:yDimParam" ?string t)

				;; if the instance name is not specified, determine it based upon
				;; existing cellview instances
				when(!instName
					instNames = sort(cv~>instances~>name
						lambda((x y) alphaNumCmp(x y) == -1))
					lastInstNum = atoi(car(parseString(car(reverse(instNames)) "I")))
					instName = sprintf(nil "I%d" lastInstNum + 1)
				)

				dbCreateParamInst(
					cv ringObj instName minX-xOffset-xBuffer-bufferSpcX:minY-yOffset-yBuffer-bufferSpcY "R0" 1
					list(				
						list(xDimParam "string" xDimValue)
						list(yDimParam "string" yDimValue)
						
					)
				)
			else
				error("No objects have been selected in the active cellview!")
			)
		)
	)
)

procedure(fdkGenRingParamValue(formula value ddId)
	let(
		(
			modFormula finalValue
		)

		;; substitute value into formula
		rexCompile("X")
		modFormula = rexReplace(formula sprintf(nil "%L" value) 0)
		finalValue = fdkSubValueForVariable(modFormula ddId)
		
		finalValue
	)
)

procedure(fdkSubValueForVariable(formula ddId)
	let(
		(
			parsedFormula (startIndex 0) subTable index finalFormula subList
		)
		
		subTable = makeTable('subTable nil)
		parsedFormula = parseString(formula "[]")
		if(car(parseString(formula "")) != "[" then
			startIndex = startIndex + 1
		)

		subList = list()
		index = startIndex
		while(index < length(parsedFormula)
			subList = append(subList list(nth(index parsedFormula)))
			index = index + 2
		)

		foreach(elem subList
			when(!subTable[elem]
				subTable[elem] = sprintf(nil "%L" fdkGetProp(ddId elem ?meters nil))
			)
		)

		;; replace all bracketed elements in formula with value
		finalFormula = formula
		foreach(elem subList
			rexCompile(elem)
			finalFormula = rexReplace(finalFormula subTable[elem] 0)
		)
		rexCompile("\\[")
		finalFormula = rexReplace(finalFormula "" 0)
		rexCompile("\\]")
		finalFormula = rexReplace(finalFormula "" 0)

		evalstring(finalFormula)
	)
)


