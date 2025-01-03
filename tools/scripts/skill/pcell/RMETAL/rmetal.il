;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Intel Top Secret                                                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Copyright (C) 2020, Intel Corporation.  All rights reserved.               ;
;                                                                            ;
; This is the property of Intel Corporation and may only be utilized         ;
; pursuant to a written Restricted Use Nondisclosure Agreement               ;
; with Intel Corporation.  It may not be used, reproduced, or                ;
; disclosed to others except in accordance with the terms and                ;
; conditions of such agreement.                                              ;
;                                                                            ;
; All products, processes, computer systems, dates, and figures              ;
; specified are preliminary based on current expectations, and are           ;
; subject to change without notice.                                          ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Author:
;   Mauricio Marulanda
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure( mmRmetalCB(cdfId)
let( (metals mtl)
  metals = list("m1" "m2" "m3" "m4" "m5" "m6" "m7" "gmz" "gm0" "gmb")
  metals = reverse(metals)
  mtl = member(cdfId~>layer~>value metals)
  mtl = nth(1 mtl)
;  cdfId~>model~>value = strcat("r" cdfId~>layer~>value mtl)
  cdfId~>model~>value = strcat("r" cdfId~>layer~>value)
))
