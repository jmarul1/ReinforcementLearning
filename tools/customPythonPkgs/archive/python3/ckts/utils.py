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
#   Useful functions
#
##############################################################################

def getIncludes(sim,skew,incOvr=None):
  import os
  if sim=='scs': section = ['include','section='+skew]; fileP = os.getenv('SPECTRE_MODEL_FILE') if incOvr==None else incOvr
  else: section = ['.lib',skew]; fileP = os.getenv('PROJECT_UPF_FILE') if incOvr==None else incOvr
  includes = section[0]+' "'+fileP+'" '+section[1]
  return includes

def checkSub(name,files):
  import os, re
  for ff in files.split('\n'):
    if ff.strip() == '': continue
    ff = (ff.split(' ')[1]).strip('"')
    if not os.path.isfile(ff): continue
    with open(ff) as fid: 
      ext = os.path.splitext(ff)[1]
      regExp = 'subckt\s+'+name+'\s+'+'(.*)' if ext=='.scs' else 'model\s*=\s*"\s*'+name+'\s*"\s+numPorts\s*=\s*(\d+)'
      for line in fid:
        test = re.search(r'^\s*'+regExp,line,flags=re.I)
        if test: return test.group(1)
  return False

def getUpfVersion(path):
  import re, os
  test = re.search(r'/\d+(x\d+r\d+(?:..)?)/\w+$',path)
  if test: return test.group(1)
  else: 'unknown'

