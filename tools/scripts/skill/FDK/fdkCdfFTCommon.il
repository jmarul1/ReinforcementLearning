procedure( fdkGetCapexec(capexecPath cmdArgs)
   let((result cmd cid output outLine outValue outUnit outValueUnit)
       cmd = strcat(capexecPath " " cmdArgs) 
       cid = ipcBeginProcess(cmd)
       ipcWait(cid)
       output= ipcReadProcess(cid)
       ipcKillProcess(cid)
       outLine= nth(0 parseString(output "\n"))
       if(rexMatchp("^-E-:" outLine) then
          printf("%s\n" outLine)
          result = "Value not available"
       else  
          outValue = nth(0 parseString(outLine " "))
          outUnit = nth(0 parseString(nth(1 parseString(outLine " ")) ""))
          outValueUnit = strcat(outValue outUnit)
          if(numberp(cdfParseFloatString(outValueUnit)) then
              result =  outValueUnit
          else
              result =  outValue
          )
      )
   )
   
)
             
procedure( fdkGetCapexecPath( skewCorner )
    let((capexecDir result)
        result="capexec missing"
        capexecDir = strcat(env("INTEL_PDK") "/models/utils/capexec/")
        capexecFiles=getDirFiles(capexecDir)
        foreach(skew capexecFiles
            if( rexMatchp(skewCorner skew) then
                capexecFile = skew
                result=strcat(capexecDir skew)
            )
        )
        result
    )
)

