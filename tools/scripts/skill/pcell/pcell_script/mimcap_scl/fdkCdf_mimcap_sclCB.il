;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Intel Top Secret                                                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copyright (C) 2014 Intel Corporation.  All rights reserved.             ;;
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

putd( 'fdkCdf_mimcap_sclCB nil )
procedure(

  fdkCdf_mimcap_sclCB(lib cell cdfId @key (stacked nil))

let((
    celldd Aeff Aholes Area Cest Crmimcap L1scale L2L3scale MIMgap Rest Rmimcap
    _snap drTable l1 l2 l3 ldmax ldmin ldrawn lh lmodel m maxViaOffsetL
    maxViaOffsetR mfgGrid minViaOffsetL minViaOffsetR mmax mmin
    modelLimit nh tfId um_ovlp um_space viaLength viaOffsetL
    viaOffsetR viaType viaWidth w wh wmax wmin value defValue prompt 
    mimMinWidth mimSpaceVia mimViaOffset
  ); let variables

  fdkCdfDebug(3 ">> ENTERING fdkCdf_mimcap_sclCB <<\n")

  aelPushSignifDigits(12) ;use 12 digits of precision (default is %.8g)

  ;;Get all cdf defaults and property bag values (assume PB/default are real numbers)
  celldd         = ddGetObj(lib cell)
  tfId           = techGetTechFile(celldd)
  mfgGrid        = techGetMfgGridResolution(tfId)*1u
  _snap          = lambda((x mn mx) cond( ( x <= mn mn ) ( x >= mx mx ) ( t fdkSnapGrid(mfgGrid x) ) ))
  drTable        = fdkGetPropTable(celldd ?name "designRules")
  Crmimcap       = (1f/1p)*drTable["Crmimcap"]; make it F/m (In PB is fF/u^2)
  Rmimcap        = drTable["Rmimcap"]
  L1scale        = drTable["L1scale"]
  L2L3scale      = drTable["L2L3scale"]
  mimViaOffset   = drTable["MIMSpaceVia"]*1u
  um_ovlp        = drTable["upperMetal"]["overlap"]*1u
  um_space       = drTable["upperMetal"]["space"]*1u
  mimMinWidth    = drTable["MIMMinWidth"]*1u
  mimSpaceVia    = drTable["MIMSpaceVia"]*1u
  modelLimit     = drTable["modelLimit"]

; ;; Check if user input values are numbers only.
; (setq m               (fdkCdfParseIntString cdfId->m->value))
; (setq w               (cdfParseFloatString cdfId->w->value))
; (setq ldrawn          (cdfParseFloatString cdfId->ldrawn->value))
; (setq viaOffsetL      (cdfParseFloatString cdfId->viaOffsetL->value))
; (setq viaOffsetR      (cdfParseFloatString cdfId->viaOffsetR->value))
; (foreach param '(m w ldrawn viaOffsetL viaOffsetR)
;      value    = (eval param)
;      defValue = (get cdfId param)->defValue
;      prompt   = (get cdfId param)->prompt
;      (unless (numberp value)
;         (artWarn "%L value (%L) is not allowed - adjusting to default (%L)\n" prompt value defValue)
;         (set param defValue)))

  ;; parameter value evaluation and boundary check
  m    = cdfId->m->value
  mmin = drTable["mmin"]
  mmax = drTable["mmax"]
  m    = fdkAelEval(
		?entry		(sprintf nil "%s" m)
		?visualFormat	"%d"		; force integer
		?aelSuffix	t		; allow MKS units
		?noVar		t		; don't allow variables, only scalar
		?minimum	mmin
		?maximum	mmax
		?default	cdfId->m->defValue
  )
  when( stringp(m) && (m != cdfId->m->value) cdfId->m->value = m )
  m = atoi(m)

  w    = cdfId->w->value
  wmin = cdfParseFloatString(cdfId->w->defValue)
  wmax = drTable["wmax"]*1u
  w = fdkAelEval(
		?entry		(sprintf nil "%s" w)
		?visualFormat	"%s"
		?aelSuffix	t
		?noVar		t		; don't allow variables, only scalar
		?minimum	wmin
		?maximum	wmax
		?default	cdfId->w->defValue
  )
  when( stringp(w) && (w != cdfId->w->value) cdfId->w->value = w )
  w = cdfParseFloatString(w)
  w = fdkSnapGrid(mfgGrid w)

  ldmin  = cdfParseFloatString(cdfId->ldrawn->defValue)
  ldmax  = drTable["ldmax"]*1u
  ldrawn = cdfId->ldrawn->value
  ldrawn = fdkAelEval(
		?entry		(sprintf nil "%s" ldrawn)
		?visualFormat	"%s"
		?aelSuffix	t
		?noVar		t		; don't allow variables, only scalar
		?minimum	ldmin
		?maximum	ldmax
		?default	cdfId->ldrawn->defValue
  )
  when( stringp(ldrawn) && (ldrawn != cdfId->ldrawn->value) cdfId->ldrawn->value = ldrawn )
  ldrawn = cdfParseFloatString(ldrawn)
  ldrawn = fdkSnapGrid(mfgGrid ldrawn)

  ;; get new viaLeftMax based on current L and minimumViaRightOffset (give priority to Length)
  viaType       = cdfId->viaType->value
  viaWidth      = drTable["viaType"][viaType]["width"]*1u
  viaLength     = drTable["viaType"][viaType]["length"]*1u
  MIMgap        = drTable["MIMBspace"]*1u
  viaOffsetL    = cdfId->viaOffsetL->value

  minViaOffsetL = cdfParseFloatString(cdfId->viaOffsetL->defValue)
  minViaOffsetR = cdfParseFloatString(cdfId->viaOffsetR->defValue)

  maxViaOffsetL = ldrawn-minViaOffsetR-(2*(viaLength/2.0+um_ovlp)+um_space)
  maxViaOffsetL = min(maxViaOffsetL ldrawn/(1+modelLimit)+2*(viaLength/2+mimSpaceVia)-minViaOffsetR)
  when( stacked
    maxViaOffsetL = min(maxViaOffsetL (ldrawn/2 - (MIMgap/2.0+mimMinWidth+mimSpaceVia+viaLength/2.0)))
    maxViaOffsetL = min(maxViaOffsetL (viaLength/2+mimSpaceVia) + ldrawn/(2*(modelLimit + 1)))
  );when
  maxViaOffsetL = floor(pcFix(maxViaOffsetL/mfgGrid))*mfgGrid
  viaOffsetL    = fdkAelEval(
			?entry		(sprintf nil "%s" viaOffsetL)
			?visualFormat	"%s"
			?aelSuffix	t
		 	?noVar		t		; don't allow variables, only scalar
			?minimum	minViaOffsetL
			?maximum	maxViaOffsetL
			?default	cdfId->viaOffsetL->defValue
  )

  ;; for mimcap_stk set viaOffset{L,R} to the the same value
  if( stacked then
    when(viaOffsetL != cdfId->viaOffsetL->value cdfId->viaOffsetL->value = viaOffsetL )
    when(viaOffsetL != cdfId->viaOffsetR->value cdfId->viaOffsetR->value = viaOffsetL )
    viaOffsetL    = cdfParseFloatString(viaOffsetL)
    viaOffsetL    = fdkSnapGrid(mfgGrid viaOffsetL)
    viaOffsetR    = viaOffsetL
  else
    when(viaOffsetL != cdfId->viaOffsetL->value cdfId->viaOffsetL->value = viaOffsetL )
    viaOffsetL    = cdfParseFloatString(viaOffsetL)
    viaOffsetL    = fdkSnapGrid(mfgGrid viaOffsetL)
    ;; get new viaRightMax based on current L and ViaLeftOffset (give priority to Length and viaLeftOffset)
    maxViaOffsetR = ldrawn - viaOffsetL - (2*(viaLength/2.0+um_ovlp)+um_space)
    maxViaOffsetR = min(maxViaOffsetR ldrawn/(1+modelLimit) + 2*(viaLength/2+mimSpaceVia)-viaOffsetL)
    maxViaOffsetR = floor(pcFix(maxViaOffsetR/mfgGrid))*mfgGrid
    viaOffsetR    = cdfId->viaOffsetR->value
    viaOffsetR    = fdkAelEval(
			?entry		(sprintf nil "%s" viaOffsetR)
			?visualFormat	"%s"
			?aelSuffix	t
		 	?noVar		t		; don't allow variables, only scalar
			?minimum	minViaOffsetR
			?maximum	maxViaOffsetR
			?default	cdfId->viaOffsetR->defValue
    )
    when(stringp(viaOffsetR) && (viaOffsetR != cdfId->viaOffsetR->value) cdfId->viaOffsetR->value = viaOffsetR)
    viaOffsetR = cdfParseFloatString(viaOffsetR)
    viaOffsetR = fdkSnapGrid(mfgGrid viaOffsetR)
  ); if stacked

  ;;**************************************************
  ;; Calculate l1,l2,l3 variables
  ;;**************************************************

  ;; calculate values
  l3 = max(0.0 viaOffsetL - viaLength/2.0 - mimViaOffset)
  l2 = max(0.0 viaOffsetR - viaLength/2.0 - mimViaOffset)
  l1 = max(0.0 ldrawn - l2 - l3)
  wh = max(0.0 viaWidth + 2*mimViaOffset)
  lh = max(0.0 viaLength + 2*mimViaOffset)

  ;; calculate number of holes in PGD direction
  nh = max(1 floor(pcFix((w - mimMinWidth)/(viaWidth + 2*mimSpaceVia+mimMinWidth))))

  ;; calculate the effective area and length model
  if( stacked
  then Area   = w*(l1+l2+l3-MIMgap)/2.0
       Aholes = nh*wh*lh
       Aeff   = (Area-Aholes)/2
       lmodel = L1scale*l1 + L2L3scale*(l2+l3)
  else Area   = w*(l1+l2+l3)
       Aholes = 2*nh*wh*lh
       Aeff   = Area-Aholes
       lmodel = (2/3.0)*(L1scale*l1 + L2L3scale*(l2+l3))
  )

  ;; calculate caps and resistances
  Cest = Aeff*Crmimcap
  Rest = Rmimcap*lmodel/w

  ;; Update CDF with any new values
  foreach( param_nm '("Cest" "Rest" "l1" "l2" "l3" "wh" "lh" "nh")
  let((param_val cdf_paramId)
    when( !null(param_val = evalstring(param_nm))
      param_val = fdkAelEval(?entry param_val ?visualFormat "%g" ?aelSuffix t)
      cdf_paramId = cdfFindParamByName(cdfId param_nm)
      when( stringp(param_val) && !null(cdf_paramId) && (param_val != cdf_paramId->value)
        cdf_paramId->value = param_val
      )
    )
  ))

  aelPopSignifDigits()

t)) ; procedure fdkCdf_mimcap_sclCB

putd( 'fdkCdf_mimcap_scl_doneProc nil )
procedure( fdkCdf_mimcap_scl_doneProc(instId)
let((cdfgData)
  when( !null(cdfgData = cdfGetInstCDF(instId))
    fdkCdf_mimcap_sclCB(instId->libName instId->cellName cdfgData)
  )
)) ; procedure

putd( 'fdkCdf_mimcap_stk_sclCB nil )
procedure( fdkCdf_mimcap_stk_sclCB(lib cell cdfId)
  fdkCdf_mimcap_sclCB(lib cell cdfId ?stacked t)
)

putd( 'fdkCdf_mimcap_stk_scl_doneProc nil )
procedure( fdkCdf_mimcap_stk_scl_doneProc(instId)
let((cdfgData)
  when( !null(cdfgData = cdfGetInstCDF(instId))
    fdkCdf_mimcap_stk_sclCB(instId->libName instId->cellName cdfgData)
  )
)) ; procedure
