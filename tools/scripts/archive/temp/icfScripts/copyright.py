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

# Creates copyright header
# Arguments:
#   [Argument 1]: If given with value of "spectre" or "hspice", the respective format is used
#   [Argument 2]: If given with any value, only empty inductor netlist is printed not the copyright

import sys, os, re

def getProject(): import os; return {'fdk73':'1273','fdk71':'1271','f1275':'1275'}.get(os.getenv('PROJECT'))

def printHelp():
  print "\
Creates copyright header\n\
Arguments:\n\
  [Argument 1]: If given with value of 'spectre' or 'hspice', the respective format is used\n\
  [Argument 2]: If given with any value, only empty inductor netlist is printed not the copyright"

def getCopyRight():
  return "\
*\n\
*******************************************************************************\n\
*** Intel Top Secret                                                         **\n\
*******************************************************************************\n\
*** Copyright (C) 2014, Intel Corporation.  All rights reserved.             **\n\
***                                                                          **\n\
*** This is the property of Intel Corporation and may only be utilized       **\n\
*** pursuant to a written Restricted Use Nondisclosure Agreement             **\n\
*** with Intel Corporation.  It may not be used, reproduced, or              **\n\
*** disclosed to others except in accordance with the terms and              **\n\
*** conditions of such agreement.                                            **\n\
***                                                                          **\n\
*** All products, processes, computer systems, dates, and figures            **\n\
*** specified are preliminary based on current expectations, and are         **\n\
*** subject to change without notice.                                        **\n\
*******************************************************************************\n\
\n\
******************************************************************************\n\
* process: dot"+os.getenv("FDK_DOTPROC")+"\n\
* version: 1\n\
******************************************************************************\n"

def getNetlist(simulator):
  if simulator == "spectre":
    secType = "section"; endSecType = "endsection";
  elif simulator == "hspice":
    secType = ".lib"; endSecType = ".endl"; simulator = "spice"
## print the netlist
  result = "\n\
****************************** INDUCTORS *************************************\n\
simulator lang = "+simulator+"\n"
  skews = ["lowQ","typQ","highQ"] if getProject() != '1275' else ["ssss","tttt","ffff"]
  for skew in skews:
    result = result + "\n\
**************\n\
* "+str.upper(skew)+" SKEW *\n\
**************\n"\
+secType+" "+skew+"\n\
\n"\
+endSecType
  result = result + "\n********************************************************************************\n"
  return result

###############################
####### PROGRAM STARTS ########
###############################

args = " ".join(sys.argv); result = ""
if re.search(r"\b\w+[ \t]\-h(elp)*\b",args):
  printHelp(); sys.exit(1)
elif len(sys.argv) < 3:
  result = getCopyRight()
if len(sys.argv) > 1:
  if re.search(r"(\b\.scs\b|\bspectre\b|\bscs\b)",str.lower(sys.argv[1])):
    result = result + getNetlist("spectre")
  elif re.search(r"(\b\.hsp\b|\bhspiced*\b|\bhsp\b)",str.lower(sys.argv[1])):
    result = result + getNetlist("hspice")
print result
sys.exit(0)
