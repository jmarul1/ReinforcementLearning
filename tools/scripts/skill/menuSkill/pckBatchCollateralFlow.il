;;
;; (load "pckBatchCollateralFlow.il")
(defun pckBatchCollateralFlow (PIFprop)
  (let ((origin (list 0 0)) (strcount 1) StructInfo instname cv instId port sourceId instCell  (cellList (list )))
    ;;
    ;; opening cell view for WRITE
    ;; blow away any junk
    (setq cv
          (dbOpenCellViewByType
           PIFprop->libName
           PIFprop->test_row_name "layout" "maskLayout" "w"))
    (setq StructInfo (pckGetStructureList))
    (pckInfo "pckPlaceStructuresInLayout"
             "Starting test structure placement in layout cellview...")
    ;;
    ;; Each instance destribed in GetStructureList
    ;; gets instantiated, then custom cell based on that instance created and
    ;; substituted for that instance.
    
    (foreach inst StructInfo
             (pckInfo "pckPlaceStructuresInLayout"
                      "Opening SYNTHESIZED template source and layout cellviews.")
             (unless
                 (setq sourceId
                       (dbOpenCellViewByType inst->library inst->template "layout" "" "r" ))
               (pckErr 206 (sprintf nil "Cannot open template %s %s"
                                    inst->template
                                    inst->library))
               )
             (if inst->targetName
                 (setq instname inst->targetName)
                 (progn
                   (sprintf instname "inst%d" strcount)
                   (setq strcount (add1 strcount))
                   )
                 )
             ;;inst->instname = instname
             (putpropq inst instname "instname")
             (if (getq inst "targetLnfLib") 
                 (setq targetLnfLib (getq inst "targetLnfLib"))
                 (setq targetLnfLib "") )
             
             (pckInfo "pckPlaceStructuresInLayout"
                      (sprintf nil "Placing template %s." instname))
             (when (or
                    (null instname)
                    (rexMatchp "^[ \t]*$" instname))
               (pckErr 999
                       (sprintf nil "Collateral target name - %L is empty" instname))
               )
             (setq instId
                   (pckPlaceLayoutTemplate cv inst sourceId
                                           (car origin) (cadr origin) PIFprop))
             (dbClose sourceId)
             (pckInfo "pckPlaceStructuresInLayout"
                      (sprintf nil "Creating new cell %s %s." inst->library instname))
             ;; create new cell and replace original instance with it.
             (setq instCell
                   (leMakeCell (list instId) cv~>libName instname "layout" t ))
             (dbSave instCell)
             (dbClose instCell)
             (pckInfo "pckPlaceStructuresInLayout"
                      (sprintf nil "Opening new cell %s %s to flatten its contents."
                               cv~>libName instname))
             (setq instCell
                   (dbOpenCellViewByType  cv~>libName instname "layout" "maskLayout" "a" ))
             ;;
             ;; how would ROD names be translated during this process?
             ;; change the name on instantiated cell to "inst1"
             (fprintf stdout "--D-- name of the instance in created cell: %L\n" (car instCell~>instances)~>name)
             (dbSetq (car instCell~>instances) "inst1" name)
             (pckFlattenCellsWithRODs instCell) ;; using ROD flattening
             ;;(dbSetq instCell instname rodInstPrefix)
             (dbSave instCell)
             (pckSetpckGen cv~>libName instname "layout")
             (setq origin
                   (pckShiftPoint origin
                                  (car (trBBoxDims instCell~>bBox)) 0.0))
             (pckInfo "pckPlaceStructuresInLayout" (sprintf nil "New origin %L." origin))

             (dbClose instCell)
             (dbSave cv)
             ;;
             ;; Stream out and convert to LNF
             (pckPostGenStreamout
              (getShellEnvVar "PDSSTM")  cv~>libName instname (strcat instname ".stm"))
             (pckStm2Lnf (strcat (getShellEnvVar "WORK_AREA_ROOT_DIR") "/genesys/")
                         targetLnfLib
                         instname
                         (strcat (getShellEnvVar "PDSSTM") "/" instname ".stm")
                         (strcat instname ".lnf")
                         "-notextSubstrate -noautoboundarypins -portpartialvia -noportxboundary"
                         t
                         )
             (setq cellList (cons instname cellList))
             )
    (pckAddCellsToCat cv~>libName cv~>cellName cellList)
    (setq port (outfile
                (sprintf nil "%s/%s_%s.cdl" 
                         (getShellEnvVar "TCC_NETLIST_TMP")
                         PIFprop->libName PIFprop->test_row_name)))
    (pckNetlistCdl cv (pckGetPadPCName)
                   (getq cv~>tcc_dpl "PadrowType")					  
                   port)
    (dbSave cv)                 
    (dbClose cv)

    (close port)

    ;; Undefine pckGetConnectivity, so it won't cause problems later in the session
    (when (fboundp 'pckGetConnectivity)
      (putd 'pckGetConnectivity nil))
    )
  )



(defun pckBatchAntFlow (PIFprop)
  (let ((origin (list 0 0)) (strcount 1) StructInfo instname cv instId port sourceId instCell  (cellList (list )))
    ;;
    ;; opening cell view for WRITE
    ;; blow away any junk
    (setq cv
          (dbOpenCellViewByType
           PIFprop->libName
           PIFprop->test_row_name "layout" "maskLayout" "w"))
    (setq StructInfo (pckGetStructureList))
    (pckInfo "pckPlaceStructuresInLayout"
             "Starting test structure placement in layout cellview...")
    ;;
    ;; Each instance destribed in GetStructureList
    ;; gets instantiated, then custom cell based on that instance created and
    ;; substituted for that instance.
    
    (foreach inst StructInfo
             (pckInfo "pckPlaceStructuresInLayout"
                      "Opening SYNTHESIZED template source and layout cellviews.")
             (unless
                 (setq sourceId
                       (dbOpenCellViewByType inst->library inst->template "layout" "" "r" ))
               (pckErr 206 (sprintf nil "Cannot open template %s %s"
                                    inst->template
                                    inst->library ))
               )
             (if inst->targetName
                 (setq instname inst->targetName)
                 (progn
                   (sprintf instname "inst%d" strcount)
                   (setq strcount (add1 strcount))
                   )
                 )
             inst->instname = instname

             (pckInfo "pckPlaceStructuresInLayout"
                      (sprintf nil "Placing template %s." instname))
             (when (or
                    (null instname)
                    (rexMatchp "^[ \t]*$" instname))
               (pckErr 999
                       (sprintf nil "Collateral target name - %L is empty" instname))
               )
             (setq instId
                   (pckPlaceLayoutTemplate cv inst sourceId
                                           (car origin) (cadr origin) PIFprop))
             (dbClose sourceId)
             (pckInfo "pckPlaceStructuresInLayout"
                      (sprintf nil "Creating new cell %s %s." inst->library instname))
             ;; create new cell and replace original instance with it.
			 (pckInfo "pckPlaceStructuresInLayout"
                      (sprintf nil "Opening new cell %s %s to flatten its contents."
                               cv~>libName instname))
			 
			 (setq origin
                   (pckShiftPoint origin
								  (car (trBBoxDims instId~>bBox)) 0.0))
			 
             (pckFlattenSynthRow cv nil t)
			 
			 (pckSetpckGen cv~>libName instname "layout")
             
             (pckInfo "pckPlaceStructuresInLayout" (sprintf nil "New origin %L." origin))

			 (dbSave cv)
             ;;
             ;; Stream out and convert to LNF
             (pckPostGenStreamout
              (getShellEnvVar "PDSSTM")  cv~>libName instname (strcat instname ".stm"))
             
             (setq cellList (cons instname cellList))
             )
    (pckAddCellsToCat cv~>libName cv~>cellName cellList)
    (setq port (outfile
                (sprintf nil "%s/%s_%s.cdl" 
                         (getShellEnvVar "TCC_NETLIST_TMP")
                         PIFprop->libName PIFprop->test_row_name)))
    (pckNetlistCdl cv (pckGetPadPCName)
                   (getq cv~>tcc_dpl "PadrowType")					  
                   port)
    (dbSave cv)                 
    (dbClose cv)

    (close port)

    ;; Undefine pckGetConnectivity, so it won't cause problems later in the session
    (when (fboundp 'pckGetConnectivity)
      (putd 'pckGetConnectivity nil))
    )
  )

;;; tccROSMaster.il ends here
