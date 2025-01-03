#!/usr/bin/env python3.7.4
import argparse, sys, os, vco, tempfile, subprocess, ascendtools, numtools, sparameter

def simulateCell(tech,freq,banks,inCsv,outCsv):
  freq = numtools.getScaleNum(freq);
  bankPins = [f'vctrl{ii}' for ii in range(len(banks))]   
  try:
    dt = ascendtools.inCsvToDict(inCsv)     # convert the input csv to a dictionary
    vcoObj = vco.vcoCell(tech,**dt,banks=bankPins)
    runDir = vcoObj.runSim(banks,vdd=3,**dt)   ## run harmonic balance
    oscfreq,vpp,power,n1M,n10M,nInt = vcoObj.readOutput(1e6,10e6)
    oscFreqCost = ((oscfreq - freq)*1e-9)**2; vppCost = vpp*-1; 
  except: 
    print('combination failed, output set to worst'); oscFreqCost,vppCost,power,nInt = 1e9,1e9,1e9,1e9; oscfreq,vpp,n1M,n10M = 0,0,1e9,1e9
  finally:  
    dt = {'oscFreqCost':oscFreqCost,'vppCost':vppCost,'power':power,'noiseInt':nInt};    # convert the output to a csv
   # dt = {'oscFreqCost':oscFreqCost,'vppCost':vppCost,'power':power,'oscfreq':'{oscfreq*1e-9:.3f}G','vpp':vpp,'noiseInt':nInt,'noise1M':'{n1M:.3f}dbV/Hz','noise10M':'{n10M:.3f}dbV/Hz'};    # convert the output to a csv
    if outCsv: ascendtools.dictToCsv(dt,outCsv)
    else: print(dt); print(f'oscfreq={oscfreq*1e-9:.3f}G  vpp={vpp:.3f}V  power={power*1e3:.3f}mW  noiseInt={nInt:.3f}V  noise1M={n1M:.3f}dbV/Hz  noise10M={n10M:.3f}dbV/Hz')  
  return 0

def createBbCmd(tech,freq,banks):
  banks = ' '.join(banks)
  outStr = f"""def bbox_execution_cmd(run_info):
  cmd = f'genVcoCell.py {tech} -freq {freq} -banks {banks} -incsv {{run_info.ward}}/.ascend/plan.csv -outcsv {{run_info.ward}}/.ascend/output.csv'
  return cmd\n"""
  return outStr

##############################################################################
# Argument Parsing
##############################################################################
argparser = argparse.ArgumentParser(description='Generate optimized gm cell')
argparser.add_argument(dest='tech', choices = ['1231'], help='Technology node')
argparser.add_argument('-freq', dest='freq', required = True, help='Frequency of operation')
argparser.add_argument('-banks', dest='banks', choices = ['-1','0','1'], nargs='+', required = True, help='Value for each bank, len of values sets the number of banks')
argparser.add_argument('-incsv', dest='inCsv', help=argparse.SUPPRESS)
argparser.add_argument('-outcsv', dest='outCsv', help=argparse.SUPPRESS)
args = argparser.parse_args()

##############################################################################
# execute the cell from input.csv and generate output.csv
##############################################################################
if args.inCsv:
  simulateCell(args.tech,args.freq,args.banks,args.inCsv,args.outCsv) 
  exit(0)
  
##############################################################################
# get the best version based on the range below
##############################################################################
ward = tempfile.mkdtemp(prefix=f'ascendVco_',dir='.')  
bbCmd = createBbCmd(args.tech,args.freq,args.banks)
inputs={
'xtrW_gm':['CONTINUOUS','1.168e-6','30e-6'],
'xtrL_gm':['STRING','30n','35n','40n','50n','70n','90n','130n','180n','250n'],
'xtrNF_gm':['STRING']+[str(ii) for ii in range(1,65)],
'tfrW_gm':['CONTINUOUS','230e-9','1e-6'],
'tfrL_gm':['CONTINUOUS','1e-9','19.4e-6'],
'mimNX_gm':['STRING']+[str(ii) for ii in range(1,100)],
'mimNY_gm':['STRING']+[str(ii) for ii in range(1,89)],
'xtrW_tank':['CONTINUOUS','1.168e-6','30e-6'],
'xtrL_tank':['STRING','30n','35n','40n','50n','70n','90n','130n','180n','250n'],
'xtrNF_tank':['STRING']+[str(ii) for ii in range(1,65)],
'tfrW_tank':['CONTINUOUS','230e-9','1e-6'],
'tfrL_tank':['CONTINUOUS','1e-9','19.4e-6'],
'mimNX_tank':['STRING']+[str(ii) for ii in range(1,100)],
'mimNY_tank':['STRING']+[str(ii) for ii in range(1,89)],
'L':['CONTINUOUS','50e-12','1.0e-9'], 'R':['CONTINUOUS','1.0','20.0'], #later to be a list of files
'vbias':['CONTINUOUS','1.0','3.0'],
'ven':['CONTINUOUS','-1.0','1.0'],}
outputs={
'oscFreqCost':'Square delta to target frequency',
'vppCost':'Square delta to maximize the -ve peakToPeak Voltage',
'power':'Minimization of the power',
'noiseInt':'Minimization of the integrated noise'}
#'oscfreq':['Oscillation Frequency, not for study'],'vpp':['peakToPeak'],'n1M':['Spot Noise at 1M'],'n10M':['Spot Noise at 10M']}
## run init
tankOpt = ascendtools.init(ward,inputs=inputs,outputs=outputs,iterations=[100,100],bbScript=bbCmd)
cmd = f'cd {ward}; ascend init {tankOpt.config}'
subprocess.run(cmd,shell=True)
## run ascend
cmd = f'cd {ward}; ascend run'
subprocess.run(cmd,shell=True)
 


