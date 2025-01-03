#!/usr/intel/bin/python2.7
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
#   Type >> calculateQLSp.py -h 
#
##############################################################################

def plotData(xArray,Qdict,Ldict):
  import pylab as pl
  figure = (pl.figure()).add_subplot(111); pl.hold(True)
## plot all the Qs
  for qq in Qdict.keys():
    figure.plot(xArray,Qdict[qq],'-k',label='Q'+qq)
    figure.set_ylabel('Quality Factor'); figure.set_xlabel('Frequency (GHz)');
    #figure.set_yscale('log'); #figure.set_ylim(0,10);
    figure.legend(loc='best')
## plot the Ls
  axL = figure.twinx()
  for qq in Qdict.keys():
    axL.plot(xArray,Ldict[qq],'-b',label='L'+qq)
    axL.set_ylabel('Inductance (nH)');
    #pl.savefig('output.png')  
  pl.show()
  pl.hold(False)

##############################################################################
# Argument Parsing
##############################################################################
import argparse, os
argparser = argparse.ArgumentParser(description='Extracts a simple RLk model from a TCoil Sparameter file.')
argparser.add_argument(dest='spFiles', nargs='+', help='sparameter file')
argparser.add_argument('-csv', dest='csvFile', action='store_true', help='store results in a csv file: "spfile"_QL.csv')
#argparser.add_argument('-plot', dest='plotme', action='store_true', help='displays and saves a plot picture')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
import sys, re
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
import sparameter as sp

## run for each file specified 
for iiSpFile in args.spFiles:

  ## Get real path of the file and decide for how many ports
  if os.path.exists(iiSpFile) and re.search(r'\.s3p$',os.path.splitext(iiSpFile)[1],flags=re.I):
    spFile = os.path.realpath(iiSpFile); spFileName = os.path.splitext(os.path.basename(iiSpFile))[0]
    sparam = sp.read(iiSpFile)
  else: print('Sparameter file '+iiSpFile+' either does not exists or is not a correct sparameter file'); exit(1)

  ## Get the differential, center tap components and losses
  [Qdiff,Ldiff,Qse,Lse,Rdiff,Rse] = sparam.getQLR()
  [L1ToCt,R1ToCt,L2ToCt,R2ToCt,kL1L2,C11,C22,C33] = sparam.getTCoilFns()

  ## Compile the results in a string
  results = 'Freq(GHz),Ldiff(nH),L1ToCt(nH),L2ToCt(nH),R1ToCt(Ohms),R2ToCt(Ohms),kL1L2,C11(fF),C22(fF),C33(fF)\n'
  for ii in range(len(sparam.freq)):
    results += ','.join([str(sparam.freq[ii]),str(Ldiff[ii]),str(L1ToCt[ii]),str(L2ToCt[ii]),str(R1ToCt[ii]),str(R2ToCt[ii]),str(kL1L2[ii]),str(C11[ii]),str(C22[ii]),str(C33[ii])])
    results += '\n'

  ## if csv enable print values in csv file ## else print to the prompt
  if args.csvFile:
    with open(spFileName+'_TCoil.csv','w') as fout:
      fout.write(results)
  else: print(results)

  ## show the plot if requested
  #if args.plotme: plotData(freq,Q,L)
exit(0)
