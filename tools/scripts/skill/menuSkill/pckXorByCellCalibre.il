;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Filename: pckXorByCellCalibre.il                   Project: TCC
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; (C) Copyright Intel Corporation, 2005
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Functional description:
;;     XOR layout between 2 Cadence layout cells. This uses a script to call Calibre
;;     to do the XOR and start a dialog to allow the user to hilight the differences
;;
;; File dependencies:
;;	   xorScript = "/prj/advda/bin/calibre-xor32"
;;     setupScript = "/to1/to_tools/3.3/env/calibre_env_setup"
;;
;; Revision History:
;;     05/01/2004 Bill Harris       Original.
;;     10/19/2005 Bill Harris       Update to work in Cadence5.x/DesignSync environment
;;     10/27/2005 Bill Harris       Update to use Calibre to do XOR and show differences
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; load "tcc_collateral/core/tctools/pckXorByCellCalibre.il"
;;
;; For testing in TCCQA or Production environment:
;; load strcat("/prj/tccdev/work_areas/" getShellEnvVar("USER") "/tccdev/tcc_collateral/core/tctools/pckXorByCellCalibre.il")
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


/**************************************************************************/
	; This is the code that is run when a user clicks on the menu option
	; in the library browser.
/**************************************************************************/

procedure( pckXorCellGUI( @optional cv)

let( 

        ( Cell1NameField Cell2NameField defLib defLibName defCell defCellName
          xorByCellForm Lib1NameField FileNameField
          Lib2NameField Version1Field Version2Field VersionList
        )

		if( cv == nil then
            cv = geGetEditCellView()
        )

        if( cv == nil then
            defLib = ""
            defCell = ""
        else
		    defLib = cv~>libName
		    defCell = cv~>cellName
        )
		defLibName = defLib
		defCellName = defCell
		VersionList = XORverCallback( defLibName defCellName 
									  defLibName defCellName)

		Cell1NameField = hiCreateStringField(
			?name		'Cell1NameField
			?prompt		"Cell 1 Name:"
			?value      defCell
			?callback   "VersionList = XORverCallback( Lib1NameField->value Cell1NameField->value 
                                           Lib2NameField->value Cell2NameField->value)"
		)

		Cell2NameField = hiCreateStringField(
			?name		'Cell2NameField
			?prompt		"Cell 2 Name:"
			?value      defCell
			?callback   "VersionList = XORverCallback( Lib1NameField->value Cell1NameField->value 
                                           Lib2NameField->value Cell2NameField->value)"
		)

		Lib1NameField = hiCreateStringField(
			?name		'Lib1NameField
			?prompt		"Cell 1 Library Name:"
			?value      defLib
			?callback   "VersionList = XORverCallback( Lib1NameField->value Cell1NameField->value 
                                           Lib2NameField->value Cell2NameField->value)"
		)

		Lib2NameField = hiCreateStringField(
			?name		'Lib2NameField
			?prompt		"Cell 2 Library Name:"
			?value      defLib
			?callback   "VersionList = XORverCallback( Lib1NameField->value Cell1NameField->value 
                                           Lib2NameField->value Cell2NameField->value)"
		)

		Version1Field = hiCreateCyclicField(
			?name		'Version1Field
			?prompt		"Cell 1 Version:"
			?choices	car(VersionList)
			?value		car(car( VersionList ))
		)
		Version2Field = hiCreateCyclicField(
			?name		'Version2Field
			?prompt		"Cell 2 Version:"
			?choices	cadr(VersionList)
			?value		car(cadr( VersionList ))
		)

		FileNameField = hiCreateStringField(
			?name		'FileNameField
			?prompt		"Output File:"
			?value		strcat( "XOR_results_"
                                Cell1NameField->value ) 
			?defValue	strcat( "XOR_results_"
                                Cell1NameField->value ) 
			?editable	nil

		)

		xorByCellForm = hiCreateAppForm(
			?name		'xorByCellForm
			?fields		list('Cell1NameField
							 'Lib1NameField
                             'Version1Field 
							 'Cell2NameField
							 'Lib2NameField
                             'Version2Field 
                             'FileNameField
                            )
			?formTitle	"XOR By Library/Cell/Version"
			?callback	"{ XORcellCallback( xorByCellForm) }"

		)
		hiDisplayForm( 'xorByCellForm )
);end let

);end pckXorCellGUI procedure

