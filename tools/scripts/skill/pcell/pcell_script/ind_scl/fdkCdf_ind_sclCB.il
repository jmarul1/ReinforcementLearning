;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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

/*---------------------------------------------------------------------------
 procedure: fdkDoneProcIndCDF
 Purpose: Updates the name of the inductor from the CDF parameters.
 ---------------------------------------------------------------------------*/
procedure( fdkDoneProcIndCDF(instance)
  let( (cdfgData)
    cdfgData = cdfGetInstCDF(instance)
    fdkPutIndCktParamsInCDF(cdfgData)
  ) ; let
) ; procedure

/*---------------------------------------------------------------------------
 procedure: fdkPutIndCktParamsInCDF
 Purpose: Puts or updates the circuit parameters and the name in the CDF symbol of scalable inductors (this function is a call back as well)
 ---------------------------------------------------------------------------*/
procedure( fdkPutIndCktParamsInCDF(cdfgData)
  let( (N S W Dx Dy topMetal cktParamNameList cktParamList tempData )
;; Check the dimension values
    fdkChkIndDim(cdfgData)
;; Get the dimensions values
    N  = cdfgData->nrturns->value
    S  = cdfgData->coilspcx->value
    W  = cdfgData->coilwx->value
    Dx = cdfgData->innerwx->value
    Dy = cdfgData->innerwy->value
    topMetal = cdfgData->toplayer->value
;; Convert to Float and use microMeter dimensions for Coil Space, Coil Width and Diameter(XY)
    when(type(N) =='string N =cdfParseFloatString(N))
    when(type(S) =='string S =cdfParseFloatString(S)*1e6)
    when(type(W) =='string W =cdfParseFloatString(W)*1e6)
    when(type(Dx)=='string Dx=cdfParseFloatString(Dx)*1e6)
    when(type(Dy)=='string Dy=cdfParseFloatString(Dy)*1e6)
;; Get the list of the circuit parameters
    cktParamList = fdkGetXtrCktParamList(N S W Dx topMetal)
;; Get the correct cktParamNameList depending on the instance of the CDF
    cktParamNameList = list("Ls1" "L1" "Rs1" "R1" "Cox1" "Rsub1" "Co12" "K12" "QdPeak" "LdPeak" "FreqPeak") 
;; Assign the values to the CDF parameters
    foreach(skew list("lowQ" "typQ" "highQ")
      foreach(cktParam cktParamNameList 
        tempData = strcat(lowerCase(skew) cktParam) ;set entryName ID in the Camel Notation
        putprop(cdfFindParamByName(cdfgData tempData) get(cktParamList tempData) 'value) 
	when(and(or(cktParam=="QdPeak" cktParam=="LdPeak" cktParam=="FreqPeak") get(cktParamList tempData))
	  putprop(cdfFindParamByName(cdfgData tempData) fdkNum2Str(cdfParseFloatString(get(cktParamList tempData)) 3) 'value) )
      );foreach(cktParam
    );foreach(skew
 
    fdkCalculateRMSCurrent(cdfgData)
    t
  );let
);procedure


/*---------------------------------------------------------------------------
 procedure: fdkCalculateRMSCurrent
 Purpose: Generates the approximate RMS current specs for a given range of inductor parameters 
 Parameters: cdfgData
 ---------------------------------------------------------------------------*/

procedure( fdkCalculateRMSCurrent(cdfgData)
    let( (N W irms irmstm1 irms_m11 defaultParams topMet coilw termloc cellId minSpace maxWidth sigWidth numSig usedSpace
    drTable defaultParams coilWidth viaTopEnc viaWidth viaSpace numVia )

	  
	  cellId = cdfgData->id
	  
	  when(cellId->type=="trueInst" cellId = ddGetObj(cellId->libName cellId->cellName))

	  defaultParams = fdkGetPropTable( cellId ?name "defaults" ?string t)
	  drTable = fdkGetPropTable( cellId ?name "designRules" ?string t)
	  
         N = cdfgData->nrturns->value
         W  = cdfgData->coilwx->value
         termloc  = cdfgData->termside->value
	 
         when(type(N) =='string N =cdfParseFloatString(N))
         when(type(W) =='string W =cdfParseFloatString(W)*1e6)
	 
         topMet = cdfgData->toplayer->value
         if( N == 1 then
	    irms = drTable["irms"][topMet]
	    when(type(irms) =='string irms =cdfParseFloatString(irms))
            cdfgData->currentrms->value = sprintf(nil "%s" fdkNum2Str(irms*W))
	    if( topMet == "m12" then
	      ;break()
	      minSpace = drTable["layer"]["m11"]["minSpace"]
     	      maxWidth = drTable["layer"]["m11"]["maxWidth"]
              when(type(minSpace) =='string minSpace =cdfParseFloatString(minSpace))
              when(type(maxWidth) =='string maxWidth =cdfParseFloatString(maxWidth))
	      
              sigWidth = maxWidth
	      numSig = fix( (W-sigWidth)/(sigWidth+minSpace))+1
              usedSpace = numSig*sigWidth
	      irms_m11 = drTable["irms"]["m11"]
              when(type(irms_m11) =='string irms_m11 =cdfParseFloatString(irms_m11))	      
              cdfgData->currentrms->value = sprintf(nil "%s" fdkNum2Str(irms*W+irms_m11*usedSpace))	      
	    )
         else
           if( topMet == "tm1" then

		coilWidth = cdfgData~>coilwx~>value
		viaTopEnc = drTable["via"]["v12"][topMet]["enc"]
		viaWidth = drTable["via"]["v12"]["width"]
		viaSpace = drTable["via"]["v12"]["space"]
		when(type(coilWidth) =='string coilWidth =cdfParseFloatString(coilWidth))
		when(type(viaTopEnc) =='string viaTopEnc =cdfParseFloatString(viaTopEnc))		
		when(type(viaWidth) =='string viaWidth =cdfParseFloatString(viaWidth))
		when(type(viaSpace) =='string viaSpace =cdfParseFloatString(viaSpace))				
		numVia = max( fix( (coilWidth-2*viaTopEnc-viaWidth)/(viaWidth+viaSpace))+1 1)

		irms = drTable["irms"]["v12"]
		when(type(irms) =='string irms =cdfParseFloatString(irms))
		cdfgData->currentrms->value = sprintf(nil "%s" fdkNum2Str(irms*numVia))
	    
	    else
	       if( (topMet == "m12" && (termloc == "Top" || termloc == "Bottom")) then
	         ;break()
   	         minSpace = drTable["layer"]["m11"]["minSpace"]
     	         maxWidth = drTable["layer"]["m11"]["maxWidth"]
                 when(type(minSpace) =='string minSpace =cdfParseFloatString(minSpace))
                 when(type(maxWidth) =='string maxWidth =cdfParseFloatString(maxWidth))
	      
                 sigWidth = maxWidth
	         numSig = fix( (W-sigWidth)/(sigWidth+minSpace))+1
                 usedSpace = numSig*sigWidth
	         irms_m11 = drTable["irms"]["m11"]
                 when(type(irms_m11) =='string irms_m11 =cdfParseFloatString(irms_m11))	      
                 cdfgData->currentrms->value = sprintf(nil "%s" fdkNum2Str(irms_m11*usedSpace))	      
	       )
	       if( (topMet == "m12" && (termloc == "Left" || termloc == "Right")) then
	         if( W >= 5.5  then numVia11 = 15)
	         if( (W >= 5 && W < 5.5)  then numVia11 = 10)
	         if( (W < 5 && W > 3.93)  then numVia11 = 8)
		 if( W <= 3.93   then numVia11 = 6)
		 
	         irms_v11 = drTable["irms"]["v11"]		 
		when(type(irms_v11) =='string irms_v11 =cdfParseFloatString(irms_v11))
		 cdfgData->currentrms->value = sprintf(nil "%s" fdkNum2Str(irms_v11*numVia11))	      
	       ) ;; else topMet == m12

	     ) ; topMet == tm1

	    
	 ) ;if N == 1

	t 
    ) ;let
);proc


/*---------------------------------------------------------------------------
 procedure: fdkGetXtrCktParamList
 Purpose: Generates the extracted paramaters in a disembodied list of strings for all skews based on the perl spline generator. 
 Parameters: N S W D can be either floatnums, integers or strings
 ---------------------------------------------------------------------------*/
procedure(fdkGetXtrCktParamList(N S W D topMetal)
  let( (argumentStr perlScriptFile commandUnixRead commandUnixPid parameterList parameterStr parameterVal 
        (tableObj gensym()) tempData)
;; Make sure the dimensions are floating or integer numbers and not strings
    when(type(N)=='string N=cdfParseFloatString(N))
    when(type(S)=='string S=cdfParseFloatString(S))
    when(type(W)=='string W=cdfParseFloatString(W))
    when(type(D)=='string D=cdfParseFloatString(D))
;; prepare arguments for the perl spline generator
    argumentStr = sprintf(nil "nrturns = %f coilspcx = %f coilwx = %f innerwx = %f toplayer = %s" float(N) float(S) float(W) float(D) topMetal)
;; run the spline parameter generatior
    perlScriptFile = strcat(getShellEnvVar("INTEL_PDK") "/models/utils/scalable/bin/v1.0/fdk_ind_sclParamGen.pl")
    unless(isFile(perlScriptFile) perlScriptFile = strcat(getShellEnvVar("INTEL_PDK") "/models/utils/scalable/bin/latest/fdk_ind_sclParamGen.pl") )
    unless(isFile(perlScriptFile) perlScriptFile = strcat(getShellEnvVar("INTEL_PDK") "/models/utils/scalable/bin/fdk_ind_sclParamGen.pl") )
    ;; check that the perl script was found
    if(isFile(perlScriptFile) then
      commandUnixRead = sprintf(nil "%s %s" perlScriptFile argumentStr)
      commandUnixPid = ipcBeginProcess(commandUnixRead)
      ipcWait(commandUnixPid)
;; read the data
      parameterList = "" ; initialize
      while( (tempData = ipcReadProcess(commandUnixPid)) != nil 
        parameterList=strcat(parameterList tempData)
      ) ; while
;; parse the values obtained and put them in a disembodied list
      tempData = pcreCompile("^(\\w+) *= *(\\d+(?:\\.\\d+)?) *" 0x00000001) 
      while(pcreExecute(tempData parameterList) 
        parameterStr = pcreSubstitute("\\1")   parameterVal = pcreSubstitute("\\2")
        ;; add values (float) to the disembodied list
        putprop(tableObj parameterVal parameterStr) 
        parameterList = pcreReplace(tempData parameterList "" 1)
      ) ;while
    else
      artError("Could not generate simulation parameters for the symbol (WIP)")
    ) ;if/else
    tableObj    
  ) ; let
) ; procedure fdkgetNetlistString

/*---------------------------------------------------------------------------
 procedure: fdkGetTopMetalLayer
 purpose: Cleans up the string given for the top metal returning "metal12" "tm1" or default "metal12" for top metal.
 ---------------------------------------------------------------------------*/
procedure( fdkGetTopMetalLayer(metalStr)
  metalStr = lowerCase(metalStr)
  if(rexMatchp("m.*12" metalStr) then
    "m12"
    else if(rexMatchp("t.*m.*1" metalStr) then
	   "tm1"
         else
	   printf("INFO: corrected invalid cdf entry:TopMetal\n")
	   "tm1" ; default
	 ) ; if tm1
  ) ; if metal 12
) ; procedure

/*---------------------------------------------------------------------------
 procedure: fdkGetIndArea
 Purpose: Returns the Area of an inductor
 ---------------------------------------------------------------------------*/
procedure( fdkGetIndArea(N S W D)
  let( (Douter)
    N = cdfParseFloatString(fdkNum2Str(N,25))
    S = cdfParseFloatString(fdkNum2Str(S,25))
    W = cdfParseFloatString(fdkNum2Str(W,25))
    D = cdfParseFloatString(fdkNum2Str(D,25))
    Douter = (N-1)*S + N*W + D/2
    Douter*Douter
    D*D
  ) ; let
) ; procedure

/*---------------------------------------------------------------------------
 procedure: fdkChkIndDim
 Purpose: Checks the dimensions of the inductor, if wrong then default values are set. This procedure also sets InnerWy equal to InnerWx in this version..
 ---------------------------------------------------------------------------*/
procedure( fdkChkIndDim(cdfgData)
  let( (N S W D Dy tExt tSep Nmax Nmin Ndefault Smax Smin Sdefault Wmax Wmin Wdefault Dmax Dmin Ddefault tExtMin tExtMax tSepMin tSepMax topMetal paramRngs)
;; check the topMetal layer and shape
    topMetal = fdkGetTopMetalLayer(cdfgData->toplayer->value)
    cdfgData->toplayer->value = topMetal
    indShape = cdfgData->indShape->value
;; call function to set ranges, values are assumed to be in microMeters for S,W and D    
    paramRngs = fdkGetParamRng(cdfgData->model->value topMetal)
    Nmax=paramRngs["Nmax"] Nmin=paramRngs["Nmin"] Smax=paramRngs["Smax"] Smin=paramRngs["Smin"] 
    Wmax=paramRngs["Wmax"] Wmin=paramRngs["Wmin"] Dmax=paramRngs["Dmax"] Dmin=paramRngs["Dmin"] 
    Ndefault=paramRngs["Ndefault"] Sdefault=paramRngs["Sdefault"] 
    Wdefault=paramRngs["Wdefault"] Ddefault=paramRngs["Ddefault"]
    tExtMin = paramRngs["tExtMin"] tSepMin=paramRngs["tSepMin"] 
;; convert string to floating, and if its a number to micrometers, if it is not let it be, except D and N since they are used
    when(type(cdfgData->nrturns->value) =='string N=cdfParseFloatString(cdfgData->nrturns->value) N=(if numberp(N) N 0))
    when(type(cdfgData->coilspcx->value)=='string S=cdfParseFloatString(cdfgData->coilspcx->value) when(numberp(S) S=S*1e6))
    when(type(cdfgData->coilwx->value)  =='string W=cdfParseFloatString(cdfgData->coilwx->value) when(numberp(W) W=W*1e6))
    when(type(cdfgData->innerwx->value) =='string D=cdfParseFloatString(cdfgData->innerwx->value) D=(if numberp(D) D*1e6 0) )    
    when(type(cdfgData->innerwy->value) =='string Dy=cdfParseFloatString(cdfgData->innerwy->value) Dy = (if numberp(Dy) Dy*1e6 0))        
    when(type(cdfgData->termext->value) =='string tExt=cdfParseFloatString(cdfgData->termext->value) when(numberp(tExt) tExt=tExt*1e6))        
    when(type(cdfgData->termspc->value) =='string tSep=cdfParseFloatString(cdfgData->termspc->value) when(numberp(tSep) tSep=tSep*1e6))
    when(type(cdfgData->termside->value)=='string termSide=cdfgData->termside->value)           
;; set innerWx and innerWy equal
    unless(or(cdfgData->model->value=="indcust_scl" D==Dy) cdfgData->innerwy->value = cdfgData->innerwx->value Dy = D)   
;; check or correct dimensions (use three decimals when correcting and use microMeters)
    unless(or( and( numberp(N) N>Nmin N<Nmax) fdkCompFloatNums(N Nmin) fdkCompFloatNums(N Nmax) )
      cdfgData->nrturns->value = fdkNum2Str(Ndefault) printf("INFO: corrected invalid cdf entry for the Number of turns (out of range)\n") N=Ndefault)
   ;; special handling for spiral allowing quater turns and not just integers
    if(indShape == "spiral" then
      unless(fdkCompFloatNums(N/0.25 fix(N/0.25)) 
        cdfgData->nrturns->value = fdkNum2Str(0.25*round(N/0.25) 2) printf("INFO: corrected invalid cdf entry for the Number of turns (only quater-multiple turns allowed)\n"))
    else
      unless(fdkCompFloatNums(N fix(N)) N=fix(N) cdfgData->nrturns->value = fdkNum2Str(N) printf("INFO: corrected invalid cdf entry for the Number of turns (only integers allowed)\n"))
    );if(indShape    
    unless(or( and( numberp(S) S>Smin S<Smax) fdkCompFloatNums(S Smin) fdkCompFloatNums(S Smax) )
      cdfgData->coilspcx->value = strcat(fdkNum2Str(Sdefault 3) "u") printf("INFO: corrected invalid cdf entry for the Spacing (out of range)\n") )
   ;; special handling for N>1 and TM1 for Wmin
    when(and(N>1 topMetal=="tm1" indShape=="symmetrical" ) Wmin = 6.8)
    unless(or( and( numberp(W) W>Wmin W<Wmax) fdkCompFloatNums(W Wmin) fdkCompFloatNums(W Wmax) ) 
      cdfgData->coilwx->value = strcat(fdkNum2Str(Wdefault 3) "u") printf("INFO: corrected invalid cdf entry for the Width (out of range)\n") )
    unless(or( and( numberp(D) D>Dmin D<Dmax) fdkCompFloatNums(D Dmin) fdkCompFloatNums(D Dmax) ) 
      cdfgData->innerwx->value = strcat(fdkNum2Str(Ddefault 3) "u") printf("INFO: corrected invalid cdf entry for the Inner X Diameter (out of range)\n") )
    unless(or( and( numberp(Dy) Dy>Dmin Dy<Dmax) fdkCompFloatNums(Dy Dmin) fdkCompFloatNums(Dy Dmax) ) 
      cdfgData->innerwy->value = strcat(fdkNum2Str(Ddefault 3) "u") printf("INFO: corrected invalid cdf entry for the Inner Y Diameter (out of range)\n") )
   ;; special handling for minimum and maximum terminal extension
    tExtMax = 10*max(D Dy)
    when(and(oddp(fix(N)) cdfgData->centertap->value == "Yes" topMetal=="tm1" tExtMin < W+S) tExtMin = W + S + 0.1) ; using 0.1 more than the minimum
    unless(or( and( numberp(tExt) tExt>tExtMin tExt<tExtMax) fdkCompFloatNums(tExt tExtMin) fdkCompFloatNums(tExt tExtMax)) 
      cdfgData->termext->value = strcat(fdkNum2Str(tExtMin 3) "u") printf("INFO: corrected invalid cdf entry for the Terminal Extension (out of range)\n") )
   ;; special handling for the minimum separation of terminals
    when(and(evenp(fix(N)) cdfgData->centertap->value == "Yes" tSepMin < W+2*S) tSepMin = W + 2*S )
    (if or(termSide == "Left" termSide == "Right") tSepMax = Dy tSepMax = D)
    unless(or( and( numberp(tSep) tSep>tSepMin tSep<tSepMax) fdkCompFloatNums(tSep tSepMin) fdkCompFloatNums(tSep tSepMax) ) 
        cdfgData->termspc->value = strcat(fdkNum2Str(tSepMin 3) "u") printf("INFO: corrected invalid cdf entry for the Terminal Separation (out of range)\n") )
    cdfgData->m->value = fdkAelEval(?entry cdfgData->m->value ?noVar t ?visualFormat "%d" ?minimum 1 ?maximum 100 ?default 1)
)) ; procedure

/*---------------------------------------------------------------------------
 procedure: fdkNum2Str
 Purpose: Converts a number to string, if the input is not a number it returns the value unchanged.
          A precision of 6 is the default value, if not specified or specified wrongly (must be a digit).
 ---------------------------------------------------------------------------*/
procedure( fdkNum2Str(numberGiven @optional (precision 6) )
  let( ()
    if(numberp(precision) then
      sprintf(precision "%d" fix(precision)) 
    else 
      sprintf(precision "%d" fix(6))
    ) ; if
    case(type(numberGiven)
      (fixnum sprintf(numberGiven "%d" numberGiven))
      (flonum sprintf(numberGiven strcat("%." precision "f") float(numberGiven)))
      (t numberGiven)
    ) ; case
    when(rexMatchp("[0-9]*\\." numberGiven )
      while(rexMatchp("0$" numberGiven) numberGiven = rexReplace(numberGiven "" 1)) ; while to remove extra "0s"
      when(rexMatchp("\\.$" numberGiven) numberGiven = rexReplace(numberGiven "" 1) ) ; when to make integer for ".0"
    ) ; when
    numberGiven
  )
) ; procedure

/*---------------------------------------------------------------------------
 procedure: fdkDotToLetter
 Purpose: Converts dot to the letter p ("." to "p") in a decimal number by default, if option is given with a negative value, 
          the reverse process is done. Up to six decimals are supported for any notation, including exponential.
 ---------------------------------------------------------------------------*/
procedure( fdkDotToLetter(strVal @optional (direction 1) )
  if(direction >= 0 then
    when(type(strVal)=='string  strVal=cdfParseFloatString(strVal))
    strVal = fdkNum2Str(strVal) ;only six decimals are kept regardless of the notation
    rexCompile("\\.")
    rexReplace(strVal "p" 1)
  else
    strVal = fdkNum2Str(strVal) ;make sure it is a string
    rexCompile("p")
    rexReplace(strVal "." 1)
  ) ; if
) ; procedure

/*---------------------------------------------------------------------------
 procedure: fdkCompFloatNum
 Purpose: Compares two floating numbers, tolerance if not given is 1e-12. If inputs are not numbers, nil is return
 ---------------------------------------------------------------------------*/
procedure(fdkCompFloatNums(fNum1 fNum2 @optional (tolGiven 1e-12) )
  let( ( (result nil) )
    when(and(numberp(fNum1) numberp(fNum2) abs(fNum1-fNum2) < tolGiven) result=t) 
    result
)); procedure

/*---------------------------------------------------------------------------
 procedure: fdkListBBox
 Purpose: Creates the list of all 4 points for the given bbox
 ---------------------------------------------------------------------------*/
procedure( fdkListBBox(bBoxGiven)
    let((leftBotX leftBot rightTopX rightTopY)
        (leftBotX = caar(bBoxGiven))
        (leftBotY = cadar(bBoxGiven))
        (rightTopX = caadr(bBoxGiven))
        (rightTopY = cadadr(bBoxGiven))
        list(list(leftBotX leftBotY)
            list(leftBotX rightTopY)
            list(rightTopX rightTopY)
            list(rightTopX leftBotY)
        )
    )
)

/*---------------------------------------------------------------------------
 procedure: fdkGetParamRng
 Purpose: Returns the parameter range allowed for the given input of N,S,W,D,Y
 ---------------------------------------------------------------------------*/
procedure( fdkGetParamRng(cellName topLayer)
  let((outputTbl)
    outputTbl = makeTable(gensym() nil)
    if(cellName == "indcust_scl" then
      if(topLayer == "m12" then
        outputTbl["Nmax"]=50 outputTbl["Nmin"]=1    outputTbl["Smax"]=10   outputTbl["Smin"]=0.54
	outputTbl["Wmax"]=50 outputTbl["Wmin"]=0.54 outputTbl["Dmax"]=1000 outputTbl["Dmin"]=0.54
        outputTbl["Ndefault"]=fix(3) outputTbl["Sdefault"]=0.54 outputTbl["Wdefault"]=5 outputTbl["Ddefault"]=50 
	outputTbl["tExtMin"]=0.54 outputTbl["tSepMin"]=0.54
      else ; topLayer == "tm1"
        outputTbl["Nmax"]=50 outputTbl["Nmin"]=1   outputTbl["Smax"]=10   outputTbl["Smin"]=5.5 
	outputTbl["Wmax"]=50 outputTbl["Wmin"]=5.5 outputTbl["Dmax"]=1000 outputTbl["Dmin"]=5.5
        outputTbl["Ndefault"]=fix(3) outputTbl["Sdefault"]=5.5 outputTbl["Wdefault"]=6.8 outputTbl["Ddefault"]=50     
	outputTbl["tExtMin"]=5.5 outputTbl["tSepMin"]=5.5
      ) ; if(topLayer
    else ;"ind2t_scl" or "ind3t_scl"
      if(topLayer == "m12" then
        outputTbl["Nmax"]=5  outputTbl["Nmin"]=1    outputTbl["Smax"]=0.6  outputTbl["Smin"]=0.54
	outputTbl["Wmax"]=6  outputTbl["Wmin"]=3.6  outputTbl["Dmax"]=67   outputTbl["Dmin"]=20
        outputTbl["Ndefault"]=fix(3) outputTbl["Sdefault"]=0.54 outputTbl["Wdefault"]=5 outputTbl["Ddefault"]=50 
	outputTbl["tExtMin"]=14 outputTbl["tSepMin"]=10
      else ; topLayer == "tm1"
        outputTbl["Nmax"]=5   outputTbl["Nmin"]=1   outputTbl["Smax"]=5.52 outputTbl["Smin"]=5.5 
	outputTbl["Wmax"]=6.8 outputTbl["Wmin"]=5.5 outputTbl["Dmax"]=128  outputTbl["Dmin"]=38
        outputTbl["Ndefault"]=fix(3) outputTbl["Sdefault"]=5.5 outputTbl["Wdefault"]=6.8 outputTbl["Ddefault"]=50     
	outputTbl["tExtMin"]=14 outputTbl["tSepMin"]=10
      ) ; if(topLayer
    ) ; if(cellName
    outputTbl
));procedure
