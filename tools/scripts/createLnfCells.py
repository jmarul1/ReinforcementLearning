#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

def chkLnf(lnf):
  import os
  lnf = os.path.splitext(lnf)
  if lnf[1] != '.lnf': raise argparse.ArgumentTypeError('File is not an LNF: '+lnf)
  else: return lnf[0]

def createMasterTag(filePath):
  with open(filePath,'wb') as fout: 
    fout.write('-- Master.tag File, Rev:1.0\nlnf.dat\n')
    
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, subprocess, sys
argparser = argparse.ArgumentParser(description='Create LNF Cells to be checked in')
argparser.add_argument(dest='lnfs', nargs='+', type=chkLnf, help='lnf file(s)')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))

## run for each lnf specified 
for iiLnfFile in args.lnfs:
  if os.path.isdir(iiLnfFile): #remove the directory   
    cmd = 'rm -rf '+iiLnfFile
    subprocess.call(cmd,shell=True)
  #create the files    
  cmd1 = 'mkdir -p '+iiLnfFile+'/lnf'
  cmd2 = 'cp '+iiLnfFile+'.lnf '+iiLnfFile+'/lnf/lnf.dat'
  subprocess.call(cmd1,shell=True)
  subprocess.call(cmd2,shell=True)
  createMasterTag(iiLnfFile+'/lnf/master.tag')
exit(0)
