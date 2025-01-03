#!/usr/bin/env python2.7
##############################################################################
# Intel Top Secret							     #
##############################################################################
# Copyright (C) 2015, Intel Corporation.  All rights reserved.  	     #
#									     #
# This is the property of Intel Corporation and may only be utilized	     #
# pursuant to a written Restricted Use Nondisclosure Agreement  	     #
# with Intel Corporation.  It may not be used, reproduced, or		     #
# disclosed to others except in accordance with the terms and		     #
# conditions of such agreement. 					     #
#									     #
# All products, processes, computer systems, dates, and figures 	     #
# specified are preliminary based on current expectations, and are	     #
# subject to change without notice.					     #
##############################################################################

##############################################################################
# Intel Top Secret                                                           #
# Author: Chang-Tsung Fu, Mauricio Marulanda
# Description:
#   Type >> runCrisp.py -h 
##############################################################################
import argparse, os, tempfile, re, sys, operator
sys.path.append('/p/fdk/gwa/jmarulan/environment/myPython/lib/python'); sys.path.append('/p/fdk/gwa/jmarulan/utils/scripts'); sys.stderr.write('\n')
import jobFeed, crisp, csvUtils, itertools

## defaults
DEFAULTCRISP = '/nfs/site/eda/group/SYSNAME/tcad/common/netcap3d/v9.3/netcap3d' #updated v9.2->v9.3
DEFAULTQCAP = '/p/fdk/gwa/jmarulan/environment/myPython/lib/python'+{'fdk736':'/crisp/p1273_6x2r0.qcap','f12756':'/crisp/p1275_6x1r2u0.qcap','fdk735':'/crisp/p1273_5x0r0.qcap','f12752':'/crisp/p1275_2x1r3u0_tv1.bin.qcap'}.get(os.getenv('PROJECT')+os.getenv('FDK_DOTPROC'))
##updated the f12756 qcap to x2r1u0

## arguments fns
def checkCrisp(ff):
  if os.path.isfile(ff): return os.path.realpath(ff)
  else: raise IOError('Crisp executable invalid: '+ff) 

def checkQcap(ff):
  if os.path.isfile(ff) and os.path.splitext(ff)[1]=='.qcap': return os.path.realpath(ff)
  else: raise IOError('qcap file does not exist or not valid: '+ff)

def checkGds(ff): #return [cellName,gdsFullPath,ports]
  temp = os.path.splitext(os.path.basename(ff))
  if os.path.isfile(ff) and temp[1]=='.gds': 
    return [(temp[0],os.path.realpath(ff),'')]
  elif os.path.isfile(ff) and temp[1]=='.csv': 
    csv = csvUtils.dFrame(ff);
    if not('gds' in csv.keys() and 'ports' in csv.keys()): raise argparse.ArgumentTypeError('CSV file has bad headers :'+','.join(csv.keys()))
    return [(os.path.splitext(os.path.basename(gds))[0],os.path.realpath(gds),csv['ports'][ii]) for ii,gds in enumerate(csv['gds']) if (gds and csv['ports'][ii] and os.path.isfile(gds))]
  else: raise IOError('gds does not exist: '+ff)

def attachPortsToGdsAndFlatten(): #GDS inputs get the args.ports and create a list of cellName,gdsFullPath,ports components
  args.gds_or_csv = list(itertools.chain(*args.gds_or_csv))
  for ii,entry in enumerate(args.gds_or_csv):
    if entry[2] == '': args.gds_or_csv[ii] = args.gds_or_csv[ii][0:2]+tuple([' '.join(args.ports)])
  args.gds_or_csv = set(args.gds_or_csv)
##

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
argparser = argparse.ArgumentParser(add_help=False)
argparser.add_argument('-qcap', dest='qcap',default=DEFAULTQCAP,type=checkQcap,help='Technology QCap file.')
argparser.add_argument('-ports', dest='ports', nargs='+', default=['mfcport1','mfcport2'], help='Ports to be extracted, applied to all gds inputs and ignore for csv inputs (default: mfcport1 mfcport2)')
argparser.add_argument('-outdir', dest='outdir', default='.', help='Working directory, defaults to current')
argparser.add_argument('-jobs', dest='count', default=1, type=int, help='Max number of job(s) in parallel')
argparser.add_argument('-nb', dest='nb',help=argparse.SUPPRESS,action='store_const',default='',const='NETBATCH_CMD: nbjob run --target pdx_vpnb --class SLES11_EM64T_16G --qslot /icf/fdk/pck_max\nNETBATCH_POOL: pdx_normal')
argparser.add_argument('-time', dest='time',default=60, type=int,help=argparse.SUPPRESS)
argparser.add_argument('-crisp', dest='crisp', default=DEFAULTCRISP, type=checkCrisp, help='netcap3d path')
argparser.add_argument('-csv', dest='csvFile', action='store_true', help='store results in a csv file: "crisp_*.csv"')
group2 = argparser.add_argument_group('get results only optional argument'); group2.add_argument('-readonly', dest='dir', help='Target directory where crisp was previously run (other arguments ignored, except "-csv")')
tempParse = argparser.parse_known_args() #partially parse to see if readonly came up 
fargparser = argparse.ArgumentParser(parents=[argparser],description='Runs crisp, make sure CRISP version and QCAP files are compatible, both are available as optional inputs. If ICV fails try overwriting ICVhome with\n >> setenv ICV_HOME_DIR "/p/foundry/eda/em64t_SLES11/icvalidator/K-2015.06-SP1"')
fargparser.add_argument(dest='gds_or_csv',nargs = '+',type=checkGds, help='GDS file(s) or CSV file(s), csv file must have headings "gds,ports" (ports to be separted by space)')
if not( ('-h' in tempParse[1] or '--help' in tempParse[1]) or any(tempParse[1])) and tempParse[0].dir: readOnly(tempParse[0].dir,tempParse[0].csvFile); exit(0) ## Read ONLY
args = fargparser.parse_args(); attachPortsToGdsAndFlatten(); sys.stderr.write('QCAP_FILE: '+args.qcap+'\n')
##############################################################################
## create working temp dir
tempDir=tempfile.mkdtemp(prefix='crisp_',dir=args.outdir)
stdin = tempfile.TemporaryFile(); stdin.write('no\n'); jobs=[]; crispObjs=[]; oneSucceed=False
## run for each gds input
for gds in args.gds_or_csv:
  crispObjs.append(crisp.crispClass(tempDir,gds,args.qcap,args.nb,args.time))   ## create necessary files
  jobs.append(crispObjs[-1].run(args.crisp,stdin))   ## run the files    
  if len(jobs) >= args.count: jobFeed.waitForJobs(jobs)    ## wait if the count is reached
jobFeed.waitForJobs(jobs)
stdin.close(); 
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
