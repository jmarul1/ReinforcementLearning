#!/usr/bin/env python2.7
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> netbatch.py -h 
##############################################################################

## Submit the job
def submit(argStr,memory='64',mail=False,interactive=False):
  import subprocess as sb, re, os
  mailme = '--mail E' if mail else '--mail no'
  inter = '--mode interactive' if interactive else ''
  setGroups()
  cmd = 'nbjob run '+inter+' '+mailme+' --target pdx_normal --class-reservation "cores=6,memory='+memory+'" --qslot /adg/lvd/pd '+argStr
  process = sb.Popen(cmd,stdout=sb.PIPE,stderr=sb.PIPE,shell=True) ###########
  if interactive: return process
  log = process.communicate()
  jobID = re.search(r'\bJobID\s+(\d+)',log[0])
  if jobID: return jobID.group(1)
  else: raise IOError('Problems submitting the job to the batch')

## Poll the jobs, returns True when is done
def poll(jobID,target='pdx_normal'):
  import subprocess as sb, re
  cmd = 'nbstatus jobs "jobid==\''+str(jobID)+'\'"'
  process = sb.Popen(cmd,stdout=sb.PIPE,stderr=sb.PIPE,shell=True)
  log = '\n'.join(process.communicate())
  if re.search(r'(run|wait|queue|remote).*'+jobID,log,flags = re.I): return False
  else: return True

def setGroups():
  import subprocess, os
  cmd=subprocess.Popen('groups',shell=True,stdout = subprocess.PIPE); groups = cmd.communicate()[0].strip()
  if groups: os.environ['NB_WASH_GROUPS'] = ','.join(groups.split())
  #print os.environ['NB_WASH_GROUPS']
      
## if called as stand alone
if __name__ == '__main__':
  import argparse
  argparser = argparse.ArgumentParser(description='This submits job to the batch',epilog='Note: if command has "-options" wrap the whole command in a "string"')
  group = argparser.add_mutually_exclusive_group(required=True)
  group.add_argument('-submit',dest='cmd',nargs='+', help='Command to submit')
  group.add_argument('-poll',dest='jobid',type=int, help='JobId to check')  
  argparser.add_argument('-mail',dest='mail',action='store_true', help='Mail Option')
  argparser.add_argument('-memory',dest='memory',default='"SLES11&&96G&&nosusp"',help='memory to use')  
  argparser.add_argument('-i,-interactive',dest='interactive',action='store_true',help='Use local process to submit (returns a python Popen object)')  
  args = argparser.parse_args()
  if args.cmd: print 'JOBID = '+submit(' '.join(args.cmd),memory=args.memory,mail=args.mail,interactive=args.interactive)
  else: print 'FINISHED' if poll(str(args.jobid)) else 'RUNNING'
