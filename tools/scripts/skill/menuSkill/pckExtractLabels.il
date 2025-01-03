;;
;; (load "pckExtractLabels.il")
;;
;; (load "/nfs/ch/disks/ch_ciaf_disk007/fdk_gwa_disk002/pvrott/fdk73/fossil/pck73_skill/core/skill/pckExtractLabels.il")
;; (pckCreateMasterSheet (list "intel73custom") "/p/fdk/gwa/pvrott/fdk73/work/p6/master.csv")
;;
;; (pckDumpCellList (list (ddGetObj "fdk71pxprimtemplate")) (strcat (getShellEnvVar "FDK_WORK") "/1271.2_pxprimtemplate_cell_list"))
(defun pckDumpCellList (lib_list outf)
  (let (lib cell pOut)
	(if (setq pOut (outfile outf "w"))
		(progn 
		  (foreach lib lib_list
				   (fprintf pOut "Library: %s\n" lib~>name)
				   (foreach cell (sort (dbGetq lib "cells")~>name nil)
							(when (dbAllCellViews lib cell)
							  ;;
							  ;; to ignore cells with no cellviews
							  (fprintf pOut "\t%s\n" cell))
							)
				   )
		  (close pOut)
		  )
	  (progn
		(fprintf stdout "Could not open %s for writing.\n" outf))	  
		)
	)
  )
;;
;; (pckCreateFullCellViewList (list "fdk71p2esd" "fdk71p2idv" "fdk71p2primtemplate" "fdk71p2tapeout" "fdk71p2sram") "<filename here>")
;; (pckCreateFullCellViewList (list "fdk71p6esd" "fdk71p6idv" "fdk71p6primtemplate" "fdk71p6tapeout" "fdk71p6sram") "<filename here>")
;; (pckCreateFullCellViewList (list "fdk71p9esd" "fdk71p9idv" "fdk71p9primtemplate" "fdk71p9tapeout" "fdk71p9sram") "<filename here>")
;; 
;;
(defun pckCreateFullCellViewList (lib_list outf)
  (let (cell pOut)
	(if (setq pOut (outfile outf "w"))
		(progn 
		  (fprintf pOut "LibraryName,Category,CellName,Description,schematic,symbol,interior,layout,pcell,pycell,auCdl,hspiceD,spectre,scs,hsp,cdl\n")
		  ;;(fprintf stdout "LibraryName,Category,CellName,Description,schematic,symbol,interior,layout,pcell,pycell,auCdl,hspiceD,spectre,scs,hsp,cdl\n")
		  (foreach library lib_list
				   (setq lib (ddGetObj library))
				   (foreach cell (sort (dbGetq lib "cells")~>name nil)
							(when (dbAllCellViews lib cell)
							  ;;
							  ;; to ignore cells with no cellviews
							  (fprintf pOut "%s,,%s," library cell) ;; description field is empty so leading comma from view will mark its place
							  ;;(fprintf stdout "%s,e,%s,e" library cell)
							  (foreach view (list "schematic" "symbol" "interior" "layout"
												  "pcell" "pycell" "auCdl" "hspiceD" "spectre" "scs" "hsp" "cdl")
									   (if (member view (dbAllCellViews lib cell))
										   (progn
											 (fprintf pOut ",X" )
											 ;;(fprintf stdout ",f - %s" view )											 
											 )
										 (progn 
										   (fprintf pOut ",")
										   ;;(fprintf stdout ",m - %s" view)										   
										   )
										 ))
							  (fprintf pOut "\n" )
							  ;;(fprintf stdout "\n" )
							  )
							)
				   )
		  (close pOut)
		  )
	  (progn
		(fprintf stdout "Could not open %s for writing.\n" outf))         
	  )
	)
  )