/**************************************************************************/
; This is the main callback procedure:

procedure( XORcellCallback( formHandle)

let( ( cv1 cv2 errMsg errForm msg1 msg2)

    errMsg = "" 
    msg1 = "" 
    msg2 = ""

    if( formHandle->Lib1NameField->value != "" && formHandle->Cell1NameField->value != "" then
	    cv1 = dbOpenCellViewByType( formHandle->Lib1NameField->value formHandle->Cell1NameField->value "layout" )
        if(cv1 == nil then
            msg1 = strcat( "Library/Cellview #1 cannot be opened: " formHandle->Lib1NameField->value "/" formHandle->Cell1NameField->value )
        )
    )

    if( formHandle->Lib2NameField->value != "" && formHandle->Cell2NameField->value != "" then
	    cv2 = dbOpenCellViewByType( formHandle->Lib2NameField->value formHandle->Cell2NameField->value "layout" )
        if(cv2 == nil then
            msg2 = strcat( "Library/Cellview #2 cannot be opened: " formHandle->Lib2NameField->value "/" formHandle->Cell2NameField->value )
        )
    )

	if( cv1 != nil && cv2 != nil then

        xorByCell( 
                 formHandle->Cell1NameField->value 
                 formHandle->Cell2NameField->value 
                 formHandle->Lib1NameField->value 
                 formHandle->Lib2NameField->value 
                 formHandle->Version1Field->value 
                 formHandle->Version2Field->value  
                 formHandle->FileNameField->value
        )

    else

        sprintf( errMsg "\n%s\n%s" msg1 msg2)
 
        pckWarn("XOR by Cell or Version" errMsg)

        errForm = hiDisplayAppDBox(
                        ?name `errFormName
                        ?dboxBanner "XOR by Cell or Version: Unable to Open Cellview"
                        ?dboxText  errMsg
                        ?dialogType  hicErrorDialog ;; showing up as global in Lint!
                        ?dialogStyle  `modal ;; `modeless
                        ?buttonLayout `Close ;; 'OKCancel
        )

    )  

); let
); procedure XORcellCallback


/*************************************************************************/
procedure( XORverCallback( Lib1Name Cell1Name Lib2Name Cell2Name)

let( (VersionList1 VersionList2 tmpList isRevCtrl cv 
      cv2 errMsg errForm )

	VersionList1 = list("LATEST")
	VersionList2 = list("LATEST")
    cv = nil

	;; OK, this is really STUPID!  The function dssGetViewVersionsP will
	;;                                                           ^
    ;; CRASH if the cellview has never been checked in! It SHOULD just return nil but NNNOOOOO...
	;; Therefore I have to first run dssGetViewVersionP in case the cell has never been checked in
	;;                                                ^ (no 's'!)

    if( Lib1Name != "" && Cell1Name != "" then
	    cv = dbOpenCellViewByType( Lib1Name Cell1Name "layout" )
    )
	if( cv != nil then
		isRevCtrl = dssGetViewVersionP( Lib1Name Cell1Name "layout")

		if( isRevCtrl != "Unknown" && isRevCtrl != "Unmanaged" then
			tmpList = dssGetViewVersionsP( Lib1Name Cell1Name "layout")

			foreach( i tmpList
				VersionList1 = append1( VersionList1 i )
			);end foreach
        )
    )

    cv2 = cv ;; will be used to check for hierarchy below...
    cv = nil
    if( Lib2Name != "" && Cell2Name != "" then
	    cv = dbOpenCellViewByType( Lib2Name Cell2Name "layout" )
    )

	if( cv != nil then
	    isRevCtrl = dssGetViewVersionP( Lib2Name Cell2Name "layout")

	    if( isRevCtrl != "Unknown" && isRevCtrl != "Unmanaged" then
	        tmpList = dssGetViewVersionsP( Lib2Name Cell2Name "layout")

	        foreach( i tmpList
		        VersionList2 = append1( VersionList2 i )
	        );end foreach
        )
	)
	if( VersionList1 == nil then VersionList1 = list( "LATEST"))
	if( VersionList2 == nil then VersionList2 = list( "LATEST"))

    if( cv~>instances != nil || cv2~>instances != nil then

        errMsg = "Hierarchy Detected: This tool may produce incorrect or misleading results!!\nThis is because changes that may exist in the subcell(s) may not be shown\nespecially if the subcell(s) are different versions in the top cells you are XOR'ing."
        pckWarn("XOR by Cell or Version" errMsg)

        errForm = hiDisplayAppDBox(
                        ?name `errFormName
                        ?dboxBanner "XOR by Cell or Version: Hierarchy Detected"
                        ?dboxText  errMsg
                        ?dialogType  hicErrorDialog ;; showing up as global in Lint!
                        ?dialogStyle  `modal ;; `modeless
                        ?buttonLayout `Close ;; 'OKCancel
        )

    )

    if( cv dbClose(cv))
    if( cv2 dbClose(cv2))

	list(VersionList1 VersionList2)
)
)

