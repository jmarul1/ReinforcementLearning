#!/usr/bin/env python
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

#Arguments:
#    Argument 1: File with the arguments to extract parameters from with skew and simulator  *****typQ.scs$ or ****highQ.hsp$
#    Argument 2: Used to determined spectre or hspice type insertion,input can be spectre, scs, .scs or hspice, hsp, .hsp.

import sys, os
import string, re
import subprocess

def printHelp():
  print "Please give file to read from and the file with context\n\
  Argument 1: File with the arguments to extract parameters from. With skew and simulator  *****typQ.scs$ or ****highQ.hsp$\n\
  Argument 2: Used to determined spectre or hspice type insertion,input can be spectre, scs, .scs or hspice, hsp, .hsp.\n"

def getProject(): import os; return {'fdk73':'1273','fdk71':'1271','f1275':'1275'}.get(os.getenv('PROJECT'))  

def xtrSubckt(insLstFile):   # can store many subcircuits of the same skew
  result = []; myTempLst = []; keepFetch = False
  for nextLine in insLstFile:
    if not re.search(r"^\*",nextLine):
      if re.search(r"^[\t ]*\.?subckt[\t ]+\b(\w+)\b",nextLine,re.I): # start reading
        keepFetch = True
      if re.search(r"^[\t ]*\.?ends\b",nextLine,re.I): # stop reading and re-initialize
        result.append(myTempLst)
	keepFetch = False; myTempLst = []
      if keepFetch:
        myTempLst.append(nextLine)
  return result

def xtrParams(simulator,context):
  params = {}; flagErr = False
  for nextLine in context:
    testParam = re.search(r"^[\t ]*(\w+)\b.*[ \t]+(\d+(?:\.\d+)?(?:e[+-]*\d+)?)",nextLine)
    testSub = re.search(r"^[\t ]*\.?subckt[\t ]+\b(\w+)\b",nextLine,re.I)
    if testSub:
      subCktName = testSub.group(1);
      ports = re.findall(r"\b\w+\b",nextLine); del ports[0:2]; # keep ports only
      modelName = "ind"+str(len(ports))+"tmodel" # get the model name based on port size
    elif testParam:
      if re.search("^[Ll]",testParam.group(1)):
    	params[(testParam.group(1)).capitalize()] = str(float(testParam.group(2))*1e9) #make them nH
      elif re.search("^[Cc]",testParam.group(1)):
    	params[(testParam.group(1)).capitalize()] = str(float(testParam.group(2))*1e15) #make them fF
      else: # for resistors and Ks keep the same units
    	params[(testParam.group(1)).capitalize()] = testParam.group(2)
  ## check if all parameters are defined or missing
  if len(ports) == 2: DefParams = ["Cc1","Cox1","K11","K12","K1_2","L1","Lbrg1","Ls1","R1","Rs1","Rsub1"]; numParams = len(DefParams)+1 # for the math below
  else: DefParams = ["Cc1","Cox1","K11","K12","K1_2","L1","Lbrg1","Ls1","R1","Rs1","Rst","Rsub1"]; numParams = len(DefParams)
  for ii in iter(DefParams):
    if ii not in params:
      print "WARNING: The model parameter %s is not defined in the given subckt %s" %(ii,subCktName)
  if not len(params) == numParams*2-1+len(ports): #-1 for K12 and +Ports for Rsub1_3&4 and Cox1_3&4, I used the ports for math, just trust me
    print "WARNING: The given subckt %s is not consistent with the default model" %(subCktName)
  ## create the string
  resultStr = sorted(map("=".join, params.items()))
  resultStr = " ".join(resultStr)
  if simulator=="spectre":
    simSyntax = ["(",")",""]
  elif simulator=="hspice":    
    simSyntax = ["","","."]
  ports = simSyntax[0]+(" ".join(sorted(ports)))+simSyntax[1]
  context = " ".join([simSyntax[2]+"subckt",subCktName,ports])
  context = context+"\n"+" ".join(["  x"+subCktName,ports,modelName])+" "+resultStr
  context = context+"\n"+simSyntax[2]+"ends "+subCktName+"\n"
  return context

