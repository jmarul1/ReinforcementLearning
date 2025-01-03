#!/usr/bin/env python3.7.4
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


## MAIN BEGINS ##    
import sys, argparse, tempfile, subprocess, os, shutil
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); import cadence, shell

## INPUTS ##
argparser = argparse.ArgumentParser(description='Streams out cdl files into specified directory (defaults to current)')
argparser.add_argument(dest='cellNames', nargs = '+', help='Cell View(s)')
argparser.add_argument('-lib', dest='libName', required = True, help='Library with top views')
argparser.add_argument('-format', dest='format', default='sn', choices=['iif','sn','sch','sp','v','iifsch','snsch'], help='output file format')
argparser.add_argument('-outdir', dest='outDir', default = '.', help='Output Directory')
args = argparser.parse_args()

## run for each gds file
cdsFile = os.getenv('CDSLIB')
if not os.path.isfile(cdsFile): raise IOError('cds.lib is missing or corrupted')
## get the cells with support to regular expression
cdsObj = cadence.readCds(cdsFile); effCells=[]
for topCell in args.cellNames: effCells += cdsObj.getLibCells(args.libName,'^'+(topCell.strip().rstrip('$').lstrip('^'))+'$')
if not effCells: sys.stderr.write('No matching cells in library\n')
## create dir
nike = os.getenv('NIKE_NETLISTER')
options =  ' -no_defl_for_non_mos -builder_specific_options \" -global_as_pin\"  -informat cdba_cdf -multdz 0 -stopl device -hier'
options += ' -outdir '+args.outDir
for cellName in effCells:
  arguments = ' -outf '+args.format+' -libpath '+args.libName+' -cell '+cellName+' -libpath '+cdsFile
  cmd = nike+options+arguments
  subprocess.call(cmd,shell=True)
  shell.rmFile(topCell+'__cdba_cdf_to_Sn__nike_netlister.log')
