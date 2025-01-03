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
;                         Template PCELL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure( fdkCreateSymmInd( pcCellView drTable paramTable)
  let( ( adddummyfill centertap ctType jumpType nrturns origBbox 
    ptList solver3d stapleList termType toplayer)

    ;; Retrieve parameters from table
    nrturns = paramTable["nrturns"] = pcFix( paramTable["nrturns"])
    toplayer = paramTable["toplayer"]
    centertap = paramTable["centertap"]
    solver3d = paramTable["solver3d"]
    ctType = drTable["layer"][toplayer]["ctType"]
    adddummyfill = paramTable["adddummyfill"]
    jumpType = drTable["layer"][toplayer]["jumpType"]
    stapleList = drTable["layer"][toplayer]["stapleList"]
    termType = drTable["layer"][toplayer]["ctType"]
    when( solver3d == "Yes" && termType != "OneMetalStraight"
      paramTable["solver3d"] = "No")

    ;; When adding fill, calculate the bounding box of the fill
    ;; and update the terminal extension to create coincidental
    ;; terminal ends to the edge of fill
    when( adddummyfill == "Yes"
      origBbox = fdkResetIndTermExtForFill( pcCellView paramTable drTable)
    ) ;; when

    ;; Generate main path point list
    ptList = fdkGenIndMainPtList( drTable paramTable)

    ;; Use point list to generate main path 
    fdkDrawIndBody( pcCellView drTable paramTable ptList)

    ;; Draw bridge on inner coil
    fdkDrawIndBridge( pcCellView drTable paramTable)

    ;; When inductor has more than one coil, generate jumps
    when( nrturns > 1
      case( jumpType
        ("StapleArray"
          fdkDrawIndJumps_StapleArray( pcCellView drTable paramTable))
        ("IndVias"
          fdkDrawIndJumps_IndVias( pcCellView drTable paramTable))
      ) ;; case
    ) ;; when

    ;; Create staples as specified in stapleList
    drTable["idShape5bBox"] = nil
    fdkDrawIndStaples( pcCellView drTable paramTable 
      ?drawStapleArray member( "jump" stapleList) 
      ?drawStapleBody member( "body" stapleList)
      ?drawStapleTerm member( "terminal" stapleList))

    ;; Create centertap when specified by the user
    when( centertap == "Yes"
      case( ctType
        ("OneMetalStraight"
          fdkDrawIndCentertap_OneMetalStraight( pcCellView 
            drTable paramTable))
        ("TwoMetalStraight"
          fdkDrawIndCentertap_TwoMetalsStraight( pcCellView
            drTable paramTable))
        ("OneMetalBubble"
          fdkDrawIndCentertap_OneMetalBubble( pcCellView
            drTable paramTable))
      ) ;; case
    ) ;; when

    ;; Create terminal pins
    fdkDrawIndTermPins( pcCellView drTable paramTable)

    ;; Add fill when specified by the user
    when( adddummyfill == "Yes"
      fdkFillIndShape( pcCellView drTable origBbox)
    ) ;; when

    ;; Add ID Shapes
    fdkDrawIDShapes( pcCellView drTable paramTable)

    ;; Add VID Shapes
    fdkDrawVIDShapes( pcCellView drTable)

  )
)

procedure( fdkCreateSpiralInd( pcCellView drTable paramTable)
  let( ( adddummyfill origBbox ptList spiralTermType
    stapleList toplayer)

    ;; Retrieve parameters from table
    toplayer = paramTable["toplayer"]
    spiralTermType = drTable["layer"][toplayer]["spiralTermType"]
    adddummyfill = paramTable["adddummyfill"]
    stapleList = drTable["layer"][toplayer]["stapleList"]
    paramTable["termextJump"] = paramTable["termext"]

    ;; When adding fill, calculate the bounding box of the fill
    ;; and update the terminal extension to create coincidental
    ;; terminal ends to the edge of fill
    when( adddummyfill == "Yes"
      origBbox = fdkResetSpiralIndTermExtForFill( pcCellView 
        paramTable drTable)
    ) ;; when

    ;; Generate main path point list
    ptList = fdkGenSpiralIndMainPtList( drTable paramTable)

    ;; Use point list to generate main path 
    fdkDrawIndBody( pcCellView drTable paramTable ptList)

    ;; Create staples as specified in stapleList
    drTable["idShape5bBox"] = nil
    when( spiralTermType == "OneMetalStraight" stapleList = nil)
    fdkDrawIndStaples( pcCellView drTable paramTable 
      ?drawStapleArray member( "jump" stapleList) 
      ?drawStapleBody member( "body" stapleList)
      ?drawStapleTerm member( "terminal" stapleList))

    ;; Create outer terminal crossover
    case( spiralTermType
      ("OneMetalStraight"
        fdkDrawSpiralIndTerm_OneMetalStraight( pcCellView 
          drTable paramTable))
      ("OneMetalStraightIndVias"
        fdkDrawSpiralIndTerm_OneMetalStraightIndVias( pcCellView 
          drTable paramTable))
      ("TwoMetalStraight"
        fdkDrawSpiralIndTerm_TwoMetalsStraight( pcCellView
          drTable paramTable))
    ) ;; case

    ;; Create terminal pins
    fdkDrawIndTermPins( pcCellView drTable paramTable)

    ;; Add fill when specified by the user
    when( adddummyfill == "Yes"
      fdkFillIndShape( pcCellView drTable origBbox)
    ) ;; when

    ;; Add ID Shapes
    fdkDrawSpiralIDShapes( pcCellView drTable paramTable)

    ;; Add VID Shapes
    fdkDrawVIDShapes( pcCellView drTable)

  )
)

procedure( fdkGenIndMainPtList( drTable paramTable)
  let(( coilspcx coilwx coilwxHalf innerwx innerwxHalf innerwy innerwyHalf
    jumpSpaceHalf minGrid nrturns ptList ptListB ptListL ptListR ptListT 
    spcJump spcTerm termext termside termspc termspcHalf turnPitch x 
    xOffset y yOffset)

    ; Retrieve parameters and design rules from tables
    nrturns = paramTable["nrturns"]
    innerwx = paramTable["innerwx"]
    innerwy = paramTable["innerwy"]
    coilwx = paramTable["coilwx"]
    coilspcx = paramTable["coilspcx"]
    termext = paramTable["termext"]
    termspc = paramTable["termspc"]
    termside = paramTable["termside"]
    minGrid = drTable["minGrid"]

    ;; Do base calculations
    jumpSpaceHalf = fdkSnapGrid( minGrid (coilwx+2*coilspcx)*0.5)
    innerwxHalf = fdkSnapGrid( minGrid innerwx*0.5)
    innerwyHalf = fdkSnapGrid( minGrid innerwy*0.5)
    coilwxHalf = fdkSnapGrid( minGrid coilwx*0.5)
    termspcHalf = fdkSnapGrid( minGrid termspc*0.5)
    turnPitch = coilwx+coilspcx
    xOffset = innerwxHalf+coilwxHalf
    yOffset = innerwyHalf+coilwxHalf
    spcJump = jumpSpaceHalf
    spcTerm = termspcHalf+coilwxHalf

    ;; Create point list for two halfs of each turn
    ;; depending on the terminal side
    if( termside == "Top" || termside == "Bottom" then

      ;; For inductor with terminals on the top or bottom
      ;; create a left half and a right half for each turn
      for( turn 1 nrturns

        x = xOffset
        y = yOffset

        ;; Point list will be clockwise
        ;; Calculate left half from bottom to top
        ptListL = list( -spcJump:-y -x:-y -x:y -spcJump:y)
        ;; Calculate right half from top to bottom
        ptListR = list( spcJump:y x:y x:-y spcJump:-y)

        ;; Add terminal points if processing last turn
        when( turn == nrturns
          if( termside == "Top" then
            ptListL = append( remove( -spcJump:y ptListL) 
              list( -spcTerm:y -spcTerm:y+termext+coilwxHalf))
            ptListR = append( list( spcTerm:y+termext+coilwxHalf
              spcTerm:y) cdr( ptListR))
          else ;; termside == "bottom"
            ptListL = append( list( -spcTerm:-y-termext-coilwxHalf
              -spcTerm:-y) cdr( ptListL))
            ptListR = append( remove( spcJump:-y ptListR)
              list( spcTerm:-y spcTerm:-y-termext-coilwxHalf))
          ) ;; if
        ) ;; when

        ptList = cons( ptListL ptList)
        ptList = cons( ptListR ptList)

        xOffset = xOffset+turnPitch
        yOffset = yOffset+turnPitch
      ) ;; for

    else ;; termside == "left" || "right"

      ;; For inductor with terminals on the left or right
      ;; create a bottom half and a top half for each turn
      for( turn 1 nrturns

        x = xOffset
        y = yOffset

        ;; Point list will be counter-clockwise
        ;; Calculate bottom half from left to right
        ptListB = list( -x:-spcJump -x:-y x:-y x:-spcJump)
        ;; Calculate top half from right to left
        ptListT = list( x:spcJump x:y -x:y -x:spcJump)

        ;; Add terminal points if processing last turn
        when( turn == nrturns
          if( termside == "Right" then
            ptListB = append( remove( x:-spcJump ptListB)
              list( x:-spcTerm x+termext+coilwxHalf:-spcTerm))
            ptListT = append( list( x+termext+coilwxHalf:spcTerm
              x:spcTerm) cdr( ptListT))
          else ;; termside == "left"
            ptListB = append( list( -x-termext-coilwxHalf:-spcTerm
              -x:-spcTerm) cdr( ptListB))
            ptListT = append( remove( -x:spcJump ptListT)
              list( -x:spcTerm -x-termext-coilwxHalf:spcTerm))
          ) ;; if
        ) ;; when

        ptList = cons( ptListB ptList)
        ptList = cons( ptListT ptList)

        xOffset = xOffset+turnPitch
        yOffset = yOffset+turnPitch
      ) ;; for

    ) ;; if
    reverse( ptList) ;; Return value
  )
)

procedure( fdkGenSpiralIndMainPtList( drTable paramTable)
  let(( coilspcx coilwx coilwxHalf fTurn hTurn innerwx 
    innerwxHalf innerwy innerwyHalf minGrid nrturns 
    nrturnsInt newPtList ptList qTurn termext termside 
    tqTurn turnCtr turnPitch xCtr yCtr)

    ; Retrieve parameters and design rules from tables
    nrturns = paramTable["nrturns"]
    innerwx = paramTable["innerwx"]
    innerwy = paramTable["innerwy"]
    coilwx = paramTable["coilwx"]
    coilspcx = paramTable["coilspcx"]
    termext = paramTable["termext"]
    termside = paramTable["termside"]
    minGrid = drTable["minGrid"]

    ;; Do base calculations
    nrturnsInt = pcFix( nrturns)
    innerwxHalf = fdkSnapGrid( minGrid innerwx*0.5)
    innerwyHalf = fdkSnapGrid( minGrid innerwy*0.5)
    coilwxHalf = fdkSnapGrid( minGrid coilwx*0.5)
    turnPitch = coilwx+coilspcx

    ;; Calculate location of outer terminal
    yCtr = -(innerwyHalf+coilwx+(nrturnsInt-1)*turnPitch+termext)
    xCtr = -(innerwxHalf+coilwxHalf+(nrturnsInt-1)*turnPitch+
      if( nrturns-nrturnsInt > minGrid turnPitch 0))
    ptList = list( xCtr:yCtr)

    ;; Calculate points for turns
    fTurn = abs( nrturns-nrturnsInt) < minGrid ;; Full turn
    qTurn = abs( nrturns-nrturnsInt-0.25) < minGrid ;; Quarter turn
    hTurn = abs( nrturns-nrturnsInt-0.5) < minGrid ;; Half turn
    tqTurn = abs( nrturns-nrturnsInt-0.75) < minGrid ;; Three quarter turn
    for( i 0 nrturnsInt
      turnCtr = nrturnsInt-i
      ;; Upper left pt
      unless( zerop( turnCtr) && fTurn
        yCtr = innerwyHalf+cond(
          ( qTurn && zerop( turnCtr) -coilspcx)
          ( qTurn || fTurn coilwxHalf+(turnCtr-1)*turnPitch)
          ( t     coilwxHalf+turnCtr*turnPitch))
        ptList = cons( xCtr:yCtr ptList)
      ) ;; unless
      ;; Upper right pt
      unless( zerop( turnCtr) && (fTurn || qTurn)
        xCtr = innerwxHalf+cond(
          ( hTurn && zerop( turnCtr) -coilspcx)
          ( tqTurn coilwxHalf+turnCtr*turnPitch)
          ( t      coilwxHalf+(turnCtr-1)*turnPitch))
        ptList = cons( xCtr:yCtr ptList)
      ) ;; unless
      ;; Lower right pt
      unless( zerop( turnCtr) && (fTurn || qTurn || hTurn)
        yCtr = -innerwyHalf-cond(
          ( tqTurn && zerop( turnCtr) -coilspcx)
          ( t       coilwxHalf+(turnCtr-1)*turnPitch))
        ptList = cons( xCtr:yCtr ptList)
      ) ;; unless
      ;; Lower left pt
      unless( zerop( turnCtr)
        xCtr = -innerwxHalf-cond(
          ( fTurn && onep( turnCtr) -coilspcx)
          ( fTurn  coilwxHalf+(turnCtr-2)*turnPitch)
          ( t      coilwxHalf+(turnCtr-1)*turnPitch))
        ptList = cons( xCtr:yCtr ptList)
      ) ;; unless
    ) ;; for

    ;; Transform the point list if terminal not bottom
    unless( termside == "Bottom"
      foreach( pt ptList 
        newPtList = cons( dbTransformPoint( pt list( 0:0 
          case( termside ("Right" "R90") ("Top" "R180") ("Left" "R270"))))
          newPtList)
      ) ;; foreach
      ptList = reverse( newPtList)
    ) ;; unless

    list( reverse( ptList)) ;; Return value
  )
)


procedure( fdkDrawIndBody( pcCellView drTable paramTable ptList)
  let(( bodyLayers bottomlayer indShape layerList mainOffset maxWidth 
    minGrid minSpace nrturns numSig offsetPathList pitch
    remainingSpace1 remainingSpace2 runningOffset side sigSpace 
    sigWidth toplayer turnA turnB turnCtr turnName usedSpace width)

    ;; Retrieve parameters from table
    toplayer = paramTable["toplayer"]
    width = paramTable["coilwx"]
    nrturns = paramTable["nrturns"]
    indShape = paramTable["indShape"]

    ;; Retrieve design rules from table
    minGrid = drTable["minGrid"]
    layerList = drTable["layer"][toplayer]["layers"]
    bottomlayer = cadr( layerList)
    bodyLayers = drTable["layer"][toplayer]["bodyLayers"]

    ;; Process each layer in the inductor
    foreach( layerName layerList
      layerName = fdkPcLayer( layerName)
      minSpace = drTable["layer"][car( layerName)]["minSpace"]
      maxWidth = drTable["layer"][car( layerName)]["maxWidth"]
      turnCtr = 1
      side = "A"

      ;; Determine whether layer is slotted or not
      if( width <= maxWidth then
        sigWidth = width
        mainOffset = 0
      else ;; slotted layer
        ;; Recalculate signal spacing by subtracting total individual
        ;; signal width (numSig*maxWidth) from coil width.  Using newly
        ;; calculated signal spacing value, calculate remaining space 
        ;; and divide by two to 'stuff' difference between the
        ;; the 'topmost' signal and adjacent, and the 'bottommost' 
        ;; signal and adjacent.
        sigWidth = maxWidth
        numSig = pcFix( (width-sigWidth)/(sigWidth+minSpace))+1
        usedSpace = numSig*sigWidth
        sigSpace = fdkSnapDownGrid( minGrid (width-usedSpace)/(numSig-1))
        remainingSpace1 = fdkSnapGrid( minGrid
          (width-numSig*sigWidth-(numSig-1)*sigSpace)*0.5)
        remainingSpace2 = width-numSig*sigWidth-(numSig-1)*sigSpace-
          remainingSpace1
        pitch = sigWidth+sigSpace
        mainOffset = fdkSnapGrid( minGrid (width-sigWidth)*0.5)
        runningOffset = pitch+remainingSpace1

        ;; Calculate offset value for 'inside' signal.  The first signal
        ;; will be the main path.  The last signal will be calculated
        ;; separately to accoung for 'remainingSpace'.
        for( i 2 numSig-1
          offsetPathList = cons( list( ?layer layerName ?width sigWidth
            ?sep runningOffset) offsetPathList)
          runningOffset = runningOffset+pitch
        ) ;; for
        offsetPathList = cons( list( ?layer layerName ?width sigWidth
          ?sep runningOffset+remainingSpace2) offsetPathList)
      ) ;; if

      ;; Process each point list for each turn
      foreach( pts ptList

        when( member( car( layerName) bodyLayers)
          rodCreatePath(
            ?cvId pcCellView
            ?name sprintf( nil "%s_turn%d_side%s" car( layerName) turnCtr side)
            ?layer layerName
            ?width sigWidth
            ?pts pts
            ?justification "center"
            ?offset -mainOffset
            ?offsetSubPath offsetPathList)
        ) ;; when

        if( side == "A" then
          side = "B"
        else
          side = "A"
          ++turnCtr
        ) ;; if
      ) ;; foreach

      ;; Save turn IDs for future use
      drTable["TT"] = makeTable( "Turn Table" nil)
      for( i 1 pcFix( nrturns)
        sprintf( turnName "%s_turn%d_sideA" toplayer i)
        turnA = drTable["TT"][turnName] = rodGetObj( turnName pcCellView)
        when( indShape == "symmetrical"
          sprintf( turnName "%s_turn%d_sideB" toplayer i)
          turnB = drTable["TT"][turnName] = rodGetObj( turnName pcCellView)
        ) ;; when
        when( bottomlayer
          sprintf( turnName "%s_turn%d_sideA" bottomlayer i)
          drTable["TT"][turnName] = rodGetObj( turnName pcCellView)
          drTable["TT"][turnName]~>dbId~>TLpts = turnA~>dbId~>points
          when( indShape == "symmetrical"
            sprintf( turnName "%s_turn%d_sideB" bottomlayer i)
            drTable["TT"][turnName] = rodGetObj( turnName pcCellView)
            drTable["TT"][turnName]~>dbId~>TLpts = turnB~>dbId~>points
          ) ;; when
        ) ;; when
      ) ;; for

      ;; Save offset list for later use in jump generation
      drTable[car( layerName)] = list( nil 
        'offsetPathList offsetPathList 'sigWidth sigWidth 
        'sigSpace sigSpace 'mainOffset mainOffset)
    ) ;; foreach
  )
)

