;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; $Id: CopyRenameHierRegex.il.rca 1.1 Tue Mar 22 17:57:38 2011 pvrott Experimental $
;; ;
;; ;Copy a whole hier over and rename/rebind cells in the process
;; ;
;; ;This needs TraverseToplevel from /prj/advda/utils/skill/showHierarchy_headers_43.il
;; ;
;; ;(load "/tccdev/skill/showHierarchy_headers.il")
;; ;(load "/tccdev/skill/CopyRenameHierRegex.il")
;; ;
;; ;USAGE : z(CopyRename  "source_lay" "source_cell" "schematic" "^x5b" "sc64" "dest_lib" (list exclude_libs))
;; ;This hier copies x4cgtbp1 from cap_x4tc_lay to x51bda_lib and prefixes the copies with "x5ply". It also rebinds the copies
;; ;so that the copies are rebound to point to the new cells. It skips the copy and rebinsd steps for cells from
;; ;the libraries "label_x4tc_lay" & "pad_x4tc_lay"
;; ;
;; ; A. Vincent Rayappa -- 8/23/2004
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Modification:  This script now allows for a user to change the name of cells within a hierarchy.  replacePattern2 
;; should have the same value as replacePattern -- it is a dummy variable.
;; Usage: Rename and Rebind all cells under top cell x6ac_gcapp (which have cells x6ac_gcapp_* and x6as_gcapn_*) to
;; cells named x6ac_gcppu_*.  First rename all cells to x6ac_gcpup_* and x6ac_gcpun_* using srchPattern "x6ac_gcap"
;; and replacePattern "x6ac_gcpu".  Then reapply the function to rename x6ac_gcpun_* to x6ac_gcpup_* using srchPattern 
;; "x6ac_gcpun_" and replacePattern "x6ac_gcpup_".  Finally apply this script to rename/rebind all cells named
;;  x6ac_gcpup_* to x6ac_gcppu_*.
;;
;;
;; (load "/prj/advda/utils/skill/CopyRenameHierRegex.il")
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; To dump hierarchy:
;;(TraverseToplevel lib cell "layout" (lambda (x) (printf "%L %L %L\n" (getSGq x libName) (getSGq x cellName) (getSGq x viewName))))

(defun TraverseToplevel (lib cell view fn @optional (startat 0) (asList nil))
  (let ((cv (dbOpenCellView lib cell view)) 
    (index startat) 
    (pathTable (makeTable "pathTable" nil))
    toprows lst)
    ;(setq toprows (getSGq cv instHeaders) FIRSTmaster)
    (setq toprows (getSGq cv instHeaders))
    (setarray pathTable (strcat lib " " cell " " view) 1)
    (while (lessp index (length toprows))
      (printf "Looking at : %d/%d - %s/%s \n" index 
          (length toprows) 
          (nth index toprows)~>master~>cellView~>cellName 
          (nth index toprows)~>master~>cellView~>libName)
      (TraverseHeaders (nth index toprows) pathTable fn)
      (setq index (plus index 1)))
    (if asList
    (progn
     (foreach key pathTable
          (setq lst (cons (parseString key) lst)))
     lst)
    pathTable)))


(defun TraverseToplevelList (lst fn @optional (startat 0))
  (let ((index startat)
    (pathTable (makeTable "pathTable" nil)))
    (while (lessp index (length lst))
      (printf "Looking at %L (%d/%d).\n" (nth index lst) index (length lst))
      (TraverseHeaders (dbOpenCellView (cadr (nth index lst)) (car (nth index lst)) "layout")~>instHeaders
               pathTable
               fn)
      (setq index (plus index 1)))))

