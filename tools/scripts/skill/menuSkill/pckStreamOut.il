;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Filename: pckStreamOut.il                   Project: TCC
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; (C) Copyright Intel Corporation, 2005
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Functional description:
;;     Functions to build a Stream file
;;
;;
;; Revision History:
;;     10/24/2005 Bill Harris       Original.
;;	   6/5/2011		Balaji Ramasubramanian
;;			Added functionality to look for the techfile corresponding to the
;;			specific library. So for example, if you're streaming out a cell
;;			from fdk71p9tapeout and that is bound to fdk71p9tech, then this
;;			uses the appropriate tech file and not the FDK_OATECH_DIR. But
;;			if the said library does not have the required mapfiles, it uses
;;			the FDK_OATECH_DIR.
;;	   6/6/2011		Balaji Ramasubramanian
;;			Added code to create runDir if not present
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; (load "pckStreamOut.il")
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun pckStreamOut (libName cellName cellView runDir stmFile @key (stm_options "") )	
(let (retval)

  (pckInfo "pckStreamOut" "Starting stream out process.")

  (unless (isDir runDir) (createDir runDir))

  (pckMakeStreamFileNew runDir libName cellName cellView stmFile ?stm_options stm_options)

  ; gds file specified as absolute path?
  (if (rexMatchp "^/" stmFile)
    (setq retval stmFile)
    (sprintf retval "%s/%s" runDir stmFile)
  )

  (if (isFile retval)
    (pckInfo "pckStreamOut" (sprintf nil "Generated stream file %L" retval))
    (pckError "pckStreamOut" (sprintf nil "Stream file %L not generated!" retval))
  )

  retval

))

(defun pckGetTechMapFile (pathList pattern)
(let (pth (i 0) (found nil) (filename nil))
	(while (and (not found) (lessp i (length pathList)))
		(setq pth (nth i pathList))
		(if (and (isDir pth) (nequal 0 (length (setof x (getDirFiles pth) (rexMatchp pattern x))))) (progn
			(setq found t)
			(setq filename (strcat pth "/" (car (setof x (getDirFiles pth) (rexMatchp pattern x)))))
			(pckInfo "pckGetTechMapFile" (strcat "Using map file " filename))
		) (progn
			(pckError "pckGetTechMapFile" (strcat "Cannot find mapfile " pattern " at " pth))
		))
		(setq i (add1 i))
	)
	filename
))


(defun pckGenTechPathList (lib)
(let (pathList)
	(if (nequal "cdsDefTechLib" (techGetTechFile (ddGetObj lib))~>libName) (progn
		(setq pathList (list (ddGetObj (techGetTechFile (ddGetObj lib))~>libName)~>readPath FDK_OATECH_DIR))
	) (progn
		(setq pathList (list FDK_OATECH_DIR))
	))
	pathList
))


(defun pckGetCDSLibFile ()
(let (cdsLib)
    (setq cdsLib (getShellEnvVar "CDSLIB"))
	(unless  cdsLib
	  (setq cdsLib (ddGetForcedLib))
	)
	(if (and (equal cdsLib "") (isFile (strcat (getShellEnvVar "FDK_WORK") "/cds.lib")))  (progn
		(setq cdsLib (strcat (getShellEnvVar "FDK_WORK") "/cds.lib"))		
	) (progn
		(pckError "pckMakeStreamFileNew" (sprintf nil "Could not find suitable cds.lib file."))
	))
	cdsLib
))


(defun pckGetTechLib (lib)
(let (thistechLib)
	(setq thistechLib (techGetTechFile (ddGetObj lib))~>libName)
	(when (equal nil thistechLib) (setq thistechLib TECH_LIB))
	thistechLib
))

