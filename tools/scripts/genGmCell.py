#!/usr/bin/env python3.7.4
import argparse, sys, os, vco, tempfile, subprocess, ascendtools, socket

def simulateGmCell(tech,freq,inCsv,outCsv):
  try:
    # convert the input csv to a dictionary
    dt = ascendtools.inCsvToDict(inCsv)
    gmcell = vco.gmcell(tech,**dt)
    runDir = gmcell.runSim(freq,vdd=1,**dt)
    print(f'runfolder -> {socket.gethostname()}: {runDir}')
    gm = gmcell.readOutput();
  except:print('combination failed, output set to worst'); gm = 1e9    
  # convert the output to a csv
  dt = {'gm':gm*1e3};  
  if outCsv: ascendtools.dictToCsv(dt,outCsv)
  else: print(dt)

def createBbCmd(tech,freq):
  outStr = f"""def bbox_execution_cmd(run_info):
  cmd = f'genGmCell.py {tech} -freq {freq} -incsv {{run_info.ward}}/.ascend/plan.csv -outcsv {{run_info.ward}}/.ascend/output.csv'
  return cmd\n"""
  return outStr
 
##############################################################################
# Argument Parsing
##############################################################################
argparser = argparse.ArgumentParser(description='Generate optimized gm cell')
argparser.add_argument(dest='tech', choices = ['1231'], help='Technology node')
argparser.add_argument('-freq', dest='freq', default='54G', required=True,help='Frequency of operation')
argparser.add_argument('-incsv', dest='inCsv', help=argparse.SUPPRESS)
argparser.add_argument('-outcsv', dest='outCsv', help=argparse.SUPPRESS)
args = argparser.parse_args()

##############################################################################
# execute the cell from input.csv and generate output.csv
##############################################################################
if args.inCsv:
  simulateGmCell(args.tech,args.freq,args.inCsv,args.outCsv) 
  exit()
##############################################################################
# get the best version based on the range below
##############################################################################
ward = tempfile.mkdtemp(prefix=f'ascendGm_',dir='.')  
bbCmd = createBbCmd(args.tech,args.freq)
inputs={
'xtrW':['CONTINUOUS','11.52e-6','1.08e-3'],
'xtrL':['STRING','30n','35n','40n','50n','70n','90n','130n','180n','250n'],
'xtrNF':['STRING']+[str(ii) for ii in range(1,65)],
'tfrW':['CONTINUOUS','230e-9','1e-6'],
'tfrL':['CONTINUOUS','1e-9','19.4e-6'],
'mimNX':['STRING']+[str(ii) for ii in range(1,100)],
'mimNY':['STRING']+[str(ii) for ii in range(1,89)],
'vbias':['CONTINUOUS','0.5','1.0'],
'ven':['CONTINUOUS','0.0','1.0']}
outputs={'gm':'GM which is Negative Resistance'}
## run init
gmOpt = ascendtools.init(ward,inputs=inputs,outputs=outputs,iterations=[10,100],bbScript=bbCmd)
cmd = f'cd {ward}; ascend init {gmOpt.config}'
subprocess.run(cmd,shell=True)
## run ascend
cmd = f'cd {ward}; ascend run'
subprocess.run(cmd,shell=True)
 