(defun TraverseHeaders (headers cache fn)
  (let (mastercv result)
    ;;force instHeaders to be a list
    (when (atom headers)
      (setq headers (list headers)))
    (foreach h headers
         (errset 
          (progn 
        (setq mastercv h~>master~>cellView)
        (unless (arrayref cache (strcat mastercv~>libName " " mastercv~>cellName " " mastercv~>viewName))
          ;(printf "Looking at %s in %s.\n" mastercv~>cellName mastercv~>libName)
          (setq result (funcall fn mastercv))
          (setarray cache (strcat mastercv~>libName " " mastercv~>cellName " " mastercv~>viewName) 1)
          (when (mastercv~>instHeaders)
            (mapcar (lambda (x) (TraverseHeaders x cache fn)) mastercv~>instHeaders))))
          t)
         )))


(defun CopyRename (lib cell view srchPattern replacePattern replacePattern2 destlib exclude_libs
                   @optional (nonMatchLeaveAsIs nil))  
  (let ((hierTbl (TraverseToplevel lib cell view (lambda (x) t)))
    lcvToCopy srclst dstlst ref newlst cv h)
    (rexCompile srchPattern)
    ;;filter out cv that are in exclude_libs
    (foreach lcv hierTbl
         (setq srclst (parseString lcv))
         (printf "string value = %s\n" lcv)
         (if (member (nth 0 srclst) exclude_libs)
             (progn 
               (remove lcv hierTbl))
             (progn 
               (if (rexMatchp srchPattern (nth 1 srclst))
                   (progn 
                     (setarray hierTbl lcv (strcat destlib " " (rexReplace (nth 1 srclst) replacePattern 0) " " (nth 2 srclst))))
                   (progn
                     (if nonMatchLeaveAsIs
                         (setarray hierTbl lcv (strcat destlib " " (nth 1 srclst) " " (nth 2 srclst)))
                         (setarray hierTbl lcv (strcat destlib " " (strcat replacePattern "_" (nth 1 srclst)) " " (nth 2 srclst)))))))))
    ;;copy over cv
    (printf "Copying hier ...\n")
    (foreach lcv hierTbl
         (setq srclst (parseString lcv))
         (setq dstlst (parseString hierTbl[lcv]))
         (dbCopyCellView (dbOpenCellView (nth 0 srclst)(nth 1 srclst)(nth 2 srclst))
                 (nth 0 dstlst) (nth 1 dstlst)(nth 2 dstlst)))
    ;;rebind
    (printf "rebinding hier ...\n")
    (foreach lcv hierTbl
        (setq srclst (parseString lcv))
        (setq dstlst (parseString hierTbl[lcv]))
        (setq cv (dbOpenCellView (nth 0 dstlst) (nth 1 dstlst) (nth 2 dstlst) nil "a"))
        (foreach h cv~>instHeaders
             (setq ref (strcat h~>libName " " h~>cellName " " h~>viewName))
             ;(printf "Checking %s \n" ref)
             (when hierTbl[ref]
               (setq newlst (parseString hierTbl[ref]))
               ;(printf "   ... resetting reference to %s \n" ref)
               (h~>instances~>master = (dbOpenCellView (nth 0 newlst) (nth 1 newlst) (nth 2 newlst)))))
        (dbSave cv))
    (printf "Done.\n")))


