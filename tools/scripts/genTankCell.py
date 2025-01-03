#!/usr/bin/env python3.7.4
import argparse, sys, os, vco, tempfile, subprocess, ascendtools, socket, numtools, sparameter

def simulateGmCell(tech,freq,banks,inCsv,outCsv):
  freq = numtools.getScaleNum(freq);
  bankPins = [f'vctrl{ii}' for ii in range(len(banks))]   
  try:
    dt = ascendtools.inCsvToDict(inCsv)     # convert the input csv to a dictionary
    lctank = vco.tankCell(tech,**dt,banks=bankPins,vdd=3);
    runDir = lctank.runSim(freq,vctrls=banks,caponly=True,vdd=1)
    cap,rpdum = lctank.readOutput(); L = getInductance(dt['spFile'],freq) if 'spFile' in list(dt.keys()) else numtools.getScaleNum(dt['L'])
    oscFreq = 1/(2*3.1416)/(L*cap)**0.5
    runDir = lctank.runSim(freq,vctrls=banks,vdd=3)
    capdum,rp = lctank.readOutput()
    oscFreqCost,rpInv = (abs(freq - oscFreq)*1e-9)**2,abs(1e3/rp)     
    print(f'runfolder -> {socket.gethostname()}: {runDir}')    
  except: print('combination failed, output set to worst'); oscFreqCost,rpInv=1e90,1e90
  dt = {'oscFreqCost':oscFreqCost,'rpInv':rpInv};    # convert the output to a csv
  if outCsv: ascendtools.dictToCsv(dt,outCsv)
  else: print(dt); print(f'cap={cap*1e15} freq={oscFreq*1e-9} rp={rpInv}')

def createBbCmd(tech,freq,banks):
  banks = ' '.join(banks)
  outStr = f"""def bbox_execution_cmd(run_info):
  cmd = f'genTankCell.py {tech} -freq {freq} -banks {banks} -incsv {{run_info.ward}}/.ascend/plan.csv -outcsv {{run_info.ward}}/.ascend/output.csv'
  return cmd\n"""
  return outStr

def getInductance(spFile,freq):
  sp = sparameter.read(spFile)
  Qd,Ld,Qse,Lse,Rd,Rse,k12 = sp.getQLR()
  index = numtools.closestNum(sp.freq,freq,1)
  if numtools.isNumber(index): return 0
  else: return Ld[index]  


##############################################################################
# Argument Parsing
##############################################################################
argparser = argparse.ArgumentParser(description='Generate optimized gm cell')
argparser.add_argument(dest='tech', choices = ['1231'], help='Technology node')
argparser.add_argument('-freq', dest='freq', default='54G', required = True, help='Frequency of operation')
argparser.add_argument('-banks', dest='banks', default=['1'], choices = ['-1','0','1'], nargs='+', required = True, help='Value for each bank, len of values sets the number of banks')
argparser.add_argument('-incsv', dest='inCsv', help=argparse.SUPPRESS)
argparser.add_argument('-outcsv', dest='outCsv', help=argparse.SUPPRESS)
args = argparser.parse_args()

##############################################################################
# execute the cell from input.csv and generate output.csv
##############################################################################
if args.inCsv:
  simulateGmCell(args.tech,args.freq,args.banks,args.inCsv,args.outCsv) 
  exit()
##############################################################################
# get the best version based on the range below
##############################################################################
ward = tempfile.mkdtemp(prefix=f'ascendTank_',dir='.')  
bbCmd = createBbCmd(args.tech,args.freq,args.banks)
inputs={
'xtrW':['CONTINUOUS','1.168e-6','30e-6'],
'xtrL':['STRING','30n','35n','40n','50n','70n','90n','130n','180n','250n'],
'xtrNF':['STRING']+[str(ii) for ii in range(1,65)],
'tfrW':['CONTINUOUS','230e-9','1e-6'],
'tfrL':['CONTINUOUS','1e-9','19.4e-6'],
'mimNX':['STRING']+[str(ii) for ii in range(1,100)],
'mimNY':['STRING']+[str(ii) for ii in range(1,89)],
'vbias':['CONTINUOUS','1.0','3.0'],
'L':['CONTINUOUS','50e-12','1.0e-9'],
'R':['CONTINUOUS','1.0','20.0']}
outputs={'oscFreqCost':'Square delta to target frequency','rpInv':'Rp value as small as possible'}
## run init
tankOpt = ascendtools.init(ward,inputs=inputs,outputs=outputs,iterations=[100,100],bbScript=bbCmd)
cmd = f'cd {ward}; ascend init {tankOpt.config}'
subprocess.run(cmd,shell=True)
## run ascend
cmd = f'cd {ward}; ascend run'
subprocess.run(cmd,shell=True)
 