;; END OF GRAPHIC MODE LOADED CODE
/*************************************************************************/


/**************************************************************************/
 ;; This is the procedure that actually runs the XOR
/**************************************************************************/

procedure( xorByCell( Cell1Name
                      Cell2Name 
					  Lib1Name 
					  Lib2Name 
					  Ver1 
					  Ver2  
					  File )

let( 
	( ProcName  
	  viewName runDir streamFileName stm1 stm2
	  tmpView1 tmpView2
    )

    tmpView1 = 0
    tmpView2 = 0

	ProcName = "xorByCell"

    runDir = strcat( getShellEnvVar("WORK_AREA_ROOT_DIR") "/pds/stream")
 
	pckInfo( ProcName sprintf( nil "\nXORing cell %L/%L %s to cell %L/%L %s\n" 
                      Lib1Name Cell1Name Ver1 Lib2Name Cell2Name Ver2))

	;; NOTE: I tested and, yes, this will work if ver* is set to "LATEST", it will get the latest version.


	if( Ver1 == "LATEST" then
		viewName = "layout"
	else
        viewName = strcat( "layout_v" Ver1)
		dssFetchCellViewVersionP( Lib1Name Cell1Name "layout" Ver1)
		tmpView1 = 1
	)
		
	streamFileName = strcat( getShellEnvVar("WORK_AREA_ROOT_DIR") 
                             "/pds/stream/" Lib1Name "_" Cell1Name "_" viewName ".stm")
	stm1 = pckStreamOut( Lib1Name Cell1Name viewName runDir streamFileName ) 

    pckInfo( ProcName "First Stream File Completed ...\n")

	if( Ver2 == "LATEST" then
		viewName = "layout"
	else
        viewName = strcat( "layout_v" Ver2)
		dssFetchCellViewVersionP( Lib2Name Cell2Name "layout" Ver2)
		tmpView2 = 1
    )
		
	streamFileName = strcat( getShellEnvVar("WORK_AREA_ROOT_DIR") 
                             "/pds/stream/"  Lib2Name "_" Cell2Name "_" viewName ".stm")
	stm2 = pckStreamOut( Lib2Name Cell2Name viewName runDir streamFileName ) 

    pckInfo( ProcName "Second Stream File Completed ...\n")

	if( tmpView1 == 1 then dssDeleteTemporaryViewsP( Lib1Name))
	if( Lib2Name != Lib1Name then 
		if( tmpView2 == 1 then dssDeleteTemporaryViewsP( Lib2Name))
    )
	if( isFile( stm1) && isFile( stm2) then

        doXOR( stm1 stm2 File Cell1Name Cell2Name runDir)

	else

	    pckWarn( ProcName "One or more Stream files not generated!")
    )

    t

) ;let
) ;procedure 



