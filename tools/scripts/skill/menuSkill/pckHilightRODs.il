(defun  pckHilightRods () 		   
  (let (cv inst d )
	cv = geGetEditCellView()
    
	(if inst = (car (geGetSelectedSet cv))
		(progn
		  d = (pckHilightRodDepth inst~>master 0 nil ) ;; d = depth of hierarchy
          
		  (pckHilightRodListBox cv d (sprintf nil "%d" d ) "" "ALL" "No" "")
		  )				  ;;progn
		(pckHilightRodError) ;; no instance selected 
		) 	
	      
	) ;;let
  t
  )

(defun pckGetRodNames (cv depth filterString layerString insts)
  
  (let (inst names names1 newNames fnames lppName)
   
    (setq lppName (parseString layerString))
    
    ;; (when (equal "No" insts) (setq insts nil))
    fnames = (list )
	inst = (car (geGetSelectedSet cv))
    ;; (pckHilightHier cv nil inst~>name depth layer)
    (when (rodGetNamedShapes inst~>master )	;; non-instance RODs at top level
      (if (not (equal layerString "ALL"))
          (progn            
            names1 = (setof x (rodGetNamedShapes (car (geGetSelectedSet cv))~>master )
                            (and x (equal lppName (getSGq (getSGq x dbId) lpp))))~>name
            )
          names1 = (rodGetNamedShapes (car (geGetSelectedSet cv))~>master )~>name
          )
	                     
	  )
    
    (when filterString == "" filterString = ".")
    
	(if  depth == 0
        
           (when (equal insts "Yes") names1 =  (cons inst~>master~>instances~>name  names1)
                 
                 )
  		  
		 names = (cons (pckHilightHier (car (geGetSelectedSet cv))~>master nil inst~>name depth-1 layerString insts) names))
    
	(when names  
	  newNames = (pckParseRODNames names))

	newNames = (cons names1 newNames)
	newNames = (pckFlattenList newNames)
    newNames = (sort newNames nil)
    (if (get_pname (getchar filterString 1)) == "!"
        (progn
          
          filterString = (car (parseString filterString "!") ) 
          (foreach name newNames
                   (when (not (rexMatchp filterString name))
                     fnames = (cons name fnames)
                     )
                   )
          )
        (foreach name newNames
             (when (rexMatchp filterString name)
               fnames = (cons name fnames)
               )
             )
        )
    
    
	
     (when !fnames fnames = (cons "" fnames))
     
     fnames
	)
  )
 
(defun pckParseRODNames (names)	;; removes leading instance name
  ( let (newNames x y)
	names = (pckFlattenList names)
	newNames = (list )
	(foreach name names
			 x = (parseString name "/")
			 x = (cdr x)
			 y = (car x)
			 (when (length x) > 1
				   (for i 1 (length x)-1
						y = (strcat y "/" (nth i x)))
				   )
			 (when y
			   newNames = (cons y newNames)) 
			 )
	newNames = (pckFlattenList newNames)
    newNames = (sort newNames nil)

	)
  )
(defun pckHilightRodError ()
  (let ( )
	(hiDisplayAppDBox
	 ?name (gensym 'errorBox)
	 ?dboxBanner "pckHilightRODs"
	 ?dboxText "No instance was selected!"
	 ?dialogType 1 
	 )
	
  )
)
(defun  pckHilightHier (cv names instName depth layerString insts)
  (let (name lppName) ;; recursively walks thru hierarchy adding rod and instances names
    ;
    (if (equal "ALL" layerString)
        (setq lppName layerString)
        (setq lppName (parseString layerString)))
	(foreach inst cv~>instances
             
             cv = inst~>master
             name = inst~>name
             (unless (or (not (equal "ALL" lppName)) (equal insts "No")) 
               names = (cons (strcat instName "/" name) names)
               )
             
             (foreach rod (rodGetNamedShapes cv)
                      
                      (if (not (equal "ALL" lppName))
                          (when (equal lppName (getSGq (getSGq rod dbId) lpp))
                            names = (cons (strcat instName "/" name "/" rod~>name ) names)
                            )
                          (if (equal insts "Yes")
                              names = (cons (strcat instName "/" name "/" rod~>name ) names)
                              (when (equal "rect" (getSGq (getSGq rod dbId) objType))
                                names = (cons (strcat instName "/" name "/" rod~>name ) names)
                                )
                              )
                          )
                      
                      )
             
             (when depth > 0 
                   names = (pckHilightHier cv names  (strcat instName "/" name) depth-1 layer insts)

                   )
             ;; )
			 )			 
	names = (reverse (sort names nil) )
    names
	) ;;let					 		 
  )
 