procedure( fdkDrawIndStaples( pcCellView drTable paramTable 
  @key (drawStapleArray t) (drawStapleBody t) (drawStapleTerm t))
  let(( bBox bBox1 bBox2 bTerm bottomlayer brPt bridge coilSpace 
    coilSlotLength coilWidth coilWidthHalf copyXoffset dir 
    dontDrawHorStaples extraSpace firstPt gap holeArea indShape 
    innerWidth jumpWidth lL lTerm lR lastBLTurnA lastBLTurnB 
    lastPt lastPtBL lastTurnA lastTurnB lastTurnNameA 
    lastTurnNameB layerList lrTerm maxWidthBL minGrid minSpaceBL 
    mult newPt noBodyBottomLayer nrturns numVia pathWidth
    pinBbox1 pinBbox2 pt1 ptList ptListBL rTerm remSpace 
    remainingSpace sLastPt saWidth secPt slotLength slotLengthMult 
    slotWidth solver3d stapleArrayGroup stapleArrayViaSpace stapleArrayWidth 
    stapleHGroup stapleVGroup stapleNum staplePitch stapleHShapeList 
    stapleShapeList stapleSpace stapleVShapeList stapleWidth 
    tTable tTerm tbTerm termSlotLength termside toplayer 
    turnId turn1A turn1B turnA turnB uL uR usedSpace via viaArea 
    viaEncX viaEncY viaLarge viaLayer viaLength viaLengthLarge 
    viaNum viaSpace viaWidth viaWidthLarge xLeft xRight)

    toplayer = paramTable["toplayer"]
    layerList = drTable["layer"][toplayer]["layers"]
    bottomlayer = cadr( layerList)

    ;; Only generate staple arrays when there is a bottom layer
    when( bottomlayer

      ;; Retrieve parameter values
      coilWidth = paramTable["coilwx"]
      coilSpace = paramTable["coilspcx"]
      nrturns = paramTable["nrturns"]
      termside = paramTable["termside"]
      indShape = paramTable["indShape"]
      solver3d = paramTable["solver3d"] == "Yes"

      ;; Calculate number of vias that will fit in staple
      ;; and staple size
      viaLayer = fdkPcLayer( drTable["layer"][toplayer]["viaLayer"])
      via = car( viaLayer)
      viaWidth = drTable["via"][via]["width"]
      viaLength = drTable["via"][via]["length"]
      viaEncY = drTable["via"][via][bottomlayer]["enc"]
      stapleWidth = drTable["layer"][toplayer]["stapleWidth"]
      viaEncX = (stapleWidth-viaWidth)*0.5
      viaSpace = drTable["via"][via]["space"]
      minGrid = drTable["minGrid"]
      minSpaceBL = drTable["layer"][bottomlayer]["minSpace"]
      maxWidthBL = drTable["layer"][bottomlayer]["maxWidth"]

      numVia = pcFix( (coilWidth-2*viaEncY-viaLength)/(viaLength+viaSpace))+1
      usedSpace = viaEncY+numVia*viaLength+(numVia-1)*viaSpace+viaEncY
      remainingSpace = fdkSnapGrid( minGrid (coilWidth-usedSpace)*0.5)
      drTable["stapleWidth"] = stapleWidth
      drTable["stapleRemainingSpace"] = remainingSpace
      drTable["stapleViaEncX"] = viaEncX
      bridge = rodGetObj( "ind_bridge" pcCellView)
      brPt = bridge~>mid0
      coilWidthHalf = fdkSnapGrid( minGrid coilWidth*0.5)

      ;; Calculate staple spacing based on hole area
      holeArea = drTable["layer"][bottomlayer]["holeArea"]
      dontDrawHorStaples = drTable["dontDrawHorStaples"]
      stapleArrayViaSpace = drTable["layer"][toplayer]["stapleArrayViaSpace"]
      slotWidth = drTable[bottomlayer]->sigSpace
      slotLength = max( fdkSnapUpGrid( minGrid holeArea/slotWidth) 
        stapleArrayViaSpace-2*viaEncX)
      slotLengthMult = drTable["slotLengthMult"]
      stapleSpace = slotLength*slotLengthMult
      stapleNum = drTable["stapleNum"]
      stapleArrayWidth = stapleWidth*stapleNum+slotLength*(stapleNum-1)
      staplePitch = coilWidth+coilSpace
      drTable["slotLength"] = slotLength
      drTable["stapleArrayWidth"] = stapleArrayWidth

      ;; Find inner turns by name
      tTable = drTable["TT"]
      turn1A = tTable[sprintf( nil "%s_turn1_sideA" toplayer)]
      turn1B = tTable[sprintf( nil "%s_turn1_sideB" toplayer)]

      ;; Place staples depending on inductor shape
      cond(
      ( indShape == "spiral"
        ptList = turn1A~>dbId~>points 

        ;; Draw staple arrays at jump junction
        when( drawStapleArray
          lastPt = car( last( ptList))
          sLastPt = cadr( reverse( ptList)) ;; second to last pt
          lrTerm = abs( cadr( lastPt)-cadr( sLastPt)) < minGrid
          tbTerm = !lrTerm
          dir = "HOR"
          cond( 
            ( tbTerm && dontDrawHorStaples
              saWidth = coilWidth
              remSpace = 0
              gap = "distribute")
            ( t 
              when( tbTerm dir = "VER")
              saWidth = stapleArrayWidth
              remSpace = remainingSpace
              gap = "minimum")
          ) ;; cond
          cond( 
            ( lrTerm 
              mult = if( car( sLastPt)-car( lastPt) > minGrid 1 -1)
              coilSlotLength = slotLength
              bBox = list( car( lastPt):cadr( lastPt)-coilWidthHalf
              car( lastPt)+saWidth*mult:cadr( lastPt)+coilWidthHalf))
            ( t 
              mult = if( cadr( sLastPt)-cadr( lastPt) > minGrid 1 -1)
              coilSlotLength = max( minSpaceBL viaSpace-2*viaEncX)
              bBox = list( car( lastPt)-coilWidthHalf:cadr( lastPt)
                car( lastPt)+coilWidthHalf:cadr( lastPt)+saWidth*mult)))
          fdkDrawStaplesInBbox( pcCellView dir bBox 
            bottomlayer stapleWidth coilWidth coilSlotLength viaLayer 
            viaWidth viaLength viaSpace viaEncX viaEncY remSpace gap)

          ;; When not drawing horizontal staples, and forced to draw
          ;; vertical staples on a vertical turn end, we will retract
          ;; the bottomlayer under the vertical staples
          when( tbTerm && dontDrawHorStaples 

            ;; Get bottomlayer to retract
            turnA = tTable[sprintf( nil "%s_turn1_sideA" bottomlayer)]
            ptListBL = turnA~>dbId~>points
            lastPtBL = car( last( ptListBL))
            newPt = car( lastPtBL):cadr( lastPtBL)+coilWidth*mult
            turnA~>dbId~>points = append( reverse( cdr( reverse( ptListBL)))
              list( newPt))

            dbCreatePath( pcCellView bottomlayer
              list( car( lastPt):cadr( lastPtBL)+coilWidth*mult 
                car( lastPt):cadr( lastPtBL)+(coilWidth-maxWidthBL)*mult) 
              coilWidth)
            dbCreatePath( pcCellView bottomlayer list( lastPt
              car( lastPt):cadr( lastPt)+maxWidthBL*mult) coilWidth)
          ) ;; when
        ) ;; when

        ;; Draw body staples
        firstPt = car( ptList)
        when( drawStapleBody
          pt1 = car( ptList)
          foreach( pt2 cdr( ptList)
            extraSpace = if( pt1 == firstPt || pt2 == lastPt
              (stapleArrayWidth-coilWidth)+stapleSpace 0)
            cond( 
              ( abs( cadr( pt1)-cadr( pt2)) < minGrid ;; Horizontal Edge
                mult = if( car( pt2)-car( pt1) > minGrid 1 -1)
                bBox = list( car( pt1)+(coilWidth+extraSpace)*mult:
                  cadr( pt1)-coilWidthHalf
                  car( pt2)-(coilWidth+extraSpace)*mult:
                  cadr( pt2)+coilWidthHalf)
                when( pt1 == sLastPt || pt2 == sLastPt
                  bBox = pcGrowBox( bBox 0)
                  drTable["idShape5bBox"] = list( car( bBox)
                    caar( bBox)+minGrid:cadadr( bBox)))
                fdkDrawStaplesInBbox( pcCellView "HOR" bBox bottomlayer 
                  stapleWidth coilWidth stapleSpace viaLayer viaWidth 
                  viaLength viaSpace viaEncX viaEncY remainingSpace))
              ( !dontDrawHorStaples ;; Vertical Edge AND draw horStaples
                mult = if( cadr( pt2)-cadr( pt1) > minGrid 1 -1)
                bBox = list( car( pt1)-coilWidthHalf:
                  cadr( pt1)+(coilWidth+extraSpace)*mult
                  car( pt2)+coilWidth:
                  cadr( pt2)-(coilWidth+extraSpace)*mult)
                fdkDrawStaplesInBbox( pcCellView "VER" bBox bottomlayer 
                  stapleWidth coilWidth stapleSpace viaLayer viaWidth 
                  viaLength viaSpace viaEncX viaEncY remainingSpace))
            ) ;; cond
            pt1 = pt2
          ) ;; foreach
        ) ;; when

        ;; Draw staples at outer terminal
        secPt = cadr( ptList)
        when( drawStapleTerm
          lrTerm = abs( cadr( firstPt)-cadr( secPt)) < minGrid
          tbTerm = !lrTerm
          dir = if( tbTerm && !dontDrawHorStaples "VER" "HOR")
          cond( 
            ( lrTerm 
              mult = if( car( secPt)-car( firstPt) > minGrid 1 -1)
              termSlotLength = slotLength
              bBox = list( car( firstPt):cadr( firstPt)-coilWidthHalf
                car( firstPt)+coilWidth*mult:cadr( firstPt)+coilWidthHalf))
            ( t 
              mult = if( cadr( secPt)-cadr( firstPt) > minGrid 1 -1)
              termSlotLength = max( minSpaceBL viaSpace-2*viaEncX)
              bBox = list( car( firstPt)-coilWidthHalf:cadr( firstPt)
                car( firstPt)+coilWidthHalf:cadr( firstPt)+coilWidth*mult)))
          fdkDrawStaplesInBbox( pcCellView dir bBox 
            bottomlayer stapleWidth coilWidth termSlotLength viaLayer 
            viaWidth viaLength viaSpace viaEncX viaEncY 0 "distribute")

          turn1A~>dbId~>pinBbox = bBox

          ;; When not drawing horizontal staples, and forced to draw
          ;; vertical staples on a vertical turn end, we will retract
          ;; the bottomlayer under the vertical staples
          when( tbTerm && dontDrawHorStaples 

            ;; Get bottomlayer to retract
            turnA = tTable[sprintf( nil "%s_turn1_sideA" bottomlayer)]
            ptListBL = turnA~>dbId~>points
            newPt = caar( ptListBL):cadar( ptListBL)+coilWidth*mult
            turnA~>dbId~>points = cons( newPt cdr( ptListBL))

            mult = if( termside == "Bottom" 1 -1)
            dbCreatePath( pcCellView bottomlayer
              list( caar( ptList):cadar( ptListBL)+coilWidth*mult 
                caar( ptList):cadar( ptListBL)+(coilWidth-maxWidthBL)*mult) 
              coilWidth)
            dbCreatePath( pcCellView bottomlayer list( car( ptList)
              caar( ptList):cadar( ptList)+maxWidthBL*mult) coilWidth)
          ) ;; when
        ) ;; when
      ) ;; indShape == "spiral"
      ( termside == "Top" || termside == "Bottom" ;; symmetrical

        ;; Draw staple arrays at jump junctions (when needed)
        when( drawStapleArray && nrturns > 1
          ;; Generate staple array on first turn and create a group
          ;; uR - upperRight corner of bottom segment of left inner turn
          uR = turn1A~>startRight0 
          uL= turn1B~>endRightLast
          jumpWidth = abs( car( uL)-car( uR))
          copyXoffset = stapleArrayWidth+jumpWidth

          bBox = list( car( uR)-stapleArrayWidth:cadr( uR)-coilWidth uR)
          stapleShapeList = fdkDrawStaplesInBbox( pcCellView "HOR" bBox 
            bottomlayer stapleWidth coilWidth slotLength viaLayer 
            viaWidth viaLength viaSpace viaEncX viaEncY remainingSpace)
          drTable["idShape5bBox"] = list( caadr( bBox)-minGrid:cadar( bBox)
            cadr( bBox))

          ;; Generate 3D via, if needed
          when( solver3d
            ;; Calculate required dimensions for large via
            viaNum = length( setof( shape stapleShapeList 
              shape~>layerName == car( viaLayer)))
            viaArea = viaNum*viaWidth*viaLength
            pathWidth = drTable[bottomlayer]->sigWidth *
              (length( drTable[bottomlayer]->offsetPathList)+1)
            viaLengthLarge = pathWidth
            viaWidthLarge = viaArea/viaLengthLarge
            viaLarge = rodCreateRect( ?cvId pcCellView ?layer viaLayer
              ?width viaWidthLarge ?length viaLengthLarge)
            rodAlign( ?alignObj viaLarge ?alignHandle "mid2" 
              ?refObj turn1A ?refHandle "start0" ?maintain nil)
            copyXoffset = jumpWidth+viaWidthLarge
            ;; Replace via array
            foreach( viaShape stapleShapeList
              dbDeleteObject( viaShape)
            ) ;; foreach
            stapleShapeList = list( viaLarge~>dbId)
            ;; Resize jump path
            foreach( shape setof( shape pcCellView~>shapes 
              shape~>layerName == bottomlayer) 
              shape~>width = viaLengthLarge
            ) ; foreach
          ) ;; when
  
          stapleArrayGroup = dbCreateFigGroup( pcCellView 
            "stapleArrayGroup" t 0:0 "R0")
          foreach( shape stapleShapeList 
            dbAddFigToFigGroup( stapleArrayGroup shape))
  
          ;; Copy staple group to every turn
          tTerm = termside == "Top"
          bTerm = !tTerm

          ;; Bottom left
          for( i 1 nrturns-if( tTerm 1 2)
            when( !solver3d || 
              !((evenp( nrturns) && evenp( i)) || (oddp( nrturns) && oddp( i)))
              dbCopyFig( stapleArrayGroup pcCellView list(
                0:-(staplePitch*i) "R0"))
            ) ;; when
          ) ;; for
          ;; Bottom right
          for( i 0 nrturns-if( tTerm 1 2)
            when( !solver3d || !((bTerm && zerop( i)) || 
              (evenp( nrturns) && oddp( i)) || (oddp( nrturns) && evenp( i)))
              dbCopyFig( stapleArrayGroup pcCellView list(
                copyXoffset:-(staplePitch*i) "R0"))
            ) ;; when
          ) ;; for
          ;; Top left
          lR = turn1A~>endLeftLast
          innerWidth = abs( cadr( lR)-cadr( uR))
          for( i 0 nrturns-if( tTerm 2 1)
            when( !solver3d || !((tTerm && evenp( nrturns) && zerop( i)) ||
              (evenp( nrturns) && oddp( i)) || (oddp( nrturns) && evenp( i)))
              dbCopyFig( stapleArrayGroup pcCellView list(
                0:innerWidth+(staplePitch*i) "R0"))
            ) ;; when
          ) ;; for
          ;; Top right
          for( i 0 nrturns-if( tTerm 2 1)
            when( !solver3d || !((bTerm && oddp( nrturns) && zerop( i)) || 
              (evenp( nrturns) && evenp( i)) || (oddp( nrturns) && oddp( i)))
              dbCopyFig( stapleArrayGroup pcCellView list(
                copyXoffset:innerWidth+(staplePitch*i) "R0"))
            ) ;; when
          ) ;; for
          when( solver3d && (evenp( nrturns) || (tTerm && oddp( nrturns)))
            foreach( viaShape stapleShapeList dbDeleteObject( viaShape))
          ) ;; when
        ) ;; when

        ;; Draw staples throughout body
        when( drawStapleBody
          for( i 1 nrturns
            turnId = tTable[sprintf( nil "%s_turn%d_sideA" toplayer i)]
            ;; Create horizontal staples
            if( i == nrturns && termside == "Bottom" then
              uR = turnId~>startRight1
              uL = turnId~>endRight1
            else
              uR = car( turnId~>endRight2):cadr( turnId~>startRight0)
              uL = car( turnId~>startRight2):cadr( turnId~>endRight0)
            ) ;; if
            bBox = list( car( uL)+stapleSpace:cadr( uL)-coilWidth
              car( uR)-stapleArrayWidth-stapleSpace:cadr( uR))
            unless( onep( nrturns) || abs( car( uR)-car( uL)) <
              stapleArrayWidth+stapleWidth+stapleSpace*2
              stapleHShapeList = append( fdkDrawStaplesInBbox( pcCellView 
                "HOR" bBox bottomlayer stapleWidth coilWidth stapleSpace 
                viaLayer viaWidth viaLength viaSpace viaEncX viaEncY 
                remainingSpace) stapleHShapeList)
            )
            ;; Create vertical staples
            if( i == nrturns && termside == "Bottom" then
              lR = turnId~>startRight2
              uR = turnId~>endRight2
            else
              lR = turnId~>startRight1
              uR = turnId~>endRight1
            ) ;; if
            bBox = list( car( lR)-coilWidth:cadr( lR)+stapleSpace
              car( uR):cadr( uR)-stapleSpace)

            unless( dontDrawHorStaples
              stapleVShapeList = append( fdkDrawStaplesInBbox( pcCellView 
                "VER" bBox bottomlayer stapleWidth coilWidth stapleSpace 
                viaLayer viaWidth viaLength viaSpace viaEncX viaEncY 
                remainingSpace) stapleVShapeList)
            ) ;; unless
          ) ;; for
          stapleHGroup = dbCreateFigGroup( pcCellView 
            "stapleHGroup" t 0:0 "R0")
          foreach( shape stapleHShapeList 
            dbAddFigToFigGroup( stapleHGroup shape))
          stapleVGroup = dbCreateFigGroup( pcCellView 
            "stapleVGroup" t 0:0 "R0")
          foreach( shape stapleVShapeList 
            dbAddFigToFigGroup( stapleVGroup shape))

          ;; Copy horizontal staple group
          ;; Bottom right
          dbCopyFig( stapleHGroup pcCellView list( 0:0 "MY"))
          unless( onep( nrturns)
            ;; Top left
            dbCopyFig( stapleHGroup pcCellView list( 0:0 "MX"))
            ;; Top right
            dbCopyFig( stapleHGroup pcCellView list( 0:0 "R180"))
          ) ;; unless

          ;; Copy vertical staple group
          ;; Right
          dbCopyFig( stapleVGroup pcCellView list( 0:0 "MY"))
        ) ;; when
          
        ;; For inductors with a single coil, draw staples on side
        ;; opposite to terminals. 
        sprintf( lastTurnNameA "%s_turn%d_sideA" toplayer nrturns)
        sprintf( lastTurnNameB "%s_turn%d_sideB" toplayer nrturns)
        lastTurnA = tTable[lastTurnNameA]
        lastTurnB = tTable[lastTurnNameB]
        when( drawStapleBody && onep( nrturns)
          if( termside == "Top" then
            uL = lastTurnA~>endRight0
            uR = lastTurnB~>startRightLast
            bBox = list( car( uL)+stapleSpace:cadr( uL)-coilWidth 
              car( uR)-stapleSpace:cadr( uR))
          else ;; termside == "Bottom"
            lL = lastTurnA~>startRightLast
            lR = lastTurnB~>endRight0
            bBox = list( car( lL)+stapleSpace:cadr( lL) 
              car( lR)-stapleSpace:cadr( lR)+coilWidth)
          ) ;; if
          stapleShapeList = fdkDrawStaplesInBbox( pcCellView 
            "HOR" bBox bottomlayer stapleWidth coilWidth stapleSpace 
            viaLayer viaWidth viaLength viaSpace viaEncX viaEncY 
            remainingSpace)
          drTable["idShape5bBox"] = list( car( bBox) 
            caar( bBox)+minGrid:cadadr( bBox))
        ) ;; when

        ;; Draw staple arrays at terminals
        if( termside == "Top" then
          uR = lastTurnA~>endRightLast
          bBox1 = list( car( uR)-coilWidth:cadr( uR)-stapleArrayWidth uR)
          pinBbox1 = list( car( uR)-coilWidth:cadr( uR)-coilWidth uR)
          uR = lastTurnB~>startLeft0
          bBox2 = list( car( uR)-coilWidth:cadr( uR)-stapleArrayWidth uR)
          pinBbox2 = list( car( uR)-coilWidth:cadr( uR)-coilWidth uR)
        else ;; termside == "Bottom"
          lL = lastTurnA~>startLeft0
          bBox1 = list( lL car( lL)+coilWidth:cadr( lL)+stapleArrayWidth)
          pinBbox1 = list( lL car( lL)+coilWidth:cadr( lL)+coilWidth)
          lL = lastTurnB~>endRightLast
          bBox2 = list( lL car( lL)+coilWidth:cadr( lL)+stapleArrayWidth)
          pinBbox2 = list( lL car( lL)+coilWidth:cadr( lL)+coilWidth)
        ) ;; if
        when( drawStapleTerm
          if( dontDrawHorStaples then
            stapleSpace = max( minSpaceBL viaSpace-2*viaEncX)
            stapleShapeList = fdkDrawStaplesInBbox( pcCellView "HOR" pinBbox1
              bottomlayer stapleWidth coilWidth stapleSpace viaLayer 
              viaWidth viaLength viaSpace viaEncX viaEncY 0 "distribute")
            stapleShapeList = fdkDrawStaplesInBbox( pcCellView "HOR" pinBbox2
              bottomlayer stapleWidth coilWidth stapleSpace viaLayer 
              viaWidth viaLength viaSpace viaEncX viaEncY 0 "distribute")

            ;; Retract bottomlayer slotted end where vertical staples are
            lastBLTurnA = tTable[sprintf( nil "%s_turn%d_sideA" 
              bottomlayer nrturns)]
            lastBLTurnB = tTable[sprintf( nil "%s_turn%d_sideB" 
              bottomlayer nrturns)]
            if( termside == "Top" then
              ptList = lastBLTurnA~>dbId~>points
              lastPt = car( last( ptList))
              newPt = car( lastPt):cadr( lastPt)-coilWidth
              lastBLTurnA~>dbId~>points = append( remove( lastPt ptList) 
                list( newPt))
              dbCreatePath( pcCellView bottomlayer 
                list( caar( last( lastTurnA~>dbId~>points)):cadr( newPt)
                  caar( last( lastTurnA~>dbId~>points)):cadr( newPt)+maxWidthBL)
                coilWidth)
              ptList = lastBLTurnB~>dbId~>points
              newPt = caar( ptList):cadar( ptList)-coilWidth
              lastBLTurnB~>dbId~>points = cons( newPt cdr( ptList))
              dbCreatePath( pcCellView bottomlayer 
                list( caar( lastTurnB~>dbId~>points):cadr( newPt)
                  caar( lastTurnB~>dbId~>points):cadr( newPt)+maxWidthBL) 
                coilWidth)
            else
              ptList = lastBLTurnA~>dbId~>points
              newPt = caar( ptList):cadar( ptList)+coilWidth
              lastBLTurnA~>dbId~>points = cons( newPt cdr( ptList))
              dbCreatePath( pcCellView bottomlayer 
                list( caar( lastTurnA~>dbId~>points):cadr( newPt)
                  caar( lastTurnA~>dbId~>points):cadr( newPt)-maxWidthBL) 
                coilWidth)
              ptList = lastBLTurnB~>dbId~>points
              lastPt = car( last( ptList))
              newPt = car( lastPt):cadr( lastPt)+coilWidth
              lastBLTurnB~>dbId~>points = append( remove( lastPt ptList) 
                list( newPt))
              dbCreatePath( pcCellView bottomlayer 
                list( caar( last( lastTurnB~>dbId~>points)):cadr( newPt)
                  caar( last( lastTurnB~>dbId~>points)):cadr( newPt)-maxWidthBL)
                coilWidth)
            ) ;; if
          else
            stapleShapeList = fdkDrawStaplesInBbox( pcCellView "VER" bBox1
              bottomlayer stapleWidth coilWidth slotLength viaLayer 
              viaWidth viaLength viaSpace viaEncX viaEncY remainingSpace)
            stapleShapeList = fdkDrawStaplesInBbox( pcCellView "VER" bBox2
              bottomlayer stapleWidth coilWidth slotLength viaLayer 
              viaWidth viaLength viaSpace viaEncX viaEncY remainingSpace)
          ) ;; if

        ) ;; when
        lastTurnA~>dbId~>pinBbox = pinBbox1
        lastTurnB~>dbId~>pinBbox = pinBbox2
  
      )
      ( t ;; termside == "Left" || "Right" - symmetrical

        ;; Draw staple arrays at jump junctions (when needed)
        when( drawStapleArray && nrturns > 1
          ;; Generate staple array on first turn and create a group
          ;; uL - upperRight corner of left segment of bottom inner turn
          uL = turn1A~>startRight0 
          uR= turn1B~>endRightLast
          jumpWidth = abs( cadr( uL)-cadr( uR))
          bBox = list( car( uL):cadr( uL)-stapleArrayWidth
            car( uL)+coilWidth:cadr( uL))
          if( dontDrawHorStaples then
            bBox = list( car( uL):cadr( uL)-coilWidth
              car( uL)+coilWidth:cadr( uL))
            stapleShapeList = append( fdkDrawStaplesInBbox( pcCellView "HOR" 
              bBox bottomlayer stapleWidth coilWidth 
              max( minSpaceBL viaSpace-2*viaEncX) viaLayer viaWidth 
              viaLength stapleArrayViaSpace viaEncX viaEncY 0 "distribute") 
              stapleShapeList)
            stapleArrayWidth = coilWidth
          else
            stapleShapeList = append( fdkDrawStaplesInBbox( pcCellView "VER"
              bBox bottomlayer stapleWidth coilWidth slotLength viaLayer 
              viaWidth viaLength viaSpace viaEncX viaEncY remainingSpace)
              stapleShapeList)
          ) ;; if
          copyXoffset = stapleArrayWidth+jumpWidth

          ;; Generate 3D via, if needed
          when( solver3d
            ;; Calculate required dimensions for large via
            viaNum = length( setof( shape stapleShapeList 
              shape~>layerName == car( viaLayer)))
            viaArea = viaNum*viaWidth*viaLength
            pathWidth = drTable[bottomlayer]->sigWidth *
              (length( drTable[bottomlayer]->offsetPathList)+1)
            viaWidthLarge = pathWidth
            viaLengthLarge = viaArea/viaWidthLarge
            viaLarge = rodCreateRect( ?cvId pcCellView ?layer viaLayer
              ?width viaWidthLarge ?length viaLengthLarge)
            rodAlign( ?alignObj viaLarge ?alignHandle "mid1" 
              ?refObj turn1A ?refHandle "start0" ?maintain nil)
            copyXoffset = jumpWidth+viaLengthLarge
            ;; Replace via array
            foreach( viaShape stapleShapeList
              dbDeleteObject( viaShape)
            ) ;; foreach
            stapleShapeList = list( viaLarge~>dbId)
            ;; Resize jump path
            foreach( shape setof( shape pcCellView~>shapes 
              shape~>layerName == bottomlayer) 
              shape~>width = viaWidthLarge
            ) ; foreach
          ) ;; when
  
          stapleArrayGroup = dbCreateFigGroup( pcCellView 
            "stapleArrayGroup" t 0:0 "R0")
          foreach( shape stapleShapeList 
            dbAddFigToFigGroup( stapleArrayGroup shape))

          ;; Copy staple group to every turn
          ;; NOTE: When not creating horizontal staples, we will not
          ;;   create staple arrays on the bridge region
          lTerm = termside == "Left"
          rTerm = !lTerm

          ;; Bottom left
          for( i 1 nrturns-if( termside == "Left" 2 1)
            when( !solver3d || !(
              (lTerm && evenp( nrturns) && oddp( i)) || 
              (lTerm && oddp( nrturns) && evenp( i)) ||
              (rTerm && evenp( nrturns) && evenp( i)) || 
              (rTerm && oddp( nrturns) && oddp( i)))
              dbCopyFig( stapleArrayGroup pcCellView list(
                -(staplePitch*i):0 "R0"))
            ) ;; when
          ) ;; for
          ;; Top left
          for( i 0 nrturns-if( termside == "Left" 2 1)
            unless( dontDrawHorStaples && zerop( i) &&
              ((evenp( nrturns) && termside == "Left") ||
              (oddp( nrturns) && termside == "Right"))
            when( !solver3d || !((lTerm && evenp( nrturns) && zerop( i)) ||
              (lTerm && evenp( nrturns) && evenp( i)) || 
              (lTerm && oddp( nrturns) && oddp( i)) ||
              (rTerm && evenp( nrturns) && oddp( i)) || 
              (rTerm && oddp( nrturns) && evenp( i)))
              dbCopyFig( stapleArrayGroup pcCellView list(
                -(staplePitch*i):copyXoffset "R0"))
            ) ;; unless
            ) ;; when
          ) ;; for
          ;; Bottom right
          lL = turn1A~>endLeftLast
          innerWidth = abs( car( lL)-car( uR))
          for( i 0 nrturns-if( termside == "Left" 1 2)
            unless( dontDrawHorStaples && zerop( i) &&
              ((oddp( nrturns) && termside == "Left") ||
              (evenp( nrturns) && termside == "Right"))
            when( !solver3d || !(zerop( i) || 
              (lTerm && evenp( nrturns) && evenp( i)) || 
              (lTerm && oddp( nrturns) && oddp( i)) ||
              (rTerm && evenp( nrturns) && oddp( i)) || 
              (rTerm && oddp( nrturns) && evenp( i)))
              dbCopyFig( stapleArrayGroup pcCellView list(
                innerWidth+(staplePitch*i):0 "R0"))
            ) ;; unless 
            ) ;; when
          ) ;; for
          ;; Top right
          for( i 0 nrturns-if( termside == "Left" 1 2)
            unless( dontDrawHorStaples && zerop( i) &&
              ((oddp( nrturns) && termside == "Left") ||
              (evenp( nrturns) && termside == "Right"))
            when( !solver3d || !(
              (lTerm && evenp( nrturns) && oddp( i)) || 
              (lTerm && oddp( nrturns) && evenp( i)) ||
              (rTerm && evenp( nrturns) && evenp( i)) || 
              (rTerm && oddp( nrturns) && oddp( i)))
              dbCopyFig( stapleArrayGroup pcCellView list(
                innerWidth+(staplePitch*i):copyXoffset "R0"))
            ) ;; unless 
            ) ;; when
          ) ;; for
          when( solver3d ;&& (evenp( nrturns) || (tTerm && oddp( nrturns)))
            foreach( viaShape stapleShapeList dbDeleteObject( viaShape))
          ) ;; when

          ;; Remove bridge staple array, if still there
          when( dontDrawHorStaples && 
            ((evenp( nrturns) && termside == "Left") ||
            (oddp( nrturns) && termside == "Right"))
            foreach( fig stapleArrayGroup~>figs dbDeleteObject( fig))
            dbDeleteObject( stapleArrayGroup)
          ) ;; when

          ;; When not drawing horizontal staples, and forced to draw
          ;; vertical staples on vertical turn ends, we will retract
          ;; the bottomlayer under the vertical staples (when needed)
          when( dontDrawHorStaples && !solver3d
          for( i 1 nrturns
            ;; When no body bottomlayer, use the toplayer point list
            ;; to create jump staple arrays.
            turnA = tTable[sprintf( nil "%s_turn%d_sideA" bottomlayer i)]
            turnB = tTable[sprintf( nil "%s_turn%d_sideB" bottomlayer i)]

            ptList = turnA~>dbId~>points
            xLeft = caar( turnA~>dbId~>TLpts)
            xRight = caar( last( turnA~>dbId~>TLpts))
            unless( turnA && turnB
              noBodyBottomLayer = t
              turnA = tTable[sprintf( nil "%s_turn%d_sideA" toplayer i)]
              turnB = tTable[sprintf( nil "%s_turn%d_sideB" toplayer i)]
              ptList = turnA~>dbId~>points
              xLeft = caar( turnA~>dbId~>points)
              xRight = caar( last( turnA~>dbId~>points))
            ) ;; unless
            unless( (i == nrturns && termside == "Left") ||
              (onep( i) && ((evenp( nrturns) && termside == "Left") ||
              (oddp( nrturns) && termside == "Right")))
              dbCreatePath( pcCellView bottomlayer list( xLeft:cadar( ptList) 
                xLeft:cadar( ptList)-maxWidthBL) coilWidth)
              newPt = caar( ptList):cadar( ptList)-coilWidth
              unless( noBodyBottomLayer
                ptList = turnA~>dbId~>points = cons( newPt cdr( ptList))
              ) ;; unless
              dbCreatePath( pcCellView bottomlayer list( xLeft:cadr( newPt)
                  xLeft:cadr( newPt)+maxWidthBL) coilWidth)
            ) ;; unless
            unless( (i == nrturns && termside == "Right") ||
              (onep( i) && ((oddp( nrturns) && termside == "Left") ||
              (evenp( nrturns) && termside == "Right")))
              lastPt = car( last( ptList))
              dbCreatePath( pcCellView bottomlayer list( xRight:cadr( lastPt) 
                xRight:cadr( lastPt)-maxWidthBL) coilWidth)
              newPt = car( lastPt):cadr( lastPt)-coilWidth
              unless( noBodyBottomLayer
                turnA~>dbId~>points = append( remove( lastPt ptList) list( newPt))
              ) ;; unless
              dbCreatePath( pcCellView bottomlayer list( xRight:cadr( newPt)
                  xRight:cadr( newPt)+maxWidthBL) coilWidth)
            ) ;; unless

            ptList = turnB~>dbId~>points
            unless( (i == nrturns && termside == "Left") ||
              (onep( i) && ((evenp( nrturns) && termside == "Left") ||
              (oddp( nrturns) && termside == "Right")))
              lastPt = car( last( ptList))
              bBox = dbCreatePath( pcCellView bottomlayer 
                list( xLeft:cadr( lastPt) xLeft:cadr( lastPt)+maxWidthBL) 
                coilWidth)
              when( onep( i)
                bBox = bBox~>bBox
                drTable["idShape5bBox"] = list( car( bBox)
                  caadr( bBox):cadar( bBox)+minGrid)
              ) ;; when
              newPt = car( lastPt):cadr( lastPt)+coilWidth
              unless( noBodyBottomLayer
                ptList = turnB~>dbId~>points = append( remove( lastPt ptList) 
                  list( newPt))
              ) ;; unless
              dbCreatePath( pcCellView bottomlayer list( xLeft:cadr( newPt)
                  xLeft:cadr( newPt)-maxWidthBL) coilWidth)
            ) ;; unless
            unless( (i == nrturns && termside == "Right") ||
              (onep( i) && ((oddp( nrturns) && termside == "Left") ||
              (evenp( nrturns) && termside == "Right")))
              bBox = dbCreatePath( pcCellView bottomlayer 
                list( xRight:cadar( ptList) xRight:cadar( ptList)+maxWidthBL) 
                coilWidth)
              when( onep( i)
                bBox = bBox~>bBox
                drTable["idShape5bBox"] = list( car( bBox)
                  caadr( bBox):cadar( bBox)+minGrid)
              ) ;; when
              newPt = caar( ptList):cadar( ptList)+coilWidth
              unless( noBodyBottomLayer
                turnB~>dbId~>points = cons( newPt cdr( ptList))
              ) ;; unless
              dbCreatePath( pcCellView bottomlayer list( xRight:cadr( newPt)
                  xRight:cadr( newPt)-maxWidthBL) coilWidth)
            ) ;; unless
          ) ;; for
          ) ;; when
        ) ;; when

        ;; Draw staples throughout body
        when( drawStapleBody
          for( i 1 nrturns
            turnId = tTable[sprintf( nil "%s_turn%d_sideA" toplayer i)]
            ;; Create vertical staples
            if( i == nrturns && termside == "Left" then
              uR = turnId~>startLeft1
              lR = turnId~>endLeft1
            else
              uR = car( turnId~>startLeft0):cadr( turnId~>endLeft2)
              lR = car( turnId~>endLeft0):cadr( turnId~>startLeft2)
            ) ;; if
            bBox = list( car( lR)-coilWidth:cadr( lR)+stapleSpace
              car( uR):cadr( uR)-stapleArrayWidth-stapleSpace)
            unless( onep( nrturns) || dontDrawHorStaples ||
              abs( cadr( uR)-cadr( lR)) <
                stapleArrayWidth+stapleWidth+stapleSpace*2
              stapleVShapeList = append( fdkDrawStaplesInBbox( pcCellView 
                "VER" bBox bottomlayer stapleWidth coilWidth stapleSpace 
                viaLayer viaWidth viaLength viaSpace viaEncX viaEncY 
                remainingSpace) stapleVShapeList)
            ) ;; unless
            ;; Create horizontal staples
            if( i == nrturns && termside == "Left" then
              uL = turnId~>startLeft2
              uR = turnId~>endLeft2
            else
              uL = turnId~>startLeft1
              uR = turnId~>endLeft1
            ) ;; if
            bBox = list( car( uL)+stapleSpace:car( uL)-coilWidth
              car( uR)-stapleSpace:cadr( uR))
            stapleHShapeList = append( fdkDrawStaplesInBbox( pcCellView 
              "HOR" bBox bottomlayer stapleWidth coilWidth stapleSpace 
              viaLayer viaWidth viaLength viaSpace viaEncX viaEncY 
              remainingSpace) stapleHShapeList)
          ) ;; for
          stapleVGroup = dbCreateFigGroup( pcCellView 
            "stapleVGroup" t 0:0 "R0")
          foreach( shape stapleVShapeList 
            dbAddFigToFigGroup( stapleVGroup shape))
          stapleHGroup = dbCreateFigGroup( pcCellView 
            "stapleHGroup" t 0:0 "R0")
          foreach( shape stapleHShapeList 
            dbAddFigToFigGroup( stapleHGroup shape))

          ;; Copy vertical staple group
          ;; Top left
          dbCopyFig( stapleVGroup pcCellView list( 0:0 "MX"))
          unless( onep( nrturns)
            ;; Bottom right
            dbCopyFig( stapleVGroup pcCellView list( 0:0 "MY"))
            ;; Top right
            dbCopyFig( stapleVGroup pcCellView list( 0:0 "R180"))
          ) ;; unless

          ;; Copy horizontal staple group
          ;; Right
          dbCopyFig( stapleHGroup pcCellView list( 0:0 "MX"))
        ) ;; when

        ;; For inductors with a single coil, draw staples on side
        ;; opposite to terminals, unless dontDrawHorStaples is t
        sprintf( lastTurnNameA "%s_turn%d_sideA" toplayer nrturns)
        sprintf( lastTurnNameB "%s_turn%d_sideB" toplayer nrturns)
        lastTurnA = tTable[lastTurnNameA]
        lastTurnB = tTable[lastTurnNameB]
        when( drawStapleBody && onep( nrturns)
          if( dontDrawHorStaples then
            bBox = list( car( brPt)-coilWidthHalf:cadr( brPt)
              car( brPt)+coilWidthHalf:cadr( brPt)+maxWidthBL)
            dbCreateRect( pcCellView bottomlayer bBox)
            drTable["idShape5bBox"] = list( car( bBox) 
              caadr( bBox):cadar( bBox)+minGrid)
          else
            if( termside == "Left" then
              lL = lastTurnA~>startLeftLast
              uL = lastTurnB~>endLeft0
              bBox = list( car( lL):cadr( lL)+stapleSpace
                car( uL)+coilWidth:cadr( uL)-stapleSpace)
            else ;; termside == "Right"
              lR = lastTurnA~>endLeft0
              uR = lastTurnB~>startLeftLast
              bBox = list( car( lR)-coilWidth:cadr( lR)+stapleSpace
                car( uR):cadr( uR)-stapleSpace)
            ) ;; if
            stapleShapeList = fdkDrawStaplesInBbox( pcCellView "VER" bBox
              bottomlayer stapleWidth coilWidth stapleSpace viaLayer 
              viaWidth viaLength viaSpace viaEncX viaEncY remainingSpace)
            drTable["idShape5bBox"] = list( car( bBox) 
              caadr( bBox):cadar( bBox)+minGrid)
          ) ;; if
        ) ;; when

        ;; Draw staple arrays at terminals
        when( dontDrawHorStaples stapleArrayWidth = coilWidth)
        if( termside == "Left" then
          lL = lastTurnA~>startRight0
          bBox1 = list( lL car( lL)+stapleArrayWidth:cadr( lL)+coilWidth)
          pinBbox1 = list( lL car( lL)+coilWidth:cadr( lL)+coilWidth)
          lL = lastTurnB~>endLeftLast
          bBox2 = list( lL car( lL)+stapleArrayWidth:cadr( lL)+coilWidth)
          pinBbox2 = list( lL car( lL)+coilWidth:cadr( lL)+coilWidth)
        else ;; termside == "Right"
          uR = lastTurnA~>endLeftLast
          bBox1 = list( car( uR)-stapleArrayWidth:cadr( uR)-coilWidth uR)
          pinBbox1 = list( car( uR)-coilWidth:cadr( uR)-coilWidth uR)
          uR = lastTurnB~>startRight0
          bBox2 = list( car( uR)-stapleArrayWidth:cadr( uR)-coilWidth uR)
          pinBbox2 = list( car( uR)-coilWidth:cadr( uR)-coilWidth uR)
        ) ;; if
        when( drawStapleTerm
          stapleSpace = max( minSpaceBL viaSpace-2*viaEncX
            fdkSnapUpGrid( minGrid holeArea/slotWidth))
          stapleShapeList = fdkDrawStaplesInBbox( pcCellView "HOR" bBox1
            bottomlayer stapleWidth coilWidth stapleSpace viaLayer 
            viaWidth viaLength viaSpace viaEncX viaEncY 0 "distribute")
          stapleShapeList = fdkDrawStaplesInBbox( pcCellView "HOR" bBox2
            bottomlayer stapleWidth coilWidth stapleSpace viaLayer 
            viaWidth viaLength viaSpace viaEncX viaEncY 0 "distribute")
        ) ;; when
  
        lastTurnA~>dbId~>pinBbox = pinBbox1
        lastTurnB~>dbId~>pinBbox = pinBbox2
      ) 
      ) ;; cond
    ) ;; when
  )
)

