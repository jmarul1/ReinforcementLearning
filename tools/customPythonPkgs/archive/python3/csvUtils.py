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
#   Useful functions for working with csv files
#
##############################################################################
def dFrame(csvFile,text=True):
  """Read the csv"""
  import csv,re,numtools,collections,io
  if isinstance(csvFile,io.IOBase): ## file already open, flush it and reset to zero
    csvFile.flush(); csvFile.seek(0); fIn = csvFile  
  else: fIn = open(csvFile)
  dataF = collections.OrderedDict()
  for line in csv.reader(fIn):
    if not re.search(r'^\s*#|^\s*$',' '.join(line)): #ignore empty lines or beginning with #
      if re.search(r'#',' '.join(line)): # replace line with cell entries until cell starting with #
        newLine = []
        for cell in line:
          if re.search(r'^#',cell.strip()): break
          newLine.append(cell)
        line = newLine
      if not (numtools.isNumber(line[0]) or any(dataF)): # if found the header STORE HEADER
        headers = [] # keep the headers in order for reference later
        for cc,vv in enumerate(line):
          vv = (re.sub(r'#.*','',vv)).strip();
          if vv: dataF[vv]=[];                    headers.append(vv)
          else:  dataF['NH_'+str(cc+1)]=[];       headers.append('NH_'+str(cc+1))
      else:
        if any(dataF):  ## headers have been stored
          for cc,vv in enumerate(line):
            if cc < len(headers): #only store up to the header count
              vv = (re.sub(r'#.*','',vv)).strip();
              if text==True: dataF[headers[cc]].append(vv) # store the string if text is selected
              elif numtools.isNumber(vv): dataF[headers[cc]].append(float(vv)) # if there is a numeric value convert to float
              elif text=='both': dataF[headers[cc]].append(vv) # store the string if its not a number
              else: dataF[headers[cc]].append(0.) # store zero if non-numeric and text=False
          if len(line) < len(headers): # headers with no value at this row location place a zero or empty string
            for rr in range(cc+1,len(headers)):
              if text: dataF[headers[rr]].append('') # store the string
              else: dataF[headers[rr]].append(0.)
        else: raise IOError('Could not generate headers : '+csvFile)
  if not any(dataF): raise IOError('File has no data : '+csvFile)
  return dataF

def toStr(dataF,givenKeys=[],lst=False,**kArgs):
  dL = '"' if kArgs.get('useQuotes',False) else ''
  keyLst = givenKeys if any(givenKeys) else dataF.keys()   
  resultStr = [','.join((dL+kArgs.get(kk,kk)+dL) for kk in keyLst)]
  longest = max([len(jj) for ii,jj in dataF.items()])
  for rr in xrange(longest):
    resultStr.append(','.join(dL+str(dataF[key][rr]+dL) for key in keyLst))
  if lst: return resultStr
  else: return '\n'.join(resultStr)

def strToDict(csvString):
  import tempfile
  scratch = tempfile.TemporaryFile(mode='w+')
  scratch.write(csvString)
  return dFrame(scratch,text=True)

def targetFiles(path):
  """Summarize in a list the files meeting the criteria of the full path"""
  import os, re
  lstFiles = []; ext = '.csv'
  if os.path.isdir(path):
    lstFiles = os.listdir(path); lstFiles = filter(lambda ff: re.search('\\'+ext+'$',ff,flags=re.I), lstFiles); 
    if any(lstFiles): lstFiles = [path+'/'+ii for ii in lstFiles]; lstFiles = map(os.path.normpath,lstFiles); 
  elif os.path.isfile(path): 
    if os.path.splitext(path)[1]==ext: lstFiles = [path]
  else: raise argparse.ArgumentTypeError('File or Dir doesn\'t exist: '+path)
  return lstFiles

def sortDict(dTbl,keys):
  """ Sort the dictionary based on the keys """
  import numpy, collections 
  effKeys = keys[:]; effKeys.reverse()
  matrix = [dTbl[jj] for jj in effKeys if jj in dTbl.keys()]
  indxs = numpy.lexsort(matrix)
  newTbl = collections.OrderedDict()
  for nn in indxs:
    for kk in dTbl.keys(): 
      if kk not in newTbl.keys(): newTbl[kk] = [] 
      newTbl[kk].append(dTbl[kk][nn])
  return newTbl

def appendCsvDicts(csvDictLst):
  """The dict must have the same number of keys"""
  newDict = {}
  for key,item in csvDictLst[0].items():
    if type(item) == dict:
      for iiDict in csvDictLst: newDict.update(iiDict)
    else:
      newDict[key] = []
      for iiDict in csvDictLst:
        newDict[key] += iiDict[key]
  return newDict

def _filter(csvDt,keyDt,tgtK):
  """Gets the values matching keyDt from csvDt, The keyDt must have valid keys"""
  for kk in keyDt.keys()+[tgtK]:   ## are all keys and tgtK part of the csvDt
    if kk not in csvDt.keys(): raise IOError('Not all keys are part of the csvDt')
  tgtLst = []
  for ii,val in enumerate(csvDt[tgtK]):
    if all(map(lambda kk: csvDt[kk][ii]==keyDt[kk], keyDt.keys())): tgtLst.append(csvDt[tgtK][ii])
  return tgtLst

def filterBasedOnIndex(csvDt,indeces):
  """ Reduce the Dict based on the indeces given """
  import collections
  newDt = collections.OrderedDict(); length = len(csvDt[csvDt.keys()[0]]); 
  for kk in csvDt.keys(): newDt[kk]=[] 
  for ii in indeces:
    if ii < length:
      for kk in newDt.keys(): newDt[kk].append(csvDt[kk][ii])
  return newDt
