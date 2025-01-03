;;
;; (load "pckFindGndSymbol.il")
;;
(defun pckFindGndSymbol (libName)
  (let ((view_list '("schematic" "interior")) (cell_list '()
														 ))
	 (foreach cell (dbGetq (dbGetq (ddGetObj libName) "cells") "name")
			  (pckInfo "pckCheckLibBindings"
					   (sprintf nil "Processing cell %s %s. Available views - %L"
								libName cell (dbAllCellViews (ddGetObj libName) cell)))
			  (foreach view view_list					   
					   (when (member view (dbAllCellViews (ddGetObj libName) cell))
						 (fprintf stdout "-D- Library: %s Cell: %s View: %s\n" libName cell view)			   
						 (when (setq cv (dbOpenCellViewByType libName cell view "" "r"))
						   (when
							   (and
								(member "analogLib" cv~>instances~>libName)
								(or
								  (member "vss" cv~>instances~>cellName)
								  (member "gnd" cv~>instances~>cellName)))
							 (pckInfo "pckFindGndSymbol" (sprintf nil ">> GND found in %L %L" libName cell))
							 (setq cell_list (cons cell cell_list))
							 )				  
						   (dbClose cv))
						 ))
			  )
	 (fprintf stdout "LIbrary CellName\n")
	 (foreach elem cell_list
			  (fprintf stdout "%s %s\n" libName elem)
			  )
	 t
	
	)
  )