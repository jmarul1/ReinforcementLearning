#!/usr/bin/env python
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
##############################################################################

def isPython(cmd):
  import os
  if len(cmd) == 1: test = cmd[0].split()[0]
  else: test = cmd[0]
  if os.path.splitext(test)[1]=='.py': return True
  else: return False

def waitForJobs(jobs,logFout): 
  index = [] ## find jobs that finish, pop them, and continue, if none just pop randomly, wait, and continue
  for ii,jj in enumerate(jobs): 
    jj.poll(); 
    if jj.returncode != None: index.append(ii); ## store only the ones that did finish == None
  if len(index)>0:## if at least one finish, pop and continue
    for ii in sorted(index,reverse=True): 
      if ii < len(jobs): test = jobs.pop(ii); updateLog(test,logFout)
  elif any(jobs): test = jobs.pop(); updateLog(test,logFout) #if none finish wait randomly for one

def updateLog(job,logFout): 
  text = [ff for ff in job.communicate() if ff]
  if any(text) and logFout != False:
    text = [str.strip(ff.decode()) for ff in text]
    logFout.write(('\n'.join(text)+'\n').encode()); logFout.flush()

def compileLogs(logFout,logLst):
  for log in logLst:
    with open(log,'rb') as fin: logFout.write((fin.read()+b'\n'))
     
def mainExe(argLst=None):
  ##############################################################################
  # Argument Parsing
  ##############################################################################
  import sys, argparse, os, re, subprocess as sb, datetime, textutils
  sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python'))
  import netbatch as nb
  argparser = argparse.ArgumentParser(description='Feed jobs to the batch with a single command')
  argparser.add_argument(dest='count', type=int, help='Max number of job(s)')
  argparser.add_argument('-cmd', dest='cmd', required=True, nargs='+', help='command')
  argparser.add_argument('-files', dest='files', nargs='+', required=True, help='file(s)')
  argparser.add_argument('-batch', dest='batch', nargs='?', const='True', choices=['True','False'], default='noBatch', help='use netbacth (provide arg False for non interactive mode to submit all at once)')
  argparser.add_argument('-nomail', dest='mail', action='store_false', help='e-mail the user')
  argparser.add_argument('-lvs', dest='lvs', action='store_true',help='lvs runs')
  args = argparser.parse_args()
  ##############################################################################
  # Main Begins
  ##############################################################################
  jobs=[]; stamp = str(datetime.datetime.now().strftime('%b%d_%H:%M'))
  logFout = open(stamp+'_FullTranscript.log','wb'); user = os.getenv('USER'); logLst = []
  #run for each file
  for runNum,ff in enumerate(args.files):
    if args.cmd and args.lvs and isPython(args.cmd): cmd = ' '.join(args.cmd)+' -cdl '+os.path.splitext(ff)[0]+'.cdl -- '+ff
  ## is it python add --
    elif args.cmd and isPython(args.cmd): cmd = ' '.join(args.cmd)+' -- '+ff
    else: cmd = ' '.join(args.cmd)+' '+ff
    iiLog = 'log'+str(runNum+1)+'_'+str(datetime.datetime.now().strftime('%b%d_%H:%M'))+'_transcript.log'
    cmd = cmd+' >> '+iiLog; logLst.append(iiLog)
  ## use batch or local decision
    if args.batch != 'noBatch': jobs.append(nb.submit(cmd,interactive=eval(args.batch))); print( 'Batch:Submitted ',cmd) #jobs.append(sb.Popen('ls > '+iiLog,shell=True))
    else: jobs.append(sb.Popen(cmd,stdout=sb.PIPE,stderr=sb.PIPE,shell=True)); print('Local:Submitted pid: '+str(jobs[-1].pid)+' ',cmd)
  ## wait if the count is reached
    if (args.batch == 'noBatch' or args.batch) and len(jobs) >= args.count: waitForJobs(jobs,logFout) #for args.batch = False keep submitting
  ## wait for any jobs left
  while len(jobs) > 0: waitForJobs(jobs,logFout)
  compileLogs(logFout,logLst); logFout.close()
  ## send email
  if args.mail:
    subject = 'Script trigger '+stamp+' finished'; body = textutils.shorten(' '.join(sys.argv),500)
    sb.call("echo '"+body+"' | mail -s '"+subject+"' "+user,shell=True)

if __name__ == '__main__':
  mainExe()
