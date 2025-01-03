;;****h* TCC/pckFunctions
;; NAME
;; pckFunctions - collection of general purpose TCC Funcitons
;;
;; AUTHOR 
;; Bill Harris, Vincent Rayappa, Pavel Rott
;;
;; COPYRIGHT 
;; Intel Corporation 2004
;;
;; USAGE
;; load "tcc_collateral/core/skill/pckFunctions.il"
;;
;; KEYWORDS: TCC Project, MOS, DSR
;;****

;;****f* pckFunctions/pckReload
;;
;; FUNCTION
;;
;; pckReload - reloads entire TCC structure
;;
;; USAGE
;; 
;; (pckReload)
;;
(defun pckReload ()
"Reloads entire TCC structure, all SKILL files and pCells."
  (load (strcat TCC_UTILS "/loader.il"))
  )

;;****f* pckFunctions/pckReloadDrf
;;
;; FUNCTION
;;
;; pckReloadDrf - reloads display.drf Display Resource File
;;
;; USAGE
;; 
;; (pckReloadDrf)
;;
(defun pckReloadDrf ()
"Reloads display.drf (Display Resource File) and thus resets all the display colors, stipples, etc."
  (drLoadDrf (strcat (getShellEnvVar "CDS_SITE") "/display.drf"))
)

;;****f* pckFunctions/pckAtof
;;
;; FUNCTION
;;
;; pckAtof - convers string with empty spaces into floating number
;;
;; USAGE
;;
;; pckAtof "10 20" would return 1020.0
;; 
;; SOURCE

(defun pckAtof ( str )
"Converts string with empty spaces into floating number. pckAtof \"10 20\" would return 1020.0 => f_float"
;;****
  (let ( st stList )
    st = ""
    stList = parseString( str )
    foreach( s stList st = strcat( st s))    
    (atof st)
    )
  )

;;****f* pckFunctions/pckGEQP
;;
;; FUNCTION
;;
;; pckGEQP - compares 2 floating numbers within optional tolerance range for "greater than" check.
;; Tolerance by default is set to 1.0e-6. This function MUST be used in pCell development
;; when comparing any floating numbers (coordinates, etc).
;;
;; USAGE
;;
;; (pckGEQP a b )
;;****


(defun pckGEQP ( a b @optional ( tolerance 1.0e-6 ) )
"Compares 2 floating numbers within optional tolerance range for \"greater than or equal to\" check.
Tolerance by default is set to 1.0e-6. This function MUST be used in pCell development
when comparing any floating numbers (coordinates, etc). => t/nil"
  (let ( ) 
    ( cond 
      ( ( a > b ) 
       t
        )
      ( ( abs ( a - b ) ) < tolerance
        t
        )
      ( t
       nil )
      )
    )
  );

;;This function computes the distance between point p1 and p2 using the distance formula
(defun pckPtPtDistance (p1 p2)
"Computes the distance between point p1 and p2 using the distance formula. => f_float"
  (sqrt (plus (times (difference (xCoord p1) (xCoord p2)) (difference (xCoord p1) (xCoord p2)))
     (times (difference (yCoord p1) (yCoord p2))(difference (yCoord p1) (yCoord p2)) ))))



;;****f* pckFunctions/pckLEQP
;;
;; FUNCTION
;;
;; pckLEQP - compares 2 floating numbers within optional tolerance range for "less than" check.
;; Tolerance by default is set to 1.0e-6. This function MUST be used in pCell development
;; when comparing any floating numbers (coordinates, etc).
;;
;; USAGE
;;
;; (pckLEQP a b )
;;****

(defun pckLEQP ( a b @optional ( tolerance 1.0e-6 ) )
"Compares 2 floating numbers within optional tolerance range for \"less than or equal to\" check.
Tolerance by default is set to 1.0e-6. This function MUST be used in pCell development
when comparing any floating numbers (coordinates, etc). => t/nil"
  (let ( ) 
    ( cond 
      ( ( a < b ) 
       t
        )
      ( ( abs ( b - a ) ) < tolerance
        t
        )
      ( t 
       nil )
      )
    )
  );

;;****f* pckFunctions/pckEQP
;;
;; FUNCTION
;;
;; pckEQP - compares 2 floating numbers within optional tolerance range for "equal" check.
;; Tolerance by default is set to 1.0e-6. This function MUST be used in pCell development
;; when comparing any floating numbers (coordinates, etc).
;;
;; USAGE
;;
;; (pckEQP a b )
;;****


(defun pckEQP (a b @optional (tolerance 1.0e-6))
"Compares 2 floating numbers within optional tolerance range for \"equal\" check.
Tolerance by default is set to 1.0e-6. This function MUST be used in pCell development
when comparing any floating numbers (coordinates, etc). => t/nil" 
  (if (lessp (abs (difference a b)) tolerance)
      t
    nil))


;;****f* pckFunctions/pckLessp
;;
;; FUNCTION
;;
;; pckLessp - compares 2 floating numbers within optional tolerance range for "less than" check.
;; Tolerance by default is set to 1.0e-6. This function MUST be used in pCell development
;; when comparing any floating numbers (coordinates, etc).
;;
;; USAGE
;;
;; (pckLEQP a b )
;;****

(defun pckLessp (a b @optional (tolerance 1.0e-6))
"Compares 2 floating numbers within optional tolerance range for \"less than\" check.
Tolerance by default is set to 1.0e-6. This function MUST be used in pCell development
when comparing any floating numbers (coordinates, etc). => t/nil"
  (let () 
    (cond 
      ((and (lessp a  b) (greaterp (abs (difference b  a)) tolerance))
        t)
      (t 
        nil))))

;;****f* pckFunctions/pckGreaterp
;;
;; FUNCTION
;;
;; pckGreaterp - compares 2 floating numbers within optional tolerance range for "Greater than" check.
;; Tolerance by default is set to 1.0e-6. This function MUST be used in pCell development
;; when comparing any floating numbers (coordinates, etc).
;;
;; USAGE
;;
;; (pckLEQP a b )
;;****

(defun pckGreaterp (a b @optional (tolerance 1.0e-6))
"Compares 2 floating numbers within optional tolerance range for \"greater than\" check.
Tolerance by default is set to 1.0e-6. This function MUST be used in pCell development
when comparing any floating numbers (coordinates, etc). => t/nil"
  (let () 
    (cond 
      ((and (greaterp a  b) (greaterp (abs (difference b  a)) tolerance))
        t)
      (t 
        nil))))

; *************************************************************************************
; GET PROCESS ID / CHECK FOR 1265 or 1266 / CHECK FOR ANY PROCESS:

;;****f* pckFunctions/pckGetProcessId
;;
;; FUNCTION
;;
;; pckGetProcessId - obtain manufacturing process ID (e.g. 1264, 1266) defined in technology file.
;; By default it check technology libray attahced to AUX_LIB
;;
;; USAGE
;;
;; (pckGetProcessId MOS_LIB)
;;****

