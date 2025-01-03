#!/usr/bin/env python3.7.4
##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> calculateQLSp.py -h 
##############################################################################

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os
argparser = argparse.ArgumentParser(description='Calculates the characteristics of a transmission line')
argparser.add_argument(dest='spFiles', nargs='+', help='sparameter file(s)')
argparser.add_argument('-csv', dest='csvFile', action='store_true', help='store results in a csv file: "spfile"_TL.csv')
argparser.add_argument('-ports', dest='ports', nargs=2, default=[1,2], type=int, help='main two ports, defaults to <1 2>, rest are gnd')
argparser.add_argument('-resonator', dest='rsn', type=int, help='port to resonate from, the rest are gnd')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
import sys, re, math
import sparameter as sp
## run for each sparameter specified 
for iiSpFile in args.spFiles:
  spFile = os.path.realpath(iiSpFile); spFileName = os.path.splitext(os.path.basename(spFile))[0]
  sparam = sp.read(spFile)
  if args.rsn:
    RealZ,ImagZ,RsnF = sparam.getTLChar([args.rsn])
    RsnF = RsnF[0] if RsnF  else '>'+str(sparam.freq[-1])
    results = 'Freq(GHz),R11(Ohms),Imag(Z11),RsnF(GHz)\n'    
    for ii in range(len(sparam.freq)):
      results += ','.join([str(sparam.freq[ii]),str(RealZ[ii]),str(ImagZ[ii]),str(RsnF)])+'\n'
  else:
    Qdiff,Ldiff,Rdiff,gammaL,Zeff = sparam.getTLChar(args.ports)
    results = 'Freq(GHz),Qdiff,Ldiff(nH),Rdiff(Ohms),gammaL(deg),Zc(Ohms)\n'
    for ii in range(len(sparam.freq)):
      results += ','.join([str(sparam.freq[ii]),str(Qdiff[ii]),str(Ldiff[ii]),str(Rdiff[ii]),str(gammaL[ii].real),str(Zeff[ii].real)])+'\n'

## if csv enable print values in csv file ## else print to the prompt
  if args.csvFile:
    with open(spFileName+'_TL.csv','w') as fout: fout.write(results)
  else: print(results)

exit(0)