procedure( fdkGetCompValue( capexecPath component @optional caller )
    	let(
             ((cdfId caller||cdfgData))           
	   let(
               (temperature resArgs resModel width_um wl_um wr_um wln_um wrn_um spacel_um spacer_um spaceln_um spacern_um estRValue estR  capSel capReplaceList capEvaluate capComponents capModel capArgs compValue estCompValue estC (coeff 1) (totalCap 0) ( scale_m2um 1e6) (capError nil))

               
               length=cdfId->l->value
               width_um = sprintf(nil "%f" cdfParseFloatString(cdfId->w->value)*scale_m2um)
               if(!stringp(cdfParseFloatString(length)) then
                    l_um = sprintf(nil "%f" cdfParseFloatString(cdfId->l->value)*scale_m2um)
               )               
               
               case(component
                   ("resistance"
                    if(rexMatchp("^rcr" cdfId->model->value) 
                    then
                        rexCompile("rcr")
                    else    
                        rexCompile("r")
                    )
                    temperature = cdfId->temperature->value
                    resModel = rexReplace(cdfId->model->value "rr" 0) 
                    resArgs = buildString(list("-nolegal" resModel "R" temperature width_um) " ")
                    if(!stringp(cdfParseFloatString(length)) then
                        resArgs=buildString(list("-l" l_um resArgs) " ")
                    )
                    estRValue = fdkGetCapexec(capexecPath resArgs)
                    if(numberp(cdfParseFloatString(estRValue)) then
                       estR = sprintf(nil "%L" cdfParseFloatString(estRValue)) 
                    else
                       estR =  estRValue 
                     )               
                    )
                    ("capacitance"
                        wl_um = sprintf(nil "%f" cdfParseFloatString(cdfId->wl->value)*scale_m2um)
                        wr_um = sprintf(nil "%f" cdfParseFloatString(cdfId->wr->value)*scale_m2um)
                        spacel_um = sprintf(nil "%f" cdfParseFloatString(cdfId->spacel->value)*scale_m2um)
                        spacer_um = sprintf(nil "%f" cdfParseFloatString(cdfId->spacer->value)*scale_m2um)
                        if(numberp(cdfParseFloatString(cdfId->wln->value)) then 
                           wln_um=sprintf(nil "%f" cdfParseFloatString(cdfId->wln->value)*scale_m2um)
                        else
                           wln_um = cdfId->wln->value
                        )
                        if(numberp(cdfParseFloatString(cdfId->wrn->value)) then 
                           wrn_um=sprintf(nil "%f" cdfParseFloatString(cdfId->wrn->value)*scale_m2um)
                        else
                           wrn_um = cdfId->wrn->value
                        )
                        if(numberp(cdfParseFloatString(cdfId->spaceln->value)) then 
                           spaceln_um=sprintf(nil "%f" cdfParseFloatString(cdfId->spaceln->value)*scale_m2um)
                        else
                           spaceln_um = cdfId->spaceln->value
                        )
                        if(numberp(cdfParseFloatString(cdfId->spacern->value)) then 
                           spacern_um=sprintf(nil "%f" cdfParseFloatString(cdfId->spacern->value)*scale_m2um)
                        else
                           spacern_um = cdfId->spacern->value
                        )                           
          	        capSel=cdfId->cSel->value
                        
                        if(!(cdfParseFloatString(cdfId->mcf->value) == 1 ||  cdfId->mcf->value == "") && capSel == "ctot"  then
                             if(cdfId->mcf->value == "0" then
                                 capSel="ctop+cbot"
                             else                            
                                 capSel=strcat("ctop+cbot+" cdfId->mcf->value "*cll_l+" cdfId->mcf->value "*cll_r")
                             ) 
                        )                                       
                        capReplaceList = mapcar( lambda((x) rexCompile(nth(0 x)) capSel=rexReplace(capSel nth(1 x) 0)) '(("cll_l" "cll_l") ("cll_r" "cll_r") ("ctop" "cu+2*cstp") ("cbot" "ca+2*cfp") ))
                        capEvaluate = car(last(capReplaceList)) 
                        capComponents = parseString(capEvaluate "\\+")
                    	if(rexMatchp("^rcr" cdfId->model->value) 
                        then
				rexCompile("rcr")
                        	capModel = rexReplace(cdfId->model->value "cr" 0)
                     	else    
                        	capModel = cdfId->model->value
                     	)                    
                        foreach(cap capComponents
                                if(rexMatchp("\\*" cap) then
                                     coeff = evalstring(nth(0 parseString(cap "\\*")))
                                     cap = nth(1 parseString(cap "\\*"))
                                else
                                     coeff = 1 
                                )
                                case(cap
                                    ("ctot"
                                      capArgs=buildString(list("-nolegal" capModel cap spacel_um spacer_um width_um wl_um wr_um spaceln_um spacern_um wln_um wrn_um) " ") 
                                    )
                                    ("cll_l"
                                      capArgs=buildString(list("-nolegal" capModel "clls" spacel_um width_um wl_um) " ") 
                                    )
                                    ("cll_r"
                                      capArgs=buildString(list("-nolegal" capModel "clls" spacer_um width_um wr_um) " ") 
                                    )
                                    ("cfp"
                                      capArgs=buildString(list("-nolegal" capModel cap spacel_um width_um) " ") 
                                    )
                                    ("cstp"
                                      capArgs=buildString(list("-nolegal" capModel cap spacel_um width_um width_um) " ") 
                                    )
                                    ("ca"
                                      capArgs=buildString(list("-nolegal" capModel cap width_um) " ")
                                    )
                                    ("cu"
                                      capArgs=buildString(list("-nolegal" capModel cap width_um) " ")
                                    )
                                )
                                if(!stringp(cdfParseFloatString(length)) then
                                    capArgs=buildString(list("-l" l_um capArgs) " ")
                                )
                                compValue = fdkGetCapexec(capexecPath capArgs)
                                if(numberp(cdfParseFloatString(compValue)) then
                                   if(!capError  then                                                         
                                       estCompValue = cdfParseFloatString(compValue)*coeff
                                       totalCap = totalCap+estCompValue
                                   )
                                else
                                     capError=t
                                     totalCap = compValue
                                 
                                
                                )
                        )
                        if(capError then
                           estC = totalCap
                        else
                           estC = sprintf(nil "%L" totalCap)
                        )        
                     )
               )
         )
    )
)

procedure( layerOtherCond(@optional caller)
    	let(
             ((cdfId caller||cdfgData))
           
	   let(
               (
                   cdfDisp	        
             )
             if( cdfId->layer->value == "other"
              then
              cdfDisp = t
              else 
              cdfDisp = nil
             )
             
            cdfDisp
           
            )
    )
)

procedure( fdkCalcCompEnabled(@optional caller)
    	let(
             ((cdfId caller||cdfgData))
           
	   let(
               (
                 
		
                   cdfDisp
	        
             )
                       
                         
                        
             
             if( !cdfId->calcComp->value 
              then
              cdfDisp = nil
              else 
              cdfDisp = t
             )
             
            cdfDisp
           
            )
    )
)

procedure( displayCondOP(@optional caller)
    	let(
             ((cdfId caller||cdfgData))
        
	   let(
               (
                 
		
                   cdfOPDisp
	        
             )
                       
             if( cdfId->layer->value == "other" && cdfId->otherproperties->value
              then
              cdfOPDisp = t
              else 
              cdfOPDisp = nil
             )
           cdfOPDisp  
         )   
           
            
    )
)

procedure( mcfDisp(@optional caller)   
    	let(
             ((cdfId caller||cdfgData))
	   let(
               (                 		
                   mcfDisp	        
             )

             if( cdfId->ctotal->value
              then
              mcfDisp = t
              else 
              mcfDisp = nil
             )
             
            mcfDisp
           
            )
    )
)





procedure( layerNotOtherAndCtotCond(@optional caller)
    	let(
             ((cdfId caller||cdfgData))
	   let(
               (
                 
		
                   cdfDisp
	        
             )
                       
                         
                        
             
             if( cdfId->layer->value == "other" 
              then
              cdfDisp = nil
              else 
              cdfDisp = t
             )
             
            cdfDisp
           
            )
    )
)
procedure( ftSetCtot(@optional caller)
	  let(
             ((cdfId caller||cdfgData))  
	   let((
		  (cell case(cdfId->type
                	("cellData" cdfId->id->name)
                  	("instData" cdfId->id->cellName)
                  	(t warn("fdkCdfRint_metalCB: Cannot determine cell name from CDF type: %L\n" cdfId->type))
                      ) ; case
              	   ) ; cell
                    cellFirstLetterUC cellRemaining
                )                		
                   	        
         
		if(cdfId->ctotal->value
	  	then
			cdfId->mcf->value="1"
                        cdfId->cflag->value = ""
            		cdfId->cll_l->value = nil
	    		cdfId->cll_r->value = nil
            		cdfId->ctop->value = nil
            		cdfId->cbottom->value = nil
                else if(!(cdfId->cll_l->value || cdfId->cll_r->value || cdfId->ctop->value || cdfId->cbottom->value) then
                     			      cdfId->ctotal->value= t
		     			      cdfId->mcf->value="1"
                                              cdfId->cflag->value = ""
		     ) 
                
	  	)
          cellFirstLetterUC = upperCase(getchar(cell 1))
          cellRemaining=      substring(cell 2 strlen(cell)-1)
	  evalstring(sprintf(nil "fdkCdf%s%sCB()" cellFirstLetterUC cellRemaining))
	    
	)
     )
)

procedure( ftSetNonCtot(@optional caller)
	  let(
             ((cdfId caller||cdfgData))     
	   let(
               ((cell case(cdfId->type
                	("cellData" cdfId->id->name)
                  	("instData" cdfId->id->cellName)
                  	(t warn("fdkCdfRint_metalCB: Cannot determine cell name from CDF type: %L\n" cdfId->type))
                      ) ; case
              	   ) ; cell
                    cellFirstLetterUC cellRemaining)                 		
                   	        
         
		if((cdfId->cll_l->value || cdfId->cll_r->value || cdfId->ctop->value || cdfId->cbottom->value)
	  	then
			
            		cdfId->ctotal->value = nil
                else 
                        cdfId->ctotal->value= t
			cdfId->mcf->value="1"
                        cdfId->cflag->value=""
		     )
                if((cdfId->cll_l->value && cdfId->cll_r->value && cdfId->ctop->value && cdfId->cbottom->value)
                then
                        cdfId->ctotal->value= t
			cdfId->mcf->value="1"
                        cdfId->cflag->value=""
			cdfId->cll_l->value = nil
	    		cdfId->cll_r->value = nil
            		cdfId->ctop->value = nil
            		cdfId->cbottom->value = nil  
		) 
          cellFirstLetterUC = upperCase(getchar(cell 1))
          cellRemaining=      substring(cell 2 strlen(cell)-1)
	  evalstring(sprintf(nil "fdkCdf%s%sCB()" cellFirstLetterUC cellRemaining))
	    
	)
     )
)

procedure(fdkCdfFtLenMultUpdate(rctype @optional caller)
  let( ((cdfId caller||cdfgData))
  	let( (
      ;(cdfId caller||cdfgData)
		  (lib case(cdfId->type
                        ("cellData" cdfId->id->lib->name)
                        ("instData" cdfId->id->libName)
                        (t warn("fdkCdfRint_metalCB: Cannot determine cell name from CDF type: %L\n" cdfId->type))
                     ) ; case
              	) ; lib
		  (cell case(cdfId->type
                	("cellData" cdfId->id->name)
                  	("instData" cdfId->id->cellName)
                  	(t warn("fdkCdfRint_metalCB: Cannot determine cell name from CDF type: %L\n" cdfId->type))
                      ) ; case
              	) ; cell
             ; scale values
	   
	        ( scale_m2nm   1e9 )
	        ( scale_nm2m   1e-9 )
                ( scale_m2um   1e6 )
                
                cellId layer len multiplier                 
                grid grid_m gridu gridu_m  gridInM                
                widthInM minArea  minLforW minLforWInUm
                layerMinLUnit 
                defaults dRules dRulesString defaultM maxM  estR estC
                ; tfId 
             )
            cellId    = ddGetObj(lib cell)
            defaults = fdkGetPropTable(cellId  ?name "defaults" ?meters t)
            dRules=fdkGetPropTable(cellId  ?name "designRules")
            dRulesString=fdkGetPropTable(cellId  ?name "designRules" ?string t)
            layer= cdfId->layer->value
            grid =  defaults["minL"]
            gridu = defaults["l"]
            grid = grid * scale_m2nm
            gridu = gridu * scale_m2nm            
            grid_m = strcat(sprintf(nil "%f" grid) "n")
            gridu_m = strcat(sprintf(nil "%f" gridu) "n")
            defaultM = defaults["m"]
            defaultscaleR = defaults["scaleR"]  
            defaultscaleC = defaults["scaleC"]             
            maxM = defaults["maxM"]
            if(layer != "other" then
               layerMinLUnit = dRulesString["layers"][layer]["minL"]
               if(dRules["layers"][layer]["minArea"] == 'unbound then
                  cdfId->l->value = fdkAelEval(?entry cdfId->l->value  ?desc "Length" ?grid grid_m  ?aelSuffix t  ?noBlank t ?minimum layerMinLUnit ?maximum "1" ?default layerMinLUnit)
               )
               if(dRules["layers"][layer]["minArea"] != 'unbound then
                  minArea = dRules["layers"][layer]["minArea"]
                  widthInM = cdfParseFloatString( cdfId->w->value) 
                  minLforW = minArea/widthInM
                  gridInM = grid*scale_nm2m
                  minLforW = fdkSnapUpEpsilonGrid(gridInM minLforW)
                  minLforWInUm = minLforW*scale_m2um
                  minLforWInUm = strcat(sprintf(nil "%L" minLforWInUm) "u")
                  cdfId->l->value = fdkAelEval(?entry cdfId->l->value  ?desc "Length for the width entered" ?grid grid_m  ?aelSuffix t  ?noBlank t ?minimum minLforWInUm ?maximum "1" ?default minLforWInUm)                                     
                )
             else 
                cdfId->l->value = fdkAelEval(?entry cdfId->l->value  ?desc "Length" ?grid grid_m  ?aelSuffix t  ?noBlank t ?minimum grid_m ?maximum "1" ?default gridu_m)
             )          
	    cdfId->m->value =  fdkAelEval(?entry cdfId->m->value  ?desc "Multiplier"  ?grid defaultM  ?aelSuffix t ?noBlank t ?minimum defaultM ?maximum maxM ?default defaultM)
            if(rexMatchp("Res" rctype) then
              ;scaler
              cdfId->scaler->value =  fdkAelEval(?entry cdfId->scaler->value  ?desc "Resistance Scaling Factor"  ?aelSuffix t ?noBlank t ?minimum 1e-9 ?default defaultscaleR)
            )
            if(rexMatchp("Cap" rctype) then
             ;scalec 		  
	      cdfId->scalec->value =  fdkAelEval(?entry cdfId->scalec->value  ?desc "Capacitance Scaling Factor"  ?aelSuffix t ?noBlank t ?minimum 1e-9 ?default defaultscaleC) 
            ) 
            if(cdfId->calcComp->value 
                 fdkFtUpdateRC(rctype cdfId)
            )
     )
  )
)

procedure( fdkFtUpdateRC(rctype @optional caller)
   let( ((cdfId caller||cdfgData))
  	let( ( len multiplier estR estC multiplierScaleR multiplierScaleC)
           len = cdfParseFloatString(cdfId->l->value)
           multiplier = cdfParseFloatString(cdfId->m->value)
           if(rexMatchp("Res" rctype) then
              estR = cdfParseFloatString(cdfId->estRperUnitL->value)
              scaleR = cdfParseFloatString(cdfId->scaler->value)
              cond(
                  ((numberp scaleR) && (numberp multiplier)
                     multiplierScaleR = multiplier/scaleR
                   )
                   (!(numberp scaleR) && (numberp multiplier)
                       multiplierScaleR = sprintf(nil "(%L/(%s))"  multiplier scaleR)
                    )
                   ((numberp scaleR) && !(numberp multiplier)
                       multiplierScaleR = sprintf(nil "((%s)/%L)"  multiplier scaleR)
                    )
                    (!(numberp scaleR) && !(numberp multiplier)
                       multiplierScaleR = sprintf(nil "((%s)/(%s))"  multiplier scaleR)
                    )
                )
              cond(
                  (estR == "capexec missing" || estR == "Value not available"
                       cdfId->estR->value= estR
                       
                   ) 
                  (numberp(len) && numberp(multiplierScaleR)
                      cdfId->estR->value= sprintf(nil "%L" (estR/multiplierScaleR)) 
                       
                   )
                  (numberp(len) && !numberp(multiplierScaleR)
                      cdfId->estR->value= sprintf(nil "%L/(%s)" (estR) multiplierScaleR) 
                       
                   ) 
                  (!numberp(len) && numberp(multiplierScaleR)
                      cdfId->estR->value= sprintf(nil "%L*(%s)" (estR/multiplierScaleR) len) 
                      
                   )
                  (!numberp(len) && !numberp(multiplierScaleR)
                      cdfId->estR->value= sprintf(nil "%L*(%s)/(%s)" estR len multiplierScaleR) 
                          
                   )
               )
           )
           if(rexMatchp("Cap" rctype) then
             ;scalec 		  
	      cdfId->scalec->value =  fdkAelEval(?entry cdfId->scalec->value  ?desc "Capacitance Scaling Factor"  ?aelSuffix t ?noBlank t ?minimum 1e-9 ?default defaultscaleC) 
              estC = cdfParseFloatString(cdfId->estCperUnitL->value)
              scaleC = cdfParseFloatString(cdfId->scalec->value)
              cond(
                  ((numberp scaleC) && (numberp multiplier)
                    multiplierScaleC = multiplier*scaleC
                   )
                   (!(numberp scaleC) && (numberp multiplier)
                      multiplierScaleC = sprintf(nil "(%L*(%s))"  multiplier scaleC)
                   )
                   ((numberp scaleC) && !(numberp multiplier)
                       multiplierScaleC = sprintf(nil "((%s)*%L)"  multiplier scaleC)
                   )
                   (!(numberp scaleC) && !(numberp  multiplier)
                       multiplierScaleC = sprintf(nil "((%s)*(%s))"   multiplier scaleC)
                   )
             )
              cond(
                  (estC == "capexec missing" || estC == "Value not available"
                       cdfId->estC->value= estC
                   ) 
                  (numberp(len) && numberp(multiplierScaleC)
                      cdfId->estC->value= sprintf(nil "%L" (estC*multiplierScaleC))   
                   )
                  (numberp(len) && !numberp(multiplierScaleC)
                      cdfId->estC->value= sprintf(nil "%L*(%s)" (estC) multiplierScaleC)   
                   ) 
                  (!numberp(len) && numberp(multiplierScaleC)
                      cdfId->estC->value= sprintf(nil "%L*(%s)" (estC*multiplierScaleC) len)    
                   )
                  (!numberp(len) && !numberp(multiplierScaleC)
                      cdfId->estC->value= sprintf(nil "%L*(%s)*(%s)" estC len multiplierScaleC)    
                   )
               )
           )
                        
         
         
        )
     )
)


procedure( fdkCdfDefLenCB(@optional caller)
         
    
    	let(
             ((cdfId caller||cdfgData))
           
	   let(
               (
		(lib case(cdfId->type
                        ("cellData" cdfId->id->lib->name)
                        ("instData" cdfId->id->libName)
                        (t warn("fdkCdf_rmetalCB: Cannot determine cell name from CDF type: %L\n" cdfId->type))
                     ) ; case
              	) ; lib
		(cell case(cdfId->type
                	("cellData" cdfId->id->name)
                  	("instData" cdfId->id->cellName)
                  	(t warn("fdkCdf_rmetalCB: Cannot determine cell name from CDF type: %L\n" cdfId->type))
                      ) ; case
              	) ; cell
               (scale_um2nm 1e3)
               cellId layer dRules
               defLen defLeninNm minWidth color
	        
             )
             
             cellId   = ddGetObj(lib cell)
           
             layer     = cdfId->layer->value
             color     = get(cdfId strcat("cSelect_" layer))~>value
             dRules=fdkGetPropTable(cellId  ?name "designRules")
             
             cond(
                 (color 
                    minWidth = dRules["layers"][layer][color]["minWidth"]
                 )
                 (t
                    minWidth = dRules["layers"][layer]["minWidth"]
                 )
             ) 
             defLen = minWidth/2
             defLeninNm = defLen*scale_um2nm
             defLeninNm = strcat(sprintf(nil "%L" defLeninNm) "n")
             cdfId->l->value = defLeninNm
             cond( 
                 ((cell == "rmetal")
                  fdkCdf_rmetalCB())
                 ((cell== "rpoly")
                  fdkCdf_rpolyCB())
               )
            
             
           ); let
      
     ); let
         
   ) ; procedure

procedure( fdkCdf_lvsPrefDirDisp(@optional caller)
         
    
    	let(
             ((cdfId caller||cdfgData))
           
	   let(
               (
		(lib case(cdfId->type
                        ("cellData" cdfId->id->lib->name)
                        ("instData" cdfId->id->libName)
                        (t warn("fdkCdf_rmetalCB: Cannot determine cell name from CDF type: %L\n" cdfId->type))
                     ) ; case
              	) ; lib
		(cell case(cdfId->type
                	("cellData" cdfId->id->name)
                  	("instData" cdfId->id->cellName)
                  	(t warn("fdkCdf_rmetalCB: Cannot determine cell name from CDF type: %L\n" cdfId->type))
                      ) ; case
              	) ; cell
               cellId layer dRules
	        
             )
             
             cellId   = ddGetObj(lib cell)
           
             layer     = cdfId->layer->value 
            if(layer == "other"
            then 
            nil
            else 
            dRules=fdkGetPropTable(cellId  ?name "designRules")
            dRules["layers"][layer]["allowNonPreferredDirection"]
            ) 
           ); let
      
     ); let
         
   ) ; procedure

procedure( fdkCdf_WEditCond(@optional caller)
         
    
    	let(
             ((cdfId caller||cdfgData))
           
	   let(
               (
		(lib case(cdfId->type
                        ("cellData" cdfId->id->lib->name)
                        ("instData" cdfId->id->libName)
                        (t warn("fdkCdf_rmetalCB: Cannot determine cell name from CDF type: %L\n" cdfId->type))
                     ) ; case
              	) ; lib
		(cell case(cdfId->type
                	("cellData" cdfId->id->name)
                  	("instData" cdfId->id->cellName)
                  	(t warn("fdkCdf_rmetalCB: Cannot determine cell name from CDF type: %L\n" cdfId->type))
                      ) ; case
              	) ; cell
               cellId layer dRules WEditCond color colorParamId wChoices
	        
             )
             
             cellId   = ddGetObj(lib cell)            
             layer     = cdfId->layer->value
             colorParamId = strcat("cSelect_" layer)
             dRules=fdkGetPropTable(cellId  ?name "designRules")
             color  =  cdfFindParamByName(cdfId colorParamId)~>value              
             if(layer == "other"
             then
              WEditCond = t
             else
              cond(
                  (color 
                      wChoices = dRules["layers"][layer][color]["preferredWidthChoices"]
                  )
                  (!color
                      wChoices = dRules["layers"][layer]["preferredWidthChoices"]
                  )
              )
              if( !wChoices 
               then
               WEditCond = t
               else
               WEditCond = nil
               )
              )
             
            WEditCond
      )
   )
)

procedure( fdkCdf_colorDispCond(layerCurr @optional caller)
         
    
    	let(
             ((cdfId caller||cdfgData))
           
	   let(
               (
                 
		
               userLayer  colorDispCond 
	        
             )
                       
             userLayer  = cdfId->layer->value
             
             
             colorDispCond = nil 
             if( (userLayer == layerCurr)
              then
              colorDispCond = t
                 )
             colorDispCond
            
           
            )
    )
)

procedure( fdkCdf_WChoiceDispCond(wName checkColor @optional caller)
    	let(
             ((cdfId caller||cdfgData))           
	   let(
               (
               userDir userLayer userColor paramDir paramLayer paramColor color WDispCond wNameParsed
	        
             )                       
             userLayer  =  cdfId->layer->value
             userDir    =  cdfId->preferredDirection->value
             color = strcat("cSelect_" userLayer)
             userColor  =  cdfFindParamByName(cdfId color)~>value
             wNameParsed =  parseString(wName "_")
             paramLayer = nth(1 wNameParsed)                
             cond(
                  (checkColor
                     paramColor = nth(2 wNameParsed)
                     paramDir = nth(3 wNameParsed)
                     if(equal(paramColor "nonColor")
                        paramColor = nil 
                     )              
                  )
                  (t
                     paramDir = nth(2 wNameParsed)                       
                     paramColor = nil
                   )
              )             
             if( userDir
              then
              userDir = "pref" 
              else 
              userDir = "nonPref"
             )
             WDispCond = nil 
             if( (userLayer == paramLayer) &&(userDir == paramDir) && (userColor == paramColor)
              then
              WDispCond = t
                 )
              WDispCond
            
           
            )
    )
)

 
