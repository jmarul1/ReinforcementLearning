#!/usr/bin/env python2.7
##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2014, Intel Corporation.  All rights reserved.               #
#                                                                            #
# This is the property of Intel Corporation and may only be utilized         #
# pursuant to a written Restricted Use Nondisclosure Agreement               #
# with Intel Corporation.  It may not be used, reproduced, or                #
# disclosed to others except in accordance with the terms and                #
# conditions of such agreement.                                              #
#                                                                            #
# All products, processes, computer systems, dates, and figures              #
# specified are preliminary based on current expectations, and are           #
# subject to change without notice.                                          #
##############################################################################
#
# Author:
#   Mauricio Marulanda
#
# Description:
#   Type >> gdsToGeo.py -h
#
##############################################################################

def globalVars():
  global i2iVer, i2iDir, fStep, fRangeOW, cFList, project  
  project = os.getenv('PROJECT'); dot = os.getenv('FDK_DOTPROC')
  i2iDir = '/nfs/site/disks/icf_fdk_scalablerf001/jmarulan/'+project+'/dot'+dot+'/INDUCTOR/techFiles'
  project = {'fdk71':'71','fdk73':'73','f1275':'75'}.get(project)
# use for frequency resolution of simulation 
  fStep = 0.5 # frequency steps
  fRangeOW = []
  #fRangeOW = [0.1,0.2,0.3,0.4,0.5]; fRangeOW.extend(map(lambda ff: ff/10.0, range(10,1205,5))) #use if wanting to overwrite the frequency range with custom
  cFList=[dict(ncells='218',fmax='500G'), # N = 1 (500 G conservative)    # N = 1 (575 G conservative)
	  dict(ncells='490',fmax='100G'), # N = 2 (120 G conservative)	  # N = 2 (170 G conservative)
	  dict(ncells='618',fmax='50G'),  # N = 3 (55 G conservative)	  # N = 3 (80 G conservative)
	  dict(ncells='750',fmax='40G'),  # N = 4 (30 G conservative)	  # N = 4 (50 G conservative)
	  dict(ncells='806',fmax='20G'),  # N = 5 (20 G conservative)	  # N = 5 (40 G conservative)
# Use for default (N = 6) or modify the combination to the user needs
	  dict(ncells='400',fmax='65G')]
  if args.fmax: 
    for ii,val in enumerate(cFList): cFList[ii]['fmax'] = args.fmax
  if args.ncells:
    for ii,val in enumerate(cFList): cFList[ii]['ncells'] = args.ncells
    
def createDir(path):
  if not os.path.exists(path):
    os.makedirs(path)

def pToDot(strNum,dirMode='toP'):
  strNum = str(strNum)
  if dirMode == 'toP': # change the dot to letter "p"
    strNum = re.sub(r'\.','p',strNum,count=1)
  else: # change the letter "p" to a dot
    strNum = re.sub('p','.',strNum,flags=re.I,count=1)
  return strNum

def getI2iFile(nrturns, skew, outDir):
  cF = cFList[int(float(nrturns))-1] # get the respective i2i reference ncells/fmax value from the globals
# Create the frequency range if not given in globals, first create the number of points and attach to the inital 0.1, fStep
  if len(fRangeOW) != 0: fRange = fRangeOW
  else:
    nPoints = int(float(cF['fmax'].rstrip('G'))/fStep)-1; fRange = [fStep];
    for ii in range(nPoints): fRange.append(fRange[-1] + fStep)
  fidTemp = tempfile.TemporaryFile() # create temporary file 
# Create the command to replace fmax, ncells, and frequency range
  sedCmdStr = 'sed -e \'s/fmax=\"x\"/fmax=\"'+cF['fmax']+'\"/g\' -e \'s/ncells=\"x\"/ncells=\"'+cF['ncells']+'\"/g\' -e \'s/FrequencyParameters\">x/FrequencyParameters\">'+','.join(map(str,fRange))+'/g\' ' 
# Get the template i2i file, run sed, and dump it into the output file
  i2iTmplFile = i2iDir + '/p12'+project+'_'+os.getenv('FDK_DOTPROC') + i2iVer + '_' + skew + '_x_xG.i2i'; outFileName = ''
  if os.path.exists(i2iTmplFile):
    sedCmd = subprocess.Popen(sedCmdStr+i2iTmplFile,shell=True,stdout=fidTemp); sedCmd.wait()
    fidTemp.flush(); fidTemp.seek(0) # go to the origin of the file
    outFileName = 'p12'+project+'_'+os.getenv('FDK_DOTPROC')+i2iVer+'_'+skew+'_'+cF['ncells']+'_'+cF['fmax']+'.i2i'
    fidOut = open(outDir + '/' + outFileName,'w') # create the i2i output file
    fidOut.writelines(fidTemp.readlines()); fidOut.close(); 
  fidTemp.close()
  return outFileName
