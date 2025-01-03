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
#   Type >> waivers.py -h 
##############################################################################

def update(cellName,flow,rule,newCount,comment):
  import re
  with open(cellName,'rb') as fid: lines = fid.readlines()
  with open(cellName,'wb') as fid:
    fFlag = False; success=False; flow = flow.split(' ')
    for line in lines:
      ## find the main flow
      if not(fFlag) and re.search(r':violation\w+\s+'+flow[0]+'\s+'+flow[1],line,flags=re.I): 
        fFlag = True; fid.write(line); continue
      if fFlag:
        if not(re.search(r':violation',line,flags=re.I)): 
          ## find the rule and replace with the new number
          if re.search(r'^\s*'+rule+'\s+\d+',line,flags=re.I): 
	    newline = re.sub(r'(^\s*'+rule+'\s+)\d+(.*)','\g<1>'+newCount+'\g<2>',line,count=1)
	    fid.write(newline); success=True; fFlag = False; continue
	else: fid.write(rule+'\t'+newCount+'\t'+comment+'\n'); fFlag = False; success=True;# reached the end and no rule so just add it
      fid.write(line)
    if not(success): fid.write(':violationcnts  '+flow[0]+' \t'+flow[1]+'\n'+rule+'\t'+newCount+'\t'+comment+'\n'); success=True #reach the end of the file just add the full flow
  return success

def updateErr(string): sys.stderr.write(string+'\n'); log.write(string+'\n')
    
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, csv
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import designM, csvUtils
argparser = argparse.ArgumentParser(description='Handles the waivers')
argparser.add_argument('-file', dest='file', type=csvUtils.dFrame, help='File with "cell,flow(e.g.:icv_drc flow),rule,count" (All other args below are ignored)')
argparser.add_argument('-cell', dest='cell', help=argparse.SUPPRESS) #help='CellName Path'
argparser.add_argument('-flow', dest='flow', nargs=2, help=argparse.SUPPRESS)#help='CatFlow flow -- e.g. icv_drc drcd (Require if !-file)'
argparser.add_argument('-rule', dest='rule', help=argparse.SUPPRESS)#help='Rule name (Require if !-file)'
argparser.add_argument('-nc','-newcount', dest='nc', help=argparse.SUPPRESS)#help='New count (Require if !-file)',
argparser.add_argument('-nco',dest='co', action='store_false', help='Do not try to check out')
args = argparser.parse_args()
if not args.file and not (args.flow and args.rule and args.nc): print >> sys.stderr,'Missing argument\n'; argparser.print_help()
##############################################################################
# Main Begins
##############################################################################
inputLst = zip(args.file['cell'],args.file['flow'],args.file['rule'],args.file['count']) if args.file else [[args.cell,' '.join(args.flow),args.rule,args.nc]]
log = open('waiverLog.log','wb'); coLst = []
for ii,ins in enumerate(inputLst):
  cellName,flow,rule,newCount = ins
  ## check out the cell
  path = os.path.join(cellName,'lvqaWaivers','text.txt')
  if not os.path.isfile(path): err = 'Waiver file does not exist: '+path; updateErr(err); continue
  effPath = os.path.join(cellName,'lvqaWaivers.sync.cds')
  if args.co:
    if effPath not in coLst: 
      if not designM.checkout(effPath): err = 'File not managed or checked out before running this script'; updateErr(err)
      else: coLst.append(effPath) ## remember checkout items
  ## if comment added include it
  comment = args.file['comment'][ii] if 'comment' in args.file.keys() else ''
  ## update the waiver
  result = update(path,flow,rule,newCount,comment)
  if not result: err = flow+' '+rule+' does not exist in '+path; updateErr(err)
  else: err = 'Updated ... '+cellName+' '+rule+' with '+newCount; updateErr(err)
if coLst: updateErr('Checked out items: '+('\n'.join(coLst)))
log.close()  
exit()