(putd 'pckPrepareStrmOutRunDir nil)
(defun pckPrepareStrmOutRunDir (runDir cdsLib)
(let (fpath)

  (setq fpath (sprintf nil "%s/cds.lib" runDir))

  ; if there is already an existing cds.lib file,
  (if (isFileName fpath)
    (if (isFile fpath)
      (case (system (sprintf nil "exec cmp -s %L %L" cdsLib fpath))
        ; if cds.lib already has matching contents, then we don't need to do anything
	( 0
	  (pckInfo "pckPrepareStrmOutRunDir" (sprintf nil "cds.lib %L already matches desired contents" fpath))
	)
	; otherwise, warn user that they might be clobbering existing results
	( t (let (msg)
	  (sprintf msg "cds.lib %L doesn't match desired cds.lib %L" fpath cdsLib)
	  (pckError "pckPrepareStrmOutDir" msg)
	  (pckError "pckPrepareStrmOutDir" "Please make sure you aren't accidentally clobbering existing results.")
	  (pckError "pckPrepareStrmOutDir" (sprintf nil "If this is okay, then remove the existing cds.lib file %L and try again." fpath))
	  (error msg)
	))
      )
      ; if the object at fpath is a directory,
      (let (msg)
        (sprintf msg "cds.lib %L is a directory" fpath)
        (pckError "pckPrepareStrmOutRunDir" msg)
	(error msg)
      )
    )
    ; otherwise, there isn't anything already here.
    ; go ahead and create the symbolic link.
    (let (cmdline ev)
      (case (setq ev (system (sprintf cmdline "exec ln -s %L %L" cdsLib fpath)))
	( 0
	 (pckInfo "pckPrepareStrmOutDir" (sprintf nil "cds.lib %L symbolically linked to %L" fpath cdsLib))
	)
	( t (let (msg)
          (sprintf msg "Exit status %L executing command line: %s" ev cmdline)
	  (pckError "pckPrepareStrmoutDir" msg)
	  (error msg)
	))
      )
    )
  )

t))

(putd 'pckWriteStrmOutTemplateFile nil)
(defun pckWriteStrmOutTemplateFile (runDir libName logFname tmplFname projUtils mapFile cellName stmFile cellView objMap)
(let (fpath oport (maxVertices "3500"))

  (setq fpath (sprintf nil "%s/%s" runDir tmplFname))

  (if (outportp (setq oport (outfile fpath)))
    (progn
      (fprintf oport "library %L\n" libName)
      (fprintf oport "runDir %L\n" runDir)
      (fprintf oport "outputDir %L\n" runDir)
      (fprintf oport "logFile %L\n" logFname)
      ;;(fprintf oport "userSkillFile %L\n" (sprintf nil "%s/loader.il" projUtils))
      (fprintf oport "userSkillFile \"\"\n")
      (fprintf oport "ignorePcellEvalFail %L\n" nil)
      (fprintf oport "layerMap %L\n" mapFile)
      (fprintf oport "topCell %L\n" cellName)
      (fprintf oport "strmFile %L\n" stmFile)
      (fprintf oport "convertPin %L\n" "geometryAndText") ;-flattenPcells removed to support mimcap
      (fprintf oport "view %L\n" cellView)
      (fprintf oport "techLib %L\n" (pckGetTechLib libName))
      (fprintf oport "maxVertices %L\n" maxVertices)
      (fprintf oport "objectMap %L\n" objMap)
      (fprintf oport "flattenVias \n")
      (if (close oport)
        (pckInfo "pckWriteStrmOutTemplateFile" (sprintf nil "Finished writing template file %L" fpath))
        (pckError "pckWriteStrmOutTemplateFile" (sprintf nil "Could not complete write to template file %L" fpath))
      )
    )
    (pckError "pckWriteStrmOutTemplateFile" (sprintf nil "Couldn't open template file %L for writing" fpath))
  )

  fpath

))

(putd 'pckExecuteStrmOutCmd nil)
(defun pckExecuteStrmOutCmd (runDir tmplFpath stm_options)
(let (syscmd ipcid outputs exitstatus)

  (setq outputCollectorCB (lambda (childId data) (setq outputs (cons data outputs))))
  (setq syscmd (sprintf nil "cd %L && exec strmout %s -templateFile %L" runDir stm_options tmplFpath))

  (if (null (setq ipcid (ipcBeginProcess syscmd "" outputCollectorCB outputCollectorCB nil "")))
    (pckError "pckExecuteStrmOutCmd" (sprintf nil "Couldn't execute command-line %L" syscmd))
    (progn
      (pckInfo "pckExecuteStrmOutCmd" (sprintf nil "Executed command line: %s" syscmd))
      (ipcWait ipcid)
      (setq exitstatus (ipcGetExitStatus ipcid))
      (if (exitstatus == 0)
        (pckInfo "pckExecuteStrmOutCmd" "Strmout command completed successfully.")
	(progn
	  (pckError "pckExecuteStrmOutCmd" (sprintf nil "Strmout command completed with exit status %L" exitstatus))
	  (setq outputs (cons (sprintf nil "exit status %L" exitstatus) outputs))
	)
      )
    )
  )
  
  buildString(reverse(outputs) "\n")

))

(putd 'pckMakeStreamFileNew nil)
(defun pckMakeStreamFileNew (runDir libName cellName cellView stmFile @key dontRun (stm_options ""))
(let (mapFile objMap projUtils logFile cdsLib result )

  (pckInfo "pckMakeStreamFileNew" "Using new pckMakeStreamFileNew function for stream-out.")
  (pckInfo "pckMakeStreamFileNew" "Checking variables and directories.")

  (setq mapFile (pckGetTechMapFile (pckGenTechPathList libName) "tech\\.layermap"))
  (setq objMap (pckGetTechMapFile (pckGenTechPathList libName) "tech\\.objectmap"))
  (setq projUtils "$PCK_COLLATERAL_SKILL")
  (setq logFname (strcat libName "_" cellName "_streamout.log"))     
  (setq tmplFname (strcat libName "_" cellName "_streamout.tmpl"))     
  (setq cdsLib (pckGetCDSLibFile))

  (let (cvId msg)
  (if (null (setq cvId (dbOpenCellViewByType libName cellName cellView)))
    (progn
      (setq msg (sprintf nil "Cell view %s.%s.%s does not exist!" libName cellName cellView))
      (pckError "pckMakeStreamFileNew" msg)
      (error msg)
    )
    (progn
      (setq msg (sprintf nil "Verified existence of cell view %s.%s.%s" libName cellName cellView))
      (pckInfo "pckMakeStreamFileNew" msg)
      (dbClose cvId)
    )
  ))

  (pckPrepareStrmOutRunDir runDir cdsLib)

  (setq tmplfpath (pckWriteStrmOutTemplateFile runDir libName logFname tmplFname projUtils mapFile cellName stmFile cellView objMap))

  (if dontRun

    (progn
      (pckInfo "pckMakeStreamFileNew" "strmout template file has been created but not run!")
      (setq result (sprintf nil "strmout -templateFile %L %s" tmplfpath stm_options))
    )

    (setq result (pckExecuteStrmOutCmd runDir tmplfpath stm_options))

  )

  result

))
