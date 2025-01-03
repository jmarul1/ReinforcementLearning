;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Intel Confidential                                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Copyright (C) 2014, Intel Corporation.  All rights reserved.             ;;
;;;                                                                          ;;
;;; This is the property of Intel Corporation and may only be utilized       ;;
;;; pursuant to a written Restricted Use Nondisclosure Agreement             ;;
;;; with Intel Corporation.  It may not be used, reproduced, or              ;;
;;; disclosed to others except in accordance with the terms and              ;;
;;; conditions of such agreement.                                            ;;
;;;                                                                          ;;
;;; All products, processes, computer systems, dates, and figures            ;;
;;; specified are preliminary based on current expectations, and are         ;;
;;; subject to change without notice.                                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Filename: fdkMtpViaColorUtils.il
;;
;; Description: Various functions related to via coloring 
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure(fdkMptSetMetalViaColorDefaults()
  let((techLibName tfId)

      ;TODO: get the list of colorable vias and metal layers from the tech file 

      techLibName = "intel22tech"
      tfId =  techGetTechFile(ddGetObj( techLibName))

      ;cond( 
      ;  ( rexMatchp( "ICADV12.2-64b.2" getVersion(t))
      ;      ; Note: was supposed to use the mptSetLayerDefaultColor function
      ;      ;       however this is not yet enabled in LA2
          ; vias
      if(isCallable('dptSetLayerDefaultColor) then
          dptSetLayerDefaultColor(tfId "v1" "mask1Color")
          dptSetLayerDefaultColor(tfId "v2" "mask1Color")
          dptSetLayerDefaultColor(tfId "v3" "mask1Color")
          ;metals
          dptSetLayerDefaultColor(tfId "m0" "mask1Color")
          dptSetLayerDefaultColor(tfId "m2" "mask1Color")
          dptSetLayerDefaultColor(tfId "m3" "mask1Color")
          dptSetLayerDefaultColor(tfId "m4" "mask1Color")
          dptSetLayerDefaultColor(tfId "m5" "mask1Color")
      ;  ) 
      ;  ( rexMatchp( "ICADV12.2-64b.1" getVersion(t))
      ;    ; vias
      ;    dptSetLayerDefaultColor(tfId "v1" "mask1Color")
      ;    dptSetLayerDefaultColor(tfId "v2" "mask1Color")
      ;    dptSetLayerDefaultColor(tfId "v3" "mask1Color")
      ;    ;metals
      ;    dptSetLayerDefaultColor(tfId "m0" "mask1Color")
      ;    dptSetLayerDefaultColor(tfId "m2" "mask1Color")
      ;    dptSetLayerDefaultColor(tfId "m3" "mask1Color")
      ;    dptSetLayerDefaultColor(tfId "m4" "mask1Color")
      ;    dptSetLayerDefaultColor(tfId "m5" "mask1Color")
      ;  )
      ;)

          (printf "-I-: fdkMptSetMetalViaColorDefaults: Default metal and via color set\n")
      else
          (printf "-I-: fdkMptSetMetalViaColorDefaults: Default metal and via color NOT set because dptSetLayerDefaultColor not available in this tool.\n")
           
      )

  )
)

;load the function to set the default via colors
;fdkMptSetMetalViaColorDefaults()


procedure(fdkMptSetEntryLayerColor(color)
	prog( (entryLayer retVal cv)
		entryLayer = car(leGetEntryLayer())
		cv = geGetEditCellView()
		if(techGetLayerNumColorMasks(techGetTechFile(cv) entryLayer) == nil then
			return(nil)
		)
		if(!isCallable('dptSetLayerDefaultColor) then
			return(nil)
		)
		case(color
			("grayColor" || "mask1Color" || "mask2Color" || "mask3Color"
				dptSetLayerDefaultColor(entryLayer color)
				retVal = t
			)
			("entryColor"
				dptSetLayerDefaultColor(entryLayer dptGetLayerDefaultColor(entryLayer))	
				retVal = t
			)
			(t 
				printf("Warning: Invalid color specified for entry layer")
				retVal = nil
			)
		)
		return(retVal)
	)
)

procedure(fdkMptSetColorForSelectedObjects(color)
	prog( (obj modCount nonViaFlag)
		modCount = 0
		nonViaFlag = nil
		foreach(obj geGetSelSet() 
			case(obj~>objType
				("inst" nil)
				("stdVia" || "customVia"
					modCount = modCount + 1
					fdkMptSetViaColorShift(obj color)
				)

				(t
					nonViaFlag = t
				)
			)
		)
		
		;geDeselectAll()
		
		if(modCount > 0 then
		     printf("Info: Updated color for %d via(s)\n" modCount)
			hiRedraw()
			return(t)
		else
		;no via shapes are selected
		 when(nonViaFlag
		   printf("Info: Only via color can be changed \n")
		  )
			return(nil)
		)
	)
)

procedure(fdkMptSetViaColorShift(viaId color)
	prog( (layer1Control layer2Control cutControl)
		case(color
			("grayColor" || "mask1Color" || "mask2Color" || "mask3Color" 
				cutControl = fdkMptGetControlFromColor(color)
				layer1Control = fdkMptGetControlFromColor(color)
				layer2Control = fdkMptGetControlFromColor(color)

			)
			("entryColor"
				cutControl = fdkMptGetViaLayerDefaultControl(viaId "cutLayer")
				layer1Control = fdkMptGetViaLayerDefaultControl(viaId "layer1")
				layer2Control = fdkMptGetViaLayerDefaultControl(viaId "layer2")
			)
			(t 
				cutControl = nil
				layer1Control = nil
				layer2Control = nil
			)
			if(envGetVal("dpt" "cutLayerDefaultSameAsTopLayer") == t then
				cutControl = layer2Control
			)
		)
		if(layer1Control == nil || layer2Control == nil || cutControl == nil  then
			return(nil)
		)
		;dbSetViaLayer1Control(viaId layer1Control)	
		;dbSetViaLayer2Control(viaId layer2Control)	
		dbSetViaCutLayerControl(viaId cutControl)
		hiRedraw()
		return(t)
	)
)

procedure(fdkMptGetViaLayerDefaultControl(via layer)
	prog( (viaLayer)
		case(layer
			("layer1"
				viaLayer = via~>viaHeader~>viaDef~>layer1~>name
			)
			("layer2"
				viaLayer = via~>viaHeader~>viaDef~>layer2~>name
			)
			("cutLayer"
				if(via~>objType == "stdVia" then
					viaLayer = car(via~>viaHeader~>viaDef~>params)
				else
					viaLayer = nil
				)
			)
			(t viaLayer = nil)
		)

		if(viaLayer == nil then
			color = "grayColor"
		else
		    if(isCallable('dptSetLayerDefaultColor) then
			    color = dptGetLayerDefaultColor(viaLayer)
            else
                color = "grayColor"
		    )
		)

		control = fdkMptGetControlFromColor(color)

		return(control)
	)
)

procedure(fdkMptGetControlFromColor(color)
	prog( (control)
		case( color
			("grayColor" control = "noColor")
			("mask1Color" control = "noShift")
			("mask2Color" control = "shift1")
			("mask3Color" control = "shift2")
			(t control = "noColor")
		)
		return(control)
	)
)

;hiSetBindKey("Layout" "Shift<Key>0" "fdkMptSetEntryLayerColor(\"grayColor\")")
;hiSetBindKey("Layout" "Shift<Key>1" "fdkMptSetEntryLayerColor(\"mask1Color\")")
;hiSetBindKey("Layout" "Shift<Key>2" "fdkMptSetEntryLayerColor(\"mask2Color\")")
;hiSetBindKey("Layout" "Shift<Key>3" "fdkMptSetEntryLayerColor(\"mask3Color\")")

;hiSetBindKey("Layout" "Ctrl<Key>0" "fdkMptSetColorForSelectedObjects(\"grayColor\")")
;hiSetBindKey("Layout" "Ctrl<Key>1" "fdkMptSetColorForSelectedObjects(\"mask1Color\")")
;hiSetBindKey("Layout" "Ctrl<Key>2" "fdkMptSetColorForSelectedObjects(\"mask2Color\")")
;hiSetBindKey("Layout" "Ctrl<Key>3" "fdkMptSetColorForSelectedObjects(\"mask3Color\")")
;hiSetBindKey("Layout" "Ctrl<Key>9" "fdkMptSetColorForSelectedObjects(\"entryColor\")")