procedure( fdkDrawIndBridge( pcCellView drTable paramTable)
  let(( bodyLayers bottomlayer coilWidth bridgePtList mainOffset 
    nrturns offsetPathList sigWidth termside toplayer turn1A turn1B)

    ;; Get parameter and design rule values needed
    nrturns = paramTable["nrturns"]
    coilWidth = paramTable["coilwx"]
    toplayer = paramTable["toplayer"]
    termside = paramTable["termside"]
    bodyLayers = drTable["layer"][toplayer]["bodyLayers"]
    bottomlayer = cadr( bodyLayers)
    offsetPathList = drTable[bottomlayer]->offsetPathList
    mainOffset = drTable[bottomlayer]->mainOffset
    sigWidth = drTable[bottomlayer]->sigWidth

    ;; Find inner turns by name.
    turn1A = drTable["TT"][sprintf( nil "%s_turn1_sideA" toplayer)]
    turn1B = drTable["TT"][sprintf( nil "%s_turn1_sideB" toplayer)]

    ;; Generate bridge on innermost ring
    bridgePtList = if( (evenp( nrturns) &&
      ( termside == "Top" || termside == "Right")) ||
      ( oddp( nrturns) && ( termside == "Bottom" || termside == "Left"))
      list( turn1A~>endLast turn1B~>start0)
      list( turn1B~>endLast turn1A~>start0))
    rodCreatePath( ?cvId pcCellView ?layer toplayer 
      ?name "ind_bridge" ?width coilWidth ?pts bridgePtList)
    when( bottomlayer
      rodCreatePath( ?cvId pcCellView ?layer bottomlayer 
        ?width sigWidth ?pts bridgePtList ?offset -mainOffset
        ?offsetSubPath offsetPathList)
    ) ;; when
  )
)

procedure( fdkDrawIndJumps_StapleArray( pcCellView drTable paramTable)
  let(( bottomY bottomlayer coilSpace coilWidth copyCtr hJumpBL 
    hJumpBLPtList hJumpGroup hJumpTL jumpBL jumpTL layerList leftX 
    mainOffset mult nJumpBL nJumpBLPtList nJumpGroup nJumpTL nrturns 
    offset offsetPathList rightX sJumpBL sJumpBLPtList sJumpGroup sJumpTL 
    sigWidth solver3d startX startY termside topY toplayer turn1A turn1B 
    turnPitch turnPitch2 zJumpBL zJumpBLPtList zJumpGroup zJumpTL)

    nrturns = paramTable["nrturns"]
    coilWidth = paramTable["coilwx"]
    coilSpace = paramTable["coilspcx"]
    toplayer = paramTable["toplayer"]
    termside = paramTable["termside"]
    solver3d = paramTable["solver3d"]
    layerList = drTable["layer"][toplayer]["layers"]
    bottomlayer = cadr( layerList)
    offsetPathList = drTable[bottomlayer]->offsetPathList
    mainOffset = drTable[bottomlayer]->mainOffset
    sigWidth = drTable[bottomlayer]->sigWidth
    layerList = drTable["layer"][toplayer]["jumpLayers"]
    offset = drTable["layer"][toplayer]["stapleArrayOffset"] || 0
    jumpTL = car( layerList)
    jumpBL = cadr( layerList)
    when( solver3d == "Yes"
      mainOffset = 0
      offsetPathList = nil
    ) ;; when

    ;; Find inner turns by name
    turn1A = drTable["TT"][sprintf( nil "%s_turn1_sideA" toplayer)]
    turn1B = drTable["TT"][sprintf( nil "%s_turn1_sideB" toplayer)]

    ;; Generate jumps when more than one turn
    when( nrturns > 1
      turnPitch = coilWidth+coilSpace
      turnPitch2 = turnPitch*2
      if( termside == "Top" || termside == "Bottom" then
        topY = cadr( turn1A~>endLast)
        bottomY = cadr( turn1A~>start0)

        ;; An 'sJump' is a horizontal jump that connects lower
        ;; left to upper right, like an 'S'
        ;; Create base sJump and group
        sJumpGroup = dbCreateFigGroup( pcCellView "sJumpGroup" t 0:0 "R0")
        sJumpTL = rodCreatePath( ?cvId pcCellView ?layer jumpTL 
          ?width coilWidth ?pts list( car( turn1A~>start0)-offset:0
            0:0 0:turnPitch car( turn1B~>start0)+offset:turnPitch))
        dbAddFigToFigGroup( sJumpGroup sJumpTL~>dbId)
        sJumpBLPtList = list( car( turn1A~>start0)-offset:turnPitch 
          0:turnPitch 0:0 car( turn1B~>start0)+offset:0)
        sJumpBL = rodCreatePath( ?cvId pcCellView ?layer jumpBL 
          ?width sigWidth ?offset -mainOffset ?offsetSubPath offsetPathList 
          ?pts if( termside == "Top" sJumpBLPtList reverse( sJumpBLPtList)))
        foreach( shape sJumpBL~>subShapes 
          dbAddFigToFigGroup( sJumpGroup shape))
        dbAddFigToFigGroup( sJumpGroup sJumpBL~>dbId)

        startY = cond(
          (termside == "Top" && evenp( nrturns) topY+turnPitch)
          (termside == "Top" topY)
          (termside == "Bottom" && evenp( nrturns) bottomY-turnPitch2)
          (termside == "Bottom" bottomY-turnPitch))
        mult = if( termside == "Top" 1 -1)
        copyCtr = pcFix( nrturns*0.5) -
          if( evenp( nrturns) 2 1)

        ;; Copy sJump to coils on terminal side
        for( i 0 copyCtr
          dbCopyFig( sJumpGroup pcCellView 
            list( 0:startY+(turnPitch2*i)*mult "R0"))
        ) ;; for
        foreach( fig sJumpGroup~>figs dbDeleteObject( fig))
        dbDeleteObject( sJumpGroup)

        ;; A 'zJump' is a horizontal jump that connects upper
        ;; left to lower right, like a 'Z'
        ;; Create base zJump and group
        zJumpGroup = dbCreateFigGroup( pcCellView "zJumpGroup" t 0:0 "R0")
        zJumpTL = rodCreatePath( ?cvId pcCellView ?layer jumpTL 
          ?width coilWidth ?pts list( car( turn1A~>start0)-offset:0
            0:0 0:-turnPitch car( turn1B~>start0)+offset:-turnPitch))
        dbAddFigToFigGroup( zJumpGroup zJumpTL~>dbId)
        zJumpBLPtList = list( car( turn1A~>start0)-offset:-turnPitch
            0:-turnPitch 0:0 car( turn1B~>start0)+offset:0)
        zJumpBL = rodCreatePath( ?cvId pcCellView ?layer jumpBL 
          ?width sigWidth ?offset -mainOffset ?offsetSubPath offsetPathList 
          ?pts if( termside == "Top" zJumpBLPtList reverse( zJumpBLPtList)))
        foreach( shape zJumpBL~>subShapes 
          dbAddFigToFigGroup( zJumpGroup shape))
        dbAddFigToFigGroup( zJumpGroup zJumpBL~>dbId)

        startY = cond(
          (termside == "Top" && evenp( nrturns) bottomY)
          (termside == "Top" bottomY-turnPitch)
          (termside == "Bottom" && evenp( nrturns) topY+turnPitch)
          (termside == "Bottom" topY+turnPitch2))
        mult = if( termside == "Top" -1 1)
        copyCtr = pcFix( nrturns*0.5)-1

        ;; Copy zJump to coils on opposite side of terminals
        for( i 0 copyCtr
          dbCopyFig( zJumpGroup pcCellView 
            list( 0:startY+(turnPitch2*i)*mult "R0"))
        ) ;; for
        foreach( fig zJumpGroup~>figs dbDeleteObject( fig))
        dbDeleteObject( zJumpGroup)

      else ;; termside == "Left" || "Right"

        leftX = car( turn1A~>start0)
        rightX = car( turn1A~>endLast)

        ;; An 'nJump' is a vertical jump that connects lower
        ;; left to upper right, like an 'N'
        ;; Create base nJump and group
        nJumpGroup = dbCreateFigGroup( pcCellView "nJumpGroup" t 0:0 "R0")
        nJumpTL = rodCreatePath( ?cvId pcCellView ?layer jumpTL 
          ?width coilWidth ?pts list( 0:cadr( turn1A~>start0)-offset
            0:0 turnPitch:0 turnPitch:cadr( turn1B~>start0)+offset))
        dbAddFigToFigGroup( nJumpGroup nJumpTL~>dbId)
        nJumpBLPtList = list( turnPitch:cadr( turn1A~>start0)-offset
          turnPitch:0 0:0 0:cadr( turn1B~>start0)+offset)
        nJumpBL = rodCreatePath( ?cvId pcCellView ?layer jumpBL 
          ?width sigWidth ?offset -mainOffset ?offsetSubPath offsetPathList 
          ?pts if( termside == "Right" nJumpBLPtList reverse( nJumpBLPtList)))
        foreach( shape nJumpBL~>subShapes 
          dbAddFigToFigGroup( nJumpGroup shape))
        dbAddFigToFigGroup( nJumpGroup nJumpBL~>dbId)

        startX = cond(
          (termside == "Right" && evenp( nrturns) rightX+turnPitch)
          (termside == "Right" rightX)
          (termside == "Left" && evenp( nrturns) rightX)
          (termside == "Left" rightX+turnPitch))
        mult = 1
        copyCtr = pcFix( nrturns*0.5) - 
          if( evenp( nrturns) && termside == "Right" 2 1)

        ;; Copy nJump to coils on terminal side
        for( i 0 copyCtr
          dbCopyFig( nJumpGroup pcCellView 
            list( startX+(turnPitch2*i)*mult:0 "R0"))
        ) ;; for
        foreach( fig nJumpGroup~>figs dbDeleteObject( fig))
        dbDeleteObject( nJumpGroup)

        ;; An 'hJump' is a vertical jump that connects upper
        ;; left to lower right, like an 'h' (not really, but 
        ;; we are going with that ;)
        ;; Create base hJump and group
        hJumpGroup = dbCreateFigGroup( pcCellView "hJumpGroup" t 0:0 "R0")
        hJumpTL = rodCreatePath( ?cvId pcCellView ?layer jumpTL 
          ?width coilWidth ?pts list( 0:cadr( turn1A~>start0)-offset
            0:0 -turnPitch:0 -turnPitch:cadr( turn1B~>start0)+offset))
        dbAddFigToFigGroup( hJumpGroup hJumpTL~>dbId)
        hJumpBLPtList = list( -turnPitch:cadr( turn1A~>start0)-offset
          -turnPitch:0 0:0 0:cadr( turn1B~>start0)+offset)
        hJumpBL = rodCreatePath( ?cvId pcCellView ?layer jumpBL 
          ?width sigWidth ?offset -mainOffset ?offsetSubPath offsetPathList 
          ?pts if( termside == "Right" hJumpBLPtList reverse( hJumpBLPtList)))
        foreach( shape hJumpBL~>subShapes 
          dbAddFigToFigGroup( hJumpGroup shape))
        dbAddFigToFigGroup( hJumpGroup hJumpBL~>dbId)

        startX = cond(
          (termside == "Right" && evenp( nrturns) leftX)
          (termside == "Right" leftX-turnPitch)
          (termside == "Left" && evenp( nrturns) leftX-turnPitch)
          (termside == "Left" leftX))
        mult = -1
        copyCtr = pcFix( nrturns*0.5)-
          if( evenp( nrturns) && termside == "Left" 2 1)

        for( i 0 copyCtr
          dbCopyFig( hJumpGroup pcCellView 
            list( startX+(turnPitch2*i)*mult:0 "R0"))
        ) ;; for
        foreach( fig hJumpGroup~>figs dbDeleteObject( fig))
        dbDeleteObject( hJumpGroup)

      ) ;; if
    ) ;; when
  )
)

