;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Intel Top Secret, Intel Proprietary                                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copyright (C) 2011, Intel Corporation.  All rights reserved.             ;;
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  These are procedures in fdkGetProp.il which were replicated from the
; the original code in fdkPcCommon.il.  The actual implementation now
; for these will be done in fdkGetProp.il but the original procedure names
; will be kept for now in case there are pcells which use the fdkPc* 
; equivalents.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure(fdkPcScaleToMicrons( value @key (scale 1.0) (grid  0.0005))
    fdkScaleToMicrons(value ?scale scale ?grid grid)
) ; end procedure

procedure(fdkPcStringGetFormat(string)
    fdkStringGetFormat(string)
) ; end procedure

procedure(fdkPcStringToMicrons(string @key (scale 1e-6) (grid 0.5n))
    fdkProcessString(string ?scale scale ?grid grid ?meters nil)
) ; end procedure


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkPcMicronsToFormatString
;  reformats micron fp number into string
;  note that m means meters...but could also mean that
;  the number is a non micron, non nanometer number
;  and its reformating is based on scale
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; COMMENTED OUT - REMOVE BEFORE RELEASE IF NO
; DEPENDENCIES EXIST
;
;procedure(fdkPcMicronsToFormatString(microns format scale)
;    cond(
;        (format == "u" 
;            sprintf(nil "%4.9fu" microns)
;        ) 
;        (format == "n"
;            sprintf(nil "%4.9fn" (microns * 1000))
;        )
;        (format == "m"
;            sprintf(nil "%4.9f" (microns * scale))
;        )
;        (t nil)
;    )
;) ; end procedure


;procedure(fdkPcStringExternalSpacePurge(string)
;    fdkStringExternalSpacePurge(string)
;)

;procedure(fdkPcStringIsInteger(string)
;    fdkStringIsInteger(string)
;)

;procedure(fdkPcConvertPropValue(value @key (string nil) (aslist t))
;    fdkConvertPropValue(value ?string string ?aslist aslist ?meters nil)
;)

;procedure(fdkPcConvertBoolean(value)
;    fdkConvertBoolean(value)
;)

