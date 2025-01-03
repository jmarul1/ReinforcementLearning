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
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> icvlvl.py -h 
##############################################################################

def checkGds(path):
  if os.path.isfile(path):
    if os.path.splitext(path)[1] == '.gds': return os.path.realpath(path)
    else: return False
  else: raise argparse.ArgumentTypeError('File doesn\'t exist or is a directory: '+path)

def getProject(): import os; return {'fdk73':'1273','fdk71':'1271','f1275':'1275'}.get(os.getenv('PROJECT'))  
  
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, shutil, subprocess
project = getProject()
argparser = argparse.ArgumentParser(description='Runs ICV or DBDIFF for two gds, it assumes the name of the gds is the cell name')
argparser.add_argument(dest='gds', nargs=2, type=checkGds, help='two gds files')
argparser.add_argument('-tool', dest='tool',default='icv_lvl', choices = ['dbdiff','icv_lvl'],help='tool to use, defaults to ICV_LVL')
argparser.add_argument('-lf', dest='lf', default = os.getenv('INTEL_RUNSETS')+'/PXL/'+project+'/p'+project+'dx_icv_lvl_assign.rs', help='layer file, defaults to current $ISSRUNSET')
#argparser.add_argument('-text', dest='text', action='store_true', help='icv_lvl text comparison')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################

## Error checking and flow fixing
if not os.path.isfile(args.lf) and args.tool == 'icv_lvl': raise argparse.ArgumentTypeError('Not a valid layer file from the runset present')
## Prepare the files and cells
gds1,gds2 = args.gds
cell1,cell2 = map(lambda ff: os.path.basename(os.path.splitext(ff)[0]),args.gds)
report =  '_'.join(['xor_'+args.tool,cell1,cell2])+'.log'
if args.tool == 'icv_lvl':
  ## Prepare working dir
  workDir = 'xor_'+args.tool+'.'+cell1+'_'+cell2; 
  if not os.path.exists(workDir): os.mkdir(workDir) ## asume you have written permissions 
  else: subprocess.call('chmod -R +w '+workDir+' ; rm -rf '+workDir,shell=True); os.mkdir(workDir)
  cmd = ' '.join(['icv_lvl',gds1,gds2,'-lf',args.lf,'-c1',cell1,'-c2',cell2,'-text']) 
  print cmd;  result = subprocess.call('cd '+workDir+';'+cmd,shell=True) ## run the command
  if not result: subprocess.call('cp '+workDir+'/*LVL_ERRORS '+report,shell=True)
else:
  cmd = ' '.join(['dbdiff','-system GDS -refsystem GDS','-design',gds1,'-refdesign',gds2,'-report',report])
  print cmd;  result = subprocess.call(cmd,shell=True) ## run the command