procedure( fdkDrawIndJumps_IndVias( pcCellView drTable paramTable)
  let(( bottomY coilSpace coilWidth copyCtr extension hJumpBL 
    hJumpBLPtList hJumpBLVias hJumpGroup hJumpTL jumpBL jumpBLInfo 
    jumpTL layerList leftX mult nJumpBL nJumpBLPtList nJumpBLVias 
    nJumpGroup nJumpTL nrturns rightX sJumpBL sJumpBLPtList 
    sJumpBLVias sJumpGroup sJumpTL startX startY termside topY 
    toplayer turn1A turn1B turnPitch turnPitch2 zJumpBL 
    zJumpBLPtList zJumpBLVias zJumpGroup zJumpTL)

    nrturns = paramTable["nrturns"]
    coilWidth = paramTable["coilwx"]
    coilSpace = paramTable["coilspcx"]
    toplayer = paramTable["toplayer"]
    termside = paramTable["termside"]
    layerList = drTable["layer"][toplayer]["jumpLayers"]
    jumpTL = car( layerList)
    jumpBL = cadr( layerList)

    ;; Find inner turns by name
    turn1A = drTable["TT"][sprintf( nil "%s_turn1_sideA" toplayer)]
    turn1B = drTable["TT"][sprintf( nil "%s_turn1_sideB" toplayer)]

    ;; Calculate jump slotting
    jumpBLInfo = fdkCalcTM1JumpBL( drTable paramTable)
    drTable["jumpBLInfo"] = jumpBLInfo
    extension = jumpBLInfo->extension

    ;; Generate jumps when more than one turn
    when( nrturns > 1
      turnPitch = coilWidth+coilSpace
      turnPitch2 = turnPitch*2
      if( termside == "Top" || termside == "Bottom" then
        topY = cadr( turn1A~>endLast)
        bottomY = cadr( turn1A~>start0)

        ;; An 'sJump' is a horizontal jump that connects lower
        ;; left to upper right, like an 'S'
        ;; Create base sJump and group
        sJumpGroup = dbCreateFigGroup( pcCellView "sJumpGroup" t 0:0 "R0")
        sJumpTL = rodCreatePath( ?cvId pcCellView ?layer jumpTL 
          ?width coilWidth ?pts list( car( turn1A~>start0):0
            0:0 0:turnPitch car( turn1B~>start0):turnPitch))
        dbAddFigToFigGroup( sJumpGroup sJumpTL~>dbId)
        sJumpBLPtList = list( car( turn1A~>start0):turnPitch 0:turnPitch 
            0:0 car( turn1B~>start0):0)
        sJumpBL = rodCreatePath( ?cvId pcCellView ?layer jumpBL 
          ?width jumpBLInfo->mainWidth ?offset jumpBLInfo->mainOffset 
          ?subRect jumpBLInfo->subRectList ?endType "variable" 
          ?offsetSubPath jumpBLInfo->offsetPathList
          ?beginExt extension ?endExt extension
          ?pts if( termside == "Top" sJumpBLPtList reverse( sJumpBLPtList)))
        foreach( shape sJumpBL~>subShapes 
          dbAddFigToFigGroup( sJumpGroup shape))
        dbAddFigToFigGroup( sJumpGroup sJumpBL~>dbId)

        ;; When vias defined as subpaths for width that allow multiple
        ;; via placements, create via subpaths
        when( jumpBLInfo->viaOffsetPathList 
          sJumpBLVias = rodCreatePath( ?cvId pcCellView ?layer jumpBL 
            ?width jumpBLInfo->mainWidth ?offset jumpBLInfo->mainOffset 
            ?offsetSubPath jumpBLInfo->viaOffsetPathList ?endType "variable" 
            ?beginExt jumpBLInfo->extension ?endExt jumpBLInfo->extension 
            ?pts if( termside == "Top" sJumpBLPtList reverse( sJumpBLPtList)))
          foreach( shape sJumpBLVias~>subShapes 
            dbAddFigToFigGroup( sJumpGroup shape))
          dbAddFigToFigGroup( sJumpGroup sJumpBLVias~>dbId)

          sJumpBLVias = rodCreatePath( ?cvId pcCellView ?layer jumpBL 
            ?width jumpBLInfo->mainWidth ?offset -(jumpBLInfo->mainOffset) 
            ?offsetSubPath jumpBLInfo->viaOffsetPathList2 ?endType "variable" 
            ?beginExt jumpBLInfo->extension ?endExt jumpBLInfo->extension 
            ?pts if( termside == "Top" reverse( sJumpBLPtList) sJumpBLPtList))
          foreach( shape sJumpBLVias~>subShapes 
            dbAddFigToFigGroup( sJumpGroup shape))
          dbAddFigToFigGroup( sJumpGroup sJumpBLVias~>dbId)
        ) ;; when

        startY = cond(
          (termside == "Top" && evenp( nrturns) topY+turnPitch)
          (termside == "Top" topY)
          (termside == "Bottom" && evenp( nrturns) bottomY-turnPitch2)
          (termside == "Bottom" bottomY-turnPitch))
        mult = if( termside == "Top" 1 -1)
        copyCtr = pcFix( nrturns*0.5) -
          if( evenp( nrturns) 2 1)

        ;; Copy sJump to coils on terminal side
        for( i 0 copyCtr
          dbCopyFig( sJumpGroup pcCellView 
            list( 0:startY+(turnPitch2*i)*mult "R0"))
        ) ;; for
        foreach( fig sJumpGroup~>figs dbDeleteObject( fig))
        dbDeleteObject( sJumpGroup)

        ;; A 'zJump' is a horizontal jump that connects upper
        ;; left to lower right, like a 'Z'
        ;; Create base zJump and group
        zJumpGroup = dbCreateFigGroup( pcCellView "zJumpGroup" t 0:0 "R0")
        zJumpTL = rodCreatePath( ?cvId pcCellView ?layer jumpTL 
          ?width coilWidth ?pts list( car( turn1A~>start0):0
            0:0 0:-turnPitch car( turn1B~>start0):-turnPitch))
        dbAddFigToFigGroup( zJumpGroup zJumpTL~>dbId)
        zJumpBLPtList = list( car( turn1A~>start0):-turnPitch
            0:-turnPitch 0:0 car( turn1B~>start0):0)
        zJumpBL = rodCreatePath( ?cvId pcCellView ?layer jumpBL 
          ?width jumpBLInfo->mainWidth ?offset jumpBLInfo->mainOffset 
          ?subRect jumpBLInfo->subRectList ?endType "variable" 
          ?offsetSubPath jumpBLInfo->offsetPathList
          ?beginExt jumpBLInfo->extension ?endExt jumpBLInfo->extension
          ?pts if( termside == "Top" zJumpBLPtList reverse( zJumpBLPtList)))
        foreach( shape zJumpBL~>subShapes 
          dbAddFigToFigGroup( zJumpGroup shape))
        dbAddFigToFigGroup( zJumpGroup zJumpBL~>dbId)

        ;; When vias defined as subpaths for width that allow multiple
        ;; via placements, create via subpaths
        when( jumpBLInfo->viaOffsetPathList 
          zJumpBLVias = rodCreatePath( ?cvId pcCellView ?layer jumpBL 
            ?width jumpBLInfo->mainWidth ?offset jumpBLInfo->mainOffset 
            ?offsetSubPath jumpBLInfo->viaOffsetPathList ?endType "variable" 
            ?beginExt jumpBLInfo->extension ?endExt jumpBLInfo->extension 
            ?pts if( termside == "Top" zJumpBLPtList reverse( zJumpBLPtList)))
          foreach( shape zJumpBLVias~>subShapes 
            dbAddFigToFigGroup( zJumpGroup shape))
          dbAddFigToFigGroup( zJumpGroup zJumpBLVias~>dbId)

          zJumpBLVias = rodCreatePath( ?cvId pcCellView ?layer jumpBL 
            ?width jumpBLInfo->mainWidth ?offset -(jumpBLInfo->mainOffset) 
            ?offsetSubPath jumpBLInfo->viaOffsetPathList2 ?endType "variable" 
            ?beginExt jumpBLInfo->extension ?endExt jumpBLInfo->extension 
            ?pts if( termside == "Top" reverse( zJumpBLPtList) zJumpBLPtList))
          foreach( shape zJumpBLVias~>subShapes 
            dbAddFigToFigGroup( zJumpGroup shape))
          dbAddFigToFigGroup( zJumpGroup zJumpBLVias~>dbId)
        ) ;; when

        startY = cond(
          (termside == "Top" && evenp( nrturns) bottomY)
          (termside == "Top" bottomY-turnPitch)
          (termside == "Bottom" && evenp( nrturns) topY+turnPitch)
          (termside == "Bottom" topY+turnPitch2))
        mult = if( termside == "Top" -1 1)
        copyCtr = pcFix( nrturns*0.5)-1

        ;; Copy zJump to coils on opposite side of terminals
        for( i 0 copyCtr
          dbCopyFig( zJumpGroup pcCellView 
            list( 0:startY+(turnPitch2*i)*mult "R0"))
        ) ;; for
        foreach( fig zJumpGroup~>figs dbDeleteObject( fig))
        dbDeleteObject( zJumpGroup)

      else ;; termside == "Left" || "Right"

        leftX = car( turn1A~>start0)
        rightX = car( turn1A~>endLast)

        ;; An 'nJump' is a vertical jump that connects lower
        ;; left to upper right, like an 'N'
        ;; Create base nJump and group
        nJumpGroup = dbCreateFigGroup( pcCellView "nJumpGroup" t 0:0 "R0")
        nJumpTL = rodCreatePath( ?cvId pcCellView ?layer jumpTL 
          ?width coilWidth ?pts list( 0:cadr( turn1A~>start0)
            0:0 turnPitch:0 turnPitch:cadr( turn1B~>start0)))
        dbAddFigToFigGroup( nJumpGroup nJumpTL~>dbId)
        nJumpBLPtList = list( turnPitch:cadr( turn1A~>start0)
          turnPitch:0 0:0 0:cadr( turn1B~>start0))
        nJumpBL = rodCreatePath( ?cvId pcCellView ?layer jumpBL 
          ?width jumpBLInfo->mainWidth ?offset jumpBLInfo->mainOffset 
          ?subRect jumpBLInfo->subRectList ?endType "variable" 
          ?offsetSubPath jumpBLInfo->offsetPathList
          ?beginExt jumpBLInfo->extension ?endExt jumpBLInfo->extension
          ?pts if( termside == "Right" nJumpBLPtList reverse( nJumpBLPtList)))
        foreach( shape nJumpBL~>subShapes 
          dbAddFigToFigGroup( nJumpGroup shape))
        dbAddFigToFigGroup( nJumpGroup nJumpBL~>dbId)

        ;; When vias defined as subpaths for width that allow multiple
        ;; via placements, create via subpaths
        when( jumpBLInfo->viaOffsetPathList 
          nJumpBLVias = rodCreatePath( ?cvId pcCellView ?layer jumpBL 
            ?width jumpBLInfo->mainWidth ?offset jumpBLInfo->mainOffset 
            ?offsetSubPath jumpBLInfo->viaOffsetPathList ?endType "variable" 
            ?beginExt jumpBLInfo->extension ?endExt jumpBLInfo->extension 
            ?pts if( termside == "Top" nJumpBLPtList reverse( nJumpBLPtList)))
          foreach( shape nJumpBLVias~>subShapes 
            dbAddFigToFigGroup( nJumpGroup shape))
          dbAddFigToFigGroup( nJumpGroup nJumpBLVias~>dbId)

          nJumpBLVias = rodCreatePath( ?cvId pcCellView ?layer jumpBL 
            ?width jumpBLInfo->mainWidth ?offset -(jumpBLInfo->mainOffset) 
            ?offsetSubPath jumpBLInfo->viaOffsetPathList2 ?endType "variable" 
            ?beginExt jumpBLInfo->extension ?endExt jumpBLInfo->extension 
            ?pts if( termside == "Top" reverse( nJumpBLPtList) nJumpBLPtList))
          foreach( shape nJumpBLVias~>subShapes 
            dbAddFigToFigGroup( nJumpGroup shape))
          dbAddFigToFigGroup( nJumpGroup nJumpBLVias~>dbId)
        ) ;; when

        startX = cond(
          (termside == "Right" && evenp( nrturns) rightX+turnPitch)
          (termside == "Right" rightX)
          (termside == "Left" && evenp( nrturns) rightX)
          (termside == "Left" rightX+turnPitch))
        mult = 1
        copyCtr = pcFix( nrturns*0.5) - 
          if( evenp( nrturns) && termside == "Right" 2 1)

        ;; Copy nJump to coils on terminal side
        for( i 0 copyCtr
          dbCopyFig( nJumpGroup pcCellView 
            list( startX+(turnPitch2*i)*mult:0 "R0"))
        ) ;; for
        foreach( fig nJumpGroup~>figs dbDeleteObject( fig))
        dbDeleteObject( nJumpGroup)

        ;; An 'hJump' is a vertical jump that connects upper
        ;; left to lower right, like an 'h' (not really, but 
        ;; we are going with that ;)
        ;; Create base hJump and group
        hJumpGroup = dbCreateFigGroup( pcCellView "hJumpGroup" t 0:0 "R0")
        hJumpTL = rodCreatePath( ?cvId pcCellView ?layer jumpTL 
          ?width coilWidth ?pts list( 0:cadr( turn1A~>start0)
            0:0 -turnPitch:0 -turnPitch:cadr( turn1B~>start0)))
        dbAddFigToFigGroup( hJumpGroup hJumpTL~>dbId)
        hJumpBLPtList = list( -turnPitch:cadr( turn1A~>start0)
          -turnPitch:0 0:0 0:cadr( turn1B~>start0))
        hJumpBL = rodCreatePath( ?cvId pcCellView ?layer jumpBL 
          ?width jumpBLInfo->mainWidth ?offset jumpBLInfo->mainOffset 
          ?subRect jumpBLInfo->subRectList ?endType "variable" 
          ?offsetSubPath jumpBLInfo->offsetPathList
          ?beginExt jumpBLInfo->extension ?endExt jumpBLInfo->extension
          ?pts if( termside == "Right" hJumpBLPtList reverse( hJumpBLPtList)))
        foreach( shape hJumpBL~>subShapes 
          dbAddFigToFigGroup( hJumpGroup shape))
        dbAddFigToFigGroup( hJumpGroup hJumpBL~>dbId)

        ;; When vias defined as subpaths for width that allow multiple
        ;; via placements, create via subpaths
        when( jumpBLInfo->viaOffsetPathList 
          hJumpBLVias = rodCreatePath( ?cvId pcCellView ?layer jumpBL 
            ?width jumpBLInfo->mainWidth ?offset jumpBLInfo->mainOffset 
            ?offsetSubPath jumpBLInfo->viaOffsetPathList ?endType "variable" 
            ?beginExt jumpBLInfo->extension ?endExt jumpBLInfo->extension 
            ?pts if( termside == "Top" hJumpBLPtList reverse( hJumpBLPtList)))
          foreach( shape hJumpBLVias~>subShapes 
            dbAddFigToFigGroup( hJumpGroup shape))
          dbAddFigToFigGroup( hJumpGroup hJumpBLVias~>dbId)

          hJumpBLVias = rodCreatePath( ?cvId pcCellView ?layer jumpBL 
            ?width jumpBLInfo->mainWidth ?offset -(jumpBLInfo->mainOffset) 
            ?offsetSubPath jumpBLInfo->viaOffsetPathList2 ?endType "variable" 
            ?beginExt jumpBLInfo->extension ?endExt jumpBLInfo->extension 
            ?pts if( termside == "Top" reverse( hJumpBLPtList) hJumpBLPtList))
          foreach( shape hJumpBLVias~>subShapes 
            dbAddFigToFigGroup( hJumpGroup shape))
          dbAddFigToFigGroup( hJumpGroup hJumpBLVias~>dbId)
        ) ;; when

        startX = cond(
          (termside == "Right" && evenp( nrturns) leftX)
          (termside == "Right" leftX-turnPitch)
          (termside == "Left" && evenp( nrturns) leftX-turnPitch)
          (termside == "Left" leftX))
        mult = -1
        copyCtr = pcFix( nrturns*0.5)-
          if( evenp( nrturns) && termside == "Left" 2 1)

        for( i 0 copyCtr
          dbCopyFig( hJumpGroup pcCellView 
            list( startX+(turnPitch2*i)*mult:0 "R0"))
        ) ;; for
        foreach( fig hJumpGroup~>figs dbDeleteObject( fig))
        dbDeleteObject( hJumpGroup)

      ) ;; if
    ) ;; when
  )
)

