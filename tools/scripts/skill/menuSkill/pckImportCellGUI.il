;;
;; (load "pckImportCellGUI.il")
;; (pckImportCellForm)
(defun pckImportCellForm ()
  (let (y (step 0) stepField statusField field_list field_list2 importGuiForm importColFormTabs
          (infoImportFlow
			(hiCreateLabel
			 ?name 'infoFillerFlow
			 ?labelText "Import collateral flow - by Chinmay Joshi and Pavel Rott"))
          (cn (hiCreateStringField
				?name 'cn
				?prompt "Cell"
				?defValue (geGetEditCellView)~>cellName
				?editable t))
          (ln (hiCreateStringField
				?name 'ln
				?prompt "Library"
				?defValue (geGetEditCellView)~>libName
				?editable t))
          
          (numTerminals (hiCreateCyclicField
						 ?name 'numTerminals
						 ?prompt "Number of terminals"
						 ?choices (list "1" "2" "3" "4" "5" "6" "7" "8")
						 ?defValue "1"
						 ?enabled t
						 ))
          (layer (hiCreateStringField
				?name 'layer
				?prompt "Layer"
				?defValue "metal1"
				?editable t))
          instructionField
          (pickPinDim
           (hiCreateCyclicField
			 ?name 'pickPinDim
			 ?prompt "Use pin width"
			 ?choices (list "yes" "no")
			 ?defValue "yes"
			 ?callback "(pckSelectPinMethodGUI importGuiForm)"
			 ?enabled  t))
          (pinWidth (hiCreateFloatField
				?name 'pinWidth
				?prompt "Pin Width"
				?defValue 1.0
				?editable t))
          (pinNumber (hiCreateIntField
				?name 'pinNumber
				?prompt "Number of metal lines in pin"
				?defValue 5
				?editable nil))
          (pinHeight (hiCreateFloatField
				?name 'pinHeight
				?prompt "Pin Height"
				?defValue 0.1
				?editable t))
          (pinOrient (hiCreateBooleanButton
                      ?name 'pinOrient
                      ?buttonText "Vertical"
                      ?value t
                      ?defValue t
                      ;;?callback "pckEnableFillerFlowForm( pdsForm )"
                      ?enabled  t))
          (prev (hiCreateButton
                 ?name ?prev
                 ?buttonText "Back"
                 ;;?callback "foo
                 ?enabled t))
          (next (hiCreateButton
                 ?name ?next
                 ?buttonText "Next"
                 ;;?callback "foo
                 ?enabled t))
          (sep1 (hiCreateSeparatorField ?name 'sep1 ) )
          (sep2 (hiCreateSeparatorField ?name 'sep2 ) )
          (sep3 (hiCreateSeparatorField ?name 'sep3 ) )
          (sep4 (hiCreateSeparatorField ?name 'sep4 ) )
          (sep5 (hiCreateSeparatorField ?name 'sep5 ) )
          (sep6 (hiCreateSeparatorField ?name 'sep6 ) )
          (sep7 (hiCreateSeparatorField ?name 'sep7 ) )
          (sep8 (hiCreateSeparatorField ?name 'sep8 ) )
          (sep9 (hiCreateSeparatorField ?name 'sep9 ) )
          )
    (setq stepField
          (hiCreateLabel
           ?name 'stepField
           ?labelText (get_pname (concat "Step " step))           
           ))
    (setq statusField
          (hiCreateLabel
           ?name 'statusField
           ?labelText "Select cell to import"
           ))
    (setq instructionField
          (hiCreateMLTextField
           ?name 'instructionField
           ?prompt "Instructions"
           ?value (sprintf nil "Step %d. \nPlease provide cell and library name. Select number of terminal. \nThen click \"Apply\" button." step)
           ;;[?defValue t_defaultValue] 
           ;; [?font t_font] 
           ;;?hasVerticalScrollbar g_hasVerticalScrollbar
           ?hasHorizontalScrollbar nil
           ?enableWordWrap t
           ?editable nil))
    
    ;;
    ;; map out the form
    (setq y 5)
    (setq field_list (tconc field_list (list sep1 0:y 500:0) ))
    (setq y (plus y 5))

    ;;
    ;; select cell
    (setq field_list (tconc field_list (list cn 0:y 180:30 80) ))
	(setq field_list (tconc field_list (list ln 200:y 250:30 80) ))
    (setq y (plus y 35))
    (setq field_list (tconc field_list (list numTerminals 0:y 500:30 150)))
    (setq y (plus y 35))
    (setq field_list (tconc field_list (list instructionField 0:y 500:80 150)))
    ;;
    ;; little counter here
    (setq y (plus y 85))
    (setq field_list (tconc field_list (list sep2 0:(plus 15 y) 50:0)))
    (setq field_list (tconc field_list (list stepField 15:y 75:30)))
    (setq field_list (tconc field_list (list statusField 85:y 200:30)))
    (setq field_list (tconc field_list (list sep3 220:(plus 15 y) 280:0)))
    ;;
    (setq y (plus y 35))
    (setq field_list (tconc field_list (list layer 0:y 500:30 200) ))
    (setq y (plus y 35))
    (setq field_list (tconc field_list (list pinOrient 0:y 500:30 200) ))
    (setq y (plus y 35))
    (setq field_list (tconc field_list (list pickPinDim 0:y 500:30 200) ))
    (setq y (plus y 35))
    (setq field_list (tconc field_list (list pinWidth 0:y 500:30 200) ))
    (setq y (plus y 35))
    (setq field_list (tconc field_list (list pinNumber 0:y 500:30 200) ))
    (setq y (plus y 35))
    (setq field_list (tconc field_list (list pinHeight 0:y 500:30 200) ))
    
    (setq field_list (car field_list))
    
    ;;**********************************************************************
	;;
	;; Second Tab
	;;
	;;**********************************************************************
	(setq y 5)
	(setq field_list2 (tconc field_list2 (list sep2 5:y 500:0)))
	(setq y (plus y 5))
    (setq field_list2 (tconc field_list2 (list infoImportFlow 5:y 500:30)))
    (setq y (plus y 5))
    (setq field_list2 (tconc field_list2 (list sep3 5:y 500:0)))
    (setq field_list2 (car field_list2))

    ;;(fprintf stdout ">> field info: %L\n" sep1->??)
    ;;(fprintf stdout ">>> field_list %L\n>>>+ field_list2 %L\n" field_list field_list2)
    (setq importColFormTabs (hiCreateTabField
					 ?name 'importColFormTabs
					 ?fields (list field_list field_list2)
                     ;;?fields (list field_list )
					 ?tabs list( "Import" "Options")
					 ?tabPlacement 'top
					 ?value 1 ) )
    
    (setq importGuiForm (hiCreateAppForm
					 ?name 'importGuiForm
					 ?formTitle "TCC Collateral Import Wizard"
					 ?callback (list "(pckStartCollateralImportOKCB importGuiForm step)" )
;;					 ?fields list( sep1  boundaryCheck 
;;										 sep2 cn ln fcns fln tcn tln pcn pln
;;										 sep3 flowName cellName libName )
                     ?fields field_list
					 ;;?fields (list (list importColFormTabs 0:0 500:280) ) ;; 330
					 ?initialSize t
                     ?buttonLayout (list 'ApplyCancel (list 'Back 'pckImportFormBackCB) (list 'Next 'pckImportFormNextCB))
					 ?unmapAfterCB  t
					 )
		   )
    (hiDisplayForm importGuiForm)
    )
  )

(defun pckStartCollateralImportOKCB (zeForm step)
  (let ((fieldInfo (zeForm->fieldList)) cv edit)
    (pckInfo "pckStartCollateralImport" "started.")
    (pckInfo "pckStartCollateralImport" (sprintf nil  "Opened fields: %L Step: %L\n" zeForm->? step))    

	 (sscanf zeForm->stepField->value "Step %d" step)

	 (if (equal step 0) 
	 	;;zeForm->stepField->value = (get_pname (concat "Step " (add1 step)))
	 	
		;;(if (equal (dbFindOpenCellView zeForm->ln->value  zeForm->cn->value "layout") nil) then
		(progn
			edit=(geOpen
			;;?window hiGetCurrentWindow( ) 
			?lib zeForm->ln->value
			?cell zeForm->cn->value
			?view "layout" 
			;;?viewType "maskLayout" 
			?mode "a"
			)
			
		;;else 
		;;t
		;;)
		;;cv = geGetEditCellView
		;;cv = dbOpenCellViewByType(zeForm->ln->value  zeForm->cn->value "layout")
		;;(fprintf stdout "\n THE PARAMETER cellView IS %L" cv)
		
		(if (equal edit nil)
		(progn
			 zeForm->instructionField->value = (sprintf nil "Step %d. CANNOT OPEN THE CELL IN EDIT MODE." step)
		)
		(progn
          zeForm->numTerminals->enabled = nil
			 zeForm->instructionField->value = (sprintf nil "Step %d. \nPlease click \"Next\" button to continue." step)
		)
		)
					 	
    ) 
		;;(fprintf stdout "\n THE PARAMETER cellView IS %L" cv)	
		
	(progn
			cv = dbOpenCellViewByType(zeForm->ln->value  zeForm->cn->value "layout") 
			zeForm->instructionField->value = (sprintf nil "Step %d. \nPlease left-click the mouse button on the \"Lower-Left\" point to place the Pin.\nWhen satisfied, then click \"Next\" button to coninue." step)
		 	
				
		(pckDefinePin
			cv
			?pinName (sprintf nil "T%d" step)
			?layer zeForm->layer->value
			?vertOrient zeForm->pinOrient->value
			?PinWidth zeForm->pinHeight->value
			?isLength (if (equal zeForm->pickPinDim->value "yes") t nil)
			?PinLength zeForm->pinWidth->value
			?PinNumber zeForm->pinNumber->value
			?PinOrigin (enterPoint
             			?prompts       list("LEFT CLICK at LowerLeft Point of the PIN")
             			;;?form          form
             			?doneProc     "pckCoordPin"
             			;;?alwaysMap     t
      					)
		)
		
	
	  )
	  )
	 
	 (pckRedrawImportForm zeForm)

	 t
    )
  )
(defun pckSelectPinMethodGUI (zeForm)
  "This function enables defintion of pin width either through pin width or through number of metal lines."
  (let ()
    (pckInfo "pckSelectPinMethodGUI" (sprintf nil "Field value: pinWidth %L pinNumber %L\n" zeForm->pinWidth->value zeForm->pinNumber->value))
    (if (equal zeForm->pickPinDim->value "yes")
        (progn
          zeForm->pinWidth->editable = t
          zeForm->pinNumber->editable = nil)
        (progn
          zeForm->pinNumber->editable =  t
          zeForm->pinWidth->editable = nil)
    )
    t
    )
  )
(defun pckImportFormBackCB (zeForm)
  ;;; call-back for BACK BUTTON
  (let (step)
    (pckDebug "pckRedrawImportFormBack" (sprintf nil "Status of GUI: %L\n" zeForm->stepField->value))
    (sscanf zeForm->stepField->value "Step %d" step)
    (pckDebug "pckRedrawImportFormBack" (sprintf nil "Reducing step from %L to %L\n" step (sub1 step)))
    zeForm->stepField->value = (get_pname (concat "Step " (sub1 step)))
    
	 (setq step (sub1 step))
 	 
	  (if (equal step 0)
	  		(progn 
			zeForm->statusField->value = "Select cell to import"
			zeForm->instructionField->value = (sprintf nil "Step %d. \nPlease provide cell and library name. Select number of terminal. \nThen click \"Apply\" button." step)
			)
			(progn
				(if step <= (atoi zeForm->numTerminals->value)
					(progn
					zeForm->instructionField->value = (sprintf nil "Step %d. \nPlease provide parameters for the current terminal. \nThen click \"APPLY\" button." step)
					zeForm->statusField->value = "Define terminal"
					)
					(progn
					zeForm->instructionField->value = (sprintf nil "Step %d. \nIt is DONE. ^_^ \nRemember to save before you exit" step)
					zeForm->statusField->value = "DONE"
					)
				)
		   )
	  )
   )
 )

(defun pckImportFormNextCB (zeForm)
  ;; call-back for NEXT BUTTON
  (let (step)
    (pckDebug "pckRedrawImportFormNext" (sprintf nil "Status of GUI: %L\n" zeForm->stepField->value))
    (sscanf zeForm->stepField->value "Step %d" step)
    (pckDebug "pckRedrawImportFormBack" (sprintf nil "Incrementing step from %L to %L\n" step (add1 step)))
    zeForm->stepField->value = (get_pname (concat "Step " (add1 step)))
	 	 
	 (setq step (add1 step))
	 
	 (if step > (atoi zeForm->numTerminals->value)
		(progn
		zeForm->instructionField->value = (sprintf nil "Step %d. \nIt is DONE. ^_^ \nRemember to save before you exit" step)
		zeForm->statusField->value = "DONE"
		)
		(progn
		zeForm->instructionField->value = (sprintf nil "Step %d. \nPlease provide parameters for the current terminal. \nThen click \"APPLY\" button." step)
		zeForm->statusField->value = "Define terminal"
		)
	)
  )
)

(defun pckRedrawImportForm (zeForm)
  (let (y field_list field_list2 )
    (pckDebug "pckRedrawImportForm" "Status of what?")
    
    t
  )
)
  
(defun pckCoordPin (win done Coords)
	(let (x y)
		;;; this functions is called when Left Click of Mouse is pressed - gives out LowerLeft coordinates for the current Pin  
		x = car(car(Coords))
		y = cadr(car(Coords))
		(list x y)
	)
)

(defun pckDefinePin (cv @key 	
									(pinName "T1")
									(layer "metal1")
									(layerPurpose "drawing")
									(vertOrient t)
									(PinWidth 0.1)
									(isLength nil)
									(PinLength 0.1)
									(PinNumber 4)
									(PinOrigin (list 0 0))
							)
	
	;;; Defines Pin with given properties and calls CreatePinLable function

  ( let (num length pinBBox)
  
		(if (equal isLength t) 
			(progn
			num = (pckMeshLineNumFloor PinLength layer vertOrient)
			length = (pckMeshWidth num layer vertOrient)
			)
			(progn 
			length = (pckMeshWidth PinNumber layer vertOrient)
			)		
		)
		
		(if (equal vertOrient t) 
			(progn
				pinBBox = ( list ( list  car(PinOrigin) cadr(PinOrigin) ) (list  car(PinOrigin)+PinWidth cadr(PinOrigin)+length ))
			)					
			(progn
				pinBBox = ( list ( list  car( PinOrigin ) cadr( PinOrigin )) (list  car( PinOrigin )+length cadr(PinOrigin)+PinWidth ))
			)
		)
		
		(pckCreatePinLable cv pinName layer layerPurpose pinBBox)
		
	)
)

		
		;;; THIS function helps to define, create and (re)place pin with lable attached to it
(defun pckCreatePinLable ( cv pinName layer layerPurpose bBox @optional (pinDirection "inputOutput") ) 
  	( let (x y rectId netId width labelId)
	 		
		(setq rectId (dbCreateRect cv list( layer layerPurpose ) bBox ))	
		(if (nequal (car (setof x cv~>nets (equal x~>name pinName))) nil)
			(dbDeleteObject (car (setof x cv~>nets (equal x~>name pinName))))
			t
		)
		
		(setq netId (dbCreateNet cv pinName ))	 		
		(if (nequal (car (setof x cv~>terminals (equal x~>name pinName))) nil)
			(dbDeleteObject (car (setof x cv~>terminals (equal x~>name pinName))))
		t
		)

		(dbCreateTerm netId pinName pinDirection )
	 	(dbCreatePin netId rectId ) 
	 	x = car( trBBoxCenter( bBox ) )
	 	y = cadr( trBBoxCenter( bBox ) )
	 		
		(if (nequal (car (setof x cv~>shapes (equal x~>theLabel pinName))) nil)
			(dbDeleteObject (car (setof x cv~>shapes (equal x~>theLabel pinName))))
		t
		)
			
		labelId = dbCreateLabel( cv list("text" "drawing") x:y pinName "centerCenter" "R0" "swedish" cadr( trBBoxDims( bBox ) ) )

		 (while pckFindBBoxInsideZone( list( labelId~>bBox ) bBox ) == nil
					labelId~>height =  (if (nequal labelId~>height 0.01) 
													labelId~>height - 0.01 
													labelId~>height - 0.005
											 ) 
		)
			
	(leAttachFig rectId labelId ) ;;; label is made a parent !!! and rect-pin is attached to it
			
	 t
	)
)
