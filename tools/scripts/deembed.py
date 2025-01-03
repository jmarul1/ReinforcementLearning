#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

def deembSingleMatlab(spFile,shorts=None,opens=None,thrus=None):
  import sys, os
  if not any([shorts,opens,thrus]): sys.stderr.write('Skipping dut (nothing to deembed): '+os.path.basename(spFile)+'\n'); return 0
  spFileBase,spFileExt = os.path.splitext(os.path.basename(spFile))
  outFile = spFileBase+'_De'+('Op' if opens else '')+('Sh' if shorts else '')+('Th' if thrus else '')+spFileExt
  cmd = ["deembedmm('"+spFile+"'"]
  cmd += ["'opens','"+opens+"'" if opens else ""]+["'shorts','"+shorts+"'" if shorts else ""]+["'thrus','"+thrus+"'" if thrus else ""]
  cmd = [ff for ff in cmd if ff != '']
  cmd = (','.join(cmd))+",'outFileName','"+outFile+"');"
  return cmd

def deembSingleRide(spFile,shorts=None,opens=None,thrus=None):
  import os, subprocess
  cmd = ['/nfs/site/eda/group/SYSNAME/tcad/RFDesigner/ride/ride -device='+spFile]
  cmd += ['-open='+opens if opens else '']+['-shorts='+shorts if shorts else '']
  spFileBase,spFileExt = os.path.splitext(os.path.basename(spFile))
  outFile = spFileBase+'_De'+('Op' if opens else '')+('Sh' if shorts else '')+spFileExt
  cmd += ['-output='+outFile]
  cmd = (' '.join(cmd))+';'
  return cmd

def getDeemb(dut,deembFiles): #return one file with the 
  import re, sys
  if deembFiles == None: return None #if there is no file
  elif len(deembFiles) <=1: return deembFiles[0] # if there is only one
  else:
    test = re.search(r'^(X-?\d+Y-?\d+)',os.path.basename(dut),flags=re.I)
    if not test: sys.stderr.write('Skipping dut (no die information): '+os.path.basename(dut)+'\n'); return None #if no die in the pattern skip
    die = test.group(1)
    # search the deembFiles for the one with the die
    test = [ff for ff in deembFiles if re.search(r''+die,os.path.basename(ff),flags=re.I)]
    if not test: sys.stderr.write('Skipping dut (no matchin open with die information): '+os.path.basename(dut)+'\n'); return None #if no die in the pattern skip    
    return test[0]
    
def checkInput(spFile):
  import subprocess, sparameter
  if os.path.exists(spFile) and re.search(r'\.(s\d+p|c.?ti)$',os.path.splitext(spFile)[1],flags=re.I):
    subprocess.call('dos2unix '+spFile, stderr = subprocess.PIPE, shell = True)
    if not re.search(r'\.s\d+p',os.path.splitext(spFile)[1],flags=re.I): spFile = sparameter.citiToTs(spFile)
  else: raise IOError('Sparameter file '+spFile+' either does not exists or is not an sparameter file')
  return os.path.abspath(spFile)  

##############################################################################
# Argument Parsing
##############################################################################
import sys, re, math, argparse, os, tempfile, subprocess
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import sparameter as sp, numtools
argparser = argparse.ArgumentParser(description='Deembed sparameters')
argparser.add_argument(dest='spFile', nargs = '+', type=checkInput, help='Raw sparameter file(s)')
argparser.add_argument('-thrus', dest='thrus', nargs = '+', type=checkInput, help='Thrus sparameter file(s)')
argparser.add_argument('-shorts', dest='shorts', nargs = '+', type=checkInput, help='Shorts sparameter file(s)')
argparser.add_argument('-opens', dest='opens', nargs = '+', type=checkInput, help='Opens sparameter file(s)')
argparser.add_argument('-ride', dest='ride', action='store_true', help='Use Ride instead MATLAB (only works for s2p files in the same directory)')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
results = []
## run for each sparameter specified 
for iiSpFile in args.spFile:
  ## decide the deembedding
  shorts = getDeemb(iiSpFile,args.shorts)
  opens =  getDeemb(iiSpFile,args.opens)
  thrus =  getDeemb(iiSpFile,args.thrus)
  ## deembed
  if args.ride: results.append(deembSingleRide(iiSpFile,shorts,opens,thrus))
  else: results.append(deembSingleMatlab(iiSpFile,shorts,opens,thrus))
## create the file to run
if args.ride:
  outFile = tempfile.mkstemp(prefix='ride_',suffix='.csh')[1]
  with open(outFile,'w') as fout: fout.write('\n'.join(results))
  print(outFile)
else:
  outFile = tempfile.mkstemp(prefix='deemb_',suffix='.m',dir='.')[1]
  with open(outFile,'w') as fout: fout.write('\n'.join(results)+('\nexit\n'))
  print('Running Matlab '+outFile)
  ## run matlab
  script = os.path.splitext(os.path.basename(outFile))[0]
  subprocess.call('\matlab -nosplash -noFigureWindows -r '+script,shell=True)
exit(0)