procedure( fdkCalcTM1JumpBL( drTable paramTable)
  let(( bottomlayer coilSpace coilWidth extension fillerWidth1 
    fillerWidth2 infoList jumpLength layerList mainOffset mainWidth
    maxWidthBL minGrid minSpaceBL minWidthBL numVia offsetPathList 
    outerPitch1 outerPitch2 pitch viaOffsetPathList remainingSpace1 
    remainingSpace2 runningOffset sigWidth subRectList toplayer 
    via viaBotEnc viaBotInsideEnc viaLayer viaLength 
    viaOffsetPathList2 viaSep viaSepList viaSpace viaTopEnc viaWidth)

    ;; Retrieve parameter and design rule values
    coilWidth = paramTable["coilwx"]
    coilSpace = paramTable["coilspcx"]
    toplayer = paramTable["toplayer"]
    layerList = drTable["layer"][toplayer]["jumpLayers"]
    bottomlayer = cadr( layerList)
    minGrid = drTable["minGrid"]
    maxWidthBL = drTable["layer"][bottomlayer]["maxWidth"]
    minWidthBL = drTable["layer"][bottomlayer]["minWidth"]
    minSpaceBL = drTable["layer"][bottomlayer]["minSpace"]
    viaLayer = fdkPcLayer( drTable["layer"][toplayer]["viaLayer"])
    via = car( viaLayer)
    viaWidth = drTable["via"][via]["width"]
    viaLength = drTable["via"][via]["length"]
    viaSpace = drTable["via"][via]["space"]
    viaTopEnc = drTable["via"][via][toplayer]["enc"]
    viaBotEnc = drTable["via"][via][bottomlayer]["enc"]
    infoList = list( nil 'mainWidth nil 'mainOffset nil 
      'offsetPathList nil 'viaOffsetPathList nil 'extension nil)
    extension = viaBotEnc+viaLength+viaTopEnc
    infoList->extension = extension

    ;; Calculate the number of vias that will fit in the tm1 jump
    ;; We will assume toplayer width will fit at least one via
    numVia = max( 
      pcFix( (coilWidth-2*viaTopEnc-viaWidth)/(viaWidth+viaSpace))+1 1)

    ;; Calculate location of vias and bottom layer
    cond( 
      ;; For a single via, we will generate a single jump of bottomlayer
      ;; at maxWidth centered on toplayer coil
      ( onep( numVia)

        infoList->mainWidth = maxWidthBL
        infoList->mainOffset = 0.0

        ;; Place via at the beginning and end of jump
        subRectList = list( list( ?layer viaLayer ?width viaWidth
          ?length viaLength ?space viaSpace ?gap "minimum" ?beginOffset -viaBotEnc 
          ?beginSegOffset fdkSnapGrid( minGrid
            coilWidth-(coilWidth-maxWidthBL)*0.5+coilSpace+viaTopEnc)))

        ;; If coil width is wide enough, we will generate metal filler 
        ;; on both sides of the bottomlayer jump to meet minSpace & minWidth
        when( coilWidth > maxWidthBL+2*minSpaceBL+2*minWidthBL
          remainingSpace1 = fdkSnapGrid( minGrid
            (coilWidth-maxWidthBL-2*minSpaceBL-2*minWidthBL)*0.5)
          fillerWidth1 = minWidthBL+remainingSpace1
          remainingSpace2 = coilWidth-maxWidthBL-2*minSpaceBL-
            2*minWidthBL-remainingSpace1
          fillerWidth2 = minWidthBL+remainingSpace2
          offsetPathList = list( 
            list( ?layer bottomlayer ?width fillerWidth1
              ?sep (maxWidthBL+fillerWidth1)*0.5+minSpaceBL)
            list( ?layer bottomlayer ?width fillerWidth2
              ?sep -((maxWidthBL+fillerWidth2)*0.5+minSpaceBL)))
          infoList->offsetPathList = offsetPathList

          ;; Add bottomlayer strap to connect jump and fillers
          subRectList = cons( list( ?layer bottomlayer ?width coilWidth
            ?length maxWidthBL ?gap "minimum" 
            ?beginOffset -(viaBotEnc+(viaLength-maxWidthBL)*0.5 )
            ?beginSegOffset fdkSnapGrid( minGrid
              coilWidth-(coilWidth-maxWidthBL)*0.5+coilSpace+viaTopEnc+
              (viaLength-maxWidthBL)*0.5))
            subRectList)
          infoList->subRectStrapDPL = list( nil 'layer bottomlayer 
            'width coilWidth 'length maxWidthBL 
            'beginOffset viaBotEnc+(viaLength-maxWidthBL)*0.5)
        ) ;; when
        infoList->subRectList = subRectList
        infoList->subRectViaDPL = list( nil 'layer viaLayer 'width viaWidth
          'length viaLength 'beginOffset viaBotEnc)
      )

      ;; For multiple vias, we will place the edge vias at toplayer
      ;; overlap of via and then distribute the rest of the vias within
      ;; the width of the coil
      ( t ;; More than one via

        ;; Calculate via spacing to distribute them within the coil width
        viaSpace = (coilWidth-2*viaTopEnc-viaWidth*numVia)/(numVia-1)

        ;; Calculate bottomlayer via enclose to maintain bottomlayer
        ;; minSpace rule when calculated via space is greater than viaSpace
        viaBotInsideEnc = fdkSnapDownGrid( minGrid (viaSpace-minSpaceBL)*0.5)

        mainWidth = fdkSnapDownGrid( minGrid*2 
          viaTopEnc+viaWidth+viaBotInsideEnc)
        mainOffset = (coilWidth-mainWidth)*0.5
        sigWidth = 2*viaBotInsideEnc+viaWidth
        pitch = sigWidth+minSpaceBL
        outerPitch1 = mainWidth*0.5-viaBotInsideEnc+viaSpace+viaWidth*0.5
        remainingSpace1 = coilWidth-2*mainWidth-sigWidth*max( numVia-2 0)-
          minSpaceBL*max( numVia-2 0)
        outerPitch2 = coilWidth-mainWidth
        runningOffset = outerPitch1
        jumpLength = extension+3*coilSpace+2*coilWidth+viaTopEnc

        ;; Calculate topmost via location based on viaTopEnc
        viaSep = -mainWidth*0.5+viaTopEnc+viaWidth*0.5
        viaOffsetPathList = list( list( ?layer viaLayer ?width viaWidth 
          ?beginOffset -viaBotEnc ?endOffset -jumpLength
          ?sep viaSep))
        viaSepList = list( viaSep mainWidth*0.5)
        viaOffsetPathList2 = list( list( ?layer viaLayer ?width viaWidth 
          ?beginOffset -viaBotEnc ?endOffset -jumpLength ?sep -viaSep))

        ;; Calculate inside via locations
        for( i 2 numVia-1
          offsetPathList = cons( list( ?layer bottomlayer ?width sigWidth
            ?sep runningOffset) offsetPathList)
          viaOffsetPathList = cons( list( ?layer viaLayer ?width viaWidth 
            ?beginOffset -viaBotEnc ?endOffset -jumpLength 
            ?sep runningOffset) viaOffsetPathList)
          viaSepList = cons( runningOffset viaSepList)
          viaOffsetPathList2 = cons( list( ?layer viaLayer ?width viaWidth 
            ?beginOffset -viaBotEnc ?endOffset -jumpLength
            ?sep -runningOffset) viaOffsetPathList2)
          runningOffset = runningOffset+pitch
        ) ;; for

        ;; Calculate bottommost via location based on viaTopEnc
        offsetPathList = cons( list( ?layer bottomlayer
          ?width mainWidth ?sep outerPitch2) 
          offsetPathList)
        viaSep = outerPitch2+mainWidth*0.5-
          viaTopEnc-viaWidth*0.5
        viaOffsetPathList = cons( list( ?layer viaLayer ?width viaWidth 
          ?beginOffset -viaBotEnc ?endOffset -jumpLength
          ?sep viaSep) viaOffsetPathList)
        viaSepList = cons( viaSep viaSepList)
        viaOffsetPathList2 = cons( list( ?layer viaLayer ?width viaWidth 
          ?beginOffset -viaBotEnc ?endOffset -jumpLength
          ?sep -viaSep) viaOffsetPathList2)

        ;; Add bottomlayer strap to connect jump and fillers
        viaOffsetPathList2 = cons( list( ?layer bottomlayer ?width coilWidth 
          ?beginOffset -(viaBotEnc+(viaLength-maxWidthBL)*0.5) 
          ?endOffset -(jumpLength+(viaLength-maxWidthBL)*0.5)
          ?sep -(coilWidth-mainWidth)*0.5) viaOffsetPathList2)

        infoList->subRectStrapDPL = list( nil 'layer bottomlayer 
          'width coilWidth 'length maxWidthBL 
          'beginOffset viaBotEnc+(viaLength-maxWidthBL)*0.5)
        infoList->offsetPathViaDPL = list( nil 'layer viaLayer 
          'width viaWidth 'length viaLength 'beginOffset viaBotEnc 
          'viaSepList reverse( viaSepList))

        infoList->mainWidth = mainWidth
        infoList->mainOffset = -mainOffset
        infoList->offsetPathList = offsetPathList
        infoList->subRectList = subRectList
        infoList->viaOffsetPathList = viaOffsetPathList
        infoList->viaOffsetPathList2 = viaOffsetPathList2
      )
    ) ;; cond

    infoList ;; Return value
  )
)

procedure( fdkDrawStaplesInBbox( pcCellView bBoxType bBox stapleLayer 
  stapleWidth stapleLength stapleSpace viaLayer viaWidth viaLength 
  viaSpace viaEncX viaEncY remainingSpace @optional (gap "minimum"))
  let(( stapleShapeList)

    bBox = pcGrowBox( bBox 0) ;; Reset bBox to lowerLeft/upperRight
    if( bBoxType == "HOR" || (bBoxType == "CALC" &&
      abs( caadr( bBox)-caar( bBox)) > abs( cadadr( bBox)-cadar( bBox))) then
      ;; Horizontal bounding box
      stapleShapeList = rodFillBBoxWithRects( ?cvId pcCellView
        ?layer stapleLayer ?width stapleWidth ?length stapleLength
        ?fillBBox bBox ?spaceX stapleSpace ?spaceY stapleSpace ?gap gap)
      stapleShapeList = append( rodFillBBoxWithRects( ?cvId pcCellView
        ?layer viaLayer ?width viaWidth ?length viaLength
        ?fillBBox list( caar( bBox)+viaEncX:cadar( bBox)+viaEncY+remainingSpace
          caadr( bBox)-viaEncX:cadadr( bBox)-viaEncY)
        ?spaceX stapleSpace+2*viaEncX ?spaceY viaSpace ?gap gap)
        stapleShapeList)
    else ;; Vertical bounding box
      stapleShapeList = rodFillBBoxWithRects( ?cvId pcCellView
        ?layer stapleLayer ?width stapleLength ?length stapleWidth
        ?fillBBox bBox ?spaceX stapleSpace ?spaceY stapleSpace ?gap gap)
      stapleShapeList = append( rodFillBBoxWithRects( ?cvId pcCellView
        ?layer viaLayer ?width viaLength ?length viaWidth
        ?fillBBox list( caar( bBox)+viaEncY+remainingSpace:cadar( bBox)+viaEncX
          caadr( bBox)-viaEncY:cadadr( bBox)-viaEncX)
        ?spaceY stapleSpace+2*viaEncX ?spaceX viaSpace ?gap gap)
        stapleShapeList)
    ) ;; if
    stapleShapeList ;; Return value
  )
)

procedure( fdkDrawIndCentertap_OneMetalStraight( pcCellView 
  drTable paramTable)
  let(( bBox bTerm bridge coilSpace coilWidth coilWidthHalf ct 
    ctBaseId ctId ctLL ctLayer ctLength ctUR eTurns enc endPt 
    extent handle lTerm lrTerm minGrid minSpace mult nrturns 
    oTurns pinBbox pitch ptList rTerm rbTerm sep shapeId 
    startPt tTerm tbTerm termside toplayer vLL vLength 
    vUR vWidth via viaBotEnc viaId viaLayer viaLength 
    viaLengthHalf viaTopEnc viaWidth xSep ySep)

    ;; Retrieve parameter and design rule values
    nrturns = paramTable["nrturns"]
    toplayer = paramTable["toplayer"]
    termside = paramTable["termside"]
    coilWidth = paramTable["coilwx"]
    coilSpace = paramTable["coilspcx"]
    extent = paramTable["termext"]
    ctLayer = fdkPcLayer( car( drTable["layer"][toplayer]["ctLayers"]))
    ct = car( ctLayer)
    viaLayer = fdkPcLayer( drTable["layer"][ct]["viaLayer"])
    via = car( viaLayer)
    viaWidth = drTable["via"][via]["width"]
    viaLength = drTable["via"][via]["length"]
    viaTopEnc = drTable["via"][via][ct]["enc"]
    viaBotEnc = drTable["via"][via][toplayer]["enc"]
    minGrid = drTable["minGrid"]
    minSpace = drTable["layer"][toplayer]["minSpace"]

    ;; Computations
    pitch = coilWidth+coilSpace
    rbTerm = member( termside list( "Right" "Bottom"))
    tbTerm = member( termside list( "Top" "Bottom"))
    lrTerm = member( termside list( "Left" "Right"))
    tTerm = termside == "Top"
    bTerm = termside == "Bottom"
    lTerm = termside == "Left"
    rTerm = termside == "Right"
    eTurns = evenp( nrturns)
    oTurns = !eTurns
    coilWidthHalf = fdkSnapGrid( minGrid coilWidth*0.5)
    viaLengthHalf = fdkSnapGrid( minGrid viaLength*0.5)

    ;; Find bridge from which centertap will originate
    bridge = rodGetObj( "ind_bridge" pcCellView)

    ;; Create centertap dependent on number of turns 
    cond(
      ;; For single turn, centertap will be located opposite
      ;; to terminals.
      ( onep( nrturns)
        ctLength = extent
        startPt = if( rbTerm bridge~>midLeft0 bridge~>midRight0)
        ptList = case( termside
          ( "Right" list( startPt car( startPt)-ctLength:cadr( startPt)))
          ( "Left" list( startPt car( startPt)+ctLength:cadr( startPt)))
          ( "Top" list( startPt car( startPt):cadr( startPt)-ctLength))
          ( "Bottom" list( startPt car( startPt):cadr( startPt)+ctLength))
        ) ;; case
        ctId = rodCreatePath( ?cvId pcCellView ?name "ind_centertap" 
          ?layer toplayer ?width coilWidth ?pts ptList 
          ?prop list( "endPt" cadr( ptList)))
      )
      ;; For two turns, centertap will be located between terminals.
      ( nrturns == 2
        ctLength = pitch+extent
        startPt = if( lrTerm bridge~>midRight0 bridge~>midLeft0)
        ptList = case( termside
          ( "Right" list( startPt car( startPt)+ctLength:cadr( startPt)))
          ( "Left" list( startPt car( startPt)-ctLength:cadr( startPt)))
          ( "Top" list( startPt car( startPt):cadr( startPt)+ctLength))
          ( "Bottom" list( startPt car( startPt):cadr( startPt)-ctLength))
        ) ;; case
        ctId = rodCreatePath( ?cvId pcCellView ?name "ind_centertap" 
          ?layer toplayer ?width coilWidth ?pts ptList
          ?prop list( "endPt" cadr( ptList)))
      )
      ;; For turns greater than two, centertap will be located between 
      ;; terminals for even number turns, and opposite terminals for
      ;; odd number turns.
      ( t 
        ;; Create coil via and overlaping layer on bridge
        vWidth = if( tbTerm viaLength viaWidth)
        vLength = if( tbTerm viaWidth viaLength)
        viaId = rodCreateRect( ?cvId pcCellView ?layer viaLayer
          ?width vWidth ?length vLength)
        rodAlign( ?alignObj viaId ?alignHandle "centerCenter" 
          ?refObj bridge ?refHandle "centerCenter" ?maintain nil)
        ctBaseId = rodCreateRect( ?cvId pcCellView ?layer ctLayer 
          ?fromObj viaId ?size viaTopEnc)

        ;; Create centertap via and overlaping layers
        viaId = rodCreateRect( ?cvId pcCellView ?layer viaLayer
          ?width vLength ?length vWidth)
        sep = coilWidthHalf+pitch*(nrturns-1)+minSpace+viaBotEnc+viaLengthHalf
        when( eTurns sep = -sep)
        xSep = cond( (tbTerm 0) (rTerm -sep) (lTerm sep))
        ySep = cond( (lrTerm 0) (tTerm -sep) (bTerm sep))
        rodAlign( ?alignObj viaId ?alignHandle "centerCenter" 
          ?refObj bridge ?refHandle "centerCenter" 
          ?xSep xSep ?ySep ySep ?maintain nil)
        handle = cond( ((tTerm && oTurns)||(bTerm && eTurns) "mid1") 
          ((bTerm && oTurns)||(tTerm && eTurns) "mid3") 
          ((rTerm && oTurns)||(lTerm && eTurns) "mid2") 
          ((lTerm && oTurns)||(rTerm && eTurns) "mid0"))
        ctId = shapeId = rodCreateRect( ?cvId pcCellView ?name "ind_centertap"
          ?layer toplayer ?width if( tbTerm coilWidth extent-minSpace)
          ?length if( tbTerm extent-minSpace coilWidth) 
          ?prop list( "handle" case( handle ("mid0" "mid2") ("mid1" "mid3")
            ("mid2" "mid0") ("mid3" "mid1"))))
        sep = viaBotEnc
        when( eTurns sep = -sep)
        xSep = cond( (tbTerm 0) (rTerm sep) (lTerm -sep))
        ySep = cond( (lrTerm 0) (tTerm sep) (bTerm -sep))
        rodAlign( ?alignObj shapeId ?alignHandle handle
          ?refObj viaId ?refHandle handle
          ?xSep xSep ?ySep ySep ?maintain nil)
        vLL = viaId~>start0
        vUR = viaId~>start2
        ctLL = ctBaseId~>start0
        ctUR = ctBaseId~>start1
        enc = viaTopEnc
        bBox = 
          cond(
          ( (bTerm && oTurns)||(tTerm && eTurns) 
            list( car( vLL)-enc:cadr( ctUR) car( vUR)+enc:cadr( vUR)+enc))
          ( (tTerm && oTurns)||(bTerm && eTurns) 
            list( car( vLL)-enc:cadr( vLL)-enc car( vUR)+enc:cadr( ctLL)))
          ( (rTerm && oTurns)||(lTerm && eTurns) 
            list( car( vLL)-enc:cadr( vLL)-enc car( ctLL):cadr( vUR)+enc))
          ( (lTerm && oTurns)||(rTerm && eTurns) 
            list( car( ctLL):cadr( vLL)-enc car( vUR)+enc:cadr( vUR)+enc)))
        rodCreateRect( ?cvId pcCellView ?layer ctLayer ?bBox bBox)
      )
    ) ;; cond

    ;; Save pinBbox for centertap
    endPt = ctId~>dbId~>endPt || rodGetHandle( ctId ctId~>dbId~>handle)
    mult = if( eTurns 1 -1)
    case( termside
      ( "Right" 
        pinBbox = list( car( endPt)-coilWidth*mult:cadr( endPt)-coilWidthHalf 
          car( endPt):cadr( endPt)+coilWidthHalf))
      ( "Left" 
        pinBbox = list( car( endPt):cadr( endPt)-coilWidthHalf
          car( endPt)+coilWidth*mult:cadr( endPt)+coilWidthHalf))
      ( "Top" 
        pinBbox = list( car( endPt)-coilWidthHalf:cadr( endPt)-coilWidth*mult 
          car( endPt)+coilWidthHalf:cadr( endPt)))
      ( "Bottom" 
        pinBbox = list( car( endPt)-coilWidthHalf:cadr( endPt)
          car( endPt)+coilWidthHalf:cadr( endPt)+coilWidth*mult)))
    ctId~>dbId~>pinBbox = pinBbox
  )
)

procedure( fdkDrawIndCentertap_TwoMetalsStraight( pcCellView 
  drTable paramTable)
  let(( bBox bTerm bottomlayer bridge coilSpace coilWidth 
    coilWidthHalf ct ctBLId ctBaseId ctId ctLL ctLayer ctLength 
    ctUR dontDrawHorStaples eTurns enc endPt extent handle holeArea
    lTerm layerList lrTerm mainOffset maxWidthBL minGrid minSpace 
    minSpaceBL mult newPt nrturns oTurns offsetPathList pinBbox 
    pitch ptList rTerm remainingSpace sep shapeId sigWidth 
    slotWidth stapleArrayWidth stapleGap stapleList stapleSpace 
    stapleWidth startPt tTerm tbTerm termside toplayer vLL vLength 
    vUR vWidth via viaBotEnc viaEncX viaEncY viaId viaLayer 
    viaLength viaLengthHalf viaSpace viaTopEnc viaWidth xSep ySep)

    ;; Retrieve parameter and design rule values
    nrturns = paramTable["nrturns"]
    toplayer = paramTable["toplayer"]
    layerList = drTable["layer"][toplayer]["layers"]
    bottomlayer = cadr( layerList)
    termside = paramTable["termside"]
    coilWidth = paramTable["coilwx"]
    coilSpace = paramTable["coilspcx"]
    extent = paramTable["termext"]
    ctLayer = fdkPcLayer( car( drTable["layer"][toplayer]["ctLayers"]))
    ct = car( ctLayer)
    viaLayer = fdkPcLayer( drTable["layer"][ct]["viaLayer"])
    via = car( viaLayer)
    viaWidth = drTable["via"][via]["width"]
    viaLength = drTable["via"][via]["length"]
    viaSpace = drTable["via"][via]["space"]
    viaTopEnc = drTable["via"][via][ct]["enc"]
    viaBotEnc = drTable["via"][via][toplayer]["enc"]
    minGrid = drTable["minGrid"]
    minSpace = drTable["layer"][toplayer]["minSpace"]
    offsetPathList = drTable[bottomlayer]->offsetPathList
    mainOffset = drTable[bottomlayer]->mainOffset
    sigWidth = drTable[bottomlayer]->sigWidth
    stapleArrayWidth = drTable["stapleArrayWidth"]
    stapleWidth = drTable["stapleWidth"]
    stapleList = drTable["layer"][toplayer]["stapleList"]
    remainingSpace = drTable["stapleRemainingSpace"]
    minSpaceBL = drTable["layer"][bottomlayer]["minSpace"]
    maxWidthBL = drTable["layer"][bottomlayer]["maxWidth"]

    ;; Computations
    pitch = coilWidth+coilSpace
    tbTerm = member( termside list( "Top" "Bottom"))
    lrTerm = member( termside list( "Left" "Right"))
    tTerm = termside == "Top"
    bTerm = termside == "Bottom"
    lTerm = termside == "Left"
    rTerm = termside == "Right"
    eTurns = evenp( nrturns)
    oTurns = !eTurns
    coilWidthHalf = fdkSnapGrid( minGrid coilWidth*0.5)
    viaLengthHalf = fdkSnapGrid( minGrid viaLength*0.5)

    ;; Find bridge from which centertap will originate
    bridge = rodGetObj( "ind_bridge" pcCellView)

    ;; Create centertap dependent on number of turns 
    cond(
      ;; For single turn, centertap will be located opposite
      ;; to terminals.
      ( onep( nrturns)
        ctLength = extent
        startPt = if( tbTerm bridge~>midLeft0 bridge~>midRight0)
        ptList = case( termside
          ( "Right" list( startPt car( startPt)-ctLength:cadr( startPt)))
          ( "Left" list( startPt car( startPt)+ctLength:cadr( startPt)))
          ( "Top" list( startPt car( startPt):cadr( startPt)-ctLength))
          ( "Bottom" list( startPt car( startPt):cadr( startPt)+ctLength))
        ) ;; case
        ctId = rodCreatePath( ?cvId pcCellView ?name "ind_centertap" 
          ?layer toplayer ?width coilWidth ?pts ptList 
          ?prop list( "endPt" cadr( ptList)))
        ctBLId = rodCreatePath( ?cvId pcCellView ?layer bottomlayer 
          ?width sigWidth ?pts ptList ?offset -mainOffset-minGrid 
          ?offsetSubPath offsetPathList)
      )
      ;; For two turns, centertap will be located between terminals.
      ( nrturns == 2
        ctLength = pitch+extent
        startPt = if( lrTerm bridge~>midRight0 bridge~>midLeft0)
        ptList = case( termside
          ( "Right" list( startPt car( startPt)+ctLength:cadr( startPt)))
          ( "Left" list( startPt car( startPt)-ctLength:cadr( startPt)))
          ( "Top" list( startPt car( startPt):cadr( startPt)+ctLength))
          ( "Bottom" list( startPt car( startPt):cadr( startPt)-ctLength))
        ) ;; case
        ctId = rodCreatePath( ?cvId pcCellView ?name "ind_centertap" 
          ?layer toplayer ?width coilWidth ?pts ptList
          ?prop list( "endPt" cadr( ptList)))
        ctBLId = rodCreatePath( ?cvId pcCellView ?layer bottomlayer 
          ?width sigWidth ?pts ptList ?offset -mainOffset-minGrid 
          ?offsetSubPath offsetPathList)
      )
      ;; For turns greater than two, centertap will be located between 
      ;; terminals for even number turns, and opposite terminals for
      ;; odd number turns.
      ( t
        ;; Create coil via and overlaping layer on bridge
        vWidth = if( tbTerm viaLength viaWidth)
        vLength = if( tbTerm viaWidth viaLength)
        viaId = rodCreateRect( ?cvId pcCellView ?layer viaLayer
          ?width vWidth ?length vLength)
        rodAlign( ?alignObj viaId ?alignHandle "centerCenter" 
          ?refObj bridge ?refHandle "centerCenter" ?maintain nil)
        ctBaseId = rodCreateRect( ?cvId pcCellView ?layer ctLayer 
          ?fromObj viaId ?size viaTopEnc)

        ;; Create centertap via and overlaping layers
        viaId = rodCreateRect( ?cvId pcCellView ?layer viaLayer
          ?width vLength ?length vWidth)
        sep = coilWidthHalf+pitch*(nrturns-1)+minSpace+viaBotEnc+viaLengthHalf
        when( eTurns sep = -sep)
        xSep = cond( (tbTerm 0) (rTerm -sep) (lTerm sep))
        ySep = cond( (lrTerm 0) (tTerm -sep) (bTerm sep))
        rodAlign( ?alignObj viaId ?alignHandle "centerCenter" 
          ?refObj bridge ?refHandle "centerCenter" 
          ?xSep xSep ?ySep ySep ?maintain nil)
        handle = cond( ((tTerm && oTurns)||(bTerm && eTurns) "mid1") 
          ((bTerm && oTurns)||(tTerm && eTurns) "mid3") 
          ((rTerm && oTurns)||(lTerm && eTurns) "mid2") 
          ((lTerm && oTurns)||(rTerm && eTurns) "mid0"))
        ctId = shapeId = rodCreateRect( ?cvId pcCellView ?name "ind_centertap"
          ?layer toplayer ?width if( tbTerm coilWidth extent-minSpace)
          ?length if( tbTerm extent-minSpace coilWidth) 
          ?prop list( "handle" case( handle ("mid0" "mid2") ("mid1" "mid3")
            ("mid2" "mid0") ("mid3" "mid1"))))
        sep = viaBotEnc
        when( eTurns sep = -sep)
        xSep = cond( (tbTerm 0) (rTerm sep) (lTerm -sep))
        ySep = cond( (lrTerm 0) (tTerm sep) (bTerm -sep))
        rodAlign( ?alignObj shapeId ?alignHandle handle
          ?refObj viaId ?refHandle handle
          ?xSep xSep ?ySep ySep ?maintain nil)
        ctBLId = rodCreatePath( ?cvId pcCellView ?layer bottomlayer 
          ?width sigWidth ?pts if( tbTerm list( shapeId~>mid1 shapeId~>mid3) 
             list( shapeId~>mid0 shapeId~>mid2)) 
          ?offset -mainOffset-minGrid ?offsetSubPath offsetPathList)
        vLL = viaId~>start0
        vUR = viaId~>start2
        ctLL = ctBaseId~>start0
        ctUR = ctBaseId~>start1
        enc = viaTopEnc
        bBox = 
          cond(
          ( (bTerm && oTurns)||(tTerm && eTurns) 
            list( car( vLL)-enc:cadr( ctUR) car( vUR)+enc:cadr( vUR)+enc))
          ( (tTerm && oTurns)||(bTerm && eTurns) 
            list( car( vLL)-enc:cadr( vLL)-enc car( vUR)+enc:cadr( ctLL)))
          ( (rTerm && oTurns)||(lTerm && eTurns) 
            list( car( vLL)-enc:cadr( vLL)-enc car( ctLL):cadr( vUR)+enc))
          ( (lTerm && oTurns)||(rTerm && eTurns) 
            list( car( ctLL):cadr( vLL)-enc car( vUR)+enc:cadr( vUR)+enc)))
        rodCreateRect( ?cvId pcCellView ?layer ctLayer ?bBox bBox)
      )
    ) ;; cond

    ;; Add staple array to centertap
    viaLayer = fdkPcLayer( drTable["layer"][toplayer]["viaLayer"])
    via = car( viaLayer)
    viaWidth = drTable["via"][via]["width"]
    viaLength = drTable["via"][via]["length"]
    viaSpace = drTable["via"][via]["space"]
    viaEncX = drTable["stapleViaEncX"]
    viaEncY = drTable["via"][via][bottomlayer]["enc"]
    holeArea = drTable["layer"][bottomlayer]["holeArea"]
    slotWidth = drTable[bottomlayer]->sigSpace
    stapleSpace = max( minSpaceBL viaSpace-2*viaEncX)
    when( termside == "Left" || termside == "Right"
      stapleSpace = max( stapleSpace fdkSnapUpGrid( minGrid holeArea/slotWidth))
    ) ;; when
    stapleGap = "minimum"
    dontDrawHorStaples = drTable["dontDrawHorStaples"]
    endPt = ctId~>dbId~>endPt || rodGetHandle( ctId ctId~>dbId~>handle)
    mult = if( eTurns 1 -1)
    when( dontDrawHorStaples 
      stapleGap = "distribute"
      stapleArrayWidth = coilWidth)
    case( termside
      ( "Right" 
        bBox = list( car( endPt)-stapleArrayWidth*mult:
          cadr( endPt)-coilWidthHalf car( endPt):cadr( endPt)+coilWidthHalf)
        pinBbox = list( car( endPt)-coilWidth*mult:cadar( bBox) cadr( bBox)))
      ( "Left" 
        bBox = list( car( endPt):cadr( endPt)-coilWidthHalf
          car( endPt)+stapleArrayWidth*mult:cadr( endPt)+coilWidthHalf)
        pinBbox = list( car( bBox) car( endPt)+coilWidth*mult:cadadr( bBox)))
      ( "Top" 
        bBox = list( car( endPt)-coilWidthHalf:
          cadr( endPt)-stapleArrayWidth*mult
          car( endPt)+coilWidthHalf:cadr( endPt))
        pinBbox = list( caar( bBox):cadr( endPt)-coilWidth*mult cadr( bBox)))
      ( "Bottom" 
        bBox = list( car( endPt)-coilWidthHalf:cadr( endPt)
          car( endPt)+coilWidthHalf:cadr( endPt)+stapleArrayWidth*mult)
        pinBbox = list( car( bBox) caadr( bBox):cadr( endPt)+coilWidth*mult)))

    when( member( "terminal" stapleList)

      if( dontDrawHorStaples && member( termside list( "Top" "Bottom")) then
        fdkDrawStaplesInBbox( pcCellView "HOR" pinBbox 
          bottomlayer stapleWidth coilWidth stapleSpace viaLayer 
          viaWidth viaLength viaSpace viaEncX viaEncY 0 "distribute")
  
        ;; Retract bottomlayer slotted end where vertical staples are
        ptList = ctBLId~>dbId~>points
        endPt = if( ctId~>dbId~>objType == "rect" 
          ctId~>mid1 car( ctId~>dbId~>points))
        cond(
          ((onep( nrturns) && termside == "Bottom") ||
           (nrturns == 2 && termside == "Top")
            newPt = caadr( ptList):cadadr( ptList)-coilWidth
            ctBLId~>dbId~>points = list( car( ptList) newPt)
            dbCreatePath( pcCellView bottomlayer 
              list( car( endPt):cadr( newPt)
                car( endPt):cadr( newPt)+maxWidthBL) coilWidth))
          ((termside == "Top" && oddp( nrturns)) ||
           (termside == "Bottom" && evenp( nrturns))
            newPt = caadr( ptList):cadadr( ptList)+coilWidth
            ctBLId~>dbId~>points = list( car( ptList) newPt)
            dbCreatePath( pcCellView bottomlayer 
              list( car( endPt):cadr( newPt)
                car( endPt):cadr( newPt)-maxWidthBL) coilWidth))
          (t
            newPt = caar( ptList):cadar( ptList)-coilWidth
            ctBLId~>dbId~>points = list( newPt cadr( ptList))
            dbCreatePath( pcCellView bottomlayer 
              list( car( endPt):cadr( newPt)
                car( endPt):cadr( newPt)+maxWidthBL) coilWidth))
        ) ;; cond
      else
        fdkDrawStaplesInBbox( pcCellView 
          if( member( termside list( "Top" "Bottom")) "VER" "HOR") 
          bBox bottomlayer stapleWidth coilWidth stapleSpace viaLayer 
          viaWidth viaLength viaSpace viaEncX viaEncY remainingSpace
          stapleGap)
      ) ;; if
    ) ;; when
    ctId~>dbId~>pinBbox = pinBbox
  )
)

procedure( fdkDrawIndCentertap_OneMetalBubble( pcCellView drTable paramTable)
  let(( bBox bTerm bottomlayer bridge coilSpace coilWidth coilWidthHalf 
    ct ctId ctLayer ctLength eTurns endPt jumpBLInfo layerList lTerm 
    lrTerm mainSep maxWidthBL minGrid minSpaceBL mult nrturns oTurns 
    pinBbox pitch ptList rTerm rbTerm startPt startPtX startPtY strap1 
    strapInfo tTerm tbTerm termExt termside toplayer via via1 viaBotEnc 
    viaInfo viaLayer viaLength viaTopEnc xExt xMult yExt yMult)

    ;; Retrieve parameter and design rule values
    nrturns = paramTable["nrturns"]
    toplayer = paramTable["toplayer"]
    layerList = drTable["layer"][toplayer]["jumpLayers"]
    bottomlayer = cadr( layerList)
    termside = paramTable["termside"]
    coilWidth = paramTable["coilwx"]
    coilSpace = paramTable["coilspcx"]
    termExt = paramTable["termext"]
    ctLayer = fdkPcLayer( car( drTable["layer"][toplayer]["ctLayers"]))
    ct = car( ctLayer)
    viaLayer = fdkPcLayer( drTable["layer"][ct]["viaLayer"])
    via = car( viaLayer)
    viaLength = drTable["via"][via]["length"]
    viaTopEnc = drTable["via"][via][toplayer]["enc"]
    viaBotEnc = drTable["via"][via][bottomlayer]["enc"]
    minGrid = drTable["minGrid"]
    minSpaceBL = drTable["layer"][bottomlayer]["minSpace"]
    maxWidthBL = drTable["layer"][bottomlayer]["maxWidth"]
    jumpBLInfo = drTable["jumpBLInfo"]

    ;; Computations
    pitch = coilWidth+coilSpace
    rbTerm = member( termside list( "Right" "Bottom"))
    tbTerm = member( termside list( "Top" "Bottom"))
    lrTerm = member( termside list( "Left" "Right"))
    tTerm = termside == "Top"
    bTerm = termside == "Bottom"
    lTerm = termside == "Left"
    rTerm = termside == "Right"
    eTurns = evenp( nrturns)
    oTurns = !eTurns
    coilWidthHalf = fdkSnapGrid( minGrid coilWidth*0.5)

    ;; Find bridge from which centertap will originate
    bridge = rodGetObj( "ind_bridge" pcCellView)

    ;; Create centertap dependent on number of turns 
    cond(
      ;; For single turn, centertap will be located opposite
      ;; to terminals.
      ( onep( nrturns)
        ctLength = termExt
        startPt = if( tbTerm bridge~>midLeft0 bridge~>midRight0)
        startPtX = car( startPt) startPtY = cadr( startPt)
        ptList = case( termside
          ( "Right" list( startPt startPtX-ctLength:startPtY))
          ( "Left" list( startPt startPtX+ctLength:startPtY))
          ( "Top" list( startPt startPtX:startPtY-ctLength))
          ( "Bottom" list( startPt startPtX:startPtY+ctLength))
        ) ;; case
        ctId = rodCreatePath( ?cvId pcCellView ?name "ind_centertap" 
          ?layer toplayer ?width coilWidth ?pts ptList 
          ?prop list( "endPt" cadr( ptList)))
      )
      ;; For two turns, centertap will be located between terminals.
      ( nrturns == 2
        ctLength = pitch+termExt
        startPt = if( rbTerm bridge~>midRight0 bridge~>midLeft0)
        startPt = if( lrTerm bridge~>midRight0 bridge~>midLeft0)
        startPtX = car( startPt) startPtY = cadr( startPt)
        ptList = case( termside
          ( "Right" list( startPt startPtX+ctLength:startPtY))
          ( "Left" list( startPt startPtX-ctLength:startPtY))
          ( "Top" list( startPt startPtX:startPtY+ctLength))
          ( "Bottom" list( startPt startPtX:startPtY-ctLength))
        ) ;; case
        ctId = rodCreatePath( ?cvId pcCellView ?name "ind_centertap" 
          ?layer toplayer ?width coilWidth ?pts ptList
          ?prop list( "endPt" cadr( ptList)))
      )
      ;; For turns greater than two, centertap will be located between 
      ;; terminals for even number turns, and opposite terminals for
      ;; odd number turns.
      ( t
        cond( 
          ( tbTerm
            ;; Create bubble
            xExt = viaTopEnc+viaLength+viaBotEnc+minSpaceBL+coilWidthHalf-
              if( jumpBLInfo->subRectStrapDPL 0 
                fdkSnapGrid( minGrid (coilWidth-maxWidthBL)*0.5))
            yExt = if( oTurns nrturns nrturns-1)*pitch
            yMult = if( (bTerm && oTurns) || (tTerm && eTurns) 1 -1)
            ptList = list( bridge~>mid0
              car( bridge~>end0)+xExt:cadr( bridge~>mid0) 
              car( bridge~>end0)+xExt:cadr( bridge~>mid0)+yExt*yMult
              car( bridge~>start0)-xExt:cadr( bridge~>mid0)+yExt*yMult
              car( bridge~>start0)-xExt:cadr( bridge~>mid0) 
              bridge~>mid0)
            rodCreatePath( ?cvId pcCellView ?layer bottomlayer
              ?width jumpBLInfo->mainWidth ?offset jumpBLInfo->mainOffset 
              ?offsetSubPath jumpBLInfo->offsetPathList
              ?pts ptList)
            ;; Create CT via when single via jump
            when( viaInfo = jumpBLInfo->subRectViaDPL
              via1 = rodCreateRect( ?cvId pcCellView ?layer viaInfo->layer 
                ?width viaInfo->length ?length viaInfo->width)
              rodAlign( ?alignObj via1 ?alignHandle "centerCenter" 
                ?refObj bridge ?refHandle "centerCenter")
              dbCopyShape( via1~>dbId pcCellView list( 0:yExt*yMult "R0"))
            ) ;; when
            ;; Create bottomlayer strap when metal slotted
            when( strapInfo = jumpBLInfo->subRectStrapDPL
              strap1 = rodCreateRect( ?cvId pcCellView ?layer strapInfo->layer
                ?width strapInfo->length ?length strapInfo->width)
              rodAlign( ?alignObj strap1 ?alignHandle "centerCenter" 
                ?refObj bridge ?refHandle "centerCenter")
              dbCopyShape( strap1~>dbId pcCellView list( 0:yExt*yMult "R0"))
            ) ;; when
            ;; Create CT vias when multiple via jump
            when( viaInfo = jumpBLInfo->offsetPathViaDPL 
              mainSep = jumpBLInfo->mainOffset
              foreach( sep cdr( viaInfo->viaSepList)
                via1 = rodCreateRect( ?cvId pcCellView ?layer viaInfo->layer 
                  ?width viaInfo->length ?length viaInfo->width)
                rodAlign( ?alignObj via1 ?alignHandle "centerCenter" 
                  ?refObj bridge ?refHandle "centerCenter" ?ySep mainSep+sep)
                dbCopyShape( via1~>dbId pcCellView list( 0:yExt*yMult "R0"))
              ) ;; foreach
            ) ;; when
            ;; Create toplayer tap on outer edge of bubble
            ctId = rodCreateRect( ?cvId pcCellView ?layer toplayer
              ?length bridge~>length ?width 2*viaTopEnc+viaLength
              ?prop list( "handle" if( onep( yMult) "mid1" "mid3")))
            rodAlign( ?alignObj ctId ?alignHandle "centerCenter" 
              ?refObj bridge ?refHandle "mid0" ?ySep yExt*yMult)
            ;; Add toplayer to match terminal extension (if needed)
            if( (oTurns && coilWidth+coilSpace < termExt) || eTurns then
              ctLength = termExt+if( oTurns -coilSpace coilWidth)
              strap1 = rodCreateRect( ?cvId pcCellView ?layer toplayer
                ?width coilWidth ?length ctLength ?name "ind_centertap" 
                ?prop list( "handle" if( onep( yMult) "mid1" "mid3")))
              rodAlign( ?alignObj strap1 
                ?alignHandle if( onep( yMult) "mid3" "mid1")
                ?refObj ctId ?refHandle if( onep( yMult) "mid3" "mid1"))
              ctId = strap1
            else
              rodNameShape( ?shapeId ctId~>dbId ?name "ind_centertap"
                ?permitRename t)
            ) ;; if
          ) ;; tbTerm
          ( lrTerm
            ;; Create bubble
            xExt = if( oTurns nrturns nrturns-1)*pitch
            yExt = viaTopEnc+viaLength+viaBotEnc+minSpaceBL+coilWidthHalf-
              if( jumpBLInfo->subRectStrapDPL 0 
                fdkSnapGrid( minGrid (coilWidth-maxWidthBL)*0.5))
            xMult = if( (lTerm && oTurns) || (rTerm && eTurns) 1 -1)
            ptList = list( bridge~>mid0
              car( bridge~>mid0):cadr( bridge~>start0)-yExt
              car( bridge~>mid0)+xExt*xMult:cadr( bridge~>start0)-yExt
              car( bridge~>mid0)+xExt*xMult:cadr( bridge~>end0)+yExt
              car( bridge~>mid0):cadr( bridge~>end0)+yExt
              bridge~>mid0)
            rodCreatePath( ?cvId pcCellView ?layer bottomlayer
              ?width jumpBLInfo->mainWidth ?offset jumpBLInfo->mainOffset 
              ?offsetSubPath jumpBLInfo->offsetPathList
              ?pts ptList)
            ;; Create CT via when single via jump
            when( viaInfo = jumpBLInfo->subRectViaDPL
              via1 = rodCreateRect( ?cvId pcCellView ?layer viaInfo->layer 
                ?width viaInfo->width ?length viaInfo->length)
              rodAlign( ?alignObj via1 ?alignHandle "centerCenter" 
                ?refObj bridge ?refHandle "centerCenter")
              dbCopyShape( via1~>dbId pcCellView list( xExt*xMult:0 "R0"))
            ) ;; when
            ;; Create bottomlayer strap when metal slotted
            when( strapInfo = jumpBLInfo->subRectStrapDPL
              strap1 = rodCreateRect( ?cvId pcCellView ?layer strapInfo->layer
                ?width strapInfo->width ?length strapInfo->length)
              rodAlign( ?alignObj strap1 ?alignHandle "centerCenter" 
                ?refObj bridge ?refHandle "centerCenter")
              dbCopyShape( strap1~>dbId pcCellView list( xExt*xMult:0 "R0"))
            ) ;; when
            ;; Create CT vias when multiple via jump
            when( viaInfo = jumpBLInfo->offsetPathViaDPL 
              mainSep = -coilWidthHalf+car( viaInfo->viaSepList)
              foreach( sep cdr( viaInfo->viaSepList)
                via1 = rodCreateRect( ?cvId pcCellView ?layer viaInfo->layer 
                  ?width viaInfo->width ?length viaInfo->length)
                rodAlign( ?alignObj via1 ?alignHandle "centerCenter" 
                  ?refObj bridge ?refHandle "centerCenter" ?xSep mainSep+sep)
                dbCopyShape( via1~>dbId pcCellView list( xExt*xMult:0 "R0"))
              ) ;; foreach
            ) ;; when
            ;; Create toplayer tap on outer edge of bubble
            ctId = rodCreateRect( ?cvId pcCellView ?layer toplayer
              ?width bridge~>width ?length 2*viaTopEnc+viaLength
              ?prop list( "handle" if( onep( xMult) "mid2" "mid0")))
            rodAlign( ?alignObj ctId ?alignHandle "centerCenter" 
              ?refObj bridge ?refHandle "mid0" ?xSep xExt*xMult)
            ;; Add toplayer to match terminal extension (if needed)
            if( (oTurns && coilWidth+coilSpace < termExt) || eTurns then
              ctLength = termExt+if( oTurns -coilSpace coilWidth)
              strap1 = rodCreateRect( ?cvId pcCellView ?layer toplayer
                ?length coilWidth ?width ctLength ?name "ind_centertap"
                ?prop list( "handle" if( onep( xMult) "mid2" "mid0")))
              rodAlign( ?alignObj strap1 
                ?alignHandle if( onep( xMult) "mid0" "mid2")
                ?refObj ctId ?refHandle if( onep( xMult) "mid0" "mid2"))
              ctId = strap1
            else
              rodNameShape( ?shapeId ctId~>dbId ?name "ind_centertap"
                ?permitRename t)
            ) ;; if
          ) ;; lrTerm
        ) ;; cond
      )
    ) ;; cond

    ;; Save location of terminal pin for later use
    endPt = ctId~>dbId~>endPt || rodGetHandle( ctId ctId~>dbId~>handle)
    bBox = ctId~>dbId~>bBox
    mult = if( eTurns 1 -1)
    case( termside
      ( "Right" 
        pinBbox = list( car( endPt):cadar( bBox) 
          car( endPt)-coilWidth*mult:cadadr( bBox)))
      ( "Left" 
        pinBbox = list( car( endPt)+coilWidth*mult:cadar( bBox)
          car( endPt):cadadr( bBox)))
      ( "Top" 
        pinBbox = list( caar( bBox):cadr( endPt) 
          caadr( bBox):cadr( endPt)-coilWidth*mult))
      ( "Bottom" 
        pinBbox = list( caar( bBox):cadr( endPt)+coilWidth*mult 
          caadr( bBox):cadr( endPt))))
    ctId~>dbId~>pinBbox = pinBbox
  )
)

procedure( fdkDrawSpiralIndTerm_OneMetalStraightIndVias( pcCellView 
  drTable paramTable)
  let(( bottomlayer coilSpace coilWidth coilWidthHalf extent filler 
    jumpBLInfo layerList lrTerm mainSep minTLViaWidth minGrid mult 
    nrturns nrturnsInt pitch pt1 pt2 ptList refHandle1 refHandle2
    refObj strap1 strapInfo tbTerm termBLPt1 termBLPt2 termPinBbox 
    termTLId termside toplayer turn1A vLength vWidth via 
    via1 via1Id viaBotEnc viaInfo viaLayer viaLength 
    viaTopEnc viaWidth xSepVia1 xSepVia2 ySepVia1 ySepVia2)

    ;; Retrieve parameter and design rule values
    nrturns = paramTable["nrturns"]
    toplayer = paramTable["toplayer"]
    layerList = drTable["layer"][toplayer]["jumpLayers"]
    bottomlayer = cadr( layerList)
    termside = paramTable["termside"]
    coilWidth = paramTable["coilwx"]
    coilSpace = paramTable["coilspcx"]
    extent = paramTable["termextJump"]
    viaLayer = fdkPcLayer( drTable["layer"][toplayer]["viaLayer"])
    via = car( viaLayer)
    viaWidth = drTable["via"][via]["width"]
    viaLength = drTable["via"][via]["length"]
    viaTopEnc = drTable["via"][via][toplayer]["enc"]
    viaBotEnc = drTable["via"][via][bottomlayer]["enc"]
    minGrid = drTable["minGrid"]

    ;; Computations
    pitch = coilWidth+coilSpace
    coilWidthHalf = fdkSnapGrid( minGrid coilWidth*0.5)
    nrturnsInt = pcFix( nrturns)

    ;; Calculate jump slotting
    jumpBLInfo = fdkCalcTM1JumpBL( drTable paramTable)
    turn1A = drTable["TT"][sprintf( nil "%s_turn1_sideA" toplayer)]
    ptList = turn1A~>dbId~>points 
    pt1 = car( last( ptList))
    pt2 = cadr( reverse( ptList))
    lrTerm = abs( cadr( pt1)-cadr( pt2)) < minGrid
    tbTerm = !lrTerm
    vWidth = if( tbTerm viaWidth viaLength)
    vLength = if( tbTerm viaLength viaWidth)
    xSepVia1 = ySepVia1 = xSepVia2 = ySepVia2 = 0
    refObj = turn1A
    minTLViaWidth = 2*viaTopEnc+viaWidth
    if( lrTerm then
      mult = if( car( pt2)-car( pt1) > minGrid 1 -1)
      refHandle1 = if( onep( mult) "mid0" "mid2")
      refHandle2 = if( onep( mult) "mid2" "mid0")
      xSepVia1 = viaTopEnc*mult
      xSepVia2 = -(vWidth+pitch*nrturnsInt+coilSpace+2*viaTopEnc)*mult
      termBLPt1 = car( pt1)-(pitch*nrturnsInt+coilSpace)*mult:
        cadr( pt1)
      termBLPt2 = car( termBLPt1)-(extent-coilSpace)*mult:cadr( pt1)
      termPinBbox = list( car( termBLPt2):cadr( termBLPt2)-coilWidthHalf
        car( termBLPt2)+coilWidth*mult:cadr( termBLPt2)+coilWidthHalf)
    else
      mult = if( cadr( pt2)-cadr( pt1) > minGrid 1 -1)
      refHandle1 = if( onep( mult) "mid3" "mid1")
      refHandle2 = if( onep( mult) "mid1" "mid3")
      ySepVia1 = viaTopEnc*mult
      ySepVia2 = -(vLength+pitch*nrturnsInt+coilSpace+2*viaTopEnc)*mult
      termBLPt1 = car( pt1):
        cadr( pt1)-(pitch*nrturnsInt+coilSpace)*mult
      termBLPt2 = car( pt1):cadr( termBLPt1)-(extent-coilSpace)*mult
      termPinBbox = list( car( termBLPt2)-coilWidthHalf:cadr( termBLPt2)
        car( termBLPt2)+coilWidthHalf:cadr( termBLPt2)+coilWidth*mult)
    ) ;; if

    if( lrTerm then ;; Horizontal jump terminal

      ;; Create via when single via jump
      when( viaInfo = jumpBLInfo->subRectViaDPL
        ;; When the toplayer is not wide enough to cover a single
        ;; via, add a piece of toplayer that is
        when( coilWidth < 2*viaTopEnc+viaWidth
          filler = rodCreatePath( ?cvId pcCellView ?layer toplayer
            ?width 2*viaTopEnc+viaWidth ?pts list( 0:0
              (2*viaTopEnc+viaLength)*-mult:0))
          rodAlign( ?alignObj filler ?alignHandle "endLeftLast"
            ?refObj refObj ?refHandle "endLeftLast" 
            ?maintain nil)
          refObj = filler
          pt1 = filler~>endLast
          termPinBbox = list( car( termBLPt2):cadr( pt1)-coilWidthHalf
            car( termBLPt2)+coilWidth*mult:cadr( pt1)+coilWidthHalf)
        ) ;; when
        via1Id = rodCreateRect( ?cvId pcCellView ?layer viaLayer
          ?width vWidth ?length vLength)
        rodAlign( ?alignObj via1Id ?alignHandle refHandle1
          ?refObj refObj ?refHandle "endLast" ?maintain nil
          ?xSep xSepVia1)
        dbCopyShape( via1Id~>dbId pcCellView list( xSepVia2:ySepVia2 "R0"))
      ) ;; when
      ;; Create bottomlayer jump
      rodCreatePath( ?cvId pcCellView ?layer bottomlayer
        ?width jumpBLInfo->mainWidth ?offset jumpBLInfo->mainOffset 
        ?offsetSubPath jumpBLInfo->offsetPathList
        ?pts list( car( pt1)+(viaBotEnc+viaLength+viaTopEnc)*mult:cadr( pt1) 
          car( pt1)-((coilSpace+coilWidth)*nrturnsInt+coilSpace+viaTopEnc+
          viaLength+viaBotEnc)*mult:cadr( pt1)))
      ;; Create bottomlayer strap when metal slotted
      when( strapInfo = jumpBLInfo->subRectStrapDPL
        strap1 = rodCreateRect( ?cvId pcCellView ?layer strapInfo->layer
          ?width strapInfo->length ?length strapInfo->width)
        rodAlign( ?alignObj strap1 ?alignHandle refHandle1
          ?refObj refObj ?refHandle "endLast")
      ) ;; when
      ;; Create vias when multiple via jump
      when( viaInfo = jumpBLInfo->offsetPathViaDPL 
        mainSep = jumpBLInfo->mainOffset
        foreach( sep cdr( viaInfo->viaSepList)
          via1 = rodCreateRect( ?cvId pcCellView ?layer viaLayer 
            ?width vWidth ?length vLength)
          rodAlign( ?alignObj via1 ?alignHandle refHandle1
            ?refObj refObj ?refHandle "endLast" 
            ?xSep xSepVia1 ?ySep mainSep+sep)
          dbCopyShape( via1~>dbId pcCellView list( xSepVia2:0 "R0"))
        ) ;; foreach
      ) ;; when
      ;; Create toplayer outer terminal
      termTLId = rodCreatePath( ?name "jumpTerm" ?cvId pcCellView 
        ?layer toplayer ?width max( coilWidth 2*viaTopEnc+viaWidth)
        ?pts list( car( pt1)-((coilSpace+coilWidth)*nrturnsInt+coilSpace)*mult:
          cadr( pt1) car( pt1)-((coilSpace+coilWidth)*nrturnsInt+extent)*mult:
          cadr( pt1)))
      when( filler
        termPinBbox = list( termTLId~>endRightLast 
          car( termTLId~>endLeftLast)+minTLViaWidth*mult:
          cadr( termTLId~>endLeftLast))
      ) ;; when
      ;; Create bottomlayer strap when metal slotted
      when( strapInfo = jumpBLInfo->subRectStrapDPL
        strap1 = rodCreateRect( ?cvId pcCellView ?layer strapInfo->layer
          ?width strapInfo->length ?length strapInfo->width)
        rodAlign( ?alignObj strap1 ?alignHandle refHandle2
          ?refObj termTLId ?refHandle "start0")
      ) ;; when

    else ;; Vertical jump terminal

      ;; Create via when single via jump
      when( viaInfo = jumpBLInfo->subRectViaDPL
        ;; When the toplayer is not wide enough to cover a single
        ;; via, add a piece of toplayer that is
        when( coilWidth < minTLViaWidth
          filler = rodCreatePath( ?cvId pcCellView ?layer toplayer
            ?width minTLViaWidth ?pts list( 0:0
            0:(2*viaTopEnc+viaLength)*-mult))
          rodAlign( ?alignObj filler ?alignHandle "endLeftLast"
            ?refObj refObj ?refHandle "endLeftLast" 
            ?maintain nil)
          refObj = filler
          pt1 = filler~>endLast
        ) ;; when
        via1Id = rodCreateRect( ?cvId pcCellView ?layer viaLayer
          ?width vWidth ?length vLength)
        rodAlign( ?alignObj via1Id ?alignHandle refHandle1
          ?refObj refObj ?refHandle "endLast" ?maintain nil
          ?ySep ySepVia1)
        dbCopyShape( via1Id~>dbId pcCellView list( xSepVia2:ySepVia2 "R0"))
      ) ;; when
      ;; Create bottomlayer jump
      rodCreatePath( ?cvId pcCellView ?layer bottomlayer
        ?width jumpBLInfo->mainWidth ?offset jumpBLInfo->mainOffset 
        ?offsetSubPath jumpBLInfo->offsetPathList
        ?pts list( car( pt1):cadr( pt1)+(viaBotEnc+viaLength+viaTopEnc)*mult
          car( pt1):cadr( pt1)-((coilSpace+coilWidth)*nrturnsInt+coilSpace+
          viaTopEnc+viaLength+viaBotEnc)*mult))
      ;; Create bottomlayer strap when metal slotted
      when( strapInfo = jumpBLInfo->subRectStrapDPL
        strap1 = rodCreateRect( ?cvId pcCellView ?layer strapInfo->layer
          ?width strapInfo->width ?length strapInfo->length)
        rodAlign( ?alignObj strap1 ?alignHandle refHandle1
          ?refObj turn1A ?refHandle "endLast")
      ) ;; when
      ;; Create vias when multiple via jump
      when( viaInfo = jumpBLInfo->offsetPathViaDPL 
        mainSep = jumpBLInfo->mainOffset
        foreach( sep cdr( viaInfo->viaSepList)
          via1 = rodCreateRect( ?cvId pcCellView ?layer viaLayer 
            ?width vWidth ?length vLength)
          rodAlign( ?alignObj via1 ?alignHandle refHandle1
            ?refObj refObj ?refHandle "endLast" 
            ?xSep mainSep+sep ?ySep ySepVia1)
          dbCopyShape( via1~>dbId pcCellView list( 0:ySepVia2 "R0"))
        ) ;; foreach
      ) ;; when
      ;; Create toplayer outer terminal
      termTLId = rodCreatePath( ?name "jumpTerm" ?cvId pcCellView 
        ?layer toplayer ?width max( coilWidth 2*viaTopEnc+viaWidth) 
        ?pts list( car( pt1):
          cadr( pt1)-((coilSpace+coilWidth)*nrturnsInt+coilSpace)*mult
          car( pt1):cadr( pt1)-((coilSpace+coilWidth)*nrturnsInt+extent)*mult))
      when( filler
        termPinBbox = list( termTLId~>endRightLast car( termTLId~>endLeftLast):
          cadr( termTLId~>endLeftLast)+minTLViaWidth*mult)
      ) ;; when
      ;; Create bottomlayer strap when metal slotted
      when( strapInfo = jumpBLInfo->subRectStrapDPL
        strap1 = rodCreateRect( ?cvId pcCellView ?layer strapInfo->layer
          ?width strapInfo->width ?length strapInfo->length)
        rodAlign( ?alignObj strap1 ?alignHandle refHandle2
          ?refObj termTLId ?refHandle "start0")
      ) ;; when
    ) ;; if

    ;; Define pin location
    termTLId~>dbId~>pinBbox = termPinBbox
    drTable["TT"][sprintf( nil "%s_turn1_sideB" toplayer)] = termTLId
    drTable["jumpTerm"] = termTLId
    pt1 = car( ptList)
    mult = if( termside == "Right" || termside == "Top" 1 -1)
    termPinBbox = if( termside == "Right" || termside == "Left"
      list( car( pt1):cadr( pt1)-coilWidthHalf 
        car( pt1)-coilWidth*mult:cadr( pt1)+coilWidthHalf)
      list( car( pt1)-coilWidthHalf:cadr( pt1)
        car( pt1)+coilWidthHalf:cadr( pt1)-coilWidth*mult))
    turn1A~>dbId~>pinBbox = termPinBbox

  )
)

procedure( fdkDrawSpiralIndTerm_TwoMetalsStraight( pcCellView 
  drTable paramTable)
  let(( bottomlayer coilSpace coilWidth coilWidthHalf ct
    ctLayer dontDrawHorStaples extent holeArea
    layerList lrTerm mainOffset maxWidthBL minGrid 
    minSpaceBL mult newPt nrturns nrturnsInt offsetPathList 
    pitch pt1 pt2 ptList ptListBL refHandle sigWidth 
    slotWidth stapleList stapleSpace stapleWidth tbTerm 
    termBLId termBLPt1 termBLPt2 termPinBbox termTLId 
    termside toplayer turn1A vLength vWidth via viaBotEnc 
    viaEncX viaEncY via1Id via2Id viaLayer viaLength 
    viaSpace viaTopEnc viaWidth xSepVia1
    xSepVia2 ySepVia1 ySepVia2)

    ;; Retrieve parameter and design rule values
    nrturns = paramTable["nrturns"]
    toplayer = paramTable["toplayer"]
    layerList = drTable["layer"][toplayer]["layers"]
    bottomlayer = cadr( layerList)
    termside = paramTable["termside"]
    coilWidth = paramTable["coilwx"]
    coilSpace = paramTable["coilspcx"]
    extent = paramTable["termextJump"]
    ctLayer = fdkPcLayer( car( drTable["layer"][toplayer]["ctLayers"]))
    ct = car( ctLayer)
    viaLayer = fdkPcLayer( drTable["layer"][ct]["viaLayer"])
    via = car( viaLayer)
    viaWidth = drTable["via"][via]["width"]
    viaLength = drTable["via"][via]["length"]
    viaSpace = drTable["via"][via]["space"]
    viaTopEnc = drTable["via"][via][ct]["enc"]
    viaBotEnc = drTable["via"][via][toplayer]["enc"]
    minGrid = drTable["minGrid"]
    offsetPathList = drTable[bottomlayer]->offsetPathList
    mainOffset = drTable[bottomlayer]->mainOffset
    sigWidth = drTable[bottomlayer]->sigWidth
    stapleWidth = drTable["stapleWidth"]
    stapleList = drTable["layer"][toplayer]["stapleList"]
    minSpaceBL = drTable["layer"][bottomlayer]["minSpace"]
    maxWidthBL = drTable["layer"][bottomlayer]["maxWidth"]
    dontDrawHorStaples = drTable["dontDrawHorStaples"]

    ;; Computations
    pitch = coilWidth+coilSpace
    tbTerm = member( termside list( "Top" "Bottom"))
    lrTerm = member( termside list( "Left" "Right"))
    coilWidthHalf = fdkSnapGrid( minGrid coilWidth*0.5)
    nrturnsInt = pcFix( nrturns)

    turn1A = drTable["TT"][sprintf( nil "%s_turn1_sideA" toplayer)]
    ptList = turn1A~>dbId~>points 
    pt1 = car( last( ptList))
    pt2 = cadr( reverse( ptList))
    lrTerm = abs( cadr( pt1)-cadr( pt2)) < minGrid
    tbTerm = !lrTerm

    vWidth = if( tbTerm viaWidth viaLength)
    vLength = if( tbTerm viaLength viaWidth)
    xSepVia1 = ySepVia1 = xSepVia2 = ySepVia2 = 0
    if( lrTerm then
      mult = if( car( pt2)-car( pt1) > minGrid 1 -1)
      refHandle = if( onep( mult) "mid0" "mid2")
      xSepVia1 = viaBotEnc*mult
      xSepVia2 = -(vWidth+pitch*nrturnsInt+coilSpace+2*viaBotEnc)*mult
      termBLPt1 = car( pt1)-(pitch*nrturnsInt+coilSpace)*mult:
        cadr( pt1)
      termBLPt2 = car( termBLPt1)-(extent-coilSpace)*mult:cadr( pt1)
      termPinBbox = list( car( termBLPt2):cadr( termBLPt2)-coilWidthHalf
        car( termBLPt2)+coilWidth*mult:cadr( termBLPt2)+coilWidthHalf)
    else
      mult = if( cadr( pt2)-cadr( pt1) > minGrid 1 -1)
      refHandle = if( onep( mult) "mid3" "mid1")
      ySepVia1 = viaBotEnc*mult
      ySepVia2 = -(vLength+pitch*nrturnsInt+coilSpace+2*viaBotEnc)*mult
      termBLPt1 = car( pt1):
        cadr( pt1)-(pitch*nrturnsInt+coilSpace)*mult
      termBLPt2 = car( pt1):cadr( termBLPt1)-(extent-coilSpace)*mult
      termPinBbox = list( car( termBLPt2)-coilWidthHalf:cadr( termBLPt2)
        car( termBLPt2)+coilWidthHalf:cadr( termBLPt2)+coilWidth*mult)
    ) ;; if

    ;; Create jump inner via 
    via1Id = rodCreateRect( ?cvId pcCellView ?layer viaLayer
      ?width vWidth ?length vLength)
    rodAlign( ?alignObj via1Id ?alignHandle refHandle
      ?refObj turn1A ?refHandle "endLast" ?maintain nil
      ?xSep xSepVia1 ?ySep ySepVia1)

    ;; Create jump outer via
    via2Id = dbCopyShape( via1Id~>dbId pcCellView list( xSepVia2:ySepVia2 "R0"))
    via2Id = rodNameShape( ?shapeId via2Id)

    ;; Create jump toplayer
    rodCreateRect( ?cvId pcCellView ?layer ctLayer 
      ?fromObj list( via1Id via2Id) ?size viaTopEnc)

    ;; Create jump terminal 
    termTLId = rodCreatePath( ?name "jumpTerm" ?cvId pcCellView 
      ?layer toplayer ?width coilWidth ?pts list( termBLPt1 termBLPt2))
    termBLId = rodCreatePath( ?cvId pcCellView ?layer bottomlayer 
      ?width sigWidth ?offset -mainOffset-minGrid 
      ?offsetSubPath offsetPathList ?pts list( termBLPt1 termBLPt2))

    ;; Add staple array to jump terminal
    viaLayer = fdkPcLayer( drTable["layer"][toplayer]["viaLayer"])
    via = car( viaLayer)
    viaWidth = drTable["via"][via]["width"]
    viaLength = drTable["via"][via]["length"]
    viaSpace = drTable["via"][via]["space"]
    viaEncX = drTable["stapleViaEncX"]
    viaEncY = drTable["via"][via][bottomlayer]["enc"]
    holeArea = drTable["layer"][bottomlayer]["holeArea"]
    slotWidth = drTable[bottomlayer]->sigSpace
    stapleSpace = max( minSpaceBL viaSpace-2*viaEncX)
    when( lrTerm
      stapleSpace = max( stapleSpace fdkSnapUpGrid( minGrid holeArea/slotWidth))
    ) ;; when

    when( member( "terminal" stapleList)

      if( dontDrawHorStaples && tbTerm then
        fdkDrawStaplesInBbox( pcCellView "HOR"
          termPinBbox bottomlayer stapleWidth coilWidth stapleSpace viaLayer 
          viaWidth viaLength viaSpace viaEncX viaEncY 0 "distribute")
  
        ;; Get bottomlayer to retract
        ptListBL = termBLId~>dbId~>points
        pt1 = cadr( ptListBL)
        pt2 = cadr( termTLId~>dbId~>points)
        newPt = car( pt1):cadr( pt1)+coilWidth*mult
        termBLId~>dbId~>points = list( car( ptListBL) newPt)

        dbCreatePath( pcCellView bottomlayer
          list( car( pt2):cadr( pt2)+coilWidth*mult 
            car( pt2):cadr( pt2)+(coilWidth-maxWidthBL)*mult) 
          coilWidth)
        dbCreatePath( pcCellView bottomlayer list( pt2
          car( pt2):cadr( pt2)+maxWidthBL*mult) coilWidth)
      else
        fdkDrawStaplesInBbox( pcCellView "HOR"
          termPinBbox bottomlayer stapleWidth coilWidth stapleSpace viaLayer 
          viaWidth viaLength viaSpace viaEncX viaEncY 0 "distribute")
      ) ;; if
    ) ;; when
    termTLId~>dbId~>pinBbox = termPinBbox
    drTable["TT"][sprintf( nil "%s_turn1_sideB" toplayer)] = termTLId
    drTable["jumpTerm"] = termTLId

  )
)

procedure( fdkDrawSpiralIndTerm_OneMetalStraight( pcCellView 
  drTable paramTable)
  let(( coilSpace coilWidth coilWidthHalf ct ctLayer extent 
    lrTerm minGrid mult nrturns nrturnsInt pitch 
    pt1 pt2 ptList refHandle tbTerm termBLPt1 termBLPt2 
    termPinBbox termTLId termside toplayer turn1A vLength 
    vWidth via viaBotEnc via1Id via2Id viaLayer viaLength 
    viaTopEnc viaWidth xSepVia1 xSepVia2 ySepVia1 ySepVia2)

    ;; Retrieve parameter and design rule values
    nrturns = paramTable["nrturns"]
    toplayer = paramTable["toplayer"]
    termside = paramTable["termside"]
    coilWidth = paramTable["coilwx"]
    coilSpace = paramTable["coilspcx"]
    extent = paramTable["termextJump"]
    ctLayer = fdkPcLayer( car( drTable["layer"][toplayer]["ctLayers"]))
    ct = car( ctLayer)
    viaLayer = fdkPcLayer( drTable["layer"][ct]["viaLayer"])
    via = car( viaLayer)
    viaWidth = drTable["via"][via]["width"]
    viaLength = drTable["via"][via]["length"]
    viaTopEnc = drTable["via"][via][ct]["enc"]
    viaBotEnc = drTable["via"][via][toplayer]["enc"]
    minGrid = drTable["minGrid"]

    ;; Computations
    pitch = coilWidth+coilSpace
    tbTerm = member( termside list( "Top" "Bottom"))
    lrTerm = member( termside list( "Left" "Right"))
    coilWidthHalf = fdkSnapGrid( minGrid coilWidth*0.5)
    nrturnsInt = pcFix( nrturns)

    turn1A = drTable["TT"][sprintf( nil "%s_turn1_sideA" toplayer)]
    ptList = turn1A~>dbId~>points 
    pt1 = car( last( ptList))
    pt2 = cadr( reverse( ptList))
    lrTerm = abs( cadr( pt1)-cadr( pt2)) < minGrid
    tbTerm = !lrTerm

    vWidth = if( tbTerm viaWidth viaLength)
    vLength = if( tbTerm viaLength viaWidth)
    xSepVia1 = ySepVia1 = xSepVia2 = ySepVia2 = 0
    if( lrTerm then
      mult = if( car( pt2)-car( pt1) > minGrid 1 -1)
      refHandle = if( onep( mult) "mid0" "mid2")
      xSepVia1 = viaBotEnc*mult
      xSepVia2 = -(vWidth+pitch*nrturnsInt+coilSpace+2*viaBotEnc)*mult
      termBLPt1 = car( pt1)-(pitch*nrturnsInt+coilSpace)*mult:
        cadr( pt1)
      termBLPt2 = car( termBLPt1)-(extent-coilSpace)*mult:cadr( pt1)
      termPinBbox = list( car( termBLPt2):cadr( termBLPt2)-coilWidthHalf
        car( termBLPt2)+coilWidth*mult:cadr( termBLPt2)+coilWidthHalf)
      drTable["idShape5bBox"] = list( car( pt1):cadr( pt1)-coilWidthHalf
        car( pt1)+minGrid*mult:cadr( pt1)+coilWidthHalf)
    else
      mult = if( cadr( pt2)-cadr( pt1) > minGrid 1 -1)
      refHandle = if( onep( mult) "mid3" "mid1")
      ySepVia1 = viaBotEnc*mult
      ySepVia2 = -(vLength+pitch*nrturnsInt+coilSpace+2*viaBotEnc)*mult
      termBLPt1 = car( pt1):
        cadr( pt1)-(pitch*nrturnsInt+coilSpace)*mult
      termBLPt2 = car( pt1):cadr( termBLPt1)-(extent-coilSpace)*mult
      termPinBbox = list( car( termBLPt2)-coilWidthHalf:cadr( termBLPt2)
        car( termBLPt2)+coilWidthHalf:cadr( termBLPt2)+coilWidth*mult)
      drTable["idShape5bBox"] = list( car( pt1)-coilWidthHalf:cadr( pt1)
        car( pt1)+coilWidthHalf:cadr( pt1)+minGrid*mult)
    ) ;; if

    ;; Create jump inner via 
    via1Id = rodCreateRect( ?cvId pcCellView ?layer viaLayer
      ?width vWidth ?length vLength)
    rodAlign( ?alignObj via1Id ?alignHandle refHandle
      ?refObj turn1A ?refHandle "endLast" ?maintain nil
      ?xSep xSepVia1 ?ySep ySepVia1)

    ;; Create jump outer via
    via2Id = dbCopyShape( via1Id~>dbId pcCellView list( xSepVia2:ySepVia2 "R0"))
    via2Id = rodNameShape( ?shapeId via2Id)

    ;; Create jump toplayer
    rodCreateRect( ?cvId pcCellView ?layer ctLayer 
      ?fromObj list( via1Id via2Id) ?size viaTopEnc)

    ;; Create jump terminal 
    termTLId = rodCreatePath( ?name "jumpTerm" ?cvId pcCellView 
      ?layer toplayer ?width coilWidth ?pts list( termBLPt1 termBLPt2))

    termTLId~>dbId~>pinBbox = termPinBbox
    drTable["TT"][sprintf( nil "%s_turn1_sideB" toplayer)] = termTLId
    drTable["jumpTerm"] = termTLId

    ;; When creating single layer spiral inductor, calculate the other
    ;; pin bbox as well
    pt1 = car( ptList)
    termPinBbox = if( member( termside list( "Top" "Bottom")) then
      mult = if( cadr( pt2)-cadr( pt1) > minGrid 1 -1)
      list( car( pt1)-coilWidthHalf:cadr( pt1)
        car( pt1)+coilWidthHalf:cadr( pt1)+coilWidth*mult)
    else
      mult = if( car( pt2)-car( pt1) > minGrid 1 -1)
      termPinBbox = list( car( pt1):cadr( pt1)-coilWidthHalf
        car( pt1)+coilWidth*mult:cadr( pt1)+coilWidthHalf)
    ) ;; if
    turn1A~>dbId~>pinBbox = termPinBbox

  )
)
procedure( fdkDrawIndTermPins( pcCellView drTable paramTable)
  let(( centertap ctId ctPinName coilWidth indShape lL 
    minusPinName nrturns pin pinBbox1 pinBbox2 plusMinusPinLayer 
    plusPinName termside toplayer turnA turnB turnCtr uR)

    ;; Retrieve parameter and design rule values
    coilWidth = paramTable["coilwx"]
    nrturns = paramTable["nrturns"]
    toplayer = paramTable["toplayer"]
    centertap = paramTable["centertap"]
    termside = paramTable["termside"]
    plusPinName = drTable["plusPinName"]
    minusPinName = drTable["minusPinName"]
    ctPinName = drTable["ctPinName"]
    indShape = paramTable["indShape"]
    plusMinusPinLayer = fdkPcLayer( drTable["layer"][toplayer]["pinLayer"])

    ;; Retrieve terminal pin bounding boxes
    turnCtr = case( indShape ("symmetrical" nrturns) ("spiral" 1) (t 0))
    turnA = drTable["TT"][sprintf( nil "%s_turn%d_sideA" toplayer turnCtr)]
    turnB = drTable["TT"][sprintf( nil "%s_turn%d_sideB" toplayer turnCtr)]
    when( turnA && turnB && !((pinBbox1 = turnA~>dbId~>pinBbox) &&
      (pinBbox2 = turnB~>dbId~>pinBbox))
      case( termside 
        ("Top" 
          when( uR = turnA~>endRightLast
            pinBbox1 = list( car( uR)-coilWidth:cadr( uR)-coilWidth uR))
          when( uR = turnB~>startLeft0
            pinBbox2 = list( car( uR)-coilWidth:cadr( uR)-coilWidth uR)))
        ("Bottom"
          when( lL = turnA~>startLeft0
            pinBbox1 = list( lL car( lL)+coilWidth:cadr( lL)+coilWidth))
          when( lL = turnB~>endRightLast
            pinBbox2 = list( lL car( lL)+coilWidth:cadr( lL)+coilWidth)))
        ( "Left"
          when( lL = turnA~>startRight0
            pinBbox1 = list( lL car( lL)+coilWidth:cadr( lL)+coilWidth))
          when( lL = turnB~>endLeftLast
            pinBbox2 = list( lL car( lL)+coilWidth:cadr( lL)+coilWidth)))
        ( "Right"
          when( uR = turnA~>endLeftLast
            pinBbox1 = list( car( uR)-coilWidth:cadr( uR)-coilWidth uR))
          when( uR = turnB~>startRight0
            pinBbox2 = list( car( uR)-coilWidth:cadr( uR)-coilWidth uR)))
      ) ;; case
    ) ;; when

    ;; PLUS Pin
    when( pinBbox1
      pin = rodCreateRect( 
        ?name "plusPin"
        ?cvId pcCellView
        ?layer plusMinusPinLayer
        ?bBox pinBbox1
        ?pin t
        ?netName plusPinName)
      drTable["plusPin"] = pin
    ) ;; when

    ;; MINUS Pin
    when( pinBbox2
      pin = rodCreateRect( 
        ?name "minusPin"
        ?cvId pcCellView
        ?layer plusMinusPinLayer
        ?bBox pinBbox2
        ?pin t
        ?netName minusPinName)
      drTable["minusPin"] = pin
    ) ;; when

    ;; CT Pin
    when( centertap == "Yes"
      ctId = rodGetObj( "ind_centertap" pcCellView)
      when( pinBbox1 = ctId~>dbId~>pinBbox
        pin = rodCreateRect( 
          ?cvId pcCellView
          ?layer plusMinusPinLayer
          ?bBox pinBbox1
          ?pin t
          ?netName ctPinName)
        drTable["ctPin"] = pin
      ) ;; when
    ) ;; when
  )
)

procedure( fdkResetIndTermExtForFill( pcCellView paramTable drTable)
  let(( baseFillerId centertap coilSpace coilWidth coilWidthSpace 
    fillBaseCell fillCellLibrary fillExt fillTopCells 
    innerWxHalf innerWyHalf minGrid newBbox nrturns offsetList 
    origBbox termExt termExtInc termSide topMetFillerId)

    ;; When adding fill, calculate the bounding box of the fill
    ;; and update the terminal extension to create coincidental
    ;; terminal ends to the edge of fill
    nrturns = paramTable["nrturns"]
    coilWidth = paramTable["coilwx"]
    coilSpace = paramTable["coilspcx"]
    termSide = paramTable["termside"]
    termExt = paramTable["termext"]
    centertap = paramTable["centertap"]
    innerWxHalf = paramTable["innerwx"]*0.5
    innerWyHalf = paramTable["innerwy"]*0.5
    fillCellLibrary = drTable["fillCellLibrary"]
    fillTopCells = drTable["fillTopCells"]
    fillBaseCell = drTable["fillBaseCell"]
    fillExt = drTable["fillExtension"]
    minGrid = drTable["minGrid"]

    topMetFillerId = dbOpenCellViewByType( fillCellLibrary 
      car( fillTopCells) "layout")
    baseFillerId = dbOpenCellViewByType( fillCellLibrary 
      fillBaseCell "layout")
    coilWidthSpace = coilWidth*nrturns+coilSpace*(nrturns-1)
    origBbox = list( -innerWxHalf-coilWidthSpace:-innerWyHalf-coilWidthSpace
      innerWxHalf+coilWidthSpace:innerWyHalf+coilWidthSpace)

    ;; Grow box to accommodate terminals
    origBbox = case( termSide
      ("Left" 
         list( caar( origBbox)-termExt:cadar( origBbox)-fillExt 
           caadr( origBbox)+fillExt:cadadr( origBbox)+fillExt))
      ("Right" 
         list( caar( origBbox)-fillExt:cadar( origBbox)-fillExt 
           caadr( origBbox)+termExt:cadadr( origBbox)+fillExt))
      ("Top" 
         list( caar( origBbox)-fillExt:cadar( origBbox)-fillExt
           caadr( origBbox)+fillExt:cadadr( origBbox)+termExt))
      ("Bottom" 
         list( caar( origBbox)-fillExt:cadar( origBbox)-termExt 
           caadr( origBbox)+fillExt:cadadr( origBbox)+fillExt)))

    ;; Grow box to accommodate centertap if extending on the 
    ;; opposite direction as the terminals (odd number of turns)
    when( centertap == "Yes" && oddp( nrturns)
      termExtInc = max( termExt coilWidth+coilSpace)-fillExt
      origBbox = case( termSide
        ( "Left"
          list( car( origBbox) caadr( origBbox)+termExtInc:cadadr( origBbox)))
        ( "Right" 
          list( caar( origBbox)-termExtInc:cadar( origBbox) cadr( origBbox)))
        ( "Top" 
          list( caar( origBbox):cadar( origBbox)-termExtInc cadr( origBbox)))
        ( "Bottom" 
          list( car( origBbox) caadr( origBbox):cadadr( origBbox)+termExtInc)))
    ) ;; when

    newBbox = car( fdkFindCellFillBound( topMetFillerId pcCellView origBbox))

    ;; NOTE: The current base filler cell has a prBoundary that is not 
    ;; coincidental with the cell bounding box.  This will cause the
    ;; calculated fill bounding box to be off.  The following function
    ;; checks if there is a difference, and grows the newBbox if needed.
    when( offsetList = fdkGetPRBboxDiff( baseFillerId minGrid)
      newBbox = list( 
        caar( newBbox)+car( offsetList):cadar( newBbox)+cadr( offsetList)
        caadr( newBbox)+caddr( offsetList):cadadr( newBbox)+cadddr( offsetList))
    ) ;; when

    termExtInc = case( termSide
      ( ("Left" "Right") abs( caar( newBbox)-caar( origBbox)))
      ( ("Top" "Bottom") abs( cadar( newBbox)-cadar( origBbox))))
    paramTable["termext"] = termExt+termExtInc

    dbClose( topMetFillerId)
    dbClose( baseFillerId)

    origBbox ;; Return value
  )
)

procedure( fdkResetSpiralIndTermExtForFill( pcCellView paramTable drTable)
  let(( baseFillerId botInc coilSpace coilWidth coilWidthSpace 
    fTurn fillBaseCell fillCellLibrary fillExt fillTopCells 
    hTurn innerWxHalf innerWyHalf leftInc minGrid newBbox 
    nrturns nrturnsInt offsetList origBbox pitch qTurn 
    rightInc termExt termExtInc termSide topInc topMetFillerId 
    tqTurn)

    ;; When adding fill, calculate the bounding box of the fill
    ;; and update the terminal extension to create coincidental
    ;; terminal ends to the edge of fill
    nrturns = paramTable["nrturns"]
    coilWidth = paramTable["coilwx"]
    coilSpace = paramTable["coilspcx"]
    termSide = paramTable["termside"]
    termExt = paramTable["termext"]
    innerWxHalf = paramTable["innerwx"]*0.5
    innerWyHalf = paramTable["innerwy"]*0.5
    fillCellLibrary = drTable["fillCellLibrary"]
    fillTopCells = drTable["fillTopCells"]
    fillBaseCell = drTable["fillBaseCell"]
    fillExt = drTable["fillExtension"]
    minGrid = drTable["minGrid"]
    nrturnsInt = pcFix( nrturns)
    fTurn = abs( nrturns-nrturnsInt) < minGrid ;; Full turn
    qTurn = abs( nrturns-nrturnsInt-0.25) < minGrid ;; Quarter turn
    hTurn = abs( nrturns-nrturnsInt-0.5) < minGrid ;; Half turn
    tqTurn = abs( nrturns-nrturnsInt-0.75) < minGrid ;; Three quarter turn

    topMetFillerId = dbOpenCellViewByType( fillCellLibrary 
      car( fillTopCells) "layout")
    baseFillerId = dbOpenCellViewByType( fillCellLibrary 
      fillBaseCell "layout")
    pitch = coilWidth+coilSpace
    coilWidthSpace = coilWidth*nrturnsInt+coilSpace*(nrturnsInt-1)
    origBbox = list( -innerWxHalf-coilWidthSpace:-innerWyHalf-coilWidthSpace
      innerWxHalf+coilWidthSpace:innerWyHalf+coilWidthSpace)

    ;; Grow box to accommodate terminals. Make calculations assuming 
    ;; main terminal on the bottom.
    origBbox = cond( 
      ( fTurn ;; Full turn
        list( caar( origBbox)-termExt:cadar( origBbox)-termExt
          caadr( origBbox)+fillExt:cadadr( origBbox)+fillExt))
      ( qTurn ;; Quarter turn
        list( caar( origBbox)-pitch-fillExt:cadar( origBbox)-termExt
          caadr( origBbox)+fillExt:cadadr( origBbox)+termExt))
      ( hTurn ;; Half turn
        list( caar( origBbox)-pitch-fillExt:cadar( origBbox)-termExt
          caadr( origBbox)+termExt:cadadr( origBbox)+pitch+fillExt))
      ( tqTurn ;; Three quarter turn
        list( caar( origBbox)-pitch-fillExt:cadar( origBbox)-termExt
          caadr( origBbox)+pitch+fillExt:cadadr( origBbox)+pitch+fillExt)))

    ;; Transform the bounding box if terminal not bottom
    unless( termSide == "Bottom"
      origBbox = dbTransformBBox( origBbox list( 0:0
          case( termSide ("Right" "R90") ("Top" "R180") ("Left" "R270"))))
    ) ;; unless

    newBbox = car( fdkFindCellFillBound( topMetFillerId pcCellView origBbox))

    ;; NOTE: The current base filler cell has a prBoundary that is not 
    ;; coincidental with the cell bounding box.  This will cause the
    ;; calculated fill bounding box to be off.  The following function
    ;; checks if there is a difference, and grows the newBbox if needed.
    when( offsetList = fdkGetPRBboxDiff( baseFillerId minGrid)
      newBbox = list( 
        caar( newBbox)+car( offsetList):cadar( newBbox)+cadr( offsetList)
        caadr( newBbox)+caddr( offsetList):cadadr( newBbox)+cadddr( offsetList))
    ) ;; when

    ;; Since the terminals may not be located on the same side,
    ;; we will recalculate termext and use it for the main terminal,
    ;; and create a new termextJump variable to independently control
    ;; the terminal extension of the jump terminal.

    ;; Main Terminal
    leftInc = abs( caar( newBbox)-caar( origBbox))
    rightInc = abs( caadr( newBbox)-caadr( origBbox))
    botInc = abs( cadar( newBbox)-cadar( origBbox))
    topInc = abs( cadadr( newBbox)-cadadr( origBbox))
    termExtInc = case( termSide
      ( "Left" leftInc) ("Right" rightInc) ("Top" topInc) ("Bottom" botInc))
    paramTable["termext"] = termExt+termExtInc

    ;; Jump Terminal
    termExtInc = cond(
      ( fTurn case( termSide
        ( "Left" topInc) ("Right" botInc) ("Top" rightInc) ("Bottom" leftInc)))
      ( qTurn case( termSide
        ( "Left" rightInc) ("Right" leftInc) ("Top" botInc) ("Bottom" topInc)))
      ( hTurn case( termSide
        ( "Left" botInc) ("Right" topInc) ("Top" leftInc) ("Bottom" rightInc)))
      ( tqTurn case( termSide
        ( "Left" leftInc) ("Right" rightInc) ("Top" topInc) ("Bottom" botInc))))
    paramTable["termextJump"] = termExt+termExtInc

    origBbox ;; Return value
  )
)

procedure( fdkDrawIDShapes( pcCellView drTable paramTable)
  let(( bridge cPt ctExt centertap coilSpace coilWidth coilWidthHalf 
    idShapeIndLayer idShapeLayer idShapeM12Layer idShapeTextSize
    idShapeTm1Layer idShapeWidth idShapeWidthHalf indBbox innerwx
    innerwxHalf innerwy innerwyHalf minGrid minusBbox nrturns 
    nrturnsHalf shapeBbox termSide toplayer)

    coilWidth = paramTable["coilwx"]
    coilSpace = paramTable["coilspcx"]
    nrturns = paramTable["nrturns"]
    termSide = paramTable["termside"]
    toplayer = paramTable["toplayer"]
    centertap = paramTable["centertap"]
    idShapeTm1Layer = fdkPcLayer( drTable["layer"]["tm1"]["idLayer"])
    idShapeM12Layer = fdkPcLayer( drTable["layer"]["m12"]["idLayer"])
    idShapeIndLayer = fdkPcLayer( drTable["layer"]["inductorIDLayer"])
    idShapeTextSize = drTable["layer"]["inductorIDTextSize"]
    innerwx = paramTable["innerwx"]
    innerwy = paramTable["innerwy"]
    minGrid = drTable["minGrid"]

    ;; Do base calculations
    idShapeWidth = 0.01
    idShapeWidthHalf = fdkSnapGrid( minGrid idShapeWidth*0.5)
    coilWidthHalf = fdkSnapGrid( minGrid coilWidth*0.5)
    nrturnsHalf = fdkSnapGrid( minGrid nrturns*0.5)
    innerwxHalf = fdkSnapGrid( minGrid innerwx*0.5)
    innerwyHalf = fdkSnapGrid( minGrid innerwy*0.5)

    ;; Create IND shape around inductor, not to include terminal 
    ;; and centertap pins
    indBbox = pcCellView~>bBox
    ctExt = if( centertap == "Yes" && oddp( nrturns) coilWidth 0)
    shapeBbox = case( termSide
      ( "Left" 
        list( caar( indBbox)+coilWidth:cadar( indBbox) 
          caadr( indBbox)-ctExt:cadadr( indBbox)))
      ( "Right"
        list( caar( indBbox)+ctExt:cadar( indBbox)
           caadr( indBbox)-coilWidth:cadadr( indBbox)))
      ( "Top" 
        list( caar( indBbox):cadar( indBbox)+ctExt 
          caadr( indBbox):cadadr( indBbox)-coilWidth))
      ( "Bottom" 
        list( caar( indBbox):cadar( indBbox)+coilWidth 
          caadr( indBbox):cadadr( indBbox)-ctExt)))

    idShapeLayer = if( toplayer == "tm1" idShapeTm1Layer idShapeM12Layer)
    dbCreateRect( pcCellView idShapeLayer shapeBbox)

    ;; Create IND text
    dbCreateLabel( pcCellView idShapeLayer 
      caar( shapeBbox):cadadr( shapeBbox) 
      sprintf( nil "Inductor2Scl_%s" upperCase( toplayer)) 
      "leftTop" "R0" "stick" idShapeTextSize)

    ;; Create inductorID shape #1 (on terminal)
    when( minusBbox = rodGetObj( "minusPin" pcCellView)~>dbId~>bBox
      shapeBbox = case( termSide
        ( "Left" 
          list( caadr( minusBbox):cadar( minusBbox)
            caadr( minusBbox)+coilSpace:cadadr( minusBbox)))
        ( "Right"
          list( caar( minusBbox)-coilSpace:cadar( minusBbox) 
            caar( minusBbox):cadadr( minusBbox)))
        ( "Top" 
          list( caar( minusBbox):cadar( minusBbox)-coilSpace 
            caadr( minusBbox):cadar( minusBbox)))
        ( "Bottom" 
          list( caar( minusBbox):cadadr( minusBbox)
            caadr( minusBbox):cadadr( minusBbox)+coilSpace)))
  
      dbCreateRect( pcCellView idShapeIndLayer shapeBbox)
    ) ;; when

    ;; Create inductorID shape #2 (inside inner ring)
    bridge = rodGetObj( "ind_bridge" pcCellView)
    cPt = bridge~>mid0
    shapeBbox = cond(
      ( (termSide == "Bottom" && oddp( nrturns)) ||
        (termSide == "Top" && evenp( nrturns))
        list( car( cPt)-innerwxHalf:cadr( cPt)-coilWidthHalf-minGrid
          car( cPt)+innerwxHalf:cadr( cPt)-coilWidthHalf-minGrid-idShapeWidth))
      ( (termSide == "Bottom" && evenp( nrturns)) ||
        (termSide == "Top" && oddp( nrturns))
        list( car( cPt)-innerwxHalf:cadr( cPt)+coilWidthHalf+minGrid
          car( cPt)+innerwxHalf:cadr( cPt)+coilWidthHalf+minGrid+idShapeWidth))
      ( (termSide == "Left" && evenp( nrturns)) ||
        (termSide == "Right" && oddp( nrturns))
        list( car( cPt)+coilWidthHalf+minGrid:cadr( cPt)-innerwyHalf
          car( cPt)+coilWidthHalf+minGrid+idShapeWidth:cadr( cPt)+innerwyHalf))
      ( (termSide == "Left" && oddp( nrturns)) ||
        (termSide == "Right" && evenp( nrturns))
        list( car( cPt)-coilWidthHalf-minGrid:cadr( cPt)-innerwyHalf
          car( cPt)-coilWidthHalf-minGrid-idShapeWidth:cadr( cPt)+innerwyHalf)))

    dbCreateRect( pcCellView idShapeIndLayer shapeBbox)

    ;; Create inductorID shape #3 (outside inner ring)
    shapeBbox = cond(
      ( (termSide == "Bottom" && oddp( nrturns)) ||
        (termSide == "Top" && evenp( nrturns))
        list( car( cPt)+innerwxHalf+coilWidth-idShapeWidthHalf:
          cadr( cPt)-coilWidthHalf
          car( cPt)+innerwxHalf+coilWidth+idShapeWidthHalf:
          cadr( cPt)-coilWidthHalf-innerwy))
      ( (termSide == "Bottom" && evenp( nrturns)) ||
        (termSide == "Top" && oddp( nrturns))
        list( car( cPt)+innerwxHalf+coilWidth-idShapeWidthHalf:
          cadr( cPt)+coilWidthHalf
          car( cPt)+innerwxHalf+coilWidth+idShapeWidthHalf:
          cadr( cPt)+coilWidthHalf+innerwy))
      ( (termSide == "Left" && evenp( nrturns)) ||
        (termSide == "Right" && oddp( nrturns))
        list( car( cPt)+coilWidthHalf:
          cadr( cPt)+innerwxHalf+coilWidth-idShapeWidthHalf
          car( cPt)+coilWidthHalf+innerwy:
          cadr( cPt)+innerwxHalf+coilWidth+idShapeWidthHalf))
      ( (termSide == "Left" && oddp( nrturns)) ||
        (termSide == "Right" && evenp( nrturns))
        list( car( cPt)-coilWidthHalf:
          cadr( cPt)+innerwxHalf+coilWidth-idShapeWidthHalf
          car( cPt)-coilWidthHalf-innerwy:
          cadr( cPt)+innerwxHalf+coilWidth+idShapeWidthHalf)))

    dbCreateRect( pcCellView idShapeIndLayer shapeBbox)

    ;; Create inductorID shape #4 (step ladder inside inner ring)
    shapeBbox = case( termSide
      ( ("Top" "Bottom")
        list( -nrturnsHalf:0 nrturnsHalf:0 nrturnsHalf:idShapeWidth
          idShapeWidthHalf:idShapeWidth idShapeWidthHalf:idShapeWidth*2
          -idShapeWidthHalf:idShapeWidth*2 -idShapeWidthHalf:idShapeWidth
          -nrturnsHalf:idShapeWidth))
      ( ("Left" "Right")
        list( 0:-nrturnsHalf 0:nrturnsHalf -idShapeWidth:nrturnsHalf
          -idShapeWidth:idShapeWidthHalf -idShapeWidth*2:idShapeWidthHalf
          -idShapeWidth*2:-idShapeWidthHalf -idShapeWidth:-idShapeWidthHalf
          -idShapeWidth:-nrturnsHalf)))

    dbCreatePolygon( pcCellView idShapeIndLayer shapeBbox)

    ;; Create inductorID shape #5 (on inner ring, location based on toplayer)
    shapeBbox = cond( 
      ( toplayer == "tm1" && member( termSide list("Top" "Bottom"))
        list( car( cPt):cadr( cPt)-coilWidthHalf 
          car( cPt)+minGrid:cadr( cPt)+coilWidthHalf))
      ( toplayer == "tm1" ;("Left" "Right")
        list( car( cPt)-coilWidthHalf:cadr( cPt)
          car( cPt)+coilWidthHalf:cadr( cPt)+minGrid))
      ( drTable["idShape5bBox"] drTable["idShape5bBox"])
      ( drTable["idShape5bBox"] drTable["idShape5bBox"])
      ( (bridge = rodGetObj( "ind_bridge" pcCellView)) &&
        member( termSide list("Top" "Bottom"))
        list( bridge~>midRight0 
          car( bridge~>midLeft0)+minGrid:cadr( bridge~>midLeft0)))
      ( t ;; member( termSide list("Left" "Right"))
        list( bridge~>midRight0 
          car( bridge~>midLeft0):cadr( bridge~>midLeft0)+minGrid)))

    dbCreateRect( pcCellView idShapeIndLayer shapeBbox)

  )
)


procedure( fdkDrawSpiralIDShapes( pcCellView drTable paramTable)
  let(( coilSpace coilWidth idShapeIndLayer idShapeLayer 
    idShapeM12Layer idShapeTextSize idShapeTm1Layer idShapeWidth 
    idShapeWidthHalf minGrid mult nrturns nrturnsHalf numSeg 
    plusBbox s5mult s5vert segPt1 segPt2 shapeBbox termSide 
    tmpShapeList toplayer turn1A)

    coilWidth = paramTable["coilwx"]
    coilSpace = paramTable["coilspcx"]
    nrturns = paramTable["nrturns"]
    termSide = paramTable["termside"]
    toplayer = paramTable["toplayer"]
    idShapeTm1Layer = fdkPcLayer( drTable["layer"]["tm1"]["idLayer"])
    idShapeM12Layer = fdkPcLayer( drTable["layer"]["m12"]["idLayer"])
    idShapeIndLayer = fdkPcLayer( drTable["layer"]["inductorIDLayer"])
    idShapeTextSize = drTable["layer"]["inductorIDTextSize"]
    minGrid = drTable["minGrid"]
    turn1A = drTable["TT"][sprintf( nil "%s_turn1_sideA" toplayer)]

    ;; Do base calculations
    idShapeWidth = 0.01
    idShapeWidthHalf = fdkSnapGrid( minGrid idShapeWidth*0.5)
    nrturnsHalf = fdkSnapGrid( minGrid nrturns*0.5)

    ;; Create IND shape around inductor, not to include terminal pins
    idShapeLayer = if( toplayer == "tm1" idShapeTm1Layer idShapeM12Layer)
    tmpShapeList = dbLayerXor( pcCellView idShapeLayer
      list( turn1A~>dbId drTable["jumpTerm"]~>dbId) 
      list( drTable["plusPin"]~>dbId drTable["minusPin"]~>dbId))

    shapeBbox = rodCreateRect( ?cvId pcCellView ?layer idShapeLayer ?fromObj 
      foreach( mapcar shape tmpShapeList rodNameShape( ?shapeId shape)))
    foreach( shape tmpShapeList dbDeleteObject( shape))

    ;; Create IND text
    dbCreateLabel( pcCellView idShapeLayer 
      caar( shapeBbox~>dbId~>bBox):cadadr( shapeBbox~>dbId~>bBox) 
      sprintf( nil "InductorScl_%s" upperCase( toplayer)) 
      "leftTop" "R0" "stick" idShapeTextSize)

    ;; Create inductorID shape #1 (on terminal)
    when( plusBbox = rodGetObj( "plusPin" pcCellView)~>dbId~>bBox
      shapeBbox = case( termSide
        ( "Left" 
          list( caadr( plusBbox):cadar( plusBbox)
            caadr( plusBbox)+coilSpace:cadadr( plusBbox)))
        ( "Right"
          list( caar( plusBbox)-coilSpace:cadar( plusBbox) 
            caar( plusBbox):cadadr( plusBbox)))
        ( "Top" 
          list( caar( plusBbox):cadar( plusBbox)-coilSpace 
            caadr( plusBbox):cadar( plusBbox)))
        ( "Bottom" 
          list( caar( plusBbox):cadadr( plusBbox)
            caadr( plusBbox):cadadr( plusBbox)+coilSpace)))
  
      dbCreateRect( pcCellView idShapeIndLayer shapeBbox)
    ) ;; when

    ;; Create inductorID shape #2 (inside inner ring)
    numSeg = turn1A~>numSegments
    segPt1 = rodGetHandle( turn1A sprintf( nil "startRight%d" numSeg-2))
    segPt2 = rodGetHandle( turn1A sprintf( nil "endRight%d" numSeg-2))
    shapeBbox = if( abs( car( segPt1)-car( segPt2)) < minGrid then ;; vert seg
      s5vert = t
      mult = if( cadr( segPt2) > cadr( segPt1) 1 -1)
      list( car( segPt1)+minGrid*mult:cadr( segPt1) 
        car( segPt2)+(minGrid+idShapeWidth)*mult:cadr( segPt2))
    else
      mult = if( car( segPt2) < car( segPt1) 1 -1)
      list( car( segPt1):cadr( segPt1)+minGrid*mult 
        car( segPt2):cadr( segPt2)+(minGrid+idShapeWidth)*mult)
    ) ;; if
    s5mult = mult

    dbCreateRect( pcCellView idShapeIndLayer shapeBbox)

    ;; Create inductorID shape #3 (outside inner ring)
    segPt1 = rodGetHandle( turn1A sprintf( nil "startRight%d" numSeg-3))
    segPt2 = rodGetHandle( turn1A sprintf( nil "endRight%d" numSeg-3))
    shapeBbox = if( abs( car( segPt1)-car( segPt2)) < minGrid then ;; vert seg
      mult = if( cadr( segPt2) > cadr( segPt1) 1 -1)
      list( car( segPt1)-(coilWidth-idShapeWidthHalf)*mult:cadr( segPt1) 
        car( segPt2)-(coilWidth+idShapeWidthHalf)*mult:cadr( segPt2))
    else
      mult = if( car( segPt2) < car( segPt1) 1 -1)
      list( car( segPt1):cadr( segPt1)-(coilWidth-idShapeWidthHalf)*mult 
        car( segPt2):cadr( segPt2)-(coilWidth+idShapeWidthHalf)*mult)
    ) ;; if

    dbCreateRect( pcCellView idShapeIndLayer shapeBbox)

    ;; Create inductorID shape #4 (step ladder inside inner ring)
    shapeBbox = case( termSide
      ( ("Top" "Bottom")
        list( -nrturnsHalf:0 nrturnsHalf:0 nrturnsHalf:idShapeWidth
          idShapeWidthHalf:idShapeWidth idShapeWidthHalf:idShapeWidth*2
          -idShapeWidthHalf:idShapeWidth*2 -idShapeWidthHalf:idShapeWidth
          -nrturnsHalf:idShapeWidth))
      ( ("Left" "Right")
        list( 0:-nrturnsHalf 0:nrturnsHalf -idShapeWidth:nrturnsHalf
          -idShapeWidth:idShapeWidthHalf -idShapeWidth*2:idShapeWidthHalf
          -idShapeWidth*2:-idShapeWidthHalf -idShapeWidth:-idShapeWidthHalf
          -idShapeWidth:-nrturnsHalf)))

    dbCreatePolygon( pcCellView idShapeIndLayer shapeBbox)

    ;; Create inductorID shape #5 (on inner ring, location based on toplayer)
    shapeBbox = cond(
      ( toplayer == "tm1" && ( segPt1 = rodGetHandle( turn1A 
        sprintf( nil "midRight%d" numSeg-2))) && s5vert
        list( segPt1 car( segPt1)-coilWidth*s5mult:cadr( segPt1)+minGrid))
      ( toplayer == "tm1" 
        list( segPt1 car( segPt1)+minGrid:cadr( segPt1)+coilWidth*s5mult))
      ( drTable["idShape5bBox"] drTable["idShape5bBox"]))

    when( shapeBbox
      dbCreateRect( pcCellView idShapeIndLayer shapeBbox))

  )
)

procedure( fdkDrawVIDShapes( pcCellView drTable)
  let(( bBox cellName vidLayer)
    
    cellName = drTable["cellName"]
    vidLayer = fdkPcLayer( drTable["layer"]["VIDLayer"])
    bBox = rodCreateRect( ?cvId pcCellView ?layer vidLayer 
      ?bBox pcCellView~>bBox)
    dbCreateLabel( pcCellView vidLayer bBox~>centerCenter 
      sprintf( nil "vid_fdk_%s_1__0" cellName) "centerCenter" 
      "R0" "stick" if( bBox~>width > 45.0 2.0 1.0))
  )
)

procedure( fdkGetPRBboxDiff( fillerId minGrid)
  let(( bBox offsetList prBbox)
    bBox = fillerId~>bBox
    prBbox = fillerId~>prBoundary~>bBox
    offsetList = list( caar( bBox)-caar( prBbox) cadar( bBox)-cadar( prBbox)
      caadr( bBox)-caadr( prBbox) cadadr( bBox)-cadadr( prBbox))
    when( abs( car( offsetList)) < minGrid && 
      abs( cadr( offsetList)) < minGrid && 
      abs( caddr( offsetList)) < minGrid && 
      abs( cadddr( offsetList)) < minGrid
      offsetList = nil
    ) ;; when
    offsetList ;; Return value
  )
)

/*---------------------------------------------------------------------------
 procedure: fdkFillIndShape
 Purpose: Create a new cell based on the shape, an _fill cell that has the filling.
 ---------------------------------------------------------------------------*/
procedure( fdkFillIndShape( pcCellView drTable @optional origIndShapeBbox)
  let((indFlDumLib indBaseFlDumCell topMetalLst baseFillerId indBox 
    fillerWx fillerWy temp blockLayerList topMetFillerId indMetFlDumCells)

;; get bounding parameters from the filling cells
    indFlDumLib = drTable["fillCellLibrary"]
    indBaseFlDumCell = drTable["fillBaseCell"]
    indMetFlDumCells = drTable["fillTopCells"]
    baseFillerId = dbOpenCellViewByType(indFlDumLib indBaseFlDumCell "layout")
    topMetFillerId = dbOpenCellViewByType(indFlDumLib car( indMetFlDumCells) 
      "layout")
    temp = fdkFindCellFillBound( topMetFillerId pcCellView origIndShapeBbox)
    indBox = car( temp)		
    fillerWx = cadr( temp)		
    fillerWy = caddr( temp)

;; spread the filling cells, first the base, then the top metals
    fdkFindMosaicFill( pcCellView indFlDumLib indBox fillerWx fillerWy 
      list( "base" indBaseFlDumCell))
    fdkFindMosaicFill( pcCellView indFlDumLib indBox fillerWx fillerWy 
      list( "metalT" car( indMetFlDumCells)) t)
    when( cdr( indMetFlDumCells)
      fdkFindMosaicFill( pcCellView indFlDumLib indBox fillerWx fillerWy 
        list( "metalB" cadr( indMetFlDumCells)) t)
    ) ;; when

;; remove the overlapping cells
    topMetalLst = drTable["fillTopLayers"]
    fdkFindRemoveOverlap(pcCellView topMetalLst)

;; delete shapes and add PR boundaries and blockages
    dbCreatePRBoundary(pcCellView fdkListBBox(indBox))
;    dbCreatePRBoundary(pcCellView fdkListBBox(pcCellView->bBox))
    blockLayerList = drTable["fillBlockageLayers"]
    foreach( blockLayer blockLayerList
      dbCreateLayerBlockage(pcCellView blockLayer "fill" 
        fdkListBBox(pcCellView->bBox))	
    ) ;; foreach

;; close the cells   
    dbClose( baseFillerId)
    dbClose( topMetFillerId)
    t
));; procedure

/*---------------------------------------------------------------------------
 procedure: fdkIndBaseMosaicFill
 Purpose: Place filler base cells under the inductor metals using mosaics 
 ---------------------------------------------------------------------------*/
procedure( fdkFindCellFillBound(fillerId indId @optional indInstBbox)
  let( ( bBox lEdge rEdge tEdge bEdge fillerWx fillerWy wAdd lAdd 
    indBox width length minGrid)

;; set filling parameters
     bBox = indInstBbox || indId~>bBox
     minGrid = fdkGetProp( ddGetObj( indId~>libName indId~>cellName) "designRules:minGrid")
     lEdge = fdkPutOnGrid(leftEdge(bBox) minGrid)
     rEdge = fdkPutOnGrid(rightEdge(bBox) minGrid)
     tEdge = fdkPutOnGrid(topEdge(bBox) minGrid)
     bEdge = fdkPutOnGrid(bottomEdge(bBox) minGrid)
     fillerWx = caadr(fillerId~>prBoundary~>bBox)	
     fillerWy = cadadr(fillerId~>prBoundary~>bBox)

;; set the boundaries based on the basefilling cell
     width = abs( caadr( bBox)-caar( bBox))
     length = abs( cadadr( bBox)-cadar( bBox))

     wAdd = fdkPutOnGrid(((pcFix(fdkPutOnGrid(width/(2*fillerWx) minGrid))+1)*fillerWx - (width/2)) minGrid)
     lAdd = fdkPutOnGrid(((pcFix(fdkPutOnGrid(length/(2*fillerWy) minGrid))+1)*fillerWy - (length/2)) minGrid)

     indBox = list( list(lEdge-wAdd bEdge-lAdd) list(rEdge+wAdd tEdge+lAdd) )  
     list(indBox fillerWx fillerWy)
));; procedure


/*---------------------------------------------------------------------------
 procedure: fdkFindMetalMosaicFill
 Purpose: Place filler base cells under the inductor metals using mosaics or
          Place only the top most underneath filler metal/via cells under the fillCell given
 ---------------------------------------------------------------------------*/
procedure( fdkFindMosaicFill( fillCell flDumLib indBox Wx Wy layerList @optional (flatten nil))
  let( (rows cols fillerId origin arrayId mLayer minGrid)

;; set the row and cols parameters with origin


    minGrid = fdkGetProp( ddGetObj( fillCell~>libName fillCell~>cellName) "designRules:minGrid")
    cols = floor(fdkPutOnGrid( (rightEdge(indBox) - leftEdge(indBox)) / Wx minGrid))
    rows = floor(fdkPutOnGrid( (topEdge(indBox) - bottomEdge(indBox)) / Wy minGrid))
    origin = car(indBox)

;; check if we are filling the base layer    
    if( car( layerList) == "base" then
      mLayer = cadr( layerList)
      fillerId = dbOpenCellViewByType( flDumLib mLayer "layout")
      arrayId = dbCreateSimpleMosaic(fillCell fillerId "mBaseFill" origin 
        "R0" 2*rows 2*cols Wy/2 Wx/2)
      when(flatten dbFlattenInst(arrayId 1 t t t))
      dbClose(fillerId)
    else 
;; fill with metals and via under cells
      mLayer = cadr( layerList)
      fillerId = dbOpenCellViewByType( flDumLib mLayer "layout")
      if( car( layerList) =="metalT" then
        arrayId = dbCreateSimpleMosaic(fillCell fillerId strcat(mLayer "Fill") 
          origin "R0" rows cols Wy Wx)
      else
        arrayId = dbCreateSimpleMosaic(fillCell fillerId strcat(mLayer "Fill") 
          origin "R0" 2*rows 2*cols Wy/2 Wx/2)
      ) ; if mLayer
      when(flatten dbFlattenInst(arrayId 1 t t t))
      dbClose(fillerId)

    );; if
    t
));; procedure


procedure( fdkFindRemoveOverlap(fillCellId topMetalLst)
  let( (indShapes testObjs indShapesGrown (indShTile list()) growLen 
    overlapRex vLayer)

;;lambda function to get the via underneath a metal
    getViaUnder = lambda((x) pcreMatchp("\\D*(\\d+)" x)	strcat("v" fdkNum2Str(pcFix(cdfParseFloatString(pcreSubstitute("\\1")))-1)))

;;get the inductor shape layers, grow at min DRC them and convert them to rectangular trapezoids for overlapping comparison
    foreach(mLayer topMetalLst 
      if(mLayer == "tm1" then
        indShapes = setof(x fillCellId->shapes pcreMatchp("tm1" x->layerName))
	growLen = fdkSetDrcRules("tm1")
	indShapesGrown = dbLayerSize(fillCellId list("tm1" "drawing") indShapes growLen)
        indShTile = append(indShTile dbLayerTile(fillCellId (list "tm1" "drawing") indShapesGrown))
        mapcar('dbDeleteObject indShapesGrown)
      else
        indShapes = setof(x fillCellId->shapes pcreMatchp(mLayer x->layerName))
	growLen = fdkSetDrcRules(mLayer)
	indShapesGrown = dbLayerSize(fillCellId list(mLayer "drawing") indShapes growLen)
	indShTile = append(indShTile dbLayerTile(fillCellId list(mLayer "drawing") indShapesGrown))
        mapcar('dbDeleteObject indShapesGrown)
	);;if
      );;foreach

;; get the overlaps and remove only instances that have the metals of indShapes (inductor coil)
    foreach(window indShTile
      testObjs = dbProduceOverlapInst(fillCellId window->bBox) ; gets all overlapping instances in the window
      when(testObjs
        vLayer = apply(getViaUnder list(window->layerName))	
	overlapRex = strcat("[a-z0-9_]+fill"  window->layerName  vLayer )
        testObjs = setof(x testObjs pcreMatchp(overlapRex x->cellName 0x00000001)) ; gets only for the overlapping metal
        mapcar('lambda( (x) when(dbobjectp(x) dbDeleteObject(x)) ) testObjs) )
      );;foreach

;;  m12v11 removal if m12 fill cell does not have 4 m11v10 cells overlapping it (corner case for some dimensions of ind)
    m12insts = setof(x fillCellId~>instances pcreMatchp("d86sindfillm12v11" x~>cellName))
    foreach(m12inst m12insts
       bbox =  m12inst~>bBox
       bBoxnew = list(list(leftEdge(bbox)+0.001 bottomEdge(bbox)+0.001)  list(rightEdge(bbox)-0.001 topEdge(bbox)-0.001))
       overlapinsts=dbProduceOverlapInst( fillCellId bBoxnew)
;       m11insts = length(setof(x overlapinsts x~>cellName=="d86sindfillm11v10"))
       
       if( length(setof(x overlapinsts x~>cellName=="d86sindfillm11v10")) != 4 then
          dbDeleteObject(m12inst)
       );;if length
       
    ) ;; foreach m12insts 

;;cleanup
    mapcar('dbDeleteObject indShTile)
    t
));;procedure


/*
procedure( fdkFindRemoveOverlap(fillCellId topMetalLst)
  let( (indShapes testObjs indShapesGrown (indShTile list()) growLen 
    overlapRex vLayer)

;;lambda function to get the via underneath a metal
    getViaUnder = lambda((x) pcreMatchp("\\D*(\\d+)" x)	strcat("v" fdkNum2Str(pcFix(cdfParseFloatString(pcreSubstitute("\\1")))-1)))

;;get the inductor shape layers, grow at min DRC them and convert them to rectangular trapezoids for overlapping comparison
    foreach(mLayer topMetalLst 
      if(mLayer == "tm1" then
        indShapes = setof(x fillCellId->shapes pcreMatchp("tm1" x->layerName))
	growLen = fdkSetDrcRules("tm1")
	indShapesGrown = dbLayerSize(fillCellId list("tm1" "drawing") indShapes growLen)
        indShTile = append(indShTile dbLayerTile(fillCellId (list "tm1" "drawing") indShapesGrown))
        mapcar('dbDeleteObject indShapesGrown)
;	break()
      else
        indShapes = setof(x fillCellId->shapes pcreMatchp(mLayer x->layerName))
	growLen = fdkSetDrcRules(mLayer)
	indShapesGrown = dbLayerSize(fillCellId list(mLayer "drawing") indShapes growLen)
	indShTile = append(indShTile dbLayerTile(fillCellId list(mLayer "drawing") indShapesGrown))
        mapcar('dbDeleteObject indShapesGrown)
;	break()
	);;if
      );;foreach

;; get the overlaps and remove only instances that have the metals of indShapes (inductor coil)
    foreach(window indShTile
      testObjs = dbProduceOverlapInst(fillCellId window->bBox) ; gets all overlapping instances in the window
;      break()
      when(testObjs
        vLayer = apply(getViaUnder list(window->layerName))	
;	overlapRex = strcat("[a-z0-9_]+fill(" vLayer "|" window->layerName ")$")
	overlapRex = strcat("[a-z0-9_]+fill"  window->layerName  vLayer )
        testObjs = setof(x testObjs pcreMatchp(overlapRex x->cellName 0x00000001)) ; gets only for the overlapping metal
        mapcar('lambda( (x) when(dbIsObjectBound(x) dbDeleteObject(x)) ) testObjs) )
;	break()
      );;foreach

;;cleanup
    mapcar('dbDeleteObject indShTile)
    t
));;procedure
*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; NOTE: The following code was provided by Mauricio Marulanda.
;;       The code does not seem to be available in the current 
;;       release.  These functions should be removed from this 
;;       file as soon as they are checked in by Mauricio.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

/*---------------------------------------------------------------------------
 procedure: fdkSetDrcRules
 Purpose: Sets the minimum spacing between filling layers and the shape being filled.
 ---------------------------------------------------------------------------*/
procedure( fdkSetDrcRules(metalLyr)
  let( (grow)
    case(lowerCase(metalLyr) 
      ("tm1" grow = 5.5)
      ("m12" grow = 0.54)
      ("m11" grow = 0.63)
      ("m10" grow = 0.63)
      (t grow = 0.0)
    );;case  
    grow
));;procedure


;;****f* GridFunctions/fdkPutOnGrid
;;
;; FUNCTION
;;
;; fdkPutOnGrid - round floating number to the nearest grid point. Takes optional grid size (if different from 
;; specified in tech file).
;;
;; USAGE
;;
;; (fdkPutOnGrid 17.5)
(defun fdkPutOnGrid ( float_num grid )
"Round floating number to the nearest grid point. Takes optional grid size (if different from value
specified in tech file). => f_float"
    grid * ( round float_num/ grid ) 
);
