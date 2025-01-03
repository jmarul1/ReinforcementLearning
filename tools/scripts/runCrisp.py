#!/usr/bin/env python3.7.4
##############################################################################
# Intel Top Secret                                                           #
# Author: Chang-Tsung Fu, Mauricio Marulanda
# Description:
#   Type >> runCrisp.py -h 
##############################################################################
import argparse, os, tempfile, re, sys, operator
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/environment/myPython/lib/python')); 
sys.path.append(os.path.expanduser('~jmarulan/work_area/utils/utils/scripts')); sys.stderr.write('\n')
import jobFeed, crisp, csvUtils, itertools

## defaults
DEFAULTCRISP = '/nfs/site/eda/group/SYSNAME/tcad/common/netcap3d/v9.2/netcap3d'
DEFAULTQCAP = ''

## arguments fns
def checkCrisp(ff):
  if os.path.isfile(ff): return os.path.realpath(ff)
  else: raise IOError('Crisp executable invalid: '+ff) 

def checkGds(ff): #return [cellName,gdsFullPath,ports]
  temp = os.path.splitext(os.path.basename(ff))
  if os.path.isfile(ff) and temp[1]=='.gds': 
    return [temp[0],os.path.realpath(ff),'']
  else: raise IOError('gds does not exist: '+ff)

def readOnly(tmpDir,csv=False):
  if not(os.path.isdir(tmpDir+'/crisp5') and os.listdir(tmpDir+'/crisp5')): raise argparse.ArgumentTypeError('Does not exist or is not dir: '+tmpDir)
  with open('crisp_readOnly.log','wb') as logId:
    netsCapsDts = {}; oneSucceed=False
    for cell in os.listdir(tmpDir+'/crisp5'):
      mfactor = crisp.getMFactor(cell)
      dataNetCap = crisp.readFile(tmpDir+'/crisp5/'+cell+'/allNets.summary',mfactor)
      if dataNetCap: netsCapsDts[cell] = dataNetCap; logId.write(cell+' SUCESS\n'); oneSucceed=True   ## create a dictionary with the data above
      else: logId.write(cell+' ...... FAIL(DATA_COLLECT)\n') 
  if oneSucceed: outputTheResults(getOutputLst(netsCapsDts),tmpDir if csv else False)
  else: print 'Everything FAILED, you have learned nothing'

def getOutputLst(netsCapsFullDts):
  netNames = []   ## extract all the nets and sort them
  for cell,netsCapsDt in netsCapsFullDts.items(): netNames += netsCapsDt.keys()
  netNames = sorted(set(netNames))
  outLst = [','.join(['cellName']+netNames)]## prepare the output
  for cell,netsCapsDt in netsCapsFullDts.items(): outLst.append(','.join([cell]+[(netsCapsDt[net] if net in netsCapsDt.keys() else '') for net in netNames]))
  return outLst

def outputTheResults(outLst,name):
  if name != False:
    with open(name+'_caps.csv','w') as fout: fout.write('\n'.join(outLst))
  else: print '\n'.join(outLst)

##############################################################################
# Argument Parsing
##############################################################################
if not os.getenv('PROJECT'): raise IOError('Run this in an environemnt technology session with PROJECT variable defined')
argparser = argparse.ArgumentParser(description='Runs crisp, make sure CRISP version and QCAP files are compatible, both are available as optional inputs. If ICV fails try overwriting ICVhome with\n >> setenv ICV_HOME_DIR "/p/foundry/eda/em64t_SLES11/icvalidator/K-2015.06-SP1"')
argparser.add_argument(dest='gds',nargs = '+',type=checkGds, help='GDS file(s)')
argparser.add_argument('-qcap', dest='qcap',required=True,help='Technology QCap file')
argparser.add_argument('-ports', dest='ports', nargs='+', default=['port1'], help='Ports to be extracted, applied to all gds inputs)')
argparser.add_argument('-time', dest='time',default=60, type=int,help=argparse.SUPPRESS)
argparser.add_argument('-jobs', dest='count', default=2, type=int, help='Jobs in parallel')
argparser.add_argument('-csv', dest='csvFile', action='store_true', help='store results in a csv file: "crisp_*.csv"')
argparser.add_argument('-report', dest='report', help='Target directory where crisp was previously run (other arguments ignored, except "-csv")')
args = argparser.parse_args(); sys.stderr.write('QCAP_FILE: '+args.qcap+'\n')
##############################################################################
## create working temp dir
tempDir=tempfile.mkdtemp(prefix='crisp_',dir='.'); logFile = tempfile.mkstemp(dir=tempDir)
jobs=[]; crispObjs=[]; oneSucceed=False
## run for each gds input
for gds in args.gds:
  crispObjs.append(crisp.crispClass(tempDir,gds,args.qcap,args.time))   ## create necessary files
  jobs.append(crispObjs[-1].run(DEFAULTCRISP))   ## run the files    
  if len(jobs) >= args.count: jobFeed.waitForJobs(jobs,logFile)    ## wait if the count is reached
jobFeed.waitForJobs(jobs,logFile)

## read the results and print the log
with open('crisp_run.log','wb') as logId: 
  netsCapsDts = {}
  for crispObj in crispObjs:
    if crispObj.pid.returncode != 0 : logId.write(crispObj.cell+' ...... FAIL\n')
    else: 
      dataNetCap = crispObj.readData()
      if dataNetCap: netsCapsDts[crispObj.cell] = dataNetCap; logId.write(crispObj.cell+' SUCESS\n'); oneSucceed=True
      else: logId.write(crispObj.cell+' ...... SUCESS(CRISP) ... FAIL(DATA_COLLECT)\n') 
## print the results 
if oneSucceed: outputTheResults(getOutputLst(netsCapsDts),tempDir if args.csvFile else False)
else: print 'Everything FAILED, you have learned nothing'
exit(0)
