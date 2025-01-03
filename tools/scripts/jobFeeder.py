#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> jobFeeder.py -h 
##############################################################################

def runCmd(cmd,log,batch):
  ## create the command so that stdout/stderr goes to the iiLog 
  log = log+'_'+str(datetime.datetime.now().strftime('%b%d_%H:%M'))+'.log'; cmd = f'{cmd} >& {log}'
  if batch: print(f'Batch:Submitted --> {cmd}'); nb.submitV2(cmd);  
  else: print(f'Local:Submitted --> {cmd}'); sb.run(cmd,shell=True); 
  return log

def parseCmds(cmdStr):
  cmds = cmdStr.split(';'); cmds = list(map(str.strip,cmds))
  cmds = list(map(lambda ff: re.sub(r'\s+',' ',ff),cmds))
  return cmds
  
##############################################################################
# Argument Parsing
##############################################################################
import sys, argparse, os, re, subprocess as sb, datetime, textutils, netbatch as nb, multiprocessing
argparser = argparse.ArgumentParser(description='Feed unix commands locally or to the batch in parallel, note that the list of commands must come after "--" in the usage',usage='jobFeeder.py [-h] -count COUNT [-batch] [-nomail] -- listOfCommands [cmds ...]')
argparser.add_argument(dest='cmds', type=parseCmds, help='a string with the list of commands separated by ";"')
argparser.add_argument('-count', dest='count', required=True, type=int, help='Number of job(s) in parallel')
argparser.add_argument('-batch', dest='batch', action='store_true', help='use the netbatch')
argparser.add_argument('-nomail', dest='mail', action='store_false', help='do not e-mail the user')
argparser.add_argument('-files', dest='files', nargs='+', default = [''], help='apply cmds to each file')
args = argparser.parse_args()
##############################################################################
# Main Begins
##############################################################################
jobs=[]; stamp = str(datetime.datetime.now().strftime('%b%d_%H:%M')); logFout = stamp+'_fullTranscript.log'
pool = multiprocessing.Pool(args.count); runNum=0
## run for each cmd
for cmd in args.cmds: 
  for ffFile in args.files: 
    cmdEff = f'{cmd} {ffFile}'
    jobs.append(pool.apply_async(runCmd,[cmdEff,'log'+str(runNum+1),args.batch])); runNum+=1
## wait for the jobs and compile log files
with open(logFout,'w') as logOut:
  for job in jobs: 
    log = job.get()
    with open(log) as fin: logOut.write(fin.read()); logOut.flush()
pool.terminate()
## send email
if args.mail:
  subject = 'Script trigger '+stamp+' finished'; body = textutils.shorten(' '.join(sys.argv),500)
  sb.call("echo '"+body+"' | mail -s '"+subject+"' "+os.getenv('USER'),shell=True)
