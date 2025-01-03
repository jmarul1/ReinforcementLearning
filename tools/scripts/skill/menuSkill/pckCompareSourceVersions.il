;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;; VERSION:  
;;      $Id: pckCompareSourceVersions.il.rca 1.1 Fri Dec 10 15:47:46 2010 pvrott Experimental $
;;
;; NAME
;;      pckCompareSourceVersions.il
;;
;; DESCRIPTION
;;      This file conatins functions to compare SKILL source files between development, QA, production environments.
;;
;; GLOBAL VARIABLES
;;
;;      TCC_UTILS : path to the SKILL code source files
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; load "tcc_collateral/core/skill/pckCompareSourceVersions.il"
;;
;; For testing in TCCQA or Production environment:
;; load strcat("/prj/tccdev/work_areas/" getShellEnvVar("USER") "/tccdev/tcc_collateral/core/skill/pckCompareSourceVersions.il")


(defun pckSendSourceCompare ( path @optional isRecursive )
(let ( tmpfile)

  ;; mailTo = pckGetMailingList()
  tmpfile = pckDoCompare( path isRecursive)

  ;; MUST have "Auto Publish" in email subject!
  ;; printf( strcat( "mailx -s \"Auto Publish Source Version Comparison Report\" " mailTo " < " tmpfile)) 
  if( fileLength( tmpfile) > 0 then
      pckMailHandler( sprintf( nil "Source Version Comparison Report for %s" path ) tmpfile)
      ;; sh( strcat( "mailx -s \"Auto Publish Source Version Comparison Report\" " mailTo " < " tmpfile)) 
  )

) ;; let
)


(defun pckViewSourceCompare ( path @optional isRecursive )

(let ( tmpfile)

  tmpfile = pckDoCompare( path isRecursive)
  view( tmpfile)
)
)


(defun pckDoCompare ( path @optional isRecursive )

(let (dsscCmd user process workarea1 tmpfile fp)
  
  user = getShellEnvVar("USER")
  process = getShellEnvVar("PROCESS_NAME")
  tmpfile = strcat("/tmp/" user "_dsscCompareOut.txt")

  ;; Added to fix wierd bug where old file is being reported instead of correct one
  if( isFile( tmpfile) then csh( sprintf(nil "rm -f %s\n" tmpfile)))

  workarea1 = strcat( TCC_UTILS "/"  path) 

  if( isRecursive then
     sprintf( dsscCmd "dssc compare -rec %s > %s" workarea1 tmpfile)
  else
     sprintf( dsscCmd "dssc compare %s > %s" workarea1 tmpfile)
  )
  csh( dsscCmd)

  tmpfile
  
) ;; let
) ;; pckCompareSourceVersions

/*

(defun pckCSVmenu
(let ( CSVform 

     )



)
)

*/