(defun pckGetProcessId ( @optional libName)
"Obtain manufacturing process ID (e.g. 1264, 1266) defined in PROCESS_NAME env. variable. => t_string"
  (let (tid processId)

    if( (libName == nil) then if( boundp( 'AUX_LIB) then libName = AUX_LIB))
    if( libName == nil then
         processId = getShellEnvVar( "PROCESS_NAME")
         else
         processId = getShellEnvVar( "PROCESS_NAME")
;; Changed to always use PROCESS_NAME env var per Pasha's request 9-5-2006 
;; All other logic left in so as not to disturb argument list and keep LINT happy :-)
;;       tid = techGetTechFile( ddGetObj( libName ))
;;       processId = techGetParam(tid "processId")
         )
    processId
    
    )
  )

;;****f* pckFunctions/pckIs1268
;;
;; FUNCTION
;;
;; pckIs1268 - check whether you are working in 1266 process. Returns t or nil
;;
;; USAGE
;;
;; (pckIs1268)
;;****

(defun pckIs1268 ( @optional libName)
"Check whether you are working in 1268 process. => t/nil"
  (if (equal (pckGetProcessId libName) "1268") t nil)
  )

;;****f* pckFunctions/pckIs1266
;;
;; FUNCTION
;;
;; pckIs1266 - check whether you are working in 1266 process. Returns t or nil
;;
;; USAGE
;;
;; (pckIs1266)
;;****

(defun pckIs1266 ( @optional libName)
"Check whether you are working in 1266 process. => t/nil"
  (if (equal (pckGetProcessId libName) "1266") t nil)
  )

;;****f* pckFunctions/pckIs1265
;;
;; FUNCTION
;;
;; pckIs1265 - check whether you are working in 1265 process. Returns t or nil
;;
;; USAGE
;;
;; (pckIs1265)
;;****

(defun pckIs1265 ( @optional libName)
"Check whether you are working in 1265 process. => t/nil"
    (if (equal (pckGetProcessId libName) "1265") t nil)
)

;;****f* pckFunctions/pckNot1265
;;
;; FUNCTION
;;
;; pckNot1265 - check whether you are not working in 1265 process. Returns t or nil
;;
;; USAGE
;;
;; (pckNot1265)
;;****

(defun  pckNot1265 ( @optional libName)
"Check whether you are NOT working in 1265 process. => t/nil"
    (if (equal (pckGetProcessId libName) "1265") nil t)
  )

;;****f* pckFunctions/pckIsProcess
;;
;; FUNCTION
;;
;; pckIsProcess - compares a string to a process define in the tech library
;;
;; USAGE
;;
;; (pckIsProcess "1266" CON_LIB)
;;****

(defun pckIsProcess ( thisProcName @optional libName)
"Compares a string to a process defined by the PROCESS_NAME env. variable => t/nil"
    (if (equal (pckGetProcessId libName) thisProcName ) t nil)
  )

;;****f* pckFunctions/pckGTProcess
;;
;; FUNCTION
;;
;; pckGTProcess - compares a string to a process define in the tech library - returns t if PROCESS_ID is greater
;;
;; USAGE
;;
;; (pckGTProcess "1266") - returns t if you are in 1268 environment
;;****

(defun pckGTProcess ( thisProcName @optional libName)
"Compares if a string is \"greater than\" a process defined by the PROCESS_NAME env. variable => t/nil"
  ( let (result)
    (setq result (strcmp  (pckGetProcessId libName) thisProcName ))
    (if (equal result 1 ) t nil)
  )
)

;;****f* pckFunctions/pckLTProcess
;;
;; FUNCTION
;;
;; pckLTProcess - compares a string to a process define in the tech library - returns t if PROCESS_ID is lesser
;;
;; USAGE
;;
;; (pckLTProcess "1268") - returns t if you are in 1266 environment
;;****

(defun pckLTProcess ( thisProcName @optional libName)
"Compares if a string is \"less than\" a process defined by the PROCESS_NAME env. variable => t/nil"
  ( let (result)
    (setq result (strcmp  (pckGetProcessId libName) thisProcName ))
    (if (equal result -1 ) t nil)
  )
)

;;
;; 

;;****f* pckFunctions/pckNeedCfTf
;;
;; FUNCTION
;;
;; pckNeedCfTf - checks whether you need to draw compliance features (X6+ requirements)
;;
;; USAGE
;;
;; (pckNeedCfTf "metal3")
;;****
(defun pckNeedCfTf ( layer )
"Checks if the given layer needs Compliance Features by checking for presence of a CF rule. => t/nil"
(let (result isLog)
    isLog = pckIsLogOn()
    if( isLog then pckLogOff()) 
    result = pckLayerInfo( AUX_LIB "bn2Width" layer )
    if( result != nil then result = t)
    if( isLog then pckLogOn())
    result
)
)


;;****f* pckFunctions/pckNeedCfTfMetalsList
;;
;; FUNCTION
;;
;; pckNeedCfTfMetalsList - returns list of metals that require Compliance/Termination Features
;; A metal is determined to need Cf/Tf it it has a "bn2Width" rule in the techfile.
;;
;; USAGE
;;
;; metalsList = pckNeedCfTfMetalsList()
;; 
;; SOURCE

(defun pckNeedCfTfMetalsList ()
"Generate a list of all layers that require Compliance Features. => l_list"
;;****

( let ( i cfTfMetalsList thisMetal )

    i = 1
    sprintf(thisMetal "metal%d" i)

    while( pckNeedCfTf( thisMetal)
        cfTfMetalsList = tconc( cfTfMetalsList thisMetal)
        i = i + 1
        sprintf(thisMetal "metal%d" i)
    )

    car(cfTfMetalsList)

) ; let
) ; pckNeedCfTfMetalsList


;;****f* pckFunctions/pckIsSAV
;;
;; FUNCTION
;;
;; pckIsSAV - checks if via can be a SAV (X6+ requirements)
;;
;; USAGE
;;
;; (pckIsSAV "via1")
;;****
(defun pckIsSAV ( layer )
"Checks if via can be a SAV (Self-aligned via). => t/nil"
(let (result isLog)
    isLog = pckIsLogOn()
    if( isLog then pckLogOff()) 
    result = pckLayerInfo( AUX_LIB "wingWidth" layer )
    if( result != nil then result = t)
    if( isLog then pckLogOn())
    result
)
)


;;****f* pckFunctions/pckGetClearance
;;
;; FUNCTION
;;
;; pckGetClearance - Returns amount of space to clear for adjacent bussing or other metal.  Includes space for CF if needed.
;;
;; USAGE
;;
;; (pckGetClearance "metal1") 
;;****
(defun pckGetClearance ( layer )
"Returns amount of space to clear for adjacent bussing or other metal. Includes space for CF if needed. => f_float"
(let (clearance  )

    if( pckNeedCfTf( layer) then

        clearance = pckLayerInfo(AUX_LIB "bn1WideWidthSpace" layer ) +
                    pckLayerInfo(AUX_LIB "bn1WideWidthSpace" layer ) +
                    pckLayerInfo(AUX_LIB "bn1WideWidthSpace" layer ) +
                    pckLayerInfo(AUX_LIB "bn2Width" layer ) +
                    pckLayerInfo(AUX_LIB "bn2MinSpacing" layer )*1.5

        clearance = pckPutOnGrid( clearance) ;; Mult by 1.5 above so need this! 

    else

        clearance = max( pckLayerInfo(AUX_LIB "minSpacingX" layer) pckLayerInfo(AUX_LIB "minSpacingY" layer))
        clearance = pckPutOnGrid( clearance * 1.5) ;; Mult by 1.5 so need this! 

    )

    clearance

) ; let
)

;;****f* pckFunctions/pckGetBSpullback
;;
;; FUNCTION
;;
;; pckGetBSpullback - Returns distance to pull back the "needTermCells" from long edges of narrow metal lines for correct Banana Spacing (BS).
;;
;; USAGE
;;
;; (pckGetBSpullback lineWidth layer) 
;;****
(defun pckGetBSpullback ( lineWidth layer )
"Returns distance to pull back the \"needTermCells\" from long edges of narrow metal lines for correct Banana Spacing (BS). => f_float"
(let (pb  )

    if( pckNeedCfTf( layer) then

        if( lineWidth < pckLayerInfo(AUX_LIB "cfNarrow2WideBdry" layer ) then

            pb = pckLayerInfo(AUX_LIB "bn1WideWidthSpace" layer ) - 
                 pckLayerInfo(AUX_LIB "bn1NarrowWidthSpace" layer )

       else

           pb = 0.0

      )

    else

        pb = 0.0

    )

    pb

) ; let
)

;;**********************************************************************
;; FUT functions:
;;
;; NOTE: Moved here from pckX6Functions.il since pckCreateRectFUT is called by many templates, 
;; and can work in 1265 process if you set addFUT parameter to "no".
;; 07-12-2005  Bill Harris was here!
;;
procedure(pckCreateFUT( cv meLyr bBox @optional libName)
"Add the FUT layer to the given bBox. => d_object"
let( (dbId futPurpose tid lid)

    ;;futPurpose = strcat( meLyr "fut")
    ;; new techfile defintions according to DT. 2/10/05
    futPurpose = "FeatureUnderTest"

    if( (libName == nil) then libName = AUX_LIB)
    tid = techGetTechFile( ddGetObj( libName ))

    lid = techGetLP( tid list( meLyr futPurpose))

    if( lid then
        dbId = dbCreateRect( cv list( meLyr futPurpose) bBox)
    else
        pckDebug( "pckCreateFUT" strcat("No FUT layer defined for Layer: " meLyr))
        dbId = nil
    )

    dbId

); let
); pckCreateFUT

(defun pckCreateRectFUT ( cv meLyr bBox )
"Draw the FUT layer along with the metal layer to the given bBox if \"addFUT\" parameter = \"yes\". => d_object"
  (let (dbId futPurpose tid lid figId)

    figId  = dbCreateRect( cv meLyr bBox )
    
    (setq tid (car (setof param cv~>parameters~>value (equal param~>name "addFUT" )) ) )

    if( tid then

        (if (member car( meLyr ) parseString( tid~>value ) ) || (equal tid~>value "yes" )
            (progn dbCreateRect( cv list( car( meLyr ) "FeatureUnderTest" ) bBox ) )
            ) 

    )

    figId

); let
); pckCreateRectFUT

; *************************************************************************************
; DESIGN RULE ACQUISITION:

;;****h* TCC/DesignRules
;; NAME
;; Design Rules Aquisition functions.
;;
;; AUTHOR 
;; Bill Harris, Vincent Rayappa, Pavel Rott
;;
;; COPYRIGHT 
;; Intel Corporation 2004
;;
;; USAGE
;;****

;;****f* DesignRules/pckUpdateTechfile
;;
;; FUNCTION
;;
;; pckUpdateTechfile - function reopens current technology library and refreshes its contents in vurtual memory.
;; Useful when techfile was reloaded and you need to refresh another session.
;;
;; USAGE
;;
;;( pckUpdateTechfile)
;;****

(defun pckUpdateTechfile ()
"Reopens current technology library and refreshes its contents in vurtual memory.
Useful when techfile was reloaded and you need to refresh another session. => t"
  (let (thisTechfileLib)
    (setq thisTechfileLib (strcat "p" (getShellEnvVar "PROCESS_NAME") "TechnologyLib"))
    (techRefreshTechFile (techOpenTechFile thisTechfileLib "techfile.cds" ) )
    t
  )
)

;;****f* DesignRules/pckLayerInfo
;;
;; FUNCTION
;;
;; pckLayerInfo - returns value for a spacing rule. Requires library name (may use corresponding global variable)
;; rule name (minWidth, maxWidth, etc) and layer name. LayerPurpose parameter is optional.
;;
;; USAGE
;;
;;(pckLayerInfo MOS_LIB "minWidth" "metal1")
;;****

(defun pckLayerInfo ( lib name layer @optional ( layerPurpose "drawing" ) )
"Returns value for a spacing rule. Requires library name (may use corresponding global variable) or nil,
rule name (minWidth, maxWidth, etc.), and layer name. LayerPurpose parameter is optional. => f_float/nil"
  (let (value)
    layer = convertLayerName(layer)
     (setq value
           (car
            (exists x TCC_PROCESS_RULES
                    (and
                     (equal x->name name)
                     (equal x->layer1 layer)
                     (equal x->layer2 nil)))))
     (unless value
       (pckDebug "pckLayerInfo" (strcat "returning nil for Rule: " name "; Layer: " layer))
       )
     (value->value)
     )
  )


;;****f* DesignRules/pck2LayerInfo
;;
;; FUNCTION
;;
;; pck2LayerInfo - returns value for a 2 layer spacing rule. Requires library name (may use corresponding global variable)
;; rule name (minWidth, maxWidth, etc) and layer names. LayerPurpose parameters are optional.
;;
;; USAGE
;;
;;(pck2LayerInfo MOS_LIB "minEnclosure" "metal1" "via1" )
;;****

(defun pck2LayerInfo ( lib name layer1 layer2 @key ( layer1Purpose "drawing" ) ( layer2Purpose "drawing" ) )
"Returns value for a 2 layer spacing rule. Requires library name (may use corresponding global variable) or nil,
rule name (minWidth, maxWidth, etc.), and layer names. LayerPurpose parameters are optional. => f_float/nil"
  (let (value)
    layer1 = convertLayerName(layer1)
    layer2 = convertLayerName(layer2)
     (setq value
           (car
            (exists x TCC_PROCESS_RULES
                    (and (equal x->name name) 
                         (or (and (equal x->layer1 layer1) (equal x->layer2 layer2))
                             (and (equal x->layer1 layer2) (equal x->layer2 layer1))
                             )
                         ))))
     (unless value
       (pckDebug "pck2LayerInfo" strcat("returning nil for Rule: " name "; Layer1: " layer1 "; Layer2: " layer2)))
     value->value
     ) ; let
  )


;;****f* DesignRules/pckFindRuleByComment
;;
;; FUNCTION
;;
;; pckFindRuleByComment - find a spacing rule by it's optional comment. If mutliple rules have the same comment, 
;; will return the first rule with the comment.
;;
;; USAGE
;;
;;(pckFindRuleByComment "NW_12" )
;;****
(defun pckFindRuleByComment ( comment )
"Find a spacing rule by it's optional comment. If mutliple rules have the same comment, 
will return the first rule with the comment. => f_float/nil"
  (let ( value )
     (setq value (car (exists x TCC_PROCESS_RULES (equal x->comment comment) ) ) )
     (unless value
       (pckDebug "pckFindRuleByComment" "Cannot find a rule with comment: " comment) )
     value
     )
  )

;;****f* DesignRules/pckAddTechRule
;;
;; FUNCTION
;;
;; pckAddTechRule - temprorarily add a rule to available set of rules. Will be accessible only in sessions that call this function. 
;; Use it for testing your templates.
;;
;; USAGE
;;
;;(pckAddTechRule "minWidthNNY" "poly" 12.4 nil "New rule")

(defun pckAddTechRule ( name layer1 value @optional (layer2 nil) (comment "") )
"Temprorarily add a rule to available set of rules. Will be accessible only in sessions that call this function. 
Use it for testing your templates. => t"
  (let (dpl)
    (setq dpl (ncons nil))
    (putpropq dpl name name)
    (putpropq dpl layer1 layer1)
    (putpropq dpl value value)
    (putpropq dpl layer2 layer2)
    (putpropq dpl comment comment)
    
    (unless (and
             (nequal "YES" (getShellEnvVar "TCC_DEVELOPMENT_ENV"))
             (equal "x10atc" (getShellEnvVar "PROJECT")))
      (setq TCC_PROCESS_RULES (cons dpl TCC_PROCESS_RULES))
      (fprintf stdout "***** DEFINING/REDEFINING RULE *****\n")
      (pckWarn "pckAddTechRule" (sprintf nil "%L %L %L %L %L" name layer1 layer2 value comment)))
    t
    )
  )


;; *************************************************************************************
;; GET GRID, SNAP TO GRID:
;;****h* TCC/GridFunctions
;; NAME
;; Various grid functions
;;
;; AUTHOR 
;; Bill Harris, Vincent Rayappa, Pavel Rott
;;
;; COPYRIGHT 
;; Intel Corporation 2004
;;
;; USAGE
;;****

;;****f* GridFunctions/pckGetFillerGrid
;;
;; FUNCTION
;;
;; pckGetFillerGrid - obtain grid size for the filler cells
;;
;; USAGE
;;
;; (pckGetFillerGrid  "" "x" ) - returns the x width of the be filler cell.
;; (pckGetFillerGrid  "be" "y" ) - returns the y width of the be filler cell.
;; (pckGetFillerGrid  "fe" "x" ) - returns the x width of the fe filler cell.

(defun pckGetFillerGrid ( type dir )
"Obtain grid size for the filler cells. (pckGetFillerGrid  \"\" \"x\" ) - returns the x width of the be filler cell.
(pckGetFillerGrid  \"be\" \"y\" ) - returns the y width of the be filler cell.
(pckGetFillerGrid  \"fe\" \"x\" ) - returns the x width of the fe filler cell. => f_float"

(let (fillerName)

  if( type == nil then type = "")
  fillerName = strcat( type "fillergrid_" dir)
  (pckGetProcessInfo fillerName)

)
)

;;****f* GridFunctions/pckGetGrid
;;
;; FUNCTION
;;
;; pckGetGrid - obtain grid size for the cellview
;;
;; USAGE
;;
;;(pckGetGrid)
(defun pckGetGrid ( @optional cvId ) 
"Obtain grid size for the cellview. => f_float"
  (pckGetProcessInfo "XSNAP_SPACING")
  ); pckGetGrid

;;****f* GridFunctions/pckPutOnGrid
;;
;; FUNCTION
;;
;; pckPutOnGrid - round floating number to the nearest grid point. Takes optional grid size (if different from 
;; specified in tech file).
;;
;; USAGE
;;
;; (pckPutOnGrid 17.5)
(defun pckPutOnGrid ( float_num @optional grid )
"Round floating number to the nearest grid point. Takes optional grid size (if different from value
specified in tech file). => f_float"
  (let ( )
    (if (grid == nil) then
        grid = pckGetGrid()
    )
    grid * ( round float_num/ grid ) 
    )
);

(defun pckPutOnGridCeiling ( float_num @optional grid (tolerance (pckGetGrid)))
"Round floating number to the nearest grid point ABOVE. Takes optional grid size (if different from value
specified in tech file). => f_float"
  (let (floorVal ceilingVal)
    (if (grid == nil) then
        grid = pckGetGrid()
    )
    (setq ceilingVal (pckPutOnGrid grid * (ceiling (pckPutOnGrid float_num tolerance)/ grid) tolerance))
    (setq floorVal (pckPutOnGrid grid * (floor (pckPutOnGrid float_num tolerance)/grid) tolerance))
    (if (pckEQP float_num floorVal) floorVal ceilingVal)
    )
);

(defun pckPutOnGridFloor (float_num @optional grid (tolerance (pckGetGrid)))
"Round floating number to the nearest grid point BELOW. Takes optional grid size (if different from value
specified in tech file). => f_float"
  (let (floorVal ceilingVal)
    (if (grid == nil) then
        grid = pckGetGrid()
    )
    (setq ceilingVal (pckPutOnGrid grid * (ceiling (pckPutOnGrid float_num tolerance)/ grid) tolerance))
    (setq floorVal (pckPutOnGrid grid * (floor (pckPutOnGrid float_num tolerance)/grid) tolerance))
    (if (pckEQP float_num ceilingVal) ceilingVal floorVal)
    )
);


(defun pckCheckGrid ( float_num @optional (grid pckGetGrid() )   )
"Checks if a given floating number is on-grid. => t/nil"
  (let ()
    (when ( equal ( pckPutOnGrid float_num grid ) - float_num  0.0 )
      t
      )
    )
  )

(defun pckPutOnGridBBoxList ( xyList @optional (grid pckGetGrid() )   )
"Round all coordinates in the given bBox to the nearest grid point. Takes optional grid size (if different from value
specified in tech file). => l_list"
  (let (llx lly urx ury )
    ( mapcar  (
               lambda ( x )
                      ury = pckPutOnGrid( yCoord( upperRight( x )) grid )
                      urx = pckPutOnGrid( xCoord( upperRight( x )) grid )
                      llx = pckPutOnGrid( xCoord( lowerLeft( x )) grid )
                      lly = pckPutOnGrid( yCoord( lowerLeft( x )) grid )
                      list( llx:lly urx:ury )
                      ) xyList
              )
    )
)
(defun pckPutOnGridBBox ( bBox @optional (grid pckGetGrid() )   )
"Round all coordinates in the given bBox to the nearest grid point. Takes optional grid size (if different from value
specified in tech file). => l_list"
  (let (llx lly urx ury )
    ury = pckPutOnGrid( yCoord( upperRight( bBox )) grid )
    urx = pckPutOnGrid( xCoord( upperRight( bBox )) grid )
    llx = pckPutOnGrid( xCoord( lowerLeft( bBox )) grid )
    lly = pckPutOnGrid( yCoord( lowerLeft( bBox )) grid )
    list( llx:lly urx:ury )
    )
)

;; *************************************************************************************
;; PAD/BUSS INFORMATION:

(defun pckGetPadInfo ( libName padName )
"Returns a DPL list of all the given PADROW attributes => l_list/nil"
  (car (exists x PAD_PARAMS (equal x->name padName) ))
  );; pckGetPadInfo

