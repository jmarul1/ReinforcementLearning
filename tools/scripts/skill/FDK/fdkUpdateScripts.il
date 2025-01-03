procedure(fdkBackupCellView(cvId)
	let(
		(
			currDateList origCellSuffix savedCvIdName (origSaved nil)
		)

        printf("Backing up original design ... ")
        currDateList = parseString(getCurrentTime())
        origCellSuffix = sprintf(nil "%s_%s_%s" 
            nth(0 currDateList) nth(1 currDateList) nth(3 currDateList))
        savedCvIdName = sprintf(nil "%s_%s" cvId~>cellName origCellSuffix)
        origSaved = dbSave(cvId libName savedCvIdName "layout")
        printf("Done.\n")

		origSaved
	)
)

procedure(fdkValidateCellView(libName cellName)
	let(
		(
			cvId (errorFlag nil)
		)

        ;; open layout cellview to be modified
        if(ddGetObj(libName cellName "layout") then
            cvId = dbOpenCellViewByType(libName cellName "layout" "maskLayout" "a")
            if(!cvId then
                errorFlag = t
            )
        else
            errorFlag = t
        )
        if(errorFlag then
            error("%s/%s/layout could not be opened for append" libName cellName)
        )

		cvId
	)
)

procedure(fdkUpdateGuardRingCell(libName cellName @key (keepOrig t))
	let(
		(
			grList cvId (srcLibName "intel22tech") originTable ddId propValue
		)

		;; define list of guard rings to be operated upon in cellview
		grList = list("n70ring" "n84ring" "n140ring" "n210ring" "p70ring" "p84ring"
			"p140ring" "p210ring")

		;; define a table specifying the required origin shift for each guardring based upon
		;; the cell name and the value of the defaultPolyExt property value
		originTable = makeTable("originTable" 0.0)
		foreach(cell grList
			when(ddId = ddGetObj(srcLibName cell)
				propValue = fdkGetProp(ddId "designRules:defaultPolyExt" ?meters nil)
				originTable[cell] = propValue
			)
		)

		;; validate cellview being requested exists and is able to be opened for edit
		cvId = fdkValidateCellView(libName cellName)

        ;; initialize data values needed for backing up original design
        ;; and save original design if properly opened
        if(keepOrig && cvId then
			origSaved = fdkBackupCellView(cvId)
        )

		printf("Beginning update of guardring instances ...\n")
        ;; search for all instances of a guardring
        when(keepOrig && origSaved || !keepOrig
            foreach(inst cvId~>instances

                ;; if the current instance is in the guardring list, make the
                ;; necessary changes
                when(member(inst~>cellName grList)
                    printf("  Updating %s (%s) ... " inst~>name inst~>cellName)

                    ;; move the origin the designated amount if moveOrigin_rel0.2 property
					;; doesn't exist
                    if(inst~>moveOrigin_rel0_2 == nil then

                        ;; move origin by designated amount
						currY = cadr(inst~>xy)
						currY = currY - originTable[inst~>cellName]
						inst~>xy = list(car(inst~>xy) currY)

						;; add a new property indicating this update has been applied so that
						;; it can't be applied again
						dbReplaceProp(inst "moveOrigin_rel0_2" "boolean" t)
                    )
                    printf("Done.\n")    
                )
            )
            printf("Saving updates ... ")
            dbSave(cvId)
            dbClose(cvId)
            printf("Done.\n")
        )

		t
	)
)

procedure(fdkUpdateTransRegionCell(libName cellName @key (keepOrig t))
    let(
        (
            currDateList origCellSuffix cvId (origSaved nil) inst
            trCellList enableTapsValue savedCvIdName (errorFlag nil)
        )

        ;; define list of transition regions to be operated upon in cellview
        trList = list("tr70to140" "tr70to210" "tr140to70" "tr210to70"
            "tr70to140_co" "tr70to140_ci" "tr70to210_co" "tr70to210_ci")

		;; validate cellview being requested exists and is able to be opened for edit
		cvId = fdkValidateCellView(libName cellName)

        ;; initialize data values needed for backing up original design
        ;; and save original design if properly opened
        if(keepOrig && cvId then
			origSaved = fdkBackupCellView(cvId)
        )
    
        printf("Beginning update of transition region instances ...\n")
        ;; search for all instances of a transition region 
        when(keepOrig && origSaved || !keepOrig
            foreach(inst cvId~>instances

                ;; if the current instance is in the transition region list, make the
                ;; necessary changes
                when(member(inst~>cellName trList)
                    printf("  Updating %s (%s) ... " inst~>name inst~>cellName)

                    ;; check for enableTaps property and operate on instance if it exists
                    enableTapsValue = inst~>enableTaps
                    when(enableTapsValue == "TRUE"

                        ;; set new tapOption parameter
                        inst~>tapOption = "both"

                        ;; remove old enableTaps property
                        dbDeletePropByName(inst "enableTaps")
                    )
                    printf("Done.\n")    
                )
            )
            printf("Saving updates ... ")
            dbSave(cvId)
            dbClose(cvId)
            printf("Done.\n")
        )
    
        t
    )
)