;;rename_fn needs to be a function that takes one parameter and returns one value:
;; - the parameter will be the existing cell name
;; - the return value needs to be the new name for the cell
;;
(defun CopyRenameFlex (lib cell view rename_fn destlib exclude_libs)
  (let ((hierTbl (TraverseToplevel lib cell view (lambda (x) t)))
        lcvToCopy srclst dstlst ref newlst cv h)
  ;;filter out cv that are in exclude_libs
  (foreach lcv hierTbl
           (setq srclst (parseString lcv))
           (if (member (nth 0 srclst) exclude_libs)
               (progn 
                 (remove lcv hierTbl))
               (progn
                 (setarray hierTbl lcv (strcat destlib " " (funcall rename_fn (nth 1 srclst)) " " (nth 2 srclst))))))  
    ;;copy over cv
    (printf "Copying hier ...\n")
    (foreach lcv hierTbl
         (setq srclst (parseString lcv))
         (setq dstlst (parseString hierTbl[lcv]))
         (dbCopyCellView (dbOpenCellView (nth 0 srclst)(nth 1 srclst)(nth 2 srclst))
                 (nth 0 dstlst) (nth 1 dstlst)(nth 2 dstlst)))
    ;;rebind
    (printf "rebinding hier ...\n")
    (foreach lcv hierTbl
        (setq srclst (parseString lcv))
        (setq dstlst (parseString hierTbl[lcv]))
        (setq cv (dbOpenCellView (nth 0 dstlst) (nth 1 dstlst) (nth 2 dstlst) nil "a"))
        (foreach h cv~>instHeaders
             (setq ref (strcat h~>libName " " h~>cellName " " h~>viewName))
             ;(printf "Checking %s \n" ref)
             (when hierTbl[ref]
               (setq newlst (parseString hierTbl[ref]))
               ;(printf "   ... resetting reference to %s \n" ref)
               (h~>instances~>master = (dbOpenCellView (nth 0 newlst) (nth 1 newlst) (nth 2 newlst)))))
        (dbSave cv))
    (printf "Done.\n")))

(defun CopyRenameHierUI ()
  (let ((libs (sort (ddGetLibList)~>name nil))
        srcLib srcLibFld
        dstLib dstLibFld
        srcCell srcCelFldl
        srcView srcViewFld
        srchPattern srchPatternFld
        replacePattern replacePatternFld
        excludeLibs excludeLibsFld
        default_excludeLibs
        CopyRenameHierForm)

    ;;(importSkillVar TCC_PRIM_LIBS)
    (importSkillVar AUX_LIB)
    (setq default_excludeLibs "")
    ;; (foreach lib TCC_PRIM_LIBS
    ;;     (setq default_excludeLibs (strcat default_excludeLibs lib " ")))
    (setq default_excludeLibs (strcat default_excludeLibs AUX_LIB))
    (printf "default_excludeLibs=%s\n" default_excludeLibs)

    (setq srcCellFld (hiCreateStringField
                      ?name 'srcCell
                      ?prompt "Source Cell"))
    (setq srcLibFld (hiCreateCyclicField
                     ?name 'srcLib
                     ?value (car libs)
                     ?choices libs
                     ?prompt "Source Library"))
    (setq srcViewFld (hiCreateCyclicField
                      ?name 'srcView
                      ?value "layout"
                      ?choices (list "layout" "schematic")
                      ?prompt "Source View"))
    (setq dstLibFld (hiCreateCyclicField
                     ?name 'dstLib
                     ?value (car libs)
                     ?choices libs
                     ?prompt "Destination Library"))
    (setq srchPatternFld (hiCreateStringField
                          ?name 'srchPattern
                          ?prompt "Search Pattern"))
    (setq replacePatternFld (hiCreateStringField
                          ?name 'replacePattern
                          ?prompt "Replace Pattern"))
    (setq excludeLibsFld (hiCreateStringField
                          ?name 'excludeLibs
                          ?defValue default_excludeLibs
                          ?prompt "Exclude Libs (space-separated)"))                         
    (setq CopyRenameHierForm (hiCreateAppForm
                              ?name 'crhForm
                              ?fields (list srcCellFld srcLibFld
                                            srcViewFld dstLibFld
                                            srchPatternFld replacePatternFld
                                            excludeLibsFld)
                              ?formTitle "Copy/Rename/Rebind Hier"
                              ?callback 'CopyRenameHierUICB))
    (hiDisplayForm CopyRenameHierForm)))

(defun CopyRenameHierUICB (frm)
  (CopyRename frm->srcLib->value
              frm->srcCell->value
              frm->srcView->value
              frm->srchPattern->value
              frm->replacePattern->value
              frm->replacePattern->value
              frm->dstLib->value
              (parseString frm->excludeLibs->value)))