/*************************************************************************/

procedure( DeleteThisFile( fileName)
let( (syscmd)

    ; Delete existing file
    syscmd = strcat("rm -f " fileName)
    sh(syscmd)
)
)


/**************************************************************************/
 ;; Do the XOR using magic XOR script and Calibre
/**************************************************************************/

procedure( doXOR( file1 file2 reportFilePrefix top1 top2 runDir )

let( (syscmd xorScript setupScript pOut tmpScript pid tmpScript2 layerFile thisHosttype )

    if( isReadable( file1) && isReadable( file2) then

    pckInfo( "doXOR" "Starting XOR on stream files ...\n")

;; New location for this 8-21-2006 per Pasha:

;; This works for HP environments but NOT for LINUX!  Awaiting a LINUX solution...

	thisHosttype = getShellEnvVar("HOSTTYPE")
	thisHosttype = lowerCase( thisHosttype) ;; Yes, I have seen $HOSTTYPE have both upper and lower case "linux"

    if( nindex( thisHosttype "linux") then

 	    xorScript = "/p/advda/utils/bin/calibre-xor32"

	else

 	    xorScript = "/p/advda/utils/mbaccar/bin/calibre-xor"

    )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 08-21-2006:
;; WAITING FOR NEW REPLACEMENT FOR THE FOLLOWING SCRIPT:

;; OLD: setupScript = "/to1/to_tools/3.3/env/calibre_env_setup"

;; New one according to Ning He:

	setupScript = "/p/advda/utils/bin/calibre_env_setup_2005.2_14.19"

	
	layerFile = strcat( runDir "/streamLayers.txt")		
	(if (pckGTProcess "1266")
		(progn
		  (system (strcat "cp -rf /p/advda/utils/bin/calibre-xor.layers" getShellEnvVar( "PROCESS_NAME") " " layerFile))
		  )
	  (progn
		makeLayerFile( layerFile)
		)
	  )
	(fprintf stdout "Layer file: %L\n" layerFile)
    tmpScript = strcat( runDir "/xorScript")
    tmpScript2 = strcat( runDir "/xorScript2")

    DeleteThisFile( tmpScript)
    DeleteThisFile( tmpScript2)

	when( stringp(tmpScript)
		unless( pOut = outfile(tmpScript "a") 
			printf( "Can't write to file %s\n" tmpScript)
		)
	)
    fprintf( pOut "#!/bin/csh -f\n")
    fprintf( pOut "cd %s\n" runDir)

    syscmd = strcat( xorScript " -s1 " file1 " -top1 " top1 " -s2 " file2 " -top2 " top2 " -out " reportFilePrefix " -f " layerFile)
    fprintf( pOut "%s\n" syscmd)

	when(pOut close(pOut))

    sh( strcat( "chmod 777 " tmpScript))
    sh( strcat( tmpScript " > " runDir "/" reportFilePrefix ".txt\n" )) 

	addLPPtoRepFile( runDir reportFilePrefix layerFile)

	when( stringp(tmpScript2)
		unless( pOut = outfile(tmpScript2 "a") 
			printf( "Can't write to file %s\n" tmpScript2)
		)
	)
    fprintf( pOut "#!/bin/csh -f\n")
	fprintf( pOut "source %s\n" setupScript)
	fprintf( pOut "calibre -rve %s/%s.rep\n" runDir reportFilePrefix )

	when(pOut close(pOut))

    pckInfo( "doXOR" "XOR Completed. Starting Calibre RVE to display results ...\n")

    syscmd = strcat( "chmod 777 " tmpScript2)
    sh(syscmd)

	if( mgc_rve_globals~>socket_number == -1 then
	    mgc_rve_start_socket_process()
	    mgc_rve_init_socket()
    )
	pid = ipcBeginProcess(tmpScript2)

    else

        pckError("XOR 2 Stream Files" "One or both of the input stream files are not available. Please check file or cell names.")

    ) ;; both stream files are readable

	pid

); let
); procedure

