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
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

LOCAL = ['BFGS','trust-constr','TNC','CG','COBYLA','Nelder-Mead','Powell']; GLOBAL= ['dual_annealing','shgo','differential_evolution']
##############################################################################
# Argument Parsing
##############################################################################
import argparse, multiprocessing, subprocess, qa, re, os, netbatch
argparser = argparse.ArgumentParser(description=f'Matches an s2p to an rlck model using the best result from\n{LOCAL+GLOBAL}\n',formatter_class=argparse.RawTextHelpFormatter)
argparser.add_argument(dest='spFile', help='sp file')
argparser.add_argument('-batch', dest='batch', action='store_true', help='Use the netbatch')
argparser.add_argument('-maxtime', dest='timeout', default=60, type=int, help='Maximum time to run in minutes')
args = argparser.parse_args()
##############################################################################
# Main Begins
############################################################################## 
OPTIMS = GLOBAL+LOCAL;
with multiprocessing.Pool(len(OPTIMS)) as pool:
  jobs = {}
  ## submit jobs up to the len of LOCAL+GLOBAL
  for optimizer in OPTIMS: 
    arguments = [args.spFile,'-optimizer',optimizer,'-stack']; 
    cmd = 'matchSpToRlckSngl.py ' + (' '.join(arguments))
    if args.batch: job = pool.apply_async(netbatch.submitV2,[cmd],{'interactive':True,'timeout':args.timeout,'stderr':None})   #leave the stderr so some stuff gets printed and you dont think is hanging
    else:          job = pool.apply_async(subprocess.run,[cmd],{'stdout':subprocess.PIPE,'shell':True,'timeout':args.timeout}) #leave the stderr so some stuff gets printed and you dont think is hanging
    jobs[job] = optimizer
  ## wait for the jobs and process the error
  error = '-1'; best = False
  for job,optimizer in jobs.items():
    try: data = job.get() #Popen object and optimizer    
    except subprocess.TimeoutExpired: print(f'{optimizer} timed out after {args.timeout:.2f} minutes'); continue
    ## read the results and copy the *scs file with best error to cwd
    test = re.findall(r'\S+',qa.decode(data.stdout.decode()))
    test,fpath = test[1],test[-1]
    if error == '-1' or float(test) < error: error = float(test); best = (test,optimizer,fpath)
  ## exit routine
  if best:
    subprocess.run(f'cp {best[2]} .',shell=True); fName = os.path.basename(best[2])
    print(f'Best results for {args.spFile}:\n  Error: {best[0]}%\n  Optimizer: {best[1]}\n  rlck: {fName}')  



  
