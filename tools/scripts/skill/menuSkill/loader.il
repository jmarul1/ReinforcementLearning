;;++++++++++++++++++++++++++++++++++++++++
;;
;; 1271 process-dependent skill
;;++++++++++++++++++++++++++++++++++++++++
;; Engine files
;;

;;
;;
;;
;;(load "pckUtilFunctions.il")
(load "pckFunctions.il")
(load "pckRODFunctions.il")
(load "pckDesignSync.ils")
(load "pckLayoutFunctions.il")
(load "pckRodFunctions.ils" )
(load "pckHilightRODs.il")
(load "pckFlattenFunctions.il" )
;;(load "pckCheckHier.ils")
(load "pckDensityCalc.ils" )
;;(load "pckCreateUserXstreamTelsmplate.il")
(load "pckVirtualStaticCell.ils")
(load "pckLogger.ils")
(load "pckRebindLibs.il")
;;
;;
;; if we are interactive mode - load TcTools. Otherwise skip to avoid crashing pipo.
(when (getd 'deGetAppInfo)
  (load "CopyRenameHierRegex.il")
  (load "pckLayerDisplay.il" )
  ;;(load "pckStreamOut.ils")
  (load "pckStreamOut.il")
  (load "pckQuickStream.il")
  (load "pckXorByCellCalibre.il")
  (load "pckXorStreamFiles.il")
  ;;(load "highlight/module_loader.il")
  (load "pckCdlNetlistToCompare.il")
  )

(load "pckX11Functions.il")
(load "pckInstTree.il")
(load "pckLayoutFakePoly.il")
(load "pckPDSFlow.ils")
(load "pckCheckMate.il")
(load "pckSpecialDensities.il")
(load "pckBatchCollateralFlow.il")
(load "pckStartVUE.il")
(load "pckQuickOA2LNF.il")
(load "pckImportCellGUI.il")
(load "pckRodUF.il")
(load "pckLayerFunctions.il") 
(load "pckPathMeshA.il")
(load "pckLayoutMenu.il")
(load "pckDumpVID.il")
(load "pckVIDutils.il")
(load "pckCheckHierProcess.il")
(load "pckDensityCalcGUI.il")
;;
;; Schematics
(load "pckCreateNetlist.il")
(load "pckSchMenu.il")
;;
;;
(load "pckBuildMFCTestCase.il")
(load "pckLibExportUtils.il")
(load "pckSortNetlist.il")
(load "pckCdfDiffProg.il")
;;
;;
(load "pckFindGndSymbol.il")
(load "pckReleaseConfiguration.il")
;; Core loader.il
(printf "Starting to load general skill functions in core/skill directory.\n" )
