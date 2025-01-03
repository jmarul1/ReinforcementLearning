#!/usr/bin/env python2.7
##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2016, Intel Corporation.  All rights reserved.               #
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
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> simBgDiode.py -h 
##############################################################################

def checkCore(path):
  if os.path.isfile(path): return os.path.relpath(path)
  else: raise IOError('Core file does not exist: '+path)

def getModel(project):
  return {'73':'d8xmbgdiodehvm1'}.get(project,'d8xmbgdiodehvm1')

def checkArgs():
  if len(args.skew)>1 and len(args.coreFile)>1:
    raise argparse.ArgumentTypeError('\nPROVIDE:\n ONE skew for multiple corefiles\n or\n ONE corefile for multiple skews')
  if args.mc and (args.skew[0] != 'tttt' or len(args.coreFile)>1): 
    raise argparse.ArgumentTypeError('Only tttt and only one corefile supported')  
  if len(args.skew)>1: return True
  else: return False
  
##############################################################################
# Argument Parsing
##############################################################################
import argparse, os, sys, re, subprocess, tempfile, ckts, pylab
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python'); sys.path.append('/p/fdk/gwa/jmarulan/utils/scripts/plotRF.py')
project = {'fdk73':'73','fdk71':'71','f1275':'75'}.get(os.getenv('PROJECT'))
argparser = argparse.ArgumentParser(description='Plots simulations of bgdiode')
argparser.add_argument('-sim', dest='sim', choices=['scs','hsp'], default='hsp', help='simulator')
argparser.add_argument('-skews', dest='skew', nargs = '+', choices={'73':['bghp','bglp','bglp1','tttt'],'75':['tttt']}.get(project), default=['tttt'], help='skew')
temperatures = [-40,-30,-20,-10,0,10,20,30,40,50,60,70,80,90,100,110,120,130,140]
argparser.add_argument('-temp',dest='temps',type=float,nargs='+',default=temperatures,help='temperatures')
argparser.add_argument('-corefile', dest='coreFile', nargs='+', type=checkCore, default=[False], help='UPF core files to simulate')
argparser.add_argument('-montecarlo', dest='mc', action='store_true', help='Use montecarlo (only tttt supported)')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
import plotUtils, plotRF
sFlag = checkArgs()## check arguments
## get the include files for each skew and core
includes = {}
for skew in args.skew: 
  includes[skew] = {}
  for core in args.coreFile: 
    incs,upf = ckts.getIncludes(args.sim,project,skew,core)
    includes[skew][upf] = incs
## create working dir
tempDir = os.path.realpath(tempfile.mkdtemp(dir='.'));
## create the bg diode
bgdObj = ckts.bgdiode(getModel(project),args.sim,args.temps)
## run for all skews and upfs
output = {}
for skew,upfDt in includes.items():
  output[skew] = {}
  for upfVer,incs in upfDt.items():
    output[skew][upfVer] = {'veb':bgdObj.simulate(incs,tempDir,'veb',prefix=upfVer,monteCarlo=args.mc),'beta':bgdObj.simulate(incs,tempDir,'beta',prefix=upfVer,monteCarlo=args.mc)}
## plot all
[Figs,Layouts] = plotUtils.layoutPlt(2,grW=6,grH=6); ylabel = dict(veb='(V)',beta='')
for skew,upfDt in output.items(): # only one for many upf
  for upfVer,dataDt in upfDt.items(): #only one for many skews
    for cc,(pp,data) in enumerate(dataDt.items()):
      if args.mc: 
        temp = zip(*data[1])
        for yy in plotUtils.computeStd(map(float,temp[0]),map(float,temp[1])): Layouts[cc].plot(data[0],yy,lw=2); 
      else: Layouts[cc].plot(data[0],data[1],lw=2,label=(skew if sFlag else upfVer)); 
      plotRF.fixGraph(Layouts[cc],xlabel='temperature(C)',ylabel=pp+ylabel[pp],legendSize={'size':12},limitAx=False);   ## add axis and labels
suptitle = (upfVer if sFlag else skew) + ('_montecarlo' if args.mc else '')
for iiFig in Figs: iiFig.tight_layout(); iiFig.suptitle(suptitle,y=0.5,fontsize=70,color='gray',alpha=0.3,rotation=45,va='center',ha='center')
pylab.show()

## erase working directory
#subprocess.Popen('sleep 5; rm -rf '+tempDir+'&',shell=True)
exit(0)
