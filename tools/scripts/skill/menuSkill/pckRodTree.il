;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun myNewRodTree (cvId @optional (instOnly t))
  (let (tree treeField form)
	(setq tree (traverseHier cvId nil instOnly))
	
	;;Make form
	;; create tree table and use indexTree as the value for ?choice
	(setq treeField (hiCreateTreeTable ?name (quote myTree)
									   ?title "RODs"
									   ?titleAlignment (quote center)
									   ?headers (if instOnly
												  (list
												   (list "cellName" 300 'left 'string t)
												   (list "libName" 300 'left 'string t)
												   (list "instName" 100 'left 'string t))
												  (list
												   (list "Name" 300 'left 'string t)
												   (list "libName/Layer" 200 'center 'string t)
												   (list "cellName/Purpose" 200 'center 'string t)))
									   ?choice tree
									   ?callback "myNewTreeCB"
									   ;;?sort (list 0 t)
									   ?selectMode (quote extended)
									   ))
	;; create a form
	(setq form (hiCreateAppForm ?name (quote form)
								?formTitle "ROD Hilighter Tree"
								?fields (list
										 (list treeField 5:5 700:500 20))
								?initialSize (if instOnly
											   600:500
											   700:500)))
	(hiDisplayForm form)
	(geDeleteAllHilightSet cvId)
	))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun traverseHier (cvId parent @optional (instOnly t))
  (let (currentMaster currentTree leafList)
	;;Make index when starting tree
	(unless parent
	  (setq parent (list (hiCreateTree (gensym "treeIndex")) nil))
	  (unless instOnly
		(pckTreeCollectRods cvId parent)))
	
	;;look for instances
	(foreach inst (getSGq cvId instances)
			 (setq currentMaster (getSGq inst master))
			 (cond
			  ;;Add more instances
			  ((getSGq currentMaster instances)
			   (setq currentTree (pckTreeCreateTreeItem parent inst instOnly))
			   (traverseHier currentMaster currentTree instOnly)
			   t)
			  ;;Add RODs
			  ((rodGetNamedShapes currentMaster)
			   (setq currentTree (pckTreeCreateTreeItem parent inst instOnly))
			   (unless instOnly
				 (pckTreeCollectRods currentMaster currentTree))
			   t)
			  ;;Done?
			  ((and
				(not (getSGq currentMaster instances))
				(not (rodGetNamedShapes currentMaster)))
			   (setq leafList (cons (pckTreeCreateLeafItem parent inst instOnly) leafList)))))

	;;Append leaves from t section of cond call
	(hiTreeAppendItems (car parent) leafList)

	(car parent)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun pckTreeCreateTreeItem (parent node @optional (useCellName nil))
  (let (treeItem subTree treeDescription rodDescription)
	;;Create tree description
	(setq rodDescription (reverse
						  (cons (getSGq node name) (reverse (car
															 (reverse
															  (if (and
																   (hiGetTreeItemDescription (cadr parent))
																   (listp (hiGetTreeItemDescription (cadr parent))))
																  (hiGetTreeItemDescription (cadr parent))
																nil)))))))
	(setq treeDescription (list
						   (if useCellName
							 (getSGq node cellName)
							 (getSGq node name))
						   (getSGq node libName)
						   (if useCellName
							 (getSGq node name)
							 (getSGq node cellName))
						   (getSGq node cellName)
						   rodDescription))
	;;Create tree item
	(setq treeItem (hiCreateTreeItem (gensym (strcat (getSGq node name) "_____Item")) treeDescription))
	;;Append tree item
	(hiTreeAppendItem (car parent) treeItem)
	;;Create sub-tree
	(setq subTree (hiCreateTree (gensym (concat (getSGq node name) "_____Tree"))))
	;;Put sub-tree in tree item
	(hiItemInsertTree treeItem subTree)
	;;Return tree and treeItem
	(list subTree treeItem)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun pckTreeCreateLeafItem (parent node @optional (useCellName nil))
  (let (subTree treeDescription rodDescription)
	;;Create tree description
	(setq rodDescription (reverse
						   (cons (getSGq node name) (reverse (car
															  (reverse
															   (if (and
																	(hiGetTreeItemDescription (cadr parent))
																	(listp (hiGetTreeItemDescription (cadr parent))))
																 (hiGetTreeItemDescription (cadr parent))
																 nil)))))))
	(setq treeDescription (list
						   (if (and
								useCellName
								(equal (getSGq node objType) "inst"))
							 (getSGq node cellName)
							 (getSGq node name))
						   (if (equal (getSGq node objType) "inst")
							 (getSGq node libName)
							 (car (getSGq (getSGq node dbId) lpp)))
						   (if (equal (getSGq node objType) "inst")
							 (if useCellName
							   (getSGq node name)
							   (getSGq node cellName))
							 (cadr (getSGq (getSGq node dbId) lpp)))
						   rodDescription))
	;;Create tree item
	(hiCreateTreeItem (gensym (strcat (getSGq node name) "_____Leaf")) treeDescription)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun pckTreeCollectRods (cvId parent)
  (let (leafList)
	(foreach elem (rodGetNamedShapes cvId)
						(setq leafList (cons (pckTreeCreateLeafItem parent elem) leafList)))
	(hiTreeAppendItems (car parent) leafList)
	t))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun myNewTreeCB (treeField value)
  (let (cvId rodName hlSetId rodId)
	(setq cvId (geGetEditCellView))
	(geDeleteAllHilightSet cvId)
	(setq hlSetId (geCreateHilightSet cvId (list "ndiff" "CAPID") nil))
	(foreach elem value
			 (when (setq rodName (buildString (car (reverse (hiGetTreeItemDescription (eval elem)))) "/"))
			   (setq rodId (pckRodGetObj rodName cvId))
			   (setq hiObj (geAddHilightRectangle hlSetId (list
												  (getSGq rodId lowerLeft)
												  (getSGq rodId upperRight))))
	  (putpropq hlSetId t enable)))
	t))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;






















/*











(defun treeTest ()
  (let (indexTree dowTree dow nas new newTree treeField form dpl)
	
	;; create a root tree
	indexTree=hiCreateTree('index) 
	
	;; create two tree items and append them to the root tree
	dow=hiCreateTreeItem('dow list("Dow Jones"))
	nas=hiCreateTreeItem('nas list("NASDAQ"))
	hiTreeAppendItem(indexTree dow)
	hiTreeAppendItem(indexTree nas) 
	
	;; create two sub-trees 
	dowTree=hiCreateTree('dows)
	nasTree=hiCreateTree('nass) 
	
	;; put the two sub-trees into the two items created earlier
	hiItemInsertTree(dow dowTree)
	hiItemInsertTree(nas nasTree)

	
	;; add a few leaves for the dowTree and nasTree
	hiTreeAppendItem(dowTree hiCreateTreeItem('cdn list("Cadence" 80.5 1 "Strong Buy")))
	hiTreeAppendItem(dowTree hiCreateTreeItem('ibm list("I.B.M." 118 3 "Hold")))
	hiTreeAppendItem(nasTree hiCreateTreeItem('sunw list("Sun Micro" 27.750 4 "Sell")))
	hiTreeAppendItem(nasTree hiCreateTreeItem('orcl list("Oracle" 28.925 5 "Strong Sell")))
	
	;new=hiCreateTreeItem('new list("NEW"))
	;hiTreeAppendItem(nasTree new)
	;newTree=hiCreateTree('news)
	;hiItemInsertTree(new newTree)
	(setq dpl (list nil (stringToSymbol "nas_tree") nasTree))
	;;(fprintf stdout "dpl = %L\n" dpl)
	(setq dpl (pckTreeCreateTreeItem "nas" "new" dpl))
	(pckTreeCreateLeafItem "new" (list "Sun Micro" 27.750 4 "Sell") dpl)
	(pckTreeCreateLeafItem "new" (list "Oracle" (list 28.925) 5 "Strong Sell") dpl)
	;hiTreeAppendItem((get dpl "new-tree") hiCreateTreeItem('sunw list("Sun Micro" 27.750 4 "Sell")))
	;hiTreeAppendItem((get dpl "new-tree") hiCreateTreeItem('orcl list("Oracle" (list 28.925) 5 "Strong Sell")))
	;hiTreeAppendItem(newTree hiCreateTreeItem('sunw list("Sun Micro" 27.750 4 "Sell")))
	;hiTreeAppendItem(newTree hiCreateTreeItem('orcl list("Oracle" 28.925 5 "Strong Sell")))
	
	;; create tree table and use indexTree as the value for ?choice
	treeField = hiCreateTreeTable(
								  ?name 'treeField
										?title "Stocks"
										?titleAlignment 'center
										?headers list(list("Name" 125 'left 'string) 
														  list("Price" 60 'left 'float3)
														  list("Rating" 45 'center 'int)
														  list("Recommendation" 125 'right)
														  )
										?choice indexTree
										?callback "myTreeCB"
										?sort (list 3 t)
										)
	
	;; create a form
	form = hiCreateAppForm(
						   ?name 'form
								 ?formTitle "A Tree Sample"
								 ?fields list(
											  list(treeField 5:5 400:200 55)
												  )
								 ?initialSize 500:250)
	
	hiDisplayForm(form)
	;(fprintf stdout "indexTree = %L\n" nasTree~>??)
	;nasTree
	t))

;; create callback, which is called whenever any tree items are selected and which
;; prints the selected item's description
procedure( myTreeCB(name itemSymList)
				 while(itemSymList
					   itemSym=car(itemSymList)
					   println(hiGetTreeItemDescription(eval(itemSym)))
					   itemSymList=cdr(itemSymList)
					   ) 
				 )



;;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
(defun rodTree (cvId @optional (exceptions ""))
  (let (rawRodNames dpl currentRod previousRod leafList)
	;;Initialize DPL
	(setq dpl (list nil))

	;;Create root tree and add to DPL
	(putprop dpl (hiCreateTree (quote index)) (stringToSymbol "index_tree"))
	
	;;get rod names
	(setq rawRodNames (mapcar (lambda (x) (parseString x "/")) (pckGetRodNames cvId (dbGetMaxHierDepth) exceptions "")))
	
	;;Walk across all rods
	(foreach elem rawRodNames
			 ;;(fprintf stdout "elem = %L\n" elem)
			 ;;Initialize current rod name and previous rod name
			 (setq currentRod nil)
			 ;;Walk across each level of hier in the ROD name
			 (for i 0 (sub1 (length elem))
				  ;;Set previous rod name
				  (if currentRod
					(setq previousRod currentRod)
					(setq previousRod (list "index")))
				  ;;Are we looking at TREES or LEAVES?
				  (if (pckEQP i (sub1 (length elem)))
					;;Leaves
					;;Put leaves in list for to add later
					(setq leafList (cons elem leafList))
					;;Trees
					(progn
					  ;;Create current rod name using "_" as concat char
					  (setq currentRod (reverse (cons (nth i elem) (reverse currentRod))))
					  ;;(fprintf stdout "i = %L, previousRod = %L, currentRod = %L\n" i previousRod currentRod)
					  ;;Look for existance of tree and create if does not exist
					  (if (get dpl (concat (buildString currentRod "/") "_tree"))
						t;;(fprintf stdout "Tree already exists %L %L\n" currentRod (get dpl (concat (buildString currentRod "_") "_tree")))
						(progn
						  ;;(fprintf stdout "Tree does not exist %L %L\n" currentRod (get dpl (concat (buildString currentRod "_") "_tree")))
						  (setq dpl (pckTreeCreateTreeItem (buildString previousRod "/") (buildString currentRod "/") dpl)))))
					)
				  )
			 )
	
	;;Leaves
	
	(foreach elem (reverse leafList)
			 (setq currentRod (car (reverse elem)))
			 (if (pckEQP (length elem) 1)
			   (progn
				 ;;(fprintf stdout "Checking for %L: %L\n" (concat currentRod "_tree") (get dpl (concat currentRod "_tree")))
				 ;;(fprintf stdout "Checking for %L: %L\n" (concat currentRod "_item") (get dpl (concat currentRod "_item")))
				 (unless (or
						  (get dpl (concat currentRod "_tree"))
						  (get dpl (concat currentRod "_item")))
				   ;;(fprintf stdout "Adding leaf %L\n" currentRod)
				   (setq dpl (pckTreeCreateLeafItem "index" (list currentRod
																  (if (equal
																	   (getSGq (getSGq (pckRodGetObj (strcat (getSGq (car (geGetSelectedSet)) name) "/" currentRod) cvId) dbId) objType)
																	   "inst")
																	""
																	(car (getSGq (getSGq (pckRodGetObj (strcat (getSGq (car (geGetSelectedSet)) name) "/" currentRod) cvId) dbId) lpp)))
																  (if (equal
																	   (getSGq (getSGq (pckRodGetObj (strcat (getSGq (car (geGetSelectedSet)) name) "/" currentRod) cvId) dbId) objType)
																	   "inst")
																	""
																	(cadr (getSGq (getSGq (pckRodGetObj (strcat (getSGq (car (geGetSelectedSet)) name) "/" currentRod) cvId) dbId) lpp)))
																  ) dpl))
				   t)
				 t)
			   (progn
				 (setq previousRod (reverse (cdr (reverse elem))))
				 ;;(fprintf stdout "Checking for %L: %L\n" (concat (buildString previousRod "_") "_" currentRod "_tree") (get dpl (concat (buildString previousRod "_") "_" currentRod "_tree")))
				 ;;(fprintf stdout "Checking for %L: %L\n" (concat (buildString previousRod "_") "_" currentRod "_item") (get dpl (concat (buildString previousRod "_") "_" currentRod "_item")))
				 (unless (or
						  (get dpl (concat (buildString previousRod "/") "/" currentRod "_tree"))
						  (get dpl (concat (buildString previousRod "/") "/" currentRod "_item")))
				   (setq previousRod (reverse (cdr (reverse elem))))
				   ;;(fprintf stdout "Adding leaf %L %L\n" (buildString previousRod "_") currentRod)
				   (setq dpl (pckTreeCreateLeafItemList (buildString previousRod "/") (list currentRod) dpl))
				   t)
				 t)))
	(foreach elem (reverse (getq dpl ?))
			 ;;(fprintf stdout "elem = %s\n" elem)
			 (when (equal (car (reverse (parseString elem "_"))) "leafList")
			   (setq elem (cdr (reverse (parseString elem "_"))))
			   (hiTreeAppendItems (get dpl (concat (buildString elem "/") "_tree"))
								  (get dpl (concat (buildString elem "/") "_leafList")))))
	
	;; create tree table and use indexTree as the value for ?choice
	(setq treeField (hiCreateTreeTable ?name 'treeField
									   ?title "RODs"
									   ?titleAlignment 'center
									   ?headers (list
												 (list "Name" 200 'left 'string t)
												 (list "Layer" 100 'center 'string t)
												 (list "Purpose" 100 'center 'string t))
									   ?choice (getq dpl index_tree)
									   ?callback "myTreeCBHilight"
									   ;;?sort (list 0 t)
									   ?selectMode (quote extended)
									   ))
	;;(fprintf stdout "treeField = %L\n" treeField~>??)
	;; create a form
	(setq form (hiCreateAppForm ?name 'form
								?formTitle "ROD Hilighter Tree"
								?fields (list
										 (list treeField 5:5 400:500 20))
								?initialSize 500:250))
	;;(fprintf stdout "form = %L\n" form~>??)
	(hiDisplayForm form)
	(geDeleteAllHilightSet cvId)
	form))
;;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
(defun pckTreeCreateTreeItem (parent node dpl)
  (let (treeItem subTree)
	;;(fprintf stdout "TREE parentTree = %L %L\n" (get dpl (concat parent "_tree")) (concat parent "_tree"))
	;;(fprintf stdout "TREE parentTreeItem = %L %L\n" (get dpl (concat parent "_item")) (concat parent "_item"))
	;;Create tree item
	(setq treeItem (hiCreateTreeItem (concat node "_item") (list (car (reverse (parseString node "/"))))))
	;;Append tree item
	(hiTreeAppendItem (get dpl (concat parent "_tree")) treeItem)
	;;Create sub-tree
	(setq subTree (hiCreateTree (concat node "_tree")))
	;;Put sub-tree in tree item
	(hiItemInsertTree treeItem subTree)
	;;Populate DPL
	(putprop dpl treeItem (concat node "_item"))
	(putprop dpl subTree (concat node "_tree"))
	;;return DPL
	dpl))
;;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
(defun pckTreeCreateLeafItem (parent leaf @optional (dpl nil))
  (let (leafItem)
	;(fprintf stdout "LEAF parentTree = %L %L\n" (get dpl (concat parent "_tree")) (concat parent "_tree"))
	;(fprintf stdout "LEAF parentTreeItem = %L %L\n" (get dpl (concat parent "_item")) (concat parent "_item"))
	;;Append tree item
	(setq leafItem (hiTreeAppendItem
					(get dpl (concat parent "_tree"))
					(hiCreateTreeItem (concat parent "/" (car leaf) "_leaf") leaf)))
	;;Populate DPL
	;;(fprintf stdout "leafItem = hiTreeAppendItem => %L\n" leafItem)
	(putprop dpl leafItem (concat parent "/" (car leaf) "_item"))
	dpl))
;;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
(defun pckTreeCreateLeafItemList (parent leaf @optional (dpl nil))
  (let (leafItem rodId layer purpose)
	;;Append tree item
	(setq rodId (pckRodGetObj (strcat (getSGq (car (geGetSelectedSet)) name) "/" parent "/" (car leaf)) (geGetEditCellView)))
	;;(fprintf stdout "leaf = %L\nrodObj = %L\n" leaf rodId)
	(if (equal (getSGq (getSGq rodId dbId) objType) "inst")
	  (progn
		(setq layer "")
		(setq purpose ""))
	  (progn
	   (setq layer (car (getSGq (getSGq rodId dbId) lpp)))
	   (setq purpose (cadr (getSGq (getSGq rodId dbId) lpp)))))
	;;(fprintf stdout "lpp = %L %L\n" layer purpose)
	(setq leafItem (hiCreateTreeItem (concat parent "/" (car leaf) "_leaf") (list (car leaf) layer purpose)))
	;;(fprintf stdout "leafItem = %L\n" leafItem~>??)
	;;Populate DPL
	(putprop dpl
			 (cons leafItem (get dpl (concat parent "_leafList")))
				   (concat parent "_leafList"))
	dpl))
;;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
(defun myTreeCBHilight (treeField value)
  (let (cvId hlSetId topName rodName rodId hiObj)
	(setq cvId (geGetEditCellView))
	(geDeleteAllHilightSet cvId)
	(setq hlSetId (geCreateHilightSet cvId (list "ndiff" "CAPID") nil))
	(setq topName (getSGq (car (geGetSelectedSet)) name))
	;;(fprintf stdout "value = %L\n" value)
	(foreach elem value
	(when (setq rodName elem);;(setq rodName (car value))
	  (setq rodName (reverse (cdr (reverse (parseString rodName "_")))))
	  ;;(fprintf stdout "rodName = %L\n" rodName)
	  (setq rodName (buildString rodName "_"))
	  ;;(fprintf stdout "rodName = %L\n" rodName)
	  (setq rodName (parseString rodName "/"))
	  ;;(fprintf stdout "rodName = %L\n" rodName)
	  (when (equal (car rodName) "index")
		(setq rodName (cdr rodName)))
	  ;;(fprintf stdout "rodName = %L\n" rodName)
	  (setq rodName (cons topName rodName))
	  ;;(fprintf stdout "rodName = %L\n" rodName)
	  (setq rodName (buildString rodName "/"))
	  (setq rodId (pckRodGetObj rodName cvId))
	  ;;(fprintf stdout "rodName = %L\nrodId = %L\n" rodName rodId)
	  (setq hiObj (geAddHilightRectangle hlSetId (list
												  (getSGq rodId lowerLeft)
												  (getSGq rodId upperRight))))
	  (putpropq hlSetId t enable)))
	  ;;(fprintf stdout "hiObj = %L\n" hiObj)
	  
	t))


*/