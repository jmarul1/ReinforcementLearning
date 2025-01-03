;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Intel Top Secret                                                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copyright (C) 2014, Intel Corporation.  All rights reserved.             ;;
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

putd( 'fdkPcMimcapGenLayout nil )
procedure(

  fdkPcMimcapGenLayout(paramTable drTable)

let((
    BLOCKAGE_LAYER
    BM_LAYER
    BOTTOM_LAYER
    BOTTOM_RECOG_LAYER
    TM_LAYER
    TM_PIN_LAYER
    TOP_LAYER
    TOP_RECOG_LAYER
    VIA_BLOCKAGE_LAYER
    VIA_LAYER
    bm_min_width
    bm_ol_via
    bm_ol_via_X
    bottomLayerShape
    bottom_plate_length
    bottom_plate_width
    diff
    dev_length
    metType
    stacked
    minGrid
    term_name_A
    term_name_B
    tm_ol_via
    tmpBottomLayerHoleList
    tmpTopLayerHoleList
    topLayerShape
    top_bottom_ol
    top_plate_length
    top_plate_width
    viaOffsetL
    viaOffsetR
    viaType
    via_bBox_B
    viaList_B
    via_bBox_T
    viaList_T
    via_height
    via_hole_bbox_T
    via_hole_bbox_B
    via_hole_space
    via_num
    via_offset
    via_space
    via_width
    via_width_half
    dev_width
  )

  ;; Retrieve parameters from table
  dev_width = paramTable["width"]
  dev_length = paramTable["length"]
  viaOffsetL = paramTable["viaOffsetL"]
  viaOffsetR = paramTable["viaOffsetR"]
  viaType = paramTable["viaType"]
  metType = paramTable["metType"]
  stacked = paramTable["stacked"]
  minGrid = paramTable["minGrid"]

  ;; Retrieve design rules from table
  VIA_LAYER = fdkPcLayer( drTable["viaLayer"] )
  TM_LAYER = fdkPcLayer( drTable["upperMetal"]["layer"] )
  TM_PIN_LAYER = fdkPcLayer( drTable["upperMetal"]["pinLayer"] )
  BM_LAYER = fdkPcLayer( drTable["lowerMetal"]["layer"] )
  TOP_LAYER = fdkPcLayer( drTable["MIMTLayer"] )
  BOTTOM_LAYER = fdkPcLayer( drTable["MIMBLayer"] )
  TOP_RECOG_LAYER = list( car(TOP_LAYER) "keepGenAway" )
  BOTTOM_RECOG_LAYER = list( car(BOTTOM_LAYER) "keepGenAway" )
  VIA_BLOCKAGE_LAYER = fdkPcLayer( drTable["viaBlockageLayer"] )

  term_name_A = drTable["term_name_A"]
  term_name_B = drTable["term_name_B"]
  tm_ol_via = drTable["upperMetal"]["overlap"]
  bm_ol_via = drTable["lowerMetal"]["overlap"]
  bm_min_width = drTable["lowerMetal"]["minWidth"]
  top_bottom_ol = drTable["MIMOffset"]
  via_hole_space = drTable["MIMSpaceVia"]
  def_via_type = drTable["viaTypeVal"]

  ;; Calculate number of vias to create and vertical offset
  via_width = drTable["viaType"][viaType]["width"]
  via_height = drTable["viaType"][viaType]["length"]

  when( drTable["defaultViaRotate"]
   via_width = via_height
   via_height = drTable["viaType"][viaType]["width"]
  ) ;; when

  via_space = drTable["MIMMinWidth"]+2*via_hole_space

  via_num = floor((dev_width-drTable["MIMMinWidth"] )/(via_height+2*via_hole_space+drTable["MIMMinWidth"] ))

  via_offset = (fdkSnapGrid minGrid (dev_width-2*tm_ol_via-via_num*via_height-(via_num-1)*via_space)/2.0)

  via_width_half = fdkSnapGrid( minGrid via_width/2.0)

  ;; Check that bottom metal to be created meets minWidth
  bm_ol_via_X = if( (via_width + 2 * bm_ol_via) < bm_min_width
                then ceiling((pcFix(bm_min_width/minGrid) - pcFix(via_width/minGrid))/2.0)*minGrid
                else bm_ol_via
                )

  ;;**************************************************
  ;; Create top & bottom vias & holes
  ;;**************************************************
  via_bBox_B = list(
    viaOffsetL-via_width_half:via_offset+tm_ol_via
    viaOffsetL+via_width_half:via_offset+tm_ol_via+via_num*via_height+(via_num-1)*via_space
  )

  viaList_B = rodFillBBoxWithRects(
                ?cvId pcCellView
                ?layer VIA_LAYER
                ?fillBBox via_bBox_B
                ?width via_width
                ?length via_height
                ?gap "minimum"
                ?spaceX via_space
                ?spaceY via_space
                ?returnBoolean nil
              )

  tmpBottomLayerHoleList = dbLayerSize(pcCellView VIA_LAYER viaList_B via_hole_space)

  via_bBox_T = list(
    dev_length-viaOffsetR-via_width_half:via_offset+tm_ol_via
    dev_length-viaOffsetR+via_width_half:via_offset+tm_ol_via+via_num*via_height+(via_num-1)*via_space
  )

  viaList_T = rodFillBBoxWithRects(
                ?cvId pcCellView
                ?layer VIA_LAYER
                ?fillBBox via_bBox_T
                ?width via_width
                ?length via_height
                ?gap "minimum"
                ?spaceX via_space
                ?spaceY via_space
                ?returnBoolean nil
              )

  tmpTopLayerHoleList = dbLayerSize(pcCellView VIA_LAYER viaList_T via_hole_space)

  ;;**************************************************
  ;; Create bottom plate with vias, holes, bottom metal and pins
  ;;**************************************************

  bottom_plate_length = dev_length
  bottom_plate_width = dev_width

  bottomLayerShape = let((botLyrEr newShape)

    botLyrEr = dbCreateRect(pcCellView BOTTOM_RECOG_LAYER list(0:0 bottom_plate_length:bottom_plate_width))

    case( stacked

      ;;; if we're double-stacked, then create two solid pieces connected to the vias
      ( "double" let((bottom_spacing x1 x2 bottom_gap)

        bottom_spacing = max(drTable["MIMBspace"] drTable["lowerMetal"]["space"] )

        x1 = floor(pcFix(((leftEdge(botLyrEr) + rightEdge(botLyrEr) - bottom_spacing)/2)/minGrid))*minGrid
        x2 = ceiling(pcFix((x1 + bottom_spacing)/minGrid))*minGrid

        bottom_gap = list(
          dbCreateRect(pcCellView list("scl_mim" "id2") list(x1:bottomEdge(botLyrEr) x2:topEdge(botLyrEr)))
          dbCreateRect(pcCellView list("scl_mim" "id3") list(x1:bottomEdge(botLyrEr) x2:topEdge(botLyrEr)))
        )

        newShape = dbLayerAndNot(pcCellView BOTTOM_LAYER list(botLyrEr) bottom_gap)

      ))

      ;;; otherwise, create holes around the vias on one side
      ( t

        newShape = dbLayerAndNot(pcCellView BOTTOM_LAYER list(botLyrEr) tmpBottomLayerHoleList)

        ;; Clean up temporary shapes
        foreach( figId tmpBottomLayerHoleList dbDeleteObject(figId) )

      )

    )

    dbDeleteObject(botLyrEr)

    newShape

  )

  ;; add bottom metal in appropriate form
  case( metType
    ( "solid"
      dbCreateRect( pcCellView BM_LAYER
        list(
          rodSubPoints(lowerLeft(via_bBox_B) bm_ol_via_X:bm_ol_via)
          rodAddPoints(upperRight(via_bBox_B) bm_ol_via_X:bm_ol_via)
        )
      )
    )
    ( "broken"
      if( round(bm_ol_via_X/minGrid) != round(bm_ol_via/minGrid)
      then foreach( viaFigId viaList_B
             dbCreateRect(pcCellView BM_LAYER
               list(
                 rodSubPoints(lowerLeft(viaFigId->bBox) bm_ol_via_X:bm_ol_via)
                 rodAddPoints(upperRight(viaFigId->bBox) bm_ol_via_X:bm_ol_via)
               )
             )
           )
      else dbLayerSize(pcCellView BM_LAYER viaList_B bm_ol_via)
      )
    )
    ( t error(sprintf(nil "Unexpected metType value %L" metType)) )
  )

  ;; Create pin connectivity shapes
  dbCreateRect(pcCellView TM_LAYER 
    list(
      rodSubPoints(lowerLeft(via_bBox_B) tm_ol_via:tm_ol_via)
      rodAddPoints(upperRight(via_bBox_B) tm_ol_via:tm_ol_via)
    )
  )

  ;; create TM pin layer shape(s)
  rodCreateRect(?cvId pcCellView
    ?name "right_term"
    ?layer TM_PIN_LAYER
    ?bBox list(
            rodSubPoints(lowerLeft(via_bBox_B) tm_ol_via:tm_ol_via)
            rodAddPoints(upperRight(via_bBox_B) tm_ol_via:tm_ol_via)
          )
    ?pin t
    ?termName term_name_B
    ?netName term_name_B
  )

  dbCreateLabel(pcCellView TM_PIN_LAYER
    rodGetObj("right_term" pcCellView)->centerCenter
    term_name_B
    "centerCenter" "R90" "roman" 2.0
  )

  ;;************************************************************
  ;; Create top plate with vias, holes, bottom metal, and pins
  ;;************************************************************

  top_plate_length = dev_length+2*top_bottom_ol
  top_plate_width = dev_width+2*top_bottom_ol

  topLayerShape = let((topLyrEr newShape)

    ;; Create top plate with holes
    topLyrEr = dbCreateRect(pcCellView TOP_RECOG_LAYER
                 dbTransformBBox(list(0:0 top_plate_length:top_plate_width) list(-top_bottom_ol:-top_bottom_ol "R0"))
               )

    case( stacked

      ;;; if we're double-stacked, then create holes around the vias on both sides
      ( "double" let((tmp_hole_list)

        tmp_hole_list = append(tmpBottomLayerHoleList tmpTopLayerHoleList)
  
        newShape = dbLayerAndNot(pcCellView TOP_LAYER list(topLyrEr) tmp_hole_list)

        ;; Clean up temporary shapes
        foreach( figId tmp_hole_list dbDeleteObject(figId) )

      ))

      ;;; otherwise, just create holes around the vias on one side
      ( t

        newShape = dbLayerAndNot(pcCellView TOP_LAYER list(topLyrEr) tmpTopLayerHoleList)

        ;; Clean up temporary shapes
        foreach( figId tmpTopLayerHoleList dbDeleteObject(figId) )

      )

    )

    dbDeleteObject(topLyrEr)

    newShape

  )

  ;; add bottom metal in appropriate form
  case( metType
    ( "solid"
      dbCreateRect( pcCellView BM_LAYER
        list(
          rodSubPoints(lowerLeft(via_bBox_T) bm_ol_via_X:bm_ol_via)
          rodAddPoints(upperRight(via_bBox_T) bm_ol_via_X:bm_ol_via)
        )
      )
    )
    ( "broken"
      if( round(bm_ol_via_X/minGrid) != round(bm_ol_via/minGrid)
      then foreach( viaFigId viaList_T
             dbCreateRect(pcCellView BM_LAYER
               list(
                 rodSubPoints(lowerLeft(viaFigId->bBox) bm_ol_via_X:bm_ol_via)
                 rodAddPoints(upperRight(viaFigId->bBox) bm_ol_via_X:bm_ol_via)
               )
             )
           )
      else dbLayerSize(pcCellView BM_LAYER viaList_T bm_ol_via)
      )
    )
    ( t error(sprintf(nil "Unexpected metType value %L" metType)) )
  )

  dbCreateRect(pcCellView TM_LAYER
    list(
      rodSubPoints(lowerLeft(via_bBox_T) tm_ol_via:tm_ol_via)
      rodAddPoints(upperRight(via_bBox_T) tm_ol_via:tm_ol_via)
    )
  )

  rodCreateRect(?cvId pcCellView
    ?layer TM_PIN_LAYER
    ?name "left_term"
    ?bBox list(
            rodSubPoints(lowerLeft(via_bBox_T) tm_ol_via:tm_ol_via)
            rodAddPoints(upperRight(via_bBox_T) tm_ol_via:tm_ol_via)
          )
    ?pin t
    ?netName term_name_A
    ?termName term_name_A
  )

  dbCreateLabel(pcCellView TM_PIN_LAYER
    rodGetObj("left_term" pcCellView)->centerCenter
    term_name_A
    "centerCenter" "R90" "roman" 2.0     
  )

  ;;**************************************************
  ;; ADD MIMCAP ID layers
  ;;**************************************************
  rodCreateRect(
    ?cvId pcCellView
    ?name "left_mimcap_id"
    ?layer list("scl_mim" "id3")
    ?width viaOffsetL-via_width/2.0-via_hole_space
    ?length dev_width
    ?origin 0:0
  )

  rodCreateRect(
    ?cvId pcCellView
    ?name "right_mimcap_id"
    ?layer list("scl_mim" "id2")
    ?width viaOffsetR-via_width/2.0-via_hole_space
    ?length dev_width
    ?origin dev_length - (viaOffsetR-via_width/2.0-via_hole_space):0
  )

  rodCreateRect(
    ?cvId pcCellView
    ?name "center_mimcap_id"
    ?layer list("scl_mim" "id1")
    ?bBox list(0:0 dev_length:dev_width)
  )
  
  ;;**************************************************
  ;; Create routing blockage shapes
  ;;**************************************************

  ; TM_PIN_LAYER routing blockage
  let((tm_pins)
  if( dtpr(tm_pins = setof(fig pcCellView->shapes fig->lpp == TM_PIN_LAYER))
  then foreach( pinFig tm_pins
       let((blkg)
         blkg = dbCreateLayerBlockage(
                  pcCellView car(TM_PIN_LAYER) "routing"
                  pinFig->points ||
                  let((x1 y1 x2 y2)
                    x1 = leftEdge(pinFig)
                    y1 = bottomEdge(pinFig)
                    x2 = rightEdge(pinFig)
                    y2 = topEdge(pinFig)
                    list(x1:y1 x2:y1 x2:y2 x1:y2)
                  )
                )
       ))
  else warn("Couldn't find any %L shapes in cell view %s/%s/%s\n"
         TM_PIN_LAYER pcCellView->libName pcCellView->cellName pcCellView->viewName
       )
  ))
  
  ; VIA ROUTING BLOCKAGE AROUND PRBOUNDARY
  ; create prBoundary if necessary
  let((prBnd_list)
    prBnd_list = cond(
                   ( null(pcCellView->prBoundary)
                   let((bb x1 y1 x2 y2)
                     bb = dbComputeBBoxNoNLP(pcCellView)
                     x1 = xCoord(lowerLeft(bb))
                     y1 = yCoord(lowerLeft(bb))
                     x2 = xCoord(upperRight(bb))
                     y2 = yCoord(upperRight(bb))
                     list(dbCreatePRBoundary(pcCellView list(x1:y1 x2:y1 x2:y2 x1:y2)))
                   ))
                   ( dtpr(pcCellView->prBoundary)
                     pcCellView->prBoundary
                   )
                   ( t list(pcCellView->prBoundary) )
                 )
    foreach( prBndId prBnd_list
    let((blkg)
      blkg = dbCreateLayerBlockage(pcCellView car(VIA_LAYER) "routing" prBndId->points)
    ))
  )

  ; BM ROUTING BLOCKAGE 1.0nm INSIDE BM SHAPES
  let((bm_figs temp_bm_figs)
  if( dtpr(bm_figs = setof(fig pcCellView->shapes fig->lpp == BM_LAYER))
  then temp_bm_figs = dbLayerSize(pcCellView BM_LAYER bm_figs -1.0e-03)
       while( dtpr(temp_bm_figs)
       let((temp_bm_fig blkg)
         temp_bm_fig = car(temp_bm_figs)
         blkg = dbCreateLayerBlockage(
                  pcCellView car(BM_LAYER) "routing"
                  temp_bm_fig->points ||
                  let((x1 y1 x2 y2)
                     x1 = leftEdge(temp_bm_fig)
                     y1 = bottomEdge(temp_bm_fig)
                     x2 = rightEdge(temp_bm_fig)
                     y2 = topEdge(temp_bm_fig)
                     list(x1:y1 x2:y1 x2:y2 x1:y2)
                  )
                )
         temp_bm_figs = cdr(temp_bm_figs)
         dbDeleteObject(temp_bm_fig)
       ))
  else warn(
         "Couldn't find any BM pins in pcell view %s/%s/%s\n"
         pcCellView->libName pcCellView->cellName pcCellView->viewName
       )
  ))

  ;;**************************************************
  ;; Create fill blockage layers
  ;;**************************************************
  foreach( fillBlockLayer list(car(TOP_LAYER) car(BOTTOM_LAYER) car(VIA_LAYER))
    dbCreateLayerBlockage(
      pcCellView fillBlockLayer "fill" fdkListBBox(pcCellView->bBox)
    )
  )

t))