;procedure(fdkPcParsePropElements(value @key
;                (string nil)
;                                (boundLeft "{")
;                                (boundRight "}")
;                                (delimiter ","))
;    fdkParsePropElements(value ?string string
;                            ?meters nil
;                            ?boundLeft boundLeft
;                            ?boundRight boundRight
;                            ?delimiter delimiter)
;)
;
;procedure(
; fdkPcPrintTable(pV @key (level "  ") )
;    fdkPrintTable(pV ?level level)
;)
;
;procedure(
; fdkPcElementInTable(req pV @key (table 1) (hier 1))
;    fdkPcElementInTable(req pV ?table table ?hier hier ?meters nil)
;)
;
;procedure(
; fdkPcAppendPropTable(dbId @key (name "") (string nil) (pV nil) )
;    fdkAppendPropTable(dbId ?name name ?string string ?pV pV ?meters nil)
;)
;
;procedure(
; fdkPcGetPropTable(ddId @key (name "") (string nil) )
;    fdkGetPropTable(ddId ?name name ?string string ?meters nil)
;)
;
;procedure(
; fdkPcNoGetProp(ddId name @key (string nil) (boolean nil) )
;    ;no longer mirroring this as it exists within fdkGetProp
;    fdkGetProp(ddId name ?string string ?boolean boolean)
;)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                         PCELL Utilities
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkPcLayer
; Description: Converts a propertybag colon separated string into a LPP list
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkPcLayer(layer)
    let( (result)
        result = parseString(layer ":")
        if( (length(result)==1) then
            result = list(layer "drawing")
        )
        result
    )
) ; end procedure

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkPcStretchUserFunc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkPcStretchUserFunc(info)
    let((oldV min max scale)
        scale = info->userData->scale
        oldV = info->increment + fdkPcStringToMicrons(info->paramVal)/scale
        max = info->userData->max
        min = info->userData->min
        cond(
            ( oldV > max
                oldV = max
            )
            ( oldV < min
                oldV = min
            )
        )
        info->paramVal = sprintf(nil "%Lu" oldV)
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                fdkPcAddStretchHandleToRod
; Description: Adds a stretch handle to a rod object
;   These stretch handles use 'userData' to define the min, max and scale
; attributes on the stretch handle.
;   The names used on the arg list match the naming for PyCells.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkPcAddStretchHandleToRod(@key rodObj (userSnap 0.001) (maxVal 10000.0) (minVal 0.0) (moveOrigin nil) (userScale 1) parameter  (location 'lowerCenter)
 (direction "y") (stretchType 'relative) )
    rodAssignHandleToParameter(
        ?parameter          parameter
        ?rodObj             rodObj
        ?handleName         location
        ?stretchDir         direction
        ?stretchType        stretchType
        ?moveOrigin         moveOrigin
        ?updateIncrement    userSnap
        ?userFunction       'fdkPcStretchUserFunc
        ?userData           list( nil 'min minVal 'max maxVal 'scale userScale )
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkPcBuildRodsFromRod
; Description: 
;   copies rodObj so there are 'count' additional rod objects.
;   Each copy is the same size, type and layer as the original.
;   The alignment is offset by yOffset and xOffset.
;   Returns a list of the new rods.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(
  fdkPcBuildRodsFromRod(@key rodObj count namePrefix (startCount 1) (lastAlign "lowerLeft") (newAlign "lowerLeft") (yOffset 0) (xOffset 0) (delimiter "_") )
    let( (lastRod newRod rodsList)
        rodsList = list("OMIT")
        ;#get seed info
        lastRod = rodObj

        ;#copy and align
        for(r startCount ((count+startCount)-1)
            ;#copy the rod with new name
            newRod = rodNameShape(
                        ?name    sprintf(nil "%s%s%d" namePrefix delimiter r)
                        ?shapeId dbCopyShape(lastRod~>dbId rodObj~>cvId)
                     )
            ;#align the rod with previous rod
            rodAlign(
                ?alignObj           newRod
                ?alignHandle        newAlign
                ?refObj             lastRod
                ?refHandle          lastAlign
                ;?maintain           t
                ?xSep               xOffset
                ?ySep               yOffset
            )
            nconc(rodsList (list newRod))

            ;#prepare for next rod
            lastRod = newRod
        )
        cdr(rodsList)
    )
) ; end procedure

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkPcRepeatRodPath
; Description: 
;   creates a rod path, aligns to a refObj and then repeats it.
;   The default naming is the namePrefix.0 for the first
;   rod and then namePrefix.1, 2, 3... count. 
;   Returns a list of the new rods.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(
  fdkPcRepeatRodPath(@key count namePrefix layer length width (startCount 0) (lastAlign "lowerLeft") (newAlign "lowerLeft") (seedAlign "lowerLeft") (refAlign "lowerLeft") (yOffset 0) (xOffset 0) (refYOffset 0) (refXOffset 0) (refObj nil) (delimiter "_") )
    let( (points seedRod rodsList)
        ;#establish a list with a dummy object which will later be removed
        rodsList = list("OMIT")
        ;#create seed bbox
        points = list(
                    0:0
                    0:length
        )
        ;#create seed
        seedRod = rodCreatePath(
            ?name sprintf(nil "%s%s%d" namePrefix delimiter startCount)
            ?layer layer
            ?width width
            ?pts points
        )
        ;#generally want to align to an object, but
        ;#the first object will be the origin object so needs no
        ;#refObj, so by default refObj is nil and the rodAlign
        ;#is skipped...
        if( refObj != nil then
            rodAlign(
                ?alignObj seedRod
                ?alignHandle seedAlign
                ?refObj refObj
                ?refHandle refAlign
                ?xSep refXOffset
                ?ySep refYOffset
            )
        )
        ;#put the seedRod on the list
        nconc(rodsList (list seedRod))
        ;#create and align other rods based on the seedRod layer/bbox
        nconc(rodsList fdkPcBuildRodsFromRod(
            ?rodObj seedRod
            ?count count-1
            ?startCount startCount+1
            ?lastAlign lastAlign
            ?newAlign newAlign
            ?xOffset xOffset
            ?yOffset yOffset
            ?namePrefix namePrefix
            ?delimiter delimiter
        ))
        ;#return the list without the first dummy element
        cdr(rodsList)
    )
) ; end procedure

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkPcRepeatRodRect
; Description:
;   creates a rect path, aligns to a refObj and then repeats it.
;   The default naming is the namePrefix.0 for the first
;   rod and then namePrefix.1, 2, 3... count. 
;   Returns a list of the new rods.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(
  fdkPcRepeatRodRect(@key count namePrefix layer length width (startCount 0) (lastAlign "lowerLeft") (newAlign "lowerLeft") (seedAlign "lowerLeft") (refAlign "lowerLeft") (yOffset 0) (xOffset 0) (refYOffset 0) (refXOffset 0) (refObj nil) (delimiter "_") )
    let( (seedRod rodsList)
        ;#establish a list with a dummy object which will later be removed
        rodsList = list("OMIT")
        ;#create seed
        seedRod = rodCreateRect(
            ?name sprintf(nil "%s%s%d" namePrefix delimiter startCount)
            ?layer layer
            ?width width
            ?length length
        )
        ;#generally want to align to an object, but
        ;#the first object will be the origin object so needs no
        ;#refObj, so by default refObj is nil and the rodAlign
        ;#is skipped...
        if( refObj != nil then
            rodAlign(
                ?alignObj seedRod
                ?alignHandle seedAlign
                ?refObj refObj
                ?refHandle refAlign
                ?xSep refXOffset
                ?ySep refYOffset
            )
        )
        ;#put the seedRod on the list
        nconc(rodsList (list seedRod))
        ;#create and align other rods based on the seedRod layer/bbox
        nconc(rodsList fdkPcBuildRodsFromRod(
            ?rodObj seedRod
            ?count count-1
            ?startCount startCount+1
            ?lastAlign lastAlign
            ?newAlign newAlign
            ?xOffset xOffset
            ?yOffset yOffset
            ?namePrefix namePrefix
            ?delimiter delimiter
        ))
        ;#return the list without the first dummy element
        cdr(rodsList)
    )
) ; end procedure

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       Subroutine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;procedure(
;  fdkPcCopyStretchHandlesToRodsFromRod( seedRod number inc max min sca par @key (moveOrigin nil) (location 'lowerCenter) (dir "y") )
;    ;finds all rods by naming convention and creates stretch handles on each
;    let( (r name rname rod)
;        ;#get seed info
;        name = seedRod~>name
;        r = 1
;        ;#add stretch handles for each
;        while( (r < number)
;            ;#copy the rod with new name
;            rname = sprintf(nil "%s_%d" name r)
;            rod = rodGetObj(rname)
;            if( (rod == nil ) then
;                fprintf( stderr "Can't get rod named %L\n" rname )
;            else 
;                fdkPcAddStretchHandleToRod(
;                    ?rodObj rod
;                    ?userSnap inc 
;                    ?maxVal max 
;                    ?minVal min
;                    ?userScale sca
;                    ?parameter par
;                    ?location location
;                    ?moveOrigin moveOrigin
;                    ?direction dir
;                )
;            )
;            ;#prepare for next rod
;            r = r + 1
;        )
;    )
;) ; end procedure
;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkPcAttachPins
; Figures on the same pin are strongly connected
; Figures on different pins but on the same terminal are weakly connected
; Figures on terminals with different nets, and the terminals have the mustJoin
; attribute are must connect
; Figures on different terminals on the same net are shorted
;
; All figs in pinFigList will be strongly connected pinFigs (figs on same pin)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkPcAttachPins(@key cellView netName pinName termDirection pinAccessDir pinFigList)
    let( (net term index newPin)
        term=dbFindTermByName(cellView netName)
        if( (term == nil) then
            net=dbFindNetByName(cellView netName)
            if( (net == nil) then
                net = dbCreateNet(cellView netName)
            )
            term = dbCreateTerm(net netName termDirection)
        else
            net=dbFindNetByName(cellView netName)
        )
        index=0
        foreach(pinFig pinFigList
            if( (index==0) then
                newPin=dbCreatePin(net pinFig pinName)
            else
                dbAddFigToPin(newPin pinFig)
            )
            dbSetPinFigAccessDirection(pinFig pinAccessDir)
            index=index+1
        )
        newPin   ;return new pin

    )
) ; end procedure

procedure(fdkPcMergeLayers(cvId @key (shapeList nil) (include list()) (exclude list()))
    let(
        (
            (layerMergeList list()) layerShapeList currLayer currPurpose 
            includeList excludeList shapes mergedShapes (deletedShapes list())
        )

        ;; determine which shapes should be operated on
        ;; when shapeList is not defined (nil), all shapes from cvId are used
        shapes = shapeList || cvId~>shapes

        ;; determine which layers from shapes should be merged
        ;; include = empty list, exclude = empty list => all layers are merged
        ;; include = a, exclude = empty list => layers in list a are merged
        ;; only one of include or exclude should be a non-empty list

        ;; convert user specified include/exclude lists into common format
        includeList = mapcar('fdkPcLayer include)
        excludeList = mapcar('fdkPcLayer exclude)

        ;; find superset of possible layers to merge based on include parameter
        if(!include then

            ;; all layer/purpose pairs from the cellview should be merged
            foreach(lpp cvId~>lpps
                currLpp = fdkPcLayer(sprintf(nil "%s:%s" lpp~>layerName lpp~>purpose))
                when(!member(currLpp layerMergeList)
                    layerMergeList = cons(currLpp layerMergeList)
                )
            )
        else

            ;; only the layer/purpose pairs from the user specified include
            ;; parameter should be merged
            layerMergeList = includeList
        )

        ;; if exclude is non-nil then remove these layers from those to be merged
        when(exclude
            layerMergeList = setof(layer layerMergeList !member(layer excludeList))
        )

        ;; iterate over each layer to be merged, find all the shapes from
        ;; shape list, merge those shapse, and form a list of shapes to delete
        foreach(layer layerMergeList
            currLayer = car(layer)
            currPurpose = cadr(layer)
            layerShapeList = setof(s shapes 
                (s~>layerName == currLayer && s~>purpose == currPurpose))
            mergedShapes = dbLayerOr(cvId layer layerShapeList)
            foreach(shape layerShapeList
                deletedShapes = cons(shape deletedShapes)
            )
        )

        ;; delete all the shapes marked for deletion    
        foreach(shape deletedShapes
            dbDeleteObject(shape)
        )

        t
    )
)

procedure(fdkPcSetOrigin(cvId originShape originHandle @key (offsetX 0) (offsetY 0))
    let(
        (rodOriginShape originCoord)

        rodOriginShape = rodGetObj(originShape cvId)
        when(rodOriginShape &&
            member(originHandle list("upperLeft" "upperCenter" "upperRight"
                "lowerLeft" "lowerCenter" "lowerRight" "centerLeft" "centerCenter" "centerRight"))
            originCoord = rodGetHandle(rodOriginShape originHandle)
            foreach(shape cvId~>shapes
                  dbMoveShape(shape cvId
                      list(-car(originCoord)+offsetX:-cadr(originCoord)+offsetY "R0" 1)
                  )
            )
        )
        t
    )
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       Subroutine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(  fdkPcGetRodGroupBbox(rodList)
    let( (bbox rodBox minX minY maxX maxY)
        bbox= makeTable("bbox")
        minX=nil
        minY=nil
        maxX=nil
        maxY=nil
        foreach(rodObj rodList
            rodBox = rodObj~>dbId~>bBox 
            if( minX == nil || fdkCmp(leftEdge(rodBox) "<" minX) then
                minX=leftEdge(rodBox)
            )
            if( maxX == nil || fdkCmp(rightEdge(rodBox) ">" maxX) then
                maxX=rightEdge(rodBox)
            )
            if( minY == nil || fdkCmp(bottomEdge(rodBox) "<" minY) then
                minY=bottomEdge(rodBox)
            )
            if( maxY == nil || fdkCmp(topEdge(rodBox) ">" maxY) then
                maxY=topEdge(rodBox)
            )
       )
       bbox["left"]=minX
       bbox["right"]=maxX
       bbox["bottom"]=minY
       bbox["top"]=maxY
       bbox["width"]=maxX-minX
       bbox["length"]=maxY-minY

       bbox
    )
) ; end procedure

procedure(fdkPcAlignShapes(@key alignGroup (alignName nil) alignHandle 
                                (refGroup nil) (refName nil) (refHandle nil)
                                  (refPoint nil) 
                                (offsetX 0.0) (offsetY 0.0) (alignDir "xy"))
    let(
        (
            alignGroupList refGroupList
            alignBbox alignCoord refBbox refCoord
            refCoordX refCoordY refObj groupBoxTable
            (totalOffsetX 0.0) (totalOffsetY 0.0)
            alignX alignY (returnAlignGroup list())
        )

        ;; if reference point is being used, refGroup, refName, and
        ;; refHandle are all irrelevant and should be nil
        if(refPoint && 
            (refGroup || refName || refHandle) then 
            artWarn("When reference point is used, other reference parameters are ignored")
        )

        ;; determine if alignment is occurring in horizontal, vertical, or
        ;; both directions
        if(index(lowerCase(alignDir) "x") then
            alignX = t
        else
            alignX = nil
        )
        if(index(lowerCase(alignDir) "y") then
            alignY = t
        else
            alignY = nil
        )

        ;; if the alignGroup is not a list, make it one
        if(listp(alignGroup) then
            alignGroupList = alignGroup
        else
            alignGroupList = list(alignGroup)
        )
        returnAlignGroup = append(returnAlignGroup alignGroupList)


        ;; find the reference points for both the alignment shapes and
        ;; the reference shapes by drawing a rectangle around the 
        ;; associated group of shapes (alignGroup or refGroup) and finding
        ;; the reference coordinates specified by the appropriate
        ;; handle (alignHandle or refHandle)
        ;; after retrieveing the coordinates, delete the reference shape
        if(!alignName then
               ;groupBoxTable=fdkPcGetRodGroupBbox(alignGroupList)
               alignBbox = rodCreateRect(
                ?layer "y0"
                ;?length groupBoxTable["length"]
                ;?width  groupBoxTable["width"]
                ;?origin 0:0
				?fromObj alignGroupList
                ?cvId car(alignGroupList)~>cvId
               )
               alignCoord = rodGetHandle(alignBbox alignHandle)
            dbDeleteObject(alignBbox~>dbId)
        else
            alignCoord = rodGetHandle(rodGetObj(alignName) alignHandle)
        )

        if(refPoint then
            refCoord = refPoint
        else
            if(!refName then
                ;; if the refGroup is not a list , make it one
                if(listp(refGroup) then
                    refGroupList = refGroup
                else
                    refGroupList = list(refGroup)
                )
                returnAlignGroup = append(returnAlignGroup refGroupList)
                if(refGroupList==nil then
                    fprintf(stderr "ERROR: fdkPcAlignShapes: refGroup is:%L alignGroupis %L \n" refGroup alignGroup)
                    if(!listp(alignGroup) then
                        fprintf(stderr "alignGroup rod name is %L\n" alignGroup->name) 
                    )
                )

                refBbox = rodCreateRect(
                    ?layer "y0"
                    ?fromObj refGroupList
                    ?cvId car(refGroupList)~>cvId
                )
                refCoord = rodGetHandle(refBbox refHandle)
                dbDeleteObject(refBbox~>dbId)
            else
                refObj = rodGetObj(refName)
                returnAlignGroup = append(returnAlignGroup list(refObj))
                refCoord = rodGetHandle(refObj refHandle)
            )
        )
        refCoordX = car(refCoord)
        refCoordY = cadr(refCoord)

        ;; for each shape in the align group, create a new alignment based
        ;; upon the established reference points (alignCoord and refCoord)
        ;; and separation parameters
        foreach(shape alignGroupList
            when(alignX
                totalOffsetX = refCoordX - car(alignCoord) + offsetX
            )
            when(alignY

                totalOffsetY = refCoordY - cadr(alignCoord) + offsetY
            )
            dbMoveShape(shape~>dbId pcCellView list(totalOffsetX:totalOffsetY "R0" 1))
        )

        returnAlignGroup
    )
)

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; The following procedures moved from guardring_subs.il fdkPcCommon
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; Start guardring_subs.il

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkPcGetBboxOfGroup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkPcGetBboxOfGroup(objectGroup)
    let(((llx nil) (lly nil) (urx nil) (ury nil) (firstFlag 1))
        foreach( ob objectGroup
            if( (firstFlag ==1) then
                llx=leftEdge(ob->dbId)
                lly=bottomEdge(ob->dbId)
                urx=rightEdge(ob->dbId)
                ury=topEdge(ob->dbId)
                firstFlag=0
            else
                llx=min(llx leftEdge(ob->dbId))
                lly=min(lly bottomEdge(ob->dbId))
                urx=max(urx rightEdge(ob->dbId))
                ury=max(ury topEdge(ob->dbId))
            )
        )
        list(list(llx lly) list(urx ury))
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkPcRemoveObjects
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkPcRemoveObjects(objectGroup)
    foreach( ob objectGroup
            dbDeleteObject( ob->dbId )
    )
    t
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkPcGroupOmitLayersByNames
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkPcGroupOmitLayersByNames(group layerNames)
    let(( newgroup rodLayerName)
        newgroup = list()
        foreach( rod group
            rodLayerName = rod->dbId->layerName
            if( member(rodLayerName layerNames) == nil then
                newgroup = append1(newgroup rod)
            )
        )
        newgroup
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkPcGroupIncludeLayersByNames
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkPcGroupIncludeLayersByNames(group layerNames)
    let(( newgroup rodLayerName)
        newgroup = list()
        foreach( rod group
            rodLayerName = rod->dbId->layerName
            if( member(rodLayerName layerNames) != nil then
                newgroup = append1(newgroup rod)
            )
        )
        newgroup
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkPcGetHeightForLayerNames
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkPcGetHeightForLayerNames(layerNames)
    let((group layergroup bbox)
        group=rodGetNamedShapes()
        layergroup=fdkPcGroupIncludeLayersByNames(group layerNames)
        bbox=fdkPcGetBboxOfGroup(layergroup)
        (topEdge(bbox)-bottomEdge(bbox))
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       fdkPcRodsGetSpacing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
procedure(fdkPcRodsGetSpacing( rod1 edgetype1 rod2 edgetype2)
    ; edgetype(top bottom left right) determines which ordinate to check
    ; then gets distance between edges or nil if edgetypes don't match
    let((eOrd1 eOrd2 ob1 ob2 ord1 ord2 spacing
        stderr
        )
        eOrd1=nil
        eOrd2=nil
        if( edgetype1=="top" || edgetype1=="bottom" then
            eOrd1=1
        else
            if( edgetype1=="left" || edgetype2== "right" then
                eOrd1=0
            )
        )
        if( edgetype2=="top" || edgetype2=="bottom" then
            eOrd2=1
        else
            if( edgetype2=="left" || edgetype2== "right" then
                eOrd2=0
            )
        )
        if( eOrd1 == eOrd2 && eOrd1 != nil then
            ob1=rod1->dbId
            ob2=rod2->dbId
            if( eOrd1 == 0 then
                if( edgetype1=="left" then
                    ord1=leftEdge(ob1)
                else
                    ord1=rightEdge(ob1)
                )
                if( edgetype2=="left" then
                    ord2=leftEdge(ob2)
                else
                    ord2=rightEdge(ob2)
                )
            else
                if( edgetype1=="top" then
                    ord1=topEdge(ob1)
                else
                    ord1=bottomEdge(ob1)
                )
                if( edgetype2=="top" then
                    ord2=topEdge(ob2)
                else
                    ord2=bottomEdge(ob2)
                )
            )
            spacing=max(ord1 ord2) - min(ord1 ord2)
        else
            fprintf(stderr "spacing nil...et1:%L eOrd1:%L\n" edgetype1 eOrd1)
            fprintf(stderr " et2:%L eOrd2:%L\n" edgetype2 eOrd2)
            spacing=nil

        )
        spacing
    )
)

procedure(fdkPcAlignMultShapes(@key alignObj refObjX alignDirX refDirX 
            refObjY alignDirY refDirY (offsetX 0) (offsetY 0) (grid 0.001))
    let(
        (
            (validRodObjs t) alignHandle refObjBoxX refObjBoxY refPtX refPtY
        )

        ;; check that all rod objects exist
        unless(rodIsObj(alignObj) && rodIsObj(refObjX) && rodIsObj(refObjY)
            fprintf(stderr "Alignment and/or reference shapes are not valid ROD objects.\n")
            validRodObjs = nil
        )

        ;; if rod objects have been verified, continue with alignment
        when(validRodObjs
            ;; get alignment handle based upon alignDirX and alignDirY
            cond(
                (lowerCase(alignDirX) == "east"
                    cond(
                        (lowerCase(alignDirY) == "north"
                            alignHandle = "upperRight"
                        )
                        (lowerCase(alignDirY) == "south"
                            alignHandle = "lowerRight"
                        )
                        (lowerCase(alignDirY) == "north_south"
                            alignHandle = "centerRight"
                        )
                        (t
                            alignDir = nil
                        )
                    )
                )
                (lowerCase(alignDirX) == "west"
                    cond(
                        (lowerCase(alignDirY) == "north"
                            alignHandle = "upperLeft"
                        )
                        (lowerCase(alignDirY) == "south"
                            alignHandle = "lowerLeft"
                        )
                        (lowerCase(alignDirY) == "north_south"
                            alignHandle = "centerLeft"
                        )
                        (t
                            alignDir = nil
                        )
                    )
                )
                (lowerCase(alignDirX) == "east_west"
                    cond(
                        (lowerCase(alignDirY) == "north"
                            alignHandle = "upperCenter"
                        )
                        (lowerCase(alignDirY) == "south"
                            alignHandle = "lowerCenter"
                        )
                        (lowerCase(alignDirY) == "north_south"
                            alignHandle = "centerCenter"
                        )
                        (t
                            alignDir = nil
                        )
                    )
                )
                (t
                    alignHandle = nil
                )
            )

            ;; obtain reference point in x and y dimensions before performing alignment
            refObjBoxX = refObjX~>dbId~>bBox
            refObjBoxY = refObjY~>dbId~>bBox
            cond(
                (lowerCase(refDirX) == "east"
                    refPtX = caadr(refObjBoxX)
                ) 
                (lowerCase(refDirX) == "west"
                    refPtX = caar(refObjBoxX)
                ) 
                (lowerCase(refDirX) == "east_west"
                    refPtX = fdkSnapGrid(grid (caadr(refObjBoxX)+caar(refObjBoxX))/2.0)
                ) 
                (t
                    refPtX = nil
                )
            )
            cond(
                (lowerCase(refDirY) == "north"
                    refPtY = cadadr(refObjBoxY)
                ) 
                (lowerCase(refDirY) == "south"
                    refPtY = cadar(refObjBoxY)
                ) 
                (lowerCase(refDirY) == "north_south"
                    refPtY = fdkSnapGrid(grid (cadadr(refObjBoxY)+cadar(refObjBoxY))/2.0)
                ) 
                (t
                    refPtY = nil
                )
            )

            ;; perform final alignment when alignHandle refPtX and refPtY are all non-nil
            if(alignHandle && refPtX && refPtY then
                rodAlign(
                    ?alignObj alignObj
                    ?alignHandle alignHandle
                    ?refPoint list(refPtX refPtY)
                    ?xSep offsetX
                    ?ySep offsetY
                    ?maintain nil
                )
            else
                fprintf(stderr "Invalid alignment or reference direction specified.\n")
            )
        )

        t
    )
)

procedure(validPolygonPtList(ptList)
    let(
        (
            origList newList flagTable
            (returnValue t)
        )

        origList = ptList
        newList = car(dbPointArraySize(pcCellView list(ptList) 0))
        flagTable = makeTable('flagTable nil)
        foreach(elem origList
            flagTable[elem] = t
        )
        foreach(elem newList
            flagTable[elem] = nil
        ) 

        foreach(key flagTable~>?
            when(flagTable[key] == t
                returnValue = nil
            )
        )

        returnValue
    )
)
