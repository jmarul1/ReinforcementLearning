#!/usr/bin/env python2.7
##############################################################################
# Intel Top Secret							     #
##############################################################################
# Copyright (C) 2015, Intel Corporation.  All rights reserved.  	     #
#									     #
# This is the property of Intel Corporation and may only be utilized	     #
# pursuant to a written Restricted Use Nondisclosure Agreement  	     #
# with Intel Corporation.  It may not be used, reproduced, or		     #
# disclosed to others except in accordance with the terms and		     #
# conditions of such agreement. 					     #
#									     #
# All products, processes, computer systems, dates, and figures 	     #
# specified are preliminary based on current expectations, and are	     #
# subject to change without notice.					     #
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################


## Create the table for scalable model

def checkFile(path):
  if os.path.isfile(path): 
    if re.search(r'\.s\d+p$',path,flags=re.I): return os.path.realpath(path)
    else: return False
  else: raise argparse.ArgumentTypeError('File doesn\'t exist: '+path)

def getDevSpecs(name):
  """returns the dimension based on the name for ind_scl, otherwise just the name; 
  returns a tuple with the headers/name and tuple of the values/name (no extensions allowed)"""
  import re,math
  devTest = re.search(r'''^(?:\w)8(?:\d)\w+?		# get the project and dot process but dont capture
                     (symmetrical|spiral|symm)\w*?	# get the shape
                     (tm\d+|m\d+)\w+?             	# get the top layer
                     ''',name,flags=re.I|re.X)
  dimTest = [re.search(r'_(\d+(?:p\d+)?)'+ii+'[io]?'+('_?' if ii=='y' else '_'),name,flags=re.I) for ii in 'nswdy'] ## dimensions n s w d y
  heads = ('Shape','TopMetal','N','S','W','Di','Do','Y')
  if devTest and all(dimTest): 
    N,S,W,Di,Y = [float(re.sub('p','.',ii.group(1))) for ii in dimTest]; Neff = math.ceil(N)
    Do = Di + 2*W*Neff + 2*S*(Neff-1) 
    return heads,devTest.groups()+tuple([N,S,W,Di,Do,Y])
  else: return ('file',),(name,)

class xDict:
  def __init__(self):
    self.data = {}
    self.keys = []
  def append(self,key,newElement):
    if key not in self.data: self.data[key] = []; self.keys.append(key)
    self.data[key].append(newElement)
  def __iter__(self):
    self.index = 0
    return self
  def next(self):
    if self.index == len(self.data): raise StopIteration
    else: self.index+=1; return self.data[self.keys[self.index-1]]

def sumSps(spFiles,device='ind'):
  import sys; sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
  import sparameter as sp, numpy as np
  passive = 'L' if device=='ind' else 'C'
  valM1,valM2=xDict(),xDict(); specM1,specM2=xDict(),xDict();
  for iiFile in spFiles:
    fileName,ext = os.path.splitext(os.path.basename(iiFile))
    ## read the sparameter file and check for SRF
    sparam = sp.read(iiFile)
    srf = sparam.getSRF()
    if srf['diff'] == False: print >> sys.stderr,'Sparam must reach differential SRF:'+iiFile; continue
    ## get the name into N S W D Y Shape if possible and create the spec matrix
    specs = getDevSpecs(fileName)
    if len(specs[0]) == 1: workSpecM = specM1; workValM = valM1
    else: workSpecM = specM2; workValM = valM2
    [workSpecM.append(ii,jj) for ii,jj in zip(*specs)]    
    ## Get all the values
    if device == 'cap': Qd,Pd,Qse,Pse,Rd,Rse = sparam.getQCR()
    else: Qd,Pd,Qse,Pse,Rd,Rse = sparam.getQLR()   
    ## find the Peaking Qd,Qse, freqPeak and DC values for the passive, and put them in the matrix
    QdPeak,QsePeak = max(Qd[:sparam.freq.index(srf['diff'])]),max(Qse[:sparam.freq.index(srf['se'])])   
    FdPeak,FsePeak = sparam.freq[Qd.index(QdPeak)],sparam.freq[Qse.index(QsePeak)]
    workValM.append('QdPeak',QdPeak); workValM.append(passive+'dDc',Pd[0]); workValM.append('RdDc',Rd[0]); 
    workValM.append('FdPeak',FdPeak); workValM.append('SRFd',srf['diff']); 
    workValM.append('QsePeak',QsePeak); workValM.append(passive+'seDc',Pse[0]); workValM.append('RseDc',Rse[0])
    workValM.append('FsePeak',FsePeak); workValM.append('SRFse',srf['se']); 
  ## sort the spec matrices and create the data frame output for each matrix
  workTbl = [ii for ii in ([specM1,valM1],[specM2,valM2]) if any(ii[0].keys)]
  dFLst = []
  if any(workTbl):
    for workSpecM,workValM in workTbl:
      iSort = np.lexsort([workSpecM.data[key] for key in reversed(workSpecM.keys)])
      dF = {'__keys__':workSpecM.keys+workValM.keys};  
      for key in workSpecM.keys: dF[key] = tuple(workSpecM.data[key][ii] for ii in iSort)
      for key in workValM.keys: dF[key] = tuple(workValM.data[key][ii] for ii in iSort)
      dFLst.append(dF)      
  return dFLst

def toStr(floatNum): 
  output = str(int(floatNum)) if type(floatNum)==float and (int(floatNum)-floatNum==0) else str(floatNum); 
  return output  

if __name__ == '__main__':
##############################################################################
# Argument Parsing
##############################################################################
  import argparse, os, sys, subprocess as sb, tempfile, re
  argparser = argparse.ArgumentParser(description='Creates a table with Q/LC/R/F characteristics for a sparameter file(s)')
  argparser.add_argument(dest='spFiles', nargs='+', type=checkFile, help='sparameter file(s)')
  argparser.add_argument('-csv', dest='csvFile', nargs='?',const=True, help='store results in a csv file with the prefix name given or by default "summary_Sps.csv')  
  args = argparser.parse_args()
##############################################################################  
  dFLst = sumSps(filter(lambda ff: ff != False,set(args.spFiles)))
  results = ''
  for dF in dFLst:
    results += ','.join(dF['__keys__'])+'\n'
    for ii in range(len(dF[dF.keys()[0]])):
      results += ','.join(toStr(dF[jj][ii]) for jj in dF['__keys__'] if jj in dF.keys())+'\n'
    results += '\n'
## if csv enable print values in csv file ## else print to the prompt
  if args.csvFile:
    with open(args.csvFile+'.csv'if type(args.csvFile)==str else 'summary_Sps.csv','wb') as fOut: fOut.write(results)
  else: print(results)