procedure(fdkSyncDG(@key (libName nil) (cellName nil) (refLib "inte22tech")
                         (refCell nil))
    let(
        (
            (validParams t) refLibId (refCellId nil) designLibId (cellId nil) refCellTable
            currSyncProp currCellName currCellId designCellList currDesignCell refCellListKeys
            gridParam gridValue elemNum currRefTable currDgParamName currDgParamValue
            currGeomParamName currGeomParamValue syncFlag instCounter
        )

        ;; verify presence of reference library that will be used to determine which
        ;; cell's parameters need to be synced
        refLibId = ddGetObj(refLib)
        printf("Validating input parameters ... ")
        if(!refLibId then
            fprintf(stderr "\n  Reference library %s not found." refLib)
            validParams = nil
        else
            ;; if refCell is nil, then reference all cells in the reference library
            ;; otherwise validate that specified cell exists
            when(refCell
                refCellId = ddGetObj(refLib refCell)
                when(!refCellId
                    fprintf(stderr "\n  Reference cell %s in library %s not found." refCell refLib)
                    validParams = nil
                )
            )
        )

        ;; a library name is required, validate that it exists
        designLibId = ddGetObj(libName)
        when(!designLibId
            if(!libName then
                fprintf(stderr "\n  Design library must be specified.")
                validParams = nil
            else
                fprintf(stderr "\n  Design library %s not found." libName)
                validParams = nil
            )
        )

        ;; cell name is not required, but if it is specified, validate that it exists
        when(cellName
            cellId = ddGetObj(libName cellName)
            when(!cellId
                fprintf(stderr "\n  Cell %s in library %s not found." cellName libName)
                validParams = nil
            )
        )

        if(validParams then
            printf("Done.\n")
        else
            printf("Invalid parameters encounterd - aborting.\n")
        ) 

        ;; when a valid set of parameters has been supplied, continue to synchronization process
        ;; on appropriate cells
        when(validParams
            ;; build reference cell table
            printf("Searching for source cells requiring attention in %s ...\n" refLib)
            refCellTable = makeTable('refCellTable nil)
            if(refCellId then
                currSyncProp = fdkGetProp(ddGetObj(refLib refCell) "designRules:syncDG")
                when(listp(currSyncProp)
                    refCellTable[refCell] = currSyncProp
                    printf("  %s\n" refCell)
                )
            else
                foreach(cell refLibId~>cells
                    currCellName = cell~>name
                    currCellId = ddGetObj(refLib currCellName)
                    currSyncProp = fdkGetProp(currCellId "designRules:syncDG")
                    when(listp(currSyncProp)
                        refCellTable[currCellName] = currSyncProp
                        printf("  %s\n" currCellName)
                    )
                )
            )
            printf("Done.\n\n")
            refCellListKeys = refCellTable->?

            ;; build list of designs that need to be synced
            designCellList = list()
            if(cellId then 
                designCellList = list(dbOpenCellViewByType(libName cellName "layout" "maskLayout" "a"))
            else
                foreach(cell ddGetObj(libName)~>cells
                    currDesignCell = dbOpenCellViewByType(libName cell~>name "layout" "maskLayout" "a")
                    when(currDesignCell
                        designCellList = append(designCellList list(currDesignCell))
                    )
                )
            )

            ;; iterate over each instance in each targeted design cell
            ;; if the instance has an entry in the reference cell table, synchronize
            ;; the parameter values using that table data
            foreach(cvId designCellList
                instCounter = 0
                printf("#########################################")
                printf("#########################################\n")
                printf("Analyzing %s/%s ...\n" cvId~>libName cvId~>cellName)
                foreach(inst cvId~>instances
                    currCellName = inst~>cellName
                    when(member(currCellName refCellListKeys)
                        syncFlag = nil
                        printf("  Checking instance %s/%s ... " inst~>name currCellName)

                        ;; found an instance that needs to be synced
                        ;; use data in refCellTable to synchronize values
                        currRefTable = refCellTable[currCellName]
                        gridParam = car(currRefTable)
                        gridValue = fdkGetProp(ddGetObj(refLib currCellName)
                            sprintf(nil "designRules:%s" gridParam) ?meters nil)

                        ;; after first value in list, the remaining values are pairs of values
                        ;; that need to be synced, DG parameter followed by geometric parameter
                        elemNum = 1
                        while(elemNum < length(currRefTable)
                            currDgParamName = nth(elemNum currRefTable)
                            currGeomParamName = nth(elemNum+1 currRefTable)
                            currDgParamValue = fdkProcessString(dbGet(inst currDgParamName))
                            currGeomParamValue = fdkProcessString(dbGet(inst currGeomParamName))
                      
                            ;; if DG param value and geometric param value are out of sync,
                            ;; synchronize them now
                            when(fdkCmp(currGeomParamValue "!=" currDgParamValue * gridValue)
                                syncFlag = t
                                printf("\n    Syncing %s value to %s value ... " currDgParamName
                                    currGeomParamName)
                                dbSet(inst sprintf(nil "%d" fix(round(currGeomParamValue/gridValue)))
                                    currDgParamName)
                                printf("Done.")
                            )
                            elemNum = elemNum + 2
                        )

                        when(syncFlag
                            instCounter = instCounter + 1
                        )
                        printf("\n")
                    )
                )
                printf("Summary for %s/%s: %d instances synced.\n" cvId~>libName cvId~>cellName
                    instCounter)
                dbSave(cvId)
                dbClose(cvId)
            )
        )
    
        t
    )
)