##############################################################################
# Argument Parsing
##############################################################################
import argparse
argparser = argparse.ArgumentParser(description='This program uses Hyperlynx (already running) to create *.sim/*.geo file pairs from the gds in the given directory.')
argparser.add_argument(dest='gdsFiles', nargs='+', help='The gds file(s)')
argparser.add_argument('-skew', dest='skew', default = ['lowQ','typQ','highQ'], help='This options lets you pick a single skew to run, otherwise it runs all three of them (low typ high)')
argparser.add_argument('-i2i', dest='i2iFile', default = False, help='This options lets you use a specific i2i file (all skews are treated the same, the file must be complete with Sim Parameters) or the i2i UPF version (defaults to UPF in the environment) to be used for searching the i2i file in $Scalable/INDUCTOR/Dot/techFiles')
argparser.add_argument('-outdir', dest='outDir', help='This options lets you specify the output directory, otherwise is the current dir')
argparser.add_argument('-log', dest='logFName', nargs='?', const = True, help='This options enables a log script of the actions taken running the script')
argparser.add_argument('-fmax', dest='fmax', help='Use as maximum frequency in GHz (please include G)')
argparser.add_argument('-ncells', dest='ncells', help='Use as number of cells per wavelength')
args = argparser.parse_args()
##############################################################################

##############################################################################
# Main Begins
##############################################################################
import sys, os, tempfile
import subprocess
import re

## Define global variables
globalVars()

## make sure hyperlynx has been setup
if not os.getenv('IE3D_HOME',False):
  print 'Make sure \"The Hyperlynx Software\" has been setup with correct $IE3D_HOME variable and respective License'
  exit(1)

## check if i2iFile was given and if it exists
if args.i2iFile:
  if os.path.isfile(args.i2iFile): # get the file and version
    i2iFGiven = os.path.realpath(args.i2iFile); i2iFFName = (os.path.split(i2iFGiven))[1]; givenSkew = re.search('(lowQ|typQ|highQ)',i2iFFName)
    if givenSkew: args.skew = givenSkew.group(1)
    else:args.skew = 'givenSkew'
    i2iVer = re.search(r'(x\d+r\d+(?:v\d+)?)',i2iFFName);
    i2iVer = i2iVer.group(1) if i2iVer else 'unknown'
  elif re.search(r'(x\d+r\d+(?:v\d+)?)',args.i2iFile): #check if the given is a version to use
    i2iVer = re.search(r'(x\d+r\d+(?:v\d+)?)',args.i2iFile).group(1)
  else: raise IOError('The given i2iFile does not exists')     #neither a version nor a file
else: i2iVer = os.getenv('UPF_MODELS_REVISION') #trust the environment for the version
print 'Using ' + i2iVer

## create dirs and log file
if args.outDir: geoDir = args.outDir; map(createDir, [geoDir])
else: geoDir = '.' 
logData = logData2 = i2iLogData = ''

## create temp Dir
tempDir = tempfile.mkdtemp(dir=geoDir)
print '\n\nThe working directory is: ' + tempDir

## fix the skew input if given
if type(args.skew) == str:
  args.skew = [args.skew]

## number expr for the file
numExp = '(\d+(?:p\d+)?)'

## list all the files and copy them into the temp folder
listOfFiles = args.gdsFiles; onceRun = False; batchGdsFid = {}
for iiFile in listOfFiles:
  if not os.path.exists(iiFile) or not os.path.isfile(iiFile): 
    logData += 'INFO: The gds file'+iiFile+' does not exist or is a directory\n'; print 'INFO: The gds file'+iiFile+' does not exist or is a directory'
    continue
  iiFilePath = os.path.realpath(iiFile)
  iiFileName = os.path.splitext(os.path.basename(iiFile))[0]
  iiFileExt = os.path.splitext(iiFile)[1]
## get only the gds
  if iiFileExt == '.gds':
    onceRun = True
## get the number of turns value
    test = re.search(r'[0-9a-z]+_+'+numExp+'n',str.lower(iiFileName))
    if test: nrturns = str(int(float(pToDot(test.group(1),dirMode='toDot')))) # remove decimals
    else: nrturns = str(6) # use six as default for non scalable stuff
## create the gds file accordingly, one set of five (each turn) foreach skew.           
    for iiSkew in args.skew:
      cFileKeyName = iiFileName + '_' + iiSkew
## Skip if there is a geo/sim file pair already created
      if os.path.exists(geoDir + '/' + cFileKeyName + '.sim') and os.path.exists(geoDir + '/' + cFileKeyName + '.geo'):
        logData += 'Skipping ' + cFileKeyName + ' since it already exists in geoFolder\n'
	continue
