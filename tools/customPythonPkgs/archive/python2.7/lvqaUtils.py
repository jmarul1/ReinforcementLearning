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
#   Useful functions for working with QA LVQA files
#
##############################################################################

def targetFiles(path):
  import os, argparse
  lstFiles = []; exts = ['.TOP_LAYOUT_ERRORS','.LVS_ERRORS', '.lvs_report', '.lvs_report_ext', '.layout_erc_summary']
  if os.path.isdir(path):
    lstFiles = os.listdir(path); lstFiles = filter(lambda ff: os.path.splitext(ff)[1] in exts, lstFiles); 
    if any(lstFiles): lstFiles = [path+'/'+ii for ii in lstFiles]; lstFiles = map(os.path.normpath,lstFiles); 
  elif os.path.isfile(path): 
    if os.path.splitext(path)[1] in exts: lstFiles = [path]
  else: raise argparse.ArgumentTypeError('File or Dir doesn\'t exist: '+path)
  return lstFiles

def getEntryInfo(fullEntry):
  import os
  entry = os.path.basename(fullEntry)
  test = entry.split('.'); test2 = test[0].split('_')
  cellName = '.'.join(test[1:-1]);
  flow = '_'.join(test2[:-1]); tool = test2[-1]
  if flow == 'lvs' and test[-1] in ['TOP_LAYOUT_ERRORS','lvs_report_ext']: flow = tool+'_layoutLvs'
  elif flow == 'lvs' and test[-1] in ['layout_erc_summary']: flow = tool+'_ercSummary'
  else: flow = tool+'_'+flow
  return cellName,flow,tool
