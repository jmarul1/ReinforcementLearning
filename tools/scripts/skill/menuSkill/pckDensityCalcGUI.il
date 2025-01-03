;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;NAME
;;      pckCalculateLocalLayerDensityForm
;;
;;SYNOPSIS
;;      pckCalculateLocalLayerDensityForm()
;;
;;DESCRIPTION
;;      Calculates the density of all layers in layerList in a given area
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; (load "pckDensityCalcGUI.il")
;;
(defun pckCalculateLocalLayerDensityForm ( )
  (let (layerList densityForm layerFields useBBox text fieldflt layersel 
                   fieldDefault useBBox fltprompt selectButtons xf y yf pckDensityForm)

	(setq layerList (list "nwell" "ndiff" "exposed ndiff" "pdiff" "exposed pdiff" "drawn diff" "poly" "gcn" "tcn" "vcn" "m0" "v0" "m1" "v1" "m2" "v2" "m3" "v3" "m4" "v4" "m5" "v5" "m6" "v6" "m7" "v7" "m8" "v8" "m9" "v9" "m10" "v10" "m11" "v11" "m12" ))

    (setq layerFields nil)
    
    xf = 110
    y = 5
    yf = 50
    
   
    (setq selectButtons  ( hiCreateButtonBoxField 
                           ?name 'selectButtons
                           ?choices (list "ALL" "NONE")
                           ?callback (list "pckSelectLayersCB( pckDensityForm layerList t)"
                                           "pckSelectLayersCB( pckDensityForm layerList nil)")
                           ?prompt "Select Layers"
                           ))
    



    (setq text (hiCreateMLTextField
                ?name 'text
                ?value "Please select the layer you want to find the density for from the list below. \n"
                ?enableWordWrap t
                ?editable nil                
                ) )
    (setq layerFields (cons (list text 0:5 600:yf) layerFields))
    

    y=y + yf
    yf=40
    y = y + yf
    (setq layerFields cons((list selectButtons 390:y 81:yf 80) layerFields))
   
    y= y + yf
;;; adding BBox functionality back ;;;
    (setq useBBox (hiCreateBooleanButton
                  ?name 'useBBox
                  ?buttonText "Calculate for entire bBox?"
                  ?defValue nil
                  ?enabled t ))

    (setq layerFields cons((list useBBox 0:60 545:yf) layerFields))
   
    (foreach layer layerList
			 ;;(fprintf stdout "Layer: %L\n" layer)
             (setq fltprompt layer)

             (setq fieldflt (concat layer "value"))
             (setq fieldflt (hiCreateFloatField
                             ?name fieldflt
                             ?prompt fltprompt
                             ?acceptNil t
                             ?format "%.2f percent"
                             ?defValue nil
                             ?editable t))
    
             (setq layerFields cons((list fieldflt 0:y 500:yf xf) layerFields))

             (setq layersel (stringToSymbol layer))
             (setq fieldDefault t)

             (setq layersel (hiCreateBooleanButton
                             ?name layersel
                             ?buttonText " "
                             ?defValue fieldDefault
                             ?enabled t)  )
                       
             (setq layerFields cons((list layersel 510:y 11:yf 10) layerFields))
             
             y = y + yf
    
             ) ;; end of foreach    
  
    (setq layerFields reverse( layerFields ))
    (pckInfo "pckCalculateDensityInBBox" "Please Select the BBox from the layout After hitting Apply\n")
    (setq pckDensityForm (hiCreateAppForm
                          ?name 'pckDensityForm
                          ?fields  layerFields
                          ?formTitle "Calculates local density"
                          ?callback (list "pckCalculateDensityInBBox( (geGetEditCellView) pckDensityForm layerList )")
                          ?unmapAfterCB  t
                          )
          )

    (hiDisplayForm 'pckDensityForm )
    t
    ) ;; let
  )   ;; end of fn



;; ******************************************
;;; Callback for selecting/deselecting layers ;;;
;; ******************************************
(defun pckSelectLayersCB (form layerList action)
  (let (fieldName layersel)
 
  (sprintf nil "form=%L action=%L" form action)
    
  (foreach layer layerList
           (setq layersel (stringToSymbol layer))         
           (setq fieldName (sprintf nil "form->%L->value = action" layersel))
           (evalstring fieldName)
           )

  ) ;; end of let

  ) ;; end of fn

;;***********************************************
;;; Callback for density for the selective layer 
;;***********************************************
(defun pckCalculateDensityInBBox (cv daForm layerList)
  (prog (pnts field density LppVisible Lpp3 area layerSelected
         outFileName fp fieldName totalTime)
  (setq Lpp3 list( "text" "drawing"))
  (pckInfo "pckCalculateDensity" "Started")
  (setq totalTime
;;; return a list of 4 number only 3rd one tells the total elapsed time
       (nth 2 
            (measureTime 
            (setq libName cv~>libName)
            (setq cellName cv~>cellName)
            
  (if daForm->useBBox->value
	  (progn 
		(setq pnts cv~>bBox))
    (progn 
	  (setq pnts (enterBox
				  ?prompts list("Enter the first corner of your box."
								"Enter the last corner of your box.")
				  )))
  ) ;; end of if
  ;; Clearing all, After hitting Apply 
 (foreach layer layerList
  (setq field get(daForm (concat layer "value") ))
       field->value=nil
   
  ) 
  
   

   (setq outFileName sprintf(nil "/tmp/%s_LocalDensity.txt" cv~>cellName))
   (setq  fp outfile( outFileName))
    (when fp (fprintf fp "Layer\tDensity\tLayer Area\n")) 
	(foreach layer layerList
			 (setq fieldName sprintf(nil "daForm->%L->value" layer))
			 (setq layerSelected evalstring(fieldName))    
			 (setq area pckGetShapesArea(list(pnts)))
			 ;;(pckInfo "pckCalculateDensityInBBox" (sprintf nil "Checking layer %s" layer))			 
             (when pnts && layerSelected
				   (cond 
					((equal layer "exposed ndiff")
					 (setq density (pckGetExposedDiffusionDensity cv "ndiff" pnts)))
					((equal layer "exposed pdiff")
					 (setq density (pckGetExposedDiffusionDensity cv "pdiff" pnts)))
					((equal layer "diffcon")
					 (setq density (pckGetUpsizedContactDensity cv pnts)))
					((equal layer "total contact")
					 (setq density (pckGetContactDensity cv pnts)))
					((equal layer "drawn diff")
					 (setq density (pckGetDensity pnts (list "ndiff" "drawing" ) cv)+ (pckGetDensity pnts (list "pdiff" "drawing" ) cv)))
					(t
					 ;;(fprintf stdout "%L\n" layer)
					 (setq density (pckGetDensity pnts (list layer "drawing" ) cv))))
				   (pckInfo "pckCalculateDensityInBBox" (sprintf nil "Checking:: layer %s density %L" layer density))
				   ;;(fprintf stdout "-D- %L %14s %6.2f percent; Layer area=%.2f\n" pnts (stringToSymbol layer) density*100 area*density)
				   
				   (setq field (get daForm (concat layer "value") ))
				   field->value = density*100 
				   
				   (when fp (fprintf fp "%L\t%5.2f\t%5.2f \n" layer density*100 area*density))				   
				   ) ;; end of if of pnts and layerSelected 
     
         ) ;; end of foreach
 ))
   ) ;;; total time

(when fp (fprintf fp "Total Elapsed Time to Calculate Density is %L seconds\n" totalTime))

(when fp (close fp))
(when (isReadable outFileName) (view outFileName))

  
(leSetLayerVisible Lpp3 LppVisible)   
   return(t)
   )

)



      