## create links to each gds for low, typ and high skews    
      os.symlink(iiFilePath, tempDir + '/' + cFileKeyName + iiFileExt)
## if the file is not created, create it in batchGdsFid variable with handles to it      
      if iiSkew + '_' + nrturns + 'N' not in batchGdsFid: 
        batchGdsFid.update({iiSkew + '_' + nrturns + 'N':open(tempfile.mkstemp(prefix=iiSkew + '_' + nrturns + 'N', suffix='.txt',dir=tempDir)[1],'w')})
## create gds symbolic links to convert and add them to the file
      if not os.path.exists(tempDir + '/' + cFileKeyName + iiFileExt): os.symlink(iiFilePath, tempDir + '/' + cFileKeyName + iiFileExt)
      batchGdsFid[iiSkew + '_' + nrturns + 'N'].write(cFileKeyName + iiFileExt + '\n')

## close the gdsBatch files
batchGdsFiles = []
for iiKey in batchGdsFid.keys():
  batchGdsFiles.append(batchGdsFid[iiKey].name)
  batchGdsFid[iiKey].close()
  
## convert and copy the sim and geo files to the output destination
for iiBatchFile in batchGdsFiles:
## select i2iFile 
  iiBatchFileName = os.path.splitext(os.path.split(iiBatchFile)[1])[0]
  test = re.search(r'^([a-z]+)\D*(\d+)n', iiBatchFileName, flags=re.I)
  if args.i2iFile and os.path.isfile(args.i2iFile): 
    if not os.path.isfile(tempDir + '/' + i2iFFName): os.symlink(i2iFGiven,tempDir + '/' + i2iFFName); #skip if created
    i2iFile = i2iFFName ## if an i2iFile was given
  elif test: i2iFile = getI2iFile(test.group(2), test.group(1), tempDir) ; ## i2iVer is valid (from args.i2i calculated above) or default
  else: i2iFile = getI2iFile('6','typQ', tempDir) ;
  if not os.path.isfile(tempDir+'/'+i2iFile): raise IOError('The given i2iFile does not exists:'+i2iFile)
#debug  continue
## run Hyperlynx to convert to geoFiles
  if i2iFile and os.path.exists(tempDir + '/' + i2iFile):
    runTest = subprocess.Popen('cd ' + tempDir + '; ' + 'start_app gds2geo.sh ' + i2iFile + ' ' + iiBatchFile, stdout=subprocess.PIPE, shell=True)
    runError = runTest.communicate()
    if os.path.exists(tempDir+'/'+os.path.splitext(i2iFile)[0]+'.log'): # read the log
      with open(tempDir+'/'+os.path.splitext(i2iFile)[0]+'.log') as i2iLogFid: 
        i2iLogData += i2iLogData + '##############\n' + i2iLogFid.read()
  else: 
    logData += 'ERROR: ' + i2iDir + '/' + i2iFile + ' does not exists\n'
    continue
## read the file to copy the created geo and sim files
  iiBatchFid = open(iiBatchFile)
  for line in iiBatchFid:
    cFileName = os.path.splitext(line.rstrip('\n'))[0]
    if os.path.exists(tempDir + '/' + cFileName + '.geo'):
      subprocess.call('cp ' + tempDir + '/' + cFileName + '.geo ' + geoDir, shell=True)
      logData2 += cFileName + '.geo generated successfully (from: '+i2iFile+')\n'
    else:
      logData += 'ERROR: ' + cFileName + '.geo was not generated : ' + runError[0] + '\n'
    if os.path.exists(tempDir + '/' + cFileName + '.sim'):
      subprocess.call('cp ' + tempDir + '/' + cFileName + '.sim ' + geoDir, shell=True)
      logData2 += cFileName + '.sim generated successfully\n'
    else:
      logData += 'ERROR: ' + cFileName + '.sim was not generated : ' + runError[0] + '\n'
    if os.path.exists(tempDir + '/' + cFileName + '.err'):
      subprocess.call('cp ' + tempDir + '/' + cFileName + '.err ' + geoDir, shell=True)  
  iiBatchFid.close()

## check, close, and clean up
if not onceRun: 
  print 'INFO: None of the files were valid or did not exist'
  logData += 'INFO: None of the files were valid or did not exist\n'

## Close the log file and append any files from the run
if args.logFName:
  args.logFName = args.logFName if type(args.logFName) == str else 'gdsToGeo.log'
  with open(args.logFName, 'w') as logFid: 
    logFid.write(logData); logFid.write(i2iLogData); logFid.write(logData2)

## Erase the directory after python finishes
subprocess.call('sleep 15 && rm -rf '+ tempDir + '&', shell=True)
exit(0)

