;;

;; need to compare 2 library schematic/interior view content so we will netlist different views
;; and then compare
;; used during b8lib migration
;; example: (pckCdlNetlistToCompare  (list (ddGetObj myLibName)) ?cell_list (list "interior" "schematic")  ?debug "no")



(defun pckCdlNetlistToCompare (lib_list @key
					   (data_suf "")
					   (debug "yes")
					   (pandoraDir (strcat (getShellEnvVar "FDK_WORK") "/pandora/data"))
					   (create_sch "yes")
					   (cell_list (list "schematic"))
					   )
  "Create cdl netlists in pandora directory for list of libraries"
  ;;
 
  (let (libs c1 pandoraDir2)
	(fprintf stdout "Pandora directory - %s\n" pandoraDir)
	(when (or (nequal data_suf "") (nequal cell_list ""))
	 	(foreach c1 cell_list
	  		(setq pandoraDir2 (strcat pandoraDir "/" data_suf "/" c1 ) )
			(unless (isDir pandoraDir2)
	  			(sh (strcat "mkdir -p " pandoraDir2)))
		)
	  ) ;; end of when


	(foreach lib lib_list ;;libs
		(setq i 0)
		 (foreach cell (dbGetq lib "cells")
			  (fprintf stdout ">>>> Processing cell # %d - %s. %d to go.\n" i cell~>name
					   (difference  (length (dbGetq lib "cells") )
					   i))	
		          (foreach c1 cell_list	 
			  	(when (member c1 (dbAllCellViews lib cell~>name))
					(fprintf stdout "%s view exists for %L:%L\n" c1 lib~>name cell~>name)
					(setq pandoraDir2 (strcat pandoraDir "/" data_suf "/" c1 "/" lib~>name ) )

					 (unless (isDir pandoraDir2)
				   		     (sh (strcat "mkdir -p " pandoraDir2))
					  )  ;; end unless

					;; now create netlist
					(fprintf stdout "Running %L %L  %L\n" lib~>name cell~>name pandoraDir2)
						  (when (equal debug "no")
							  (pckMakeQuickCDLNetlist
							   cell~>name
							   lib~>name
							   pandoraDir2
							   (pckNetlistNameCB cell~>name)
							   ))
				) ;; end when
			  ) ;; end foreach c1
			  (setq i (add1 i))
		) ;; end foreach cell
	   ) ;; end foreach lib
	t
    ) ;; end let
) ;; end defun

