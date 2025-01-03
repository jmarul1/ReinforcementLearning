;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; VERSION:  
;;      $Id: pckSchMenu.il.rca 1.2 Tue Mar 22 17:58:22 2011 pvrott Experimental $
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


;; (load "pckSchMenu.il")

;;(printf "\nLoading %s pckSchMenu.il...\n" PCK_PROCESS)

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

(defun pckMenuSchPulldownMenu ()                  
  (let (pckMenuSchPulldownMenu)
	(hiCreatePulldownMenu
	 'pckMenuSchPulldownMenu "PCK Tools"
	 (list
	  ;; Verification flows ;;;;;;;;;;;;;;;
	  (hiCreateSeparatorMenuItem ?name 'sep1)
	  
	  (hiCreateMenuItem
	   ?name 'pckRunPDS 
	   ?itemText  "Run PDS DRC"
	   ?callback  "pckMenuRunPDSForm()")
	  
	  (hiCreateMenuItem
	   ?name 'pckStartVUE
	   ?itemText  "Start VUE on Previously Run PDS DRC"
	   ?callback  "pckStartVUEMenu()")
	  
	  (hiCreateMenuItem
	   ?name 'pckQCreateNetlist
	   ?itemText  "Quick Netlist Generate"
	   ?callback "pckQuickNetlistGUI()")
	  
	  ;; Layout Manipulation ;;;;;;;;;;;;;;;;;
	  (hiCreateSeparatorMenuItem ?name 'sep2)
	  )        
	 "")
  pckMenuSchPulldownMenu
  ) ;; let
)


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

(defun pckSchUserPostInstallTrigger (arg)
  (pckSchUserPostInstallMenu arg->window))

(defun pckSchUserPostInstallMenu (wid)
  (let (menu editableItems)

    (setq menu (pckMenuSchPulldownMenu))

    ;; Apparently these have to be GLOBALS to avoid error messages when menus are opened/closed.
    (setq pckMenuSchPulldownMenu (pckMenuSchPulldownMenu))
	
    (unless (member menu (hiGetBannerMenus wid))            
      (hiInsertBannerMenu
       wid
       menu
       (length (hiGetBannerMenus wid))))


	;; The following items require the layout to be opened with Write permission.
    ;; If not, this will DISABLE the following menu items.  To disable additional
    ;; items if layout now writeable, just add them to this list:
    ;; (setq editableItems 
    ;;       (list
    ;;        (list menu1 'pckCreatePolyGrid)))
        
    ;; (if (member ((geGetEditCellView wid)~>cellView~>mode) (list "a" "w"))
    ;;     (mapcar (lambda (x) 
    ;;               (hiEnableMenuItem (car x) (cadr x) wid))
    ;;             editableItems)
    ;;     (mapcar (lambda (x) 
    ;;               (hiDisableMenuItem (car x) (cadr x) wid))
    ;;             editableItems))
	
);; let
);; pckUserPostInstallMenu


(when (getd 'deGetAppInfo)  ;; BUGFIX 10-10-2005 This needs to be added so load does not craash when run for stream jobs!
  (when (not (member 'pckSchUserPostInstallTrigger (deGetAppInfo "schematic")->userPostInstallTrigList ) )      
    (deRegUserTriggers "schematic" nil nil 'pckSchUserPostInstallTrigger))
  )
