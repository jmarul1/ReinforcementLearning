;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Intel Top Secret                                                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copyright (C) 2013, Intel Corporation.  All rights reserved.             ;;
;;                                                                          ;;
;; This is the property of Intel Corporation and may only be utilized       ;;
;; pursuant to a written Restricted Use Nondisclosure Agreement             ;;
;; with Intel Corporation.  It may not be used, reproduced, or              ;;
;; disclosed to others except in accordance with the terms and              ;;
;; conditions of such agreement.                                            ;;
;;                                                                          ;;
;; All products, processes, computer systems, dates, and figures            ;;
;; specified are preliminary based on current expectations, and are         ;;
;; subject to change without notice.                                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Code to prepare proper CELLNAME list to act on ;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
result=list(1)
;prog( (x) if(cell_list==" " then return())) 
CELLNAMES=" "
if(cell_list=="all" then
	CELLNAMES=ddGetObj(LIBRARY)~>cells~>name
else
inport=infile(cell_list)
when(inport
	while(gets(line inport)
		when(rexMatchp("\n$" line)
                        line = strncat("" line strlen(line)-1)
                );
                line=list(line)
		printf("cellname = %L \n",line)
                result = cons(line result)
                printf("list = %L \n",result)
        )
)	 
result_final = remove(1 result)
CELLNAMES=result_final
close(inport)
)
printf("list = %L \n",CELLNAMES)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Code to read importConfig and execute translations accordingly ;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
putd( 'wrapper nil )
;; START OF WRAPPER PROCEDURE ;;
procedure(
  wrapper(LIBRARY) 
  ;foreach(CELL ddGetObj(LIBRARY)~>cells~>name
  ;; LOOPING OVER ALL CELLS EITHIER IN CELL LIST FILE OR ALL CELLS IN DIRECTORY ;;
  foreach(CELL1 CELLNAMES
  	prog(()
  	if(cell_list!="all" then
  		CELL=buildString(CELL1))	;; IF CELL LIST IS ENTIRE LIBRARY CONVERT LIST CELL1 TO STRING ;;
  		printf("cell current %s \n",CELL)
  		SYNC_MIRROR_DIR=getShellEnvVar("SYNC_MIRROR_DIR")
  		PROCESS=getShellEnvVar("PROCESS_NAME")
  		if(PROCESS=="1273" then
    			DIR=strcat(SYNC_MIRROR_DIR "/fdk73/oalibs/common/custom/build_scripts/skill")
  		else
    			DIR="/nfs/site/disks/icf_fdk_designsync002/fdk73/sync_mirror/fdk73/oalibs/common/custom/build_scripts/skill"
  		)
  		view2 = ddGetObj(LIBRARY CELL)~>views~>name ;; VIEW2 WILL HAVE LIST OF ALL VIEWS IN CELL ;;
  		printf("cell current %s \n",CELL)
  		printf("test %L \n", member("importConfig" view2 ))
  	 	if(member("importConfig" view2 ) ;; IF VIEW2 HAS IMPORTCONFIG VIEW THEN READ IT AND EXECUTE ALL NECESSARY FUNCTIONS LISTED IN THE IMPORTCONFIG ;;
       			then;  import_text_view_list = _fdkCustomGenerateWithinLibHierarchy(LIBRARY CELL VIEW1 ?src_lib_nm src_lib_nm)
         		printf("view2 = %L\n",view2)
       		view2="importConfig" 
       		if(ddGetObj(LIBRARY CELL view2 "text.txt") then
         		file_path = ddGetObjReadPath(ddGetObj(LIBRARY CELL view2 "text.txt"))
         		printf("view2 = %s\n",view2)
         		printf("file path = %s\n",file_path)
         		CELLNAME=list(CELL)
         		;SYNC_MIRROR_DIR=getShellEnvVar("SYNC_MIRROR_DIR")
         		;DIR=strcat(SYNC_MIRROR_DIR "/fdk73/oalibs/common/custom/build_scripts/skill")
         		printf("cellname = %L \n",CELLNAME)
         		;; read importConfig and print ;;
         		importin=infile(file_path) 
         		;while(line = lineread(importin)
          		when(importin
				while( gets(line importin)	
         				;printf("out = %L \n",line)
         				if(line == "set_fill_kor\n" then
                        			CELLNAME=list(CELL)
         					out=errset(load("/nfs/site/disks/icf_gwa_001/pajgaonk/fdk73/managed/fdk73/oalibs/common/custom/build_scripts/skill/fdkUpdateFillLayerBlockages_cell.il") t)	
         					printf("out1 = %L\n",out)
					)
                        		if(line == "Mc0Shapes\n" then
                        			CELLNAME=list(CELL)
                        			out=errset(load("/nfs/site/disks/icf_gwa_001/pajgaonk/fdk73/managed/fdk73/oalibs/common/custom/build_scripts/skill/fdkRemoveLibMc0Shapes_cell.il") t)
                        			printf("out1 = %L\n",out)
   					)
  					if(line == "LvsIgnoreProps\n" then
                        			CELLNAME=CELL
                        			out=errset(load("/nfs/site/disks/icf_gwa_001/pajgaonk/fdk73/managed/fdk73/oalibs/common/custom/build_scripts/skill/fdkUpdateLvsIgnoreProps_cell.il") t)
                        			printf("out1 = %L\n",out)
                        		)
					if(line == "UhvPinLabels\n" then
                        			CELLNAME=CELL
                        			out=errset(load("/nfs/site/disks/icf_gwa_001/pajgaonk/fdk73/managed/fdk73/oalibs/common/custom/build_scripts/skill/fdkUpdateUhvPinLabels_cell.il") t)
                        			printf("out1 = %L\n",out)
                        		)
					if(line == "UpdateVssPins\n" then
                        			CELLNAME=CELL
                        			out=errset(load("/nfs/site/disks/icf_gwa_001/pajgaonk/fdk73/managed/fdk73/oalibs/common/custom/build_scripts/skill/fdkUpdateVssPins_cell.il") t)
                        			printf("out1 = %L\n",out)
                        		)
			))
         close(importin)
         ;out=errset(load(file_path) t)
         ;printf("out = %L\n",out)

       else printf("import should be text view .txt\n")  
       )
    else printf("import text view with translations desired doesn't exist for %s %s\n",LIBRARY,CELL) 
    )
    return()) ;breaking our of for loop if we find import text view and execute it
  )
 ; )
);wrapper procedure ends here
;calling wrapper procedure
wrapper(LIBRARY)
