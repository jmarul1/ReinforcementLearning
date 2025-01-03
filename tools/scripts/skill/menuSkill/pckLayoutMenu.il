;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; VERSION:  
;;      $Id: pckLayoutMenu.il.rca 1.6 Mon Jun  6 22:29:19 2011 bramas2 Experimental $
;;
;; NAME
;;      pckLayoutMenu.il  -  create TCC menu in layout view
;;
;; DESCRIPTION
;;      This file creates a pull-down menu with TCC's specific menu items.
;;
;;      Start with loading this file in the CIW command window:
;;
;; GLOBAL VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;
;; (load "pckLayoutMenu.il")
;;


;;(printf "\nLoading %s pckLayoutMenu.il...\n" PCK_PROCESS)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;NAME
;;      pckMenuLayPulldownMenu
;;
;;SYNOPSIS
;;      pckMenuLayPulldownMenu()
;;
;;DESCRIPTION
;;      Creates menu to attach to layout windows
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun pckMenuLayPulldownMenu ()                  
(let (pckMenuLayPulldownMenu)
  (hiCreatePulldownMenu
    'pckMenuLayPulldownMenu "PCK Tools"
    (list
	 ;; Layout view help tools ;;;;;;;;;;;;

	 
	 (hiCreateMenuItem
	  ?name 'CopyRenameHierUI
	  ?itemText  "Copy and Rebind Utility"
	  ?callback  "CopyRenameHierUI()")

	 (hiCreateMenuItem
	  ?name 'pckLayerControlMenu
	  ?itemText  "LSW Layer Controls"
	  ?callback  "pckLayerControlMenu()")

           
	 (hiCreateMenuItem
	  ?name 'pckInstTree
	  ?itemText  "Hide Instance View"
	  ?callback  "pckInstTree()")
		 
	 (hiCreateMenuItem
	  ?name 'pckHilightRods
	  ?itemText "Hilight ROD objects"
	  ?callback "pckHilightRods()"
	  )
	 
	 (hiCreateMenuItem
           ?name 'pckCreatePolyGrid
           ?itemText  "Create poly grid"
           ?callback  "pckMenuAddFakePolyForm()")

           
	 ;; Verification flows ;;;;;;;;;;;;;;;
	 (hiCreateSeparatorMenuItem ?name 'sep1)

	 (hiCreateMenuItem
	  ?name 'pckRunPDS ;; Removed per Vincent, says uses extra license
	  ?itemText  "Run PDS DRC"
	  ?callback  "pckMenuRunPDSForm()")
                   
	 (hiCreateMenuItem
	  ?name 'pckStartVUE
	  ?itemText  "Start VUE for this cell"
	  ?callback  "pckStartVUEMenu()")
         
	 (hiCreateMenuItem
	  ?name 'pckCalculateLocalDensity
	  ?itemText  "Calculate local density"
	  ?callback  "pckCalculateLocalLayerDensityForm()")
         
	 (hiCreateMenuItem
	  ?name 'pckHighlightNet
	  ?itemText  "Hilight Net"
	  ?callback "pckHilightNetStartup()")

	 (hiCreateMenuItem
	  ?name 'pckQStream
	  ?itemText  "Quick STREAM File (pCells OK)"
	  ?callback "pckQuickStreamGUI()")
		 
         
	 (hiCreateMenuItem
	  ?name 'pckXor2StreamFiles
	  ?itemText  "XOR this layout with ..."
	  ?callback  "pckXORStreamGUI()")
         
	 (hiCreateMenuItem
	  ?name 'icfTestRowFillMenu
	  ?itemText  "TRFF - ICF Filler Cell Flow"
	  ?callback  "icfTestRowFillMenu()")
         
	 ;; Layout Manipulation ;;;;;;;;;;;;;;;;;
	 (hiCreateSeparatorMenuItem ?name 'sep2)
	 )        
    "")
  pckMenuLayPulldownMenu
  ) ;; let
)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;NAME
;;      pckMenuAddFakePolyForm
;;
;;SYNOPSIS
;;      pckMenuAddFakePolyForm()
;;
;;DESCRIPTION
;;      Creates menu to add "fake poly" (poly testRow) in the given area
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun pckMenuAddFakePolyForm ()

  (let (fakePolyAreaWX fakePolyAreaWY fakePolyForm  )

    (setq fakePolyAreaWX ( hiCreateFloatField
                           ?name 'fakePolyAreaWX
                           ?prompt "Area Width"
                           ?defValue car(cadr( (geGetEditCellView)~>bBox))
                           ?editable t
                           ) 
          )

    (setq fakePolyAreaWY ( hiCreateFloatField
                           ?name 'fakePolyAreaWY
                           ?prompt "Area Height"
                           ?defValue cadr(cadr( (geGetEditCellView)~>bBox))
                           ?editable t
                           ) 
          )

    (setq fakePolyForm ( hiCreateAppForm
                         ?name 'fakePolyForm
                         ?formTitle "Add poly grid"
                         ?callback list( "pckMenuAddFakePolyOKCB( (geGetEditCellView) fakePolyForm )" )
                         ?fields list( fakePolyAreaWX fakePolyAreaWY )
                         ?unmapAfterCB t
                         )
          )

    ( hiDisplayForm fakePolyForm )

    t

    ); let
  )

(defun pckMenuAddFakePolyOKCB ( cv formHandle )
  (let ( )
    
    (pckAddFakePoly cv formHandle)
                 
    t
    )
  );; pckMenuRunPDSFormOKCB



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;NAME
;;      pckUserPostInstallTrigger
;;
;;SYNOPSIS
;;      pckUserPostInstallTrigger(args)
;;
;;DESCRIPTION
;;      Add menu items to drawing menu bar at top
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun pckUserPostInstallTrigger (arg)
  (pckUserPostInstallMenu arg->window))

(defun pckUserPostInstallMenu (wid)
  (let (menu1 menu2 editableItems)

    (setq menu1 (pckMenuLayPulldownMenu))

    ;; Apparently these have to be GLOBALS to avoid error messages when menus are opened/closed.
    pckMenuLayPulldownMenu = pckMenuLayPulldownMenu()
	
    (unless (member menu1 (hiGetBannerMenus wid))            
      (hiInsertBannerMenu
       wid
       menu1
       (length (hiGetBannerMenus wid))))


	;; The following items require the layout to be opened with Write permission.
    ;; If not, this will DISABLE the following menu items.  To disable additional
    ;; items if layout now writeable, just add them to this list:
    (setq editableItems 
          (list
           (list menu1 'pckCreatePolyGrid)))
        
    (if (member ((geGetEditCellView wid)~>cellView~>mode) (list "a" "w"))
        (mapcar (lambda (x) 
                  (hiEnableMenuItem (car x) (cadr x) wid))
                editableItems)
        (mapcar (lambda (x) 
                  (hiDisableMenuItem (car x) (cadr x) wid))
                editableItems))
	
);; let
);; pckUserPostInstallMenu


(when (getd 'deGetAppInfo)  ;; BUGFIX 10-10-2005 This needs to be added so load does not craash when run for stream jobs!
  (when (not (member 'pckUserPostInstallTrigger (deGetAppInfo "maskLayout")->userPostInstallTrigList ) )      
    (deRegUserTriggers "maskLayout" nil nil 'pckUserPostInstallTrigger))
  )





      
