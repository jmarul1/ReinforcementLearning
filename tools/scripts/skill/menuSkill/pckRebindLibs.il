;; Rebind layout cellviews by changing the instHeaders' master library header to new library
;; Searches for "_x4tc_" string and replaces with "_1265tc_" string!
;; Eng Siah -- 6/6/2005  Modified from Vincent's rebind50.il
;; Current list of libraries are read from a txt file and all cells under the libs are rebinded!
;; (load "pckRebindLibs.il")

;; view can be layout, schematic etc..
;;
;; rebind cells to current lib they belong to 
;; input libname   : libname = "thmdiode_sch"
;; viewnam         : viewname = "schematic"
;; prefix1	   : prefix1 = "x10"
;; prefix2	   : prefix2 = "x11"
;; toplvl libname  : topblock = "thmdiode_sch"
;; (pckRebindLibCells50 libname viewname lib_mapping_file)
;;
;; (pckRebindLibCells "x6cthm_1266spckt_sch" "schematic" "" "" "" "x6cthm_1266spckt_sch" )
;; (pckRebindLibCells libname viewname lib_mapping_file prefix1 prefix2)



;; use these only
;; Use ddGetObj to find lib, cells, views, files 
;;
(defun pckRebindLibCells (libname viewname lib_mapping_file)
  (let ( newbind libobj outport c )
         (unless (isDir "tmp/wrk/")
          (sh (strcat "mkdir -p /tmp/wrk" )))

	(setq outport (outfile (strcat "/tmp/wrk/" libname "_rebindstat.txt") "w" ))
	(if (isFileName lib_mapping_file)
	  (progn 
		(setq get_new_lib (makeTable "atable" nil))
		(setq inf (infile lib_mapping_file))
		(when inf
		  (while (gets oneLine inf )
			(setq temp (parseString oneLine ))
			(setq new_lib (nth 1 temp))
			(setq old_lib (nth 0 temp))
			get_new_lib[old_lib] = new_lib
			(printf "-Debug- Old Lib %s new lib %s\n" old_lib new_lib)
			)
		  ))
	  (progn
		(fprintf stdout "--E-- Cannot open map file %s." lib_mapping_file)
		)
	  )		  
	(setq libobj  (ddGetObj libname))

	(foreach c libobj~>cells~>name
			 (printf "Looking at cell %s from library %s ... \n" c libname )
			 (fprintf outport "Looking at cell %s from library %s ... \n" c libname)
			 (case (typep viewname)
			   (string  ;; can use (get_pname if you want to check like string.
				(fprintf stdout "Processing cellview %s\n" viewname)
				(pckRebindLibCellView libname c viewname))
			   (list 
				(fprintf stdout "Processing views %L\n" viewname)
				(mapcar
				 (lambda (x)
				   (pckRebindLibCellView libname c x)) viewname)
				)
			   (t (fprintf stdout "Not sure what to do with cellview %L of type %s... \n" viewname (typep viewname)))
			   )
			 )
	(drain outport)
	(close outport) 
	t) ; Let
  ); EOF



(defun pckRebindLibCellView (lib cell view)
  (let (cv oldlib h extlst newlib newcell bindcell outport )
    (setq outport
		  (outfile
		   (strcat "/tmp/wrk/" lib "_rebindstat.txt") "a" ))
    ;;(setq cv (dbOpenCellViewByType lib cell view nil "a"))
    (if (and
		 (member view (dbAllCellViews (ddGetObj lib) cell))		 
		  (setq cv (dbOpenCellViewByType lib cell view nil "a")))
		(progn
		  (foreach h cv~>instHeaders 
				   (when h~>libName
					 oldlib = h~>libName
					 bindcell = h~>cellName
					 (when get_new_lib[oldlib] 
					   h~>libName = get_new_lib[oldlib]
					   )
					 (fprintf outport "-I- Rebinding block lib cell %s from Library %s ... \n" bindcell oldlib)
					 (printf "-I- Rebinding block lib cell %s from Library %s ... \n" bindcell oldlib)
					 )					; when
				   )
		  (fprintf outport "-I- Cell %s in Library %s processed OK \n\n" cell lib)
		  (printf "-I- Cell %s in Library %s processed OK \n\n" cell lib)
		  (when (equal view "schematic")  
			(schCheck cv))
		  (dbSave cv)
		  (dbClose cv))
	  (progn 
		(fprintf outport "-I- Cell %s in Library %s does not have %s cellview or the cell is not editable!!! \n\n" cell lib view)
		(printf "-I- Cell %s in Library %s does not have %s cellview or the cell is not editable!!! \n\n" cell lib view))
	  )
	t
   ); if cv != nil
 )


