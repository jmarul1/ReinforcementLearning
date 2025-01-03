#!/usr/bin/env python2.7
##############################################################################
# Intel Top Secret							     #
##############################################################################
# Copyright (C) 2015, Intel Corporation.  All rights reserved.  	     #
#									     #
# This is the property of Intel Corporation and may only be utilized	     #
# pursuant to a written Restricted Use Nondisclosure Agreement  	     #
# with Intel Corporation.  It may not be used, reproduced, or		     #
# disclosed to others except in accordance with the terms and		     #
# conditions of such agreement. 					     #
#									     #
# All products, processes, computer systems, dates, and figures 	     #
# specified are preliminary based on current expectations, and are	     #
# subject to change without notice.					     #
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################


def createFile(gdsFiles,tempDir):
  tmplFile = os.path.join(tempDir,'tmplFile.txt')
  outStr = '''
library "'''+args.libName+'''"
strmFile "'''+'","'.join(gdsFiles)+'''"
attachTechFileOfLib                ""
case                               "preserve"
cellMap                            ""
#enableColoring
excludeMapToVia                    ""
fontMap                            ""
infoToWarn                         ""
labelCase                          "preserve"
layerMap                           "'''+args.lmap+'''"
loadTechFile                       ""
logFile                            "strmIn.log"
noInfo                             ""
noWarn                             ""
objectMap                          "'''+args.omap+'''"
pinAttNum                          "0"
propMap                            ""
propSeparator                      ","
refLibList                         ""
runDir                             "."
scale                              "1.00000"
scaleTextHeight                    "1.00000"
showCompletionMsgBox
strmTechGen                        ""
summaryFile                        ""
techRefs                           ""
topCell                            ""
userSkillFile                      ""
viaMap                             ""
view                               "layout"
warnToErr                          ""'''
  with open(tmplFile, 'wb') as outF: outF.write(outStr)
  return tmplFile

## MAIN BEGINS ##    
import sys, argparse, tempfile, subprocess,os
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib')

## INPUTS ##
argparser = argparse.ArgumentParser(description='Streams in gds file into specified library (uses your $FDK_WORK/cds.lib, make sure the library is defined)')
argparser.add_argument(dest='gdsFiles', nargs='+', type=os.path.realpath, help='GDS file(s)')
argparser.add_argument('-lib', dest='libName', required = True, help='Library with top views')
argparser.add_argument('-layermap', dest='lmap', default = '', type=os.path.realpath, help='Layer Map File')
argparser.add_argument('-objectmap', dest='omap', default = '',type=os.path.realpath, help='Object Map File')
args = argparser.parse_args()


## Create the temp dir and check cds.lib
tempDir = os.path.realpath(tempfile.mkdtemp(dir='.')); cDir = os.getcwd()
os.chdir(os.getenv('FDK_WORK'))
if not os.path.isfile('cds.lib'): raise IOError('cds.lib is missing or corrupted')

## run for each gds file
tmplFile = createFile(args.gdsFiles,tempDir)
subprocess.call('strmin -templateFile '+tmplFile, shell=True)
  
## remove dirs
os.chdir(cDir)
subprocess.Popen('sleep 5; rm -rf '+tempDir,shell=True)
  
