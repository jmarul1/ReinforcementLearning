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
#   Type >> readTags.py -h 
##############################################################################
def getFiles(path):
   if os.path.exists(path):
     if os.path.isdir(path):
       files = map(os.path.normpath, os.listdir(path))
       if tempArgs.view:
         for ii in files[:]:
           if re.search(r''+tempArgs.view,ii): files = [ii]; break
       fileLst = map(lambda ii: os.path.join(path,ii), files)
       if not fileLst: print >> sys.stderr,'The dir: "'+path+'" is empty'
       return fileLst
     else: return [os.path.normpath(path)]
   else: raise argparse.ArgumentTypeError('File or Dir doesn\'t exist: '+path)

def repeat(ch,times):
  out = []
  for ii in xrange(times):
    out.append(ch)
  return out
  
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, itertools, os, re, sys, subprocess
argparser = argparse.ArgumentParser(description='This program prints the tags associated with a cell or a file')
subDirs = ['auCdl','hspiceD','layout','spectre','symbol','lvqaWaivers'] ## possible subdirs for a cell
argparser.add_argument('-view', dest='view', choices = subDirs, help='view name')
tempArgs = argparser.parse_known_args()[0]
argparser.add_argument(dest='input', nargs='+', type=getFiles, help='cellname(s) or filename(s)')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')

## get the file(s) information
if not any(args.input): raise IOError('Input dir(s) is empty')
args.input = set(itertools.chain(*args.input))

## get the history
for iiIn in args.input:
  if os.path.isdir(iiIn): #basename(iiIn) in subDirs:
    if '.SYNC' in os.path.basename(iiIn): continue
    fileName = iiIn
    iiIn += '.sync.cds'
  else: fileName = iiIn
  test = subprocess.Popen('dssc vhistory '+iiIn,shell=True,stdout=subprocess.PIPE)
  output = test.communicate()[0]
  version,versionTags,author,dateVal = [[],[],[],[]]
  for line in output.splitlines():
    test = re.search(r'Version:\s+(\d+\.\d+)',line)
    if test: version.append(test.group(1))
    test = re.search(r'Version tags:\s+(.+)',line)
    if test: versionTags.append(test.group(1))
    test = re.search(r'Author:\s+(.+)',line)
    if test: author.append(test.group(1))    
    test = re.search(r'Date:\s+(.+)',line)
    if test: dateVal.append(test.group(1))    
  ## find max for tags
  versionTagMax = max(map(len,versionTags[-1].split(','))) if any(versionTags) and versionTags[-1] else 4
  ## print the results
  if version:    
    strOut = ''.join(repeat(' ',len(fileName)-4))+'File\tVersion\tTags'+''.join(repeat(' ',versionTagMax-4))+'\tAuthor'
    strOut += ''.join(repeat(' ',len(author[-1])-6))+'\tDate\n'
    offset = ''.join(repeat(' ',len(fileName)))+'\t'+''.join(repeat(' ',len(version[-1])))+'\t'
    if any(versionTags) and versionTags[-1]:
      versionTags = map(str.strip,versionTags[-1].split(','))
      offset2 = ''.join(repeat(' ',versionTagMax-len(versionTags[0])))+'\t'
      strOut += '\t'.join([fileName,version[-1]])+'\t'+versionTags[0]+offset2+author[-1]+'\t'+dateVal[-1]+'\n'
      if len(versionTags) > 1: strOut += offset+('\n'+offset).join(versionTags[1:])
    else: strOut += '\t'.join([fileName,version[-1],'None'])
    print strOut
  else: print >> sys.stderr,'The file/dir: "'+fileName+'" is not managed'