(defun pckExtractLabels (lib_list outf cell_type)
  (let (lib cell cv pOut)
	(if (setq pOut (outfile outf "w"))
		(progn
		  (foreach lib lib_list
				   (setq i 0)
				   ;;(fprintf stdout "foo %L\n" (dbGetq lib "cells"))
				   (foreach cell (dbGetq lib "cells")
							(fprintf stdout ">>>> Processing cell # %d - %s. %d to go.\n" i cell~>name
									 (difference  (length (dbGetq lib "cells")) i))
							(when (member cell_type (dbAllCellViews lib cell~>name))
							  (fprintf pOut "-D- Library: %s Cell: %s View: %s\n" lib~>name cell~>name cell_type)
							  (setq cv
									(dbOpenCellViewByType lib~>name cell~>name cell_type))
							  (foreach obj (setof x cv~>shapes (or  (equal x~>objType "label")  (equal x~>objType "textDisplay")))
									   (case obj~>objType
										 ("label" (fprintf pOut "%s:\n%s\n" obj~>objType obj~>theLabel))
										 ("textLabel" (fprintf pOut "%s:%L\n" obj~>objType obj~>text))
										 ))
							  (dbClose cv)
							  )
							(setq i (add1 i))
							)

				   )		  
		  (close pOut)
		  )
	  (progn  (fprintf stdout "Could not open %s for writing.\n" outf))
	  )
	t
	)
  )
(defun pckDumpFloatIssNets (libName cell_list outf)
  (let (lib cell cv pOut)
	(if (setq pOut (outfile outf "w"))
		(progn
		  (foreach cellName cell_list
				   (pckDebug "pckDumpFloatIssNets" (sprintf nil "Processing cell %s." cellName))
				   (setq cv (dbOpenCellViewByType libName cellName "layout"))				   
				   (foreach obj
							(setof x cv~>shapes (equal x~>objType "label"))
							(when (rexMatchp "floatiss*" obj~>theLabel)
							  (fprintf pOut "%s: %s\n" cellName obj~>theLabel)))
				   (dbClose cv)
				   ;;(fprintf stdout "foo %L\n" (dbGetq lib "cells"))
				   )		  
		  (close pOut)
		  )
	  (progn  (pckDebug "pckDumpFloatIssNets" (sprintf nil "Could not open %s for writing." outf)))
	  )
	t
	)
  )


(defun pckCreateMasterSheet (lib_list outf)
  (let (cell pOut)
	(if (setq pOut (outfile outf "w"))
		(progn 
		  (fprintf pOut "LibraryName,Category,CellName,Description,schematic,symbol,interior,layout,pcell,pycell,auCdl,hspiceD,spectre,topcells,s_subcells,i_subcells,l_subcells,extBBox, lvsBBox, BBox, prBoundary, polyPitch, polyWidth, topLayer, ConLayers\n")
		  ;;(fprintf stdout "LibraryName,Category,CellName,Description,schematic,symbol,interior,layout,pcell,pycell,auCdl,hspiceD,spectre,scs,hsp,cdl\n")
		  (foreach library lib_list
				   (setq lib (ddGetObj library))
				   (foreach cell (sort (dbGetq lib "cells")~>name nil)
							(when (dbAllCellViews lib cell)
							  ;;
							  ;; to ignore cells with no cellviews
							  (fprintf pOut "%s,,%s," library cell) ;; description field is empty so leading comma from view will mark its place
							  ;;(fprintf stdout "%s,e,%s,e" library cell)
							  (foreach view (list "schematic" "symbol" "interior" "layout"
												  "pcell" "pycell" "auCdl" "hspiceD" "spectre")
									   (if (member view (dbAllCellViews lib cell))
										   (progn
											 (fprintf pOut ",X" )
											 ;;(fprintf stdout ",f - %s" view )											 
											 )
										 (progn 
										   (fprintf pOut ",")
										   ;;(fprintf stdout ",m - %s" view)										   
										   )
										 ))
							  ;; topcells
							  (fprintf pOut ",")
							  ;; s_subcells
							  (fprintf pOut ",%s" (pckFindTopCells lib cell "schematic"))
							  ;; s_subcells
							  (fprintf pOut ",%s" (pckFindTopCells lib cell "interior"))
							  ;; l_subcells
							  (fprintf pOut ",%s" (pckFindTopCells lib cell "layout"))
							  ;; extBBox
							  (fprintf pOut ", ")
							  ;; lvsBBox
							  (fprintf pOut ", ")
							  ;; BBox
							  (fprintf pOut ",%s" (pckFindCellBBox lib cell "layout"))
							  ;; prBoundary
							  (fprintf pOut ",%s" (pckFindPRBoundary lib cell "layout") )
							  ;; polyPitch
							  (fprintf pOut ", ")
							  ;; polyWidth
							  (fprintf pOut ", ")
							  ;; topLayer
							  (fprintf pOut ",%s" (pckFindTopLayer lib cell "layout"))
							  ;; conlayers
							  (fprintf pOut ",%s" (pckFindConLayers lib cell "layout"))
							  ;;
							  (fprintf pOut "\n" )
							  ;;(fprintf stdout "\n" )
							  )
							)
				   )
		  (close pOut)
		  )
	  (progn
		(fprintf stdout "Could not open %s for writing.\n" outf))         
	  )
	)
  )