(defun pckGetBondPadInfo ( libName bondPadName )
"Returns a DPL list of all the given PAD attributes => l_list/nil"
  (car (exists x BOND_PAD_PARAMS (equal x->name bondPadName) ))
  );; pckGetBondPadInfo

 
(defun pckGetBusInfo (libName busName )
"Returns a DPL list of all the given BUSS attributes => l_list/nil"
    (car (exists x BUS_PARAMS (equal x->name busName) ))
  );; pckGetBusInfo


(defun pckGetLabelInfo (libName labelName )
"Returns a DPL list of all the given LABEL attributes => l_list/nil"
  (car (exists x LABEL_PARAMS (equal x->name labelName) ))
  )


(defun pckGetProcessInfo (processName )
"Returns the value given a process attribute name.  Example: pckGetProcessInfo(\"TR_POLY_PITCH\") 
returns the value for that process attribute => f_float/nil"
  (getq (car (exists x PROCESS_PARAMS (equal x->name processName) )) "value")
  )

(defun pckGetDieInfo (dieName)
"Returns a DPL given a die name.  Example: pckGetDieInfo(\"X11A\") => l_list/nil"
(car (exists x TOP_DIE_PARAMS (equal (getq x name) dieName)))
)
;; *************************************************************************************
;; BUSS BUILDING FUNCTIONS:
;; Set the auxInterconnect buss leg length to fit exactly across Npads, centered.
;; width normally set to 0.0, can be used for possible future offest?

(defun pckSetInterconnectLength ( padrow npads width)
"Returns the buss leg length to fit exactly across Npads, centered.
Width normally set to 0.0, can be used for possible future offest? => f_float"
  (let (padInfo length)
    padInfo = pckGetPadInfo( ECD_LIB padrow ) 
    
    length = ((padInfo->spacing_x1 + padInfo->pad_width) * npads) - (width * 2.0)                                  
    length
    
    ) ; let
  ) ; pckSetInterconnectLength

;; *************************************************************************************
;; BUSS BUILDING FUNCTIONS:

(defun pckFillRowWithMaximumRestriction ( height space minWidth )
  (let (w number pnts)
    (if (pckLEQP height minWidth)
        (progn
          w = height
          number = 1 )
      (progn
        ;;
        ;; start iteration here
        ;;
        number = 1
        while( ( pckGEQP  ( height + space ) /( number + 1) - space minWidth )
               (fprintf stdout "-D- %L %L %L\n" ( height + space ) / ( number + 1 ) - space number minWidth)
               number++
               );; while
        w = ( height + space ) / number - space
        )
      )
    w:number
    )
  );; defun




;;Under_fills a single column strating from either top or bottom or the row
;;
;;
(defun pckFillSingleCol (BBox widthY spaceY @optional (direct "up") )
  (let (x1 y1 x2 y2  yLimit axisY pnts)
    pnts = nil
    x1 = car( lowerLeft( BBox ) )
    x2 = car( upperRight( BBox ) )
    ;;fprintf( stdout "-D- pckFillSingleCol inputs: %L %L %L\n" BBox widthY direct)
    (if (equal direct "down")
        (progn
          axisY = cadr( upperRight( BBox ) )
          BBox = car( pckReflectMXBBoxList( list( BBox ) axisY ) )
          ;;fprintf( stdout "-D- pckFillSingleCol flip bbox: %L\n" BBox )
          )
        );; if
    yLimit = cadr( upperRight( BBox ) )
    y1 = cadr( lowerLeft( BBox ) )
    while( (pckLEQP y1 yLimit - widthY )
           y2 = y1 + widthY
           pnts = cons( list( x1:y1 x2:y2) pnts)
           y1 = y2 + spaceY )

    (if (equal direct "down")
        (progn 
          pnts = pckReflectMXBBoxList( pnts axisY )
          )
        )
    pnts
    );; let
  );; pckFillSingleCol
(defun pckFillSingleRow (BBox widthX spaceX @optional (direct "right") )
  (let (x1 y1 x2 y2 axisX pnts)
    pnts = nil
    x1 = car( lowerLeft( BBox ) )
    y1 = cadr( lowerLeft( BBox ) )
    x2 = car( upperRight( BBox ) )
    y2 = cadr( upperRight( BBox ) )

    (if (equal direct "left")
        (progn
          axisX = xCoord( upperRight( BBox ) )
          BBox = car( pckReflectMYBBoxList( list( BBox ) axisX ) )
          )
        );; if
    x1 = xCoord( lowerLeft( BBox ) )
    while( (pckLEQP x1 xCoord( upperRight( BBox ) ) - widthX )
           x2 = x1 + widthX
           pnts = cons( list( x1:y1 x2:y2) pnts)
           x1 = x2 + spaceX 
           )
    (if (equal direct "left")
        (progn 
          pnts = pckReflectMYBBoxList( pnts axisX )
          )
        )
    pnts
    );; let
)
(defun pckFitSingleRowY ( BBox rWidth rSpace @optional grid )
  (let ( n x1 y y1 x2 y2 yLimit halfHeight pnts )
    ;;
    ;; This function fits a single row of rectangles into a box.
    ;; Box's width can be arbitrary
    ;; 
    ;; Intended usage: 
    ;; Find number of contacts that can fit on an active diffusio layer along a gate poly
    ;;
    ;; Returns: list of contacts's coordinates
    ;;
    ;;fprintf( stdout "Inputs BBox %L rWidth: %L rSpace: %L\n" BBox rWidth rSpace )
    ( setq pnts nil )
    ;;( pckDebug "pckFitSingleRowY" ( sprintf nil "input BBox dimensions: %L" BBox ) )
    ( setq y1 rWidth )
    ( setq n 0 )
    ( setq yLimit ( cadr ( trBBoxDims BBox ) ) )
    ;;( pckDebug "pckFitSingleRowY" ( sprintf nil "y1 %f BBox height %f" y1 yLimit ) )
    ;;
    ;; First we need to figure how how many
    ;; rectangles can be fit into the BBox
    ;; 
    ( if ( y1 - yLimit ) > 1e-6 then
         ;; ( pckError "pckFitSingleRowY" ( sprintf nil "A single contact cannot be fitted into %L" BBox ) )
         else
         ( setq n ( add1 n ) )
         )
    ( while pckLEQP( y1 yLimit)
      ( setq y1 ( plus y1 rWidth rSpace ) )
      ( when pckLEQP( y1 yLimit )
             ( setq n ( add1 n ) )
             ); when
      );
    ;;( pckDebug "pckFitSingleRowY" ( sprintf nil "Number of vertical contacts to be placed: %L" n ) )
    ( setq x1 ( xCoord ( lowerLeft BBox ) ) )
    ;; ( setq x2 ( xCoord ( lowerLeft BBox ) ) + rWidth )
    ( setq x2 ( xCoord ( upperRight BBox ) ) )

    ;;
    ;; Independently on the number of final number, start as if
    ;; we will have even number of contacts
    ;;
    ;;
    ;; in case of grid 
    (if grid then
      ( setq halfHeight ( cadr ( trBBoxCenter BBox ) )  ) ;; GRID ?
      ( setq halfHeight ( pckPutOnGrid halfHeight grid ) )
      ( setq y1  ( pckPutOnGrid halfHeight + rSpace/ 2.0 grid ) )
      ;;fprintf( stdout "Middle of the bBox: %L bottom of first contact: %L\n" halfHeight y1 )
      /*
      if( pckLEQP( y1 halfHeight + rSpace/ 2.0) then
                  y1 = y1 + grid
                  ;;fprintf( stdout "Corrected: y1 = %L\n" y1 )
                  )
      */
      else
      ( setq halfHeight ( cadr ( trBBoxCenter BBox ) )  ) ;; GRID ?
      ( setq y1 halfHeight + rSpace/ 2.0 ) 
      )
    ( when ( mod n 2 ) == 1
           ;; Make correction in case 
           ;; of odd number of contacts
           ;; place first contact then proceed as in even case
           (if grid then
             ( setq y1 ( pckPutOnGrid halfHeight - rWidth/2.0 grid ) )
             ( setq y2 y1 + rWidth )
             ;;( setq y2 ( pckPutOnGrid halfHeight + rWidth/2.0 grid ) )
             else 
             ( setq y1 halfHeight - rWidth/2.0 )
             ( setq y2 y1 + rWidth )
             ;;( setq y2 halfHeight + rWidth/2.0 )
             )
           ;;( pckDebug "pckFitSingleRowY" ( sprintf nil "First contact %L" list( x1:y1 x2:y2 ) ) )
           ( setq pnts ( cons list( x1:y1 x2:y2 ) pnts ) )
           ( setq y1 y2 + rSpace )
           ); when
    ;;( pckDebug "pckFitSingleRowY" ( sprintf nil "Even contacts: y1 %L yLimit %L" y1 ( yCoord ( upperRight BBox ) ) ) )
    (while (pckLEQP y1 ( yCoord ( upperRight BBox ) ) - rWidth )
      ( setq y2 y1 + rWidth )
      ;;( pckDebug "pckFitSingleRowY" ( sprintf nil "%L" list( x1:y1 x2:y2 ) ) )
      ( setq pnts ( cons list( x1:y1 x2:y2 ) pnts ) )
      ( setq y 2.0*halfHeight - y1 )
      ;( pckDebug "pckFitSingleRowY" ( sprintf nil "%L\n" list( x1:y1 x2:y2 ) ) )
      ;;( setq pnts ( cons list( x1:y2-rWidth x2:y2) pnts ) )
      ( setq pnts ( cons list( x1:y - rWidth x2:y) pnts ))
      ( setq y1 y2 + rSpace )
      ); while
    pnts;
    ); let
  ); pckFitSingleRowY


(defun pckFitSingleRowX ( BBox rWidth rSpace @optional grid )
  (let ( n x x1 y1 x2 y2 xLimit halfWidth pnts )
    ;;
    ;; This function fits a single row of rectangles into a box.
    ;; Box's width can be arbitrary
    ;; 
    ;; Intended usage: 
    ;; Find number of contacts that can fit on an active diffusio layer along a gate poly
    ;;
    ;; Returns: list of contacts's coordinates
    ;;
    ( setq pnts nil )
    ;;( pckDebug "pckFitSingleRowX" ( sprintf nil "input BBox dimensions: %L\n" BBox ) )
    ( setq x1 rWidth )
    ( setq n 0 )
    ( setq xLimit ( car ( trBBoxDims BBox ) ) )
    ;;
    ;; First we need to figure how how many
    ;; rectangles can be fit into the BBox
    ;; 
    ( if ( x1 - xLimit ) > 1e-6 then
         ( pckError "pckFitSingleRowX" ( sprintf nil "A single contact cannot be fitted into %L" BBox ) )
         else
         ( setq n ( add1 n ) )
         )
    ( while  pckLEQP( x1  xLimit) 
      ( setq x1 ( plus x1 rWidth rSpace ) )
      ( when pckLEQP( x1  xLimit) 
             ( setq n ( add1 n ) )
             ); when
      );
    ;;( pckDebug "pckFitSingleRowX" ( sprintf nil "Number of horizontal contacts to be placed: %L\n" n ) )
    ( setq y1 ( yCoord ( lowerLeft BBox ) ) )
    ;; ( setq x2 ( xCoord ( lowerLeft BBox ) ) + rWidth )
    ( setq y2 ( yCoord ( upperRight BBox ) ) )
    ;;
    ;; Independently on the number of final number, start as if
    ;; we will have even number of contacts
    ;;
    (if grid then
      ( setq halfWidth ( car ( trBBoxCenter BBox ) ))
      ( setq halfWidth (pckPutOnGrid halfWidth grid ) )
      ( setq x1 (pckPutOnGrid halfWidth + rSpace/ 2.0 grid ) );; GRID ???
      else
      ( setq halfWidth ( car ( trBBoxCenter BBox ) ))
      ( setq x1 halfWidth + rSpace / 2.0 ) ;; GRID ???
      )
    (when ( mod n 2 ) == 1
           ;; Make correction in case 
           ;; of odd number of contacts
           ;; place first contact then proceed as in even case
          (if grid then
            ( setq x1 (pckPutOnGrid halfWidth - rWidth/2.0 grid))
            ( setq x2 (pckPutOnGrid halfWidth + rWidth/2.0 grid))
            else 
            ( setq x1 halfWidth - rWidth/2.0 )
            ( setq x2 halfWidth + rWidth/2.0 )
            )
           ;; ( pckDebug "pckFitSingleRowX" ( sprintf nil "First contact %L\n" list( x1:y1 x2:y2 ) ) )
           ( setq pnts ( cons list( x1:y1 x2:y2 ) pnts ) )
           ( setq x1 x2 + rSpace )
           ); when

    ( while pckLEQP( x1 ( xCoord ( upperRight BBox ) ) - rWidth)
            ( setq x2 x1 + rWidth )
            ( setq pnts ( cons list( x1:y1 x2:y2 ) pnts ) )
            ( setq x 2.0*halfWidth - x1 )
            ( setq pnts ( cons list( x-rWidth:y1 x:y2) pnts ) )
            ( setq x1 x2 + rSpace )
            ); while
    ;;( pckDebug "pckFitSingleRowX" ( sprintf nil "BBoxes for the contacts: %L\n" pnts ) )
    pnts;
    ); let
); pckFitSingleRowX

