(defun pckGetVID (cv @optional (vid_layer "l9text"))
(let ()
	 (pckGetVIDObj cv vid_layer)~>theLabel
))


	
(defun pckGetVIDObj (cv @optional (vid_layer "l9text"))
(let ()
	 (setof x cv~>shapes (and (equal x~>layerName vid_layer) (equal x~>objType "label")))
))



(defun pckGetICFVIDObj (cv @optional (vid_layer "l9text"))
 (let ()
  	(setof x cv~>shapes (and (equal x~>layerName vid_layer) (equal x~>objType "label") (rexMatchp "^vid_icf_\\(.*\\)_\\(.*\\)__\\(.*\\)" x~>theLabel)))
))

(defun pckFixBadVID (cv @optional (vid_layer "l9text"))
 (let (vid goodpatt)
  	(setq goodpatt (strcat "vid_icf_" cv~>cellName "_[0-9]+__[0-9]+"))
  	(foreach vid (pckGetVIDObj cv vid_layer)
	 	(if (and (rexMatchp "^vid_icf.*" vid~>theLabel) (not (rexMatchp goodpatt vid~>theLabel)))
		 (progn
		  	(pckError "hasCellBadVID" (strcat "The cell " cv~>cellName " has a bad ICF VID: " vid~>theLabel " ICF VID patterns must follow \"vid_icf_<cellname>_<majorVer>__<minorVer>"))
			(pckInfo "hasCellBadVID" "Deleting bad vid")
		 	(dbDeleteObject vid)
		))
	)
	t
))


(defun pckCreateNewLabel (t_lib @key (majorVer 1) (minorVer 0) (vid_layer "l9text") (logfile "viddump.log"))
(let (ce cv vid vidList vidFile)
	(setq vidFile (outfile (strcat (getShellEnvVar "FDK_WORK") "/" logfile)))
	(foreach ce (setof x (ddGetObj t_lib)~>cells (member "layout" x~>views~>name))
		(setq t_cell ce~>name)
		(pckCreateNewVIDForCell t_lib ce~>name vid_label)
	)
	(close vidFile)
))



(defun pckCreateNewVIDForLib (t_lib cellpatt @key (vid_layer "l9text") (majorVer 1) (minorVer 0) (incMajor nil) (incMinor t))
(let (cv newLabel vidList verL (setErr nil) loc loc2 ce mylib vid)
 	;; If incMajor is set, then reset incMinor
	(if incMajor (setq incMinor nil))
    ;; For each cell of the pattern cellpatt
    (setq mylib (ddGetObj t_lib))
    (foreach ce (setof x mylib~>cells (rexMatchp (strcat "^" cellpatt "$") x~>name)) 
	    (setq cv (dbOpenCellViewByType ce~>lib~>name ce~>name "layout" "maskLayout" "a"))
        ;; open in append
		(setq vidList (pckGetVID cv vid_layer))
		(if (equal 0 (pckVIDMatchesICF vidList)) (progn
			;; If there is no valid ICF VID or no VID at all
			(pckFixBadVID cv vid_layer)
			(setq newLabel (pckCreateNewVIDLabel cv majorVer minorVer))
			;; Calculate the position of the new label
			(setq loc  (quotient (plus (nth 0 (nth 0 cv~>bBox)) (nth 0 (nth 1 cv~>bBox))) 2.0))
			(setq loc2 (quotient (plus (nth 1 (nth 0 cv~>bBox)) (nth 1 (nth 1 cv~>bBox))) 2.0))
			;; This creates the new VID
			(dbCreateLabel cv  "l9text" (list loc loc2) newLabel "centerCenter" "R0" "stick" .01)
		) (progn
			(if (and (equal 1 (pckVIDMatchesICF vidList)) (or (equal 1 (length vidList)) (equal 2 (length vidList))))
			 (progn
				;; CellView has one ICF VID
				(pckFixBadVID cv)
				(setq vid (car (pckGetICFVIDObj cv))~>theLabel)
				(setq verL (pckUpdateICFVersion vid ?incMajor incMajor ?incMinor incMinor ?majorVer majorVer ?minorVer minorVer))
				(setq newLabel (pckCreateNewVIDLabel cv (nth 0 verL) (nth 1 verL)))
				(pckInfo "pckCreateNewVIDForCell" (strcat "Incrementing VID for " t_lib "/" ce~>name ": " newLabel ))
				(car (pckGetICFVIDObj cv))~>theLabel = newLabel
			) (progn
				;; If there are more than one valid ICF VIDs
				(setq setErr t)
				(pckError "pckCreateNewVIDForCell" (strcat "Too many VIDs in this cell " t_lib "/" ce~>name ": " (sprintf nil "%L" vidList) ))
			))
		))
		(dbSave cv)
		(dbClose cv)
	)
	(not setErr)
))

