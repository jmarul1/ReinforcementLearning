;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Filename: pckLayerDisplay.il             Project: TCC
;; 
;;  Version: $Id: pckLayerDisplay.il.rca 1.1 Fri Dec 10 15:47:46 2010 pvrott Experimental $
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; Copyright Intel Corporation 2005
;;
;; Author: Bill Harris
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Functional Description:
;;
;; This will rearrange the valid layer list in the LSW so that:
;;
;; 1. Only the layers used by the cell that is open in the current window will be listed
;; 2. ALL the layers available will be listed
;; 3. Layer list can be saved/recalled from a personal Favorite Layer file
;; 4. And more!
;;
;; NOTE: This now requires the global variable TECH_LIB to be set to the name of the 
;; technology file library, e.g., "p1265TechnologyLib"
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; For testing in TCCQA or Production environment:
;; load strcat( getShellEnvVar("WARD") "/tcc_collateral/core/tctools/pckLayerDisplay.il")
;;
;; load "tcc_collateral/core/tctools/pckLayerDisplay.il"

/***************************************************************************/

(defun pckLayerControlMenu ()

(let (layerLppButton layerRestoreButton saveFavLayerButton restoreFavLayerButton
      layerAllButton sep1 layerControlItems layerControlMenuForm formWidth loc
      hideFELayersButton hideBELayersButton
     )

    layerLppButton = hiCreateButton(
        ?name 'layerLppButton
        ?buttonText "Set LSW to This Drawing's Layers Only"
        ?callback "pckLayerLpp()"
    )

    hideFELayersButton = hiCreateButton(
        ?name 'hideFELayersButton
        ?buttonText "Hide FE Layers" 
        ?callback "pckHideFELayers()"
    )

    hideBELayersButton = hiCreateButton(
        ?name 'hideBELayersButton
        ?buttonText "Hide BE Layers" 
        ?callback "pckHideBELayers()"
    )

    layerRestoreButton = hiCreateButton(
        ?name 'layerRestoreButton
        ?buttonText "Set LSW to Original Layers" 
        ?callback "pckLayerRevert()"
    )

    saveFavLayerButton = hiCreateButton(
        ?name 'saveFavLayerButton
        ?buttonText "SAVE Current Layers as Favorite Layers" 
        ?callback "pckSaveFavoriteLayers()"
    )

    restoreFavLayerButton = hiCreateButton(
        ?name 'restoreFavLayerButton
        ?buttonText "Set LSW to your saved Favorite Layers" 
        ?callback "pckGetFavoriteLayers()"
    )

    layerAllButton = hiCreateButton(
        ?name 'layerAllButton
        ?buttonText "Set LSW to ALL Layers" 
        ?callback "pckGetAllLayers()"
    )

    sep1 = hiCreateSeparatorField(?name 'sep1 )

    formWidth = 250
    loc = list( car(car(hiGetScreenSize())) - (formWidth + 5) 23 )

    ;; format: list(r_field x_xpos:x_ypos x_width:x_height [x_promptWidth])

    layerControlItems = list(
        list(layerLppButton          3:10    formWidth:30  150)
        list(hideFELayersButton      3:40    formWidth:30  150)
        list(hideBELayersButton      3:70    formWidth:30  150)
        list(layerRestoreButton      3:100   formWidth:30  150)
        list(restoreFavLayerButton   3:130   formWidth:30  150)
        list(layerAllButton          3:160   formWidth:30  150)
        list(sep1                    3:195   formWidth:0 )
        list(saveFavLayerButton      3:200   formWidth:30  150)
    )

    layerControlMenuForm =
    hiCreateAppForm(
    ?name  'TCC_LAYER_CONTROL_MENU_FORM       ;; form name
    ?formTitle  "LSW Layers"           ;; form titile
    ?fields layerControlItems
    ?dontBlock t
    ?buttonLayout 'OKCancel
    )

    ; disable the o.k-done options.
    hiSetCallbackStatus(layerControlMenuForm nil)

    hiDisplayForm(layerControlMenuForm loc)


) ; let

) ; pckLayerControlMenu 

/***************************************************************************/

(defun pckLayerControlMenuDock ()

(let (layerLppButton layerRestoreButton saveFavLayerButton restoreFavLayerButton
      layerAllButton sep1 layerControlItems layerControlMenuForm formWidth
      windowId )

    layerLppButton = hiCreateButton(
        ?name 'layerLppButton
        ?buttonText "Set to Drawn Layers"
        ?callback "pckLayerLpp()"
    )

    layerRestoreButton = hiCreateButton(
        ?name 'layerRestoreButton
        ?buttonText "Restore defaults" 
        ?callback "pckLayerRevert()"
    )

    saveFavLayerButton = hiCreateButton(
        ?name 'saveFavLayerButton
        ?buttonText "SAVE as Favorites" 
        ?callback "pckSaveFavoriteLayers()"
    )

    restoreFavLayerButton = hiCreateButton(
        ?name 'restoreFavLayerButton
        ?buttonText "Set to Favorites" 
        ?callback "pckGetFavoriteLayers()"
    )

    layerAllButton = hiCreateButton(
        ?name 'layerAllButton
        ?buttonText "Set to ALL" 
        ?callback "pckGetAllLayers()"
    )

    sep1 = hiCreateSeparatorField(?name 'sep1 )

    formWidth = 125

    ;; format: list(r_field x_xpos:x_ypos x_width:x_height [x_promptWidth])

    layerControlItems = list(
        list(layerLppButton          3:10    formWidth:30  150)
        list(layerRestoreButton      3:40    formWidth:30  150)
        list(restoreFavLayerButton   3:70    formWidth:30  150)
        list(layerAllButton          3:100   formWidth:30  150)
        list(sep1                    3:140   formWidth:0 )
        list(saveFavLayerButton      3:150   formWidth:30  150)
    )

     (unless (boundp (quote TCC_LAYER_CONTROL_MENU_FORM_DOCK))
       (setq TCC_LAYER_CONTROL_MENU_FORM_DOCK nil))

     (unless TCC_LAYER_CONTROL_MENU_FORM_DOCK
       layerControlMenuForm =
       hiCreateAppForm( ?name  'TCC_LAYER_CONTROL_MENU_FORM_DOCK       ;; form name
                        ?formTitle  "LSW Layers"           ;; form titile
                        ?fields layerControlItems
                        ?dontBlock t
                        ?buttonLayout 'OKCancel
                        )

       ; disable the o.k-done options.
       hiSetCallbackStatus(layerControlMenuForm nil))

       ;; hiDisplayForm(layerControlMenuForm)
     (unless (getSGq TCC_LAYER_CONTROL_MENU_FORM_DOCK window)
              (setq windowId (hiCreateDockWindow ?appType ""
                                                 ?widgetType "form"
                                                 ?handle (quote layerControl)
                                                 ?form layerControlMenuForm
                                                 ?dockSizeHint (list 125 300)
                                                 ?floatSizeHint (list 125 150)
                                                 ?title "LSW Layers"))

              (setSGq TCC_LAYER_CONTROL_MENU_FORM_DOCK windowId window))

     (hiDockWindow ?window (getSGq TCC_LAYER_CONTROL_MENU_FORM_DOCK window)
                   ?session (getSGq (hiGetCurrentWindow) sessionWindow)
                   ?side (quote left)
                   ?unmapped nil
                   )
 


) ; let

) ; pckLayerControlMenuDock 


/***************************************************************************/

;; Called from "Hide BE Layers" button

(defun pckHideBELayers ()
(let (num)

  (foreach layer METAL_LAYERS_LIST
           (unless (equal layer "metal1")
             (leSetLayerVisible (list layer "drawing") nil)
             )
           (unless (equal layer "tm1")
             (sscanf layer "metal%d" num)
             (leSetLayerVisible (list (sprintf nil "via%d" num) "drawing") nil)
             )
           )

  (when (hiGetCurrentWindow) (hiRedraw (hiGetCurrentWindow)))

) ;; let
) ;; pckHideBELayers

/***************************************************************************/

;; Called from "Hide FE Layers" button

(defun pckHideFELayers ()
(let (feLayers)

  (setq feLayers (list "nwell" "ndiff" "pdiff" "poly" "diffcon" "polycon" "via0")) 

  (foreach layer feLayers
           (leSetLayerVisible (list layer "drawing") nil)
           )

  (when (hiGetCurrentWindow) (hiRedraw (hiGetCurrentWindow)))

) ;; let
) ;; pckHideFELayers

/***************************************************************************/

;; Called from "Set LSW to This Drawing's Layers Only" button

(defun pckLayerLpp ()

(let ( cvId techFileId dLayer )
  
    cvId = geGetWindowCellView()
    if( cvId != nil then
        techFileId = techGetTechFile( ddGetObj( cvId~>libName) )

        leSetAllLayerValid( nil ) ;; techFileId )
    
        dLayer = foreach( mapcar lppId cvId~>lpps
                                 list( lppId~>layerName lppId~>purpose )
        );foreach

        foreach( lppId dLayer
                       leSetLayerValid( lppId t ) ;; techFileId )
        );foreach
  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Jul 12 11:53:49 2010 wharris: It appears that the leGetValidLayer function
;; must require the techfileId, but NOT the leSetLayerValid.
;; This seems to fix the problem reported by Gagan, I hope it does
;; (It works OK for me).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


        
        if( member( car(leGetValidLayerList( techFileId)) dLayer ) == nil then
;;            leSetLayerValid( car(leGetValidLayerList( techFileId )) nil techFileId )
;;            leSetLayerValid( car(leGetValidLayerList( )) nil )
            leSetLayerValid( car(leGetValidLayerList( techFileId )) nil )
        );if
        (when (hiGetCurrentWindow) (hiRedraw (hiGetCurrentWindow)))
    else
        printf( "*** ERROR: You must have a layout drawing open to do this! ***\n")
    )
);let

);procedure


