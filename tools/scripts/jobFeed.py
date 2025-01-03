#!/usr/bin/env python3.7.4
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
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> jobFeed.py -h 
#   Each job submitted creates a log file, this logfile appends the output of the submission
#   All jobs output is concatenated into a final logfile
##############################################################################

def isPython(cmd):
  import os
  if len(cmd) == 1: test = cmd[0].split()[0]
  else: test = cmd[0]
  if os.path.splitext(test)[1]=='.py': return True
  else: return False

def waitForJobs(jobs,logFout): 
  index = [] ## find jobs that finish, pop them, and return to the main, if none just pop randomly one, wait, and return to the main
  for ii,jj in enumerate(jobs): 
    jj.poll(); 
    if jj.returncode != None: index.append(ii); ## store only the ones that did finish == None
  if len(index)>0:## if at least one finish, pop and continue
    for ii in sorted(index,reverse=True): 
      if ii < len(jobs): test = jobs.pop(ii); updateLog(test,logFout)
  elif any(jobs): test = jobs.pop(); updateLog(test,logFout) #if none finish wait randomly for one and return to the main 

def updateLog(job,logFout):  #store any stderr in the mainlog, this will happen at the end though
  text = [ff for ff in job.communicate() if ff]
  if any(text) and logFout != False:
    text = [str.strip(ff.decode()) for ff in text]
    logFout.write(('\n'.join(text)+'\n').encode()); logFout.flush()

def compileLogs(logFout,logLst):
  if logFout == False: return
  for log in logLst:
    with open(log,'rb') as fin: logFout.write((fin.read()+b'\n'))
     
def mainExe(argLst=None):
  ##############################################################################
  # Argument Parsing
  ##############################################################################
  import sys, argparse, os, re, subprocess as sb, datetime, textutils
  import netbatch as nb
  argparser = argparse.ArgumentParser(description='Feed jobs to the batch with a single command')
  argparser.add_argument(dest='count', type=int, help='Max number of job(s)')
  argparser.add_argument('-cmd', dest='cmd', required=True, nargs='+', help='command')
  argparser.add_argument('-files', dest='files', nargs='+', required=True, help='file(s)')
  argparser.add_argument('-batch', dest='batch', nargs='?', const='True', choices=['True','False'], default='noBatch', help='use netbacth (provide arg False for non interactive mode to submit all at once)')
  argparser.add_argument('-nomail', dest='mail', action='store_false', help='e-mail the user')
  argparser.add_argument('-lvs', dest='lvs', action='store_true',help='lvs runs')
  args = argparser.parse_args(argLst)
  ##############################################################################
  # Main Begins
  ##############################################################################
  jobs=[]; stamp = str(datetime.datetime.now().strftime('%b%d_%H:%M')); logLst = []
  if args.batch != 'False': logFout = open(stamp+'_FullTranscript.log','wb'); #for batch == false no need for a main log  
  #run for each file
  for runNum,ff in enumerate(args.files):
    ## create the command
    if args.cmd and args.lvs and isPython(args.cmd): cmd = ' '.join(args.cmd)+' -cdl '+os.path.splitext(ff)[0]+'.cdl -- '+ff
    elif args.cmd and isPython(args.cmd): cmd = ' '.join(args.cmd)+' -- '+ff ## is it python add --
    else: cmd = ' '.join(args.cmd)+' '+ff
    ## create the log file
    iiLog = 'log'+str(runNum+1)+'_'+str(datetime.datetime.now().strftime('%b%d_%H:%M'))+'_transcript.log'; logLst.append(iiLog)
    ## create the command so that stdout/stderr goes to the iiLog in batchMode and stdout only for localMode
    if args.batch != 'noBatch': jobs.append(nb.submit(cmd,interactive=eval(args.batch),log=iiLog)); print(f'Batch:Submitted {cmd} >> {iiLog}') 
    else: jobs.append(sb.Popen(f'{cmd} >> {iiLog}',stdout=sb.PIPE,stderr=sb.PIPE,shell=True)); print('Local:Submitted pid: '+str(jobs[-1].pid)+f' {cmd} >> {iiLog}')
  ## wait if the count is reached
    if args.batch != 'False' and len(jobs) >= args.count: waitForJobs(jobs,logFout) #for args.batch == False keep submitting
  ## wait for any jobs left if args.batch != False else just finish
  if args.batch != 'False':
    while len(jobs) > 0: waitForJobs(jobs,logFout) # for args.batch == False no need to wait
    compileLogs(logFout,logLst); logFout.close() #compile stderr logs
  ## send email
  if args.mail:
    subject = 'Script trigger '+stamp+' finished'; body = textutils.shorten(' '.join(sys.argv),500)
    sb.call("echo '"+body+"' | mail -s '"+subject+"' "+os.getenv('USER'),shell=True)

if __name__ == '__main__':
  mainExe()
