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

procedure( adAddTxtToNets(cv @optional (tProp nil))
let( (tPropEff)
  foreach(net cv~>nets
    foreach(pinFig net~>pins~>fig
      when(pinFig
	tPropEff = (if tProp tProp txtDir(pinFig~>bBox) )
        dbCreateLabel(cv pinFig~>lpp centerBox(pinFig~>bBox) net~>name "centerCenter" car(tPropEff) "stick" cadr(tPropEff))  
    )))
t))

procedure(txtDir(bBox)
let( (temp W H dir size)
  temp = adGetWH(bBox)
  W = car(temp) 	H = cadr(temp)
  if(W > H then dir = "R0" size = H
  else dir = "R90" size = W)
  list(dir size)
))
