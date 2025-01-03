/*************************************************************************************
*																					 *
*	Name:	fdkUpPlaceArrayRows													 	 *
*	Inputs:																			 *
*		- cvId: cellview ID where the array rows will be placed (usually pcCellView) *
*		- propTable: table of data required by UP code to construct array			 *
*		- rows: number of array rows to be placed (represents core elements)		 *
*		- cols: number of array columns to be placed (representes core elements)	 *
* 		- topRow: name of row definition representing top row of array				 *
*		- botRow: name of row definition representing bottom row of array			 *
*		- rowRepeatList: list of row definitions representing the requested repeat	 *
*			pattern in the array (rows repeat from top to bottom)					 *
*		- constName: name of propBag property holding all constant values			 *
*		- defName: name of propBag property holding all default values				 *
*		- rowDefName: name of propBag property holding all row definitions			 *
*		- connectName: name of propBag property holding all pin name mappings		 *
*		- origX: initial X coordinate of the first instance placed by the UP code	 *
*		- origY: initial Y coordinate of the first instance placed by the UP code	 *
*		- propagatePins: boolean flag used to enable/disable propagation of pins	 *
*			in the UP code															 *
*		- mosaics: flag used to determine whether mosaic placement or individual	 *
*			instance placement is used (defaults to mosaics - faster)				 *
*		- dontDraw: comma separated list with valid values of top, bottom, left,	 *
*			and right (used to remove drawing of periphery cells on given sides		 *
*	Outputs:																		 *
*		- None																		 *
*																					 *	
*	Tag: _A_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpPlaceArrayRows(cvId propTable rows cols topRow botRow rowRepeatList 
			@key (constName "constDef") (defName "defaults") (rowDefName "rowDef")
			(connectName "connectivity") (origX 0.0) (origY 0.0) (propagatePins nil)
			(mosaics t) (dontDraw "") (mosaicPrefix "") (paramTable nil))
	let(
		(
			constants defaults   
			rowDefs botRowDef topRowDef currX currY
			botRowInfo botCols topRowInfo topCols repeatList repeatInfoList
			repeatRowLength currRowLength currRowInfo
			currRepeatIndex currRepeatRowInfo 
			currRepeatRowParsed currRowDef
			rowNum rowCount connect instTable
			emptyRowDef botRowElem topRowElem repeatRowCache 
			currRowName repeatRowElem repeatInstTable mosaicsTableStart mosaicsTableRepeat
			mosaicsTableEnd bottomInstTable topInstTable mosaicsBotStart mosaicsBotRepeat
			mosaicsBotEnd mosaicsTopStart mosaicsTopRepeat dontDrawList
		)

        ;; fdkUpCellDim is a global cell dimensions table
		fdkUpCellDim = makeTable('fdkUpCellDim nil)

		rowDefs = propTable[rowDefName]
		constants = propTable[constName]
		defaults = propTable[defName]
		if(propagatePins then
			connect = propTable[connectName]
		else
			connect = nil
		)
		repeatRowCache = makeTable('rowCache nil)
		emptyRowDef = makeTable('emptyRow nil)
		emptyRowDef["start"] = nil
		emptyRowDef["repeat"] = nil
		emptyRowDef["end"] = nil

		if(!botRow || !parseString(botRow) then
			botRowDef = emptyRowDef
		else
			botRowDef = rowDefs[botRow]
		)
		if(!topRow || !parseString(topRow) then
			topRowDef = emptyRowDef
		else
			topRowDef = rowDefs[topRow]
		)

		;; rowRepeatList parameter is defined as a comma separated string that
		;; needs to be formed into a SKILL list for processing
		repeatList = parseString(rowRepeatList ",")
		if(dontDraw != "" then
			dontDrawList = mapcar('lowerCase parseString(dontDraw ","))
		else
			dontDrawList = list()
		)

        ;get top and bottom row info to get empty core cell info
		botRowInfo = fdkUpFlattenRow(botRowDef constants defaults dontDrawList "bottom")
		topRowInfo = fdkUpFlattenRow(topRowDef constants defaults dontDrawList "top")
        coreCellInfo = fdkUpGetEmptyCoreCellInfo(botRowInfo topRowInfo)

		;; determine the overall length of the longest repeat list row
		;; so the correct number of cells are placed in top and bottom row
		repeatRowLength = 0.0
		repeatInfoList = list()
		foreach(repeatRow repeatList
            ;prevents errors from bad configuration
            ;NOTE--this does not appear to be as helpful as just eliminating the space in the property bag
            repeatRow=fdkStringExternalSpacePurge(repeatRow)
			currRepeatRowParsed = parseString(repeatRow ":")
			if(length(currRepeatRowParsed) == 2 then
				currRowDef = repeatRow
			else
				currRowDef = rowDefs[repeatRow]
			)
			currRowInfo = fdkUpFlattenRow(currRowDef constants defaults dontDrawList "repeat" ?coreCellInfo coreCellInfo) 
			repeatInfoList = append(repeatInfoList list(currRowInfo))
			currRowLength = fdkUpCalcRepeatRowLength(currRowInfo cols)
			repeatRowLength = max(repeatRowLength currRowLength)
            ;the repeatRowLength usage is dubious and may only apply for non-mosaics
		)

		;; retrieve information on top and bottom rows for calculating number of required
		;; repeat columns
		if(botRowInfo["repeat"]["elem"] then
			botCols = fdkUpCalcRepeatCols(botRowInfo repeatRowLength)
		else
			botCols = 0
		)
		if(topRowInfo["repeat"]["elem"] then
			topCols = fdkUpCalcRepeatCols(topRowInfo repeatRowLength)
		else
			topCols = 0
		)

        ;fprintf(stderr "create tables and then mosaics\n")
        ;;mosaics pretty much ignores everything from before except coreCellInfo and
        ;;fdkUpCellDim
		if(mosaics then
            ;fprintf(stderr "create row repeat tables\n")
			bottomInstTable = fdkUpCreateRowRepeatTable(propTable botRow dontDrawList "bottom")
			topInstTable = fdkUpCreateRowRepeatTable(propTable topRow dontDrawList "top")
			repeatInstTable = fdkUpCreateRowRepeatTable(propTable rowRepeatList dontDrawList "repeat" ?coreCellInfo coreCellInfo)

            ;fprintf(stderr "create Mosaics\n")
			currX = origX
			currY = origY
			mosaicsBotStart = fdkUpCreateMosaics(cvId 1 1 bottomInstTable "start" currX currY mosaicPrefix)
			currX = mosaicsBotStart["right"]
			mosaicsBotRepeat = fdkUpCreateMosaics(cvId 1 botCols bottomInstTable "repeat" currX currY mosaicPrefix)
			currX = mosaicsBotRepeat["right"]
			mosaicsBotEnd = fdkUpCreateMosaics(cvId 1 1 bottomInstTable "end" currX currY mosaicPrefix)
			if(mosaicsBotStart["mosaics"] then
				currY = mosaicsBotStart["top"]

			)
			if(mosaicsBotRepeat["mosaics"] then
				currY = max(currY mosaicsBotRepeat["top"])
			)
			if(mosaicsBotEnd["mosaics"] then
				currY = max(currY mosaicsBotEnd["top"])
			)

			currX = origX 
			mosaicsTableStart = fdkUpCreateMosaics(cvId rows 1 repeatInstTable "start" currX currY mosaicPrefix)
			currX = mosaicsTableStart["right"]
			mosaicsTableRepeat = fdkUpCreateMosaics(cvId rows cols repeatInstTable "repeat" currX currY mosaicPrefix)
			currX = mosaicsTableRepeat["right"]
			mosaicsTableEnd = fdkUpCreateMosaics(cvId rows 1 repeatInstTable "end" currX currY mosaicPrefix)
			currY = max(max(mosaicsTableStart["top"] mosaicsTableRepeat["top"]) mosaicsTableEnd["top"])

			currX = origX
			mosaicsTopStart = fdkUpCreateMosaics(cvId 1 1 topInstTable "start" currX currY mosaicPrefix)
			currX = mosaicsTopStart["right"]
			mosaicsTopRepeat = fdkUpCreateMosaics(cvId 1 topCols topInstTable "repeat" currX currY mosaicPrefix)
			currX = mosaicsTopRepeat["right"]
			fdkUpCreateMosaics(cvId 1 1 topInstTable "end" currX currY mosaicPrefix)
		else
			currX = origX
			currY = origY

            ;fprintf(stderr "compute single row and then place  for bottom\n")
			;; place bottom row
			botRowElem = fdkUpComputeSingleRow(botRowInfo botCols)
			fdkUpPlaceSingleRow(cvId botRowElem 0 currX currY connect)
			when(botRowElem
				currY = currY + botRowInfo["height"]
			)

            ;fprintf(stderr "compute single row and then place  for repeat\n")
			;; place repeat row structures
			rowNum = 1
			rowCount = 0
			while(repeatList && rowCount < rows
				currRepeatIndex = mod(rowNum-1 length(repeatList))
				currRepeatRowInfo = nth(currRepeatIndex repeatInfoList)
				when(currRepeatRowInfo["start"]["elem"] ||
						currRepeatRowInfo["repeat"]["elem"] ||
						currRepeatRowInfo["end"]["elem"] 
					currRowName = nth(currRepeatIndex repeatList)
					if(!repeatRowCache[currRowName] then
                        ;fprintf(stderr "--computing single row %d\n" rowCount)
						repeatRowCache[currRowName] = fdkUpComputeSingleRow(currRepeatRowInfo cols)
					)
					repeatRowElem = repeatRowCache[currRowName]
                    ;fprintf(stderr "--placing single row %d\n" rowCount)
					fdkUpPlaceSingleRow(cvId repeatRowElem rowNum currX currY connect)
					rowCount = rowCount + 1
				)
				currY = currY + currRepeatRowInfo["height"]
				rowNum = rowNum + 1
			)

            ;fprintf(stderr "compute single row and then place  for top\n")
			;; place top row
			topRowElem = fdkUpComputeSingleRow(topRowInfo topCols)
			fdkUpPlaceSingleRow(cvId topRowElem rowNum currX currY connect)
		)

		fdkUpCellDim = 'unbound

		;; build return value
		instTable = makeTable('instTable nil)
		instTable["origin"] = list(origX origY)
		instTable["rows"] = rows
		instTable["cols"] = cols
		instTable["topRowInfo"] = topRowInfo
		instTable["botRowInfo"] = botRowInfo
		instTable["repeatRowInfo"] = repeatInfoList

		;; propagate pins on mosaics if enabled
		when(connect && mosaics
			fdkUpPropagateMosaicPins(instTable cvId connect dontDrawList)
		)

		instTable
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpBuildReturnTable													 *
*	Inputs:																			 *
*		- cvId: cellview ID for which the return table is being constructed			 *
*		- rowNum: number of rows in the array structure being processed				 *
*	Outputs:																		 *
*		- instTable: table of instances that are binned by row, section, and group	 *
*																					 *
*	Tag: _B_																		 *
*   This is probably unused code and should be checked for this and removed:bvc      *
*************************************************************************************/

