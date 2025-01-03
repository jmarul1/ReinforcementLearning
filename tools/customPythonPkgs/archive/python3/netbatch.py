#!/usr/bin/env python2.7
##############################################################################
# Author:
#   Mauricio Marulanda
# Description:
#   Type >> netbatch.py -h 
##############################################################################

## Submit the job
def submit(argStr,memory='64',mail=False,interactive=False,stdout=True,stderr=True,log=None):
  import subprocess as sb, re, os;   setGroups()
  mailme = '--mail E' if mail else '--mail no'
  stdout,stderr = (sb.PIPE if stdout==True else stdout),(sb.PIPE if stderr==True else stderr)
  if interactive: inter = '--mode interactive'; argStr += f' >> {log}' if log else ''
  else: inter = ''; argStr = f'--log-file {log} {argStr}' if log else argStr
  cmd = f'nbjob run {inter} {mailme} --target pdx_normal --class-reservation "cores=6,memory={memory}" --qslot /adg/lvd/pd {argStr}'
  process = sb.Popen(cmd,stdout=stdout,stderr=stderr,shell=True) ###########
  if interactive: return process
  log = process.communicate()
  jobID = re.search(r'\bJobID\s+(\d+)',log[0].decode())
  if jobID: return jobID.group(1)
  else: raise IOError('Problems submitting the job to the batch')

## Submit the job
def submitV2(argStr,memory='64',mail=False,interactive=True,stdout=True,stderr=True,timeout=None):
  import subprocess as sb, re, os;   setGroups()
  mailme = '--mail E' if mail else '--mail no'
  inter = '--mode interactive' if interactive else '' ## wait for the job to execute
  timeout= f'--kill {int(timeout/60)}' if timeout else ''
  stdout,stderr = (sb.PIPE if stdout==True else stdout),(sb.PIPE if stderr==True else stderr)
  cmd = f'nbjob run {inter} {mailme} --target pdx_normal --class-reservation "cores=6,memory={memory}" --qslot /adg/lvd/pd {timeout} {argStr}'
  process = sb.run(cmd,stdout=stdout,stderr=stderr,shell=True) # in the interactive mode it will wait here
  if interactive: return process
  else: ## try to find out the jobID in the batch
    jobID = re.search(r'\bJobID\s+(\d+)',process.stdout.decode())
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
  cmd=subprocess.run('groups',shell=True,capture_output=True); groups = cmd.stdout.decode().strip()
  if groups: os.environ['NB_WASH_GROUPS'] = ','.join(groups.split())
  #print os.environ['NB_WASH_GROUPS']
      
