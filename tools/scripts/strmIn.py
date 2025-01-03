#!/usr/bin/env python3.7.4
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

def createFile(gdsFiles,tempDir,tool):
  tmplFile = os.path.join(tempDir,'tmplFile.txt')
  if tool in ['strmin','oasisin']:
    if tool == 'strmin': strmLine = f'strmFile "{",".join(gdsFiles)}"'; oasis = ''
    else: strmLine = f'oasisFile "{gdsFiles[0]}"'; oasis = '#'
    outStr = f'''
library "{args.libName}"
{strmLine}
attachTechFileOfLib                ""
case                               "preserve"
cellMap                            ""
#enableColoring
excludeMapToVia                    ""
{oasis}fontMap                            ""
#infoToWarn                         ""
{oasis}labelCase                          "preserve"
layerMap                           "{args.lmap}"
loadTechFile                       ""
logFile                            "strmIn.log"
noInfo                             ""
noWarn                             ""
#objectMap                          "{args.omap}"
{oasis}pinAttNum                          "0"
propMap                            ""
{oasis}propSeparator                      ","
refLibList                         ""
runDir                             "."
#scale                              "1.00000"
scaleTextHeight                    "1.00000"
#showCompletionMsgBox
{oasis}strmTechGen                        ""
summaryFile                        ""
techRefs                           ""
topCell                            ""
userSkillFile                      ""
viaMap                             ""
view                               "layout"
warnToErr                          ""'''
  else:
    outStr = '''
lib                                '''+args.libName+'''
gds                                '''+','.join(gdsFiles)+'''
layerMap                           '''+args.lmap+'''
overwrite
hierDepth 			   1000
textHeight 			   1
shared'''
  with open(tmplFile, 'w') as outF: outF.write(outStr); 
  return tmplFile

def getCmd(tool): 
  if tool == 'cadence': return 'strmin'
  elif tool == 'ads': return 'strm2oa'
  else: raise argparse.ArgumentTypeError('invalid choice: '+tool+' (choose from \'cadence\',\'ads\')')  

def prepareCdsLib(tool):
  if tool != 'strmin': 
    if not os.path.exists('cds.lib'):
      with open('cds.lib','w') as fout: fout.write('SOFTINCLUDE lib.defs')
    return '.',False
  else:
    rundir = os.getenv('WARD')+'/rundir/opus' if not (os.getenv('INTEL_RF') or os.getenv('INTEL_PDK')) else os.getenv('WARD')
    if os.path.exists(rundir+'/cds.lib'): return rundir,False
    else: os.symlink(os.getenv('CDSLIB'),rundir+'/cds.lib'); return rundir,True
  
## MAIN BEGINS ##    
import sys, argparse, tempfile, subprocess, os
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import layout
if os.getenv("PROCESS_NAME") == '1231': defTechFile = os.getenv('ISSRUNSETS')+'/Calibre/includes/p1231_map.txt'; objFile = '/nfs/pdx/disks/x31b.disk.6/work_x31b/tc1/jmarulan/myDocs/icfpdk_0p0/intel31tech/intel31tech.objectmap'
elif os.getenv("INTEL_RF") or os.getenv("INTEL_PDK"):  cmd = subprocess.run("find "+os.getenv('INTEL_PDK')+"/libraries/tech/pcell -name '*.layermap'",shell=True,stdout=subprocess.PIPE,text=True); defTechFile = cmd.stdout.strip(); cmd = subprocess.run("find "+os.getenv('INTEL_PDK')+"/libraries/tech/pcell -name '*.objectmap'",shell=True,stdout=subprocess.PIPE,text=True); objFile = cmd.stdout.strip();
else: defTechFile,objFile = layout.getTechFile() # = os.getenv('ISSRUNSETS')+'/PXL/'+os.getenv('PROCESS_NAME')+'/p'+os.getenv('PROCESS_NAME')+'.map'; objFile = '/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/skill/objectmap.map'

## INPUTS ##
tempParser = argparse.ArgumentParser(add_help=False)
tempParser.add_argument('-tool', dest='tool', default = 'cadence', type=getCmd, help='Engine to use ["cadence",ads]')
tempArgs = tempParser.parse_known_args()[0]
rundir,removeCDS=prepareCdsLib(tempArgs.tool)
argparser = argparse.ArgumentParser(description='Streams in gds file into specified library',parents=[tempParser])
argparser.add_argument(dest='gdsFiles', nargs='+', type=os.path.realpath, help='GDS file(s)')
argparser.add_argument('-lib', dest='libName', required = True, help='Library with top views')
argparser.add_argument('-layermap', dest='lmap', default = defTechFile, type=os.path.realpath, help='Layer Map File')
argparser.add_argument('-objectmap', dest='omap', default = '',type=os.path.realpath, help='Object Map File')
argparser.add_argument('-rundir', dest='rundir', default = rundir, help='Virtuoso/Ads work area, defaults to Virtuoso')
args = argparser.parse_args()

## Create the temp dir and check cds.lib
tempDir = os.path.realpath(tempfile.mkdtemp(dir='.')); cDir = os.getcwd()
os.chdir(args.rundir)

## run for each gds file
if os.path.splitext(args.gdsFiles[0])[1] == '.oas': args.tool = 'oasisin';
if args.tool == 'strmin':
  tmplFile = createFile(args.gdsFiles,tempDir,args.tool)
  subprocess.call(args.tool+' -templateFile '+tmplFile, shell=True)
else: #only one at a time
  for gdsFile in args.gdsFiles:
    tmplFile = createFile([gdsFile],tempDir,args.tool)
    subprocess.call(args.tool+' -templateFile '+tmplFile, shell=True)
  
## remove dirs
os.chdir(cDir)
removeCds = '' if removeCDS == False else ' ; rm -f '+args.rundir+'/cds.lib'
subprocess.Popen('sleep 5; rm -rf '+tempDir+removeCds,shell=True)
