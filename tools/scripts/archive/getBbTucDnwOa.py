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

import os, sys, re, argparse

def envCheck():
  project = os.getenv('PROJECT'); errStr = 'Please run this in an environment window, dbmenu, fdk, etc.'
  if project.strip() != '': return'12'+project[-2:]
  else: raise EnvironmentError(errStr)  

env=envCheck()
ce = os.getenv('INTEL_RUNSETS')+'/UTILITY/do_not_uniquify_cell_list'
bb = os.getenv('INTEL_RUNSETS')+'/PXL/'+env+'/p'+env+'dx_LVSblackBox.rs'
templates = os.getenv('INTEL_RUNSETS')+'/PXL/'+env+'/p'+env+'dx_TemplateCells.rs'
oamap = os.getenv('FSHELF_ROOT')+'/repo/rcx_tld_collab/dot'+os.getenv('FDK_DOTPROC')+'/oa_dfii_devmap/'
oamap = oamap+str(max(map(int, os.listdir(oamap))))+'/p'+env+'_'+os.getenv('FDK_DOTPROC')+'.dfii.devmap' if os.path.isdir(oamap) else ''
if not os.path.isfile(oamap): oamap=''
print >> sys.stderr,'\n'.join([bb,templates,oamap])

## ARGUMENTS
argparser = argparse.ArgumentParser(description='Creates csv for Blackbox, tuc, oamap based on RUNSET lists')
argparser.add_argument('-bb', dest='bb', help='BlackBox file path', default = bb)
argparser.add_argument('-tuc', dest='tuc', help='TUC file path', default = templates)
argparser.add_argument('-dnw', dest='dnw', help='DNW file path', default = templates)
argparser.add_argument('-oa', dest='oa', help='OAMAP file path', default = oamap)
args = argparser.parse_args()
##

filterFn = lambda ff: not(re.search(r'^d8[012789]|^x',ff) )

bbCells = []; swapPorts = {}
with open(args.bb) as fid:
  for line in fid:
    test = re.search(r'layout_cell\s*=\s*"([a-zA-Z0-9_*]+)"',line)
    if test: bbCells.append(test.group(1).lower().strip())
    test = re.search(r'swappable_ports\s*=\s*(.*)',line)
    if test and re.search(r'\w+',test.group(1)): swapPorts[bbCells[-1]] = ":".join(re.findall(r'\w+',test.group(1)))
bbCells= list(set(bbCells))
bbCells = filter(filterFn, bbCells)

tucCells = []; nestedTucCells = []; dnwCells = []; tucFeed=nestedTucFeed=dnwFeed=strFeed=False
with open(args.tuc) as fid:
  for line in fid:
    if re.search(r'^\s*templateCellsTUC',line,flags=re.I): tucFeed=True; dnwFeed=nestedTucFeed=False;
    if re.search(r'^\s*nestedTemplateCellsTUC',line,flags=re.I): nestedTucFeed=True; dnwFeed=tucFeed=False;
    if re.search(r'^\s*templateCellsNoDNW',line,flags=re.I): dnwFeed = True; tucFeed=nestedTucFeed=False;
    if re.search(r'{',line): strFeed = True
    if strFeed:
      test = re.search(r'^\s*"([a-zA-Z0-9_*]+)',line)
      if test and tucFeed: tucCells.append(test.group(1).lower().strip())
      if test and nestedTucFeed: nestedTucCells.append(test.group(1).lower().strip())
      if test and dnwFeed: dnwCells.append(test.group(1).lower().strip())
      if re.search(r'}',line): strFeed = False
tucCells = list(set(tucCells));		dnwCells = list(set(dnwCells));		nestedTucCells = list(set(nestedTucCells));
tucCells = filter(filterFn, tucCells);	dnwCells = filter(filterFn, dnwCells);	nestedTucCells = filter(filterFn, nestedTucCells);

oamapCells = {}
if os.path.isfile(args.oa):
  with open(args.oa) as fid:
    for line in fid:
      test = re.search(r'^\s*(\w+)',line)
      if test: oamapCells[test.group(1).lower()] = re.sub(r'\s+',' ',line.strip())  
else: print >> sys.stderr,'OAMAP File does not exist '+args.oa

print "cellName,blackbox,swapPorts,tuc,nestedTuc,dnwSupport,oamap"
for cellName in sorted(set(bbCells+filter(filterFn,swapPorts.keys())+tucCells+nestedTucCells+dnwCells+oamapCells.keys())):
  col1 = 'Yes' if cellName in bbCells else '';  col2 = swapPorts[cellName] if cellName in swapPorts.keys() else ''
  col3 = 'Yes' if cellName in tucCells else ''; col4 = 'Yes' if cellName in nestedTucCells else ''
  col5 = 'No'  if cellName in dnwCells else ''; col6 = oamapCells[cellName] if cellName in oamapCells.keys() else ''  
  print ','.join([cellName,col1,col2,col3,col4,col5])
