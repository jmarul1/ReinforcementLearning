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

# This program converts Cadence Tech Layer map file to a compatible input for Ride CTP generation and 
# GDS importing

import sys
import re

####### PROGRAM STARTS ######

if len(sys.argv) < 2:
  print "Please give the file path of the layerMap Tech File"
  sys.exit(0)

if len(sys.argv) > 2:
  maskDrawing = sys.argv[2]
else:
  maskDrawing = "drawing"  

maxMapLayerNumber = 0  
inputFile = open(sys.argv[1], 'r') #opening the file
for nextLine in inputFile:
  if not re.match("^#", nextLine):
    if re.match("((metal|via|m|v)\d+|c4b|tm1) +"+maskDrawing, nextLine):
      print nextLine.replace("\n", "")
      if re.match("(metal|m)\d +",nextLine):  # to be use at the end by the metal0
        metalZero = nextLine
    temp = re.findall(" \d+",nextLine)
    if temp and maxMapLayerNumber < int(max(temp)):
      maxMapLayerNumber = int(max(temp)) #maxMapLayerNumber
  else:
    print nextLine.replace("\n","")
if "metalZero" not in locals() or "metalZero" not in globals():
  print "ERROR: No Output, perhaps wrong MaskDrawing identifying string"
  sys.exit(0)
metalZero = re.sub("(metal|m)\d+ ","metal0 ",metalZero)
metalZero = re.sub(" \d+ "," "+str(maxMapLayerNumber+1)+" ",metalZero)
print "#Substrate Definition:"
print metalZero.replace("\n","")
