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
import argparse, subprocess

## INPUTS ##
argparser = argparse.ArgumentParser(description='Streams out cdl/gds files into specified directory (defaults to current)')
argparser.add_argument(dest='cellNames', nargs = '+', help='Cell View(s)')
argparser.add_argument('-lib', dest='libName', required = True, help='Library with top views')
argparser.add_argument('-outdir', dest='outDir', default = '.', help='Output Directory')
argparser.add_argument('-viewNames', dest='viewNames', metavar='views', nargs=2, default = ['layout','schematic'], help='View names of the cell for layout, schematic, RESPECTIVELY')
argparser.add_argument('-layermap', dest='lmap', help='Layer Map File')
argparser.add_argument('-objectmap', dest='omap', help='Object Map File')

args = argparser.parse_args()
## run for each cell name
arguments = ' '.join(args.cellNames)+' -lib '+args.libName+' -outdir '+args.outDir
argumentsAdd = (' -layermap '+args.lmap+' ' if args.lmap else '')+(' -objectmap '+args.omap+' ' if args.omap else '')
subprocess.call('strmOut.py '+arguments+' -viewName '+args.viewNames[0]+argumentsAdd,shell=True)
subprocess.call('strmNike.py '+arguments,shell=True)
