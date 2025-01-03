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
#
# Author:
#   Mauricio Marulanda
#
# Description:
#   Useful functions for sparameter executions
#
##############################################################################

def citiToTs(citiFile):
  from tempfile import mkdtemp,mkstemp; from subprocess import call; from os import listdir, path; from re import search
  if getFileType(citiFile) != 'citi': return citiFile
  tempDir = mkdtemp()
#  tempFile = mkstemp(dir=tempDir)[1]
  tempFile = tempDir+'/'+path.splitext(path.basename(citiFile))[0]
  with open(tempFile, 'wb') as fout:
    with open(citiFile,'rb') as fin: fout.write(fin.read())
  call('~jmarulan/work_area/utils/scripts/citi2ts '+ tempFile, shell=True)
  outFile = filter(lambda ff: search(r'\.s\d+p$',ff), listdir(tempDir))[0]
  if outFile: return tempDir+'/'+outFile
  else: raise ValueError('Invalid sparameter file')

def getFileType(spFile):
  from re import search, I; from os import path
  test = search(r'\.(?:(?P<ts>s\d+p)|(?P<ct>c.?ti))$',path.splitext(spFile)[1],flags=I)
  if test: 
    if test.group('ts'): return 'touchStone'
    else: return 'citi'
  else: raise ValueError('Invalid sparameter file')

def snpToS2pXfmr(spClass): # n is 4,5,6
  import subprocess; from tempfile import mkdtemp,mkstemp;
  ## decide the ports; when n=5, p5 is the center tap; when n=6, p3 & p6 are the center taps
  if   spClass.portNum == 4: ports = '(p1 0 n1 0 p2 0 n2 0)'
  elif spClass.portNum == 5: ports = '(p1 0 n1 0 p2 0 n2 0 0 0)'
  elif spClass.portNum == 6: ports = '(p1 0 n1 0 0  0 p2 0 n2 0 0 0)'
  ## create the file to simulate
  tempDir = mkdtemp();
  tempFile = mkstemp(dir=tempDir,suffix='.scs')[1]
  with open(tempFile,'wb') as fout: fout.write('''**************\n*Simulation of Transformer\n*************\nsimulator lang = spectre
  nport0 '''+ports+''' nport thermalnoise=yes file="'''+spClass.filename+'''" dcextrap=constant hfextrap=constant passivity=no pabstol=1e-06 causality=fmax
  p1 (p1 n1) port r=50
  p2 (p2 n2) port r=50
  spAnal sp start='''+str(spClass.freq[0]*1e9)+''' stop='''+str(spClass.freq[-1])+'''G file="output.s2p" datafmt=touchstone ports=[p1 p2]
  simulatorOptions options reltol=1e-3 vabstol=1e-6 iabstol=1e-12 temp=25 tnom=27 scalem=1.0 scale=1.0 gmin=1e-12 rforce=1 maxnotes=5 maxwarns=5 digits=5 cols=80 pivrel=1e-3 sensfile="../psf/sens.output" checklimitdest=psf cmi_opts=[0 0 1]\n''')
  runSim = subprocess.Popen('cd '+tempDir+';spectre '+tempFile,shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
  output = runSim.communicate()[0]
  return tempDir+'/output.s2p'

def snpToS2p(spClass,portLst): # Name number portLst of the ports to become 1,2
  import subprocess; from tempfile import mkdtemp,mkstemp;
  ## sort the ports and create the port name instances 
  portLine = []; portInsts = []; ports = []; portC = 1
  for ii in range(1,spClass.portNum+1):
    if ii in portLst: 
      term = 'term'+str(portC)+' 0'; ports.append('prt'+str(portC)); portLine.append(term); portInsts.append(ports[-1]+' ('+term+') port r=50'); portC+=1 
    else: portLine.append('0 0')
  portLine = '('+(' '.join(portLine))+')'; outFName = 'output.s'+str(len(ports))+'p'
  ## create the file to simulate
  tempDir = mkdtemp(); tempFile = mkstemp(dir=tempDir,suffix='.scs')[1]
  with open(tempFile,'wb') as fout: fout.write('''**************\n*Simulation of SP-Reduction\n*************\nsimulator lang = spectre
  nport0 '''+portLine+''' nport thermalnoise=yes file="'''+spClass.filename+'''" dcextrap=constant hfextrap=constant passivity=no pabstol=1e-06 causality=fmax
  '''+('\n  '.join(portInsts))+'''
  spAnal sp start='''+str(spClass.freq[0])+'''G stop='''+str(spClass.freq[-1])+'''G file="'''+outFName+'''" datafmt=touchstone ports=['''+(' '.join(ports))+''']
  simulatorOptions options reltol=1e-3 vabstol=1e-6 iabstol=1e-12 temp=25 tnom=27 scalem=1.0 scale=1.0 gmin=1e-12 rforce=1 maxnotes=5 maxwarns=5 digits=5 cols=80 pivrel=1e-3 sensfile="../psf/sens.output" checklimitdest=psf cmi_opts=[0 0 1]\n''')
#  with open(tempFile) as test: print test.read()
  runSim = subprocess.Popen('cd '+tempDir+';spectre '+tempFile,shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)  
  output = runSim.communicate()[0]
  return tempDir+'/'+outFName
