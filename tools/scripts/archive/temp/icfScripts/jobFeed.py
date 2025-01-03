#!/usr/bin/env python2.7
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
#   Type >> batchFeed.py -h 
##############################################################################

def isPython(cmd):
  import os
  if len(cmd) == 1: test = cmd[0].split()[0]
  else: test = cmd[0]
  if os.path.splitext(test)[1]=='.py': return True
  else: return False

def waitForJobs(jobs): 
  index = [] ## find jobs that finish, pop them, and continue, if none just pop randomly, wait, and continue
  for ii,jj in enumerate(jobs): 
    jj.poll(); 
    if jj.returncode != None: index.append(ii)  ## store only the ones that did finish == None
  if any(index):## if at least one finish, pop and continue
    for ii in index: test = jobs.pop(ii) if ii < len(jobs) else str(ii)+str(len(jobs));
  elif any(jobs): test = jobs.pop(); test.communicate(); #if none finish wait randomly for one

def mainExe(argLst=None):
  ##############################################################################
  # Argument Parsing
  ##############################################################################
  import sys, argparse, os, re, subprocess as sb, datetime
  sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python')
  import netbatch as nb
  argparser = argparse.ArgumentParser(description='Feed jobs to the batch with a single command')
  argparser.add_argument(dest='count', type=int, help='Max number of job(s)')
  argparser.add_argument('-cmd', dest='cmd', required=True, nargs='+', help='command')
  argparser.add_argument('-files', dest='files', nargs='+', required=True, help='file(s)')
  argparser.add_argument('-batch', dest='batch', nargs='?', const='True', choices=[True,False], type=eval, default='noBatch', help='use netbacth (provide arg False for non interactive mode)')
  argparser.add_argument('-nomail', dest='mail', action='store_false', help='e-mail the user')
  argparser.add_argument('-lvs', dest='lvs', action='store_true',help='lvs runs')
  args = argparser.parse_args()

  ##############################################################################
  # Main Begins
  ##############################################################################
  jobs=[]; stamp = str(datetime.datetime.now())
  #run for each file
  for ff in args.files:
    if args.cmd and args.lvs and isPython(args.cmd): cmd = ' '.join(args.cmd)+' -cdl '+os.path.splitext(ff)[0]+'.cdl -- '+ff
  ## is it python add --
    elif args.cmd and isPython(args.cmd): cmd = ' '.join(args.cmd)+' -- '+ff
    else: cmd = ' '.join(args.cmd)+' '+ff
  ## use batch or local decision
    if args.batch != 'noBatch': jobs.append(nb.submit(cmd,interactive=args.batch)); print 'Batch:Submitted ',cmd
    else: jobs.append(sb.Popen(cmd,stdout=sb.PIPE,stderr=sb.PIPE,shell=True)); print 'Local:Submitted ',cmd
  ## wait if the count is reached
    if len(jobs) >= args.count: waitForJobs(jobs)
  ## prepare log and send email
  for jj in jobs:
    with open('transcript.log', 'a') as fout: fout.write( '\n'.join(jj.communicate()) + '\n')
  if args.mail:
    subject = 'Script trigger '+stamp+' finished'; body = ' '.join(sys.argv)
    sb.call("echo '"+body+"' | mail -s '"+subject+"' jmarulan",shell=True)

if __name__ == '__main__':
  mainExe()
