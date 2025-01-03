;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Filename: pckQuickOA2LNF.il                   Project: TCC
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; (C) Copyright Intel Corporation, 2009
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Functional description:
;;     Quick way to create a LNF file from a layout
;;
;; Author: Dan Shi
;; Keywords: TCC Project
;; 
;;
;; (load "pckQuickOA2LNF.il")
;; (pckStartLayout "/nfs/pdx/disks/x11a.disk.38/work_x11a/tc2/pvrott/x11tc_x11a/dev11ac_rosinv_PIF.il")
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;
;;
;; This is the code that is run when a user clicks on the menu option
;;
;;

(defun pckQuickOA2LNFGUI (@optional cv)

  (let  (CellNameField defLib defCell defStreamPath defStreamName defLNFPath defLNFName defExtraSwitch
                       OA2LNFForm LibNameField StreamPathField StreamNameField LNFPathField LNFNameField ExtraSwitchField silentButton
             xorButton )

    (unless cv 
      (setq cv (geGetEditCellView))
      )
    
    (setq defLin (dbGetq cv "libName"))
    (setq defCell (dbGetq cv "cellName"))
    (setq defStreamName (strcat defCell ".stm"))
    (setq defLNFName (strcat defCell ".lnf"))
    
    (unless (isDir (strcat (getShellEnvVar "WORK_AREA_ROOT_DIR") "/genesys/lnf"))
      (csh (strcat "mkdir " (getShellEnvVar "WORK_AREA_ROOT_DIR") "/genesys/lnf"))      
      )
    
    (setq defStreamPath (strcat (getShellEnvVar "WORK_AREA_ROOT_DIR") "/pds/stream"))
    (setq defLNFPath (strcat (getShellEnvVar "WORK_AREA_ROOT_DIR") "/genesys/lnf"))
    (setq defExtraSwitch "-notextSubstrate -noautoboundarypins -portpartialvia -noportxboundary -netprefix \"floatiss\" ") 

    (setq CellNameField
          (hiCreateStringField
           ?name       'CellNameField
           ?prompt     "Cell Name:"
           ?value      defCell
           ?callback   "{ OA2LNFForm->StreamNameField->value = (strcat CellNameField->value \".stm\")
                                                    OA2LNFForm->LNFNameField->value = (strcat CellNameField->value \".lnf\") }"
           ))

    (setq LibNameField
          (hiCreateStringField
           ?name       'LibNameField
           ?prompt "Library Name:"
           ?value    defLib
           ))

    (setq StreamPathField
          (hiCreateStringField
           ?name       'StreamPathField
           ?prompt "Stream File Path:"
           ?value    defStreamPath
           ))
    (setq StreamNameField
          (hiCreateStringField
           ?name       'StreamNameField
           ?prompt     "Stream File Name:"
           ?defValue   defStreamName
           ?value      defStreamName
           ))
    (setq LNFPathField
          (hiCreateStringField
           ?name       'LNFPathField
           ?prompt "LNF File Path:"
           ?value    defLNFPath
           ))
    (setq LNFNameField
          (hiCreateStringField
           ?name       'LNFNameField
           ?prompt     "LNF File Name:"
           ?defValue   defLNFName
           ?value      defLNFName
           ))
                            
    (setq ExtraSwitchField
          (hiCreateStringField
           ?name           'ExtraSwitchField
           ?prompt     "PIE Extra Switch:"
           ?defValue   defExtraSwitch
           ?value      defExtraSwitch
           ))
        
    (setq silentButton
          (hiCreateBooleanButton
           ?name       'silentButton
           ?buttonText "Silent Mode ?"
           ?defValue   nil
           ?value  nil
           ))                                               
    (setq xorButton
          (hiCreateBooleanButton
           ?name       'xorButton
           ?buttonText "Run XOR check ?"
           ?defValue   t
           ?value  t
           ))
    (setq OA2LNFForm
          (hiCreateAppForm
           ?name       'OA2LNFForm
           ?fields (list 'CellNameField
                         'LibNameField
                         'StreamPathField
                         'StreamNameField
                         'LNFPathField
                         'LNFNameField
                         'ExtraSwitchField
                         'silentButton
                         'xorButton
                         )
           ?formTitle  "OA to LNF Converter"
           ?callback   "{ (makeOA2LNF OA2LNFForm) }"
           ))
        (hiDisplayForm 'OA2LNFForm )
        );end let  
);end pckQuickOA2LNFGUI procedure


;;**********************************************************************
;;
;; This is the code that is doing the convertion
;;
/**************************************************************************/

(defun makeOA2LNF (OA2LNFForm)
    (let (cellName libName streamPath streamName lnfPath lnfName extraSwitch silentMode xorMode runDir streamFileName stm1 ProcName summary xorFileName
     inp nl cell)

        cellName = OA2LNFForm->CellNameField->value
        libName = OA2LNFForm->LibNameField->value 
        streamPath = OA2LNFForm->StreamPathField->value
        streamName = OA2LNFForm->StreamNameField->value
        lnfPath = OA2LNFForm->LNFPathField->value
        lnfName = OA2LNFForm->LNFNameField->value
        extraSwitch = OA2LNFForm->ExtraSwitchField->value
        silentMode = OA2LNFForm->silentButton->value
        xorMode = OA2LNFForm->xorButton->value

        ProcName = "pckQuickOA2LNF"

        ;;stream out
        runDir = (strcat (getShellEnvVar "WORK_AREA_ROOT_DIR") "/pds/stream")
        (pckInfo ProcName (sprintf nil "\nStreaming out cell %s/%s\n" libName cellName ))
        streamFileName = (strcat streamPath "/" streamName)
        (if (null silentMode) then
            stm1 = (pckStreamOut libName cellName "layout" runDir streamFileName )
            
        else
            stm1 = (pckPostGenStreamout streamPath libName cellName)
        )
        (pckInfo ProcName (sprintf nil "Stream File:\n%s\nCompleted ...\n" stm1) )  
        
        
        ;;convert stm to lnf using PIE
        runDir = lnfPath
        (pckInfo ProcName (sprintf nil "\nGenerating LNF of cell %s/%s\n" libName cellName ))
      (pckStm2Lnf runDir cellName streamFileName lnfName extraSwitch silentMode xorMode)
        (pckInfo ProcName (sprintf nil "LNF file of \n%s\nCompleted ...\n" stm1) )                      

    ;;;;;;;;;;;; monitor XOR results ;;;;;;;;;;;;;;;;;
        
        (if xorMode 
        (progn
        (setq xorFileName (sprintf nil "xor.%s.srep" cellName))
        ;;(fprintf stdout "\n The File Name is  %s" xorFileName)
        ;;(fprintf stdout "\n The path of File is %s" (strcat (getShellEnvVar "WORK_AREA_ROOT_DIR") "/pds/stream" "/" xorFileName))
        
        (setq inp (infile (strcat (getShellEnvVar "WORK_AREA_ROOT_DIR") "/pds/stream" "/" xorFileName)))
            (when inp
            (while (gets nl inp)
                    ;(setq cell (parseString nl))
                    (when (rexMatchp "TOTAL DRC Results Generated" nl) 
                        ;;(fprintf stdout "\n The content is %s" nl)
                        (setq cell (parseString nl))
                        ;;(fprintf stdout "\n The parseString is %L" cell)
                        (if (nequal (nth 4 cell) "0") 
                            (progn
                            ;;(fprintf stdout "\n Xor is unsuccessful")
                            /*(pckInfo ProcName (sprintf nil "\n Xor is unsuccessful \n %s \nXor results are located at %s" 
                                nl (strcat (getShellEnvVar "WORK_AREA_ROOT_DIR") "/pds/stream" "/" xorFileName)))*/
                            (pckErr 999 (sprintf nil "\n Xor is unsuccessful \n %s \nXor results are located at %s" 
                                nl (strcat (getShellEnvVar "WORK_AREA_ROOT_DIR") "/pds/stream" "/" xorFileName)))
                            )
                            t
                        )
                    )
                )
                (close inp)
            )
        )
        t
        )


    ) ; let
) ; makeOA2LNF

;;
;;
;; Call PIE to create a lnf file
;; This routine takes stream file from $PDSSTM directory 
;; and creates LNF file in the $WARD/genesys/dir
;;
(defun pckStm2Lnf (runDir libName cellName streamName lnfName extraSwitch silentMode @optional (xorMode nil))
    (let (syscmd cmdFile shellcmd result xor apppath genesys_job ctrl_dpl) 

      (pckInfo "pckStm2Lnf" "started.")
      (pckInfo "pckStm2Lnf" (sprintf nil "Convertion log available at %s." runDir))
      (sprintf syscmd "#!/usr/intel/bin/tcsh -f\n")
        (if xorMode  
            xor = "-xor"
            xor = "")
        (if silentMode
            (progn 
              (sprintf syscmd "%s\n 
                cd %s\n
if (\"`$SETUP_REV/bin/getTv pie`\" =~ \"NoToolVer\") then \n
setenv PIE_DIR /nfs/pdx/disks/x10atc.disk.10/work_x10a/da02/yfu2/pie/7.5.1_2009ww38\n
else\n
setenv PIE_DIR $CAD_ROOT/pie/`getTv pie`\n
endif\n
setenv NIKE_TECH_DIR $PIE_DIR/data/techfiles\n
setenv SYNC_DIR /nfs/pdx/disks/x10atc.disk.1/mounts/cad/x86-64_linux26/synchronicity/V6R2009/syncinc\n
$PIE_DIR/runpie -top %s -gds %s -process %s -writelnf %s %s >&! /dev/null\n
mv -f %s.lnf %s  >&! /dev/null\n" 
                       syscmd runDir cellName streamName (getShellEnvVar "PROCESS_NAME") extraSwitch xor cellName lnfName
                       ))
            (progn 
              (sprintf syscmd "%s\n 
 cd %s\n
 if (\"`$SETUP_REV/bin/getTv pie`\" =~ NoToolVer) then \n
 setenv PIE_DIR /nfs/pdx/disks/x10atc.disk.10/work_x10a/da02/yfu2/pie/7.5.1_2009ww38\n
 else\n
 setenv PIE_DIR $CAD_ROOT/pie/`getTv pie`\n
 endif\n
 setenv NIKE_TECH_DIR $PIE_DIR/data/techfiles\n
 setenv SYNC_DIR /nfs/pdx/disks/x10atc.disk.1/mounts/cad/x86-64_linux26/synchronicity/V6R2009/syncinc\n 
 $PIE_DIR/bin/runpie -top %s -gds %s -process %s -writelnf %s %s\n
 mv -f %s.lnf %s  >&! /dev/null\n" 
                       syscmd runDir cellName streamName (getShellEnvVar "PROCESS_NAME") extraSwitch xor cellName lnfName
                       )))      

        (setq cmdFile (strcat runDir "/" cellName "_stm2lnf.sh"))
        (pckCreateCommandFile cmdFile syscmd)
        (csh (strcat "chmod 775 " cmdFile))
        ;;
        ;; Once LNF file is created, it can be installed in Genesys library
        ;; if libName variable is provided (it is set in pckBatchCollateralFlow
        ;; by template parameter "targetLnfLib"
        ;; X72 configuration - should it be here?
        ;; X72 production libraries fall into 3 categories:
        ;;
        ;; SPCKT development:
        ;; c8libdev_x72atc_lay - 1272
        ;; d8libdev_x72atc_lay - 1273
        ;;
        ;; QA for development:
        ;; c8libqanonprd_x72atc_lay
        ;; d8libqanonprd_x72atc_lay
        ;;
        ;; SPCKT Official release
        ;; c8lib and d8lib
        ;;
        ;; SPCKT development library weite-in MUST be controlled by 'control list'
        ;; to avoid creating erroneous cells.
        ;; We should also develop a success check
        ;;     - whether new cell was created nu Genesys script.
        ;;     - whether new version was installed
        ;;     - whether check-in/checkout operations failed
        ;;         - we will use version number/timestamps for this purpose.
        (setq ctrl_dpl (pckInitCollLibControlFile))
        (unless (equal libName "none")
          ;; if template has targetLnfLib parameter set and non-empty
          ;;          
          (when
              (and
               (pckFindCellInGenesysLib libName cellName)
               (pckCheckCollLibControlFile libName cellName ctrl_dpl))
            (pckInfo "pckStm2Lnf"
                     (sprintf nil "Found cell %s.%s installed. Adding checkout instructions to Genesys input file." libName cellName))
            (pckInstallLNFFile
             "Checkout"
             (strcat (getShellEnvVar "WORK_AREA_ROOT_DIR") "/genesys/")
             libName
             cellName)
            (unless (pckIsCheckedoutP libName cellName "lnf")
              ;; throw the error here
              (pckError "pckStm2Lnf" (sprintf nil "Could not checkout cell %s form library %s for LNF conversion." cellName libName))
              (pckErr 999 (sprintf nil "Could not checkout cell %s form library %s for LNF conversion." cellName libName))
              )
            
            ))
        

        (if silentMode
            (setq result
                  (system cmdFile))
            (setq result
                  (system (sprintf nil "xterm -geom 79x30 -sl 4000 -sb -ms blue -cr green  -e %s -d %s"
                                   cmdFile (getShellEnvVar "DISPLAY")))))
        ;;
        ;; need put "zscratchtest_x11atc_lay" into a variable
        (unless (equal libName "none")
      ;; make sure we are not violating control file
      (pckCheckCollLibControlFile libName cellName ctrl_dpl)
      (if (pckFindCellInGenesysLib libName cellName)
          (progn
            (pckInfo "pckStm2Lnf"
                     (sprintf nil
                              "Cell was found in %s library. Checking in the new version of the cell." libName))
            (pckInstallLNFFile
             "Checkin"
             (strcat (getShellEnvVar "WORK_AREA_ROOT_DIR") "/genesys/")
             libName
             cellName)
            (setq genesys_job "Checkin")
            )
          (progn
            (pckInfo "pckStm2Lnf"
                     (sprintf nil
                              "Cell was not found in %s library. Installing a new cell." libName))
            (pckInstallLNFFile
             "Install"
             (strcat (getShellEnvVar "WORK_AREA_ROOT_DIR") "/genesys/")
             libName
             cellName)
            (setq genesys_job "Install"))
          )
      ;;
      ;; lucky for us we can use vanilla SKILL to get for LNF cell status.
      ;;
      (unless (ddGetObj libName cellName "lnf")
        ;; throw the error
        (pckError "pckStm2Lnf" (sprintf nil
                                        "After LNF conversion cell %s does not exist in target library %s.\n
Check Genesys log file %s for debug information." cellName libName
                                        (strcat runDir "/log/" cellName "." (lowerCase genesys_job) ".log" )))
              (pckErr 999 (sprintf nil
                                   "After LNF conversion cell %s does not exist in target library %s.\n
Check Genesys log file %s for debug information." cellName libName
                                   (strcat runDir "/log/" cellName "." (lowerCase genesys_job) ".log" )))              
        )
      (when (pckIsCheckedoutP libName cellName "lnf")
        ;; throw the error
        (pckError "pckStm2Lnf"
                  (sprintf nil
                           "After LNF conversion and check-in operation cell %s is still checked-out in target library %s.\n
Check Genesys log file %s for debug information." cellName libName
                           (strcat runDir "/log/" cellName "." (lowerCase genesys_job) ".log" )))
        (pckErr 999 (sprintf nil
                             "After LNF conversion and check-in operation cell %s is still checked-out in target library %s.\n
Check Genesys log file %s for debug information." cellName libName
                             (strcat runDir "/log/" cellName "." (lowerCase genesys_job) ".log" )))
        )
      )
        )
        
    result
    ;; let
    ) ; pckStm2Lnf
(defun pckFindCellInGenesysLib (libName cellName)
  (let (path)
    (setq path
          (strcat
           (getShellEnvVar "DB_ROOT")
           "/"
           (getShellEnvVar "PROJECT")
           "/"
           (car (parseString libName "_")) "_"  (cadr (parseString libName "_"))           
           "/lay/work/"
           libName 
           "/"
           cellName
           "/lnf/lnf.dat"
           ))
    (isFile path)
    )
  )



;;
;; Create command file for Genesys to install LNF file 
;; 
;;
(defun pckInstallLNFFile (job runDir libName cellName @optional (debug "no"))
  (let ((cmd "") fn cfn logn debug_prn )
    (setq cfn (strcat runDir "/scriptFiles/" cellName "." (lowerCase job) ".csh"))
    (setq fn (strcat runDir "/scriptFiles/" cellName "." (lowerCase job) ".tcl"))
    (setq logn (strcat runDir "/log/" cellName "." (lowerCase job) ".log"))
    ;;
    ;; debug switch not used yet
    (if (equal debug "no")
        (setq debug_prn "")
        (setq debug_prn "::boo::IOUT 1 ")
        )
    ;;
    ;; see if the cell has already been installed. We need to check it out first.
    ;;
    ;; TCL script to install the hiearchy in Genesys. Install does not take -depth
    ;; argument, -depth causes the cell to be installed in the default library
    ;; instead of the target one
    ;;     Open -cellname $tcellname
    ;;     set tcell "{$tcellname,lnf}"
    ;;     set cells [udm_utils_get_hierarchy $tcell 1]
    ;;     set library "whatever"
    ;;     foreach cell $cells {
    ;;     set cellname [cell_get_name $cell]
    ;;     set viewname [cell_get_cell_view_type $cell]
    ;;     Install -cellname  $cellname -viewname $viewname -library $library
    ;;     }



    (pckInfo "pckInstallLNFFile" (sprintf nil "Creating Genesys input file %s" fn))
    ;;(sprintf cmd "set cvm [::boo::CellViewMgr_getCellViewMgr]\;;(sprintf cmd "%s$cvm getLibPath %s\n" cmd libName)
    ;;(sprintf cmd "::boo::CellViewMgr getLibPath %s\n" libName)
    (case job
      ;;
      ;; at some point we need to investigate -depth switch
      ("Checkin"
       (sprintf cmd "%sOpen -cellname \"%s\" -nowindow -viewname \"lnf\"\n"
                cmd cellName )
       (sprintf cmd "%s%s -cellname \"%s\" -library \"%s\" -viewname \"lnf\"\n"
                cmd job cellName libName))
      ("Install"
       (sprintf cmd "%s%s -cellname \"%s\" -library \"%s\" -viewname \"lnf\"\n"
                cmd job cellName libName)
       )
      ("Checkout"
       (sprintf cmd "%s%s -cellname \"%s\" -library \"%s\" -viewname \"lnf\" -nowindow\n"
                cmd job cellName libName)
       ))
    (sprintf cmd "%sExit" cmd)
    (pckInfo "pckStm2Lnf" (sprintf nil "\nGenesys command:\n%s" cmd))
    (pckCreateCommandFile fn cmd)
    (sprintf cmd "#!/bin/csh -f\n#\n# dmserver setting recovery\n
alias idmb  \"$DMSERVER_BIN_DIR/idmb_sync_wrapper -nullgt\"\n
alias itk   \"$DMSERVER_BIN_DIR/itk_sync_wrapper -i\"\n\n#\n# genesys alias recovery\n
set gend = '$WORK_AREA_ROOT_DIR'\n
set genx = '$GENESYS_DIR/bin/genesys'\n
alias genesys '(cd '\"$gend\"' && limit stacksize 131000 && $GENESYS_DIR/ConfigFiles/nike.wrapper -report $GENESYS_REPORT '\"$genx\"' -noeh \\!*)'\n
alias genesysDBG '(cd '\"$gend\"' && limit stacksize 131000 && $GENESYS_DIR/ConfigFiles/nike.wrapper -dbg '\"$genx\"' -noeh -verbose \\!*)'\n
alias LNFTest '(limit stacksize 131000 && $GENESYS_DIR/ConfigFiles/nike.wrapper -envof $GENESYS_DIR/bin/genesys $GENESYS_DIR/bin/LNFTest \\!*)'\n
genesys -nullgt -file %s >&%s\n" fn logn)
    (pckCreateCommandFile cfn cmd)
    (setq result (csh cfn))
    result
    )
  )
(defun pckInitCollLibControlFile ()
  (let ((dpl (list nil)) inport inline (fn (strcat TCC_UTILS "/" (getShellEnvVar "PROCESS_NAME") "/1271_spkt_cf.il")))
    (if (isFile fn )
        (progn
          (pckInfo "pckInitCollLibControlFile"
                   (sprintf nil "Checking collateral template control file %s" fn))
          (setq inport (infile fn))
          (when inport
            (while (gets inline inport)
              (setq inline (parseString inline))
              (when (car inline)
                ;;(printf "%L %s %s\n" inline (car inline) (cadr inline))
                (putprop dpl (car inline) (cadr inline))
                )
              )
            (close inport))
          dpl
          )        
        (progn
          (pckError "pckInitCollLibControlFile" (sprintf nil "Missing controls file %s. Cannot initialize lib/cell control list." fn))
          (pckErr 999 (sprintf nil "Missing controls file %s. Cannot initialize lib/cell control list." fn))
          ))
    )  
  )


(defun pckCheckCollLibControlFile (libName cellName dpl)
  ;; if target library is in production library list
  (if (member libName TCC_COLLATERAL_PRODUCTION_LIB)
      (progn
        ;; check if cellName is present in control file
        (if (equal libName (get dpl cellName))
            (progn
              (pckInfo "pckCheckCollLibControlFile" (sprintf nil "Cell %s in library  %s is present in control file." cellName libName))

              )
            (progn
              (pckError "pckCheckCollLibControlFile"
                        (sprintf nil "Cell %s targets production collateral library %s but is not on controls file. Aborting conversion process." cellName libName))
              (pckErr 999 (sprintf nil "Cell %s targets production collateral library %s but is not on controls file. Aborting conversion process." cellName libName))
          
              )
            )
        )
      (progn
        ;; not a member, so return t
        t
        )
      )
  )


(defun pckCreateCommandFile ( fileName text ) 
  (let ( TMPL )  
    (setq TMPL ( outfile fileName "w" ) )
    (fprintf TMPL "%s\n" text) 
    (drain TMPL )
    (close TMPL )
    (csh (strcat "chmod 775 " fileName))
    t
    )
)       