; *************************************************************************************
; SORT BBOX:
(defun pckSortBBox ( pointList dir )
  (if dir == "X" then
      ( sort pointList 'pckSortBBoxRowX )
      else
      ( sort pointList 'pckSortBBoxRowY )
      )
)

(defun pckSortInstX (inst1 inst2)
  (pckSortBBoxRowX inst1~>bBox inst2~>bBox))

(defun pckSortInstY (inst1 inst2)
  (pckSortBBoxRowY inst1~>bBox inst2~>bBox))

(defun pckSortBBoxRowX ( bbox1 bbox2 ) 
  (let ( x1 x2 )
    ( setq x1 ( xCoord ( lowerLeft bbox1 ) ) )
    ( setq x2 ( xCoord ( lowerLeft bbox2 ) ) ) 
    ( cond 
      ( x1 <= x2 t )
      ( t nil )
      ) ;cond
    )
); pckSortBBoxRowX 


(defun pckSortBBoxRowY ( bbox1 bbox2 ) 
  ( let ( y1 y2 )
    ( setq y1 ( yCoord ( upperRight bbox1 ) ) )
    ( setq y2 ( yCoord ( upperRight bbox2 ) ) ) 
    ( cond 
      ( y1 <= y2 t )
      ( t nil )
      ) ;cond
    )
); pckSortBBoxRowX

(defun pckSortBBoxRowXrev (bbox1 bbox2)
    (let (x1 x2)
      (setq x1 (car (lowerLeft bbox1)))
      (setq x2 (car (lowerLeft bbox2)))
      (cond
        ((leqp x2 x1) t)
        (t nil)
        )
      )
    )

(defun pckSortBBoxRowYrev (bbox1 bbox2)
  (let (y1 y2)
    (setq y1 (cadr (lowerLeft bbox1)))
    (setq y2 (cadr (lowerLeft bbox2)))
    (cond
      ((leqp y2 y1) t)
      (t nil)
      )
    )
  )

(defun pckBBoxListOnGrid ( xyList grid )
  (let ( llx lly urx ury )
    ( mapcar (  
              lambda ( x ) 
                     ( setq urx ( pckPutOnGrid ( xCoord ( upperRight x ) ) grid ) )
                     ( setq ury ( pckPutOnGrid ( yCoord ( upperRight x ) ) grid ) )
                     ( setq llx ( pckPutOnGrid ( xCoord ( lowerLeft x ) )  grid ) )
                     ( setq lly ( pckPutOnGrid ( yCoord ( lowerLeft x ) )  grid ) )
                     list( llx:lly urx:ury ) ) xyList )
    )
)


(defun pckDrawRectFromListWithinZone ( cv layer xyList allowedZone )
  (let ( llx lly urx ury )
    ( mapcar (  
              lambda ( x ) 
                     ( setq urx ( xCoord ( upperRight x ) ) )
                     ( setq ury ( yCoord ( upperRight x ) ) ) 
                     ( setq llx ( xCoord ( lowerLeft x ) )  )
                     ( setq lly ( yCoord ( lowerLeft x ) )  ) 
                     ( when ( llx >= ( xCoord ( lowerLeft allowedZone ) ) ) && 
                       ( urx <= ( xCoord ( upperRight allowedZone ) ) ) &&
                       ( lly >= ( yCoord ( lowerLeft allowedZone ) ) ) &&
                       ( ury <= ( yCoord ( upperRight allowedZone ) ) ) 
                       ( dbCreateRect cv layer x ) )
                     ) xyList )
    )
);;


(defun pckDrawRectFromList ( cv layer xyList )
  ( let ( figid ) 
    ( mapc ( lambda (x) 
             ( setq figid ( dbCreateRect cv layer x ) ) ) xyList )
    figid ; return
    );
 );

(defun pckShiftBBoxList ( xyList xShift yShift )
  (let (llx lly urx ury )
    ( mapcar ( 
              lambda ( x ) 
                     ( setq urx ( xCoord ( upperRight x ) ) + xShift )
                     ( setq ury ( yCoord ( upperRight x ) ) + yShift ) 
                     ( setq llx ( xCoord ( lowerLeft x ) ) + xShift )
                     ( setq lly ( yCoord ( lowerLeft x ) ) + yShift ) 
                     list( llx:lly urx:ury ) ) xyList )
    ); let
)

(defun pckReflectMYBBoxList ( xyList @optional ( axisX 0.0 ) ) 
  (let ( llx lly urx ury )
    ( mapcar  (
               lambda ( x )
                      ( setq urx 2 * axisX - ( xCoord ( upperRight x ) ) )
                      ( setq ury ( yCoord ( upperRight x ) ) ) 
                      ( setq llx 2 * axisX - ( xCoord ( lowerLeft x ) ) )
                      ( setq lly ( yCoord ( lowerLeft x ) ) ) 
                      list( ( min llx urx ):lly ( max llx urx):ury ) ) xyList )
    ); let
)

(defun pckReflectMXBBoxList ( xyList @optional ( axisY 0.0 ) ) 
  (let ( llx lly urx ury )
    ( mapcar  (
               lambda ( x )
                      ( setq urx ( xCoord ( upperRight x ) ) )
                      ( setq ury 2 * axisY - ( yCoord ( upperRight x ) ) ) 
                      ( setq llx ( xCoord ( lowerLeft x ) ) )
                      ( setq lly 2 * axisY - ( yCoord ( lowerLeft x ) ) ) 
                      list( llx:( min lly ury)  urx:( max lly ury ) ) ) xyList )
    ); let
)


(defun pckProcessInputFiles ( fn ) 
    (let (nextLine port)
      (setq port (infile fn))
      (when port
        (while (gets nextLine port )
          (unless (rexMatchp "^#" nextLine )
            ;; (println nextLine )
            (loadstring nextLine )))
        ) ;; when
      (close port )
      t
      );; let                      
    )

(defun pckNormalizeBBox ( bBox )
  (let ( x1 x2 y1 y2 )
    x1 = (car (car bBox ) )
    y1 = (cadr (car bBox ) )
    x2 = (car (cadr bBox ) )
    y2 = (cadr (cadr bBox ) )
    (list (min x1 x2):(min y1 y2) (max x1 x2):(max y1 y2) )
    );; let
  );;

(defun pckTransformBBoxList (  xyList shiftX shiftY orient)
  (mapcar
        (lambda ( bBox )
          (dbTransformBBox bBox list( shiftX:shiftY orient)) ) xyList )
  );;pckTransformBBoxList

(defun pckTransformBBoxListAsKernel ( kernel xyList )
    (mapcar
        (lambda ( bBox )
          (dbTransformBBox bBox list( kernel~>xy kernel~>orient )))  xyList )
    );; pckTransformBBoxListAsKernel

; *************************************************************************************
(defun pckKernelPropBBox ( kernel prop )
  (dbTransformBBox (get kernel~>master prop ) list( kernel~>xy kernel~>orient)))

;;
;; This redundant
(defun pckKernelPropBBoxAll ( kernel prop )
  (dbTransformBBox (get kernel~>master prop ) list( kernel~>xy kernel~>orient)))
;;
;;
;;
(defun pckComplimentaryTranf (bBox transf)
  "pckComplimentaryTransf takes a transformation in form of coord:orient and 
   converts the input bbox into coordinates as seen by coordinate system 
   under the transformation"
  (let ((x (caar transf)) (y (cadar transf)) orient rev_orient (ll (car bBox)) (ur (cadr bBox)))
    ;;(setq coord (car transf))
    (setq orient (cadr transf))
    (case orient
      ("R180"
       (setq rev_orient "R180")
       )
      ("R0"
       (setq rev_orient "R0")
       )
      ("R90"
       (setq rev_orient "R270")
       )
      ("R270"
       (setq rev_orient "R90")
       )
      ("MX"
       (setq rev_orient "MX")
       )
      ("MY"
       (setq rev_orient "MY")
       )
      (t
       (setq rev_orient "R0")
       )
      )
    (setq bBox (dbTransformBBox (dbTransformBBox bBox (list (list -x -y) "R0")) (list (list 0 0) rev_orient)))
    );; let
  )




; *************************************************************************************
; BBOX CENTER, DIMS, ETC.:

(defun trBBoxCenter ( bBox )
"Returns x:y of center coordinates of the given bBox. => l_list"
  (let ( llx lly urx ury )
     ury = yCoord( upperRight( bBox ))
     urx = xCoord( upperRight( bBox ))
     llx = xCoord( lowerLeft( bBox ))
     lly = yCoord( lowerLeft( bBox ))
;;   pckPutOnGrid((( urx + llx )/2)) : 
;;   pckPutOnGrid((( ury + lly )/2))
     ( urx + llx )/2 : ( ury + lly )/2

   ) ; let
) ; procedure

(defun trBBoxDims ( bBox )
"Returns x:y of distances LL to UR of the given bBox. => l_list"
let( ( llx lly urx ury )
     ury = yCoord( upperRight( bBox ))
     urx = xCoord( upperRight( bBox ))
     llx = xCoord( lowerLeft( bBox ))
     lly = yCoord( lowerLeft( bBox ))
     ( urx - llx ) : ( ury - lly )
     ) ; let
) ; procedure


(defun trPointLowerLeftp ( pt1 pt2 )
  ( let ( pt1x pt2x pt1y pt2y )
    ( setq pt1x ( xCoord pt1 ) )
    ( setq pt2x ( xCoord pt2 ) )
    ( cond
      ( pt1x < pt2x t )
      ( pt1x == pt2x
                ( setq pt1y ( yCoord pt1 ) )
                ( setq pt2y ( yCoord pt2 ) )
                pt1y < pt2y )
      ( t nil )
      ) ; cond
    ) ; let
  ) ; defun

(defun trPointUpperRightp ( pt1 pt2 )
  ( let ( pt1x pt2x pt1y pt2y )
    ( setq pt1x ( xCoord pt1 ) )
    ( setq pt2x ( xCoord pt2 ) )
    ( cond
      ( pt1x > pt2x t )
      ( pt1x == pt2x
                ( setq pt1y ( yCoord pt1 ) )
                ( setq pt2y ( yCoord pt2 ) )
                pt1y > pt2y )
      ( t nil )
      ) ; cond
    ) ; let
  ) ; defun

(defun trSortPointList ( aPointList @optional ( direction "lowerLeft") )
  (case direction
    ( "lowerLeft"
      ( sort aPointList 'trPointLowerLeftp )
      )
    ( "upperRight"
      (  sort aPointList 'trPointUpperRightp )
      )
    )
  ); defun

; *************************************************************************************
; FILTER INSTANCES BY NAME:
;;give a collection of instances
;;only returns instances that are
;;an instance of second arg, recognized
;;by a match between cellName of instance
;;and 2nd arg. If the 3rd arg is non-nil
;;returns items NOT matching 2nd arg.

(defun pckFilterByCellName (instances cn reverse)
"Give a collection of instances only returns instances that are an instance of second arg, recognized
by a match between cellName of instance and 2nd arg. 
If the 3rd arg is non-nil returns items NOT matching 2nd arg. => t_string"
  (let (matches non_matches)
    (foreach x instances
             (if (equal x~>master~>cellName cn)
                 (setq matches (cons x matches))
                 (setq non_matches (cons x non_matches))
                 ))
    (cond ((not reverse) matches)
          (t non_matches))))

;;Similar to above but works based on regex pattern match instead of
;;string equality (patterm match is on instance name)
(defun pckFilterByInstNamePattern (instances instNamePattern reverse)
"Give a collection of instances only returns instances that fare an instance of second arg, recognized
by a regex pattern match between cellName of instance and 2nd arg. 
If the 3rd arg is non-nil returns items NOT matching 2nd arg. => t_string"
  (let (matches non_matches)
    (foreach x instances
             (if (rexMatchp instNamePattern x~>name)
                 (setq matches (cons x matches))
                 (setq non_matches (cons x non_matches))
                 ))
    (cond ((not reverse) matches)
          (t non_matches))))

; *************************************************************************************
;;Returns the remainder of dividing floting-point number n1
;;by floating point number n2
;;similar to the predefined SKILL function remainder except
;;that this works for floats in addition to ints.

(defun pckRemainderF (n1 n2)
"Returns the remainder of dividing floating-point number n1 by floating point number n2
similar to the predefined SKILL function remainder except that this works for floats in addition to ints. => f_float"  
(difference n1 (times n2 (fix (quotient n1 n2)))))


; *************************************************************************************
; Returns true if pt in contained in the
; bounding-box bbox.

(defun pckContainedIn (bbox pt)
"Returns true if point is contained in the bounding-box bbox. => t/nil"
  (if (and (pckGEQP (car pt) (car (car bbox)))
           (pckGEQP (cadr pt) (cadr (car bbox)))
           (pckLEQP (car pt) (car (cadr bbox)))
           (pckLEQP (cadr pt) (cadr (cadr bbox))))
      t
      nil))

(defun pckFindBBoxInsideZone ( xyList bbox )
  ( let (outList )
    ( setq outList nil )
    ( foreach x xyList
              (if (and ( pckGEQP (car  ( car x  ) ) (car (car bbox)))
                       ( pckGEQP (cadr ( car x  ) ) (cadr (car bbox)))
                       ( pckLEQP (car  ( cadr x ) ) (car (cadr bbox)))
                       ( pckLEQP (cadr ( cadr x ) ) (cadr (cadr bbox)))) then
                ( setq outList ( cons x outList ) ) )

              )
    outList
    ); let
)

; *************************************************************************************
;Returns the bbox that represents the intersection
;of two bboxes that are given as a parameter
;if they intersect; returns null otherwise

(defun pckIntersectBbox (bboxA bboxB)
"Returns the bbox that represents the intersection of two bboxes that are given as a parameter
if they intersect; returns nil otherwise => l_list/nil" 
  (let (xs ys ax_lft ax_rgt bx_lft bx_rgt
       ay_bot ay_top by_bot by_top result)
    ;;(printf "Bboxes : %L & %L\n" bboxA bboxB)
    (setq ax_lft (xCoord (lowerLeft bboxA)))
    (setq ax_rgt (xCoord (upperRight bboxA)))
    (setq bx_lft (xCoord (lowerLeft bboxB)))
    (setq bx_rgt (xCoord (upperRight bboxB)))
    (setq ay_bot (yCoord (lowerLeft bboxA)))
    (setq ay_top (yCoord (upperRight bboxA)))
    (setq by_bot (yCoord (lowerLeft bboxB)))
    (setq by_top (yCoord (upperRight bboxB)))
    (setq xs (list (list "ax_lft" ax_lft)
          (list "ax_rgt" ax_rgt)
          (list "bx_lft" bx_lft)
          (list "bx_rgt" bx_rgt)))
    (setq ys (list (list "ay_bot" ay_bot)
          (list "ay_top" ay_top)
          (list "by_bot" by_bot)
          (list "by_top" by_top)))
    (setq xs (sort xs 'pckIntersectBboxSort))
    (setq ys (sort ys 'pckIntersectBboxSort))
    ;check if we have non-intersecting rectangles
    (cond ((and (equal (substring (car (nth 0 xs)) 1 2)
              (substring (car (nth 1 xs)) 1 2))
           (equal (substring (car (nth 2 xs)) 1 2)
              (substring (car (nth 3 xs)) 1 2)))
       (setq result nil))
      ((and (equal (substring (car (nth 0 ys)) 1 2)
              (substring (car (nth 1 ys)) 1 2))
           (equal (substring (car (nth 2 ys)) 1 2)
              (substring (car (nth 3 ys)) 1 2)))
       (setq result nil))
      (t (setq result (list (list (cadr (nth 1 xs)) (cadr (nth 1 ys))) 
           (list (cadr (nth 2 xs)) (cadr (nth 2 ys)))))))
    result))

; *************************************************************************************
;;Sort function used inside pckIntersectBbox.
;;*not* generally useful.
(defun pckIntersectBboxSort (a b)
  (leqp (cadr a) (cadr b)))

; *************************************************************************************
;;Shift a bbox by given dimensions in the x and y direction
;;parameters xShift and yShift are added to the coordinates
;;so to subtract be sure to call with the negative value.
;; e.g. to shift by 2 units in x and y towards the origin
;; use: (pckShiftBbox bBox (minus xShift) (minus yShift))

(defun pckShiftBbox (bBox xShift yShift)
"Shift a bbox by given dimensions in the x and y direction parameters xShift and yShift are added to the coordinates
so to subtract be sure to call with the negative value. e.g. to shift by 2 units in x and y towards the origin
use: (pckShiftBbox bBox (minus xShift) (minus yShift)) => l_list"
  (list (pckShiftPoint (car bBox) xShift yShift)
    (pckShiftPoint (cadr bBox) xShift yShift)))

(defun pckSkewBBoxY (bbox yb yt)
  "Skews given bbox in vertical direction - bottom by yb and top by yt
use: (pckSkewBBoxY bbox yb yt) => l_list
"
  (list (pckShiftPoint (car bbox) 0.0 yb)
        (pckShiftPoint (cadr bbox) 0.0 yt)
        )
  )
(defun pckSkewBBoxX (bbox xl xr)
  "Skews given bbox in horizontal direction - left edge by xl and right edge by xr
use: (pckSkewBBoxX bbox xl xr) => l_list
" 
  (list (pckShiftPoint (car bbox) xl 0.0)
        (pckShiftPoint (cadr bbox) xr 0.0)
        )
  )


; *************************************************************************************
;;Shift a point by given dimensions in the x and y direction
;;parameters xShift and yShift are added to the coordinates
;;so to subtract be sure to call with the negative value.
;; e.g. to shift by 2 units in x and y towards the origin
;; use: (pckShiftBbox bBox (minus xShift) (minus yShift))

(defun pckShiftPoint (pt xShift  yShift)
"Shift a point by given dimensions in the x and y direction parameters xShift and yShift are added to the coordinates
so to subtract be sure to call with the negative value. e.g. to shift by 2 units in x and y towards the origin
use: (pckShiftBbox bBox (minus xShift) (minus yShift)) => l_list"
  (list (plus (car pt) xShift)
    (plus (cadr pt) yShift)))

; *************************************************************************************
;;Goes through a list of structure instances and returns the 
;;value of the last aprMethod parameter that it finds.
;;######
;;ASSUMPTION: It is assumed that all the structres in the schematic are 
;;consistent with respect to busing methodology e.g. all structures that
;;need busing use the "rng" bus.
;;
;;
;; Changed 4/18/2005: We will ignore "none" if it is present
;;######
(defun pckGetAprMethod (structures)
"Goes through a list of structure instances and returns the value of the last aprMethod parameter that it finds.
** ASSUMPTION **: It is assumed that all the structures in the schematic are consistent with respect to busing 
methodology e.g. all structures that need busing use the \"rng\" bus. => t_string"
  (let ((retval "none"))
    (foreach s structures
         (foreach p (cdfGetInstCDF s)~>parameters
              (when (and (equal p~>name "aprMethod") (not (equal (lowerCase p~>value) "none")))
            (setq retval p~>value))))
    retval))



;; *************************************************************************************
;;Given a instanceId returns a DPL with the terminal name and center coords
;;for each of the terminals in the instance.
;;the getTerminalCoords function was obtained from Cadence sourcelink, hence
;;the adulterated syntax.
(defun pckGetTerminalCoords (instId)
"Given a instanceId returns a DPL with the terminal name and center coords for each of the terminals in the instance.
The getTerminalCoords function was obtained from Cadence sourcelink, hence the adulterated syntax. => l_list"
  let( (instTermbBox xa xb ya yb x1 y1 instTermList result_dpl actualList )
       (if instId~>objType == "inst"
       (progn
         (setq instTermList instId~>instTerms)
         (setq actualList nil)
         (foreach term instTermList
              (when (null term~>net) || term~>net~>instTermCount >= 1
                (setq actualList reverse(append( list(term) actualList)))))
         ;;initialize the dpl to be returned
         (setq result_dpl (list nil))
         (foreach ter actualList
              ;; need to get the origin for the instPins
              (setq instTermbBox (dbTransformBBox car(ter~>term~>pins~>fig~>bBox) 
                              instId~>transform))
              ;; calculate the center of instTerm
              xa = caar(instTermbBox)
              xb = caadr(instTermbBox)
              ya = cadar(instTermbBox)
              yb = cadadr(instTermbBox)
              x1 = (xa + xb)/2
              y1 = (ya + yb)/2
              result_dpl = append(result_dpl list(stringToSymbol(ter~>name)) )
              result_dpl = append(result_dpl list(x1:y1) )
              )         ;foreach
         result_dpl)
       (progn
         (error "You have not passed a valid instance to this procedure...")))))


;; *************************************************************************************
;;Draw a wire/net between given coords and optionally place a label on the wire/net.
;;The net is always routed (i.e. flight lines are not drawn). The wire xSpacing, ySpacing
;;and wireWidth are set to 0.01, 0.01 and 0 respectively.
;;
;;If labelOrient is not given it is assumed to be R90. If the labelSize is not given
;;the default is 10. If labelCoord is not given the label is place at the first coord
;;in wireEndPoints. The label is always aligned to loweLeft.
(defun pckDrawWire (cv wireEndPoints @optional label labelOrient labeSize labelCoord)
"Draw a wire/net between given coords and optionally place a label on the wire/net. The net is always routed 
(i.e. flight lines are not drawn). The wire xSpacing, ySpacing and wireWidth are set to 0.01, 0.01 and 0 respectively.
If labelOrient is not given it is assumed to be R90. If the labelSize is not given the default is 10. 
If labelCoord is not given the label is place at the first coord in wireEndPoints. The label is always aligned to loweLeft."
  (let ((WIRE_XSPACE 0.01)
    (WIRE_YSPACE 0.01)
    (WIRE_WIDTH 0)
    (LABEL_SIZE 10) 
    wireids)
    (setq wireids (schCreateWire cv "route" "full" 
                     (list (car wireEndPoints) (cadr wireEndPoints)) 
                     WIRE_XSPACE WIRE_YSPACE WIRE_WIDTH))
    (when label
      (unless labelOrient (setq labelOrient "R90"))
      (unless labeSize (setq labeSize LABEL_SIZE))
      (unless labelCoord (setq labelCoord (car wireEndPoints)))
      (schCreateWireLabel cv (car wireids) labelCoord label "lowerLeft" 
              labelOrient "stick" labeSize nil))
    wireids))


;; *************************************************************************************
;; Given an instance handle, set the CDF parameter with name paramName
;; to paramValue
(defun pckSetCdfInstId (instId paramName paramValue)
"Given an instance handle, set the CDF parameter with name paramName to paramValue."
  (let (cdfId cdfProp)
    (setq cdfId (cdfGetInstCDF instId))
    (setq cdfProp (car (setof item cdfId~>parameters (equal item~>name paramName))))
    (setSGq cdfProp paramValue value)))


;; *************************************************************************************
;; Given an instance handle get the CDF parameter value for the paramName parameter
(defun pckGetCdfInstValue (inst paramName)
"Given an instance handle get the CDF parameter value for the paramName parameter. => g_value"
  (let (retval)
    (foreach p (cdfGetInstCDF inst)~>parameters
         (when (equal p~>name paramName)
           (setq retval p~>value)))
    retval))


;; *************************************************************************************
;; Given a cellview and an instance handle, set the CDF parameter with name paramName
;; to paramValue
(defun pckSetCdfInstName (cv instName paramName paramValue)
"Given a cellview and an instance handle, set the CDF parameter with name paramName to paramValue."
  (pckSetCdfInstId (dbFindAnyInstByName cv instName) paramName paramValue))


;; *************************************************************************************
;; Given a library name purge virtual memory of open cellviews and property bags associated 
;; with that library
(procedure (pckPurgeLib libName)
"Given a library name purge virtual memory of open cellviews and property bags associated with that library. => t"
  /* close all the cellViews from this library name */
  (foreach cellView (dbGetOpenCellViews)
    (when (equal (dbGetq cellView libName) libName)
   (dbPurge cellView)))
  /* close any property bags associated with the library */
  (foreach bag (dbGetOpenBags)
   (dbPurgeBag bag))
  t)

;;************************************************************
;;
;; Clean exit. Saveall modified cellviews, close all views, bags, techfiles
;; Check whether display.drf has been tocuhed. Clean it up.
;; THEN - exit
(defun pckSessionExit ( @optional (batch "no") )
"Clean exit. Saveall modified cellviews, close all views, bags, techfiles. 
Check whether display.drf has been tocuhed. Clean it up.
THEN - exit!"
  (let (bag tf cv)
    ;;
    ;; Save all modified cellviews first.
    (foreach cv (dbGetOpenCellViews)
             (when (and
                    (dbIsCellViewModified cv)
                    ;; cell can appear modified, even if read only (why?)
                    (or (equal (dbGetq cv mode) "a") (equal (dbGetq cv mode) "w")))
               (dbSave cv ) )
             (when (dbIsId cv)
               (dbPurge cv) )
             )
    (foreach bag (dbGetOpenBags)
             (dbPurgeBag bag)
             )
    (foreach tf (techGetOpenTechFiles)
             (techPurgeTechFile tf)
             )
    (if (and (fboundp 'hiRegTimer) (fboundp 'hiFormCancel) (nequal batch "yes") )
        (regExitBefore 'pckSuppressDispForm) )
    (exit)
    )
  );;
(defun pckSuppressDispForm ()
  (hiRegTimer "hiFormCancel(techSaveDrmForm)" 10) 
  )


(defun pckCreatePin ( cv pinName layer layerPurpose bBox @optional (pinDirection "inputOutput") ) 
"Well, lets create a PIN object! => t"
  ( let (x y rectId netId width labelId)
     rectId = dbCreateRect( cv list( layer layerPurpose ) bBox )
     netId = dbCreateNet( cv pinName )
     dbCreateTerm( netId pinName pinDirection )
     dbCreatePin( netId rectId ) 
     x = car( trBBoxCenter( bBox ) )
     y = cadr( trBBoxCenter( bBox ) )
     labelId = dbCreateLabel( cv list("text" "drawing") x:y pinName "centerCenter" "R0" "swedish" 
                     cadr( trBBoxDims( bBox ) ) )

     (while pckFindBBoxInsideZone( list( labelId~>bBox ) bBox ) == nil
            labelId~>height =  labelId~>height - 0.01
            )
     t
    )
)

;; *************************************************************************************
;; Given a DPL return a list of the keys
(defun pckGetKeys (dpl)
"Given a DPL return a list of the keys. => l_list"
  (let (x (i 1))
    (while (and (lessp i (difference (length dpl) 1)) (greaterp (length dpl) 2))
      (setq x (cons (symbolToString (nth i dpl)) x))
      (setq i (plus i 2)))
    x))

;; Not quite sure what the heck the above does & not brave enough to
;; remove it. Here is a better function.
(defun pckGetDplKeys (dpl)
 "Here is a better function. Given a DPL return a list of the keys. => l_list"
 (pckGetDplKeys2 (cdr dpl)))
(defun pckGetDplKeys2 (dpl)
"Used by pckGetDplKeys function."
  (when dpl
    (cons (car dpl) (pckGetDplKeys2 (cddr dpl)))))


;; *************************************************************************************
;; Given a list turn into into a string with elements separated by tabs
(defun pckListToString (lst)
"Given a list turn into into a string with elements separated by tabs. 
But what about using buildString function already in coreskill? => t_string"
  (let ((ret ""))
    (mapcar (lambda (x) 
          (if (equal (strlen  ret) 0)
          (setq ret x)
        (setq ret (strcat ret " " x))))
        lst)
    ret))

(defun pckConvertListToInt (lst)
  "Given a list like ((\"1\" \"2\") nil (\"4\" \"9\")) convert it to proper list and drop any nil: ((1 2) (4 9))"
  (cond
    ((null (car lst))
     (if (equal (length lst) 0)
         (list)
         (pckConvertListToInt (cdr lst))
       ))
    ((listp (car lst))
     (cons (mapcar (lambda (y) (atoi y)) (car lst))
           (pckConvertListToInt (cdr lst))
           ))
    (t (pckConvertListToInt (cdr lst)))
    )
  );;

;;****h* TCC/StringProcessing
;;
;; NAME
;;
;; String Processing - collections of functions that perform string manipulations of weird variety.
;;
;; AUTHOR 
;; Bill Harris, Vincent Rayappa, Pavel Rott
;;       
;;****


;;****f* StringProcessing/pckFindSubstring
;;
;; NAME
;; 
;; pckFindSubstring
;;
;; DESCRIPTION
;;
;; Conveniently finds substring of a string based on start/end marker characters. Markers are NOT included into
;; the final substring
;;
;; USAGE
;;
;; pckFindSubstring "(1.0)" "(" ")"
;;
;;****


(defun pckFindSubstring ( word startChar endChar )
"Conveniently finds substring of a string based on start/end marker characters. Markers are NOT included into
the final substring. Example: pckFindSubstring \"(1.0)\" \"(\" \")\" => t_string"
  (let (x y )
    (setq x (nindex word startChar) + (strlen startChar))
    (setq y (nindex word endChar))
    (substring word x y-x)
    )
  )
;;****f* StringProcessing/pckReadUnixOutput
;;
;; NAME
;; 
;; pckReadUnixOutput
;;
;; DESCRIPTION
;;
;; Runs UNIX command and returns its output (sans \n). Command should be a simple one
;; to avoid blocking CIW.
;; Added timeout parameter to ReadProcess command; it was bombing otherwise
;;
;; USAGE
;;
;; pckReadUnixOutput "hostname"
;;
;;****

(defun pckReadUnixOutput ( cmd)
"Runs UNIX command and returns its output (sans \n). Command should be a simple one
to avoid blocking CIW. Added timeout parameter to ReadProcess command; it was bombing otherwise"
  (let (cid out)
    (setq cid (ipcBeginProcess cmd ))
    (setq out (ipcReadProcess cid 5) )
    (ipcKillProcess cid ) 
    (substring out 1 (sub1 (strlen out)))
    )
  )

;;****f* StringProcessing/pckGetResultsFromXMLOutput
;;
;; NAME
;; 
;; pckGetResultsFromXMLOutput
;;
;; DESCRIPTION
;;
;; Parses XML output and returns the value of a specified tag. Tag name is optional. 
;; Makes use of pckFindSubstring function but expands start/end markers to be XML tags. 
;; Returns t for "OK" value in XML, and nil for "failed".
;; Should not be used for obtaining values from "results" tag - those return more sofisticated XML-formatted data
;;
;; USAGE
;;
;; (pckGetResultsFromXMLOutput output "message")
;;
;;****
(defun pckGetResultsFromXMLOutput (result @optional (tag "status"))
"Parses XML output and returns the value of a specified tag. Tag name is optional. 
Makes use of pckFindSubstring function but expands start/end markers to be XML tags. 
Returns t for \"OK\" value in XML, and nil for \"failed\".
Should not be used for obtaining values from \"results\" tag - those return more sofisticated XML-formatted data => t/nil"
    (if (equal (pckFindSubstring result (strcat "<" tag ">") (strcat "</" tag ">")) "OK") t nil)
    )


       
;; *************************************************************************************
;; This is useful for creating dummy skill functions that are needed for making SKILL++
;; code that is inside a  closure compatible with and available to SKILL code.
;; For example the macro call :
;;       (pckCreateDummySkillFn fn1 p1 p2 p3)
;; gets compiled into this SKILL function : 
;; defun(fn1 
;;     (p1 p2 p3) 
;;     list(p1 p2 p3) nil
;; )
;;
(defmacro pckCreateDummySkillFn (fn @rest args)
  `(defun ,fn (,@args)
     (list ,@args)
     nil))

;;*************************************************************************************
;; Get pad Pcell name. Wrap around for SKILL++ access.
;;
(defun pckGetPadPCName ()
"Get pad Pcell name. Wrap around for SKILL++ access. => TCC_PAD_PC_NAME"
  TCC_PAD_PC_NAME)


;;*************************************************************************************
;; Get Aux Lib name name. Wrap around for SKILL++ access.
;;
(defun pckAuxLibName ()
"Get Aux Library name. Wrap around for SKILL++ access. => AUX_LIB"
  AUX_LIB)



;;*************************************************************************************
;; Get the base cell CDF value for a certain CDF parameter
;;
(defun pckGetCdfBaseValue (lib cell paramname @optional retrunOnFail)
"Get the base cell CDF value for a certain CDF parameter. => g_value"
  (let (param)
    (setq param (car (setof p (cdfGetBaseCellCDF (ddGetObj lib cell))~>parameters 
               (equal p~>name paramname))))
    (if param
    param~>value
    retrunOnFail)))

;;*************************************************************************************
;; Get the upperLeft and lowerRight of a bBox
;;
(defmacro pckUpperLeft (bbox)
  `(range (car (car ,bbox)) (cadr (cadr ,bbox))))

(defmacro pckLowerRight (bbox)
  `(range (car (cadr ,bbox)) (cadr (car ,bbox))))

;;*************************************************************************************
;; Change the given bbox in x and y directions according to given dim
;; +ve x and y grows the bbox and -ve x and y shrinks the bbox
(defun pckTransformBbox (bbox x y)
"Change the given bbox in x and y directions according to given dim. 
+ve x and y grows the bbox and -ve x and y shrinks the bbox. => l_list"
  (list (list (difference (xCoord (lowerLeft bbox)) 
            x)
          (difference (yCoord (lowerLeft bbox)) 
            y))
    (list (plus (xCoord (upperRight bbox)) 
            x)
          (plus (yCoord (upperRight bbox)) 
            y))))
    
    
;;******************************************************************************
;  Returns list of exclusion Bboxs from enclosing Bbox and inclusion Bboxs
;  Inclusion Bboxs should be contained within a list 
;  New exclusion Bboxs are given back via alst variable in a list format

(defun pckComplementBbox (bboxA bboxlst)
"Returns list of exclusion Bboxs from enclosing Bbox and inclusion Bboxs. 
Inclusion Bboxs should be contained within a list. 
New exclusion Bboxs are given back via alst variable in a list format. => l_list"
   (let (temx1 temx2 temy1 temy2 refx1 refx2 refy1 refy2 x b b2 temlst
         temlst2 temlst3 temlst4 temlst5 plst x2 tem alst )
   (setq refx1 (car (car bboxA)) )
   (setq refx2 (car (cadr bboxA)) )
   (setq refy1 (cadr (car bboxA)) )
   (setq refy2 (cadr (cadr bboxA)) )
   (setq b 0 )
   if( bboxlst == nil then
     (setq alst bboxA )
   else
   ;; Partition along x direction
   ( foreach x bboxlst
     (setq temx1 (car (car x)) )
     (setq temx2 (car (cadr x)) )
     (setq temy1 (cadr (car x)) )
     (setq temy2 (cadr (cadr x)) )
     b = b + 1 
     if( b == 1
      then
      (setq temlst (list (list (list refx1 refy1) (list temx1 refy2))))
      (setq temlst2 (list (list (list temx1 refy1) (list temx2 refy2))))
      (setq temlst append( temlst temlst2))
      (setq temlst2 (list (list (list temx2 refy1) (list refx2 refy2))))
      (setq temlst append( temlst temlst2))
      ;(setq temlst2 nil )
      else
       (setq b2 0 )
       ( foreach x2 temlst
         (setq refx1 (car (car x2)) )
         (setq refx2 (car (cadr x2)) )
         (setq refy1 (cadr (car x2)) )
         (setq refy2 (cadr (cadr x2)) )
      b2 = b2 + 1
     ( cond
       ( temx1 > refx1 && temx1 < refx2
         if( temx2 >= refx2
         then
           (setq temlst3 (list (list (list refx1 refy1) (list temx1 refy2))))
           (setq temlst4 (list (list (list temx1 refy1) (list refx2 refy2))))
            if( b2 == 1
             then
              (setq temlst2 temlst3)
              (setq temlst2 append( temlst2 temlst4))
             else
              (setq temlst2 append( temlst2 temlst3))
              (setq temlst2 append( temlst2 temlst4))
            )
          else
           (setq temlst3 (list (list (list refx1 refy1) (list temx1 refy2))))
           (setq temlst4 (list (list (list temx1 refy1) (list temx2 refy2))))
           (setq temlst5 (list (list (list temx2 refy1) (list refx2 refy2))))
           (setq temlst2 append( temlst2 temlst3))
           (setq temlst2 append( temlst2 temlst4))
           (setq temlst2 append( temlst2 temlst5))
          ) 
       )
       ( temx2 > refx1 && temx2 < refx2
         (setq temlst3 (list (list (list refx1 refy1) (list temx2 refy2))))
         (setq temlst4 (list (list (list temx2 refy1) (list refx2 refy2))))
         if( b2 == 1
          then
            (setq temlst2 temlst3)
            (setq temlst2 append( temlst2 temlst4))
          else
           (setq temlst2 append( temlst2 temlst3))
           (setq temlst2 append( temlst2 temlst4))
          )
       )
       ( b2 == 1
         (setq temlst2 (list (list (list refx1 refy1) (list refx2 refy2))))
       )
       ( b2 > 1
         (setq temlst2 append( temlst2 (list (list (list refx1 refy1) (list refx2 refy2)))))
       ) 
     ) ; cond
        ) ; foreach
       (setq temlst temlst2)
       ) ; if
    ) ; foreach
    
   declare(plst[length(temlst)] )
   
   for( x 0 length(temlst)-1
     plst[x] = 1
   )
   (setq tem 0 )
   ( foreach x temlst
     (setq refx1 (car (car x)) )
     (setq refx2 (car (cadr x)) )
     ( foreach x2 bboxlst
       (setq temx1 (car (car x2)) )
       (setq temx2 (car (cadr x2)) )
       ( cond
         ( temx1 <= refx1 && temx2 >= refx2
     plst[tem] = 0
     )
       )
     )
   tem = tem + 1
   )
   tem = 0
   (setq alst nil)
   (setq temlst2 nil)
   ( foreach x temlst
       (setq refx1 (car (car x)) )
       (setq refx2 (car (cadr x)) )
       (setq refy1 (cadr (car x)) )
       (setq refy2 (cadr (cadr x)) )
     if( plst[tem] == 1
      then
        (setq alst append( alst (list (list (list refx1 refy1) (list refx2 refy2)))))
      else
        (setq temlst2 append( temlst2 (list (list (list refx1 refy1) (list refx2 refy2)))))
     )
   tem = tem + 1
   )
   (setq temlst temlst2)
   
   ;; Partition along y direction
      
   ( foreach x bboxlst
     (setq temx1 (car (car x)) )
     (setq temx2 (car (cadr x)) )
     (setq temy1 (cadr (car x)) )
     (setq temy2 (cadr (cadr x)) )
       (setq temlst2 nil)
       ( foreach x2 temlst
         (setq refx1 (car (car x2)) )
         (setq refx2 (car (cadr x2)) )
         (setq refy1 (cadr (car x2)) )
         (setq refy2 (cadr (cadr x2)) )
         ( cond 
       ( temx1 <= refx1 && temx2 >= refx2 && temy1 > refy1 && temy2 < refy2
         (setq temlst3 (list (list (list refx1 refy1) (list refx2 temy1))))
         (setq temlst4 (list (list (list refx1 temy1) (list refx2 temy2))))
         (setq temlst5 (list (list (list refx1 temy2) (list refx2 refy2))))
         (setq temlst2 append( temlst2 temlst3))
         (setq temlst2 append( temlst2 temlst4))
         (setq temlst2 append( temlst2 temlst5))
       )
       ( temx1 <= refx1 && temx2 >= refx2 && temy1 == refy1 && temy2 < refy2
         (setq temlst3 (list (list (list refx1 refy1) (list refx2 temy2))))
         (setq temlst4 (list (list (list refx1 temy2) (list refx2 refy2))))
         (setq temlst2 append( temlst2 temlst3))
         (setq temlst2 append( temlst2 temlst4))
       )
       ( temx1 <= refx1 && temx2 >= refx2 && temy1 > refy1 && temy2 == refy2
         (setq temlst3 (list (list (list refx1 refy1) (list refx2 temy1))))
         (setq temlst4 (list (list (list refx1 temy1) (list refx2 temy2))))
         (setq temlst2 append( temlst2 temlst3))
         (setq temlst2 append( temlst2 temlst4))
       )
       ( t (setq temlst2 append( temlst2 (list (list (list refx1 refy1) (list refx2 refy2))))) )
     )  
    )
     (setq temlst temlst2)  
   )
   ;;  Sorting the complementary rectangles
   declare(plst[length(temlst)] )
   
   for( x 0 length(temlst)-1
     plst[x] = 1
   )
   (setq tem 0 )
   ( foreach x temlst
     (setq refx1 (car (car x)) )
     (setq refx2 (car (cadr x)) )
     (setq refy1 (cadr (car x)) )
     (setq refy2 (cadr (cadr x)) )
     ( foreach x2 bboxlst
       (setq temx1 (car (car x2)) )
       (setq temx2 (car (cadr x2)) )
       (setq temy1 (cadr (car x2)) )
       (setq temy2 (cadr (cadr x2)) )
       ( cond
         ( temx1 <= refx1 && temx2 >= refx2 && temy1 == refy1 && temy2 == refy2
     plst[tem] = 0
     )
       )
     )
   tem = tem + 1
   )
   tem = 0
   ( foreach x temlst
       (setq refx1 (car (car x)) )
       (setq refx2 (car (cadr x)) )
       (setq refy1 (cadr (car x)) )
       (setq refy2 (cadr (cadr x)) )
     if( plst[tem] == 1
      then
        (setq alst append( alst (list (list (list refx1 refy1) (list refx2 refy2)))))
      
      )
   tem = tem + 1
   )
   )
   alst  ; List of complementary rectangle Bboxs
   ) ; let
)

;; Flatten a list with embedded sublists            
(defun pckFlattenList (numberList) 
"Flatten the embedded sublists in a list up to the top level. => l_list"
  (mapcan 
   (lambda (element) 
     (if 
      (listp element) 
      (pckFlattenList (copy element)) 
      (ncons element))) 
   numberList))

;; Flatten a list with embedded sublists and retain nil         
(defun pckFlattenListNil (numberList) 
"Flatten the embedded sublists in a list up to the top level and retains nil elements. => l_list"
  (mapcan 
   (lambda (element) 
     (if 
      (and (listp element) (nequal element nil))
      (pckFlattenList (copy element)) 
      (ncons element)))
   numberList))


;;Check if a certain cellview is unmanaged
(defun pckUnmanagedP (lib cell view)
"Check if a certain cellview is unmanaged. => t/nil"
  (pckDSStateP lib cell view "gdmStateNone"))

;;Check if a certain cellview is checked-in
(defun pckCheckedinP (lib cell view)
"Check if a certain cellview is checked-in. => t/nil"
  (pckDSStateP lib cell view "gdmStateCI"))

(defun pckDSStateP (lib cell view state)
  (nindex (caar (gdmstatus 
        (gdmCreateSpec lib cell view (pckDSCdbName view) "LibraryUnix")
        6))
     state))

(defun pckDSCdbName (view)
  (cond ((equal view "layout")
     "layout.cdb")
    ((equal view "schematic")
     "sch.cdb")
    (t view)))

;; Get FTP host
(defun pckGetFtpHost ()
"Get FTP host. => t_string"
  (get TCC_FTP_HOST (getShellEnvVar "PROJECT")))
  
/*
;; Given number i , gives value Mi, can add if necessary with @optional
(defun matchvar (i M1 M2 M3 M4 M5 M6 M7 M8 )
"Given number i , gives value Mi, can add if necessary with @optional"
 (let ( mwidth)
   (cond
       ( i == 1
      mwidth = M1
       )
       ( i == 2
         mwidth = M2
       )
       ( i == 3
         mwidth = M3 
       )
       ( i == 4
         mwidth = M4 
       )
       ( i == 5
         mwidth = M5
       )
       ( i == 6
         mwidth = M6
       )
       ( i == 7
         mwidth = M7 
       )
       ( i == 8
         mwidth = M8 
       )
      )
   mwidth
  ); Let
) ; EOF  
*/  

;; derive unique elements from a list based on the pckMember function.
(defun pckUnique (lst compFn @optional (unique nil))
"Derive unique elements from a list based on the pckMember function."
  (if (null lst)
      unique
    (if (not (pckMember (car lst) unique compFn))
    (pckUnique (cdr lst) compFn (cons (car lst) unique))
      (pckUnique (cdr lst) compFn unique))))

;; variation of the SKILL member function, but possible to
;; change comparator function via last parameter
(defun pckMember (ele lst @optional (fn 'equal))
"Variation of the SKILL member function, but possible to
change comparator function via last parameter."
  (let (member)
    (foreach e lst
         (unless member
           (setq member (funcall fn ele e))))
    member))

;; check if two points are the same within a certain tolerance
(defun pckPointEqual (pt1 pt2)
"Check if two points are the same within a certain tolerance. => t/nil"
  (and (pckEQP (xCoord pt1) (xCoord pt2))
       (pckEQP (yCoord pt1) (yCoord pt2))))

;; check if two bboxes are the same within a certain tolerance
(defun pckBboxEqual (bbox1 bbox2)
"Check if two bboxes are the same within a certain tolerance. => t/nil" 
  (and (pckPointEqual (lowerLeft bbox1) (lowerLeft bbox2))
       (pckPointEqual (upperRight bbox1) (upperRight bbox2))))

;; Take a list of even numbered elements and build a list which is made of
;; two-elemement sublists. The sublists contain elements which where adjacent 
;; in the original list. For example, turn (1 2 3 4) into ((1 2) (3 4))
(defun pckBuildSublist (lst)
"Take a list of even numbered elements and build a list which is made of
two-elemement sublists. The sublists contain elements which where adjacent 
in the original list. For example, turn (1 2 3 4) into ((1 2) (3 4)) => l_list"
  (if (null (cddr lst))
    (cons (list (car lst) (cadr lst)) nil)
    (cons (list (car lst) (cadr lst)) (pckBuildSublist (cddr lst)))))

;; The prefix that is used for naming test structure instances
(defun pckGetStructNamePrefix ()
"The prefix that is used for naming test structure instances. => inst"
  "inst")

;;****f* pckFunctions/pckGetpckUtilsDir
;;
;; FUNCTION
;;
;; Return the value of the TCC_UTILS SKILL gloabal var for use in 
;; SKILL++ mode.
;;
;; USAGE
;;
;; (pckGetpckUtilsDir)
;;****
(defun pckGetpckUtilsDir ()
"Return the path defined by the TCC_UTILS SKILL gloabal var for use in 
SKILL++ mode. => t_string"
  TCC_UTILS)


;;****f* pckFunctions/pckGetSimpleBusTypes
;;
;; FUNCTION
;;
;; Return a list of simple bus-types.
;;
;; USAGE
;;
;; (pckGetSimpleBusTypes)
;;
;; RETURNS
;;
;; A list of simple-bus types. Simple is defined as every
;; thing other than partial-ring.
;;
;;****
(defun pckGetSimpleBusTypes ()
"A list of simple-bus types. Simple is defined as everything other than partial-ring. => l_list"
  (list "rng" "rng16" "rng1" "em"))


;;****f* pckFunctions/pckVerticesToEdges
;;
;; FUNCTION
;; 
;; Convert a list of vertices into a set of corresponding
;; lines (edges).
;;
;; USAGE
;;
;; (pckVerticesToEdges listofVertices)
;;  
;;
;; RETURNS
;;
;; A list of lines corresponding to the vertices.
;;****
(defun pckVerticesToEdges (vertices)
"Convert a list of vertices into a set of corresponding lines (edges). => l_list"
  (cond ((lessp (length vertices) 2)
         (error "Cannot call pckPolygonToEdges with just 1 coordinate."))
        ((equal (length vertices) 2)
         (cons (list (car vertices) (cadr vertices))
               nil))
        (t
         (cons (list (car vertices) (cadr vertices)) 
               (pckVerticesToEdges (cdr vertices))))))


;;****f* pckFunctions/pckPolyRectToEdges
;;
;; FUNCTION
;; 
;; Get lines that describe the perimeter of a rectangle
;; or polygon object.
;;
;; USAGE
;;
;; (pckPolyRectToEdges rectOrPolygonObj)
;;  
;;
;; RETURNS
;;
;; A list of lines corresponding to the object's perimeter.
;;****
(defun pckPolyRectToEdges (obj)
"Get lines that describe the perimeter of a rectangle or polygon object. => l_list"
  (if (equal obj~>objType "rect")
      (let ((bbox obj~>bBox))
        (printf "BBox = %L\n" bbox)
        (pckBBoxToEdges bbox))
      (pckVerticesToEdges obj~>points)))


;;****f* pckFunctions/pckBBoxToEdges
;;
;; FUNCTION
;; 
;; Get lines that describe the perimeter of a bbox
;;
;; USAGE
;;
;; (pckBBoxToEdges bbox)
;;  
;;
;; RETURNS
;;
;; A list of lines corresponding to the bbox's perimeter.
;;****
(defun pckBBoxToEdges (bbox)
"Get lines that describe the perimeter of a bbox. => l_list"
  (pckVerticesToEdges (list (lowerLeft bbox)
                            (range (rightEdge bbox) (bottomEdge bbox))
                            (upperRight bbox)
                            (range (leftEdge bbox) (topEdge bbox))
                            (lowerLeft bbox))))


;;****f* pckFunctions/pckLineContainedInLinesP
;;
;; FUNCTION
;; 
;; Check if an edge is contained in atleast one edge in
;; a list of edges. Coincident edges are considered to be
;; contained.
;;
;; USAGE
;;
;; (pckLineContainedInLinesP edge1 edgeLst)
;;  
;; RETURNS
;;
;; t if edge1 is contained in one of the edges in edgeLst
;;****
;; 
(defun pckLineContainedInLinesP (edge1 edgeLst)
"Check if an edge is contained in atleast one edge in a list of edges. 
Coincident edges are considered to be contained. => t/nil"
  (apply 'or (mapcar (lambda  (x)
                       (pckLineContainedInLineP edge1 x))
                     edgeLst)))


;;****f* pckFunctions/pckLineContainedInLineP
;;
;; FUNCTION
;; 
;; Check if line edge1 is completely contained in edge.
;; Returns nil if both edge1 and edge2 aren't orthognal.
;; USAGE
;;
;; (pckLineContainedInLinesP edge1 edgeLst)
;;  
;; RETURNS
;;
;; t if edge1 is contained in one of the edges in edgeLst
;;****
;; 
(defun pckLineContainedInLineP (edge1 edge2)
"Check if line edge1 is completely contained in edge.
Returns nil if both edge1 and edge2 aren't orthognal. => t/nil"
  (let (edge1endpts edge2endpts)
    ;; check if edge is verical or horizontal and them proceed
    (cond ((and (pckIsVerticalP edge1)
                (pckIsVerticalP edge2)
                (pckEQP (xCoord (car edge1)) (xCoord (cadr edge2))))
           ;;check if edge1 is completely within edge2 based on ycoords
           (setq edge1endpts (sort (mapcar 'cadr edge1) 'lessp))
           (setq edge2endpts (sort (mapcar 'cadr edge2) 'lessp)))
          ((and (pckIsHorizontalP edge1)
               (pckIsHorizontalP edge2)
               (pckEQP (yCoord (car edge1)) (yCoord (cadr edge2))))
           ;;check if edge1 is completely within edge2 based on xcoords
           (setq edge1endpts (sort (mapcar 'car edge1) 'lessp))
           (setq edge2endpts (sort (mapcar 'car edge2) 'lessp))))
    (and (not (null edge1endpts))
         (not (null edge2endpts))
         (pckGEQP (car edge1endpts) (car edge2endpts))
         (pckLEQP (cadr edge1endpts) (cadr edge2endpts)))))


;;****f* pckFunctions/pckIsVerticalP
;;
;; FUNCTION
;; 
;; Check if line is vertical line
;;
;; (pckIsVerticalP line)
;;  
;; RETURNS
;;
;; t if line is vertical, nil if not.
;;****
;; 
(defun pckIsVerticalP (line)
"Check if line is vertical line. => t/nil"
  (pckEQP (xCoord (car line))
          (xCoord (cadr line))))

;;****f* pckFunctions/pckIsHorizontalP
;;
;; FUNCTION
;; 
;; Check if line is veritcal line
;;
;; (pckIsHorizontalP line)
;;  
;; RETURNS
;;
;; t if line is horizontal, nil if not.
;;****
;; 
(defun pckIsHorizontalP (line)
"Check if line is horizontal line. => t/nil"
  (pckEQP (yCoord (car line))
          (yCoord (cadr line))))                  


;;****f* pckFunctions/pckWithStdoutToFile
;;
;; FUNCTION
;; 
;; Send stdout to file instead of CIW. Credit to jimka
;; on comp.cad.cadence
;;
;; 
;;  (withStdoutToFile "/tmp/myfile" 
;;   (your code)
;;   (your code) ...) 
;;  
;; RETURNS
;; 
;; Return value of enclosed code
;;****
;; 
(defmacro pckWithStdoutToFile (t_file @rest body)
  (let ((retval (gensym)))
    `(let (,retval
           (poport (outfile ,t_file "w"))
           (stdout (outfile ,t_file "w"))) 
       (unless stdout 
         (error "cannot write to %L" ,t_file)) 
       (setq ,retval (progn ,@body)) 
       (close poport)
       (close stdout)
       ,retval))) 

;;****f* pckFunctions/pckHashString1
;;
;; FUNCTION
;; 
;; Create a hash value for a string based on
;; the djb2 algorithm
;;
;; Based on http://www.cse.yorku.ca/~oz/hash.html
;;
;; RETURNS
;; 
;; +ve or -ve integer hash value
;;****
;; 
(defun pckHashString1 (s)
"Create a hash value for a string based on the djb2 algorithm
Based on http://www.cse.yorku.ca/~oz/hash.html. => x_integer"
  (let ((hash 5381) c)
    (for i 1 (strlen s)
         (setq c (charToInt (getchar s i)))
         (setq hash (plus (leftshift hash 5)
                          hash
                          c)))
    hash))

;;****f* pckFunctions/pckHashString2
;;
;; FUNCTION
;; 
;; Create a hash value for a string based on
;; the sdbm algorithm
;;
;; Based on http://www.cse.yorku.ca/~oz/hash.html
;;
;; RETURNS
;; 
;; +ve or -ve integer hash value
;;****
;; 
(defun pckHashString2 (s)
"Create a hash value for a string based on the sdbm algorithm
Based on http://www.cse.yorku.ca/~oz/hash.html. => x_integer"

  (let ((hash 0) c)
    (for i 1 (strlen s)
         (setq c (charToInt (getchar s i)))
         (setq hash (plus c 
                          (leftshift hash 6)
                          (leftshift hash 16)
                          (minus hash))))
    hash))


;;***f* pckFunctions/pckFindFile
;;
;; FUNCTION
;; 
;; Finds a file in a given directory by searching subfolders.
;; Returns relative paths to the files from the starting folder.
;;
;; USAGE
;;
;; (pckFindFile name start_dir)
;;  
;;
;; RETURNS
;;
;; A list of strings. Each string is a path to the file relative to the starting directory.
;;
;; USAGE
;;
;; (pckFindFile "pif_loader.il" (strcat TCC_UTILS "/1268/pCells"))
;;
;;****
(defun pckFindFile (name start_dir)
"Finds a file in a given directory by searching subfolders.
Returns list of relative paths to the files from the starting folder. => l_list"
  (let (fname sub_dir path_to_dir (fname_list nil))
    (setq fname (car (setof x (getDirFiles start_dir) (equal x name))))
    (when fname 
      (pckInfo "pckFindFile" (sprintf nil "File %s is found in the following subfolders of %s" name start_dir))
      (setq fname_list (cons (buildString (list start_dir fname) "/") fname_list))
      )
    
    (foreach sub_dir (setof x (getDirFiles start_dir) 
                            (and 
                             (not (member x (list "." ".." ".SYNC")))
                             (isDir (buildString (list start_dir x) "/"))))
             (setq path_to_dir ( buildString list( start_dir sub_dir ) "/" ))
             (let (alist)
               (setq alist (pckFindFile name path_to_dir))
               (when alist 
                 (setq fname_list (append fname_list alist)))))
    fname_list
    )
  );; pckFindFile
(defun pckFindAbsolutePathToPIF (fn)
  "Function retunrs absolute path for a given PIF file name. If PIF is absolte, it is returned unchanged, otherwise directories in SKILL search path are searched in their order of apperance. TCC sub-prime projects should work with this function."
  (let ((skillPath (getSkillPath)) sub_dir path)
	(if (equal "/" 
			   (get_pname (getchar fn 1)))
		(progn
		  ;; PIF is an absolute path, return it
		  (setq path fn)
		  )
		(progn
		  ;; relative path is given - need to find the actual file
		  ;;
		  (foreach dir (getSkillPath)
				   (when (isFile (strcat dir "/" fn))
					 (setq path (strcat dir "/" fn)))
				   )
		  )
		)
	path
	)
  )

;;***f* pckFunctions/pckListSubstring
;;
;; FUNCTION
;; 
;; Takes a list of paths (strings) and returns a list of relative paths, e.g.
;; '("/a/b/c/d") will be returned as '("/c/d") if start_dir is "/a/b"
;;
;; USAGE
;;
;; (pckListSubstring bb (strcat TCC_UTILS "/1268/pCells")) 
;;
(defun pckListSubstring (init_list init_string)
"Takes a list of paths (strings) and returns a list of relative paths, e.g.
'(\"/a/b/c/d\") will be returned as '(\"/c/d\") if start_dir is \"/a/b\" => l_list"
  (mapcar (lambda (x) (substring x (add1 (strlen init_string)) (strlen x))) init_list)
  )
;;***f* pckFunctions/pckRelatveDirPath
;;
;; FUNCTION
;; 
;; Takes a list of file paths and returns a list of corrsponding directories, i.e.
;; '("/a/b/c/d") will be returned as '("/a/b/c")
;;
;; USAGE
;;
;; (pckRelativeDirPath (pckListSubstring bb (strcat TCC_UTILS "/1268/pCells")))
(defun pckRelativeDirPath (init_list)
"Takes a list of file paths and returns a list of corrsponding directories, i.e.
'(\"/a/b/c/d\") will be returned as '(\"/a/b/c\") => l_list"
  (mapcar (lambda (x) (substring x 1 (difference (strlen x) (strlen (rindex x "/"))))) init_list))

;;***f* pckFunctions/pckGetLibs
;;
;; FUNCTION
;; 
;; Returns a list of library names or ddObjs based on a seach string, exclude string and
;; string/ddObj switch
;;
;; USAGE
;;
;; (pckGetLibs "x8b" "scratch") -> list of library names with "x6b" exclusive of scratch libs
(defun pckGetLibs (@optional (libPart "") (libExclude "") (returnString t))
"Returns a list of library names or ddObjs based on a seach string, exclude string and string/ddObj switch. => l_list"
  (let (libList)
    (foreach elem (ddGetLibList)
             (when (and
                    (index elem~>name libPart)
                    (not (index elem~>name libExclude)))
               (if returnString
                   (setq libList (cons elem~>name libList))
                   (setq libList (cons elem libList)))))
    libList))

;;****f* DesignRules/pckASLayerInfo
;;
;; FUNCTION
;;
;; pckASLayerInfo - returns poly region specific value for a spacing rule.
;; Requires poly region, library name (may use corresponding global variable)
;; rule name (minWidth, maxWidth, etc) and layer name. LayerPurpose parameter is optional.
;;
;; USAGE
;;
;;(pckLayerInfo "TG" MOS_LIB "minWidth" "metal1")
;;****
(defun pckASLayerInfo (Region LIBname Rule Layer)
"Returns poly region specific value for a spacing rule.
Requires poly region, library name (may use corresponding global variable)
rule name (minWidth, maxWidth, etc) and layer name. LayerPurpose parameter is optional. => f_float/nil"
(pckLayerInfo nil
              (if
               (member Region (list "logic" "digital"))
               Rule (strcat Rule Region)) Layer))

;;****f* DesignRules/pck2LayerInfo
;;
;; FUNCTION
;;
;; pck2LayerInfo - returns poly region specific value for a 2 layer spacing rule.
;; Requires poly region, library name (may use corresponding global variable)
;; rule name (minWidth, maxWidth, etc) and layer names. LayerPurpose parameters are optional.
;;
;; USAGE
;;
;;(pck2LayerInfo "TG" MOS_LIB "minEnclosure" "metal1" "via1" )
;;****
(defun pck2ASLayerInfo (Region LIBname Rule Layer1 Layer2)
"Returns poly region specific value for a 2 layer spacing rule.
Requires poly region, library name (may use corresponding global variable)
rule name (minWidth, maxWidth, etc) and layer names. LayerPurpose parameters are optional. => f_float/nil"
(pck2LayerInfo nil (if (member Region (list "logic" "digital")) Rule (strcat Rule Region)) Layer1 Layer2))

;;****f* DesignRules/pck2LayerInfo
;;
;; FUNCTION
;;
;; pckASGetPolyGrid - returns poly grid for a given poly region
;;
;;(pckASGetPolyGrid "TG")
;;****
(defun pckASGetPolyGrid (Region)
"Returns poly grid for a given poly region. => f_float/nil"
  (pckGetPolyGrid nil Region))

;;**********************************************************************
;; GET GRID, SNAP TO GRID:
;;
(defun pckGetPolyGrid ( @optional (cvId MOS_LIB) (Region "digital") ) 
"Returns poly grid for a given poly region. Default region is \"digital\" => f_float"
  (pckASLayerInfo Region cvId "minPitchX" "poly")
); pckGetGridpckLowerMetalsList

(defun pckGetPolyOffset ( @optional cvId ) 
"Returns value of TR_POLY_OFFSET from PROCESS_PARAMS DPL. => f_float"
  (unless cvId 
    cvId = MOS_LIB
    )
  (pckGetProcessInfo "TR_POLY_OFFSET")
  );; pckGetGrid

(defun pckPcCellViewParamDPL (cv)
"Puts parameter names and values from pcCellView into a DPL => l_dpl"
(let (dpl)
  (setq dpl (list nil))
  (foreach elem  (getSGq (getSGq cv parameters) value) 
           (if (floatp (getSGq elem value))
             (putprop dpl (pckPutOnGrid (getSGq elem value) (pckGetGrid)) (getSGq elem name))
             (putprop dpl (getSGq elem value) (getSGq elem name))))
  (copy dpl)))

(defun pckPcCellViewParamList (cv)
"Parameter list from pcCellView for input to dbCreateParamInst => l_list"
(mapcar
 (lambda (x)
   (if (floatp (getSGq x value)) 
     (list (getSGq x name) (getSGq x valueType) (pckPutOnGrid (getSGq x value) (pckGetGrid)))
     (list (getSGq x name) (getSGq x valueType) (getSGq x value))))
 (getSGq (getSGq cv parameters) value)))

;;;;
;;;; getSG - setSGq without quoting
(defun pckSG (d_object St_AttrOrPropName)
  "Same as getSGq without quoting the attribute name => g_value"
  (eval (list (quote getSGq) d_object (stringToSymbol St_AttrOrPropName))))

;;
;;pckListMin
;;  Returns the minimum value in a list
(defun pckListMin (numList)
  (let ()
    (setq numList (pckFlattenList (list numList)))
    (setq numList (cons (quote min) numList))
    (eval numList)))

;;
;;pckListMax
;;  Returns the maximum value in a list
(defun pckListMax (numList)
  (let ()
    (setq numList (pckFlattenList (list numList)))
    (setq numList (cons (quote max) numList))
    (eval numList)))



;;;;;;;;;;;;;;;;;; loads module_loader.il from all the subdirectory ;;;;;
(defun pckModuleLoader (pathToLib @optional (depth 0))
"Loads module_loader.il from all the template sub-categories"
 (let (theFile topDir tccPathDir skillCB pathlib)
    (foreach topDir (getDirFiles pathToLib)
         (if (not (or  (equal topDir ".SYNC") (equal topDir "." ) (equal topDir "..") )) 
             (progn 
               (setq tccPathDir (buildString (list pathToLib topDir ) "/" ))
               (when (isDir tccPathDir)
                 (fprintf stdout "TCC SYSTEM LOADER: Checking %s/%s\n"
                                                   (car (last (parseString pathToLib "/"))) topDir )
                 (when (isFile (setq filepath (strcat tccPathDir "/module_loader.il")))
                   (fprintf stdout "TCC SYSTEM LOADER: Loading %s/%s/module_loader.il\n"
                                               (car (last (parseString pathToLib "/"))) topDir)
                   (loadi filepath)
                     )
                 (foreach theFile (getDirFiles tccPathDir)                           
                          ;; (fprintf stdout " tccPathDir =%L theFile=%L\n" tccPathDir theFile)
                          (when (not (or (equal theFile "." ) (equal theFile "..") (equal theFile ".SYNC")))
                            (setq filepath (strcat tccPathDir "/" theFile))
                            (when (isDir filepath)
                              (pckModuleLoader filepath))) ;; if
                          ));;               
               (if (and (isFile tccPathDir) (equal topDir "module_loader.il"))
                   (progn
                     ;;(fprintf stdout " TCC SYSTEM LOADER: Loading %L in %L\n" topDir pathToLib)
                     (fprintf stdout " -- TCC SYSTEM LOADER: Loading %s/%s\n" (car (last (parseString pathToLib "/"))) topDir )
                     (loadi tccPathDir)
                     ))
            )) ;; end of if
         ) ;; foreach
    ) ;; let 
 ) ;; end of fn

;;;;;;;;;;;;;;;;;; loads pcell_loader.il from all the subdirectory ;;;;;
(defun pckPcellLoader (pathToLib @optional (depth 0))
"Loads pcell_loader.il from all the template sub-categories"
 (let (theFile topDir tccPathDir skillCB pathlib)
    (foreach topDir (getDirFiles pathToLib)
         (if (not (or  (equal topDir ".SYNC") (equal topDir "." ) (equal topDir "..") )) 
             (progn 
               (setq tccPathDir (buildString (list pathToLib topDir ) "/" ))
               (when (isDir tccPathDir)
                 (fprintf stdout "TCC SYSTEM LOADER: Checking %s/%s\n"
                                                   (car (last (parseString pathToLib "/"))) topDir )
                 (when (isFile (setq filepath (strcat tccPathDir "/pcell_loader.il")))
                   (fprintf stdout "TCC SYSTEM LOADER: Loading %s/%s/pcell_loader.il\n"
                                               (car (last (parseString pathToLib "/"))) topDir)
                   (loadi filepath)
                     )
                 (foreach theFile (getDirFiles tccPathDir)                           
                          ;; (fprintf stdout " tccPathDir =%L theFile=%L\n" tccPathDir theFile)
                          (when (not (or (equal theFile "." ) (equal theFile "..") (equal theFile ".SYNC")))
                            (setq filepath (strcat tccPathDir "/" theFile))
                            (when (isDir filepath)
                              (pckPcellLoader filepath))) ;; if
                          ));;               
               (if (and (isFile tccPathDir) (equal topDir "pcell_loader.il"))
                   (progn
                     ;;(fprintf stdout " TCC SYSTEM LOADER: Loading %L in %L\n" topDir pathToLib)
                     (fprintf stdout " -- TCC SYSTEM LOADER: Loading %s/%s\n" (car (last (parseString pathToLib "/"))) topDir )
                     (loadi tccPathDir)
                     ))
            )) ;; end of if
         ) ;; foreach
    ) ;; let 
 )

;; pckGetPIFFileName("x10as_cobc")

(defun pckGetPIFFileName ( nameSegment)
"Returns latest archived PIF file name which contains nameSegment within file name => s_string | nil"
(let (path allFilesList found)

    (setq path (getShellEnvVar "TCC_PIF_ARCHIVE"))
    (if path != nil then
        (when (isReadable path)

          (setq allFilesList (getDirFiles path))
          (foreach f allFilesList (if (nindex f nameSegment) (setq found f)))
          )
        )
    found
)
)

(defun pckChecksumGet (filePath)
  "Calculates and returns a checksum values for the given file => int"
  (let (ipcId ckSum)
	(if filePath
		(progn
		  (setq ipcId (ipcBeginProcess (strcat "cksum " filePath)))
		  (ipcWait ipcId)
		  (setq ckSum (ipcReadProcess ipcId 120))
		  (atoi (car (parseString ckSum " "))))
	  nil)))

(defun pckChecksumAttachProp (@key (storeLib nil)
								   (storeCell nil)
								   (checkLib nil)
								   (checkCell nil)
								   (propName nil))
  "Calculates a checksum for the checkCell and stores the checksum as a cellView property in the storeCell => t"
  (let (storeCvId checkCvId ckSum)
	(if (ddGetObj checkLib checkCell)
	  (progn
		;;Open cell for file path
		(setq checkCvId (dbOpenCellViewByType checkLib checkCell "layout" "maskLayout" "r"))
		;;Get checksum
		(setq ckSum (pckChecksumGet (getSGq checkCvId fileName)))
		;;close cell
		(dbClose checkCvId)
		;;Open cvId where checksum will be stored
		(setq storeCvId (dbOpenCellViewByType storeLib storeCell "layout" "maskLayout" "a"))
		;;create prop with checksum
		(dbSet storeCvId ckSum propName)
		;;save cvId where checksum will be stored
		(dbSave storeCvId)
		;;close cvId where checksum will be stored
		(dbClose storeCvId)
		t)
	  nil)))

(defun pckChecksumCompare (@key (storeLib nil)
								(storeCell nil)
								(checkLib nil)
								(checkCell nil)
								(propName nil))
  "Calculates a checksum for the checkCell and compares it to the checkSum property in the storeCell => t/nil"
  (let (storeCvId checkCvId ckSumStored ckSumCalc)
	(if (ddGetObj checkLib checkCell)
	  (progn
		;;Open cell for file path
		(setq checkCvId (dbOpenCellViewByType checkLib checkCell "layout" "maskLayout" "r"))
		;;Get checksum
		(setq ckSumCalc (pckChecksumGet (getSGq checkCvId fileName)))
		;;close cell
		(dbClose checkCvId)
		;;Open cvId where checksum will be stored
		(setq storeCvId (dbOpenCellViewByType storeLib storeCell "layout" "maskLayout" "r"))
		;;query checksum
		(setq ckSumStored (dbGet storeCvId propName))
		;;close cvId where checksum will be stored
		(dbClose storeCvId)
		;;Compare and return result
		(if ckSumStored
			(pckEQP ckSumCalc ckSumStored)
		  nil))
	  nil)))

procedure(convertLayerName(layer)
  let( ( (result nil) layerNum)
    if( pcreMatchp("^(via|metal|tm)\\d+$" layer)  then
      result = layer
    else
      if( pcreMatchp("^m(\\d+)$" layer)     then  layerNum = pcreSubstitute("\\1") result = strcat("metal" layerNum) 
      else if(pcreMatchp("^v(\\d+)$" layer) then  layerNum = pcreSubstitute("\\1") result = strcat("via" layerNum)
           else result = nil
	   );if 
      );if
    );if
    result
));procedure
