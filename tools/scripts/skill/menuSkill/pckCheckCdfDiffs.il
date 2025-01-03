;;****h* TCC/pckCheckCdfDiffs
;; NAME
;; pckCheckCdfDiffs.il - Run lint and tag files ready to publish to TCCQA (or wherever) 
;; COPYRIGHT
;; Copyright Intel Corporation 2007
;; AUTHOR
;; Bill Harris
;; DESCRIPTION
;; TCC Project, TCC 2.2, Autopublish
;; USAGE
;; load "tcc_collateral/core/skill/pckCheckCdfDiffs.il"
;;****
;;
;; *************************************************************************
;; Check previous and new CDF parameters for differences
;; *************************************************************************

;; pckGetCDFparameters( "tcc_collateral/1268/pCells/CMB/CMB3MEV0")

(defun pckGetCDFparameters (filePath)

           let((templateName s allCdfParamList cdfParamList fileList )

               fileList = pckGetSkillFiles( filePath)
               allCdfParamList = nil

               foreach( f fileList
                          if( (s = nindex( f "_cdf")) || (s = nindex( f "_CDF")) then 
                              templateName = substring( f 1 s-1 )
                              templateName = lowerCase( templateName)
                              ;;
                              ;; pckGetCDFparametersByName call fails when template is 
                              ;; not in production's library pointed by CMB_LIB
                              ;; It also ha incomplete treatment for subprime TCC_PROJECT
                              cdfParamList = pckGetCDFparametersByName( templateName)
                              allCdfParamList = tconc( allCdfParamList cdfParamList)
                              )
                          )

               car( allCdfParamList)

               )                        ; let
           )                            ; pckGetCDFparameters

(defun pckGetCDFParametersByRelPath (dirname)
  (let (pp fileList cdfParamList cellName libName (allCdfParamList nil))
    (setq fileList (pckGetSkillFiles dirname))
    (foreach f fileList
             ;;(println f)
             (when (setq s (nindex (lowerCase f) "_cdf"))                 
                 (setq cellName (substring f 1 (sub1 s)))
                 ;;
                 ;; pckGetCDFparametersByName call fails when template is 
                 ;; not in production's library pointed by CMB_LIB
                 ;; It also ha incomplete treatment for subprime TCC_PROJECT
                 ;;cdfParamList = pckGetCDFparametersByName( templateName)
                 (when (setq libName (pckGetLibrary (strcat dirname "/" cellName ".il")))
                   ;;
                   ;; tricky part - GetLibrary returns symbol which needs to get evaluated
                   (if (setq pp (cdfGetBaseCellCDF (ddGetObj (eval libName) cellName)))
                       (setq cdfParamList (foreach mapcar x pp~>parameters
                                                    (list x~>name x~>paramType x~>value )))
                       (setq cdfParamList nil)
                       )

                   )
                 (setq allCdfParamList (tconc allCdfParamList cdfParamList))
                 )
             )
    (car allCdfParamList)
    )
  )

procedure( pckGetCDFparametersByName( cellName)

let((pp libName cdfParamList)
    ;;
    ;; need to comprehend project-specific setup here.
    (if (getShellEnvVar "TCC_PROJECT")
        (progn
          (case (getShellEnvVar "TCC_PROJECT")
              ("mps1"
               (setq libName (strcat "s1" CMB_LIB)))
              ("mps2"
               (setq libName (strcat "s2" CMB_LIB)))
		("x9b05"
               (setq libName (strcat "b05" CMB_LIB)))
              (t (setq libName CMB_LIB)
               )
              )
          )
        (setq libName CMB_LIB))
    if( pp=cdfGetBaseCellCDF( ddGetObj( libName cellName )) then
        cdfParamList = foreach( mapcar x pp~>parameters
                                list( x~>name x~>paramType x~>value ))
    else
        cdfParamList = nil
    )

    cdfParamList

) ; let
) ; pckGetCDFparametersByName



procedure( pckWriteParamListFile( paramList)

let(( fp printFmt fileName nameWidth typeWidth len)

    sprintf( fileName "/tmp/cdfList_%d" random())
    if( fp = outfile( fileName) then

        if( paramList != nil then
            nameWidth = 1
            typeWidth = 1
            foreach( x paramList
                   len = strlen( nth(0 x)) 
                   if( len > nameWidth then nameWidth = len )               
                   len = strlen( nth(1 x)) 
                   if( len > typeWidth then typeWidth = len )               
            )

            sprintf( printFmt "%%-%ds  %%-%ds  %%s\n" nameWidth typeWidth)
            fprintf( fp printFmt "NAME" "TYPE" "VALUE")
            sprintf( printFmt "%%-%ds  %%-%ds  %%L\n" nameWidth typeWidth)
            foreach( x paramList fprintf( fp printFmt nth(0 x) nth(1 x) nth(2 x)) )

        else

            fprintf( fp "** NO PARAMETERS FOUND **" )

        )

        close( fp)

        ;; view( fileName)
    )

    fileName

) ; let
) ; pckWriteParamListFile


procedure( pckCompareCDFParams( file1 file2 templateName @optional collapse)

let( (cmd diffFile fileWidth fmtSpec title)

    fileWidth = 90
    sprintf( diffFile "/tmp/cdfDiff_%d" random()) 
    sprintf( cmd "echo \"Template Name: %s\" > %s"  templateName diffFile)
    sh( cmd)
    sprintf( fmtSpec "Previous CDF Parameters%%-%dsNew CDF Parameters"  (fileWidth/2)-21)
    sprintf( title fmtSpec " ")
    sprintf( cmd "echo \"%s\n\" >> %s"  title diffFile)
    sh( cmd)

    if( collapse sprintf( cmd "diff -ytW %d --suppress-common-lines %s %s >> %s" fileWidth file1 file2 diffFile)
                 sprintf( cmd "diff -ytW %d %s %s >> %s" fileWidth file1 file2 diffFile)
    )
    sh( cmd)

    pckMailHandler( sprintf( nil "Auto Publish CDF Parameter Differences Report (< - Previous, > - New, | - Changed)" ) diffFile )
    ;; view( diffFile)

    diffFile

) ; let
) ; pckCompareCDFParams
