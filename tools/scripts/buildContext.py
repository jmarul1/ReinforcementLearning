#!/usr/bin/env python3.7.4
##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2016, Intel Corporation.  All rights reserved.               #
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
#   Type >> buildContext.py -h 
##############################################################################

def getSkillFiles(path,followlinks=True):
  if not os.path.exists(path): raise IOError('path does not exist: '+path)
  if os.path.isfile(path): files = [[os.path.relpath(path)]]
  else: files = [[os.path.relpath(root+'/'+x) for x in ff] for root,dirs,ff in os.walk(path) if ff]
  return [ff for ff in itertools.chain(*files) if os.path.splitext(ff)[1] in ['.il','.ils']]
  
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, subprocess, itertools
argparser = argparse.ArgumentParser(description='Build the context files, uses the name of input')
argparser.add_argument(dest='skillFiles', nargs='+', type=getSkillFiles, help='.il/.ils file(s)')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
duplicates=[]
for ff in set(itertools.chain(*args.skillFiles)):
  name,ext = os.path.splitext(ff)
  name = os.path.basename(name)
  if name in duplicates: sys.stderr.write('###########\n###########\nDuplicate found, context re-created from: '+ff+'\n###########\n###########\n')
  duplicates.append(name)
  cmd = 'buildContextExe.py -s '+ext+' -c '+name+' -- '+ff  
  subprocess.call(cmd,shell=True)

