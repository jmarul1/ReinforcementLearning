
;; Script for dumping the VID of a cell
;; Balaji Ramasubramanian
;; Written for the fullchip collaterals





/*
Written to Dump all the VIDs for all the cells in the particular library
*/
(defun pckDumpVIDofLibrary (t_lib @optional (vid_layer "l9text") (logfile "viddump.log"))
(let (ce cv vid vidList vidFile)
	(if (nequal (ddGetObj t_lib) nil) (progn
		(setq vidFile (outfile (strcat (getShellEnvVar "FDK_WORK") "/" logfile)))
		;; Setup a file for writing
		(foreach ce (setof x (ddGetObj t_lib)~>cells (member "layout" x~>views~>name))
		 ;; Open each cell and get the VID of the cell
			(setq t_cell ce~>name)
			(setq cv (dbOpenCellViewByType t_lib t_cell "layout"))
			(setq vidList (pckGetVID cv vid_layer))
			(dbClose cv)
			(if (nequal 1 (length vidList)) (progn
				;; If the number of VIDs is not 1
				(if (equal 0 (length vidList)) (progn
					;; If there are no VIDs, error
					(pckError "pckDumpVIDofLibrary" (strcat "No VID on cell " t_cell))
					(fprintf vidFile (strcat "-E- " "No VID on cell " t_cell "\n"))
				) (progn
					;; If there are more than 1 VIDs, then again error saying you have more than one VID
					(pckError "pckDumpVIDofLibrary" (strcat "More than one VIDs on cell " t_cell))
					(fprintf vidFile (strcat "-E- " "More than one VID on cell " t_cell "\n"))
				))
			))
			(foreach vid vidList
			 ;; Now check if the VIDs are valid. So look at each VID.
				(if (not (rexMatchp t_cell vid)) (progn
					;; Make sure the cell has a VID that contains the cell name. If not, error.
					(pckError "pckDumpVIDofLibrary" (strcat "The cell " t_cell " has wrong VID: " vid))
					(fprintf vidFile (strcat "-E- " "The cell " t_cell " has wrong VID: " vid "\n"))
				) (progn
					;; If it has the cellname, it is valid VID.
					(pckInfo "pckDumpVIDofLibrary" (strcat "The cell " t_cell " has correct VID: " vid))
					(fprintf vidFile (strcat "-I- " "The cell " t_cell " has correct VID:" vid "\n"))
				))
			)
		)
		(close vidFile)
	))
))


/*
Written to compare VIDs of two different cells
*/
(defun pckCompVIDCells (t_lib1 t_cell1 t_lib2 t_cell2 @optional (vid_layer "l9text") (pattern nil))
(let (cv1 cv2 vids1 vids2 v1 v2 (retdata (list nil 'type "NOT_CHECKED" 'value t)))
	(if (and (nequal nil (ddGetObj t_lib1 t_cell1 "layout")) (nequal nil (ddGetObj t_lib2 t_cell2 "layout"))) (progn
		(setq cv1 (dbOpenCellViewByType t_lib1 t_cell1 "layout"))
		(setq cv2 (dbOpenCellViewByType t_lib2 t_cell2 "layout"))
		(if (and (nequal cv1 nil) (nequal cv2 nil)) (progn
			(setq vids1 (pckGetVID cv1 vid_layer))
			(setq vids2 (pckGetVID cv2 vid_layer))
			(if (or (equal 0 (length vids1)) (equal 0 (length vids2))) (progn
				(pckError "pckCompVIDCells" (strcat "No VID labels on one of the cells " t_lib1 "/" t_cell1 " or " t_lib2 "/" t_cell2))
				(setq retdata (list nil 'type "NO_VID" 'value nil))
			) (progn
				(setq retdata (list nil 'type "MULT_VID_MATCH" 'value t))
				(foreach v1 vids1
					(foreach v2 vids2
						(if (equal pattern nil) (progn
							(if (nequal v1 v2) (progn
								(setq retdata (list nil 'type "MULT_VID_MISMATCH" 'value nil))
							))
						) (progn
							(if (not (and (rexMatchp pattern v1) (rexMatchp pattern v2))) (progn
								(setq retdata (list nil 'type "PATTERN_MISMATCH" 'value nil))
							))
						))
					)
				)
			))
		) (progn
			(pckError "pckCompVIDCells" "Something is strange. Have you populated?")
			(setq retdata (list nil "DSSC_NOALIGN" 'value nil))
		))
	) (progn
		(pckError "pckCompVIDCells" "One of these cells has no layout view")
		(setq retdata (list nil 'type "NO_LAYOUT" 'value nil))
	))
	retdata
))



/*
Written to compare VIDs between cells of the same type.
Note: Loop over cells in first library to check for cells of same name pattern in the other library
*/
(defun pckCompVIDLibs (t_lib1 t_lib2 @optional (vid_layer "l9text"))
(let (l_cell1 l_cell2 ce1 ce2 t_cell1 t_cell2)
	(if (and (nequal nil (ddGetObj t_lib1)) (nequal nil (ddGetObj t_lib2))) (progn
		(setq l_cell1 (setof x (ddGetObj t_lib1)~>cells (nequal nil (member "layout" x~>views~>name))))
		(setq l_cell2 (setof x (ddGetObj t_lib2)~>cells (nequal nil (member "layout" x~>views~>name))))
		(foreach ce1 l_cell1
			(setq t_cell1 ce1~>name)
			(rexMatchp "...\\(.*\\)" t_cell1)
			(setq cell_pattern (rexSubstitute "...\\1"))
			(setq ce2 (car (setof x l_cell2 (rexMatchp (strcat cell_pattern "$") x~>name))))
			(if (nequal ce2 nil) (progn
				(setq t_cell2 ce2~>name)
				(pckInfo "pckCompVIDLibs" (strcat "Comparing: " t_lib1 "/" t_cell1 " and " t_lib2 "/" t_cell2))
				(if (pckCompVIDCells t_lib1 t_cell1 t_lib2 t_cell2 vid_layer)->value (progn
					(pckInfo "pckCompVIDLibs" "VIDs matched")
				) (progn
					(pckInfo "pckCompVIDLibs" "Mismatched. Comparing VID patterns instead.")
					(if (pckCompVIDCells t_lib1 t_cell1 t_lib2 t_cell2 vid_layer (strcat cell_pattern "_"))->value (progn
						(pckInfo "pckCompVIDLibs" (strcat "VIDs matched a pattern " cell_pattern "_"))
					))
				))
			) (progn
				(pckError "pckCompVIDLibs" (strcat "No cell corresponding to " t_lib1 "/" t_cell1 " was found in " t_lib2))
			))
		)
	) (progn
		(pckError "pckCompVIDLibs" "One of the libraries is not loaded")
	))
	t
))



