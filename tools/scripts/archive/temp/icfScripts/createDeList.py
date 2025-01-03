#!/usr/bin/env python2.7
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
# Description:
#   Type >> createDeList.py -h 
##############################################################################

def makeKCaps(dictObj):
  output = {}
  for kk,vv in dictObj.items(): output[kk.upper()] = vv
  return output

def skipItem(test):
  test = test.strip()
  if not test: return False
  elif re.search(r'no\s*bias',test.lower()): return False
  else: return True
  
##############################################################################
# Argument Parsing
##############################################################################
import argparse,os,sys,re
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import csvUtils
argparser = argparse.ArgumentParser(description='Creates a de-embedding file to be run in matlab based on instructions')
argparser.add_argument('-dir', dest='dir',default='.',help='Directory with the list of sparameter files')
argparser.add_argument('-defile', dest='defile',required=True,help='CSV file used to build the matlab deembedding code')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################

## read the whole directory
lstFiles = os.listdir(args.dir)
lstFiles = filter(lambda ff: re.search(r'(?<!DE)\.s\d+p$',ff,flags=re.I), lstFiles);
## read the instruction file for de-embedding
instDF = csvUtils.dFrame(args.defile,text=True)
instDF = makeKCaps(instDF)
## do each structure in the file
newLst=[]; checkedFiles=[]
for row in xrange(len(instDF['ROWNAME'])):
  ## construct the filename
  fileComp = [instDF[jj][row].strip() for jj in ('ROWNAME','LOCATION','STRUCTURENAME','BIAS','STRUCTUREINDEX') if skipItem(instDF[jj][row])]
  fileRx = r'(?P<die>X-?\d+Y-?\d+)_'+'_'.join(fileComp)+'(?P<ext>\.s\d+p)'
  ## find the file
  count=0;
  while lstFiles and count < len(lstFiles): ## get the raw data
    fileT = lstFiles[count]
    test = re.search(r''+fileRx,fileT,flags=re.I)
    if test:
      die = test.group('die'); ext = test.group('ext')
      ## construct the calibration files
      calsRx = {}
      for cc in ('SHORTS','OPENS','THROUGHS','PADS','SHORTS_PADS','OPENS_PADS'):
        if cc in instDF and instDF[cc][row].strip(): 
          calComp = (instDF[cc][row].strip()).split('+')
          calsRx[cc] = r''+'_'.join([die]+calComp[0:2]+['\w+']+[calComp[2]])+ext
      ## find the opens, shorts, throughs or pads if the file had cals in it
      if calsRx:      
        cals = {'RAW':fileT}; checkedFiles.append(fileT); test = False;# print calsRx
        for cc in calsRx:
	  for calTest in lstFiles[:]: 
	    test = re.search(r''+calsRx[cc],calTest,flags=re.I)
	    if test: cals[cc] = calTest; test = True; break
        newLst.append(cals)
#	if test == True: print calsRx
    count+=1 #increment the counter
## log files not used for deembedding
resFiles = [ii for ii in lstFiles if ii not in checkedFiles]
with open('noDeEmbedding.txt','w') as fOut: fOut.write('\n'.join(resFiles)+'\n')

##print the command lines for matlab
for line in newLst:
  args = "'"+line['RAW']+"','"+"','".join([key.lower()+"','"+line[key] for key in line.keys() if key!='RAW'])+"'"
  print 'deembedmm('+args+');'
