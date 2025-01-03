#!/usr/bin/env python3.7.4
##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2020, Intel Corporation.  All rights reserved.               #
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
##############################################################################

def createWard(opt):
  import tempfile, os, subprocess
  if opt == 'ascend': ## ascend
    ward = tempfile.mkdtemp(prefix=f'{opt}_',dir='.')  
  else: 
    ward = f'{opt}_match'; 
    if not os.path.exists(f'{opt}_match'): subprocess.run(f'mkdir {ward}',shell=True)
  return ward    

def mainExe(argLst=None):  
  LOCALb = ['ascend','BFGS','trust-constr','TNC']; LOCALa = ['CG','COBYLA','Nelder-Mead','Powell']; GLOBAL= ['dual_annealing','shgo','differential_evolution']
  ##############################################################################
  # Argument Parsing
  ##############################################################################
  import argparse, cktfit, cktfit.ascend, cktfit.sclind, cktfit.fitfns, os, subprocess, scipy.optimize, qa; from colors import paint
  argparser = argparse.ArgumentParser(description=f'Match an s2p to an rlck model using\nLocal: {LOCALb+LOCALa}\nGlobal: {GLOBAL}\n',formatter_class=argparse.RawTextHelpFormatter)
  argparser.add_argument(dest='spFile', nargs='+', help='sp file')
  argparser.add_argument('-fromCktCsv', dest='csvCkt', help='CMP only: csv file with ckt elements to build the netlist and compare to spFile')
  argparser.add_argument('-toCsv', dest='toCsv', help=argparse.SUPPRESS) #'CMP only: path of output.csv'
  argparser.add_argument('-optimizer', dest='opt', metavar='OPT', choices = LOCALb+LOCALa+GLOBAL, default='BFGS', help='Optimizer from above')
  argparser.add_argument('-stack', dest='stack', action='store_true', help=argparse.SUPPRESS)
  args = argparser.parse_args(argLst)
  ##############################################################################
  # Main Begins
  ############################################################################## 
  ## Was I called for comparison only
  if args.csvCkt:
    tgtDir = os.path.dirname(os.path.realpath(args.csvCkt))
    QdScore,LdScore,srfScore = cktfit.computeAccuracy(args.spFile[0],args.csvCkt,printCsvsDir=tgtDir,sim='pymm')
    ## write for each Freq
    scores = 'Lscore,{}\n'.format(LdScore)
    scores +='Qscore,{}\n'.format(QdScore)
    scores +='SRFscr,{}'.format(srfScore)  
    if args.toCsv:
      with open(args.toCsv,'wb') as fout: fout.write(scores.encode())
    else: print(scores)
    return True
  ## Called to match from scrath
  else:
    ward = createWard(args.opt); print(f'Working in: {ward}')
    for spFile in args.spFile:
      if args.opt == 'ascend': ## ascend
        print('Running ASCEND !!'); print('Creating Init File')
        init = cktfit.ascend.buildInit(ward,spFile) #send the sparameter and granularity
        with open(ward+'/init.py', 'wb') as fout: fout.write(init.encode())    
        subprocess.run(f'cd {ward}; ascend init init.py',shell=True)
        subprocess.run(f'cd {ward}; ascend run',shell=True)
      else: ## scipy
        fitObj = cktfit.sclind.fit(spFile,ward,args.opt,silent=(True if args.stack else False)); outBaseName = os.path.basename(os.path.splitext(spFile)[0])
        print(f'{paint.bold}Running SCIPY_{args.opt} for {spFile} !!{paint.end}'); 
        if args.opt in LOCALb: quest = scipy.optimize.minimize(fitObj.fun,fitObj.initVals,bounds=fitObj.bounds,method= (None if args.opt=='BFGS' else args.opt))   #,options=dict(maxiter=1)
        elif args.opt in LOCALa: quest = scipy.optimize.minimize(fitObj.fun,fitObj.initVals,method=args.opt) # no bounds allowed
        elif args.opt in GLOBAL: quest = scipy.optimize.dual_annealing(fitObj.fun,fitObj.bounds) #,maxiter=1
        print(f'{paint.green}\n{quest}\nFound Best Possible Solution, wrote: {outBaseName}_rlck.scs{paint.end}')
	## get the good rlck and simulate
        label = ('BFGS|L-BFGS-B|SLSQP' if args.opt=='BFGS' else args.opt) + ' {:.2f} error'.format(quest.fun)
        fitObj.writeCsvCkt(f'{ward}/{outBaseName}_rlck.csv',quest.x,label)
        ckt = cktfit.fitfns.readCkt(f'{ward}/{outBaseName}_rlck.csv'); ckt.createScs(f'{ward}/{outBaseName}_rlck.scs',label)
        cktfit.computeAccuracy(spFile,f'{ward}/{outBaseName}_rlck.csv',printCsvsDir=ward,sim='pymm')
        if args.stack: print(qa.encode(label+f' {ward}/{outBaseName}_rlck.scs'))
        else: return quest.fun,f'{ward}/{outBaseName}_rlck.scs' #return error and scsFile

if __name__ == '__main__':
  mainExe()
