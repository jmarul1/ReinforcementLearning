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
# Description:
#   Type >> link.py -h 
##############################################################################


##############################################################################
# Argument Parsing
##############################################################################
import argparse, os
argparser = argparse.ArgumentParser(description='Creates symbolic links FROM the specified files to the cwd.')
argparser.add_argument(dest='files', nargs='+', help='list of files to be linked')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################

## create the links for each file
for iiFile in args.files:
  if os.path.exists(iiFile): 
    srcFile = os.path.realpath(iiFile)
    dstFile = os.path.basename(srcFile)
    if not os.path.exists(dstFile):  
      os.symlink(srcFile,dstFile)
      print( 'Link to '+iiFile+' created')
    else: print( dstFile+' already exists in CWD, link not created')
  else: print( iiFile+' does not exists, link not created')
