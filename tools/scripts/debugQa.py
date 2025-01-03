#!/usr/bin/env python3.7.4
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

import os, subprocess, re, qa

subprocess.call('sleep 1',shell=True)

dirQa = '/nfs/pdx/disks/dcti_disk0036/work_x22a/template_de2/template_QA/runQaAreaWiCT/p1276/2020ww19p1'
dirQa = '/tmp/jmarulan/qa/2020ww27p1'

waiverFile = dirQa+'/waivers.csv'
#with open(waiverFile,'wb') as fWaive: fWaive.write('\n')
mainLog=open(dirQa+'/'+'batch.runlog'); mainLog.close()

# XCHIP
logFiles = ' '.join([ff for ff in os.listdir(dirQa) if re.search(r'.stats$',ff)])
# ADRF
logFiles = ' '.join([ff for ff in os.listdir(dirQa) if re.search(r'.(drcc|denall|lvs|IPall)$',ff)])

if logFiles:
#  logFiles = subprocess.run('cd '+dirQa+'; htmlReport.py -logs '+logFiles+' -logonly -waiverfile '+waiverFile,shell=True,capture_output=True); 
  logFiles = subprocess.run('cd '+dirQa+'; htmlCalReport.py '+logFiles+' -logonly -waiverfile '+waiverFile,shell=True,capture_output=True);   
  logFiles = logFiles.stdout.decode().split()
  print(qa.encode(logFiles[0]+' '+os.path.realpath(mainLog.name)+' '+'RUNSET'+' '+logFiles[1]))
#  print(qa.encode(logFiles[0]+' '+os.path.realpath(mainLog.name)+' '+os.path.basename(os.getenv('ISSRUNSETS'))+' '+logFiles[1]))
else:
  print(qa.encode(os.path.realpath(dirQa)+' '+os.path.realpath(mainLog.name)+' '+os.path.basename(os.getenv('ISSRUNSETS'))))