def createFile(outFile,context,secPattern):
## read the reference from within the directory if exists, if not set the fossil location
  fname = 'intel'+re.search(r'(71|73|75)$',getProject()).group(1)+'indwrapper'
  if os.path.exists(outFile):
    srcFileFid = open(outFile,"r")
  elif "scs" in outFile:
    refFile = os.getenv("INTEL_PDK")+"/models/spectre/custom/"+fname+".scs"    
    print refFile
  elif "hsp" in outFile:
    refFile = os.getenv("INTEL_PDK")+"/models/hspice/custom/"+fname+".hsp"      
## read the reference from Fossil if path exists, if not create file within the directory
  if not "srcFileFid" in locals():
    if os.path.exists(refFile):
      srcFileFid = open(refFile,"r")
    else:
      subprocess.call("copyright.py "+os.path.splitext(outFile)[1]+" > "+outFile,shell=True)
      srcFileFid = open(outFile,"r")
## put source reference of the file into the buffer
  srcFileLines = srcFileFid.readlines()
  srcFileFid.close()
## search and place parameters
  outFileFid = open(outFile,"w")
  done = srchAndIns(srcFileLines,secPattern,context,outFileFid)
## inductor subckt did not exist in the file attach it
  if not done:
    myTempData=subprocess.Popen("copyright.py "+os.path.splitext(outFile)[1]+" 0",stdout=subprocess.PIPE,shell=True); #myTempData.wait()
    myTempData = (myTempData.communicate()[0]).splitlines(True)
    done = srchAndIns(myTempData,secPattern,context,outFileFid) # outFileFid is already at the end of the file
## if nothing was printed exit with an error
  if not done:
    print "ERROR: There was a problem putting the context in the output file"; outFileFid.close()
    sys.exit(1)
  outFileFid.close()  

def srchAndIns(srcFileLines,secPattern,context,outFileFid):
  grnLight = False; success = False
  for nextLine in srcFileLines:
    outFileFid.write(nextLine)
    if re.search(r"^\*+ *INDUCTORS",nextLine,re.I):
      grnLight = True
    elif grnLight and re.search(secPattern,nextLine,re.I):
      outFileFid.write("\n"+context)
      success = True
  return success


###############################
####### PROGRAM STARTS ########
###############################

## Help
args = " ".join(sys.argv); result = ""
if re.search(r"\b\w+[ \t]\-h(elp)*\b",args):
  printHelp(); sys.exit(1)
elif len(sys.argv) < 3:
  printHelp(); sys.exit(1)
## Main  
if not os.path.exists(sys.argv[1]):
  print "ERROR: File given with context to insert does not exist"
  sys.exit(1)
## technology
project = getProject()  
## Read the contents of the file
insFileFid = open(sys.argv[1], "r")
insLstData = insFileFid.readlines()
if "typq" in str.lower(insFileFid.name):
  secType = "typQ" if project != '1275' else 'tttt'
elif "lowq" in str.lower(insFileFid.name):
  secType = "lowQ" if project != '1275' else 'ssss'
elif "highq" in str.lower(insFileFid.name):
  secType = "highQ" if project != '1275' else 'ffff'
else:
  print "ERROR: File given with context to insert lacks the section in the file name ****typQ.(scs|hsp)"
  sys.exit(1)
insFileFid.close() 
## Process the context to see how many subcircuits
insLstData = xtrSubckt(insLstData)
## Set the pattern to search in the reference file
context = ""
if re.search(r"(\b\.scs\b|\bspectre\b|\bscs\b)",str.lower(sys.argv[2])):
  secPattern = "^ *section *"+secType
  outFile = "indSubckt.scs"
  ## Extract the parameters
  for ii in range(len(insLstData)):
    subcktSpc = "\n" if ii > 0 else ""
    context = context + subcktSpc + xtrParams("spectre",insLstData[ii])
  createFile(outFile,context,secPattern)
elif re.search(r"(\b\.hsp\b|\bhspice*\b|\bhsp\b)",str.lower(sys.argv[2])):
  secPattern = "^ *\.lib  *"+secType
  outFile = "indSubckt.hsp"
  ## Extract the parameters
  for ii in range(len(insLstData)):
    subcktSpc = "\n" if ii > 0 else ""
    context = context + subcktSpc + xtrParams("hspice",insLstData[ii])
  createFile(outFile,context,secPattern)
sys.exit(0)
