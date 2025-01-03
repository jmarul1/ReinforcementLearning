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
#   Useful functions for ind/cap subcircuit executions
#
##############################################################################

## Re order the ports for three port networks (assume first is center tap)
def fixPorts(ports):
#  if len(ports) == 3: ports.append(ports[0]); del ports[0] back in the day where CT was the first in the subckt
  if ports[0] in ['vss','VSS']: ports.append(ports[0]); del ports[0]
  return ports

#####################################################
def createScsFile(tempDir,modelName,ports,incFiles,firstFreq,stepFreq,lastFreq):
  """ Create Spectre netlist to simulate using Sparameter Analysis"""
  import math, subprocess; from numtools import numToStr;   from tempfile import mkstemp
## Convert Freqs to GHz and convert values to strings
  [firstFreq,stepFreq,lastFreq] = [numToStr(firstFreq/1e9),numToStr(stepFreq/1e9),numToStr(lastFreq/1e9)]  
## If freqs is too small
#  print firstFreq
## Correct the ports
  effPorts = ports[0:2] if len(ports) != 2 else ports
## Create the file
  [fidOut,scsNameOut]= mkstemp(dir=tempDir,suffix='.scs');
  with open(scsNameOut,'w') as fidOut:
    outFName = 'output.s'+str(len(effPorts))+'p'
    outFData = ('\n\
*************************************************************************\n\
* MAIN\n\
*************************************************************************\n\
simulator lang = spectre\n\n\
xPassiveInst ('+' '.join(ports)+') '+modelName+'\n'
+'\n'.join(['p'+str(ii+1)+' ('+jj+' 0) port r=50' for ii,jj in enumerate(fixPorts(effPorts[:]))])+'\n\
spAnal sp start='+firstFreq+'G stop='+lastFreq+'G step='+stepFreq+'G file=\"'+outFName+'\" datafmt=touchstone ports=['+' '.join(['p'+str(ii+1) for ii in range(len(effPorts))])+']\n\
simulatorOptions options reltol=1e-3 vabstol=1e-6 iabstol=1e-12 temp=25 tnom=27 scalem=1.0 scale=1.0 gmin=1e-12 rforce=1 maxnotes=5 maxwarns=5 digits=5 cols=80 pivrel=1e-3 sensfile="../psf/sens.output" checklimitdest=psf cmi_opts=[0 0 1]\n\n')
    fidOut.write(outFData)
    fidOut.close()
  ## include the files
  for ii in range(int(len(incFiles)/2)):
    if incFiles[ii+1] == 'spice': subprocess.call('echo simulator lang = spice >> '+scsNameOut,shell=True)
    subprocess.call('cat '+incFiles[ii]+' >> '+scsNameOut,shell=True)
  return scsNameOut,outFName

#####################################################
def createHspFile(tempDir,modelName,ports,incFiles,firstFreq,stepFreq,lastFreq,rEnd):
  """ Create Hspice netlist to simulate using AC analysis """
  import math, os, subprocess; from tempfile import mkstemp; from numtools import getScaleNum, numToStr
## Convert Freqs to GHz and convert values to strings
  firstFreq,stepFreq,lastFreq = map(getScaleNum,[firstFreq,stepFreq,lastFreq])        
  [firstFreq,stepFreq,lastFreq] = [numToStr(firstFreq/1e9),numToStr(stepFreq/1e9),numToStr(lastFreq/1e9)]  
  rEnd = str(rEnd)
## Get the number of steps
  steps = str(int((float(lastFreq)-float(firstFreq))/float(stepFreq))+1)