(defun pckHilightRodListBox  (cv depth defDepth  filter layer insts pt)
  (let (depthList myDepth myListBox zoom myFileForm TextField pasteField zoomBut pickBut FilterField LayerField 
                 InstsField  rodNames selectedRodNames layerNames )
    
    (when !filter filter = "")
    (when !layer layer = "")
    ;; (when !insts insts = "")

    (for i 0 depth
		 depthList = (cons (sprintf nil "%d" i) depthList))
    
   
	zoomBut = (hiCreateBooleanButton
			   ?name 'Zoom
			   ?buttonText  "Zoom in?"               
			   ?value  nil)

     
   	myDepth = (hiCreateCyclicField
               ?name 'depthChoice
               ?choices (reverse depthList)
               ?prompt "Depth Filter"
               ?defValue defDepth			  
			   )

    TextField = (hiCreateStringField
				 ?name 'myText
				 ?value "Select ROD name to hilight"
				 ?editable nil
				 )
    
    FilterField = (hiCreateStringField
                   ?name 'myFilter
                   ?prompt "String Filter"
                   ?defValue filter
                   ?callback "(cancelEnterFun)"
                   ?editable t)    

    
 
     InstsField = (hiCreateCyclicField
                   ?name 'myInsts
                   ?prompt "Instance RODs?"
                   ?choices (list "No" "Yes")
                   ?defValue "No"
                   
                   )
     
    (setq rodNames (pckGetRodNames cv (atoi myDepth->value) FilterField->value layer insts))
    
    (when (and pt (not (equal pt "")))
      
      (setq selectedRodNames (pckGetRODListFromPoint pt rodNames))
      
      (if selectedRodNames
        (setq rodNames selectedRodNames)
        (setq rodNames (list "")))
      )
    (setq pt "")
    (setq layerNames (pckHilightRodsGetLayers cv rodNames))

     LayerField = (hiCreateCyclicField
                   ?name 'myLayer
                   ?prompt "LPP Filter"
                   ?choices layerNames
                   ?defValue "ALL"                  
                   )

    pickBut = (hiCreateBooleanButton
			   ?name 'Pick
			   ?buttonText  "Probe Layout?"               
			   ?defValue  nil
              
               )
    
    
    myListBox = (hiCreateListBoxField
                 ?name 'MyLB
                 ?choices  rodNames
                 ?changeCB "hisetList = (pckListBoxCB hiGetCurrentForm() myFileForm)"
                 ?numRows 16
                 ?multipleSelect nil
				 ?defValue (list (car rodNames)) 
                
				 
                 )
	pasteField = (hiCreateStringField
				  ?name 'myChoice
				  ?prompt "Selected:"
				  ?defValue "none"
				  ?value "none"
				  )
    
    
   
    myFileForm = (hiCreateAppForm
                  ?name 'myFileForm
                  ?formTitle "Hilight ROD Object"
                  ?fields (list
                           (list TextField (list 20 20) (list 200 10)) 
                           (list myListBox (list 10 50) (list 300 250)) 
                           (list zoomBut (list 10 310) (list 10 10) 60) 
                           (list pasteField (list 10 330) (list 300 10) 60) 
                           (list FilterField (list 10 360) (list 200 10) 80) 
                           (list LayerField (list 10 395) (list 200 10) 80) 
                           (list myDepth (list 10 425) (list 20 10) 80) 
                           (list InstsField (list 150 425) (list 20 10) 100) 
                           (list pickBut (list 10 465) (list 20 10) 80) 
                           )
                  ?callback (list "{ (geDeleteAllHilightSet cv)
                              defDepth = myDepth->value 
                              (if  myFileForm->Pick->value
                                  (setq pt (pckHilightRodsGetPoint))
                                  (cancelEnterFun))
                              
                              filter = FilterField->value
                              FilterField->defValue = \".\" 
                              layer = myFileForm->myLayer->value
                              
                              
                              insts = myFileForm->myInsts->value
                             
                              InstsField->defValue = \"NO\"                           
                              (hiFormCancel myFileForm)
                                                                         
                               (pckHilightRodListBox  cv depth defDepth filter layer insts pt)
                               LayerField->defValue = layer
                               }"
                                 
                                  "{ (fprintf stdout \"Done\n\") }")  
                  
                  ?buttonLayout 'ApplyCancel
                  ?initialSize (list 400 850)
				  )
    
        (hiDisplayForm myFileForm (list 7 100))
        
    
	)
  )
