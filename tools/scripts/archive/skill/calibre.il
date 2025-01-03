;##############################################################################
;# Intel Top Secret                                                           #
;##############################################################################
;# Copyright (C) 2015, Intel Corporation.  All rights reserved.               #
;#                                                                            #
;# This is the property of Intel Corporation and may only be utilized         #
;# pursuant to a written Restricted Use Nondisclosure Agreement               #
;# with Intel Corporation.  It may not be used, reproduced, or                #
;# disclosed to others except in accordance with the terms and                #
;# conditions of such agreement.                                              #
;#                                                                            #
;# All products, processes, computer systems, dates, and figures              #
;# specified are preliminary based on current expectations, and are           #
;# subject to change without notice.                                          #
;##############################################################################
;# Author:
;#   Mauricio Marulanda
;##############################################################################

/*---------------------------------------------------------------------------
 procedure: fdkPutCalibreId
 Created by Mauricio Marulanda
 Purpose: Creates an ID layer 1um smaller on all sides of the PRBoundary.
 ---------------------------------------------------------------------------*/
procedure( fdkPutCalibreId(libName cellName @key (viewName "layout") (lpp list("poly" "pin")) (offset -1))
let( (cv points newPolygon tempPolygon)
  cv = dbOpenCellViewByType(libName cellName viewName "maskLayout" "a")
  when(and(cv cv~>prBoundary)
    points = cv~>prBoundary~>points
    tempPolygon = rodCreatePolygon(?cvId cv ?layer lpp ?pts points)
    newPolygon = dbLayerSize(cv lpp list(tempPolygon~>dbId) offset)
    dbDeleteObject(tempPolygon~>dbId)
    dbSave(cv) dbClose(cv)
  )  
newPolygon
));procedure
