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

import sys, os
import string, re, subprocess

def printHelp(selection):
  if selection == 1:
    print "Please give file to read from\n"
  else:
    print "\
This script converts the spice file ports to Intel's standard ports n_ehv,p_ehv,etc.\n\
  Argument 1: File to convert to subcircuit Intel's compatible.\n"

###############################
####### PROGRAM STARTS ########
###############################

## Help
args = " ".join(sys.argv); result = ""
if re.search(r"\b\w+[ \t]\-h(elp)*\b",args):
  printHelp(0); sys.exit(1)
elif len(sys.argv) < 2:
  printHelp(1); sys.exit(1)
## Main  
if not os.path.exists(sys.argv[1]) or os.path.splitext(sys.argv[1])[1] != ".sp":
  print "ERROR: File given with context to insert does not exist or it is not a spice file."
  sys.exit(1)
## Read the contents of the file
fidIn = open(sys.argv[1], "r")
fDataLns = fidIn.readlines()
foutName = os.path.splitext(fidIn.name)[0]+".scs"
fidIn.close()
## Replace the contents of the file
fidOut = open(foutName, "w"); terminals = 2
for nextLine in fDataLns:
  ## ignore comments
  if re.search(r"^\*",nextLine):
    outLine = nextLine
  ## fix the subcircuit line
  elif re.search(r"^[ \t]*\.?subckt",nextLine):
    terminals = len(re.findall(r"\bn\d+\b",nextLine))-1 # get the number of terminals
    if terminals == 4: terminalsStr = "ct1_ehv ct2_ehv p_ehv n_ehv"
    elif terminals == 3: terminalsStr = "ct_ehv p_ehv n_ehv"
    else: terminalsStr = "p_ehv n_ehv"
    subLnMatch = re.search(r"^[ \t]*(\.?\w+)[ \t]+(\w+)[ \t]+",nextLine)
    outLine = subLnMatch.group(1)+" "+re.sub(r'_(pcss|tttt|pcff|prcf|prcs)','',subLnMatch.group(2),flags=re.I)+" "+terminalsStr+"\n"
  ## fix the netlist
  else:
    outLine = re.sub(r"\bn0\b","0",nextLine)
    outLine = re.sub(r"\bn1\b","p_ehv",outLine)
    outLine = re.sub(r"\bn2\b","n_ehv",outLine)
    if terminals == 3:
      outLine = re.sub(r"\bn3\b","ct_ehv",outLine)
    elif terminals == 4:
      outLine = re.sub(r"\bn3\b","ct1_ehv",outLine)
      outLine = re.sub(r"\bn4\b","ct2_ehv",outLine)
    outLine = re.sub(r"[ \t]+","\t",outLine)
  fidOut.write(outLine)	    
fidOut.close()