## Create the file
  temp = fixPorts(ports[:]); p1=temp[0]; p2=temp[1]
  [fidOut,hspNameOut]= mkstemp(dir=tempDir,suffix='.hsp'); 
  with open(hspNameOut,'w') as fidOut:
    outFName = 'output.print';
    outFData = ('\
*************************************************************************\n\
* MAIN\n\
*************************************************************************\n\
\n\
.TEMP 25\n\
.OPTION\n\
+    ARTIST=2\n+    INGOLD=2\n+    PARHIER=LOCAL\n+    PSF=2\n+    GENK=0\n\
xIndInst ('+' '.join(ports)+')\t '+modelName+'\n\
iIn1 	 '+p2+'\t'+p1+'\t ac  1\n\
rEnd     '+p2+'\t0\t'+rEnd+'\n\
.AC LIN '+steps+' '+firstFreq+'G '+lastFreq+'G\n\
.print AC VI('+p1+','+p2+') VR('+p1+','+p2+')\n\n')
    fidOut.write(outFData)
    fidOut.close()
  ## include the files
  for ii in xrange(len(incFiles)/2):
    subprocess.call('cat '+incFiles[ii]+' >> '+hspNameOut,shell=True)
    subprocess.call('echo .END >> '+hspNameOut,shell=True)
  return hspNameOut,outFName
  
#######################################################
def createACScsFile(tempDir,modelName,ports,incFiles,firstFreq,stepFreq,lastFreq,rEnd):
  """ Create Spectre netlist to simulate using AC analysis """
  import math, subprocess; from numtools import numToStr,getScaleNum;   from tempfile import mkstemp
## Convert Freqs to GHz and convert values to strings
  firstFreq,stepFreq,lastFreq = map(getScaleNum,[firstFreq,stepFreq,lastFreq])        
  [firstFreq,stepFreq,lastFreq] = [numToStr(firstFreq/1e9),numToStr(stepFreq/1e9),numToStr(lastFreq/1e9)]  
  rEnd = str(rEnd)
## Create the file
  temp = fixPorts(ports[:]); p1=temp[0]; p2=temp[1]  
  [fidOut,scsNameOut]= mkstemp(dir=tempDir,suffix='.scs');
  with open(scsNameOut,'w') as fidOut:
    outFName = 'output.print'
    outFData = ('\
*************************************************************************\n\
* MAIN\n\
*************************************************************************\n\
simulator lang = spectre\n\n\
xIndInst ('+' '.join(ports)+')\t '+modelName+'\n\
vIn1 	('+p1+'\t'+p2+')\t vsource dc=0 mag=1\n\
rEnd    ('+p2+'\t0)\t resistor r='+rEnd+'\n\
rVss    (vss\t0)\t resistor r=0\n\
\nacSweep ac start='+firstFreq+'G stop='+lastFreq+'G step='+stepFreq+'G\n\
parameters twopi = 2*3.141692654 \n\
print im(V(vIn1)/-I(vIn1)),re(V(vIn1)/-I(vIn1)), name=acSweep to=\"'+outFName+'\"\n\
\nsimulatorOptions options reltol=1e-3 vabstol=1e-6 iabstol=1e-12 temp=25 tnom=27 \
scalem=1.0 scale=1.0 gmin=1e-12 rforce=1 maxnotes=5 maxwarns=5 \
digits=5 cols=80 pivrel=1e-3 sensfile="../psf/sens.output" checklimitdest=psf\n\n')
    fidOut.write(outFData)
    fidOut.close()
  ## include the files
  for ii in range(len(incFiles)/2):
    if incFiles[ii+1] == 'spice': subprocess.call('echo simulator lang = spice >> '+scsNameOut,shell=True)
    subprocess.call('cat '+incFiles[ii]+' >> '+scsNameOut,shell=True)
  return scsNameOut,outFName

def getPassiveScaledValue(key,val,params):
  import re, numtools
  if re.search(r'^c',key.lower()): key += '(fF)'; mult = 1e15
  elif re.search(r'^l',key.lower()): key += '(nH)'; mult = 1e9
  elif re.search(r'^r',key.lower()): key += '(Ohms)'; mult = 1
  else: mult = 1
  if not numtools.isNumber(val): 
    if val in params.keys(): return key, params[val]
    else: return key, val
  else: return key, ('%g' %(float(val)*mult))