(defun pckUpdateICFVersion (vid @key (incMajor nil) (incMinor t) (majorVer 1) (minorVer 0))
 (let (oldMajorVer oldMinorVer newMajorVer newMinorVer)
  	(rexMatchp "^vid_icf_\\(.*\\)_\\(.*\\)__\\(.*\\)" vid)
	(setq oldMajorVer (rexSubstitute "\\2"))
	(setq oldMajorVer (atoi oldMajorVer))
	(setq oldMinorVer (rexSubstitute "\\3"))
	(setq oldMinorVer (atoi oldMinorVer))
	;; If the major version is to increment, increment that and set minor version to 0
	(if incMajor
	 (progn 
	  (setq newMajorVer (add1 oldMajorVer))
	  (setq newMinorVer 0) )
	 (progn 
	  (setq newMajorVer oldMajorVer) 
	))
	;; If minor version is to increment, increment it.
	(if incMinor (setq newMinorVer (add1 oldMinorVer)))
	(list newMajorVer newMinorVer)
 ))


(defun pckCreateNewVIDLabel (cv majorVer minorVer)
 (let (newLabel loc loc2)
		(sprintf newLabel "vid_icf_%s_%d__%d" cv~>cellName majorVer minorVer )
		;; create a new VID
		(pckInfo "pckCreateNewVIDLabel" (strcat "Creating a new VID for " cv~>libName "/" cv~>cellName ": " newLabel ))
		newLabel
 ))


(defun pckVIDMatchesICF (vidList)
(let ((matched 0))
	(foreach vid vidList
		(if (rexMatchp "^vid_icf_\\(.*\\)_\\(.*\\)__\\(.*\\)" vid) (setq matched (add1 matched)))
		;; The pattern is very strict
	)
	matched
))




