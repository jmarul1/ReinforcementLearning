#!/usr/intel/bin/python2.7
##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2013, Intel Corporation.  All rights reserved.               #
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
#   Type >> matchNPortInd.py -h
#
##############################################################################

def checkFile(path):
  if os.path.isfile(path): 
    if re.search(r'\.s\d+p$',path,flags=re.I): return os.path.realpath(path)
    else: return False
  else: raise argparse.ArgumentTypeError('File doesn\'t exist or is a directory: '+path)
  
##############################################################################
# Argument Parsing
##############################################################################
import sys, os, tempfile, subprocess, re,shutil
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import sparameter as sp, netbatch as nb, argparse
argparser = argparse.ArgumentParser(description='This program matches sparameter to a given ckt netlist using RIDE')
argparser.add_argument(dest='spFiles', nargs='+', type=checkFile, help='Sparameter file(s)')
argparser.add_argument('-ckt', dest='cktFile', help='Circuit file used by ride to match the subckt defaults to environment ckt in /p/fdk/gwa/jmarulan/$PROJECT/work/utils/ckts')
argparser.add_argument('-remove', dest='remove', type=int, default=0, help='Offset negatively the frequency from the SRF')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################

## if possible put a skew
skew = re.search(r'(low|typ|high)Q',args.cktFile,flags=re.I)
suffixHelp = skew.group(1)+'Q' if skew else ''

## create temp Dir
tempDir = tempfile.mkdtemp(dir='.',prefix='match', suffix=suffixHelp)
print >> sys.stderr,'The working directory is: ' + tempDir
## start working
runRideLst=[]
for spFile in filter(lambda ff: ff != False,set(args.spFiles)):
  ## Check files exist
  if not os.path.isfile(spFile): raiseIOError('Given sparameter file does not exists:'+spFile)
  if args.cktFile and not os.path.isfile(args.cktFile): raiseIOError('Given circuit file does not exists:'+args.cktFile)
  ## get files ready 
  spFileName,spFileExt = os.path.splitext(os.path.basename(spFile))
  shutil.copy(spFile,tempDir+'/'+spFileName+spFileExt)
  sparam = sp.read(spFile)
  cktFile = os.path.join('/p/fdk/gwa/jmarulan',os.getenv('PROJECT'),'work/utils/ckts','indasymm'+str(sparam.portNum)+'t_individual.ckt') if not args.cktFile else os.path.realpath(args.cktFile)
  srf = sparam.getSRF()
  if srf['diff'] == False: print >> sys.stderr,'Sparam must reach differential SRF, skipping:'+spFile
  else:
  ## append the frequencies and put the files in the tempdir
    maxFreqI = sparam.freq.index(srf['diff']) - args.remove
    with open(cktFile) as fid: cktTmpl = fid.read()
    with open(tempDir+'/'+spFileName+'.ckt','wb') as fid: fid.write(cktTmpl+'\n.maxFreqIndex:'+str(maxFreqI))
    ## run ride command
    print >> sys.stderr,'Matching '+spFileName 
    rideCmd = 'cd '+tempDir+' ; /nfs/site/eda/group/SYSNAME/tcad/RFDesigner/ride/ride -match='+spFileName+spFileExt+' -circuit='+cktFile+' -output='+spFileName+'_ckt'+spFileExt+' > '+spFileName+'_match.log'
    runRideLst.append(tuple([spFileName,subprocess.Popen(rideCmd,shell=True)]))
## Wait for completion
for spFileName,runRide in runRideLst:
  runRide.communicate()
#  print spFileName,runRide
  if os.path.isfile(tempDir+'/'+spFileName+'.sp'):
    ## fix the model names inside the output netlist
    with open(tempDir+'/'+spFileName+'.sp') as fid: netlist = re.sub(r'_(low|typ|high)Q','',fid.read(),flags=re.I)
    with open(tempDir+'/'+spFileName+'.sp','wb') as foutId: foutId.write(netlist)
    ## change the netlist with n_ehv p_ehv and put it in 1273 fossil models format    
    subprocess.call('cd '+tempDir+'; /p/fdk/gwa/jmarulan/utils/scripts/convertSpFile.py '+spFileName+'.sp',shell=True)
    print >> sys.stderr,'\nFinished '+spFileName 
    subprocess.call('echo \"Finished '+spFileName+'\" >> matchRide.log',shell=True)
  else:
    print >> sys.stderr,'Something went wrong with Ride, check: '+tempDir+'/'+spFileName+'_match.log'
