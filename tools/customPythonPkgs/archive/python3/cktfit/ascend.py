def buildInit(workDir,spFile):
  import os
  workDirLabel = os.path.basename(workDir); spFile = os.path.realpath(spFile); workDir = os.path.realpath(workDir)
  ## constant stuff
  outStr = f'''
import numpy as np
from ascend.datamodel.study import Study
from ascend.datamodel.enum import Type, Objective

def init():
  asc = Study("SiCT_Fit_{workDirLabel}", "SiCT_Inductor", "Match an sparameter to a spice netlist")
  asc.compute.nbpool = "pdx_normal"
  asc.compute.nbqslot = "/adg/lvd/pd"
  asc.compute.nbclass = "SLES11&&4G&&nosusp"
  asc.user_function.ward_allocation = "mkward"
  asc.user_function.execution = "bbox_execution_cmd"
  # INPUTS
  inputs = asc.inputs;   outputs = asc.outputs;   
  x1  = inputs.add("CC",   "input1", Type.FLOAT, np.arange(0.0, 1000, 1.0), 100.0) #femto
  x2  = inputs.add("LS",   "input2", Type.FLOAT, np.arange(0.0,  5.0, 0.1), 1.0) #nano
  x3  = inputs.add("RS",   "input3", Type.FLOAT, np.arange(0.0,   50,   1), 1.0)  
  x4  = inputs.add("LSK",  "input4", Type.FLOAT, np.arange(0.0,  5.0, 0.1), 1.0)
  x5  = inputs.add("RSK",  "input5", Type.FLOAT, np.arange(0.0,  100,   1), 1.0)
  x6  = inputs.add("COX",  "input6", Type.FLOAT, np.arange(0.0, 1.0e3,1.0), 100.0)    
  x7  = inputs.add("COX3", "input7", Type.FLOAT, np.arange(0.0, 1.0e3,1.0), 100.0)    
  x8  = inputs.add("RSUB", "input8", Type.FLOAT, np.arange(0.0, 1.0e4,1.0), 10.0)
  x9  = inputs.add("RSUB3","input9", Type.FLOAT, np.arange(0.0, 1.0e4,1.0), 10.0)
  x10 = inputs.add("K12",  "input10",Type.FLOAT, np.arange(0.1,   0.9,0.1), 0.5)
  # OUTPUTS
  YL   = outputs.add("Lscore", "L score in flat range")
  YQ   = outputs.add("Qscore", "Q score around the peak")  
  YSRF = outputs.add("SRFscr", "SRF for freq and Q")  
  # SCORERS  
  equal_scorer = asc.scorers.add("Equal_weights_scorer")
  equal_scorer.add(YL, 1, Objective.MINIMIZE)  
  equal_scorer.add(YQ, 1, Objective.MINIMIZE)
  equal_scorer.add(YSRF, 1, Objective.MINIMIZE)  
  # DEFAULTS OVERWRITTEN
  asc.iterations.defaults.scorer = equal_scorer
  asc.iterations.defaults.seeds = 1
  i0 = asc.iterations.add(100)
  i1 = asc.iterations.add(100)
  i2 = asc.iterations.add(100)
  i3 = asc.iterations.add(100)
  i4 = asc.iterations.add(100)    
  i5 = asc.iterations.add(100)      
  i6 = asc.iterations.add(100)        
  i7 = asc.iterations.add(100)        
  i8 = asc.iterations.add(100)        
  i9 = asc.iterations.add(100)        
  return asc  
  
def mkward(run_info):
  ward = f'{workDir}/{{run_info.run_id}}'
  return ward
  
def bbox_execution_cmd(run_info):
  spFile = '{spFile}'
  cmd = f'matchSpToRlckSngl.py {{spFile}} -fromCktCsv {{run_info.ward}}/.ascend/plan.csv -toCsv {{run_info.ward}}/.ascend/output.csv'
  return cmd
'''
  return outStr
