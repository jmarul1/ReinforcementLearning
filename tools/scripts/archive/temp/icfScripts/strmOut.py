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


def createFile(topCell,outDir,tempDir):
  outStr = '''strmFile "'''+topCell+'''.gds"
library "'''+args.libName+'''"
outputDir "'''+outDir+'''"
logFile "'''+outDir+'/'+topCell+'''.gdslog"
view "'''+args.viewName+'''"
topCell "'''+topCell+'''"
layerMap "'''+args.lmap+'''"
objectMap "'''+args.omap+'''"
#pathToPolygon
#maxVertices "3500"
#convertPin "geometryAndText"
'''+args.coloring
  tmplFile = os.path.join(tempDir,'tmplFile')
  with open(tmplFile, 'wb') as outF: outF.write(outStr)
  return tmplFile

def prepareCds(cds):
  with open(cds,'rb')as fin: return fin.read()
  
## MAIN BEGINS ##    
import sys, argparse, tempfile, subprocess,os
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib')

## env check ##
try: env = os.getenv("PROJECT")[-2:] 
except TypeError: raise EnvironmentError("Run in an environment 1271/1273/1275")

## INPUTS ##
argparser = argparse.ArgumentParser(description='Streams out gds files into specified directory')
argparser.add_argument(dest='topCells', nargs = '+', help='Cell View(s)')
argparser.add_argument('-lib', dest='libName', required = True, help='Library with top views')
argparser.add_argument('-outdir', dest='outDir', default = '.', help='Output Directory')
argparser.add_argument('-layermap', dest='lmap', default = os.getenv('FDK_DISPLAY_DRF_DIR')+'/'+os.getenv('FDK_TECHLIB_NAME')+'.layermap', help='Layer Map File')
argparser.add_argument('-objectmap', dest='omap', default = os.getenv('FDK_DISPLAY_DRF_DIR')+'/'+os.getenv('FDK_TECHLIB_NAME')+'.objectmap', help='Object Map File')
argparser.add_argument('-viewName', dest='viewName', default = 'layout', help='View name of the cell')
argparser.add_argument('-cdslib', dest='cdslib', type=prepareCds, help='cds.lib file to append to existing one (only works if ran in different dir than the work area')
argparser.add_argument('-keeplog', dest='keepLog',action='store_true',help=argparse.SUPPRESS)
argparser.add_argument('-coloring', dest='coloring',action='store_const',default='enableColoring' if env=='75' else '',const='enableColoring', help=argparse.SUPPRESS)
args = argparser.parse_args()

## run for each gds file
cdsFile = os.path.join(os.getenv('FDK_WORK'),'cds.lib');
if os.path.realpath(os.getcwd()) != os.path.realpath(os.getenv('FDK_WORK')): 
  subprocess.call('cp '+cdsFile+' .',shell=True); cdsErase=True; cdsFile='cds.lib'; 
  if args.cdslib: 
    with open(cdsFile,'ab') as fout: fout.write('\n'+args.cdslib)
else: cdsErase = False
if not os.path.isfile(cdsFile): raise IOError('cds.lib is missing or corrupted')
## create dir
tempDir = tempfile.mkdtemp(dir='.')
for topCell in args.topCells:
  tmplFile = createFile(topCell,args.outDir,tempDir)
  #print 'strmout -templateFile '+ os.path.relpath(tmplFile)
  subprocess.call('strmout -templateFile '+tmplFile, shell=True)
  if not(args.keepLog): logFile=args.outDir+'/'+topCell+'.gdslog'; subprocess.call('rm '+logFile,shell=True)
## remove dirs
if not(args.keepLog):
  if cdsErase: subprocess.Popen('sleep 5; rm -rf '+' '.join([tempDir,'cds.lib','1']),shell=True)
  else: subprocess.Popen('sleep 5; rm -rf '+tempDir,shell=True)