/**************************************************************************/
;; Build a Stream Layer list file for calibre-xor from ISSRUNSETS map file
/**************************************************************************/

procedure( makeLayerFile( layerFile)

let( (layerTable line fp1 fp2 itemList)

	 (if (or (equal (getShellEnvVar "PROCESS_NAME") "1272") (equal (getShellEnvVar "PROCESS_NAME") "1271") (equal (getShellEnvVar "PROCESS_NAME") "1270"))
		 layerTable = strcat( getShellEnvVar("ISSRUNSETS") "/PXL/p" getShellEnvVar("PROCESS_NAME") ".map")
		 layerTable = strcat( getShellEnvVar("ISSRUNSETS") "/Standard/p" getShellEnvVar("PROCESS_NAME") ".map"))

     if( isReadable( layerTable) then

	     if( isFile(layerTable) then

		     fp1 = infile( layerTable)

             DeleteThisFile( layerFile)

		     if( fp2 = outfile(layerFile "a") then

                 while( (gets( line fp1) != nil)

                     if( nindex( line "/*") == nil && nindex( line "#") == nil then
                         ;;  build list  here for each layer
                         itemList = parseString( line " \t\n\15")
                         if( length( itemList) > 3 then ;; eliminate empty lines
			                 fprintf( fp2 "%s:%s %s %s\n" nth(2 itemList) nth(3 itemList) nth(0 itemList) nth(1 itemList))
                         )
                     )
                 )

		     else
	     
			     pckWarn( "makeLayerTable" sprintf( nil "Can't write to Stream Layer List file %s\n" layerFile))

             ) ;; file opened for write

         ) ;; isFile

	 else

	     pckWarn( "makeLayerTable" sprintf( nil "Can't read Layer Map File %s\n" layerTable))
     )

	 when(fp1 close(fp1))
	 when(fp2 close(fp2))

) ;; let
) ;; procedure

/**************************************************************************/
 ;; Post-process the .rep file to add Cadence LPP to layer check names
/**************************************************************************/

procedure( addLPPtoRepFile( runDir reportFilePrefix layerFile)

let( (repFile tmpFile line line2 fp1 fp2 fp3 itemList)

	 repFile = strcat( runDir "/" reportFilePrefix ".rep")
     tmpFile = strcat( runDir "/" reportFilePrefix ".tmp")

     if( isReadable( repFile) then

	     if( isFile( repFile) then

		     fp1 = infile( repFile)
		     fp2 = infile( layerFile)

			 DeleteThisFile( tmpFile)

		     if( fp3 = outfile(tmpFile "a") then

                 while( (gets( line fp1) != nil)

					 itemList = parseString( line "\n")
					 line = car(itemList) ;; strip off EOL
                     if( nindex( line "xor")==1 && nindex( line ":") then
                         ;;  build list  here for each layer
						 gets( line2 fp2)
                         itemList = parseString( line2 " \t\n\15")
			             fprintf( fp3 "%s %s %s\n" line nth(1 itemList) nth(2 itemList))
                     else
					     fprintf( fp3 "%s\n" line)
					 )


                 )

		     else
	     
			     pckWarn( "addLPPtoRepFile" sprintf( nil "Can't write to temp file %s\n" tmpFile))

             ) ;; file opened for write

         ) ;; isFile

	 else

	     pckWarn( "addLPPtoRepFile" sprintf( nil "Can't read Report File %s\n" repFile))
     )

	 when(fp1 close(fp1))
	 when(fp2 close(fp2))
	 when(fp3 
		  close(fp3)
		  sh( strcat( "mv " tmpFile " " repFile))
	 )

) ;; let
) ;; procedure


;; End of file pckXorByCellCalibre.il
