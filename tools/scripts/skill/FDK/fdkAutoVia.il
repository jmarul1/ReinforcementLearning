;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Intel Top Secret                                                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copyright (C) 2013, Intel Corporation.  All rights reserved.             ;;
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
;;
;; Filename:
;;   fdkAutoVia.il
;;
;; Description:
;;   Defines functions to support auto via functionality.
;;   The functions work non-graphically or in GUI move 
;;
;; Globals:
;;
;; File revision History
;;
;; 09/18/2013: First version of code checked in.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function:
;;   fdkPreViaEngineProc
;;
;; Description:
;;  This function is a trigger for virtuoso auto via command.
;;
;; Inputs:
;;   Required: veContext which is passed by virtuoso engine.
;;
;; Returns:
;;   t/nil depending on whether a matching via is found
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure( fdkPreViaEngineProc( veContext @key debug )
  prog(( viaLayer tfId ptArray1 ptArray2 w h via layName1 layName2 ptList tmp
         wBot wTop layerStackList layerStack layName1StackDef layName2StackDef
         autoViaWidthRangeLayers
       )

    ; Check what operation via engine is doing. 
    ; Anything other than generate exit the trigger.
    when( veContext~>operationType != "generate"
      return(t)
    )

    ; get the viaDef and via related information.
    viaLayer = car( veContext~>viaModel~>viaDef~>params ) 

    ; get the techId
    tfId = veContext~>viaModel~>viaDef~>tech

    ; get the points on shapes
    ptArray1 = car( veContext~>overlapInfo )
    ptArray2 = cadr( veContext~>overlapInfo )

    ; get the overlapping shape point
    unless( car( dbPointArrayAnd( geGetEditCellView() ptArray1 ptArray2))
      return( )
    )

    ; get the overlapping shape widths
    ptList = car( ptArray2)
    w = abs( fdkRectWidth( list( car( ptList) caddr( ptList))))
    h = abs( fdkRectLength( list( car( ptList) caddr( ptList))))
    wBot = min( w h)
    layName2 = cadr( ptArray2)

    ptList = car( ptArray1)
    w = abs( fdkRectWidth( list( car( ptList) caddr( ptList))))
    h = abs( fdkRectLength( list( car( ptList) caddr( ptList))))
    wTop = min( w h)
    layName1 = cadr( ptArray1)


    ; when in create wire mode, the ordering can be swapped depending on
    ; whether we are going up or down the metal stack
    when( member( hiGetCurrentCmd( hiGetCurrentWindow()) list("Wire" "Geometric Wire"))

      layerStackList = setof( x techGetLayerFunctions(tfId) 
                         member(cadr(x) list("metal" "li")))
      layerStack = (foreach mapcar element layerStackList car(element))

      when( member(layName1 layerStack) && member(layName2 layerStack)

        layName1StackDef = car(setof( x layerStackList equal( car(x) layName1)))
        layName2StackDef = car(setof( x layerStackList equal( car(x) layName2)))

        when( caddr(layName1StackDef) < caddr(layName2StackDef)
          tmp  = wBot
          wBot = wTop
          wTop = tmp
          tmp      = layName1
          layName1 = layName2
          layName2 = tmp 
        )
      )
    )

    ; get the matching via
    cond(
      ( via = fdk_getFittingVia( tfId wBot wTop viaLayer layName2 )
        veContext~>viaModel~>cutWidth = via->cutWidth
        veContext~>viaModel~>cutHeight = via->cutHeight
        veContext~>viaModel~>cutColumns = via->cols || 1
        veContext~>viaModel~>cutRows = via->rows || 1
        when( debug
          printf( "-D-: cutWidth %L, cutHeight %L, cutColumns %L, cutRows %L\n"
            via->cutWidth via->cutHeight via->cols||1 via->rows||1)
        )
        return(t)
      )
      ( (autoViaWidthRangeLayers = techGetParam( tfId "autoViaWidthRangeLayers")) &&
          member( layName2 autoViaWidthRangeLayers)
        return(t)
      )
      ( t
        warn( "No Fitting via found for via layer %L and metal widths %L.\n" 
          viaLayer list( wTop wBot))
        (return)
      )
    )
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function:
;;   fdkPostViaEngineProc
;;
;; Description:
;;  This function is a post trigger for virtuoso auto via command.
;;
;; Inputs:
;;   Required: veContext which is passed by virtuoso engine.
;;
;; Returns:
;;   t/nil depending on whether a matching via is found
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure( fdkPostViaEngineProc( veContext @key debug )
  prog(( viaLayer tfId ptArray1 ptArray2 w h via layName1 layName2 ptList tmp
         wBot wTop layerStackList layerStack layName1StackDef layName2StackDef
         autoViaWidthRangeLayers
       )

    ; Check what operation via engine is doing. 
    ; Anything other than generate exit the trigger.
    when( veContext~>operationType != "generate"
      return(t)
    )

    ; get the viaDef and via related information.
    viaLayer = car( veContext~>viaModel~>viaDef~>params ) 

    ; get the techId
    tfId = veContext~>viaModel~>viaDef~>tech

    ; get the points on shapes
    ptArray1 = car( veContext~>overlapInfo )
    ptArray2 = cadr( veContext~>overlapInfo )

    ; get the overlapping shape point
    unless( car( dbPointArrayAnd( geGetEditCellView() ptArray1 ptArray2))
      return( )
    )

    ; get the overlapping shape widths
    ptList = car( ptArray2)
    w = abs( fdkRectWidth( list( car( ptList) caddr( ptList))))
    h = abs( fdkRectLength( list( car( ptList) caddr( ptList))))
    wBot = min( w h)
    layName2 = cadr( ptArray2)

    ptList = car( ptArray1)
    w = abs( fdkRectWidth( list( car( ptList) caddr( ptList))))
    h = abs( fdkRectLength( list( car( ptList) caddr( ptList))))
    wTop = min( w h)
    layName1 = cadr( ptArray1)


    ; when in create wire mode, the ordering can be swapped depending on
    ; whether we are going up or down the metal stack
    when( member( hiGetCurrentCmd( hiGetCurrentWindow()) list("Wire" "Geometric Wire"))

      layerStackList = setof( x techGetLayerFunctions(tfId) equal(cadr(x) "metal") || equal(cadr(x) "li"))
      layerStack = (foreach mapcar element layerStackList car(element))

      when( member(layName1 layerStack) && member(layName2 layerStack)

        layName1StackDef = car(setof( x layerStackList equal( car(x) layName1)))
        layName2StackDef = car(setof( x layerStackList equal( car(x) layName2)))

        when( caddr(layName1StackDef) < caddr(layName2StackDef)
          tmp  = wBot
          wBot = wTop
          wTop = tmp
          tmp      = layName1
          layName1 = layName2
          layName2 = tmp 
        )
      )
    )

    ; get the matching via
    cond(
      ( via = fdk_getFittingVia( tfId wBot wTop viaLayer layName2 )
        when( via->botLayerExt
            veContext~>viaModel~>layer1EncLeft   = car( via->botLayerExt)
            veContext~>viaModel~>layer1EncRight  = car( via->botLayerExt)
            veContext~>viaModel~>layer1EncTop    = cadr(via->botLayerExt)
            veContext~>viaModel~>layer1EncBottom = cadr(via->botLayerExt)
        )
        when( via->topLayerExt
            veContext~>viaModel~>layer2EncLeft   = car( via->topLayerExt)
            veContext~>viaModel~>layer2EncRight  = car( via->topLayerExt)
            veContext~>viaModel~>layer2EncTop    = cadr(via->topLayerExt)
            veContext~>viaModel~>layer2EncBottom = cadr(via->topLayerExt)
        )  
        when( debug
          printf( "-D-: layer1EncLeft/layer1EncRight %L, layer1EncTop/layer1EncBottom %L\n"
            car( via->botLayerExt) cadr( via->botLayerExt)))
        return(t)
      )
      ( (autoViaWidthRangeLayers = techGetParam( tfId "autoViaWidthRangeLayers")) && 
          member( layName2 autoViaWidthRangeLayers)
        return(t)
      )
      ( t
        warn( "No Fitting via found for via layer %L and metal widths %L.\n" 
          viaLayer list( wTop wBot))
        return()
      )
    )
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function:
;;   fdk_getFittingVia
;;
;; Description:
;;  This function returns a DPL for a via which fits the given location, as
;;  defined in the viaRulesTbl table. 
;;
;; Inputs:
;;   Required: 
;;   tfId     :tech file ID
;;   botLW    :bot layer width
;;   topLW    :top layer width
;;   viaLayer :via layer name
;;   botMetal : bottom layer name. NOTE: Not used but left behind for 
;;     backwards compatibility.
;;
;; Returns:
;;   via: DPL which usually includes topLayer, topLayerWidth, topLayerExt,
;;     botLayer, botLayerWidth, botLayerExt, cutClass, cutWidth, cutHeight,
;;     orient, rows, cols.  The fields of the returned DPL may vary.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure( fdk_getFittingVia( tfId botLW topLW viaLayer botMetal 
  @key debug viaRulesTbl )
  let(( via)
        
    unless( viaRulesTbl
      viaRulesTbl = fdkViaFillDefineRules( tfId )
    )

    via = viaRulesTbl[viaLayer][sprintf(nil "%Lx%L" topLW botLW )]

    when( debug && via
      printf( "-D-: Found fitting via. viaRulesTbl[%L][%Lx%L] - %L\n" viaLayer topLW botLW via)
    ) 

    via ;; Return value
  )
)
