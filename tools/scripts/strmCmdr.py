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
#   edited by Sanghyun Seo for COMMANDER implemenation
##############################################################################


## MAIN BEGINS ##
import sys, argparse, tempfile, subprocess, os, shutil
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); import cadence, shell

## INPUTS ##
argparser = argparse.ArgumentParser(description='netlist out cdl files using commander for p1276')
argparser.add_argument(dest='cellNames', nargs = '+', help='Cell View(s)')
argparser.add_argument('-lib', dest='libName', required = True, help='Library with top views')
argparser.add_argument('-format', dest='format', default='cdl', choices=['cdl','scs','sp'], help='output file format. Default CDL')
argparser.add_argument('-outdir', dest='outDir', default = '$WARD/netlists', help='Output Directory')
args = argparser.parse_args()

## run for each gds file
cdsFile = os.getenv('CDSLIB')
if not os.path.isfile(cdsFile): raise IOError('cds.lib is missing or corrupted')
## get the cells with support to regular expression
cdsObj = cadence.readCds(cdsFile); effCells=[]
for topCell in args.cellNames: effCells += cdsObj.getLibCells(args.libName,'^'+(topCell.strip().rstrip('$').lstrip('^'))+'$')
if not effCells: sys.stderr.write('No matching cells in library\n')
## call commander and options. Define intel76custom.cdl path
cdlPath = '/nfs/site/disks/shdk76.db.002/std/intel76custom/X76CAwork/intel76custom/cdladdon/intel76custom.cdl'
spPath = os.getenv('COMMANDER_SIM_SP_INC')
commander = os.getenv('COMMANDER')
print(commander)
if args.format == 'sp':
    options = ' -ward '+args.outDir+ " -spTreatTopAsSubckt 1 -vt 'schematic' -spType 'default' -spSwitchViewList 'hspiceD,schematic'  -spStopViewList 'hspiceD' -spSquareB 1 -spStripPrefix 1 -multoutdirs 1 -spChangeModelToCell 1 -spChangeToLowerCase 1 -spInc "+spPath
else:
    options = ' -ward '+args.outDir+ ' -cdlInc '+cdlPath

if args.outDir=='$WARD/netlists':
    options +=  ' -multoutdirs '
for cellName in effCells:
  arguments = ' -sim '+args.format+' -lib '+args.libName+' -cell '+cellName
  cmd = commander+options+arguments
  subprocess.call(cmd,shell=True)
