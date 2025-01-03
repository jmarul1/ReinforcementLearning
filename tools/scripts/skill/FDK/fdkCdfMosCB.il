;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Intel Top Secret                                                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copyright (C) 2009, Intel Corporation.  All rights reserved.             ;;
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
;;480n M
;; Function: 
;;   fdkPcMinFingersNeededForW
;;
;; Description:
;;   Calculates the minimum number of fingers needed for a given W:
;;
;;   - Let Wgiv = Given W
;;   - Let Wmax = Maximum W per finger for this device
;;   - Let a = Bird's beak add-on value
;;
;;                / Wgiv - a \
;;   n = ceiling |  --------  |
;;                \ Wmax - a /
;;
;; Inputs:
;;   - Wgiv: The transistor width from the schematic (as a float)
;;   - Wmax: The maximum transistor width allowed per finger
;;   - addon: The amount of W to add on for each subsequent finger (float)
;;
;; Returns:
;;   The minimum number of fingers required in layout for this device.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkPcMinFingersNeededForW (Wgiv Wmax addon)
  (fdkPcFingersNeededForW Wgiv Wmax addon 'ceiling))
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkPcMaxFingersAllowedForW
;;
;; Description:
;;   Calculates the maximum number of fingers allowed for a given W:
;;
;;   - Let Wgiv = Given W
;;   - Let Wmin = Minimum W per finger for this device
;;   - Let a = Bird's beak add-on value
;;
;;              / Wgiv - a \
;;   n = floor |  --------  |
;;              \ Wmin - a /
;;
;; Inputs:
;;   - Wgiv: The transistor width from the schematic (as a float)
;;   - Wmin: The minimum transistor width allowed per finger
;;   - addon: The amount of W to add on for each subsequent finger (float)
;;
;; Returns:
;;   The maximum number of fingers allowed in layout for this device.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkPcMaxFingersAllowedForW (Wgiv Wmin addon)
  (fdkPcFingersNeededForW Wgiv Wmin addon 'floor))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Function: 
;;   fdkPcFingersNeededForW
;;
;; Description:
;;   Calculates the number of fingers needed for a given W considering a target
;;   W per finger.  The number of fingers will be snapped according to a snap
;;   function given.  The snap function accepts a single floating-point
;;   argument and returns a snapped integer value.
;;
;;   This function is used for base functionality by the following:
;;   - fdkPcMinFingersNeededForW
;;   - fdkPcMaxFingersAllowedForW
;;
;;   The algorithm is as follows:
;;
;;   - Let Wgiv = Given W
;;   - Let Wtgt = Target W per finger
;;   - Let a = Bird's beak add-on value
;;
;;               / Wgiv - a \
;;   n = snapfn |  --------  |
;;               \ Wtgt - a /
;;
;; Inputs:
;;   - Wgiv: The transistor width from the schematic (as a float)
;;   - Wtgt: The target W per finger (as a float)
;;   - addon: The amount of W to add on for each subsequent finger (float)
;;   - snapfn: The snapping function (e.g. 'ceiling or 'floor)
;;
;; Returns:
;;   The number of fingers allowed in layout for this device.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun fdkPcFingersNeededForW (Wgiv Wtgt addon snapfn)
  (let ((fingers ((Wgiv-addon)/(Wtgt-addon)))
        (tolerance 1e-9))
    (max 1 (if (leqp (abs (fingers - (round fingers))) tolerance)
             ;; Close to integer - snap to it
             (round fingers)
             ;; Else, snap 
             (funcall snapfn fingers)))))

procedure( fdkCdfIsStackMos( @optional caller)
    let( (cdfId cell)
	 cdfId = caller || cdfgData
         case( cdfId->type
            ("cellData"
                cell = cdfId->id->name
            )
            ("instData"
                cell = cdfId->id->cellName
            )
            (t
                warn( "Cannot determine cell or lib name from CDF type: %L\n" cdfId->type)
            )
         )
         rexMatchp("_s$", cell)   
    )
)

(defun fdkCdfMosCB (@optional caller whichparam)
  
  (fdkCdfDebug 1 ">>>>> Entering fdkCdfMosCB <<<<<\n")
  (let ((cdfId (or caller cdfgData)))
    (let ((cell (case cdfId->type
                  ("cellData" cdfId->id->name)
                  ("instData" cdfId->id->cellName)
                  (t (warn "Cannot determine cell name from CDF type: %L\n" cdfId->type))))
          ;(cvType (hiGetCurrentWindow)~>cellView~>cellViewType)
          (simValues (makeTable "Simulation Values" nil))
	        (lib (case cdfId->type
                  ("cellData" cdfId->id->lib->name)
                  ("instData" cdfId->id->libName)
                  (t (warn "Cannot determine lib name from CDF type: %L\n" cdfId->type))))
          layout
          cellId gt_w gt_l gt_m gt_nf gt_nfsub gt_lMax gt_lMin gt_lStep gt_polySpace gt_wBBeak gt_lChoices gt_lChoices_f gt_wChoices gt_wChoices_f
          gt_wMin gt_wMax gt_pitch ws wd wi
          minDiffconLength
	      dcExtB dcExtT endcapExtT endcapExtB
          sharedSourceEndcaps sharedDrainEndcaps 
	      totalSourceEndcaps totalDrainEndcaps 
	      w_adj l_adj fin  diffconExt polyExt shieldPolyExt minPolyLength shieldPolyEndcapT shieldPolyEndcapB 
          isoNested nf w l m maxFingers minFingers nfsub shieldL lRangeAdjusted
          )

      ;;; Determine if this is a layout window
      (setq layout nil)
      ;;; GET TECH VALUES FROM THE GLOBAL TECH
      ;;; DEFINE cellId
      cellId = ddGetObj(lib cell)
      gt_wMax = (fdkGetProp cellId "maxDiffWidth")
      gt_wMin = (fdkGetProp cellId "minDiffWidth")
      gt_w = (fdkGetProp cellId "defaults:w")
      gt_l = (fdkGetProp cellId "defaults:l")
      gt_lMax = (fdkGetProp cellId "defaults:lMax")
      gt_lMin = (fdkGetProp cellId "defaults:lMin")
      gt_lStep = (fdkGetProp cellId "defaults:lStep")
      gt_polySpace = (fdkGetProp cellId "polySpace")
      ;wSelectDisplay = (fdkGetProp cellId "defaults:wSelectDisplay")
      ;lSelectDisplay = (fdkGetProp cellId "defaults:lSelectDisplay")
      gt_pitch = (fdkGetProp cellId "gatePitch") 
      gt_m = (sprintf nil "%d" (fix (fdkGetProp cellId "defaults:m")))
      gt_nf = (sprintf nil "%d" (fix (fdkGetProp cellId "defaults:nf")))
      gt_nfsub = (sprintf nil "%d" (fix (fdkGetProp cellId "defaults:nfsub")))
      gt_wBBeak = (fdkGetProp cellId "wBBeak")
      gt_lChoices = (fdkGetProp cellId "gateLength")
      gt_wChoices = (fdkGetProp cellId "wChoices")
      ;;delta_w = (fdkGetProp cellId "DeltaWidth")
      ;;delta_l = (fdkGetProp cellId "DeltaLength")
      diffconExt = fdkGetProp(cellId "diffconExt")
      polyExt = car(fdkGetProp(cellId "endCap"))
      if(getShellEnvVar("FDK_MOS_PGDABUT") && getShellEnvVar("FDK_MOS_PGDABUT") == "TRUE"
         shieldPolyExt=car(fdkGetProp(cellId "endCapShieldPolyPgdAbut"))
         shieldPolyExt=car(fdkGetProp(cellId "endCapShieldPoly"))
      )
       
      ;shieldPolyExt=car(fdkGetProp(cellId "endCapShieldPoly"))
      minPolyLength=fdkGetProp(cellId "minPolyLength")
      minDiffconLength = fdkGetProp(cellId "minDiffconLength")
      ;;diffconGrid = fdkGetProp(cellId "diffconGrid")
      ;;delta_w = 0.001n
      ;;delta_l = -2n
      
      ;;; Map lChoices as float
        (setq gt_lChoices_f gt_lChoices)
	(setq gt_wChoices_f gt_wChoices)
      
      ;; Remove leading and trailing spaces for all CDF entries first.
      (setq w buildString(parseString(cdfId->w->value) ""))
      (setq l buildString(parseString(cdfId->l->value) ""))
      (setq m buildString(parseString(cdfId->m->value) ""))
      (setq nf buildString(parseString(cdfId->nf->value) ""))
      (setq nfsub buildString(parseString(cdfId->nfsub->value) ""))
      ;(setq shieldL buildString(parseString(cdfId->shieldL->value) ""))
      (setq endcapExtT buildString(parseString(cdfId->endcapExtT->value) ""))
      (setq endcapExtB buildString(parseString(cdfId->endcapExtB->value) ""))
      (setq shieldPolyEndcapT buildString(parseString(cdfId->shieldPolyEndcapT->value) ""))
      (setq shieldPolyEndcapB buildString(parseString(cdfId->shieldPolyEndcapB->value) ""))
      (setq dcExtB buildString(parseString(cdfId->dcExtB->value) ""))
      (setq dcExtT buildString(parseString(cdfId->dcExtT->value) ""))
      
      when(fdkIsBulkEnabled(?caller cdfId) && rexMatchp("^p", cell)
           ;;printf("hello\n")
           cdfId->nwellStyle->value = cdfId->nwellStyleBulkEnabled->value
           ;;printf("hello2\n")
      )

      ;;; Fix initial input values using fdkAelEval.
      ;;; For width allow an override to fdkAel min and max checks to allow for migration with otherwise restricted W values.
     (if (boundp('fdkIgnoreMosGridW) && fdkIgnoreMosGridW)
	 then 
             (w = fdkAelEval(?entry w ?desc "Width(w)" ?aelSuffix t ?default gt_w ?noBlank t))
	 else
	     (w = fdkAelEval(?entry w ?desc "Width(w)" ?aelSuffix t ?minimum gt_wMin ?maximum gt_wMax ?default gt_w ?noBlank t))
	 
      )
      ;l = fdkAelEval(?entry l ?noVar t ?noBlank t ?default gt_lMin ?minimum gt_lMin ?maximum gt_lMax)
      ;lRangeAdjusted  = fdkAelEval(?entry cdfParseFloatString(l)-gt_lMin  ?desc "Length(l)" ?aelSuffix t ?minimum 0  ?maximum gt_lMax-gt_lMin ?default 0 ?noBlank t ?grid gt_lStep)
      ;unless(fdk_is_eq(cdfParseFloatString(l) cdfParseFloatString(lRangeAdjusted)+gt_lMin)
           ;warn("Length(l): Value half-snapped to nearest valid length; updated from %L to %L" cdfParseFloatString(l) cdfParseFloatString(lRangeAdjusted)+gt_lMin)
      ;)
      ;l = fdkAelEval(?entry cdfParseFloatString(lRangeAdjusted)+gt_lMin ?aelSuffix t)
      
      

      m  = fdkAelEval(?entry m ?desc "Multiplier(m)" ?visualFormat "%d" ?default gt_m ?noBlank t ?minimum gt_m ?maximum 2147483646 ?grid 1)
      nf = fdkAelEval(?entry nf ?desc "Number of Fingers(nf)" ?visualFormat "%d" ?default gt_nf ?noBlank t ?minimum gt_nf ?maximum 2147483646 ?grid 1)
       

      (cdfId->w->value) = w
      (cdfId->l->value) = l
      (cdfId->m->value) = m
      (cdfId->nf->value) = nf
      (cdfId->nfsub->value) = nfsub
      (cdfId->shieldPolyEndcapT->value) = shieldPolyEndcapT
      (cdfId->shieldPolyEndcapB->value) = shieldPolyEndcapB
      (cdfId->endcapExtT->value) = endcapExtT
      (cdfId->endcapExtB->value) = endcapExtB
      (cdfId->dcExtB->value) = dcExtB
      (cdfId->dcExtT->value) = dcExtT
      

      ;; Get converted parameter values from the CDF
      (setq w (cdfParseFloatString cdfId->w->value) || cdfId->w->value)
      (setq l (cdfParseFloatString cdfId->l->value))
      (setq m (fdkCdfParseIntString cdfId->m->value) || cdfId->m->value)
      (setq nf (fdkCdfParseIntString cdfId->nf->value) || cdfId->nf->value)
      (setq nfsub (fdkCdfParseIntString cdfId->nfsub->value))
      ;(setq shieldL (cdfParseFloatString cdfId->shieldL->value))
      (setq shieldPolyEndcapT (cdfId->shieldPolyEndcapT->value))
      (setq shieldPolyEndcapB (cdfId->shieldPolyEndcapB->value))
      (setq endcapExtT (cdfParseFloatString cdfId->endcapExtT->value))
      (setq endcapExtB (cdfParseFloatString cdfId->endcapExtB->value))
      (setq dcExtB (cdfParseFloatString cdfId->dcExtB->value))
      (setq dcExtT (cdfParseFloatString cdfId->dcExtT->value))

      ;;; For nf and m and w ONLY expressions containing variables are enclosed in brackets.
      (if ((stringp nf) && rexMatchp("[-+*/]" nf))
	  then (setq nf (sprintf nil "(%s)" nf))
	       (cdfId->nf->value) = nf
       )

      (if ((stringp m) && rexMatchp("[-+*/]" m))
	  then (setq m (sprintf nil "(%s)" m))
	       (cdfId->m->value) = m
       )

      (if ((stringp w) && rexMatchp("[-+*/]" w))
	  then (setq w (sprintf nil "(%s)" w))
	       (cdfId->w->value) = w
       )

      ;;; This function creates a duplicate variable with the "given_" prefix on it.
      (fdkCopyVars '(w l m nf nfsub) ?prefix 'given_)
      (mapc (lambda (sym)
              (let ((cdfval (get cdfId sym)->value)
                   cdfval_f cdfval_r)
                (setq cdfval_f (cdfParseFloatString cdfval))
                (when (floatp cdfval_f)
                  (setq cdfval_r (round cdfval_f))
                  (unless (fdk_is_eq cdfval_f cdfval_r)
                    (get cdfId sym)->value = (fdkCdfConstructValue cdfval_r)))))
            '(m nf nfsub))

      (fdkCdfDebug 2 "Parsed W/L is %L/%L\n" w l)


      ;;; Check w size - determine min/max number of fingers for this device width - if not a string (is a number)
      (if (stringp w)
	;;;then
        (progn
          (unless (fdkCdfStrHasContents 'w w gt_w)
            (setq nfsub gt_nfsub))
          )
	;;;else
        (progn
          (when (fdk_is_lt w gt_wMin)
            (artError "Width is less than minimum (%L) - adjusting to minimum (%L)\n" w gt_wMin)
            (setq w gt_wMin)
          )
          ;;; Check w > wMax
          (when (((not (boundp 'fdkUnlimitMosWf)) || fdkUnlimitMosWf == nil) && (numberp w) && (fdk_is_gt w gt_wMax))
            (artError "Width is greater than maximum (%L) - adjusting to maximum (%L)\n" w gt_wMax)
            (setq w gt_wMax)
          )
          
          ;when(wSelectDisplay         
          ;;; Check w against possible choices - added fdkIgnoreMosGridW to aid migration flow.
	  (unless (and (boundp 'fdkIgnoreMosGridW) fdkIgnoreMosGridW)
	     (unless (exists wchoice gt_wChoices_f (fdk_is_eq wchoice w))
	        (artError "Invalid width (w=%L; not in set %L) - adjusting to default (%L)\n" w gt_wChoices_f cdfId->w->defValue)
	        (setq w (cdfParseFloatString cdfId->w->defValue))
             )
          )
          ;)
          ;;; Show new W/L in debug message
          (fdkCdfDebug 2 "Validated W/L is %L/%L\n" w l)
          ;;; Check w on wGrid
          (fdkCdfDebug 3 "Determining min/max fingers for Wnm=%L wMin=%L wMax=%L addonW=%L\n"
                       w gt_wMin gt_wMax gt_wBBeak)
          (setq minFingers (fdkPcMinFingersNeededForW w gt_wMax gt_wBBeak))
          (setq maxFingers (fdkPcMaxFingersAllowedForW w gt_wMin gt_wBBeak))
          ;;; Check nfsub < minFingers
	  if(!fixp(nfsub) then
		  (fdkEmit (when layout 'artError)
			   "nfsub is not an integer. Setting to minimum %L\n"
			   minFingers)
		  (setq nfsub minFingers)
		  )
	  (when (lessp nfsub minFingers)
	    (fdkEmit (when layout 'artError)
		     "nfsub is below minimum value (%L<%L) - setting to minimum\n"
		     nfsub minFingers)
	    (setq nfsub minFingers))
          ;;; Check nfsub > maxFingers
	  (when (greaterp nfsub maxFingers)
	    (fdkEmit (when layout 'artError)
		     "nfsub is above maximum value (%L>%L) - setting to maximum\n"
		     nfsub maxFingers)
	    (setq nfsub maxFingers))

          ) ;;; w is float
        ) ;;; if is string/float

      
      ;;; Check l against possible choices
      ;when(lSelectDisplay
      (when (numberp l)
	(unless (exists lchoice gt_lChoices_f (fdk_is_eq lchoice l)) 
	  (artError "Invalid length (l=%L; not in set %L) - adjusting to default (%L)\n" l gt_lChoices_f cdfId->l->defValue)
	  (setq l (cdfParseFloatString cdfId->l->defValue))))
      ;)
      ;;; Show new W/L in debug message
      (fdkCdfDebug 2 "Validated W/L is %L/%L\n" w l)


      ;;; Check nf and m
      (if (numberp m)
	  then (fdkCdfIsPosIntValue 'm m (fdkCdfParseIntString gt_m))
       )
      (if (numberp nf)
	  then (fdkCdfIsPosIntValue 'nf nf (fdkCdfParseIntString gt_nf))
       )
   
      ;;; Correct wSelect if it is out-of-sync with w
      (fdkCdfMosWidthSelectRefresh caller)

      (when (and (stringp l) (!rexMatchp("pPar" l))) 
	(artError "Non-numeric string value not allowed for \"l\" parameter - l set to default: %L" cdfId->l->defValue)
	(setq l (cdfParseFloatString cdfId->l->defValue)))
      when(and(numberp(l) equal(gt_pitch "UR"))
           gt_pitch= gt_polySpace+l
      )
      when(and(stringp(l) equal(gt_pitch "UR"))
           (sprintf gt_pitch "(%e + %s)" gt_polySpace l)
      )
      
      ;;; Calculate params and adjust w and l to account for process variation.
       if( (and (numberp gt_pitch) (numberp l) (numberp w)) then
	(setq w_adj w)
	(setq l_adj l)
        (setq ws gt_pitch-l_adj)
        (setq wd gt_pitch-l_adj)
        (setq wi gt_pitch-l_adj)
      else
        if( stringp(w) then
	   (sprintf w_adj "(%s)" w)
	   else
	   (sprintf w_adj "(%e)" w)
	   )

	if( stringp(l) then
	   (sprintf l_adj "(%s)" l)
	   else
	   (sprintf l_adj "(%e)" l)
	   )
        if( stringp(gt_pitch) then
	   (sprintf gt_pitch_adj "(%s)" gt_pitch)
	   else
	   (sprintf gt_pitch_adj "(%e)" gt_pitch)
	   )
        (sprintf ws "(%s - %s)" gt_pitch_adj l_adj)
        (sprintf wd "(%s - %s)" gt_pitch_adj l_adj)
        (sprintf wi "(%s - %s)" gt_pitch_adj l_adj)
      )



      
    /*;cond
       ;(fdkGetProp(cellId "defaults:lSelectDisplay")
        if(nequal(fdkGetProp(cellId "gatePitch") "UR") then
           (unless (exists lchoice gt_lChoices_f (fdk_is_eq lchoice shieldL)) 
	     (artError "Invalid Shield length (l=%L; not in set %L) - adjusting to default (%L)\n" l gt_lChoices_f cdfId->shieldL->defValue)
	     (setq shieldL cdfParseFloatString(cdfId->shieldL->defValue)))
             (cdfId->shieldL->value) = fdkAelEval(?entry shieldL ?aelSuffix t)
        else
           (unless (exists lchoice gt_lChoices_f (fdk_is_eq lchoice shieldLleft)) 
	     (artError "Invalid Shield length (l=%L; not in set %L) - adjusting to default (%L)\n" l gt_lChoices_f cdfId->shieldLLeft->defValue)
	     (setq shieldLLeft cdfParseFloatString(cdfId->shieldLLeft->defValue)))
             (cdfId->shieldLLeft->value) = fdkAelEval(?entry shieldLLeft ?aelSuffix t)
           
           (unless (exists lchoice gt_lChoices_f (fdk_is_eq lchoice shieldLRight)) 
	     (artError "Invalid Shield length (l=%L; not in set %L) - adjusting to default (%L)\n" l gt_lChoices_f cdfId->shieldLRight->defValue)
	     (setq shieldLRight cdfParseFloatString(cdfId->shieldLLeft->defValue)))
             (cdfId->shieldLRight->value) = fdkAelEval(?entry shieldLRight ?aelSuffix t)
           
         
        ;(t
          ;shieldL = fdkAelEval(?entry shieldL ?noVar t ?noBlank t ?default gt_lMin )
          ;shieldLRangeAdjusted  = fdkAelEval(?entry cdfParseFloatString(shieldL)-gt_lMin  ?desc "Shield Length(l)" ?aelSuffix t ?minimum 0  ?maximum gt_lMax-gt_lMin ?default 0 ?noBlank t ?grid gt_lStep ?msgGrid t)
          ;shieldL = fdkAelEval(?entry cdfParseFloatString(shieldLRangeAdjusted)+gt_lMin ?aelSuffix t)
         ;)
      )
     */
      
      
    ;;; Check if shieldL matches gateL
    ;(when (numberp shieldL)
	  ;(unless (exists lchoice gt_lChoices_f (fdk_is_eq lchoice shieldL))
	    ;(artError "Invalid shield length (l=%L; not in set %L) - adjusting to default (%L)\n" l gt_lChoices_f cdfId->l->defValue)
	    ;(setq shieldL (cdfParseFloatString cdfId->shieldL->defValue))))

    

	 
    
    ;;; Update totalDrainEndcaps and totalSourceEndcaps based on Numfingers.  
    if(cdfId->swapSD->value 
    then 
    	when(evenp(nf)  
	      	cdfId->sharedSourceEndcaps->value = "0"
	        cdfId->totalSourceEndcaps->value =  "0"
	        cdfId->totalDrainEndcaps->value = "2")
    else
        when(evenp(nf)  
	      	cdfId->sharedDrainEndcaps->value = "0"
	        cdfId->totalDrainEndcaps->value =  "0"
	        cdfId->totalSourceEndcaps->value = "2")
    )

    when(oddp(nf)  
	  cdfId->totalSourceEndcaps->value = "1"
	  cdfId->totalDrainEndcaps->value =  "1"
    )
    
    when(stringp(nf)
              cdfId->totalSourceEndcaps->value =  "0"
              cdfId->totalDrainEndcaps->value =  "0"
    )
          

    (setq sharedDrainEndcaps (fdkCdfParseIntString cdfId->sharedDrainEndcaps->value))
    (setq sharedSourceEndcaps (fdkCdfParseIntString cdfId->sharedSourceEndcaps->value))
    (setq totalDrainEndcaps  (fdkCdfParseIntString cdfId->totalDrainEndcaps->value))
    (setq totalSourceEndcaps (fdkCdfParseIntString cdfId->totalSourceEndcaps->value))
        
      
   ;;; Syntax checks no decimals or alpha characters allow only interger values within range
   (when (or floatp(cdfId->sharedDrainEndcaps->value) rexMatchp("[-._aA-zZ]" cdfId->sharedDrainEndcaps->value) cdfId->sharedDrainEndcaps->value == ""
	     !rexMatchp("^[0-9]+$" cdfId->sharedDrainEndcaps->value))
     (artError "sharedDrainEndcaps value (%L) is not allowed - switching to default.\n" cdfId->sharedDrainEndcaps->value)
     (cdfId->sharedDrainEndcaps->value = "0")
     sharedDrainEndcaps = 0)


   (when (or floatp(cdfId->sharedSourceEndcaps->value) rexMatchp("[-._aA-zZ]" cdfId->sharedSourceEndcaps->value) cdfId->sharedSourceEndcaps->value == ""
	     !rexMatchp("^[0-9]+$" cdfId->sharedSourceEndcaps->value))
     (artError "sharedSourceEndcaps value (%L) is not allowed - switching to default.\n" cdfId->sharedSourceEndcaps->value)
     (cdfId->sharedSourceEndcaps->value = "0") 
     sharedSourceEndcaps = 0)
	  
	    
   (when (greaterp sharedSourceEndcaps totalSourceEndcaps)
     (artError "sharedSourceEndcaps value (%L) cannot be greater than totalSourceEndcaps. Assigning totalSourceEndcaps value.\n" cdfId->sharedSourceEndcaps->value)
     (cdfId->sharedSourceEndcaps->value = cdfId->totalSourceEndcaps->value )  
     sharedSourceEndcaps =   totalSourceEndcaps)

   (when (greaterp sharedDrainEndcaps totalDrainEndcaps)
     (artError "sharedDrainEndcaps value (%L) cannot be greater than totalDrainEndcaps. Assigning totalDrainEndcaps value.\n" cdfId->sharedDrainEndcaps->value)
     (cdfId->sharedDrainEndcaps->value = cdfId->totalDrainEndcaps->value ) 
     sharedDrainEndcaps =  totalDrainEndcaps)   
   
 
   ;;; Calculate as/ad/ps/pd and simulation values
   (setq simValues (fdkCdfCalcSimValues ?w w_adj
					?nf nf
					?ws ws
					?wd wd
					?wi wi				   
					?sharedSourceEndcaps sharedSourceEndcaps
					?sharedDrainEndcaps sharedDrainEndcaps
                                        ?swapSD cdfId->swapSD->value 
					))
      
   when( rexMatchp( "^[np]sr" cell)
		  cdfId->swapSD->value = nil
		  ;cdfId->swapSD->editable = nil
       )
 
   ;(when cdfId->swapSD->value
    ; _tmp_var = simValues['as]
     ;simValues['as] = simValues['ad]
     ;simValues['ad] = _tmp_var
     ;_tmp_var = simValues['ps]
     ;simValues['ps] = simValues['pd]
     ;simValues['pd] = _tmp_var    
   ;)

   ;;; Write back simulation parameters as-is
   (mapc (lambda (sym)
	   (let ((value simValues[sym]))
	     (get cdfId sym)->value = (if (stringp value) value (sprintf nil "%L" value))))
	 '(as ad ps pd pes ped))

   ;;; Calculate pes and ped - (nf_even=>pes=2*(w_adj/w*nf),ped=0) && (nf_odd=>pes=ped=w_adj/w*nf)
   ;;; check_even = 1-(nf -2*(nf/2)) - check_even = 1 if nf even - check_even = 0 if nf odd.
   ;;; pes = (check_even+1-sharedSourceEndcaps)*(w_adj/nf)
   ;;; ped = (1-check_even -(sharedDrainEndcaps*(1-check_even)))*(w_adj/nf)
   ;;; ped = ((1-check_even)*(1-sharedDrainEndcaps))*(w_adj/nf)
   ;;; Averaging has been nullified - w_adj/nf --> w_adj.
   ;check_even = (if (numberp nf)
		   ;(1-(nf - 2 *(nf/2)))
		   ;(sprintf nil "1-((%s)-2*((%s)/2))" cdfId->nf->value cdfId->nf->value))

   ;cdfId->pes->value = (if (and (numberp w_adj) (numberp nf) (numberp check_even) (numberp sharedSourceEndcaps))
			  ;(sprintf nil "%L" (check_even+1-sharedSourceEndcaps)*w_adj)
			  ;(sprintf nil "((%s)+1-(%s))*(%s)" fdkCdfConstructValue(check_even) fdkCdfConstructValue(sharedSourceEndcaps) fdkCdfConstructValue(w_adj)))

   ;cdfId->ped->value = (if (and (numberp w_adj) (numberp nf) (numberp check_even) (numberp sharedDrainEndcaps))
			  ;(sprintf nil "%L" ((1-check_even)*(1-sharedDrainEndcaps)*w_adj))
			  ;(sprintf nil "((1-(%s))*(1-(%s))*(%s))" fdkCdfConstructValue(check_even) fdkCdfConstructValue(sharedDrainEndcaps) fdkCdfConstructValue(w_adj)))
   
   ;;; Swap pes and ped when SwapSD.
   ;(when cdfId->swapSD->value
    ; _tmp_var = cdfId->pes->value
     ;cdfId->pes->value = cdfId->ped->value
     ;cdfId->ped->value = _tmp_var
    ;)
   ;;printf("INFO: pes is %L\n" cdfId->pes->value)
   ;;printf("INFO: ped is %L\n" cdfId->ped->value)
   ;;printf("INFO: w_adj is %L\n" fdkCdfConstructValue(w_adj))
   ;;printf("INFO: l_adj is %L\n" fdkCdfConstructValue(l_adj))
   ;;printf("INFO: delta_w is %L\n" fdkCdfConstructValue(delta_w))
   ;;printf("INFO: delta_l is %L\n" fdkCdfConstructValue(delta_l))
   ;;printf("INFO: as is %L\n" cdfId->as->value)
   ;;printf("INFO: ad is %L\n" cdfId->ad->value)
   ;;printf("INFO: ps is %L\n" cdfId->ps->value)
   ;;printf("INFO: pd is %L\n" cdfId->pd->value)
   
   ;;; Write validated variables back to the CDF (only if they changed)
   (mapc (lambda (sym)
	   (let ((curval (symeval sym))
		 (givval (symeval (concat 'given_ sym)))
		 newval)
	     (when (nequal curval givval)
	       (setq newval (fdkCdfConstructValue curval))
	       (fdkCdfDebug 5 "Setting CDF parameter: %L=%L\n" sym newval)
	       (get cdfId sym)->value = newval)))
	 '(w l m nf nfsub))
	  
	  
   ;;; Set effective multiplier (meff=m*nf)
   cdfId->meff->value = (if (and (numberp m) (numberp nf))
			    (sprintf nil "%d" m*nf)
			  (sprintf nil "%s*%s" cdfId->m->value cdfId->nf->value))
      
   ;;; Set effective width (weff=w*nf)
   cdfId->weff->value = (if (and (numberp w) (numberp nf))
			    (aelSuffixNotation w*nf 12)
			    (sprintf nil "%s*%s" cdfId->w->value cdfId->nf->value))

   
    if(nequal(cdfId->leftAbut->value "noAbut") then
             printf("Warning: Shield is not allowed on abutted side.Reset to 'none'\n")
             cdfId->leftShield->value = "none"
    )
    if(nequal(cdfId->rightAbut->value  "noAbut") then
             printf("Warning: Shield is not allowed on abutted side.Reset to 'none'\n")
             cdfId->rightShield->value = "none"
    )

       
    ;; calculating endCap
    if(whichparam == "w" || whichparam == "nfsub" || whichparam == "width" then
        endcapExtT = polyExt
        endcapExtB = polyExt
	if((numberp w) then
           
	   if(fdkCmp(((w/nfsub)+endcapExtT+endcapExtB) "<" minPolyLength) then
		    endcapExtT = (minPolyLength-(w/nfsub))/2.0 
		    endcapExtB = endcapExtT
            )
	    
	)
        cdfId->endcapExtT->value =  fdkCdfConstructValue(endcapExtT)
        cdfId->endcapExtB->value =  fdkCdfConstructValue(endcapExtB)
    )
    ;; calculating shieldPolyEndCap
    if(whichparam == "w" || whichparam == "nfsub" || whichparam == "width" then
        shieldPolyEndcapT= shieldPolyExt
        shieldPolyEndcapB= shieldPolyExt
	if((numberp w) then
	   if(fdkCmp(((w/nfsub)+shieldPolyEndcapT+shieldPolyEndcapB) "<" minPolyLength) then
		    shieldPolyEndcapT = (minPolyLength-(w/nfsub))/2.0 
		    shieldPolyEndcapB = shieldPolyEndcapT
            )
	)
        cdfId->shieldPolyEndcapT->value =  fdkCdfConstructValue(shieldPolyEndcapT)
        cdfId->shieldPolyEndcapB->value =  fdkCdfConstructValue(shieldPolyEndcapB)
        
    )


    ;;; Revise diffcon extensions if w, width or nfsub changed-- use min value (defDiffconExt) unless below min length
    if(whichparam == "w" || whichparam == "nfsub" || whichparam == "width" then
        dcExtT = diffconExt
        dcExtB = diffconExt
	if((numberp w) then
	   if(fdkCmp(((w/nfsub)+dcExtT+dcExtB) "<" minDiffconLength) then
		    dcExtT = (minDiffconLength-(w/nfsub))/2.0 
		    dcExtB = dcExtT 
            )
	)
        cdfId->dcExtT->value =  fdkCdfConstructValue(dcExtT)
        cdfId->dcExtB->value =  fdkCdfConstructValue(dcExtB)
    )
   isoNested =  cdfId->isoNested->value

  cond(
        (isoNested=="default"
         fdkSetIsoNestedDefValues(cdfId)
         )
        (isoNested=="user-defined"
         fdkMosUserDefIsoNested(cdfId)
         )
   )

   ;;; Swap sharedSourceEndcaps and sharedDrainEndcaps when SwapSD - their use in other equations are done by this time.
   ;;; (when cdfId->swapSD->value
   ;;; _tmp_var = cdfId->sharedSourceEndcaps->value
   ;;; cdfId->sharedSourceEndcaps->value = cdfId->sharedDrainEndcaps->value
   ;;; cdfId->sharedDrainEndcaps->value = _tmp_var
   ;;; )

   ) ;;; let
    ) ;;; let
  ) ;;; defun


(defun fdkCdfLengthSelectCB (@optional caller)
  (fdkCdfDebug 1 ">>>>> Entering fdkCdfLengthSelectCB <<<<<\n")
  (let ((cdfId (or caller cdfgData)))
    (unless (equal cdfId->lSelect->value "other")
      cdfId->l->value = cdfId->lSelect->value
      (fdkCdfMosCB caller))))

(defun fdkCdfWidthSelectCB (@optional caller)
  (fdkCdfDebug 1 ">>>>> Entering fdkCdfWidthSelectCB <<<<<\n")
  (let ((cdfId (or caller cdfgData)))
    (unless (equal cdfId->wSelect->value "other")
      cdfId->w->value = cdfId->wSelect->value
      (fdkCdfMosCB caller "w"))))

(defun fdkCdfWidthCB (@optional caller)
  (fdkCdfDebug 1 ">>>>> Entering fdkCdfWidthCB <<<<<\n")
  (let ()
      (fdkCdfMosCB caller "width")))

(defun fdkCdfNfsubCB (@optional caller)
  (fdkCdfDebug 1 ">>>>> Entering fdkCdfNfsubCB <<<<<\n")
  (let ()
      (fdkCdfMosCB caller "nfsub")))



(defun fdkCdfMosWidthSelectRefresh (@optional caller)
  (let ((cdfId (or caller cdfgData)))
    (when (nequal cdfId->w->value cdfId->wSelect->value)
      (fdkCdfDebug 2 "w and wSelect values do not agree (%L != %L) - correcting wSelect...\n"
		   cdfId->w->value cdfId->wSelect->value)
      (if (member cdfId->w->value cdfId->wSelect->choices)
	cdfId->wSelect->value = cdfId->w->value  ;; on the list, choose it
	cdfId->wSelect->value = "other"))))      ;; not on the list

procedure( fdkSetIntegerUpOnGrid( int )
    prog( (cvId tfId ogUpInt compFactor grid)
        cvId = geGetEditCellView()
        tfId = techGetTechFile(cvId)
        compFactor = 1 / 10000 
        grid = techGetParam(tfId "mfgGrid")
        ogUpInt = floor((int + compFactor) / grid) * grid
           return(ogUpInt)))

procedure( fdkSetIntegerDownOnGrid( int )
    prog( (cvId tfId ogDownInt compFactor grid)
        cvId = geGetEditCellView()
        tfId = techGetTechFile(cvId)
        compFactor = 1 / 10000 
        grid = techGetParam(tfId "mfgGrid")
        ogDownInt = ceiling((int + compFactor) / grid) * grid
           return(ogDownInt)))      

;; Gate edges are included in perimeter in the model
;;
;;     EXAMPLE - ODD NUMBER OF GATES (nf=3)
;;                   
;;     +-----+             +-----+             +-----+             +-----+             +-----+
;;     |  |  |             |  |  |             |  |  |             |  |  |             |  |  |
;;     |  +--+-------------+--+--+-------------+--+--+-------------+--+--+-------------+--+  |  ---
;;     |  |  |             |  |  |             |  |  |             |  |  |             |  |  |   ^
;;     |  |  |  SOURCE     |  |  |   DRAIN     |  |  |   SOURCE    |  |  |    DRAIN    |  |  |   |
;;     |  |  |             |  |  |             |  |  |             |  |  |             |  |  |   
;;     |  |  |<--- ws ---->|  |  |<--- wi ---->|  |  |<--- wi ---->|  |  |<---- wd --->|  |  |   w
;;     |  |  |             |  |  |             |  |  |             |  |  |             |  |  |
;;     |  |  |             |  |  |             |  |  |             |  |  |             |  |  |   |
;;     |  |  |             |  |  |             |  |  |             |  |  |             |  |  |   V
;;     |  +--+-------------|--+--+-------------+--+--+-------------+--+--+-------------+--+  |  ---
;;     |  |  |             |  |  |             |  |  |             |  |  |             |  |  | 
;;     +-----+             +-----+             +-----+             +-----+             +-----+
;;
(defun fdkCdfCalcSimValues (@key w ws wd wi nf sharedSourceEndcaps sharedDrainEndcaps swapSD)
  (let ((table (makeTable "" nil))
        (missing_args (setof sym '(w ws wd wi nf sharedSourceEndcaps sharedDrainEndcaps) (not (symeval sym))))
        odd
        ns nse nsi nd nde ndi wse wde wsi wdi as ad ps pd ped pes 
        wse_s wde_s wsi_s wdi_s
        w_s  
	sde sse nsh ndh
        nf_dummy nf_s _tmp_var)

    ;; Flag an error if a required argument is missing
    (when missing_args
      (error "Missing required argument(s): %L\n" missing_args))

    (setq wse ws)
    (setq wde wd)
    (setq wsi wi)
    (setq wdi wi)
    (setq sde sharedDrainEndcaps)
    (setq sse sharedSourceEndcaps)

    ;; Get a string representation of nf
    (setq nf_s (if (stringp nf) nf (sprintf nil "%d" nf)))

    ;; Get a string representation of floating point numbers (w ws wd wi)
    ;; if they are not already a string.  Store in a variable with a "_s"
    ;; suffix.
    (fdkSetVars
     (lambda (var value)
       (cond
        ((stringp value) value)
        ((numberp value) (sprintf nil "%g" (float value)))
        (t
         (error "Invalid type given for %L: %L (expecting string or float)\n" var value))))
     '(w ws wse wde wsi wdi) ?suffix '_s)

    ;; Set value to determine if this is an odd number of fingers or not.  This
    ;; uses integer division behavior in lieu of a % modulo division operator.
    ;; For example: 2/2=1 and 3/2=1.
    (sprintf odd "(%s-2*int(%s/2))" nf_s nf_s)

    ;; Set expression to determine the number of source and drain regions
    ;; (ns and nd respectively).
    (sprintf ns "((%s/2)+1)" nf_s)   ;; nf % 2
    (sprintf nd "((%s+1)/2)" nf_s)

    ;; Set expression to determine the number of source and drain external
    ;; regions (nse and nde respectively).
    (sprintf nse "(2-%s)" odd)  ;; nse=1 when odd and nse=2 when even
    (sprintf nde odd)           ;; nde=1 when odd and nde=0 when even
    when(swapSD
       _tmp_var = nse
       nse = nde
       nde = _tmp_var
       _tmp_var = ns
       ns = nd
       nd = _tmp_var
    ) 
    ;; Set expression to determine the number of source and drain internal
    ;; regions (nsi and ndi respectively).
    (sprintf nsi "int(%s-%s)" ns nse)
    (sprintf ndi "int(%s-%s)" nd nde)
  
    ;; Add a function to modify nse and nde here, which affects - as ad ps pd.
    ;; Using nsh and ndh which represent HALF an internal region   
    (sprintf ndh "0")
    (sprintf nsh "0")         
    when( sse==1 	      
	  when(oddp(nf) 	          
		   (sprintf nsi "(%s-1)" ns)
		   (sprintf nse "0" )
		   (sprintf nsh "1" ) 
          )   
	  when(!oddp(nf)  
		    (sprintf nsi "(%s-%s)" ns nse)
		    (sprintf nse "(1-%s)" odd)  
		    (sprintf nsh "1" )  
	  )
     )		               
    when( sde==1 
          when(oddp(nf)     
	    (sprintf ndi "(%s-1)" nd)
	    (sprintf nde "0" )  
	    (sprintf ndh "1" )
	    )
	  when(!oddp(nf)
	    (sprintf ndi "(%s-%s)" nd nde)
	    (sprintf nde "(1-%s)" odd)  
            (sprintf ndh "1" )  
           )
    )
    when( sse==2  
	     (sprintf nse "0" )
             (sprintf nsi "(%s-1)" ns)
    )
    when( sde==2  
	     (sprintf nde "0" )
             (sprintf ndi "(%s-1)" nd)
    )

    ;; Print some debugging messages
    (mapc (lambda (sym)
            (fdkCdfDebug 5 "Intermediate value: %L = %L\n" sym (symeval sym)))
          '(ns nsi nse nd ndi nde))

    ;; Calculate area (as/ad)
    ;; The area calculation is the sum of all internal diffusion segment length
    ;; parameters (wsi/wdi) and external parameters (wse/wde) multiplied by the
    ;; device channel width.
    ;; Added HALF internal region
    ;; a = ne*(we*w) + ni*(wi*w) + nxh*(wi*w)/2
    ;; as = ((nse * wse_s * w_s)+(nsi * wsi_s * w_s)+(nsh * wdi_s * w_s/2))
    ;; ad = ((nde * wde_s * w_s)+(ndi * wdi_s * w_s)+(ndh * wdi_s * w_s/2))

    (let ((expr "((%s*%s*%s)+(%s*%s*%s)+(%s*%s*%s/2))"))
       (if (and !rexMatchp("[aA-zZ]" nse) !rexMatchp("[aA-zZ]" nsi) !rexMatchp("[aA-zZ]" nsh) !rexMatchp("[aA-zZ]" nde) !rexMatchp("[aA-zZ]" ndi) !rexMatchp("[aA-zZ]" ndh))
	   then (nse = evalstring(nse))
	        (sprintf nse "%L" nse)
	        (nsi = evalstring(nsi))
		(sprintf nsi "%L" nsi)
		(nsh = evalstring(nsh))
		(sprintf nsh "%L" nsh)
		(nde = evalstring(nde))
		(sprintf nde "%L" nde)
		(ndi = evalstring(ndi))
		(sprintf ndi "%L" ndi)
		(ndh = evalstring(ndh))
		(sprintf ndh "%L" ndh)
	        (sprintf as expr nse wse_s w_s nsi wsi_s w_s nsh wdi_s w_s)
	        (sprintf ad expr nde wde_s w_s ndi wdi_s w_s ndh wdi_s w_s) 
	   else (sprintf as expr nse wse_s w_s nsi wsi_s w_s nsh wdi_s w_s)
	        (sprintf ad expr nde wde_s w_s ndi wdi_s w_s ndh wdi_s w_s)
       )
     )

    ;; Calculate periphery (ps/pd)
    ;; The periphery calculation is the sum of all diffusion edges excluding
    ;; the gate edge.  
    ;; Added HALF internal region
    ;; p = ne*(w+2*we) + ni*(2*wi) + (nxh*wi)  --> p = ne*(2*we) + ni*(2*wi) + (nxh*wi)
    ;; ps = ((nse * (2 * wse_s)) + (nsi * (2 * wsi_s)) + (nsh * wsi_s))
    ;; pd = ((nde * (2 * wde_s)) + (ndi * (2 * wdi_s)) + (ndh * wsi_s))

    (let ((expr "((%s*(2*%s))+(%s*(2*%s))+(%s*%s))"))
      (if (and !rexMatchp("[aA-zZ]" nse) !rexMatchp("[aA-zZ]" nsi) !rexMatchp("[aA-zZ]" nsh) !rexMatchp("[aA-zZ]" nde) !rexMatchp("[aA-zZ]" ndi) !rexMatchp("[aA-zZ]" ndh))
	  then (nse = evalstring(nse))
	       (sprintf nse "%L" nse)
	       (nsi = evalstring(nsi))
	       (sprintf nsi "%L" nsi)
	       (nsh = evalstring(nsh))
	       (sprintf nsh "%L" nsh)
	       (nde = evalstring(nde))
	       (sprintf nde "%L" nde)
	       (ndi = evalstring(ndi))
	       (sprintf ndi "%L" ndi)
	       (ndh = evalstring(ndh))
	       (sprintf ndh "%L" ndh)
	       (sprintf ps expr nse wse_s nsi wsi_s nsh wsi_s)
	       (sprintf pd expr nde wde_s ndi wdi_s ndh wsi_s)
	  else (sprintf ps expr nse wse_s nsi wsi_s nsh wsi_s)
	       (sprintf pd expr nde wde_s ndi wdi_s ndh wsi_s)
      )
    )
    ;; Calculate periphery (pes/ped)
    ;; The periphery calculation is the sum of all the external PGD diffusion edges 
    ;; Added HALF internal region
    ;; p = ne*(w) 
    ;; ps = (nse * w_s)
    ;; pd = (nde * w_s)

    (let ((expr "(%s*%s)"))
      (if (and !rexMatchp("[aA-zZ]" nse)  !rexMatchp("[aA-zZ]" nde) )
	  then (nse = evalstring(nse))
	       (sprintf nse "%L" nse)	       
	       (nde = evalstring(nde))
	       (sprintf nde "%L" nde)	       
	       (sprintf pes expr nse w_s)
	       (sprintf ped expr nde w_s)
	  else (sprintf pes expr nse w_s)
	       (sprintf ped expr nde w_s)
      )
    )
    
    ;; Average as/ad/ps/pd to be per finger.  Also evaluate the string if all
    ;; components are numbers (not string variables).  Also put the result
    ;; into a table using the original name (as/ad/ps/pd).
    ;; Create a dummy nf for this average.
    ;; If averaging is needed later set or replace nf_dummy to nf_s.

    (setq nf_dummy "1")
    (fdkSetVars
     (lambda (var value)
       (let (calcval)
         (fdkCdfDebug 5 "%L pre-calc (total) : %L\n" var value)
         (setq calcval 
               (if (and (numberp w)
                        (numberp ws)
                        (numberp wd)
                        (numberp wi)
                        (numberp nf))
                 (evalstring (sprintf nil "%s/%s" value nf_dummy))
                 (sprintf nil "%s/%s" value nf_dummy)))
         (fdkCdfDebug 5 "%L calc (per finger): %L\n" var calcval)
         table[var] = calcval))
     '(as ad ps pd pes ped)
     ?prefix 'avg_)

    table))



procedure( fdkIsoNestDisp(@optional caller)
        let(
             ((cdfId (or caller cdfgData)))

           let(
               ()
               (!(fdkIsLayout() || (cdfId->isoNested->value != "user-defined")))
           )
        )
)

procedure( fdkShieldPolyDisplay(side @optional caller)
        let(
             ((cdfId (or caller cdfgData)))

           let(
               (paramId)
               paramId = cdfFindParamByName(cdfId sprintf(nil "%sShield" side))
               fdkIsLayout() && (paramId->value != "none")
           )
        )
)

procedure( fdkSetIsoNestedDefValues(@optional caller)
           let(((cdfId (caller||cdfgData)))
               let((nf nfInt isoNested sharedS sharedD sharedSD sharedSorD swapS swapD)

               nf = cdfId->nf->value
               nfInt = fdkCdfParseIntString(nf)
               isoNested =  cdfId->isoNested->value
               sharedS = fdkCdfParseIntString(cdfId->sharedSourceEndcaps->value)
               sharedD= fdkCdfParseIntString(cdfId->sharedDrainEndcaps->value)
               if(cdfId->swapSD->value
               then
                   swapS=1
                   swapD=0
               else
                   swapD=1
                   swapS=0
               )
               if((sharedS==1 && sharedD==1)
               then
                   sharedSD=1
               else
                   sharedSD=0
               )
               if((sharedS==1 || sharedD==1)
               then
                   sharedSorD=1
               else
                   sharedSorD=0
               )
                        cond(
                             (stringp(nfInt)
                              cdfId->sndn->value=""
                              cdfId->sidi->value=""
                              cdfId->sndi->value=""
                              cdfId->sidn->value=""
                              )
                             (nfInt==1
                              cdfId->sndn->value=sprintf(nil "%d" sharedSD)
                              cdfId->sidi->value=sprintf(nil "%d" nfInt-sharedSorD)
                              cdfId->sndi->value=sprintf(nil "%d" sharedS-sharedSD)
                              cdfId->sidn->value=sprintf(nil "%d" sharedD-sharedSD)

                              )
                              (evenp(nfInt)
                              cdfId->sndn->value=sprintf(nil "%d" nfInt+sharedS+sharedD-2)
                              cdfId->sidi->value="0"
                              cdfId->sndi->value=sprintf(nil "%d" swapS*2-sharedD)
                              cdfId->sidn->value=sprintf(nil "%d" swapD*2-sharedS)


                              )
                              (oddp(nfInt)
                              cdfId->sndn->value=sprintf(nil "%d" nfInt+sharedS+sharedD-2)
                              cdfId->sidi->value="0"
                              cdfId->sndi->value=sprintf(nil "%d" 1-sharedD)
                              cdfId->sidn->value=sprintf(nil "%d" 1-sharedS)


                              )
                        )
                        cond(
                             (isoNested=="default"
                                if(sharedS == 0 && sharedD ==0
                                then
                                   cdfId->sndnEff->value=""
                                   cdfId->sidiEff->value=""
                                   cdfId->sndiEff->value=""
                                   cdfId->sidnEff->value=""
                                   cdfId->iNSumCheck->value= ""
                                else
                                   cdfId->sndnEff->value=sprintf(nil "%d*iPar(\"w\")" fdkCdfParseIntString(cdfId->sndn->value))
                                   cdfId->sidiEff->value=sprintf(nil "%d*iPar(\"w\")" fdkCdfParseIntString(cdfId->sidi->value))
                                   cdfId->sndiEff->value=sprintf(nil "%d*iPar(\"w\")" fdkCdfParseIntString(cdfId->sndi->value))
                                   cdfId->sidnEff->value=sprintf(nil "%d*iPar(\"w\")" fdkCdfParseIntString(cdfId->sidn->value))
                                   cdfId->iNSumCheck->value= ""
                               )
                             )
                             (isoNested=="nested"
                                cdfId->sndn->value=sprintf(nil "iPar(\"nf\")")
                                cdfId->sidi->value=""
                                cdfId->sndi->value=""
                                cdfId->sidn->value=""
                                cdfId->sndnEff->value=sprintf(nil "iPar(\"weff\")")
                                cdfId->sidiEff->value=""
                                cdfId->sndiEff->value=""
                                cdfId->sidnEff->value=""
                                cdfId->iNSumCheck->value= ""

                             )
                             (isoNested=="user-defined"
                                if(stringp(nfInt)
                                then
                                   cdfId->sndnEff->value=""
                                   cdfId->sidiEff->value=""
                                   cdfId->sndiEff->value=""
                                   cdfId->sidnEff->value=""
                                   cdfId->iNSumCheck->value= "Not applicable"
                                else
                                   cdfId->sndnEff->value=sprintf(nil "%d*iPar(\"w\")" fdkCdfParseIntString(cdfId->sndn->value))
                                   cdfId->sidiEff->value=sprintf(nil "%d*iPar(\"w\")" fdkCdfParseIntString(cdfId->sidi->value))
                                   cdfId->sndiEff->value=sprintf(nil "%d*iPar(\"w\")" fdkCdfParseIntString(cdfId->sndi->value))
                                   cdfId->sidnEff->value=sprintf(nil "%d*iPar(\"w\")" fdkCdfParseIntString(cdfId->sidn->value))
                                   cdfId->iNSumCheck->value= "yes"
                                )
                             )
                        )

            )
     )
)


procedure( fdkMosUserDefIsoNested(@optional caller)
           let(
             ((cdfId (or caller cdfgData)))
           let((nf isoNested sndn sidi sndi sidn)
                  isoNested =  cdfId->isoNested->value
                   nf =  fdkCdfParseIntString(cdfId->nf->value)


                   if(isoNested == "user-defined"
                   then
                          sndn = updateS_D_Param("sndn" cdfId)
                          sidi = updateS_D_Param("sidi" cdfId)
                          sndi = updateS_D_Param("sndi" cdfId)
                          sidn = updateS_D_Param("sidn" cdfId)
                          if(sndn =="" sndn=0)
                          if(sidi =="" sidi=0)
                          if(sndi =="" sndi=0)
                          if(sidn =="" sidn=0)
                          if(numberp(nf) && numberp(sndn) && numberp(sidi) && numberp(sndi) && numberp(sidn) 
                          then
                                if((nf==sndn+sidi+sndi+sidn)
                                then
                                        cdfId->iNSumCheck->value= "yes"
                                else
                                        cdfId->iNSumCheck->value= "no"
                                )
                        else

                                cdfId->iNSumCheck->value="Not applicable"
                        )
                )


        )
     )
 )


procedure(updateS_D_Param(sdstr @optional caller)
        let(
             ((cdfId (or caller cdfgData)))
             let(((cell (case cdfId->type
                  ("cellData" cdfId->id->name)
                  ("instData" cdfId->id->cellName)
                  (t (warn "Cannot determine cell name from CDF type: %L\n" cdfId->type))))
                (lib (case cdfId->type
                  ("cellData" cdfId->id->lib->name)
                  ("instData" cdfId->id->libName)
                  (t (warn "Cannot determine lib name from CDF type: %L\n" cdfId->type))))
                  sd sdEff sdId sdEffId sdvalue sdValueConstruct cellId maxNf)
                    cellId = ddGetObj(lib cell)
                    maxNf = (fdkGetProp cellId "defaults:nfMax")
                    sd = sprintf(nil "%s" sdstr)
                    sdEff=sprintf(nil "%sEff" sdstr)
                    sdId = cdfFindParamByName(cdfId sd)
                    sdEffId = cdfFindParamByName(cdfId sdEff)

                    sdId->value= fdkAelEval(?entry sdId->value  ?desc sdstr ?default "0"   ?minimum "0" ?maximum maxNf)
                    sdvalue = cdfParseFloatString(sdId->value)
                    cond(
                         (numberp(sdvalue)
                              sdValueConstruct=sprintf(nil "%g" sdvalue)
                         )
                         (t
                              sdValueConstruct=sprintf(nil "%s" sdvalue)
                         )
                    )
                    sdId->value=sdValueConstruct
                    cond(
                         (sdvalue==""
                          sdEffId->value=""
                          )
                         (t
                          sdEffId->value=sprintf(nil "%s*iPar(\"w\")" sdValueConstruct)
                          )
                    )
        sdvalue
            )
         )
)

procedure(fdkIsBulkEnabled(@key (propTable nil) (caller nil))
      let( 
            ((cdfId (or caller cdfgData)))
             let(((cell (case cdfId->type
                  ("cellData" cdfId->id->name)
                  ("instData" cdfId->id->cellName)
                  (t (warn "Cannot determine cell name from CDF type: %L\n" cdfId->type))))
                (lib (case cdfId->type
                  ("cellData" cdfId->id->lib->name)
                  ("instData" cdfId->id->libName)
                  (t (warn "Cannot determine lib name from CDF type: %L\n" cdfId->type))))
                  libPropTable)
             libId = ddGetObj(lib)
             libPropTable= fdkGetPropTable(libId)

             unless(propTable
                  propTable= fdkGetPropTable(ddGetObj(lib cell))
             )
             cond(
                     (propTable["bulkEnabled"]!='unbound && propTable["bulkEnabled"]!=""
                          propTable["bulkEnabled"]
                      )
                      ((propTable["bulkEnabled"]=='unbound || propTable["bulkEnabled"]!="") && libPropTable["bulkEnabled"]!='unbound
                          propTable["bulkEnabled"]= libPropTable["bulkEnabled"]
                       )
                      (t
                         bulkEnabledEnvVar= getShellEnvVar("FDK_BULK_ENABLED")
                         if(bulkEnabledEnvVar && bulkEnabledEnvVar=="TRUE" then
                            propTable["bulkEnabled"]= t
                         else
                            propTable["bulkEnabled"]= nil
                         )
                      )
             )
             propTable["bulkEnabled"]
         
       )
    )
)
                       
                      
                  
         


           
        
