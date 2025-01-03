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
#   Type >> simGeoFiles.py -h
#
##############################################################################

def checkInput(path):
  if os.path.isfile(path): 
    if os.path.splitext(path)[1].lower()=='.sim': return os.path.realpath(path)
    else: return False
  else: raise argparse.ArgumentTypeError('File doesn\'t exist: '+path)

def createDir(path):
  if not os.path.exists(path):
    os.makedirs(path)

def findPortNum(simFile):
  with open(simFile) as fid: test = re.search(r'\bports?\s*=\s*\"\s*(\d+)\s*\"',fid.read()) 
  if test: return test.group(1)
  else: return False

##############################################################################
# Argument Parsing
##############################################################################
import os, tempfile, re, subprocess, sys, argparse
argparser = argparse.ArgumentParser(description='This program uses Hyperlynx (already running) to run all *.sim/*.geo file pairs in the given directory.')
argparser.add_argument(dest='simFiles', nargs='+', type=checkInput, help='Sim Files (The files must exists as *.sim/*.geo pairs in the same directory)')
argparser.add_argument('-batch', dest='batch', action='store_true',help='This options activates the batch usage')
argparser.add_argument('-outdir', dest='outDir', help='This options lets you specify the output directory, otherwise is either in the scl structure or the current dir')
argparser.add_argument('-log', dest='logFName', nargs='?', const = True, help='This options enables a log script of the actions taken running the script')
args = argparser.parse_args()
##############################################################################

##############################################################################
# Main Begins
##############################################################################

## Create inputs
args.simFiles = filter(lambda ff: ff != False,args.simFiles)
if not any(args.simFiles): raise IOError('No sim files were found in the input')

# Create output directories
snpDir = args.outDir if args.outDir else '.'
createDir(snpDir)

## create temp Dir
tempDir = tempfile.mkdtemp(dir='.')
print '\n\nThe working directory is: ' + tempDir

## change command depending on the batch preference and distributed simulations
h3DWrapper = 'rideIE3DWrapperNB ' if args.batch  else 'ie3dLocalDistSim.sh '

## run simulations
onceRun = False; logData = logData2 = ''
for simFile in args.simFiles:
  srcDir = os.path.dirname(simFile)
  iiFile = os.path.basename(simFile) 
  iiFileName = os.path.splitext(iiFile)[0]
  iiFileExt = os.path.splitext(iiFile)[1]
  if os.path.isfile(srcDir + '/' + iiFileName + '.geo'):
## if sparameter already exists skip it
    portNum = findPortNum(simFile)
    if portNum and os.path.isfile(snpDir + '/' + iiFileName + '.s'+portNum+'p'):
      logData2 += 'Skipping ' + iiFileName + ' since it already exists in sparam Folder\n'
      continue
## create links in the temp folder and simulate
    os.symlink(srcDir + '/' + iiFileName + '.geo', tempDir + '/' + iiFileName + '.geo')
    os.symlink(srcDir + '/' + iiFileName + '.sim', tempDir + '/' + iiFileName + '.sim')
## make sure hyperlynx has been setup
    if not os.getenv('IE3D_HOME',False): raise EnvironmentError('Make sure \"The Hyperlynx Software\" has been setup with correct $IE3D_HOME variable and respective License')
## run hyperlynx wrapper for distributed simulations
    runTest = subprocess.Popen('cd ' + tempDir + '; start_app ' + h3DWrapper + iiFile, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    #runTest = subprocess.Popen('cd ' + tempDir + '; ls',stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell = True)
    runError = runTest.communicate()
    outputFile = tempDir + '/' + iiFileName + '.s'+portNum+'p'
    if os.path.isfile(outputFile):
      subprocess.call('cp '+outputFile+' '+snpDir,shell=True);
      logData2 += iiFile+' ran successfully\n'; print 'INFO: Success running '+iiFile
    else:
      logData += '--ERROR: '+iiFile+':'+runError[0]+runError[1]+'\n'
  else:
    logData += '-- Warning: file \"%s\" does not have corresponding \"%s.geo\" file\n' % (iiFile, iiFileName)
  with open(tempDir+'/currentSimGeoFiles.log','w') as tempLog: tempLog.write(logData+logData2)

## print log and clean up
if args.logFName:
  args.logFName = args.logFName if type(args.logFName) == str else 'simGeoFiles.log'
  with open(args.logFName, 'w') as logFid: logFid.write(logData+logData2)
else: print logData  
subprocess.call('sleep 5 && rm -rf '+ tempDir + '&', shell=True)
exit(0)
