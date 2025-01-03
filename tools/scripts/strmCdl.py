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


def getIncFile(path):
  import os
  if os.path.isfile(path): return os.path.realpath(path)
  else: raise IOError('Include file does not exist: '+path)

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
pinMAP = \''''+args.bracket+'''
shrinkFACTOR = 0.0
globalPowerSig = ""
displayPININFO = 't
preserveALL = 't
auCdlCDFPinCntrl = 't
auCdlPrintMultiplicityFactor = 't
preserveBangInNetlist = 't
setEQUIV = "vss=vss!"
'''
#simDetectPCellFailure = 'ignore
# globalGndSig = "vss VSS"
#when(simSimulator=="auCdl" hnlInvalidNetNames = '(("vss!" "vss")))
  envFile = os.path.join(runDir,'si.env')
  with open(envFile, 'w') as outF: outF.write(outStr)
  return envFile

## MAIN BEGINS ##    
import sys, argparse, tempfile, subprocess, os, shutil, pdkutils, cadence

## INPUTS ##
argparser = argparse.ArgumentParser(description='Streams out cdl files into specified directory (defaults to current)')
argparser.add_argument(dest='cellNames', nargs = '+', help='Cell View(s)')
argparser.add_argument('-lib', dest='libName', required = True, help='Library with top views')
argparser.add_argument('-outdir', dest='outDir', default = '.', help='Output Directory')
argparser.add_argument('-viewName', dest='viewName', default = 'schematic', help='View name of the cell')
argparser.add_argument('-include', dest='include', nargs = '+', default=pdkutils.getCdlIncludes(), type=getIncFile, help='Include file(s)')
argparser.add_argument('-bracket', dest='bracket', action='store_const', const='t', default = 'nil', help='Change <> to []')
argparser.add_argument('-keeplog', dest='keepLog',action='store_true',help=argparse.SUPPRESS)
args = argparser.parse_args()
print( args.bracket)
## run for each gds file
cdsFile = os.getenv('CDSLIB')
if cdsFile == None: cdsFile = os.getenv('WARD')+'/cds.lib';
if not os.path.isfile(cdsFile): raise IOError('cds.lib is missing or corrupted')
## get the cells with support to regular expression
cdsObj = cadence.readCds(cdsFile); effCells=[]
for topCell in args.cellNames: effCells += cdsObj.getLibCells(args.libName,'^'+(topCell.strip().rstrip('$').lstrip('^'))+'$')
if not effCells: sys.stderr.write('No matching cells in library\n')
## create dir
tempDir = os.path.realpath(tempfile.mkdtemp(dir='.')); errorLog=False
for cellName in effCells:
  fOutName = cellName+'.sp'
  tmplFile = createSiEnv(cellName,args.libName,tempDir,fOutName,args.include)
  #print 'strmout -templateFile '+ os.path.relpath(tmplFile)
  subprocess.call('si '+tempDir+' -batch -command netlist -cdslib '+cdsFile, shell=True)
  ## copy cdl or store error out if nothing
  if os.path.isfile(tempDir+'/'+fOutName): shutil.copy(tempDir+'/'+fOutName, args.outDir+'/'+fOutName)
  else: errorLog = 'ERROR: '+os.path.splitext(fOutName)[0]+' NOT created\n'
## if any files did not work output
if errorLog: sys.stderr.write(errorLog+'\n')
## remove dirs
if not args.keepLog: subprocess.Popen('sleep 5; rm -rf '+tempDir,shell=True)