/***************************************************************************/

;; Called from "Restore LSW to Original Layers" button

(defun pckLayerRevert ()

(let  ()

    techRefreshTechFile(techGetTechFile(ddGetObj(TECH_LIB)))
    (when (hiGetCurrentWindow) (hiRedraw (hiGetCurrentWindow)))

) ; let

) ; procedure

/***************************************************************************/
;; NOTE: This is not needed anymore, left in for history:

(defun pckSaveAllLayers ()
(let  ( projRoot thisProject thisProcess allLayersFile)

    projRoot = getShellEnvVar("DA_PROJECTS")
    thisProject = getShellEnvVar("PROJECT")
    thisProcess = getShellEnvVar( "PROCESS_NAME")

    allLayersFile = strcat(projRoot "/" thisProject "/" thisProcess "_LSW_Layers")
    pckSaveFavoriteLayers(allLayersFile)

) ; let
)

/***************************************************************************/

;; Called from "Save Current layers as Favorite Layers" button

(defun pckSaveFavoriteLayers ( @optional favFileName)

(let ( outfp saveFavoriteLayers cvId techFileId thisUser thisProject thisProcess doWrite)
  
;;    cvId = geGetWindowCellView()
;;    techFileId = techGetTechFile( ddGetObj( cvId~>libName) )
    techFileId = techGetTechFile( ddGetObj( TECH_LIB) )
    thisUser = getShellEnvVar("USER")
    thisProject = getShellEnvVar("PROJECT")
    thisProcess = getShellEnvVar( "PROCESS_NAME")

    saveFavoriteLayers = leGetValidLayerList( techFileId )

    if( (favFileName == nil) then
        favFileName = strcat("~" thisUser "/." thisProject "_" thisProcess "_FavoriteLayers")
    )

    if( isFile( favFileName) then

        doWrite = hiDisplayAppDBox(
            ?name          'delQuery
            ?dboxBanner    "Overwrite Favorites?"
            ?dboxText      "Overwrite your previous Favorite Layers?"
            ?dialogStyle   `modal
            ?buttonLayout  `YesNo
        
        )
    else
        doWrite = t
    )

    if( doWrite then

        outfp = outfile(favFileName "w")

        if( (outfp == nil) then
            printf("ERROR: cannot save favorite layers in file %s\n" favFileName)
        else
            foreach( item saveFavoriteLayers
                fprintf(outfp "%s %s\n" nth(0 item) nth(1 item))
            )
            close(outfp)
            printf("DONE. Favorite Layers are saved in %s ...\n" favFileName)

        )
    )

) ;; let

)