/****************************************************************************
 INTEL CONFIDENTIAL. COPYRIGHT © 2012, INTEL CORPORATION ALL RIGHTS RESERVED			    
  UNAUTHORIZED REPRODUCTION/DISTRIBUTION OF PART OR ALL OF THIS CODE 
                          IS STRICTLY PROHIBITED 				    
*****************************************************************************

Author  	   : Riad KACED <riad.kaced@intel.com>
Date		   : Thu Feb  2 18:27:48 MST 2012
Version 	   : 0.1  
Application	   : Skill
SKILL Lint	   : 100/100.
Description	   : Scripts to print out div labels from layout views  	 
Return Value	   : t/nil.
Bugs/Limitatiions  : Please report any issue to the author.


Requirement:
a. When a cell does not have a VID, please change the text output format so we could sort and compare them easily.  Change from 
   NoVID: b8xesdpmosclamp_v nil
   to 
   b8xesdpmosclamp_v ErrorNoVID nil
b. At this point, a cell could have one 1271 vid, one ICF VID, or two vid (one ICF, one 1271).   
   Error if the cell have multiple ICF VIDs or multiple 1271 VIDs.
   Example of correct  ones: 
   	b8xesdd1d2ulc250vertuhvm5 ("vid_icf_b8xesdd1d2ulc250vertuhvm5_1__0")
   	b8xdesddp1basell ("vid__1271__b8xdesddp1basell__4_1")
   	b89toprs_nest_metalfill ("vid_icf_b89toprs_nest_metalfill_1__0" "vid__1271__b8xtoprs_nest_metalfill__1_2")
   Example of incorrect ones:
	b8xesdd1ulc250vertuhvm5 ErrorMultipleVID  ("vid_icf_b8xesdd1ulc250vertuhvm5_1__0" " vid_icf_b8xesdd1ulc250vertuhvm5_1__0")
	b8xesdclampcaphv ErrorMultipleVID ("vid__1271__b8xesdclampcaphv__1_0" "vid__1271__b8xesdclampcaphv__1_0")
	b89toprs_nest_metalfill ErrorMultipleVID ("vid_icf_b89toprs_nest_metalfill_1__0" "vid__1271__b8xtoprs_nest_metalfill__1_2" "vid__1271__b8xtoprs_nest_metalfill__1_3"))
c. Add comment when the cellname does not match.
   Example: 
	b82indfillm8 WarnCellName ("vid__1271__b8xindfillm8__1_1" "vid_icf_b82indfillm8_1__0")
	b82indfillm8 WarnCellName ("vid__1271__b82indfillm8__1_1" "vid_icf_b8xindfillm8_1__0")
d. If there is multiple VID, sort vid name alphabetically so we could compare.
	Example correct: b89toprs_nest_metalfill ("vid__1271__b8xtoprs_nest_metalfill__1_2"  "vid_icf_b89toprs_nest_metalfill_1__0")
	Example incorrect one: b89toprs_nest_metalfill ("vid_icf_b89toprs_nest_metalfill_1__0" "vid__1271__b8xtoprs_nest_metalfill__1_2")

e. Sort cellname alphabetically so we could compare text file it easily.



Synopsis

  The aim of this script is to print out the div labels form a library of layout views.
  The script operates on any maskLayout view, regardless of the viewName itself.
  
  The entry point of the script is: ICFdumpVidLabels. This procedure relies on 2 other procedures
  ICFgetLabels and ICFprintGenericFileHeader.
  
  Theis scripts features the following functionality:
  - Output an error if there is no vid label on layer viadLayer in the layout view
  - Output a clean line if there is one and only label on layer viadLayer in the layout view
  - if there are 2 labels then check on whether they feature both icf and non-icf labels 
    Error if there is redendancy 
  -  if there are more than 2 labels then it's an error.
  - the cellNames in the logFile are displayed in an alphanumeric format 
  - the labels are also sorted for beter comparison
   
    
  The script takes one mandatory arument and 4 options
  
  A. Arguments 
     1. The only argument of the script is the libName to be processed
        
  B. Options (The order is not important) 
     1. vidLayer ("l9text"): Layer of interest for vid labels
     2. logFile (libName_vidDump.log): logFile  
     3. debug (t): when true, the logFile gets displayed.
     4. commentChar ("#"): Comment character for the header
     5. checkVersion:  When it is set (true), then output format is changed:
     	   - does not have (" ")
	   - if no VID, it will be changed to cellname no_vid_cellname
	   - if there is multiple VIDs, then the tool will write only one VID.  If icf vid exists, use it, otherwise, it will use original vid
     
Usage examples:
 ICFdumpVidLabels("dfd") 
  
  

****************************************************************************/
/*---------------------------------------------------------------------------
 procedure: ICFdumpVidLabels
 Created/Updated by rkaced/chlr12742 on Thu Feb  2 18:27:48 MST 2012
 Purpose: Main entry function
 Updated
 rkalim 2012/02/06  Update report format, add one extra option for checkVersion format
 rkalim 2013/02/26  Add argument exemptCells because intel73custom have cells like mfc2_s2s layout that does not have vid

---------------------------------------------------------------------------*/
procedure( ICFdumpVidLabels(libName @key (vidLayer "l9text") (logFile nil)(debug t)(commentChar "#")(checkVersion "0") (exemptCells nil))

   ;; there are one important switch here
   ;; checkVersion = This function will generate retrieve one VID per cell.  If no VID, it will put NoVID.  If there
   ;;                are multiple VIDs, it will pick the last VID (which is likely icf vid - sorted)
   ;;                The output file is used by create_check_version.pl to create p1271_CheckVersion.rs runset file
   ;;                default = 0, not used
 
  let((libId cv (vidList nil) logFilePrt cells vidListOwner)
    libId=ddGetObj(libName)
    ; Open the library object
    when(libId
      unless(logFile
        sprintf(logFile "%s_vidDump.log" libName)
      )
      logFilePrt=outfile(logFile "w")
      unless(logFilePrt
        error("Cannot open log file %s for writing\n" get_filename(logFilePrt))
      )

     (printf "creating VID for library = %L using checkVersion = %L and logfile =  %L == \n" libName checkVersion logFile)
     ; Print the header into the logFile
      ;; ICFprintGenericFileHeader(logFilePrt commentChar)
      ; get a sorted list of the cells in the library
      if((equal exemptCells nil)
      then 
            cells=sort(libId~>cells lambda((a b) alphalessp(a~>name b~>name)))
	else
            ;; now we need to exclude exemptCell from generating VID
	    ;;;(pckInfo "ronald - exemptCells" (sprintf nil "exemptCells =  %L" exemptCells))
	     cell1=sort(libId~>cells lambda((a b) alphalessp(a~>name b~>name)))
	     cells=(setof x cell1 (not (member x~>name exemptCells)))
	) ;; endif equal exemptCell	    
       ;;(pckInfo "ronald" (sprintf nil "cells =  %L" cells~>name))
       

      ; Process each cell
      foreach(cell cells
        foreach(view cell~>views 
	  ; Process any maskLayout view, regardless of the viewName itself; 
          when(ddMapGetFileViewType(ddGetObj(view~>lib~>name view~>cell~>name view~>name "*"))=="maskLayout" 
	    cv=dbOpenCellViewByType(view~>lib~>name view~>cell~>name view~>name)
	    when(cv
	      ; get the Labels from the cellView
	      vidList=ICFgetLabels(?cv cv ?layer vidLayer)~>theLabel
	      dbClose(cv)
	    )
	    if(zerop(length(vidList))
	      then
	        ; output an error if there is no vid label on layer viadLayer
		if((equal checkVersion "0")
		then
			fprintf(logFilePrt "%s ErrorNoVID %L\n" cell~>name vidList)
		else
			fprintf(logFilePrt "%s no_vid_%s\n" cell~>name cell~>name )
		) ;; end if equal checkVersion		
	      else
	    	if(onep(length(vidList))
	    	  then
		    ; output a clean line if there is one and only label on layer viadLayer
			if((equal checkVersion "0")
			then
				fprintf(logFilePrt "%s %L\n" cell~>name vidList)
			else
				newVid = sprintf(nil "%s" car(vidList))
				fprintf(logFilePrt "%s %s\n" cell~>name newVid)
			) ;; end if equal checkVersion		
	    	  else
		  ;; we will print based on checkVersion		  
		  if((equal checkVersion "0")
		  then
		   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
		    if(length(vidList)==2
		      then
            	          fprintf(logFilePrt "%s BADMultipleVID %L\n" cell~>name sort(vidList 'alphalessp))	      
		        ; if there are 2 labels then check on whether they feature both icf and non-icf labels
			; Error if there is redendancy
		        vidListOwner=foreach(mapcar x vidList cadr(parseString(x "_")))
			if(car(vidListOwner)==cadr(vidListOwner)
            	          fprintf(logFilePrt "%s ErrorMultipleVID %L\n" cell~>name sort(vidList 'alphalessp))
            	          fprintf(logFilePrt "%s %L\n" cell~>name sort(vidList 'alphalessp))
			)
		      else
		        ; if there are more than 2 labels then it's an error.
            	        fprintf(logFilePrt "%s ErrorMultipleVID %L\n" cell~>name sort(vidList 'alphalessp))
		    ) ;; end of if length
		   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		   else
		   ;; if there is multiple VIDs, then the tool will write only one VID.  
		   ;; If icf vid exists, use it. otherwise, it will use original vid
		   ;; after sort, use the last in the list
		   sortedVid = sort(vidList 'alphalessp)
		   sizeVid = length(sortedVid)
		   nthVid = sizeVid - 1
  		   lastVid = nth( nthVid sortedVid )
	           ;;(printf "RYK sortedVid = %L and size = %L and nth = %L  and we will use = %L\n" sortedVid  sizeVid nthVid lastVid)
		   fprintf(logFilePrt "%s %s\n" cell~>name lastVid)

		   )  ;; end equal checkVersion
	    	) ;; end of onep
		
	    ) ;; end of if zerop
	    ; Check on whether labels are in line with cellNames.
	    unless(forall(vidLabel vidList rexMatchp(sprintf(nil "_%s_" cell~>name) vidLabel))
	    	;; do it only for checkVersion nil
		  if((equal checkVersion "0")
		  then
              		fprintf(logFilePrt "%s WarnCellName %L\n" cell~>name sort(vidList 'alphalessp))
		  ) ;; end if equal checkVersion
	    ) ;; end unless
	    
	    
	  ) ;; end of when ddMapGetFileViewType
	)  ;; end of foreach view
      )  ;; enf of foreach cell
      ddReleaseObj(libId)
      close(logFilePrt)
      when(debug
        view(get_filename(logFilePrt))
      )
    )
    t
  )
)



/*---------------------------------------------------------------------------
 procedure: ICFdumpVidLabelsExpected
 Created rkalim 2012/02/24 per ICFdumpVidLabels function (by rkaced)
 Purpose: To generate expected VID.
              This function will generate expected VID for modified cells (b82/6/9, b8y, b8libp2/6/9).
              For other cells: use AD's vid tag (1271).
              The output file is used by create_check_version.pl to create p1271_CheckVersion.rs runset file
 Updated

---------------------------------------------------------------------------*/
 
procedure( ICFdumpVidLabelsExpected(libName @key (vidLayer "l9text") (logFile nil)(debug t)(commentChar "#")(version "_2__0" ))
  let((libId cv (vidList nil) logFilePrt cells vidListOwner)
    libId=ddGetObj(libName)
    ; Open the library object
    when(libId
      unless(logFile
        sprintf(logFile "%s_vidDump.log" libName)
      )
      logFilePrt=outfile(logFile "w")
      unless(logFilePrt
        error("Cannot open log file %s for writing\n" get_filename(logFilePrt))
      )

     (printf "creating VID for library = %L using logfile =  %L == \n" libName logFile)
      ; get a sorted list of the cells in the library
      cells=sort(libId~>cells lambda((a b) alphalessp(a~>name b~>name)))
      cellsname=sort(libId~>cells~>name lambda((a b) alphalessp(a b)))

      ;; now figure out which cells are modified ICF cells
      ;; should be: b8y, bsy, b82, b86, b89, b8libp2, b8libp6,b8libp9
/*---------------------------------------------------------------------------      
	;;cells = (list "b8libp2_chn_ogdio_minix0" "b8libp6_eredmchn_ogdio_minix0" "b8libp9_chn_pgdio_minix0" "b8libp4BAD" "fdk71b8BAD" "fdk71b82BAD" "b8ymfcd0nvc6"
	"b8yesdd4uhv" "b8xvargbndsideBAD" "b8xmfca0hvb5BAD" "b89toprs_y_small_mfill" "b86toprs_y_small_mfill" "b86indfillv8" 	"b82toprs_iso_mfill" "b81esdpmosclampBAD" "b84esdpmosclampxllBAD" "bsxBAD" "bsygood" ) 
---------------------------------------------------------------------------*/
	cellICF1 =  rexMatchList("^b8[2,6,9,y]+" cellsname)	
	cellICF2 =  rexMatchList("^b8libp[0,2,4,6,9,y]+" cellsname)	
	cellICF3 =  rexMatchList("^bs[2,6,9,y]+" cellsname)	

	cellICF = append(append(cellICF1 cellICF2) cellICF3)
	cellAD  = setof( element cellsname !member( element cellICF ))
      
      ;; now we will process cellICF and cellAD
      foreach(cell cells
        foreach(view cell~>views 
	  ; Process any maskLayout view, regardless of the viewName itself; 
          when(ddMapGetFileViewType(ddGetObj(view~>lib~>name view~>cell~>name view~>name "*"))=="maskLayout" 
	    cv=dbOpenCellViewByType(view~>lib~>name view~>cell~>name view~>name)
	    when(cv
	      ; get the Labels from the cellView
	      vidList=ICFgetLabels(?cv cv ?layer vidLayer)~>theLabel
	      dbClose(cv)
	    )
	    ;; now determine cell status
	    
	    
	    if(member(cell~>name cellICF) 
	    then
	    ;;; FOR ICF CELL
	    newVid = sprintf(nil "vid_icf_%s%s" cell~>name version)
	    fprintf(logFilePrt "%s %s\n" cell~>name newVid)
	    else
	    ;;; FOR AD CELL	    
	    ;; now check what to print
	    if(zerop(length(vidList))
	      then
	        ; output an error if there is no vid label on layer viadLayer
		fprintf(logFilePrt "%s no_vid_%s\n" cell~>name cell~>name )
	      else
	    	if(onep(length(vidList))
	    	  then
		    ; output a clean line if there is one and only label on layer viadLayer
			newVid = sprintf(nil "%s" car(vidList))
			fprintf(logFilePrt "%s %s\n" cell~>name newVid)
	    	  else
		        vidListOwner=foreach(mapcar x vidList cadr(parseString(x "_")))
            	          fprintf(logFilePrt "%s ErrorMultipleVID %L\n" cell~>name sort(vidList 'alphalessp))
            	          fprintf(logFilePrt "%s %L\n" cell~>name sort(vidList 'alphalessp))
	    	) ;; end of onep
		
	    ) ;; end of if zerop
	    ) ;; end of member cellICF
	    
	  ) ;; end of when ddMapGetFileViewType
	)  ;; end of foreach view
      )  ;; enf of foreach cell
      ddReleaseObj(libId)
      close(logFilePrt)
      when(debug
        view(get_filename(logFilePrt))
      )
    )
    t
  )
)


/*---------------------------------------------------------------------------
 procedure: ICFgetLabels
 Created/Updated by rkaced/chlr12742 on Thu Feb  2 18:27:48 MST 2012
 Purpose: get labels from a layout view
---------------------------------------------------------------------------*/
procedure( ICFgetLabels(@key (cv geGetEditCellView()) (layer nil))
  let((labels)
    when(cv
      labels=setof(x cv~>shapes x~>objType=="label")
      when(and(layer stringp(layer))
        labels=setof(x labels x~>layerName==layer)
      )
    )
    labels
  )
)
/*---------------------------------------------------------------------------
 procedure: ICFprintGenericFileHeader
 Created/Updated by rkaced/chlr12742 on Thu Feb  2 18:27:48 MST 2012
 Purpose: print header 
---------------------------------------------------------------------------*/
procedure(ICFprintGenericFileHeader(outfilePort @optional (commentChar "#"))
  when( outfilePort
    fprintf(outfilePort sprintf(nil "%s############################################################\n" commentChar))
    fprintf(outfilePort sprintf(nil "%s        This file has been automatically generated         #\n" commentChar))
    fprintf(outfilePort sprintf(nil "%s############################################################\n" commentChar))
    fprintf(outfilePort sprintf(nil "%s\n" commentChar))
    fprintf(outfilePort sprintf(nil "%s Author : %s \n" commentChar getLogin()))
    fprintf(outfilePort sprintf(nil "%s Host   : %s \n" commentChar getShellEnvVar("HOST")))
    fprintf(outfilePort sprintf(nil "%s Date   : %s \n" commentChar getCurrentTime()))
    fprintf(outfilePort sprintf(nil "%s\n" commentChar))
    fprintf(outfilePort sprintf(nil "%s############################################################\n" commentChar))
    fprintf(outfilePort sprintf(nil "%s\n" commentChar))
  )
)
