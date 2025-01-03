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


def getIncFiles():
  import os, re
  if os.getenv('PROJECT') == 'f1222' :  #updated for 1222
    mainDir = os.path.realpath(os.getenv('INTEL_PDK')+'/models/custom/cdl') 
  else :
	mainDir = os.path.realpath(os.getenv('INTEL_PDK')+'/models/cdl/custom')
  
  files = os.listdir(mainDir)
  if any(files): return filter(lambda ss: not(re.search(r'.SYNC',ss,flags=re.I)), map(lambda ff: mainDir+'/'+ff,files))
  else: return []

def createSiEnv(cellName,libName,runDir,fileName,incFiles):
  outStr = '''
simLibName = "'''+libName+'''"
simCellName = "'''+cellName+'''"
simRunDir = "'''+runDir+'''"
hnlNetlistFileName = "'''+fileName+'''"
incFILE = "'''+' '.join(incFiles)+'''"
simViewName = "'''+args.viewName+'''"
simSimulator = "auCdl"
simNotIncremental = nil
cdsNetlistingMode = "Analog"
simReNetlistAll = nil
simViewList = '("auCdl" "schematic")
simStopList = '("auCdl")
simNetlistHier = t
resistorModel = ""
shortRES = 2000.0
preserveRES = 't
checkRESVAL = 't
checkRESSIZE = 'nil
preserveCAP = 't
checkCAPVAL = 't
checkCAPAREA = 'nil
preserveDIO = 't
checkDIOAREA = 't
checkDIOPERI = 't
checkCAPPERI = 'nil
simPrintInhConnAttributes = 'nil
checkScale = "meter"
checkLDD = 'nil
pinMAP = 't
shrinkFACTOR = 0.0
globalPowerSig = ""
displayPININFO = 't
preserveALL = 't
setEQUIV = ""
''' # globalGndSig = "vss VSS"
  envFile = os.path.join(runDir,'si.env')
  with open(envFile, 'wb') as outF: outF.write(outStr)
  return envFile

## MAIN BEGINS ##    
import sys, argparse, tempfile, subprocess, os, shutil
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib')

## INPUTS ##
argparser = argparse.ArgumentParser(description='Streams out cdl files into specified directory (defaults to current)')
argparser.add_argument(dest='cellNames', nargs = '+', help='Cell View(s)')
argparser.add_argument('-lib', dest='libName', required = True, help='Library with top views')
argparser.add_argument('-outdir', dest='outDir', default = '.', help='Output Directory')
argparser.add_argument('-viewName', dest='viewName', default = 'schematic', help='View name of the cell')
args = argparser.parse_args()

## run for each gds file
cdsFile = os.path.join(os.getenv('FDK_WORK'),'cds.lib')
if not os.path.isfile(cdsFile): raise IOError('cds.lib is missing or corrupted')

## create dir
tempDir = os.path.realpath(tempfile.mkdtemp(dir='.')); errorLog=False
for cellName in args.cellNames:
  fOutName = cellName+'.cdl'
  tmplFile = createSiEnv(cellName,args.libName,tempDir,fOutName,getIncFiles())
  #print 'strmout -templateFile '+ os.path.relpath(tmplFile)
  subprocess.call('si '+tempDir+' -batch -command netlist -cdslib '+cdsFile, shell=True)
  ## copy cdl or store error out if nothing
  if os.path.isfile(tempDir+'/'+fOutName): shutil.copy(tempDir+'/'+fOutName, fOutName)
  else: errorLog = 'ERROR: '+os.path.splitext(fOutName)[0]+' NOT created\n'
## if any files did not work output
if errorLog: print >> sys.stderr, errorLog  
## remove dirs
subprocess.Popen('sleep 5; rm -rf '+tempDir,shell=True)
