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


def createFile(topCell,outDir,tempDir,coloring):
  if args.techlib: techStuff = 'techLib "'+args.techlib+'"'
  else: techStuff = 'layerMap "'+args.lmap+'"\nobjectMap "'+args.omap+'"'
  foutName = topCell if not args.overlay else args.overlay
  outStr = '''strmFile "'''+foutName+'''.gds"
library "'''+args.libName+'''"
outputDir "'''+outDir+'''"
logFile "'''+outDir+'/'+foutName+'''.gdslog"
view "'''+args.viewName+'''"
topCell "'''+topCell+'''"
'''+techStuff+'''
'''+('#' if not(os.getenv('TESTCHIP')) else '')+'''dbuPerUU "10000"
'''+('enableColoring "true" ' if coloring else '')+'''
#pathToPolygon
#maxVertices "3500"
#ignorePcellEvalFail
#convertPin "geometryAndText"
'''+('flattenPcells\nflattenVias' if args.flatten else '')
  tmplFile = os.path.join(tempDir,'tmplFile')
  with open(tmplFile, 'w') as outF: outF.write(outStr)
  return tmplFile

def prepareCds(cds):
  with open(cds,'r')as fin: return fin.read()
  
## MAIN BEGINS ##    
import sys, argparse, tempfile, subprocess,os, layout
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); import cadence

## env check ##
try: env = os.getenv("PROJECT")[-2:] 
except TypeError: raise EnvironmentError("Run in an environment")
if os.getenv("INTEL_RF") or os.getenv("INTEL_PDK"): cmd = subprocess.run("find "+os.getenv('INTEL_PDK')+"/libraries/tech/pcell -name '*.layermap'",shell=True,stdout=subprocess.PIPE); defTechFile = cmd.stdout.decode().strip(); cmd = subprocess.run("find "+os.getenv('INTEL_PDK')+"/libraries/tech/pcell -name '*.objectmap'",shell=True,stdout=subprocess.PIPE); objFile = cmd.stdout.decode().strip();
else: defTechFile,objFile = layout.getTechFile() # = os.getenv('ISSRUNSETS')+'/PXL/'+os.getenv('PROCESS_NAME')+'/p'+os.getenv('PROCESS_NAME')+'.map'; objFile = '/nfs/pdx/disks/xchip.disk.1/wireless_common/jmarulan/utils/scripts/skill/objectmap.map'
## INPUTS ##
argparser = argparse.ArgumentParser(description='Streams out gds files into specified directory')
argparser.add_argument(dest='topCells', nargs = '+', help='Cell View(s) or single regular expr for cells')
argparser.add_argument('-lib', dest='libName', required = True, help='Library with top views')
argparser.add_argument('-outdir', dest='outDir', default = '.', help='Output Directory')
argparser.add_argument('-layermap', dest='lmap', default = defTechFile, help='Layer Map File')
argparser.add_argument('-objectmap', dest='omap', default = objFile, help='Object Map File')
argparser.add_argument('-viewName', dest='viewName', default = 'layout', help='View name of the cell')
argparser.add_argument('-cdslib', dest='cdslib', type=prepareCds, help='cds.lib file to append to existing one (only works if ran in different dir than the work area')
argparser.add_argument('-keeplog', dest='keepLog',action='store_true',help=argparse.SUPPRESS)
argparser.add_argument('-flatten', dest='flatten',action='store_true',help='Flatten pcell/vias')
argparser.add_argument('-overlay', dest='overlay',nargs='?',const='overlay',help='combine all the cells in one gds by default overlay.gds')
argparser.add_argument('-techlib', dest='techlib', help='Technology Library')
args = argparser.parse_args()

## run for each gds file
cdsFile = os.getenv('CDSLIB');
if cdsFile == None: cdsFile = os.getenv('WARD')+'/cds.lib';
if os.path.realpath(os.getcwd()) != os.path.realpath(os.path.dirname(cdsFile)): 
  subprocess.call('cp '+cdsFile+' cds.lib',shell=True); cdsErase=True; cdsFile='cds.lib'; 
  if args.cdslib: 
    with open(cdsFile,'a') as fout: fout.write('\n'+args.cdslib)
else: cdsErase = False
if not os.path.isfile(cdsFile): raise IOError('cds.lib is missing or corrupted')
## create dir
tempDir = tempfile.mkdtemp(dir='.'); 
## get the cells with support to regular expression
cdsObj = cadence.readCds(cdsFile); effCells=[]
for topCell in args.topCells: effCells += cdsObj.getLibCells(args.libName,'^'+(topCell.strip().rstrip('$').lstrip('^'))+'$')
if not effCells: sys.stderr.write('No matching cells in library\n')
## if args.techlib given decide enable coloring
coloring = True if args.techlib and layout.getTechFile(cdsObj.getLibPath(args.techlib))[0].strip() else False
#coloring = True
## if overlay
if args.overlay: effCells = [','.join(effCells)]
for topCell in effCells:
  tmplFile = createFile(topCell,args.outDir,tempDir,coloring)  #print 'strmout -templateFile '+ os.path.relpath(tmplFile)
  subprocess.call('strmout -templateFile '+tmplFile, shell=True)
  if not(args.keepLog): 
    logFile=args.outDir+'/'+topCell+'.gdslog' if not args.overlay else args.outDir+'/'+args.overlay+'.gdslog'
    subprocess.call('rm '+logFile,shell=True)
## remove dirs
if not(args.keepLog):
  if cdsErase: subprocess.Popen('sleep 5; rm -rf '+' '.join([tempDir,'cds.lib','1']),shell=True)
  else: subprocess.Popen('sleep 5; rm -rf '+tempDir,shell=True)
## print tech files
if args.techlib: print('TechLib used: '+args.techlib)
else: print('TechFile used\nLayermap: '+args.lmap+'\nobjectmap: '+args.omap)
