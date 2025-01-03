#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, csv
argparser = argparse.ArgumentParser(description='Flatten the gds')
argparser.add_argument(dest='gdsFiles', nargs='+', help='gds file(s)')
args = argparser.parse_args()

##############################################################################
# Main Begins
##############################################################################

import gdspy

for gdsFile in args.gdsFiles:
  gdsii = gdspy.GdsLibrary()
  gdsii.read_gds(gdsFile)

#gdspy.LayoutViewer()
