#!/usr/bin/env python3.7.4
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
# Author:
#   Mauricio Marulanda
##############################################################################

def chkIn(num):
  import numtools
  num = numtools.getScaleNum(num)
  if numtools.isNumber(num): return num
  else: raise IOError('Provide numbers')

def simplify(csv):
  import subprocess, tempfile, re
  test=subprocess.Popen('grep -v -E -m 1 \'^\s*#\' '+csv,shell=True,stdout=subprocess.PIPE); test = test.communicate()[0]
  for ii,word in enumerate(test.split(',')):
    if re.search(r'Fd_f',word): ll=ii+1; break 
  tempF = tempfile.mkstemp()[1]
  locs = [ll,ll+1,ll-1,1,2,3,4,5] # locs = [16,17,15,1,2,3,4,5] # freq, ind, q
  locs = '$'+('","$'.join(map(str,locs)))
  with open(tempF,'wb') as fout: test = subprocess.Popen('awk -F , \'{print '+locs+'}\' '+csv,stdout=fout,shell=True); test = test.communicate()
  return tempF 
  
def getRange(val,spam):
  import math  
  floor,ceil = max(0,math.floor(val-spam)),math.ceil(val+spam)
  return range(int(floor),int(ceil)+1)

def matchLines(csv,freqLst,indLst):
  import subprocess, tempfile
  tempF = tempfile.mkstemp()[1]
  # nums to be follow by a "." or a "," (when there is no decimal)
  simple = lambda ff: str(ff)+'[\.,]'
  regexF = '\('+('\|'.join(map(simple,freqLst)))+'\)'; regexL = '\('+('\|'.join(map(str,indLst)))+'\)'
  extraCols = ''.join(['.*,' for ii in range(6)])
  regex = '^'+regexF+'.*,'+regexL+extraCols #freq....,ind....,
  with open(tempF,'wb') as fout:
    test = subprocess.Popen('grep \''+regex+'\' '+csv,stdout=fout,shell=True); test = test.communicate()
  return tempF

def simplifyQmin(dt):
  import collections
  newDt = collections.OrderedDict(); 
  for kk in dt.keys(): newDt[kk]=[]
  for line,qq in enumerate(dt['Q']):
    if float(qq) > args.inputs[2]:
      for kk in newDt.keys(): newDt[kk].append(dt[kk][line]) 
  return newDt

def closestNums(dt,key,value):
  import numpy
  value = float(value); numLst = dt[key]; 
  newLst = map(lambda ff: (ff[0],abs(float(ff[1]) - value)), enumerate(numLst));
  newLst = sorted(newLst,key=lambda ff: ff[1]); outLst,keys=[],[] 
  for index,freq in newLst:
    kk = '_'.join(dt[ii][index] for ii in dt.keys()[3:]);
    if kk not in keys: outLst.append([index,freq]); keys.append(kk)    
  ## filter based on tolerance in 0.1 steps until you have > 10 entries
  for tol in numpy.arange(0,1,0.05):
    newLst = filter(lambda ff: ff[1]<tol, outLst)
    if len(newLst) > 10: break     
  return [ii for ii,jj in newLst]

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, math, subprocess
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
import csvUtils, numtools
argparser = argparse.ArgumentParser(description='Find Dimensions of an inductor for given F/L/Q')
argparser.add_argument('-csv', dest='csvFile', default = '/nfs/pdx/disks/wict_tools/releases/EM_COLLATERAL/.inductorGuide.csv', help=argparse.SUPPRESS)
argparser.add_argument(dest='inputs', nargs='+', type=chkIn, help='List values as: freq(GHz) L(nH) minQualityFactor')
argparser.add_argument('-list', dest='list', default = 7, type = int, help=argparse.SUPPRESS)
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
freq = args.inputs[0]/1e9
## Read the file
freqs = getRange(args.inputs[0]/1e9,1)
csv = simplify(args.csvFile)                  # simplify to only three f,L,Q
ind = round(args.inputs[1]*1e9,2); inds = [numtools.numToStr(ind)] # work in nH with one decimal
csv = matchLines(csv,freqs,inds)                   # match only freqs with ind
if os.stat(csv).st_size == 0: raise IOError('Inductance out of coverage: '+str(args.inputs[1])+'H')
## match more closely
subprocess.call('sed -i \'1i freq,L,Q,shape,n,w,s,d\' '+csv, shell=True)
csv = csvUtils.dFrame(csv)
## minimum Qs
if len(args.inputs) > 2: csv = simplifyQmin(csv)
if len(csv['freq']) < 1: raise IOError('Qmin is too high, try decreasing: '+str(args.inputs[2]))
indeces = closestNums(csv,'freq',freq); 
## sort based on Ls
csv = csvUtils.filterBasedOnIndex(csv,indeces); csv = csvUtils.sortDict(csv,['L','Q'])
length = len(csv[csv.keys()[0]])
print('####')

for index in range(args.list):
  if not index < length: continue
  outputs = [csv[kk][index] for kk in csv.keys()]
  outStr = outputs[3]+'_'+outputs[4]+'n_'+outputs[5]+'w_'+outputs[6]+'s_'+outputs[7]+'d'
  f,l,q = map(lambda ff: numtools.numToStr(ff,3),outputs[0:3])
  outStr = 'L='+l+'(nH) '+'Q='+q+' @ '+f+'GHz : ' + outStr
  print(outStr)
print('####')