procedure(fdkUpBuildReturnTable(cvId rowNum)
	let(
		(
			instNames instTable rowName rowPrefix rowElems sectionElems
			parsedInstName groupNums currGroupNum currShapeNum groupNumsList
			sortedShapeNumList currShapeList currInstName
		)

		;; retrieve all instances created to return to calling function
		instNames = cvId~>instances~>name
		instTable = makeTable('upInstTable nil)
		for(row 0 rowNum
			;; get all elements in current row
			rowName = sprintf(nil "row%d" row)
			rowPrefix = sprintf(nil "%s_" rowName)
			rowElems = setof(elem instNames index(elem rowPrefix))
			instTable[rowName] = makeTable(concat(rowName) nil)
			
			;; find start, repeat, and end elements in current row
			sectionElems = makeTable('sectionElems nil)
			sectionElems["start"] = setof(elem rowElems index(elem "_start_"))
			sectionElems["repeat"] = setof(elem rowElems index(elem "_repeat_"))
			sectionElems["end"] = setof(elem rowElems index(elem "_end_"))

			;; iterate over each section's elements and divide into groups
			foreach(section list("start" "repeat" "end")
				instTable[rowName][section] = makeTable(concat(section) nil)
				foreach(elem sectionElems[section]
					parsedInstName = parseString(elem "_")
					groupNums = makeTable('groupNums nil)
					currGroupNum = atoi(nth(2 parsedInstName))
					currShapeNum = atoi(nth(3 parsedInstName))
					if(!groupNums[currGroupNum] then
						groupNums[currGroupNum] = list(currShapeNum)
					else
						groupNums[currGroupNum] = append(groupNums[currGroupNum] list(currShapeNum))
					)

					;; at this point, all the shape numbers for a particular row/
					;; section/group are stored in a list so sort the shape numbers in
					;; numeric order and replace the shape numbers with the actual instances
					groupNumsList = tableToList(groupNums)
					foreach(groupElem groupNumsList
						currGroupNum = car(groupElem)
						sortedShapeNumList = sort(cadr(groupElem) 'lessp)
						currShapeList = list()
						foreach(shapeNum sortedShapeNumList
							currInstName = sprintf(nil "%s_%s_%d_%d" rowName section currGroupNum shapeNum)
							currShapeList = append(currShapeList list(dbGetInstByName(cvId currInstName)))
						)
						instTable[rowName][section][currGroupNum] = currShapeList
					)
				)
			)
		)

		instTable
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpCalcRepeatCols														 *
*	Inputs:																			 *
*		- rowInfo: the current row being analyzed for the number of required repeat	 *
*			columns																	 *
*		- repeatLength: the length of the repeat row structure that the current row  *
*			needs to conform to														 *
*	Outputs:																		 *
*		- numCols: total number of columns necessary to create alignment between 	 *
*			current row and repeat row structure									 *
*																					 *
*	Tag: _C_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpCalcRepeatCols(rowInfo repeatLength)
	let(
		(
			remainLength (numCols 0) repeatPieces currIndex currElem pieceLength
			numRepeatPieces
		)

		;; based upon the overall available repeat length passed into the function, 
		;; determine how much space is left for placing repeat patterns by
		;; subtracting off the start and end sections for the given row specification
		remainLength = repeatLength - rowInfo["start"]["length"] - rowInfo["end"]["length"]

		;; while there is still space available, continue to place the next repeat
		;; element specified as a part of the row specification in the repeatPieces
		;; variable
		repeatPieces = rowInfo["repeat"]["elem"]
		numRepeatPieces = length(repeatPieces)
		while(fdkCmp(remainLength ">" 0)

			;; retrieve the current repeat element to place from repeatPieces
			currIndex = mod(numCols numRepeatPieces)
			currElem = nth(currIndex repeatPieces)

			;; iterate over each piece of the current element to determine the overall
			;; length (it may be a stacked element list which needs to be processed
			;; differently)
			pieceLength = 0
			foreach(piece currElem

				;; if this is a list, that means we are dealing with a stack element,
				;; otherwise we are dealing with a simple flat element
				;; and we need to determine the length of each element based upon its
				;; starting coordinate and add it to the running total
				if(listp(piece) then
					foreach(stackPiece piece
						pieceLength = max(pieceLength stackPiece["x"]+stackPiece["length"])
					)
				else
					pieceLength = max(pieceLength piece["x"]+piece["length"])
				)
			)

			;; subtract off the current element's calculated length and increase the
			;; index value so that the next element in the repeatPieces can be 
			;; properly retrieved
			remainLength = remainLength - pieceLength
			if(fdkCmp(remainLength ">=" 0) then
				numCols = numCols + 1
			)
		)

		numCols
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpCalcRepeatRowLength												 *
*	Inputs:																			 *
*		- rowInfo: information from row in rowRepeatList that is being operated on	 *
*			to determine the row length												 *
*		- cols: number of repeat columns required for the specified row definition 	 *
*			used in calculcating the total row length (start + repeate + end)		 *
*	Outputs:																		 *
*		- rowLength: total length of the row being operated on						 *
*																					 *
*	Tag: _D_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpCalcRepeatRowLength(rowInfo cols)
	let(
		(
			rowLength repeatPieces repeatPiecesLength currIndex currElem
			pieceLength
		)

		;; initialize row length by adding the start and end length together
		rowLength = rowInfo["start"]["length"] + rowInfo["end"]["length"]
        ;fprintf(stderr "repeat row length initial rowLength=%L\n" rowLength)

		;; iterate over repeat list for the number of columns specified
		repeatPieces = rowInfo["repeat"]["elem"]
		repeatPiecesLength = length(repeatPieces)
		if(repeatPiecesLength > 0 then
			for(column 0 cols-1
				;; determine which element in repeatPieces represents the next element
				;; placed based upon the column number
				currIndex = mod(column repeatPiecesLength)
				currElem = nth(currIndex repeatPieces)	

				;; iterate over each piece of the current element to determine the overall
				;; length
				columnLength = 0
                pieceNumber = 0
                ; calculate column length (deltax) considering offsets
				foreach(piece currElem
					;; if this is a list, that means we are dealing with a stack element
                    pieceLength = 0
					if(listp(piece) then
						foreach(stackPiece piece
                            pieceNumber = pieceNumber + 1
                            ;fprintf(stderr "stackpiece table:\n")
                            ;fdkPrintTable(stackPiece)
                            sPLength = stackPiece["x"]+stackPiece["length"]
                            ;only consider offset in overall length if more than one piece
                            if(pieceNumber>1 then
                                if(stackPiece["modifiers"] then
                                    if(stackPiece["modifiers"]["offsetX"] then
                                        sPOffsetXString=stackPiece["modifiers"]["offsetX"]
				                        sPOffsetX = cdfParseFloatString(sPOffsetXString)/1e-6
                                        sPLength = sPLength + sPOffsetX
                                    )
                                )
                            )
							pieceLength = max(pieceLength sPLength)
						)
					else
                        pieceNumber = pieceNumber + 1
                        pLength=piece["length"]
                        ;fprintf(stderr "piece %L x=%L length=%L original pLength=%L\n" pieceNumber piece["x"] piece["length"] pLength)
                        ;only consider offset in overall length if more than one piece
                        if(pieceNumber>1 then
                            ;fprintf(stderr "pieceNumber=%L\n" pieceNumber)
                            if(piece["modifiers"] then
                                if(piece["modifiers"]["offsetX"] then
                                    pOffsetXString=piece["modifiers"]["offsetX"]
                                    pOffsetX = cdfParseFloatString(pOffsetXString)/1e-6
                                    ;fprintf(stderr "pOffsetX=%L\n" pOffsetX)
                                    pLength = pLength + pOffsetX
                                    ;fprintf(stderr "resulting pLength=%L\n" pLength)
                                )
                            )
                        )
						;pieceLength = max(pieceLength pLength)
                        pieceLength = pLength + pieceLength
                        ;fprintf(stderr "piece table:\n")
                        ;fdkPrintTable(piece)
					)
                    ;fprintf(stderr ">>>piece from column %L length=%L\n" column pieceLength)
                    columnLength = columnLength + pieceLength
				)
                ;fprintf(stderr "repeat column %L width=%L\n" column columnLength)
				rowLength = rowLength + columnLength
			)
		)

		rowLength
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpBuildParamList														 *
*	Inputs:																			 *
*		- paramTable: the table of parameters on the element of an array			 *
*	Outputs:																		 *
*		- paramList: list of parameters for a given array element in the format		 *
*			necessary for passing as a value to pcDefinePCell						 *
*																					 *
*	Tag: _E_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpBuildParamList(paramTable)
	let(
		(
			paramList paramType
		)

		paramList = list()

		foreach(param paramTable["sortedKeys"]
			if(booleanp(paramTable[param]) then
				paramType = "boolean"
			else
				paramType = "string"
			)
			paramList = append1(paramList list(param paramType paramTable[param]))
		)

		paramList
	)	
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpPropagatePins														 *
*	Inputs:																			 *
*		- instId: single element of the array structure that is required to have its *
*			pins propagated to the top level										 *
*		- connect: table representing the pin mapping required from the pin name on  *
*			the instance to the pin name at the top level of the array structure	 *
*	Outputs:																		 *
*		- None (Pin data is created in OA data structure for each required shape	 *
*																					 *
*	Tag: _F_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpPropagatePins(instId connect)
	let(
		(
			libName cellName viewName master myPinMap netName net index
			newPinFig newPin accessDir pinMap
		)

		libName = instId~>libName
		cellName = instId~>cellName
		viewName = instId~>viewName
		master = dbOpenCellViewByType(libName cellName viewName)
		pinMap = connect[libName][cellName]["pinMap"]
		foreach(terminal master~>terminals
			myPinMap = car(exists(key pinMap (car(key) == terminal~>net~>name)))
			when(myPinMap
				netName = cadr(myPinMap)
				net = dbFindNetByName(pcCellView netName)
				if(!net then
					net = dbCreateNet(pcCellView netName)
				)
				if(!dbFindNetByName(pcCellView netName) then
					dbCreateTerm(net net~>name terminal~>direction)
					dbCreateInstTerm(net instId terminal)
				)

				;; loop through all the pins on the terminal
				foreach(pin terminal~>pins
					;; loop through all figures on pin and duplicate figure
					;; 'index' tracks the first instance of a pin
					;; the first pinFig is attached using the dbCreatePin
					;; other pinFigs are added using dbAddFigToPin
					index = 0
					foreach(pinFig pin~>figs
						newPinFig = dbCopyFig(
							pinFig pcCellView instId~>transform
						)
						if(index == 0 then 
							newPin = dbCreatePin(net newPinFig)
							dbSetPinFigName(newPinFig pin~>name)
						else
							dbAddFigToPin(newPin newPinFig)
						)
						
						;; copy pin access direction
						accessDir = dbGetPinFigAccessDirection(pinFig)
						dbSetPinFigAccessDirection(newPinFig accessDir)
						index = index + 1
					)
				)
			)
		)
		
		t
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpComputeSingleRow													 *
*	Inputs:																			 *
*		- rowInfo: information for the start, repeat, and end data for the row		 *
*			being operated upon														 *
* 		- cols: number of repeat columns required for the given row placement		 *
*	Outputs:																		 *
*		- elemList: list of tables that represent the array elements that comprise	 *
*			the given row															 *
*																					 *
*	Tag: _G_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpComputeSingleRow(rowInfo cols)
	let(
		(
			repeatCounter counter libName cellName viewName
			orientTable offsetX offsetY currRepeatIndex repeatElem
			currRepeatPiece paramList repeatMinX repeatMaxX
			cvString elemList currElemTable
			currX currY
		)

		elemList = list()
		currX = 0
		currY = 0
		counter = 0
		foreach(arrayElem rowInfo["start"]["elem"]
			currElemTable = makeTable('currElem nil)
			paramList = list()
			libName = arrayElem["libName"]
			cellName = arrayElem["cellName"]
			viewName = arrayElem["viewName"]
            ;fprintf(stderr "fdkUpComputeSingleRow--start\n")
            ;fdkPrintTable(arrayElem)
			cvString = sprintf(nil "%s:%s:%s" libName cellName viewName)
			orientTable = fdkUpProcessOrientModifiers(arrayElem
				arrayElem["modifiers"]["mirror"] arrayElem["modifiers"]["rotate"])
			offsetX = arrayElem["modifiers"]["offsetX"]
			offsetY = arrayElem["modifiers"]["offsetY"]
			if(offsetX then
                ;fprintf(stderr "cell:%s has offsetX=%L\n" cellName offsetX)
				offsetX = cdfParseFloatString(offsetX) / 1e-6
                ;fprintf(stderr "cell:%s has new offsetX=%L\n" cellName offsetX)
			else
				offsetX = 0
			)
			if(offsetY then
				offsetY = cdfParseFloatString(offsetY) / 1e-6
			else
				offsetY = 0
			)

			;; if array element has a param modifier, then build a parameter list to 
			;; pass to dbCreateParamInst
			if(arrayElem["modifiers"]["param"] then
				paramList = fdkUpBuildParamList(arrayElem["modifiers"]["param"])
			)
			counter = counter + 1
			
			;; add current element to elemList
			currElemTable["cvString"] = cvString
			currElemTable["instName"] = sprintf(nil "start_0_%d" counter) 
			currElemTable["xPos"] = currX+arrayElem["x"]+orientTable["offsetX"]+offsetX
			currElemTable["yPos"] = currY+arrayElem["y"]+orientTable["offsetY"]+offsetY
            currElemTable["xOffset"] = arrayElem["xOffset"]
            currElemTable["yOffset"] = arrayElem["yOffset"]
            ;fprintf(stderr "currElemTable xoffset=%L yoffset=%L\n" currElemTable["xOffset"] currElemTable["yOffset"])
			currElemTable["orientParam"] = orientTable["orientParam"]
			currElemTable["paramList"] = paramList
			elemList = append(elemList list(currElemTable))
		)
        ;fprintf(stderr "finished with start\n")
		when(rowInfo["start"]["elem"]
			currX = currX + rowInfo["start"]["length"]
		)

		counter = 0
		while(counter < cols
			repeatCounter = 0
			currRepeatIndex = mod(counter length(rowInfo["repeat"]["elem"]))
			repeatElem = nth(currRepeatIndex rowInfo["repeat"]["elem"])
			repeatMinX = repeatMaxX = nil
            ;fprintf(stderr "fdkUpComputeSingleRow--repeat\n")
			foreach(arrayElem repeatElem
                ;fprintf(stderr " HERE is the array element...\n")
                ;fdkPrintTable(arrayElem)
				currElemTable = makeTable('currElem nil)
				paramList = list()
				if(!repeatMinX then
					repeatMinX = arrayElem["x"]
				)
				if(!repeatMaxX then
					repeatMaxX = arrayElem["x"] + arrayElem["length"]
				)
				currRepeatPiece = arrayElem
				libName = arrayElem["libName"]
				cellName = arrayElem["cellName"]
				viewName = arrayElem["viewName"]
				cvString = sprintf(nil "%s:%s:%s" libName cellName viewName)
                ;fprintf(stderr "  process modifiers\n")
				orientTable = fdkUpProcessOrientModifiers(arrayElem
					arrayElem["modifiers"]["mirror"] arrayElem["modifiers"]["rotate"])
				offsetX = arrayElem["modifiers"]["offsetX"]
				offsetY = arrayElem["modifiers"]["offsetY"]
				if(offsetX then
                    ;fprintf(stderr "--cell:%s has offsetX=%L\n" cellName offsetX)
					offsetX = cdfParseFloatString(offsetX) / 1e-6
                    ;fprintf(stderr "--cell:%s has new offsetX=%L\n" cellName offsetX)
				else
					offsetX = 0
				)
				if(offsetY then
					offsetY = cdfParseFloatString(offsetY) / 1e-6
				else
					offsetY = 0
				)

				;; if array element has a param modifier, then build a parameter list to 
				;; pass to dbCreateParamInst
				if(arrayElem["modifiers"]["param"] then
					paramList = fdkUpBuildParamList(arrayElem["modifiers"]["param"])
				)

				;; add current element to elemList
				currElemTable["cvString"] = cvString
				currElemTable["instName"] = sprintf(nil "repeat_%d_%d" counter repeatCounter) 
				currElemTable["xPos"] = currX+arrayElem["x"]+orientTable["offsetX"]+offsetX
				currElemTable["yPos"] = currY+arrayElem["y"]+orientTable["offsetY"]+offsetY
				currElemTable["orientParam"] = orientTable["orientParam"]
				currElemTable["paramList"] = paramList
                currElemTable["xOffset"] = arrayElem["xOffset"]
                currElemTable["yOffset"] = arrayElem["yOffset"]
				elemList = append(elemList list(currElemTable))

				repeatMinX = min(repeatMinX currRepeatPiece["x"])
                ;similar to mosaics, use rlength if it exists
                ;fprintf(stderr "  deal with length and rlength\n")
                ;fdkPrintTable(currRepeatPiece)
                if(currRepeatPiece["rLength"] then
				    repeatMaxX = max(repeatMaxX currRepeatPiece["x"]+currRepeatPiece["rLength"])
                else
				    repeatMaxX = max(repeatMaxX currRepeatPiece["x"]+currRepeatPiece["length"])
                )
				repeatCounter = repeatCounter + 1
			)
			currX = currX + (repeatMaxX - repeatMinX)
			counter = counter + 1
		)

		counter = 0
        ;fprintf(stderr "fdkUpComputeSingleRow--end\n")
		foreach(arrayElem rowInfo["end"]["elem"]
            ;fdkPrintTable(arrayElem)
			paramList = list()
			currElemTable = makeTable('currElem nil)
			libName = arrayElem["libName"]
			cellName = arrayElem["cellName"]
			viewName = arrayElem["viewName"]
			cvString = sprintf(nil "%s:%s:%s" libName cellName viewName)
			orientTable = fdkUpProcessOrientModifiers(arrayElem
				arrayElem["modifiers"]["mirror"] arrayElem["modifiers"]["rotate"])
			offsetX = arrayElem["modifiers"]["offsetX"]
			offsetY = arrayElem["modifiers"]["offsetY"]
			if(offsetX then
                ;fprintf(stderr "~~cell:%s has offsetX=%L\n" cellName offsetX)
				offsetX = cdfParseFloatString(offsetX) / 1e-6
                ;fprintf(stderr "~~cell:%s has new offsetX=%L\n" cellName offsetX)
			else
				offsetX = 0
			)
			if(offsetY then
				offsetY = cdfParseFloatString(offsetY) / 1e-6
			else
				offsetY = 0
			)

			;; if array element has a param modifier, then build a parameter list to 
			;; pass to dbCreateParamInst
			if(arrayElem["modifiers"]["param"] then
				paramList = fdkUpBuildParamList(arrayElem["modifiers"]["param"])
			)
            counter = counter+1
			
			;; add current element to elemList
			currElemTable["cvString"] = cvString
			currElemTable["instName"] = sprintf(nil "end_0_%d" counter) 
			currElemTable["xPos"] = currX+arrayElem["x"]+orientTable["offsetX"]+offsetX
			currElemTable["yPos"] = currY+arrayElem["y"]+orientTable["offsetY"]+offsetY
			currElemTable["orientParam"] = orientTable["orientParam"]
			currElemTable["paramList"] = paramList
            currElemTable["xOffset"] = arrayElem["xOffset"]
            currElemTable["yOffset"] = arrayElem["yOffset"]
			elemList = append(elemList list(currElemTable))
		)

		elemList
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpPlaceSingleRow													 	 *
*	Inputs:																			 *
*		- cvId: cellview ID where the single array row is being created				 *
*		- elemList: raw flat placement data for each element in the array row		 *
*			relative to (0,0)														 *
*		- rowNum: row number of array row being placed for unique naming purpose	 *
*		- currX: x offset value so that array row is placed in the proper position	 *
*			relative to other rows in the array										 *
*		- currY: y offset value so that array row is placed in the proper position	 *
*			relative to other rows in the array										 *
*		- connect: connectivity information that is used for pin propagation		 *
*	Outputs:																		 *
*		- None																		 *
*																					 *
*	Tag: _H_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpPlaceSingleRow(cvId elemList rowNum currX currY connect)
	let(
		(
			master libName cellName viewName
			instId masterTable cvString cvStringParsed instName
		)

		masterTable = makeTable('masters nil)
		foreach(elem elemList
			cvString = elem["cvString"]
			cvStringParsed = parseString(cvString ":")
			libName = nth(0 cvStringParsed)
			cellName = nth(1 cvStringParsed)
			viewName = nth(2 cvStringParsed)
            
            if(cellName != "!nocore" then

                if(!masterTable[cvString] then
                    masterTable[cvString] = dbOpenCellViewByType(libName cellName viewName)
                )
                master = masterTable[cvString]
                instName = sprintf(nil "row%d_%s" rowNum elem["instName"])
                ;fprintf(stderr "cell %s row %L  instname %s currX %L xPos %L xoff %L yPos %L yoff %L\n" cellName rowNum instName currX elem["xPos"] elem["xOffset"] elem["yPos"] elem["yOffset"])
                ;bvchere--not in python--is it needed?
                xOffset=elem["xOffset"]
                if(elem["orientParam"]=="R180" || elem["orientParam"]=="MY" then
                    xOffset=-xOffset
                )
                yOffset=elem["yOffset"]
                if(elem["orientParam"]=="R180" || elem["orientParam"]=="MX" then
                    yOffset=-yOffset
                )
                ;fprintf(stderr "-d-placesinglerow PLACE cell %s/%s/%s xOff=%L yOff=%L xPos=%L @(%L,%L) paramList=%L\n" libName cellName viewName xOffset yOffset elem["xPos"] currX+elem["xPos"]+xOffset currY+elem["yPos"]+yOffset elem["paramList"])
                ;Place Instance
                instId = dbCreateParamInst(
                    cvId master instName
                    list(
                        currX+elem["xPos"]+xOffset
                        currY+elem["yPos"]+yOffset
                    )
                    elem["orientParam"] 
                    1 
                    elem["paramList"]
                )
                if(connect && 
                    connect[libName] != 'unbound && connect[libName][cellName] != 'unbound then
                    fdkUpPropagatePins(instId connect)
                )

            )
		)

		;; close all masters opened for placement
		foreach(instMaster tableToList(masterTable)
			dbClose(cadr(instMaster))
		)

		t
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpProcessOrientModifiers												 *
*	Inputs:																			 *
*		- element: table containing information on array element that needs to be	 *
*			processed																 *
*		- mirror: value of mirror modifier (x, y, or xy)							 *
*		- rotate: value of rotation modifier (90, 180, or 270)						 *
*	Outputs:																		 *
*		- orientTable: table of data that contains the properly formatted Virtuoso 	 *
*			orientation modifier along with required offset in the x and y direction *
*			for proper placement within the overall array structure					 *
*																					 *
*	Tag: _I_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpProcessOrientModifiers(element mirror rotate)
	let(
		(
			orientTable orientParam offsetX offsetY
			elemL elemH mirrorValue rotateValue dimTable
			libName cellName viewName dimKey paramTable currValue
		)

		libName = element["libName"]
		cellName = element["cellName"]
		viewName = element["viewName"]

		dimKey = sprintf(nil "%s_%s_%s" libName cellName viewName)
		paramTable = element["modifiers"]["param"]
		if(paramTable then
			foreach(param paramTable["sortedKeys"]
				currValue = paramTable[param]
				if(booleanp(currValue) then
					dimKey = strcat(dimKey sprintf(nil "_%s_%L" param currValue))
				else
					dimKey = strcat(dimKey sprintf(nil "_%s_%s" param currValue))
				)
			)
		)
		dimTable = fdkUpCellDim[dimKey]
        ;fprintf(stderr ">>>here is dimTable for %s\n" dimKey)
        ;fdkPrintTable(dimTable)
		
		;; by this point, all cells should have entries in fdkUpCellDim table
		elemL = dimTable["length"]
		elemH = dimTable["height"]
		;offsetX = dimTable["offsetX"]
		;offsetY = dimTable["offsetY"]
        ;basically don't include these values
        offsetX=0.0
        offsetY=0.0

		mirrorValue = mirror || "0"
		rotateValue = rotate || "0"

		;; mirror always occurs before rotation
		;; valid values for mirror are "x", "y", and "xy"
		;; valid values for rotate are "90", "180", and "270" in counter clockwise direction
		case(mirrorValue
			("0"
				case(rotateValue
					("0"
						orientParam = "R0"
					)
					("90"
						orientParam = "R90"
						offsetX = offsetX + elemH
					)
					("180"
						orientParam = "R180"
						offsetX = offsetX + elemL
						offsetY = offsetY + elemH
					)
					("270"
						orientParam = "R270"
						offsetY = offsetY + elemL
					)
				)
			)
			("x"
				case(rotateValue
					("0"
						orientParam = "MX"
						offsetY = offsetY + elemH
					)
					("90"
						orientParam = "MXR90"
					)
					("180"
						orientParam = "MY"
						offsetX = offsetX + elemL
					)
					("270"
						orientParam = "MYR90"
						offsetX = offsetX + elemH
						offsetY = offsetY + elemL
					)
				)
			)
			("y"
				case(rotateValue
					("0"
						orientParam = "MY"
						offsetX = offsetX + elemL
					)
					("90"
						orientParam = "MYR90"
						offsetX = offsetX + elemH
						offsetY = offsetY + elemL
					)
					("180"
						orientParam = "MX"
						offsetY = offsetY + elemH
					)
					("270"
						orientParam = "MXR90"
					)
				)
			)
			("xy"
				case(rotateValue
					("0"
						orientParam = "R180"
						offsetX = offsetX + elemL
						offsetY = offsetY + elemH
					)
					("90"
						orientParam = "R270"
						offsetY = offsetY + elemL
					)
					("180"
						orientParam = "R0"
					)
					("270"
						orientParam = "R90"
						offsetX = offsetX + elemH
					)
				)
			)
		)	

		orientTable = makeTable('orientTable nil)
		orientTable["orientParam"] = orientParam
		orientTable["offsetX"] = offsetX
		orientTable["offsetY"] = offsetY

		orientTable
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpGetEmptyCoreCellInfo												 *
*	Inputs:																			 *
*		- botRowInfo: table containing flattened data for the bottom row
*		- topRowInfo: table containing flattened data for the top Row
*	Outputs:																		 *
*       - coreCellInfo: table of info created from top/bottom row cells to
*           be used as a substitute for a core cell when there is no core cell.
*           This should only be passed in when working on repeat rows, not
*           for top and bottom rows.["height"] {"width"] ["offset"]
*																					 *
*	Tag: _K_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpGetEmptyCoreCellInfo(botRowInfo topRowInfo)
	let(
		(
            topRepeatLength
            botRepeatLength
            coreCellInfo
		)

		coreCellInfo = makeTable('coreCellInfo nil)
        ;following to get more info about these tables
        ;fdkPrintTable(botRowInfo)
        ;fdkPrintTable(topRowInfo)
        ;extract potential empty core cell info
        topRepeatLength=0.0
        if(topRowInfo["repeat"]["length"] then
            topRepeatLength=topRowInfo["repeat"]["length"]
        )
        botRepeatLength=0.0
        if(botRowInfo["repeat"]["length"] then
            botRepeatLength=botRowInfo["repeat"]["length"]
        )
        coreCellInfo["length"]=max(topRepeatLength botRepeatLength)
        ;return coreCellInfo
        coreCellInfo
    )
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpFlattenRow															 *
*	Inputs:																			 *
*		- rowDef: complete row definition for row to be processed which includes	 *
*			information on start, repeat, and end data structures					 *
*		- constants: table of constant values used for substitution					 *
*		- defaults: table of default values used for constructing the default		 *
*			row configuration														 *
*		- dontDrawList: list of sides to remove from row creation 					 *
*		- location: one of top, bottom, or repeat to represent the type of row		 *
*			being operated upon (used with dontDrawList to determine if a start,	 *
*			repeat, or end section should be removed from creation)					 *
*       (optional)
*       - coreCellInfo: table of info created from top/bottom row cells to
*           be used as a substitute for a core cell when there is no core cell.
*           This should only be passed in when working on repeat rows, not
*           for top and bottom rows.
*	Outputs:																		 *
*		- rowInfo: table containing flattened data for the specified row ready for	 *
*			placement in the specified pcCellView									 *
*																					 *
*	Tag: _J_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpFlattenRow(rowDef constants defaults dontDrawList location @key (coreCellInfo nil)) 
	let(
		(
			(xDim 0)
			rowInfo (rowHeight 0) repeatParam specialCase 
		)

		rowInfo = makeTable('rowDef nil)

		;; handle special row directives first
		if(stringp(rowDef) && length(parseString(rowDef ":")) == 2 then
			specialCase = parseString(rowDef ":")
			if(lowerCase(car(specialCase)) == "space" then
				rowHeight = cdfParseFloatString(cadr(specialCase)) / 1e-6
				foreach(section list("start" "repeat" "end")
					rowInfo[section] = makeTable(concat(section) nil)
					rowInfo[section]["elem"] = nil
					rowInfo[section]["length"] = 0.0
					rowInfo[section]["height"] = rowHeight
				)
				rowInfo["height"] = rowHeight
			)
		else
            ;do start and end first to get height to feed into repeat
			foreach(section list("start" "end" "repeat")
                ;fprintf(stderr "section=%s\n" section)
				if(section == "repeat" then
					repeatParam = t
				else
					repeatParam = nil
				)
                if(repeatParam then
                    rowInfo[section] = fdkUpFlattenRowSection(rowDef[section] xDim constants defaults
                        ?repeat repeatParam ?coreCellInfo coreCellInfo ?sectionName section)
                else
                    rowInfo[section] = fdkUpFlattenRowSection(rowDef[section] xDim constants defaults
                        ?repeat repeatParam ?sectionName section)
                )
				rowHeight = max(rowHeight rowInfo[section]["height"])
                if(coreCellInfo then
                    coreCellInfo["height"]=rowHeight
                )
			)
			rowInfo["height"] = rowHeight
		)

		;; post process rowInfo in the event that dontDrawList and location dictate
		;; removal of shapes	
		rowInfo = fdkUpFilter(rowInfo dontDrawList location)
        ;fprintf(stderr "here is rowInfo from fdkUpFlattenRow for rowDef %s\n" rowDef)
        ;fdkPrintTable(rowInfo)

		rowInfo
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpFlattenRowSection													 *
*	Inputs:																			 *
*		- section: one of the start, repeat, or end sections of the current row		 *
*			which needs to be flattened to convert meta-language to physical 		 *
*			placement of array elements												 *
*		- xDim: coordinate in the x dimension where the given row section is to be 	 *
*			placed (usually after the previous section with any offsets taken into	 *
*			account)																 *
*		- constants: table of constant values used for substitution					 *
*		- defaults: table of default values used for constructing the default		 *
*			row configuration														 *
*		- repeat: flag indicating whether the current section is a repeat section	 *
*			since it needs to be processed differently from a start or end			 *
*	Outputs:																		 *
*		- flatSection: table representing the flattened row data for the section     *
*			begin operated on														 *
*																					 *
*	Tag: _K_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpFlattenRowSection(section xDim constants defaults @key (repeat nil) (coreCellInfo nil) (sectionName "unknown"))
	let(
		(
			(nestedStack nil) (flat t) (yDim 0.0)
			(sectionL 0.0) (sectionH 0.0)
			flatSection arraySection
		)

		flatSection = makeTable('flatSection nil)
		flatSection["elem"] = list()

		;; determine whether each element in section is empty, flat, stacked, or a nested stack
		;; and process accordingly
        ;if(length(section)==0 && section == "repeat"  && coreCellInfo != nil then NO space for core!
        if(length(section)==0 && coreCellInfo != nil then
            ; there is no cell defined for this section and there is dimensional information found
            ; for other cells which can define the core cells...which is only passed in for repeat
            ; sections.  This supports ring cells (no core) but does not prevent cores without rings!
            sectionL=coreCellInfo["length"]
            sectionH=coreCellInfo["height"]
            ; section has only one element--the fake cell...so it is flat and not tested.
            arraySection = fdkUpProcessFlatElemFake(sectionL sectionH)
            ;sectionL for coreCellInfo already includes the length, so adding it again is not correct
            ;sectionL = sectionL + arraySection["length"]
            ;this is probably unnecessary, but can't hurt.
            sectionH = max(sectionH arraySection["height"])
            if(repeat then
                flatSection["elem"] = append1(flatSection["elem"] arraySection["elemList"])
            else
                flatSection["elem"] = append(flatSection["elem"] arraySection["elemList"])
                xDim = xDim + sectionL
            )
        else
            foreach(elem section
                if(listp(elem) then
                    flat = nil
                    foreach(nestedElem elem
                        if(listp(nestedElem) then
                            nestedStack = t
                        )
                    )
                )
            )

            if(flat then
                foreach(elem section
                    arraySection = fdkUpProcessFlatElem(elem xDim yDim constants defaults ?coreCellInfo coreCellInfo)
                    sectionL = sectionL + arraySection["length"]
                    sectionH = max(sectionH arraySection["height"])
                    if(repeat then
                        flatSection["elem"] = append1(flatSection["elem"] arraySection["elemList"])
                    else
                        flatSection["elem"] = append(flatSection["elem"] arraySection["elemList"])
                        xDim = xDim + sectionL
                    )
                )
            else
                if(nestedStack then
                    arraySection = fdkUpProcessNestedStackSection(section xDim yDim constants defaults
                        ?repeat repeat ?coreCellInfo coreCellInfo)
                    sectionL = arraySection["length"]
                    sectionH = arraySection["height"]
                    flatSection["elem"] = append(flatSection["elem"] arraySection["elemList"])
                else
                    arraySection = fdkUpProcessStackSection(section xDim yDim constants defaults ?coreCellInfo coreCellInfo)
                    sectionL = arraySection["length"]
                    sectionH = arraySection["height"]
                    if(repeat then
                        flatSection["elem"] = append1(flatSection["elem"] arraySection["elemList"])
                    else
                        flatSection["elem"] = append(flatSection["elem"] arraySection["elemList"])
                    )
                )
            )
        )
		flatSection["length"] = sectionL
		flatSection["height"] = sectionH
        ;fdkPrintTable(flatSection)

		flatSection
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpProcessNestedStackSection											 *
*	Inputs:																			 *
*		- section: one of the start, repeat, or end sections of the current row		 *
*			which needs to be flattened to convert meta-language to physical 		 *
*			placement of array elements (a nested stack section occurs when there 	 *
*			are multiple elements stacked inside other elements within the section)	 *	
*		- xDim: coordinate in the x dimension where the given row section is to be 	 *
*			placed (usually after the previous section with any offsets taken into	 *
*			account																	 *
*		- yDim: coordinate in the y dimension where the given row section is to be 	 *
*			placed 																	 *
*		- constants: table of constant values used for substitution					 *
*		- defaults: table of default values used for constructing the default		 *
*			row configuration														 *
*		- repeat: flag indicating whether the current section is a repeat section	 *
*			since it needs to be processed differently from a start or end			 *
*	Outputs:																		 *
*		- elemTable: table representing the flattened row data for the section       *
*			begin operated on taking into account the nested stack situation		 *
*																					 *
*	Tag: _L_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpProcessNestedStackSection(section xDim yDim constants defaults 
			@key (repeat nil) (coreCellInfo nil))
	let(
		(
			currX currY (stackElem nil) stackSection flatElem allH allL elemTable 
			elemList
		)

		;; initialize variables
		currX = xDim
		currY = yDim
		allL = allH = 0
		elemList = list()

		;; iterate over each piece in the nested stack
		foreach(piece section

			;; for each piece in the nested stack, determine if it is a stack or a flat element
			foreach(subPiece piece
				if(listp(subPiece) then
					stackElem = t
				)
			)	

			if(stackElem then
				stackSection = fdkUpProcessStackSection(piece currX currY constants defaults ?coreCellInfo coreCellInfo)
				if(repeat then
					elemList = append1(elemList stackSection["elemList"])
				else
					elemList = append(elemList stackSection["elemList"])
				)
				allH = max(allH stackSection["height"])
				allL = allL + stackSection["length"]
			else
                pieceNumber = 0
				foreach(subPiece piece
                    pieceNumber = pieceNumber+1
					flatElem = fdkUpProcessFlatElem(subPiece currX currY constants defaults ?coreCellInfo coreCellInfo)
					elemList = append(elemList flatElem["elemList"])
					allH = max(allH flatElem["height"])
					allL = allL + flatElem["length"]
					currX = currX + flatElem["length"]
                    ;use offsets in length calcs if more than 1...
                    if(pieceNumber>1 then
                        if(flatElem["modifiers"] then
                            if(flatElem["modifiers"]["offsetX"] then
                                offsetXString=flatElem["modifiers"]["offsetX"]
                                offsetX = cdfParseFloatString(offsetXString)/1e-6
                                currX  = currX + offsetX
                                allL   = allL  + offsetX
                            )
                        )
                    )
                            
				)
			)

			stackElem = nil
		)

		elemTable = makeTable('nestedStack nil)
		elemTable["length"] = allL
		elemTable["height"] = allH
		elemTable["elemList"] = elemList
	
		elemTable
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpProcessStackSection   												 *
*	Inputs:																			 *
*		- section: one of the start, repeat, or end sections of the current row		 *
*			which needs to be flattened to convert meta-language to physical 		 *
*			placement of array elements (a stack section occurs when there 	 		 *
*			are multiple elements stacked  in a row section							 *
*		- xDim: coordinate in the x dimension where the given row section is to be 	 *
*			placed (usually after the previous section with any offsets taken into	 *
*			account																	 *
*		- yDim: coordinate in the y dimension where the given row section is to be 	 *
*			placed 																	 *
*		- constants: table of constant values used for substitution					 *
*		- defaults: table of default values used for constructing the default		 *
*			row configuration														 *
*	Outputs:																		 *
*		- elemTable: table representing the flattened row data for the section       *
*			begin operated on taking into account the stack situation		 		 *
*																					 *
*	Tag: _M_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpProcessStackSection(section xDim yDim constants defaults
			@key (coreCellInfo nil))
	let(
		(
			currX currY stackElem stackHeight stackPieceLength
			elemList allL allH elemTable
		)

		;; initialize variables
		currX = xDim
		currY = yDim
		allL = allH = 0
		elemList = list()

		;; if the element is a stack, then each piece is an element that needs to be
		;; placed on top of each other
        ;consider offsets if pieceNumber > 1
		foreach(piece section
			;; build the row of elements that make up one level of the stack
			stackHeight = stackPieceLength = colLength=0
            stackPieceNumber = 0
			foreach(stackPiece piece
                stackPieceNumber=stackPieceNumber+1
				stackElem = fdkUpProcessFlatElem(stackPiece currX currY constants defaults ?coreCellInfo coreCellInfo)
				stackPieceLength = stackElem["length"]
				stackHeight = max(stackHeight stackElem["height"])
                if(stackPieceNumber>1 then
                    elem = car(stackElem["elemList"])
                    if(elem["modifiers"] then
                        if(elem["modifiers"]["offsetX"] then
                            sPOffsetXString=elem["modifiers"]["offsetX"]
				            sPOffsetX = cdfParseFloatString(sPOffsetXString)/1e-6
                            stackPieceLength = stackPieceLength + sPOffsetX
                            elem["rLength"]= stackPieceLength
                            stackElem["elemList"]=list(elem)
                        )
                    )
                )
				colLength = colLength + stackPieceLength
				currX = currX + stackPieceLength
				elemList = append(elemList stackElem["elemList"])
			)
			currX = xDim
			currY = currY + stackHeight
			allL = max(allL colLength)
			allH = allH + stackHeight
		)

		elemTable = makeTable('stack nil)
		elemTable["length"] = allL
		elemTable["height"] = allH
		elemTable["elemList"] = elemList

		elemTable
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpProcessFlatElemFake
*	Inputs:																			 *
*		- xDim: coordinate in the x dimension where the given element is to be 	 	 *
*			placed (usually after the previous element with any offsets taken into	 *
*			account																	 *
*		- yDim: coordinate in the y dimension where the given element is to be 	 	 *
*			placed 																	 *
*	Outputs:																		 *
*		- elemTable: table representing the fake data for the element			 *
*																					 *
*	Tag: _Z_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpProcessFlatElemFake(xDim yDim)
	let(
		(
			libName cellName viewName
			elemInfo elemTable 
			elemPlacement
		)

        ;fdkUpCellDim is a global table keyed on libName_cellName_viewName
        ;fprintf(stderr "pushing params and cell info into elemInfo...\n")
		elemInfo = fdkUpParseElemInfoFake(xDim yDim)
        ;fprintf(stderr "back with elemInfo %L\n" elemInfo)
		libName = elemInfo["libName"]
		cellName = elemInfo["cellName"]
		viewName = elemInfo["viewName"]
		dimKey = sprintf(nil "%s_%s_%s" libName cellName viewName)

		if(fdkUpCellDim[dimKey]== 'unbound || fdkUpCellDim[dimKey] == nil then
            ;fprintf(stderr "GET DIMENSIONS FOR %s using dimkey %s\n" cellName dimKey)
		    dimTable = makeTable('dimTable nil)
		    dimTable["length"] = xDim
		    dimTable["height"] = yDim
		    dimTable["xOffset"] = 0.0
		    dimTable["yOffset"] = 0.0
			fdkUpCellDim[dimKey] = dimTable
		)

		elemTable = makeTable('flatElem nil)
		elemTable["length"] = xDim
		elemTable["height"] = yDim

		elemPlacement = makeTable('elemPlace nil)
        ;formerly used xDim and yDim for x and y...but should not
		elemPlacement["x"] = 0.0
		elemPlacement["y"] = 0.0
        elemPlacement["xOffset"] = 0.0
        elemPlacement["yOffset"] = 0.0
		elemPlacement["libName"] = elemInfo["libName"]
		elemPlacement["cellName"] = elemInfo["cellName"]
		elemPlacement["viewName"] = elemInfo["viewName"]
		elemPlacement["modifiers"] = elemInfo["modifiers"]
		elemPlacement["length"] = xDim
		elemPlacement["height"] = yDim
		elemTable["elemList"] = list(elemPlacement)

		elemTable
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpProcessFlatElem													 *
*	Inputs:																			 *
*		- elem: single array element that needs to be converted from the 			 *
*			meta-language format into a format that can be used to place the actual	 *
*			OA data																	 *
*		- xDim: coordinate in the x dimension where the given element is to be 	 	 *
*			placed (usually after the previous element with any offsets taken into	 *
*			account																	 *
*		- yDim: coordinate in the y dimension where the given element is to be 	 	 *
*			placed 																	 *
*		- constants: table of constant values used for substitution					 *
*		- defaults: table of default values used for constructing the default		 *
*			row configuration														 *
*	Outputs:																		 *
*		- elemTable: table representing the flattened data for the element			 *
*																					 *
*	Tag: _N_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpProcessFlatElem(elem xDim yDim constants defaults
			@key (coreCellInfo nil))
	let(
		(
			(elemL 0) (elemH 0) libName cellName viewName
			elemInfo elemTable 
			dimKey paramTable currValue elemPlacement
		)

        ;fdkUpCellDim is a global table keyed on libName_cellName_viewName
		elemInfo = fdkUpParseElemInfo(elem constants defaults)
		libName = elemInfo["libName"]
		cellName = elemInfo["cellName"]
		viewName = elemInfo["viewName"]

		dimKey = sprintf(nil "%s_%s_%s" libName cellName viewName)
		paramTable = elemInfo["modifiers"]["param"]
		if(paramTable then
			foreach(param paramTable["sortedKeys"]
				currValue = paramTable[param]
				if(booleanp(currValue) then
					dimKey = strcat(dimKey sprintf(nil "_%s_%L" param currValue))
				else
					dimKey = strcat(dimKey sprintf(nil "_%s_%s" param currValue))
				)
			)	
		)
        ;if this cell dimension has not been stored in the global table, do it!
        ;note that parameterized cell info in property bag can change the cell dimensions, so
        ;while there may be one cellname, the parameter info has to be part of the key for
        ;unique cell dimension information with changes in parameters!
		if(fdkUpCellDim[dimKey]== 'unbound || fdkUpCellDim[dimKey] == nil then
            ;fprintf(stderr "GET DIMENSIONS FOR %s using dimkey %s\n" cellName dimKey)
            
			fdkUpCellDim[dimKey] = fdkUpGetCellDim(libName cellName viewName paramTable coreCellInfo)
		)
		elemL = fdkUpCellDim[dimKey]["length"]
		elemH = fdkUpCellDim[dimKey]["height"]

		elemTable = makeTable('flatElem nil)
        ;elemTable entries used to determine position in a row or column based on cell dimensions
		elemTable["length"] = elemL
		elemTable["height"] = elemH
        ;elemPlacement is used to translate cell information and directions for instance placement
		elemPlacement = makeTable('elemPlace nil)
        ;while this appears redundant it is not as this information is used for instance placement
		elemPlacement["x"] = xDim
		elemPlacement["y"] = yDim
        elemPlacement["xOffset"] = fdkUpCellDim[dimKey]["xOffset"]
        elemPlacement["yOffset"] = fdkUpCellDim[dimKey]["yOffset"]
        ;note elemInfo represents info from propertybag for this cell, not info from the cell itself
		elemPlacement["libName"] = elemInfo["libName"]
		elemPlacement["cellName"] = elemInfo["cellName"]
		elemPlacement["viewName"] = elemInfo["viewName"]
		elemPlacement["modifiers"] = elemInfo["modifiers"]
		elemPlacement["length"] = elemL
		elemPlacement["height"] = elemH
		elemTable["elemList"] = list(elemPlacement)

		elemTable
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpGetCellDim															 *
*	Inputs:																			 *
*		- libName: library name for cell being operated on							 *
*		- cellName: cell name for cell being operated on							 *
*		- viewName: view name for cell being operated on							 *
*		- paramTable: table of parameters for the given instance that needs to be 	 *
*			applied in order to retrieve the necessary cell dimensions				 *
*	Outputs:																		 *
*		- dimTable: table defining the length, height, and offsets of the particular *
* 			instance after all parameter values have been applied taking into 		 *
*			account the boundary layer of the cell (prBoundary, instance, or 		 *
*			geometric shapes)														 *
*																					 *
*	Tag: _O_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpGetCellDim(libName cellName viewName paramTable coreCellInfo)
	let(
		(
			cvId llX urX llY urY length height instDrawing
			bBox (offsetX 0) (offsetY 0) dimTable master paramList
			currValue paramType (testInst nil)
		)

		dimTable = makeTable('dimTable nil)
		cvId = dbOpenCellViewByType(libName cellName viewName)

        if(cvId then
			;; if there is a paramTable, then this is a parameterized cell
			;; and it needs to be placed in a dummy layout to determine the 
			;; cell dimensions
			if(paramTable then
				paramList = list()
				foreach(param paramTable["sortedKeys"]
					currValue = paramTable[param]
					if(booleanp(currValue) then
						paramType = "boolean"
					else
						paramType = "string"
					)
					paramList = append1(paramList list(param paramType paramTable[param]))
				)
				master = cvId	
				testInst = dbCreateParamInst(
					pcCellView master "fdkTestInst"
					0:0 "R0" 1 paramList
				)
				cvId = testInst~>master
			)

            ;; if instance/drawing layer exists, use it to define the cell dimensions
            ;; if instance/drawing layer doesn't exist but prBoundary object does, use it
            instDrawing = setof(shape cvId~>shapes shape~>layerName == "instance")
            if(instDrawing then
                bBox = car(instDrawing)~>bBox
            else
                if(cvId~>prBoundary then
                    bBox = cvId~>prBoundary~>bBox
                else
                    bBox = cvId~>bBox
                )
            )
            ;; create offsets to be used when instantiating.  Any instance not at 0,0
            ;; needs to be placed at an offset to get pr boundary placed at 0,0
            offsetX = -caar(bBox)
            llX = caar(bBox)
            urX = caadr(bBox)
            length = urX - llX
            offsetY = -cadar(bBox)
            llY = cadar(bBox)
            urY = cadadr(bBox)	
            height = urY - llY
        else
            height = 0.0
            offsetX = 0.0
            offsetY = 0.0
            if(coreCellInfo then
                length = coreCellInfo["length"]
            else
			    length = 0.0
            ) 
        )

		if(testInst then
			dbDeleteObject(testInst)
		)

		dimTable["length"] = length
		dimTable["height"] = height
		dimTable["xOffset"] = offsetX
		dimTable["yOffset"] = offsetY
        ;fprintf(stderr "cell %s %L x %L  with x offset=%L  and yoffset=%L\n" cellName length height offsetX offsetY)
		
		dimTable
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpParseElemInfoFake
*	Inputs:																			 *
*	Outputs:																		 *
*		- elemInfo: table containing library name, cell name, and view name for the  *
*			array element being processed along with a table representing any		 *
*			modifiers specified on the element										 *
*																					 *
*	Tag: _P_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpParseElemInfoFake(xDim yDim)
	let(
		(
			parsedValue libCellView modifiers elemInfo modifierValueList keyvaluestring
			modifierValue cellName
		)
        ;create modifiers using the pcell params
		modifiers = makeTable('modifiers nil)
        modifierValueList = list()
        ;set modifierValue to correct string of key:value,key:value, then reformat as needed
        ;foreach(param paramTable
        ;   keyvaluestring=sprintf(nil "%s:%s" param paramTable[param])
        ;   modifierValueList = append1(modifierValueList keyvaluestring)
        ;)
        modifierValue=buildString(modifierValueList ",")
	    modifiers["param"] = fdkUpParseParamModifier(modifierValue)

		cellName = "!nocore"
        /*
        ;can't use the same cell name for this, so switch to alternate cellname
        rexCompile("^\\([np]\\)\\(.*\\)$")
        if(rexExecute(cellName) then
            prefix = rexSubstitute("\\1")
            suffix = rexSubstitute("\\2")
            if($prefix == "n" then
                cellName = sprintf(nil "%s%s" "p" suffix)
            else
                cellName = sprintf(nil "%s%s" "n" suffix)
            )
        )
        */
		elemInfo = makeTable(concat(cellName) 'nil)
		elemInfo["libName"] = pcCellView~>libName
		elemInfo["cellName"] = cellName
		elemInfo["viewName"] = "layout"
		elemInfo["modifiers"] = modifiers

		elemInfo
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpParseElemInfo														 *
*	Inputs:																			 *
*		- arrayElem: string representing the current array element that needs to be	 *
*			parsed to obtain all pertinent placement information					 *
*		- subDict: table representing substitution values for variables that may	 *
*			appear in the array element definition									 *
*		- defaults: table representing default values for the given cell so that a 	 *
*			default library may be assigned to the current array element if none is	 *
*			explicity specified														 *
*	Outputs:																		 *
*		- elemInfo: table containing library name, cell name, and view name for the  *
*			array element being processed along with a table representing any		 *
*			modifiers specified on the element										 *
*																					 *
*	Tag: _P_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpParseElemInfo(arrayElem subDict defaults)
	let(
		(
			parsedValue libCellView modifiers elemInfo modifierString
			cellName libName viewName libCellViewParsed modifierName modifierValue
			parsedModifier
		)

		modifierString = ""
		modifiers = makeTable('modifiers nil)
		parsedValue = parseString(arrayElem "()")

		;; library, cell, and view name will be the first element
        ;; get the constant definition if it exists for entire libCellView
		libCellView = car(parsedValue)
		if(index(libCellView "$") then
			libCellView = subDict[libCellView]
		)
        ; warns of bad config issue before program error occurs
        if(libCellView == nil then
            fprintf(stderr "CONFIG ERROR--no definition of %L in constant definitions\n" arrayElem)
        )
        ;split on either / or :
		libCellViewParsed = parseString(libCellView "/:")
		if(length(libCellViewParsed) == 3 then
            ;libname/cellname:viewname or would allow all / or all : to split
			libName = car(libCellViewParsed)
			cellName = cadr(libCellViewParsed)
			viewName = car(reverse(libCellViewParsed))
		)
		if(length(libCellViewParsed) == 2 then
            ;either libName/cellname  or cellName:viewName
			if(member("/" parseString(libCellView "")) then
                ;libName/cellname
				libName = car(libCellViewParsed)
				cellName = cadr(libCellViewParsed)
				viewName = "layout"
			else
                ;cellName/viewname
				libName = defaults["library"]
				cellName = car(libCellViewParsed)
				viewName = cadr(libCellViewParsed)
			)
		)
		if(length(libCellViewParsed) == 1 then
            ;cellName (others are defaults)
			libName = defaults["library"]
			cellName = car(libCellViewParsed)
			viewName = "layout"
		)
        ;substitute the real values if aliased
		if(index(libName "$") then
			libName = subDict[libName]
		)
		if(index(cellName "$") then
			cellName = subDict[cellName]
		)
		if(index(viewName "$") then
			viewName = subDict[viewName]
		)

		;; determine which elements of parsed list are modifiers
		foreach(elem parsedValue
			if(index(elem "=") then
				modifierString = elem
			)
		)
		foreach(modifier parseString(modifierString ";")
			parsedModifier = parseString(modifier "=")
			modifierName = car(parsedModifier)
			modifierValue = cadr(parsedModifier)
			if(index(modifierValue "$") then
				modifierValue = subDict[modifierValue]
			)

			;; if the current modifier is a parameter list, format it
			;; properly
			if(modifierName == "param" then
				modifierValue = fdkUpParseParamModifier(modifierValue)
			)
	
			modifiers[modifierName] = modifierValue
		)

		elemInfo = makeTable(concat(cellName) 'nil)
		elemInfo["libName"] = libName
		elemInfo["cellName"] = cellName
		elemInfo["viewName"] = viewName
		elemInfo["modifiers"] = modifiers

		elemInfo
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpParseParamModifier													 *
*	Inputs:																			 *
*		- paramValues: list of user specified parameters on an array element in 	 *
*			meta-language format													 *
*	Outputs:																		 *
*		- paramTable: user specified parameters of an array element placed into a 	 *
*			table that has its values formatted for passage into the 				 *
*			dbCreateInstParam function												 *
*																					 *
*	Tag: _Q_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpParseParamModifier(paramValues)
	let(
		(
			paramList paramTable sortedParamList parsedKeyValue currKey currValue
		)	

		;; initialize paramater table
		paramTable = makeTable('param nil)

		;; parse the parameter value string into a list of colon separated
		;; key/value pairs
		paramList = parseString(paramValues "{}/")

		;; sort parameter list in alphabetical order so that same configuration
		;; can be retrieved for duplicate devices
		sortedParamList = sort(paramList nil)	

		;; iterate over each parameter and assign value to key
		paramTable["sortedKeys"] = list()
		foreach(param sortedParamList
			parsedKeyValue = parseString(param ":")
			currKey = car(parsedKeyValue)
			currValue = cadr(parsedKeyValue)
			paramTable["sortedKeys"] = append(paramTable["sortedKeys"] list(currKey))
			if(currValue == "TRUE" then
				currValue = t
			else if(currValue == "FALSE" then
				currValue = nil
			))
			paramTable[currKey] = currValue
		)

		paramTable
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpGetPropBag															 *
*	Inputs:																			 *
*		- libName: library name for location of required UP propbag data		     *
*		- cellName: cell name for location of required UP propbag data		         *
*		- constName: hierarchical property name that defines constants				 *
*		- defName: hierarchical property name that defines defaults				     *
*		- rowDefName: hierarchical property name that defines row definitions	     *
*		- connectName: hierarchical property name that defines connecivity 			 *
*			information for pin mapping												 *
*		- propagatePins: boolean property that determines whether pin propagation	 *
*			will occur for the given array (connect table is set to nil if pin		 *
*			propagation is not set to occur)										 *
*	Outputs:																		 *
*		- propTable: table representing all the required data to invoke the 		 *
*			universal placer code													 *
*																					 *
*	Tag: _R_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpGetPropBag(libName cellName @key
			(constName "constDef") (defName "defaults") (rowDefName "rowDef")
			(connectName "connectivity") (propagatePins nil))
	let(
		(
			propTable ddId
			rowDefs constants defaults connect
		)

		propTable = makeTable('upPropTable nil)

		ddId = ddGetObj(libName cellName)
		rowDefs = fdkGetPropTable(ddId ?name rowDefName)
		constants = fdkGetPropTable(ddId ?name constName)
		defaults = fdkGetPropTable(ddId ?name defName)
		if(!propagatePins then
			connect = nil
		else
			connect = fdkGetPropTable(ddId ?name connectName)
		)

		propTable[rowDefName] = rowDefs
		propTable[constName] = constants
		propTable[defName] = defaults
		propTable[connectName] = connect

		propTable
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpCalcCoreOffset														 *
*	Inputs:																			 *
*		- libName: library name for cell being operated upon						 *
*		- cellName: cell name for cell being operated upon							 *
*		- rowDefString: string for the row name for which the offset is being 		 *
*			calculated																 *
*		- constName: hierarchical property name that defines constants				 *
*		- defName: hierarchical property name that defines defaults				     *
*		- rowDefName: hierarchical property name that defines row definitions	     *
*		- dontDraw: comma separated list with valid values of top, bottom, left,	 *
*			and right (used to remove drawing of periphery cells on given sides		 *
*	Outputs:																		 *
*		- returnTable: table containing the length and height of the start section	 *
*			of the given row being operated upon (used for specifiying an offset	 *
*			value in fdkUpPlaceArrayRowsBase function in order to position origin 	 *
*			at the beginning of the core section									 *
*																					 *
*	Tag: _S_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpCalcCoreOffset(propTable rowDefString 
			@key (constName "constDef") (defName "defaults") (rowDefName "rowDef")
			(dontDraw "")) 
	let(
		(
			rowDef rowInfo constants defaults
			returnTable dontDrawList returnLength returnHeight
		)
        ;; fdkUpCellDim is a global cell dimensions table
		fdkUpCellDim = makeTable('fdkUpCellDim nil)

        ;split the dontDrawList into a list using the comma delimiter
		if(dontDraw != "" then
			dontDrawList = mapcar('lowerCase parseString(dontDraw ","))
		else
			dontDrawList = list()
		)

		;; retrieve row definition represented by rowDefName
		rowDef = propTable[rowDefName][rowDefString]
		constants = propTable[constName]
		defaults = propTable[defName]

		;; flatten requested row definition
		rowInfo = fdkUpFlattenRow(rowDef constants defaults dontDrawList "repeat" )

		fdkUpCellDim = 'unbound

		;; build return table
		returnTable = makeTable('coreOffset nil)

		if(member("left" dontDrawList) then
			returnLength = 0.0
		else
			returnLength = rowInfo["start"]["length"]
		)
		if(member("bottom" dontDrawList) then
			returnHeight = 0.0
		else
			returnHeight = rowInfo["start"]["height"]
		)

		returnTable["length"] = returnLength
		returnTable["height"] = returnHeight

		returnTable
	)
)

/*************************************************************************************
*																					 *
*	Name:	fdkUpFilter	 															 *
*	Inputs:																			 *
*		- rowInfo: row being filtered												 *
*		- dontDrawList: list of sides to remove from row creation 					 *
*		- location: one of top, bottom, or repeat to represent the type of row		 *
*			being operated upon (used with dontDrawList to determine if a start,	 *
*			repeat, or end section should be removed from creation)					 *
*	Outputs:																		 *
*		- currRowInfo: updated row information with the appropriate dontDrawList	 *
*			areas set to nil so that they are not created for the given array		 *
*																					 *
*	Tag: _T_																		 *
*																					 *
*************************************************************************************/

procedure(fdkUpFilter(rowInfo dontDrawList location)
	let(
		(
			currRowInfo (emptyStart nil) (emptyRepeat nil) (emptyEnd nil)
		)

		currRowInfo = rowInfo
		if(location == "bottom" then
			if(member("bottom" dontDrawList) then
				emptyStart = emptyRepeat = emptyEnd = t
			else
				if(member("left" dontDrawList) then
					emptyStart = t
				)
				if(member("right" dontDrawList) then
					emptyEnd = t
				)
			)
		)
		if(location == "top" then
			if(member("top" dontDrawList) then
				emptyStart = emptyRepeat = emptyEnd = t
			else
				if(member("left" dontDrawList) then
					emptyStart = t
				)
				if(member("right" dontDrawList) then
					emptyEnd = t
				)
			)
		)
		if(location == "repeat" then
			if(member("left" dontDrawList) then
				emptyStart = t
			)
			if(member("right" dontDrawList) then
				emptyEnd = t
			)
		)

		if(emptyStart then
			currRowInfo["start"]["elem"] = nil
		)
		if(emptyRepeat then
			currRowInfo["repeat"]["elem"] = nil
		)
		if(emptyEnd then
			currRowInfo["end"]["elem"] = nil
		)

		currRowInfo
	)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; usage: for top, bottom or the row-repeat, call CreateRowRepeatTable
;;    This table is then used to create each section independently.
;;    To avoid stacking a start section on top of a repeat section, pass in
;;     a different origin coordinate for the repeat mosaics (which can
;;     be derived from the table created in CreateRowRepeatTable).  Likewise
;;     for the end.
;;    Each time the CreateMosaics procedure is called it returns a simple 
;;     table: mosaicsTable["mosaics"] is a list of mosaic pointers.
;;            mosaicsTable["length"] is the leghth of all the stacked mosaics.
;;    So here is an example of how this can be used:
;; instTable = fdkUpCreateRowRepeatTable(pcCellView rowRepeatList)
;; startMosaicsTable = fdkUpCreateMosaics(pcCellView rows cols instTable "start" 0.0 0.0)
;; rx = startMosaicsTable["right"]
;; repeatMosaicsList = fdkUpCreateMosaics(pcCellView rows cols instTable "repeat" rx 0.0)
;; ex = repeatMosaicsTable["right"]
;; endMosaicsList = fdkUpCreateMosaics(pcCellView rows cols instTable "end" ex 0.0)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure(fdkUpCreateRowRepeatTable(propTable rowRepeatList dontDraw location
			@key (rowDefName "rowDef") (constName "constDef") (defName "defaults")
                 (coreCellInfo nil)            
         )
    let(
        (
            rr secList secLast rowsHeight rC
            rowDef rowDefs rDT rowHeight
            sec colNum b4Len cC oT
            elemList cellpNum tableName
            colList addHeight
            colLen
            offsetx offsety 
            el rightEdge
        )
        rowDefs = propTable[rowDefName]

        ; create rr: the rowRepeat table 
        rr = makeTable("rowRepeat")
        rowRepeatList = parseString(rowRepeatList ",")
        secList = list("start" "repeat" "end")
        secLast = length(secList)-1
        rowsHeight = 0.0
        rC = 0
        addHeight=0.0
        for( i1 0 length(rowRepeatList)-1
            rowDef =nth(i1 rowRepeatList)
            if(rexMatchp(":" rowDef) then
                ;this is not a real row: just use flattenrow to get added height
                ;to be used as y offset for next row
                rDT = fdkUpFlattenRow(rowDef propTable[constName] propTable[defName] nil "space" ?coreCellInfo coreCellInfo )
                if(rC==0 then
                    ;use to insert a space before the first row
                    addHeight=rDT["height"]
                else
                    rr[rC]["height"] == rr[rC]["height"] + rDT["height"]
                    for( i2 0 secLast
                        sec=nth(i2 secList)
                        rr[rC][sec]["height"] = rr[rC][sec]["height"]+rDT["height"]
                    )
                    rowsHeight=rowsHeight+rDT["height"]
                ) 
            else
                rC=rC+1
                rr[rC] = makeTable(sprintf(nil "row%d" rC))
                ;fix case where all sections of a rowDef are unbound
                if( rowDefs[rowDef]=='unbound then
                    rowDefs[rowDef]=makeTable(rowDef)
                )
                ;fix case where some sections of a rowDef are unbound
                for( i2 0 secLast
                    sec=nth(i2 secList)
                    if(rowDefs[rowDef][sec]=='unbound || rowDefs[rowDef][sec]==nil || rowDefs[rowDef][sec]== "" then
                        rowDefs[rowDef][sec] = list()
                    )
                )
                ;need coreCellInfo for input to this....
                rDT = fdkUpFlattenRow(rowDefs[rowDef] propTable[constName] propTable[defName] 
					dontDraw location  ?coreCellInfo coreCellInfo)
                rowHeight = 0.0
                for( i2 0 secLast
                    sec=nth(i2 secList)
                    rr[rC][sec]=makeTable(sec)
                    rr[rC][sec]["height"] = rDT[sec]["height"]+addHeight
                    rr[rC][sec]["length"] = rDT[sec]["length"]
                    rr[rC][sec]["colInfo"] = makeTable("colInfo")
                    ;sometimes elem is a table (aka, cell placement)
                    ;sometimes elem is a list of tables (aka a single column with cell placements)
                    ;sometimes elem is a list of lists (aka multiple columns, each column with cell placements)
                    ;this needs to be expanded into a list of lists in all cases so it is correctly interpreted!
                    if(tablep(rDT[sec]["elem"]) then
                        if( rDT[sec]["elem"]["x"] == 'unbound || rDT[sec]["elem"]["x"] == nil then
                            rr[rC][sec]["colInfo"]["num"]=0
                            colList = list()
                        else
                            elemList = list( rDT[sec]["elem"] )
                            colList = list(elemList)
                        )
                    else 
                        if(listp(rDT[sec]["elem"]) then
                            if(listp(nth(0 rDT[sec]["elem"])) then
                                colList = rDT[sec]["elem"]
                            else
                                colList = list( rDT[sec]["elem"])
                            )
                        )
                    )
                    if(rDT[sec]["elem"]== nil then
                        colList = list()
                    )
                    rr[rC][sec]["elem"] = rDT[sec]["elem"]
                    colNum = length(colList)
                    rr[rC][sec]["colInfo"]["num"] = colNum
                    b4Len = 0.0
                    cC = 0
                    for( i3 0 colNum-1
                        cC=cC+1
                        elemList = nth(i3 colList)
                        cellpNum = length(elemList)
                        tableName = sprintf(nil "cellInfoCol%d" cC)
                        rr[rC][sec]["colInfo"][cC] = makeTable(tableName)
                        rr[rC][sec]["colInfo"][cC]["num"] = cellpNum
                        rr[rC][sec]["colInfo"][cC]["b4Len"] = b4Len
                        ;compute length (deltax) of column, addHeight, compute offsets/orients
                        colLen = 0.0
                        for( i4 0 cellpNum-1
                            el=nth(i4 elemList)
                            ;fdkPrintTable( el )
                            el["y"] = el["y"] + addHeight
                            ;property bag offsets
                            if(!el["modifiers"]["offsetX"] then
                                offsetx = 0.0
                            else
                                offsetx = el["modifiers"]["offsetX"]
                            )
                            if(!el["modifiers"]["offsetY"] then
                                offsety = 0.0
                            else
                                offsety = el["modifiers"]["offsetY"]
                            )

                            oT = fdkUpMosaicOrient(el["length"] el["height"] offsetx offsety el["modifiers"]["mirror"] nil)
                            el["modifiers"]["offsetX"]= oT["offsetX"]
                            el["modifiers"]["offsetY"]= oT["offsetY"]
                            el["modifiers"]["mirror"]= oT["orient"]
                            rightEdge = el["x"]+el["length"]
                            colLen=max(colLen rightEdge)
                        )
                        rr[rC][sec]["colInfo"][cC]["length"] = colLen
                        b4Len=b4Len+colLen
                    );end for i3 (columns for section)
                    ;real row Height is max height of all sections
                    rowHeight = max(rowHeight rr[rC][sec]["height"])
                );end for i2 (sections for row)
                rr[rC]["height"]=rowHeight
                rr[rC]["b4Height"] = rowsHeight
                rowsHeight = rowsHeight+rowHeight
                addHeight = 0.0; reset to 0.0 so it can't be used again until another space!
            )
        )
        rr["num"]=rC
        rr["height"]=rowsHeight
        rr    
    )
)

procedure(fdkUpCreateMosaics(cV rowCount colCount rr sec originx originy mosaicPrefix)
    let(
        (
            mosaics mosaicsTable mosaicsTop mosaicsRight mosaicTop mosaicRight
            arrayRowNum arrayRowExtra aR mosaicExtentRight mosaicExtentTop
			mosaicsExtentRight mosaicsExtentTop
            rowSpacing colList elemList
            cC moId
            arrayColNum arrayColExtra aC
            colSpacing
            elem
            eoffset
            xoffset
            yoffset
            originxoffset
            originyoffset
            orient
            origin
            params
            upt
            cellName viewName libName name
        )
        ; Using data in rowRepeatTable (rr), generate mosaics for a section
        ; and return a list of the mosaic object ids
        mosaicsTable = makeTable("mosaicsTable")
        mosaics = list("OMIT")
        mosaicsExtentTop = originy
        mosaicsExtentRight = originx
        mosaicsTop = originy
        mosaicsRight = originx
        rowSpacing = rr["height"]
        ;only repeat uses colCount.  Others treated as if there is just one column
        if(sec != "repeat" then
            colCount = 1
        )
        if(rowCount >0 && colCount > 0 && rr["num"] > 0 then
            ;at least 1 row and 1 column needs to be generated
            arrayRowNum = fix(rowCount/rr["num"])
            arrayRowExtra = mod(rowCount rr["num"])
            for(rNum 1 rr["num"]
                if(rNum <= arrayRowExtra then
                    aR = arrayRowNum + 1
                else
                    aR = arrayRowNum
                )
                if(aR > 0 then
                    ;this row is included within rowCount, so generate
                    ; all Mosaics for cellPlacements for valid columns 
                    cC = rr[rNum][sec]["colInfo"]["num"]
                    if(cC > 0 then
                        arrayColNum = fix(colCount/cC)
                        arrayColExtra = mod(colCount cC)
                    )
                    for(cNum 0 cC-1
                        if(cNum+1<=arrayColExtra then
                            aC = arrayColNum+1
                        else
                            aC = arrayColNum
                        )
                        if(aC > 0 then
                            ; this col is included within colCount
                            ; so generate per cell Placement
                            colSpacing=rr[rNum][sec]["length"]
                            ;fprintf(stderr "colSpacing=%L for row %L section %L\n" colSpacing rNum sec)
                            ;sometimes elem is a table (aka, cell placement)
                            ;sometimes elem is a list of tables (aka a single column with cell placements)
                            ;sometimes elem is a list of lists (aka multiple columns, each column with cell placements)
                            ;this needs to be expanded into a list of lists in all cases so it is correctly interpreted!
                            if(tablep(rr[rNum][sec]["elem"]) then
                                elemList = list( rr[rNum][sec]["elem"] )
                                colList = list(elemList)
                            else 
                                if(listp(rr[rNum][sec]["elem"]) then
                                    if(listp(nth(0 rr[rNum][sec]["elem"])) then
                                        colList = rr[rNum][sec]["elem"]
                                    else
                                        colList = list( rr[rNum][sec]["elem"])
                                    )
                                )
                            )
                            elemList = nth(cNum colList)

                            for(eNum 0 rr[rNum][sec]["colInfo"][cNum+1]["num"]-1
                                ;collect/calculate all cell placement info
                                elem = nth(eNum elemList)
                                ;fprintf(stderr "-d-createMosaics --printing elemList %d from row %d column %d  section %L\n" eNum rNum cNum+1 sec)
                                ;fdkPrintTable(elem)
                                orient = elem["modifiers"]["mirror"]
                                params = elem["modifiers"]["param"]
                                if(params then
				                    params = fdkUpBuildParamList(params)
                                )
                                xoffset=rr[rNum][sec]["colInfo"][cNum+1]["b4Len"]
                                xoffset=xoffset+elem["x"]+originx 
                                originxoffset = elem["xOffset"]; prBoundary offset
                                originyoffset = elem["yOffset"]; prBoundary offset
                                eoffset=elem["modifiers"]["offsetX"] 
				                if(stringp(eoffset) then
                                    eoffset = cdfParseFloatString(eoffset)/1e-6
                                )
                                ;if(elem["modifiers"]["offsetX"] != 0.0 then
                                if(orient=="R180" || orient=="MY" then
                                    ;fprintf(stderr "column %L  xoffset %L modifier offsetX= %L\n" aC xoffset elem["modifiers"]["offsetX"])
                                    ;some flipping going on which means mosaic pointed in different
                                    ;direction...so not only does the offset need to be applied
                                    ;but also the mosaic needs to be pushed to re-align with
                                    ;the last element rather than the first
                                    xoffset=xoffset+eoffset+((aC-1)*colSpacing)
                                    originxoffset = -originxoffset;origin flips to right side, right column
                                else
                                    xoffset=xoffset+eoffset
                                ) 
                                yoffset=rr[rNum]["b4Height"]
                                yoffset=yoffset+elem["y"]+originy
                                eoffset=elem["modifiers"]["offsetY"] 
				                if(stringp(eoffset) then
                                    eoffset = cdfParseFloatString(eoffset)/1e-6
                                )
                                ;if(elem["modifiers"]["offsetY"] != 0.0 then
                                if(orient=="R180" || orient=="MX" then
                                    ;fprintf(stderr "column %L  yoffset %L modifier offsetY= %L\n" aC yoffset elem["modifiers"]["offsetY"])
                                    ;some flipping going on which means mosaic pointed in different
                                    ;direction...so not only does the offset need to be applied
                                    ;but also the mosaic needs to be pushed to re-align with
                                    ;the last element rather than the first
                                    yoffset=yoffset+eoffset+((aR-1)*rowSpacing)
                                    originyoffset = -originyoffset
                                else
                                    yoffset=yoffset+eoffset
                                )
                                if(!listp(params) then
                                    ;this is stupid.  params is not a list, it is a table
                                    params = list()
                                )
                                origin = xoffset+originxoffset:yoffset+originyoffset
                                cellName = elem["cellName"]
                                ;fprintf(stderr "cell:%s origin:%L originxoffset:%L xoffset:%L yoffset:%L originyoffset:%L\n" cellName origin originxoffset xoffset yoffset originyoffset)
                                if(cellName=="!nocore" then
                                    ;;no core cell, but should have spacing info
                                    mosaicRight = originx+((aC-1)*colSpacing)
                                    ;fprintf(stderr "no core cell so start with mosaicRight=%L aC=%L colSpacing=%L\n" mosaicRight aC colSpacing)
                                    mosaicRight = mosaicRight+rr[rNum][sec]["colInfo"][cNum+1]["b4Len"]+elem["x"]+elem["length"]
                                    ;fprintf(stderr "add in b4length: %L  elem x=%L and elem length=%L so mosaicRight=%L\n" rr[rNum][sec]["colInfo"][cNum+1]["b4Len"] elem["x"] elem["length"] mosaicRight)
                                    mosaicsRight = max(mosaicsRight mosaicRight)
                                    mosaicTop = originy+((aR-1)*rowSpacing)
                                    ;for some reason for fake cell y=height, so don't use y!
                                    mosaicTop = mosaicTop+rr[rNum]["b4Height"]+elem["height"]
                                    mosaicsTop = max(mosaicsTop mosaicTop)
                                    ;;other needed values obtained from start and end data
                                else 
                                    viewName = elem["viewName"]
                                    libName = elem["libName"]
                                    ;; dave
                                    name = sprintf(nil "%s_%s|sec=%s_x%L_y%L_row%d_col%d_cell%d" mosaicPrefix cellName sec xoffset yoffset rNum cNum+1 eNum)

                                    ;Place Mosaic
                                    if(orient==nil
                                        orient="R0"
                                    )
                                    ;fprintf(stderr "-d-createMosaics: Create mosaic %L %L %L %L name=%L origin=%L orient=%L rowSpacing=%L colSpacing=%L aR=%L aC=%L params=%L\n" cV libName cellName viewName name origin orient aR aC rowSpacing colSpacing params)
                                    ;for some reason the orient can arrive here as nil.  need to figure that out later
                                    moId = dbCreateParamSimpleMosaicByMasterName(cV libName cellName viewName name origin orient aR aC rowSpacing colSpacing params)
                                    if(moId then
                                        upt = upperRight(moId~>bBox)
                                        mosaicExtentRight=nth(0 upt)
                                        mosaicsExtentRight = max(mosaicsExtentRight mosaicExtentRight)
                                        mosaicRight = originx+((aC-1)*colSpacing)
                                        mosaicRight = mosaicRight+rr[rNum][sec]["colInfo"][cNum+1]["b4Len"]+elem["x"]
                                        ;fdkPrintTable(elem)
                                        if(elem["rLength"] then
                                            mosaicRight = mosaicRight+elem["rLength"]
                                        else
                                            mosaicRight = mosaicRight+elem["length"]
                                        )
                                        mosaicsRight = max(mosaicsRight mosaicRight)
                                        mosaicExtentTop=nth(1 upt)
                                        mosaicsExtentTop = max(mosaicsExtentTop mosaicExtentTop)
                                        mosaicTop = originy+((aR-1)*rowSpacing)
                                        mosaicTop = mosaicTop+rr[rNum]["b4Height"]+elem["y"]+elem["height"]
                                        mosaicsTop = max(mosaicsTop mosaicTop)
                                        nconc(mosaics (list moId))
                                    else
                                        fprintf(stderr "-e-createMosaics: Could not create mosaic %L %L %L %L name=%L origin=%L orient=%L rowSpacing=%L colSpacing=%L aR=%L aC=%L params=%L\n" cV libName cellName viewName name origin orient aR aC rowSpacing colSpacing params)
                                    )
                                )
                            )
                            ;end for eNum (cell placements)
                        )
                        ;end if aC (valid column for cell placements)
                    )
                    ;end for cNum (columns)
                    ;space columns (when cC==0) use section height rather than cell height
                    if(cC == 0 then
                        mosaicTop= originy+((aR-1)*rowSpacing)+rr[rNum]["b4Height"]+rr[rNum][sec]["height"]
                        mosaicsTop = max(mosaicsTop mosaicTop)
                    )
                )
                ;end if aR (valid row)
            )
            ;end for rNum (rows)
        )
        ;end if rowCount/colCount (valid core)
        mosaicsTable["mosaics"] = cdr(mosaics)
        mosaicsTable["right"] = mosaicsRight
        mosaicsTable["extentRight"] = mosaicsExtentRight
        mosaicsTable["top"] = mosaicsTop
        mosaicsTable["extentTop"] = mosaicsExtentTop
        mosaicsTable
    )
)

procedure(fdkUpMosaicOrient(elemL elemH offsetX offsetY mirror rotate)
	let(
		(
			orientParam orientTable
			mirrorValue rotateValue
		)

		mirrorValue = mirror || "0"
		rotateValue = rotate || "0"
        if( offsetX==nil
            offsetX=0.0
        )
        if( offsetY==nil
            offsetY=0.0
        )
        if(stringp(offsetX) then
            offsetX=cdfParseFloatString(offsetX)/1e-6
        )
        if(stringp(offsetY) then
            offsetY=cdfParseFloatString(offsetY)/1e-6
        )

		;; mirror always occurs before rotation
		;; valid values for mirror are "x", "y", and "xy"
		;; valid values for rotate are "90", "180", and "270" in counter clockwise direction
		case(mirrorValue
			("0"
				case(rotateValue
					("0"
						orientParam = "R0"
					)
					("90"
						orientParam = "R90"
						offsetX = offsetX + elemH
					)
					("180"
						orientParam = "R180"
						offsetX = offsetX + elemL
						offsetY = offsetY + elemH
					)
					("270"
						orientParam = "R270"
						offsetY = offsetY + elemL
					)
				)
			)
			("x"
				case(rotateValue
					("0"
						orientParam = "MX"
						offsetY = offsetY + elemH
					)
					("90"
						orientParam = "MXR90"
					)
					("180"
						orientParam = "MY"
						offsetX = offsetX + elemL
					)
					("270"
						orientParam = "MYR90"
						offsetX = offsetX + elemH
						offsetY = offsetY + elemL
					)
				)
			)
			("y"
				case(rotateValue
					("0"
						orientParam = "MY"
						offsetX = offsetX + elemL
					)
					("90"
						orientParam = "MYR90"
						offsetX = offsetX + elemH
						offsetY = offsetY + elemL
					)
					("180"
						orientParam = "MX"
						offsetY = offsetY + elemH
					)
					("270"
						orientParam = "MXR90"
					)
				)
			)
			("xy"
				case(rotateValue
					("0"
						orientParam = "R180"
						offsetX = offsetX + elemL
						offsetY = offsetY + elemH
					)
					("90"
						orientParam = "R270"
						offsetY = offsetY + elemL
					)
					("180"
						orientParam = "R0"
					)
					("270"
						orientParam = "R90"
						offsetX = offsetX + elemH
					)
				)
			)
		)	

		orientTable = makeTable('orientTable nil)
		orientTable["orient"] = orientParam
		orientTable["offsetX"] = offsetX
		orientTable["offsetY"] = offsetY

		orientTable
	)
)

procedure(fdkUpIsRowEmpty(rowInfo)
	let(
		(
		)

		if(!rowInfo["start"] && !rowInfo["repeat"] && !rowInfo["end"] then
			t
		else
			nil
		)
	)
)

procedure(fdkUpGetCells(arrayInfo rowReq colReq @key (dontDrawList list()))
	let(
		(
			botRowInfo repeatRowInfo topRowInfo arrayRows arrayCols
			row col (emptyBotRow nil) (emptyTopRow nil) index rowInfo (colInfo nil)
			(startLength 0) yOffset xOffset rowRepeatIndex colIndex
			currElemLength (cellInfo nil) cellInfoTable
			rowId sectionId groupId shapeId (dontDrawOffsetX 0) (dontDrawOffsetY 0)
		)

		;; retrieve row info
		botRowInfo = arrayInfo["botRowInfo"]
		repeatRowInfo = arrayInfo["repeatRowInfo"]
		topRowInfo = arrayInfo["topRowInfo"]
		when(fdkUpIsRowEmpty(botRowInfo) || member("bottom" dontDrawList)
			emptyBotRow = t
		)
		when(fdkUpIsRowEmpty(topRowInfo) || member("top" dontDrawList)
			emptyTopRow = t
		)

		;; offset location of array elements based upon dontDraw input
		when(dontDrawList
			when(member("bottom" dontDrawList)
				dontDrawOffsetY = -botRowInfo["height"]
			)	
			when(member("left" dontDrawList)
				dontDrawOffsetX = -botRowInfo["start"]["length"]
			)	
		)	

		row = fix(rowReq)
		col = fix(colReq)	

		;; retrieve number of rows and columns in array being operated upon
		arrayRows = arrayInfo["rows"]
		if(!emptyBotRow then
			arrayRows = arrayRows + 1
			rowId = row - 1
		else
			rowId = row
		)
		when(!emptyTopRow
			arrayRows = arrayRows + 1
		)
		arrayCols = arrayInfo["cols"]

		;; determine which row information is needed based upon structure of the array and
		;; the row/column requested by the user
		cond(
			(row < 1 || row > arrayRows
				rowInfo = nil	
			)
			(row == 1
				if(!emptyBotRow then
					rowInfo = botRowInfo
				else
					rowInfo = nth(0 repeatRowInfo)
				)
			)
			(row == arrayRows && !emptyTopRow
				rowInfo = topRowInfo	
			)
			(t
				if(emptyBotRow then
					index = row - 1
				else
					index = row - 2
				)
				if(index <= length(repeatRowInfo)-1 then
					rowInfo = nth(index repeatRowInfo)
				else
					rowInfo = nth(mod(index length(repeatRowInfo)) repeatRowInfo)
				)
			)
		)

		;; determine which column information is required based upon the structure of the array
		;; if the row information returned is valid (non-nil)
		when(rowInfo
			when(rowInfo["start"]
				arrayCols = arrayCols + 1
				startLength = rowInfo["start"]["length"]
			)
			when(rowInfo["end"]
				arrayCols = arrayCols + 1
			)
		
			cond(
				(col < 1 || col > arrayCols
					colInfo = nil
				)
				(col == 1
					if(rowInfo["start"] then
						colInfo = rowInfo["start"]["elem"]
						sectionId = "start"
					else
						colInfo = car(rowInfo["repeat"]["elem"])
						sectionId = "repeat"
					) 
					groupId = 0
				)
				(col == arrayCols && rowInfo["end"]
					colInfo = rowInfo["end"]["elem"]
					sectionId = "end"
					groupId = 0
				)
				(t
					if(!rowInfo["start"] then
						index = groupId = col - 1
					else
						index = groupId = col - 2
					)
					if(index <= length(rowInfo["repeat"]["elem"])-1 then
						colInfo = nth(index rowInfo["repeat"]["elem"])
					else
						colInfo = nth(mod(index length(rowInfo["repeat"]["elem"])) rowInfo["repeat"]["elem"])
					)
					sectionId = "repeat"
				)
			)
		)

		;; if a valid row/column have been specified, then determine the x and y offset into the
		;; array structure for the instances requested
		when(colInfo
			yOffset = cadr(arrayInfo["origin"])
			for(rowNum 1 row-1
				if(rowNum == 1 then
					if(!emptyBotRow then
						yOffset = yOffset + botRowInfo["height"]
						rowRepeatIndex = 1
					else
						yOffset = yOffset + car(repeatRowInfo)["height"]
						rowRepeatIndex = 2
					)
				else
					yOffset = yOffset + nthelem(rowRepeatIndex repeatRowInfo)["height"]
					rowRepeatIndex = rowRepeatIndex + 1
				)
				when(rowRepeatIndex > length(repeatRowInfo)
					rowRepeatIndex = 1
				)
			)

			xOffset = car(arrayInfo["origin"])
			for(colNum 1 col-1
				if(colNum == 1 then
					if(rowInfo["start"] then
						xOffset = xOffset + startLength
						colIndex = 1
					else
						currElemLength = 0
						foreach(elem car(rowInfo["repeat"]["elem"])
							currElemLength = max(currElemLength elem["length"])
						)
						xOffset = xOffset + currElemLength
						colIndex = 2
					)
				else
					currElemLength = 0
					foreach(elem nthelem(colIndex rowInfo["repeat"]["elem"])
						currElemLength = max(currElemLength elem["length"])
					)
					xOffset = xOffset + currElemLength
					colIndex = colIndex + 1
				)
				when(colIndex > length(rowInfo["repeat"]["elem"])
					colIndex = 1
				)
			)

			;; for each element in the row/column selected, compute the return value from
			;; this function
			cellInfo = list()
			shapeId = 0
			foreach(elem colInfo
				cellInfoTable = makeTable('cellInfo nil)
				cellInfoTable["master"] = dbOpenCellViewByType(elem["libName"] elem["cellName"] elem["viewName"])
				cellInfoTable["x"] = dontDrawOffsetX + xOffset + elem["x"]
				cellInfoTable["y"] = dontDrawOffsetY + yOffset + elem["y"]
				cellInfoTable["orientTable"] = fdkUpMosaicOrient(elem["length"] elem["height"] 0 0 elem["modifiers"]["mirror"] elem["modifiers"]["rotate"])
				cellInfoTable["params"] = elem["modifiers"]["param"]
				cellInfoTable["instName"] = sprintf(nil "row%d_%s_%d_%d" rowId sectionId groupId shapeId)
				cellInfo = append(cellInfo list(cellInfoTable))

				shapeId = shapeId + 1
			)
		)

		cellInfo
	)
)

procedure(fdkUpGetCellInfo(arrayInfo instName @key (dontDrawList list()))
	let(
		(
			parsedInstName validInstName (invalidFlag nil)
			rowId section groupId shapeId row rowMod group shape
			rowInfo sectionInfo groupInfo elem
			cellInfo (xOffset 0.0) (yOffset 0.0) currYoffset currXoffset
			currGroupInfo currCol
		)

		;; parse instance name requested from user and validate it is in correct format
		parsedInstName = parseString(instName "_")
		if(length(parsedInstName) != 4 then
			validInstName = nil
		else
			rowId = car(parseString(nth(0 parsedInstName) "row"))
			if(!floatp(cdfParseFloatString(rowId)) then
				invalidFlag = t
			)
			section = nth(1 parsedInstName)
			if(!member(section list("start" "repeat" "end")) then
				invalidFlag = t
			)
			groupId = nth(2 parsedInstName)
			if(!floatp(cdfParseFloatString(groupId)) then
				invalidFlag = t
			)
			shapeId = nth(3 parsedInstName)
			if(!floatp(cdfParseFloatString(shapeId)) then
				invalidFlag = t
			)
			if(invalidFlag then
				validInstName = nil
			else
				validInstName = t
			)
		)

		when(validInstName
			row = atoi(rowId)
			group = atoi(groupId)
			shape = atoi(shapeId)

			;; initialize offset values for calculating exact location of requested element
			when(dontDrawList
				when(member("bottom" dontDrawList)
					yOffset = -arrayInfo["botRowInfo"]["height"]
				)
				when(member("left" dontDrawList)
					xOffset = -arrayInfo["botRowInfo"]["start"]["length"]
				)
			)

			;; find proper row from arrayInfo
			rowInfo = nil
			cond(
				(row == 0
					rowInfo = arrayInfo["botRowInfo"]
				)
				(row == arrayInfo["rows"]+1
					rowInfo = arrayInfo["topRowInfo"]
				)
				(t
					;; since requested row is neither the top or bottom row, it is part of the
					;; repeat row structure and should be converted to a zero based index
					rowMod = row - 1
					if(rowMod <= length(arrayInfo["repeatRowInfo"])-1 then
						rowInfo = nth(rowMod arrayInfo["repeatRowInfo"])
					else
						rowInfo = nth(mod(rowMod length(arrayInfo["repeatRowInfo"])) arrayInfo["repeatRowInfo"])
					)
				)
			)

			;; find y offset into the currently requested row
			for(rowNum 0 row-1
				;; for the first row, we need to offset by the height of the bottom row
				;; otherwise we need to access an element in the row repeat list
				if(rowNum == 0 then
					currYoffset = arrayInfo["botRowInfo"]["height"]
				else
					rowMod = rowNum - 1
					if(rowMod <= length(arrayInfo["repeatRowInfo"])-1 then
						currYoffset = nth(rowMod arrayInfo["repeatRowInfo"])["height"]
					else
						currYoffset = nth(mod(rowMod length(arrayInfo["repeatRowInfo"])) arrayInfo["repeatRowInfo"])["height"]
					)	
				)
				yOffset = yOffset + currYoffset
			)

			;; once the row is found, find the proper column group from this row
			sectionInfo = rowInfo[section]["elem"]
			groupInfo = nil

			;; if the section required is not "start" then we know that we definitely need to provide
			;; an x offset equal to the start section
			if(section != "start" then
				xOffset = xOffset + rowInfo["start"]["length"]
			)

			;; if the section is "end" then we need to offest by the total of all the repeat columns
			if(section == "end" then
				for(col 1 arrayInfo["cols"]
					currCol = nthelem(mod(col length(rowInfo["repeat"]["elem"]))+1 rowInfo["repeat"]["elem"])
					currXoffset = 0.0
					foreach(element currCol
                        ;;the following is replaced by the new code
						;;currXoffset = currXoffset + element["length"]
                        
                        ;;instead...
						;; foreach element in current column, add x position to length
						;; if the total is greater than currXoffset, it becomes the new currXoffset
						;; mosaic pin propagation change (dcenkerx)
						currXdim = element["x"]+element["length"]
						when(currXdim > currXoffset
							currXoffset = currXdim
						)
                        ;; end of new addition
            
					)
					xOffset = xOffset + currXoffset
				)
			)
            ;originally this section always ran, but was changed so only for repeat to get different
            ;section info. For non-repeat now gets the entire sectionInfo
            if(section == "repeat" then
                cond(
                    (group <= length(sectionInfo)-1
                        groupInfo = nth(group sectionInfo)
                    )
                    (t
                        groupInfo = nth(mod(group length(sectionInfo)) sectionInfo)
                    )
                )
            else
                ;this is new--non repeat sections just get sectionInfo for groupInfo
                groupInfo = sectionInfo
            )

			;; find x offset into currently requested row
			for(groupNum 0 group-1
				if(groupNum <= length(sectionInfo)-1 then
					currGroupInfo = nth(groupNum sectionInfo)
				else
					currGroupInfo = nth(mod(groupNum length(sectionInfo)) sectionInfo)
				)
				currXoffset = 0.0
				foreach(element currGroupInfo
                    ;the following line no longer used
					;currXoffset = currXoffset + element["length"]
                    ;...instead use the following:

					;; foreach element in current column, add x position to length
					;; if the total is greater than currXoffset, it becomes the new currXoffset
					;; mosaic pin propagation change (dcenkerx)
					currXdim = element["x"]+element["length"]
					when(currXdim > currXoffset
						currXoffset = currXdim
					)
                    ;; end of new addition 
				)
				xOffset = xOffset + currXoffset
			)

			;; find the proper instance in the selected column group
			if(!listp(groupInfo) then
				groupInfo = list(groupInfo)
			)
			elem = nth(shape groupInfo)
		)

		;; construct return value
		if(elem then
			cellInfo = makeTable('cellInfo nil)
			cellInfo["master"] = dbOpenCellViewByType(elem["libName"] elem["cellName"] elem["viewName"])
			cellInfo["x"] = xOffset + elem["x"]
			cellInfo["y"] = yOffset + elem["y"]
			cellInfo["orientTable"] = fdkUpMosaicOrient(elem["length"] elem["height"] 0 0 elem["modifiers"]["mirror"] elem["modifiers"]["rotate"])
			cellInfo["params"] = elem["modifiers"]["param"]
		)

		cellInfo
	)
)

procedure(fdkUpConnectShapes(instArray cvId layer beginRef beginShape endRef 
			@key (endShape nil) (netName nil) (offsetX 0) (offsetY 0)
			(deltaX 0) (deltaY 0) (stepX 0) (stepY 0) (stepCount 1) (dontDrawList list())) 
	let(
		(
			beginCellInfo endCellInfo endShapeFinal beginBbox endBbox
			direction beginL beginH endL endH  
			startPoint endPoint enablePin rodShape
			rodShapeList validNetName validStepParam currStartPoint currEndPoint
			netNameList currNetName
		)

		;; retrieve information about beginning and end instance reference
		beginCellInfo = fdkUpGetCellInfo(instArray beginRef ?dontDrawList dontDrawList)
		endCellInfo = fdkUpGetCellInfo(instArray endRef ?dontDrawList dontDrawList)

		;; define end shape if not yet specified
		if(!endShape then
			endShapeFinal = beginShape
		else
			endShapeFinal = endShape
		)	

		;; find beginning and end shape coordinates and transform based upon location of instance and transform
		beginBbox = dbTransformBBox(beginShape~>bBox list(list(beginCellInfo["x"] beginCellInfo["y"]) beginCellInfo["orientTable"]["orient"] 1.0))
		endBbox = dbTransformBBox(endShapeFinal~>bBox list(list(endCellInfo["x"] endCellInfo["y"]) endCellInfo["orientTable"]["orient"] 1.0))

		;; determine the routing direction based upon the beginning and ending bounding boxes
		beginL = caadr(beginBbox)-caar(beginBbox)
		beginH = cadadr(beginBbox)-cadar(beginBbox)
		endL = caadr(endBbox)-caar(endBbox)
		endH = cadadr(endBbox)-cadar(endBbox)
		cond(
			(fdkCmp(beginL "==" endL) && fdkCmp(caar(beginBbox) "==" caar(endBbox))
				direction = "vertical"
			)
			(fdkCmp(beginH "==" endH) && fdkCmp(cadar(beginBbox) "==" cadar(endBbox))
				direction = "horizontal"
			)
			(t
				direction = "none"
			)
		)

		;; only continue with generating shape if direction is valid
		when(direction != "none"
			if(direction == "vertical" then
				if(fdkCmp(cadar(endBbox) ">" cadar(beginBbox)) then
					startPoint = dbTransformPoint(car(beginBbox) list(list(beginCellInfo["orientTable"]["offsetX"]
						beginCellInfo["orientTable"]["offsetY"]) "R0" 1.0)) 
					endPoint = dbTransformPoint(cadr(endBbox) list(list(endCellInfo["orientTable"]["offsetX"]
						endCellInfo["orientTable"]["offsetY"]) "R0" 1.0)) 
				else
					startPoint = dbTransformPoint(car(endBbox) list(list(endCellInfo["orientTable"]["offsetX"]
						endCellInfo["orientTable"]["offsetY"]) "R0" 1.0))
					endPoint = dbTransformPoint( cadr(beginBbox) list(list(beginCellInfo["orientTable"]["offsetX"]
						beginCellInfo["orientTable"]["offsetY"]) "R0" 1.0))
				)
			)
			if(direction == "horizontal" then
				if(fdkCmp(caar(endBbox) ">" caar(beginBbox)) then
					startPoint = dbTransformPoint(car(beginBbox) list(list(beginCellInfo["orientTable"]["offsetX"]
						beginCellInfo["orientTable"]["offsetY"]) "R0" 1.0)) 
					endPoint = dbTransformPoint(cadr(endBbox) list(list(endCellInfo["orientTable"]["offsetX"]
						endCellInfo["orientTable"]["offsetY"]) "R0" 1.0)) 
				else
					startPoint = dbTransformPoint(car(endBbox) list(list(endCellInfo["orientTable"]["offsetX"]
						endCellInfo["orientTable"]["offsetY"]) "R0" 1.0))
					endPoint = dbTransformPoint(cadr(beginBbox) list(list(beginCellInfo["orientTable"]["offsetX"]
						beginCellInfo["orientTable"]["offsetY"]) "R0" 1.0))
				)
			)

			;; if the offset or delta keyed parameters are set to non-zero, the bBox needs to be modified
			;; delta parameters control the size of the drawn shape (operates on end point)
			;; offset parameters control the positioning of the drawn shape (operates on start point)
			endPoint = list(car(endPoint)+deltaX+offsetX cadr(endPoint)+deltaY+offsetY)	
			startPoint = list(car(startPoint)+offsetX cadr(startPoint)+offsetY)

			;; if optional netName parameter is non-nil, then a net name needs to be assigned to the
			;; shape
			validNetName = t
			if(netName then
				;; if the step count is greater than 1, we need to make sure that the netName parameter is
				;; a list with a number of elements equal to the number of steps
				if(fdkCmp(stepCount ">" 1) then
					if(fdkCmp(length(netName) "!=" stepCount) then
						validNetName = nil
						error("Net name array length does not match step count")
					)
				)
				enablePin = t
			else
				enablePin = nil
			)

			;; check for valid step parameters (only one of stepX or stepY can be non-zero)
			if(fdkCmp(stepX "!=" 0) && fdkCmp(stepY "!=" 0) then
				validStepParam = nil
				error("Stepping is only permitted in one direction at a time")
			else
				validStepParam = t
			)

			;; create shape and return the rod object
			when(validNetName && validStepParam
				rodShapeList = list()
				currStartPoint = startPoint
				currEndPoint = endPoint
				for(shape 1 stepCount
					if(netName then
						if(!listp(netName) then
							netNameList = list(netName)
						else
							netNameList = netName
						)
						currNetName = nthelem(shape netNameList)
					)

					rodShape = rodCreateRect(
						?cvId cvId
						?layer layer
						?bBox list(currStartPoint currEndPoint)
						?pin enablePin
						?netName currNetName
					)
					rodShapeList = append(rodShapeList list(rodShape))
					currStartPoint = dbTransformPoint(currStartPoint list(list(stepX stepY) "R0" 1.0))
					currEndPoint = dbTransformPoint(currEndPoint list(list(stepX stepY) "R0" 1.0))
				)
			)
		)

		rodShapeList
	)
)

procedure(fdkUpPropagateMosaicPins(arrayInfo cvId connect dontDrawList)
	let(
		(
			master libName cellName pinMap myPinMap currInstName 
			pinLayer currArrayElems netName startRow startCol
		)

		;; iterate over rows and columns until no more array cells are found
		for(currRow 1 arrayInfo["rows"]+2
			for(currCol 1 arrayInfo["cols"]+2
				currArrayElems = fdkUpGetCells(arrayInfo currRow currCol ?dontDrawList dontDrawList)
				;; if there are array elements found, then continue with propagation of 
				;; necessary pins on these instances
				when(currArrayElems
					foreach(elem currArrayElems
						
						;; for each element, push into the master, retreive all the 
						;; terminals and determine if it is in the pin map data structure
						master = elem["master"]	
						libName = master~>libName
						cellName = master~>cellName
						when(tablep(connect[libName][cellName])
							pinMap = connect[libName][cellName]["pinMap"]
							foreach(terminal master~>terminals
								myPinMap = car(exists(key pinMap (car(key) == terminal~>net~>name)))
								netName = nil
								when(myPinMap
									currInstName = elem["instName"]
									netName = cadr(myPinMap)
	
									;; loop through all the pins on the terminal
									foreach(pin terminal~>pins
										;; loop through all figures on pin and duplicate figure
										foreach(pinFig pin~>figs

											;; only propagate figure if it is a rect
                                            ;; this part has a problem if the pinLayer is not defined as a LPP
                                            ;;\w *WARNING* (ROD-1044) rodCreateRect: ?layer: layer and purpose are defined in the techfile, but they are not defined as a layer/purpose pair - ("sliE1" "drawing")t 
                                            if(pinFig~>objType == "rect" || pinFig~>objType == "pathSeg" then
												pinLayer = fdkPcLayer(sprintf(nil
													"%s:%s" car(pinFig~>lpp) cadr(pinFig~>lpp)))
												;fdkUpConnectShapes(arrayInfo cvId pinLayer
												;	currInstName pinFig currInstName 
												;	?netName netName ?dontDrawList dontDrawList)
												pinLl = dbTransformPoint(car(pinFig~>bBox) 
													list(list(elem["x"] elem["y"])
													elem["orientTable"]["orient"] 1.0))
												pinUr = dbTransformPoint(cadr(pinFig~>bBox) 
													list(list(elem["x"] elem["y"])
													elem["orientTable"]["orient"] 1.0))
												rodCreateRect(
													?cvId pcCellView
													?layer pinLayer
													?bBox list(pinLl pinUr)
													?pin t
													?netName netName
												)

											)
										)	
									)
								)
							)
						)
					)
				)
			)
		)

		t
	)
)