(defun pckHilightRodsGetPoint ()
    (enterPoint
     ?prompts (list "Enter a point.")     
    )
    
  )
;
(defun pckGetRODListFromPoint ( pts rodNameList)
  (let (  pt inst cv rodList selectRods selectRodNames)
     ;; (unless (equal (length pts) 2)
    
      
    (setq cv (geGetEditCellView))
    (setq inst (car (geGetSelectedSet cv)))
   
    (setq rodList (mapcar (lambda (x) (rodGetObj (get_pname (concat (getSGq inst name) "/" x)) cv))
                          rodNameList))
    (setq selectRods (setof x rodList (and x
                                               (greaterp (car pts) (car x~>lowerLeft))
                                               (lessp (car pts) (car x~>upperRight))
                                               (greaterp (cadr pts) (cadr x~>lowerLeft))
                                               (lessp (cadr pts) (cadr x~>upperRight)))))
     (setq selectRodNames (pckParseRODNames (mapcar (lambda (x) (getq x name)) selectRods))  )
    
    )
  )
(defun pckHilightRodsGetLayers (cv rodNameList)
  (let (instName rodList lppList)
    
    (setq instName (car (geGetSelectedSet cv)))
    (setq rodList (mapcar (lambda (x) (rodGetObj (get_pname (concat (getSGq inst name) "/" x)) cv))
                          rodNameList))
    (setq lppList (list ))
    
    (mapcar (lambda (x) (setq lppString (get_pname (concat (car (getSGq (getSGq x dbId) lpp) )  " " (cadr (getSGq (getSGq x dbId) lpp)))))
                    (unless (member lppString  lppList)
                      (setq lppList (cons lppString lppList))
                      ))
            (setof x rodList (and x (equal (getSGq (getSGq x dbId) objType) "rect"))))
    
     
     
     (setq lppList (sort lppList 'alphalessp))
     (setq lppList (cons "ALL" lppList))
     
    )
  )

(defun pckListBoxCB ( MyLB x)
  (let (cv hiSetList)

	hiSetList = '()
	cv = geGetEditCellView()            			 
	hiSetList = (cons (pckHilightRodObj cv x->MyLB->value x->Zoom->value)  hiSetList)              
	x->myChoice->value = (strcat "\"" (if (car x->MyLB->value) 
												   (car x->MyLB->value)
												   (car x->MyLB->defValue)) "\"") 
	hiSetList
	);;let		   		  
  );;defun	  
				  
(defun pckHilightRodObj (cv hiList zoom)
  ;; makes highlight set
  (let ( hiset rodBBox obj)
      (geDeleteAllHilightSet cv);; removes old set
      (setq hiset (geCreateHilightSet cv (list "symbol2" "drawing") nil));;hilighting layer
      (foreach fig hiList
			   fig = (strcat (car (geGetSelectedSet cv)~>name) "/" fig);;add inst name to rodName
			   rodBBox = (list (rodGetObj fig cv)~>"lL" (rodGetObj fig cv)~>"uR" )
              obj =  (geAddHilightRectangle hiset rodBBox))      
	  (when rodBBox
		hiset->enable = t
	    (when zoom
		  (hiZoomIn (geGetCellViewWindow cv) (BlowUp rodBBox))))
    )
  )
  
(defun BlowUp (bbox )
  (pckTransformBbox bbox ((rightEdge bbox) - (leftEdge bbox))/2 ((topEdge bbox) - (bottomEdge bbox))/2)
  )

(defun pckHilightRodDepth ( cv Depth maxDepth )
  (let ();;finds depth of selected instance
    (when !maxDepth maxDepth = 0)
    (if cv~>instances
	   Depth++
       maxDepth = (max Depth maxDepth) 		 
       )
    (foreach inst cv~>instances        			 			  			    
       maxDepth =  (pckHilightRodDepth inst~>master Depth maxDepth)                 
       )
     maxDepth    					  					   
	)
)