(defun pckFindTopCells (libName cellName view)
  (let (cv (str ""))
	(when (member view (dbAllCellViews libName cellName))
	  (setq cv (dbOpenCellViewByType libName cellName view))
	  (setq cell_list cv~>instanceMasters~>cellName)
	  (when cell_list
		  (progn
			(setq str (pckListToStringWComma cell_list "\""))))
	  (dbClose cv)
	  )	
	str
	)
  )
(defun pckListToStringWComma (ll str)
  (case (car ll)
	(nil
	 ;;(sprintf str "%s" str)
	 (sprintf str "%s\"" str)
	 str)
	(t (if (or (equal "" str) (equal "\"" str))
		   (sprintf str "%s%s" str (car ll))
		   (sprintf str "%s,%s" str (car ll))
		 )
	   (pckListToStringWComma (cdr ll) str)
	   )
	)
  )
(defun pckFindCellBBox (libName cellName view)
  (let (cv (str ""))	
	(when (member view (dbAllCellViews libName cellName))
	  (setq cv (dbOpenCellViewByType libName cellName view))
	  (sprintf str "%Lx%L" (car (trBBoxDims cv~>bBox)) (cadr (trBBoxDims cv~>bBox)))
	  (dbClose cv)
	  )
	str
	)
  )
(defun pckFindPRBoundary (libName cellName view)
  (let (cv (str ""))	
	(when (member view (dbAllCellViews libName cellName))
	  (setq cv (dbOpenCellViewByType libName cellName view))
	  (when cv~>prBoundary~>bBox
		(sprintf str "%Lx%L" (car (trBBoxDims cv~>prBoundary~>bBox)) (cadr (trBBoxDims cv~>prBoundary~>bBox))))
	  (dbClose cv)
	  )
	str
	)
  )
(defun pckFindConLayers (libName cellName view)
  (let ((str "") shape_list layer_list 
		(full_stack '("viacon"	"metal0" "via0"	"metal1" "via1"	"metal2" "via2"	"metal3" "via3"	"metal4" "via4"	"metal5" "via5"	"metal6" "via6"	"metal7" "via7"	"metal8" "via8"	"metal9" "via9"	"metal10" "via10" "tm1")))
	(when (member view (dbAllCellViews libName cellName))
	  (setq cv (dbOpenCellViewByType libName cellName view))
	  (setq shape_list
			(setof x cv~>lpps
				   (and (equal x~>purpose "drawing")
						(member x~>layerName full_stack))
				   ))
	  
	  ;;(setq shape_list (sort shape_list~>layerName nil))
	  (foreach layer full_stack
			   (when (member layer shape_list~>layerName)
				 (setq layer_list (cons layer layer_list))
				 )
			   )
	  
	  ;;(fprintf stdout )
	  (when layer_list
			(setq str (pckListToStringWComma layer_list "\"")))
	  (dbClose cv)
	  )
	;;(fprintf stdout "-D- %s %s\n" cellName str)
	str
	)
  )
(defun pckFindTopLayer (libName cellName view)
  (let ((str "") shape_list 
		(full_stack '("viacon"	"metal0"	"via0"	"metal1"	"via1"	"metal2"	"via2"	"metal3"	"via3"	"metal4"	"via4"	"metal5"	"via5"	"metal6"	"via6"	"metal7"	"via7"	"metal8"	"via8"	"metal9"	"via9"	"metal10"	"via10"	"tm1")))
	(when (member view (dbAllCellViews libName cellName))
	  (setq cv (dbOpenCellViewByType libName cellName view))
	  (setq shape_list (setof x cv~>lpps
							  (and (equal x~>purpose "drawing")
								   (member x~>layerName full_stack)
								   )))
	  ;;(setq shape_list (sort shape_list~>layerName nil))
	  (foreach layer full_stack
			   (when (member layer shape_list~>layerName)
				 (setq str layer)
				 )
			   )
	  
	  ;;(fprintf stdout )
	  (dbClose cv)
	  )
	str
	)
  )
