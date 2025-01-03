import os, pandas as pd

class init:

  def __init__(self,workDir,inputs,outputs,iterations,bbScript):
    self.ward = os.path.realpath(workDir)
    wardLabel = os.path.basename(workDir);
    ## constant stuff
    outStr = f'''
import numpy as np
from ascend.datamodel.study import Study
from ascend.datamodel.enum import Type, Objective

def init():
  asc = Study("SIW_{wardLabel}", "AnalogCkts", "Optimize an analog ckt")
  asc.compute.nbpool = "pdx_normal"
  asc.compute.nbqslot = "/adg/lvd/pd"
  asc.compute.nbclass = "SLES11&&4G&&nosusp"
  asc.user_function.ward_allocation = "mkward"
  asc.user_function.execution = "bbox_execution_cmd"
  inputs = asc.inputs; outputs = asc.outputs\n'''
    ## inputs given by dictionary (key == name) and the list of values, first value is the type
    outStr += f'  # INPUTS\n'
    for ii,(name,lst) in enumerate(inputs.items()):
      tipo,default,items = lst[0],lst[1],(','.join(lst[1:]))
      if tipo == 'STRING': items = '"'+items.replace(',','","')+'"'; default = f'"{lst[1]}"'
      outStr += f'  x{ii} = inputs.add("{name}", "input{ii}", Type.{tipo}, [{items}],{default})\n' 
    ## output given by dictionary (key == name, item is the description)
    outStr += f'  # OUTPUTS\n'
    for ii,(name,desc) in enumerate(outputs.items()):
      outStr += f'  Y{ii} = outputs.add("{name}", "{desc}")\n' 
    ## constant stuff
    outStr += f'  # SCORERS\n  equal_scorer = asc.scorers.add("Equal_weights_scorer")\n'
    for ii,(name,desc) in enumerate(outputs.items()): 
      if isinstance(desc,str): outStr += f'  equal_scorer.add(Y{ii},1, Objective.MINIMIZE)\n'
    ## iterations
    outStr += '  # ITERATIONS\n  asc.iterations.defaults.scorer = equal_scorer\n  asc.iterations.defaults.seeds = 1\n'
    for ii in range(iterations[0]): outStr += f'  i{ii} = asc.iterations.add({iterations[1]})\n'
    outStr += '  return asc\n'
    ## make directory
    outStr += f'\ndef mkward(run_info):\n  ward = f"{self.ward}/{{run_info.run_id}}"\n  return ward\n'
    ## blackbox script
    outStr += f'\n{bbScript}\n'
    ## print to the file
    self.config = f'{self.ward}/config.py'
    with open(self.config,'w') as fout: fout.write(outStr)

def inCsvToDict(csv):
  outDt = {}
  df = pd.read_csv(csv,header=None,comment='#')
  for name,value in zip(df[0],df[1]): outDt[name]=value
  return outDt

def dictToCsv(dt,csv):
  with open(csv,'w') as fout:
    for name,value in dt.items(): fout.write(f'{name},{value}\n')
