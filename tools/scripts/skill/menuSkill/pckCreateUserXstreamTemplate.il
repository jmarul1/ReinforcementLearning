(defun pckCreateUserXstreamTemplate (@optional (debug nil))
  (let (port (type (list "In" "Out")))
    (foreach tmpl type     
             (setq port
                   (outfile
                    (sprintf nil "/tmp/wrk/dev-xtrm%s.tmpl-%s" tmpl (getShellEnvVar "USER"))))             
             (fprintf port "%s\n"
                      (apply (stringToSymbol (strcat "pckReturnXstream" tmpl "TemplateString")) nil))
             (close port)
             (fprintf stdout "Loading user-specific XStream %s template\n" tmpl)
             (envSetVal "xstream"  
                        (strcat "XST_" (upperCase tmpl)) 
                        'string
                        (sprintf nil "/tmp/wrk/dev-xtrm%s.tmpl-%s" tmpl (getShellEnvVar "USER")))
             (setShellEnvVar
              (strcat "XST_" (upperCase tmpl) "="
                      (sprintf nil "/tmp/wrk/dev-xtrm%s.tmpl-%s" tmpl (getShellEnvVar "USER"))))
             )

    )
  )
(defun pckReturnXstreamOutTemplateString ()
  (let (cmd)
	(sprintf cmd "runDir 	\".\" 	# Run Directory\n
#library 	\"\" 	# Input Library\n
topCell 	\"\" 	# Toplevel Cell to Translate\n
view 	\"layout\" 	# Toplevel Cell View Name\n
#strmFile 	\"\" 	# Output Stream File\n
hierDepth 	32 	# Hierarchical Depth to Translate to (0-32)\n
flattenPcells 	# (t/nil)\n
maxVertices 	200 	# Limit of Vertices Allowed\n
refLibList 	\"\" 	# Name of File Containing refLibList\n
strmVersion 	5 	# Stream Version\n
#snapToGrid 	# (t/nil)\n
#arrayInstToScalar 	# (t/nil)\n
case 	\"lower\" 	# upper | lower | preserve\n
#ignoreLines 	# (t/nil)\n
convertDot 	\"node\" 	# node | polygon | ignore\n
#rectToBox 	# (t/nil)\n
pathToPolygon 	# (t/nil)\n
logFile 	\"PIPO.LOG\" 	# Output Log File Name\n
#respectGDSIINameLimit 	# (t/nil)\n
cellMap 	\"\" 	# Input Cell Map File\n
layerMap 	\"%s\"\n
fontMap 	\"\" 	# Input Font Map File\n
convertPin 	\"geometry\" 	# geometry | text | geometryAndText | ignore\n
pinAttNum 	0 	# Stream Attribute # (1-127) for Preserving Pins\n
propMap 	\"\" 	# Input Property Map File\n
userSkillFile 	\"%s\" # Input User SKILL File\n
#doNotPreservePcellPins 	# (t/nil)\n
viaMap 	\"\" 	# Input Via Map File\n
#noObjectProp 	# (t/nil)\n
summaryFile 	\"\" 	# Output Summary File\n
techLib 	\"\" 	# Technology Library\n
#noOutputTextDisplays 	# (t/nil)\n
objectMap 	\"\" 	# Input Object Map File"
             (strcat
              (getShellEnvVar "ISSRUNSETS")
              "/PXL/p" (getShellEnvVar "PROCESS_NAME") ".map")
             (strcat (getShellEnvVar "WORK_AREA_ROOT_DIR") "/tcc_collateral/loader.il")
             )
    cmd
    )
  )
(defun pckReturnXstreamInTemplateString ()
  (let (cmd)
    (sprintf cmd "runDir 	\".\" 	# Run Directory\n
strmFile 	\"test.gds\" 	# Input Stream File\n
topCell 	\"\" 	# Toplevel Cell to Translate\n
#library 	\"\" 	# Destination Library\n
loadTechFile 	\"\" 	# ASCII Tech File\n
logFile 	\"PIPO_STMIN.LOG\" 	# Output Log File Name\n
refLibList 	\"\" 	# File Containing refLibList\n
hierDepth 	32 	# Hierarchical Depth to Translate to (0-32)\n
#snapToGrid 	# (t/nil)\n
#arrayInstToScalar 	# (t/nil)\n
case 	\"lower\" 	# upper | lower | preserve\n
#ignoreZeroWidthPath 	# (t/nil)\n
translateNode 	# (t/nil)\n
#skipUndefinedLPP 	# (t/nil)\n
#ignoreBoxes 	# (t/nil)\n
#keepStreamCells 	# (t/nil)\n
attachTechFileOfLib 	\"\" 	# Tech Lib to Attach to Target Lib\n
#noOverwriteCell 	# (t/nil)\n
cellMap 	\"\" 	# Input Cell Map File\n
layerMap 	\"%s\" \n
fontMap 	\"\" 	# Input Font Map File\n
pinAttNum 	0 	# Stream Attribute # (1-127) for Preserving Pins\n
propMap 	\"\" 	# Input Property Map File\n
propSeparator 	\",\" 	#  \n
#userSkillFile 	 	# Input User SKILL File\n
#mergeUndefPurposToDrawing 	# (t/nil)\n
maxCellsInTargetLib 	20000 	# Cell Limit Per Library\n
#disableLocking 	# (t/nil)\n
scaleTextHeight 	0.01 	# Scale Text Height\n
viaMap 	\"\" 	# Input Via Map File\n
#convertPathToPathSeg 	# (t/nil) Two Point Paths\n
view 	\"layout\" 	# Destination View Name\n
summaryFile 	\"\" 	# Output Summary File\n
techRefs 	\"\" 	# Reference Tech Libraries\n
objectMap 	\"\" 	# Input Object Map File\n"
             (strcat
              (getShellEnvVar "ISSRUNSETS")
              "/PXL/p" (getShellEnvVar "PROCESS_NAME") ".map")
             )    
    )
  )

