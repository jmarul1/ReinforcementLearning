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

def getIncludes(sim,project,skew,core=False):
  import os
  mainDir = os.getenv('INTEL_PDK')+'/models/'+('spectre' if sim=='scs' else 'hspice')
  if sim=='scs': dot=''; section = ['include','section='+skew]
  else: dot='.'; section = ['.lib',skew]
  includes = dot+'include "'+mainDir+'/custom/intel'+project+'custom.'+sim+'"\n' 
  if sim == 'hsp': includes += '.include "'+mainDir+'/core/hspice_options"\n'        
  corePath = os.path.realpath(mainDir+'/core/p12'+project+'_'+os.getenv('FDK_DOTPROC')+'_var.'+sim if core == False else core)
  upfVersion = getUpfVersion(corePath)
  includes += section[0]+' "'+os.path.realpath(corePath)+'" '+section[1]+'\n'
  if project == '73' and (skew not in ['bghp','bglp','bglp1']): includes += section[0]+' "'+mainDir+'/custom/intel73customwrapper.'+sim+'" '+section[1]+'\n'
  return includes,upfVersion

def checkSub(name,files):
  import os, re
  for ff in files.split('\n'):
    if ff.strip() == '': continue
    ff = (ff.split(' ')[1]).strip('"')
    if not os.path.isfile(ff): continue
    with open(ff) as fid: 
      for line in fid:
        if re.search(r'^\s*.?subckt\s+'+name+'\s+',line,flags=re.I): return True
  return False

def readInc(txt):
  with open(txt) as fid: includes = fid.readlines()
  includes = filter(lambda ff: not(re.search(r'^\*|^\s*$',ff)), includes)
  if not(includes): raise IOError('Invalid include file')
  return ''.join(includes)

def getUpfVersion(core):
  import re, os
  test = re.search(r'/core/(x\d+r\w+)',core,flags=re.I)
  if test: return test.group(1)
  else: #try getting it from the file
    test = re.search(r'(x\d+r[a-z0-9]+)',os.path.basename(core),flags=re.I)
  return test.group(1) if test else 'unknown'

def getParam(data,paramExp,mc):
  import re
  numExp = '([+-]?\d*(?:\.\d*)?(?:[eE][+-]?\d+)?)'; fetch = False; mcFetch = False; mcData={}; output = [[],[]]
  for line in data:
    test = re.search(r'temp\s*=\s*'+numExp,line,flags=re.I)
    if test: x=test.group(1); fetch=True; continue
    if fetch:
      if mc:
        if re.search(r'meas_variable\s*=\s*('+paramExp+')',line,flags=re.I): mcFetch=True
	if mcFetch:
	  test = re.search(r'(mean|sigma)\s*=\s*'+numExp,line,flags=re.I)
	  if test: mcData[test.group(1)] = test.group(2)
	  if len(mcData.keys())==2: output[0].append(x); output[1].append([mcData['mean'],mcData['sigma']]); mcFetch=False; mcData={}
      else:
        test = re.search(r'(?:'+paramExp+')\s*=\s*'+numExp,line,flags=re.I)
        if test: output[0].append(x); output[1].append(test.group(1)); fetch=False 
  return output
   
def createHspStr(includes,model,temps,tipo,monteCarlo=False):
  hspMC = '''
.variation
  option ignore_local_variation = no
  option ignore_global_variation = yes
  option other_percentile = percentile
.end_variation
.data percentile
  q
  0.0013
  0.0668
  0.9332
  0.9987
.enddata'''
  hspCommon = '''
.option MEASDGT=4 MEASFORM=1
.TEMP '''+(' '.join(map(str,temps)))+'''
.OPTION\n+    ARTIST=2\n+    INGOLD=2\n+    PARHIER=LOCAL\n+    PSF=2
.param dio_ie_val=10e-06
iEmit 0    emit dc=dio_ie_val'''
  hspBiasVeb = '''
vBase base 0    dc=0
xInst base emit 0 '''+model+'''
.TRAN 1e-12 3e-09 0'''+(' SWEEP MONTE=2001' if monteCarlo else '')+'''
.MEAS TRAN vemitbase AVG V(emit)\n'''
  hspBiasBeta = '''
rb    base 0    1e-3
rc    coll 0    1e-3
xInst base emit coll '''+model+'''
.TRAN 1e-12 3e-09 0'''+(' SWEEP MONTE=2001' if monteCarlo else '')+'''
.PROBE TRAN V(coll)
.PROBE TRAN V(base)
.MEAS  TRAN Icoll AVG V(coll)
.MEAS  TRAN Ibase AVG V(base)
.MEAS  TRAN gainbeta  param='Icoll/Ibase'\n'''
  return '\n'+includes+(hspMC if monteCarlo else '')+hspCommon+(hspBiasBeta if tipo=='beta' else hspBiasVeb)+'\n.END'