/***************************************************************************/

;; Called from "Set LSW to ALL Layers" button

(defun pckGetAllLayers ()

(let ( cvId techFileId )
  
;;    cvId = geGetWindowCellView()
;;    techFileId = techGetTechFile( ddGetObj( TECH_LIB) )

;;    leSetAllLayerValid( nil techFileId )
;;    leSetAllLayerValid( t techFileId )
    leSetAllLayerValid( nil )
    leSetAllLayerValid( t )
    (when (hiGetCurrentWindow) (hiRedraw (hiGetCurrentWindow)))

) ;; let
)

/***************************************************************************/

;; Called from "Set LSW to your saved Favorite Layers" button

(defun pckGetFavoriteLayers ( @optional favFileName)

(let ( infp line newLayers tmpList itemList cvId techFileId thisUser thisProject thisProcess )
  
    tmpList = nil
;;    cvId = geGetWindowCellView()
    techFileId = techGetTechFile( ddGetObj( TECH_LIB) )
    thisUser = getShellEnvVar("USER")
    thisProject = getShellEnvVar("PROJECT")
    thisProcess = getShellEnvVar( "PROCESS_NAME")

    if( (favFileName == nil) then
        favFileName = strcat("~" thisUser "/." thisProject "_" thisProcess "_FavoriteLayers")
    )

    infp = infile(favFileName)

    if( (infp == nil) then
        printf("ERROR: cannot find favorite layers file %s\n" favFileName)
    else
        while( (gets( line infp) != nil)
            
            ;;  build list  here for each layer
            itemList = parseString( line " \t\n\15")

            if( (tmpList == nil) then
                tmpList = tconc(nil itemList)
            else
                tmpList = tconc(tmpList itemList)
            )

        )
        newLayers = car(tmpList)

        close(infp)
        
        leSetAllLayerValid( nil ) ;; techFileId )

;;      printf("Adding first LPP at %s\n" getCurrentTime() ) 

        foreach( layer newLayers
            leSetLayerValid( layer t ) ;; techFileId ) 
        )  

;;      printf("Added last LPP at %s\n" getCurrentTime() ) 
        
    )

) ; let

) ; procedure


