
def bruteForce(csvF):
  import pandas as pd, re, numtools, numpy as np, itertools, os
  ## read the csv
  csvDf = pd.read_csv(csvF,comment='#')
  csvDf = csvDf.dropna(how='all'); csvDf.columns = csvDf.columns.str.strip()
  ## keys to use
  keys = ['parameter','min','max','discrete','steps','type']  
  ## create a dictionary of parameters with discrete values or with the range
  dt = {}
  for ii,param in enumerate(csvDf[keys[0]].to_list()):
    minV,maxV,discrete,steps = [csvDf[kk][ii] for kk in keys[1:-1]]
    if not pd.isna(discrete): dt[param] = re.split(r'\s*,\s*', discrete.strip())
    else: 
      minV,maxV,steps = list(map(lambda ff: numtools.getScaleNum(ff), [minV,maxV,steps]))
      ranges = np.arange(minV,maxV+steps,steps)
      dt[param] = list(map(lambda ff: numtools.numToSi(ff,precision=3), ranges))
  ## create the full list and convert it pandas
  full = list(itertools.product(*[val for param,val in dt.items()]))
  outB = pd.DataFrame(full, columns = csvDf[keys[0]].to_list())
  outT = pd.DataFrame([csvDf[keys[-1]].to_list()],columns=csvDf[keys[0]],index=['type']) 
  out = pd.concat([outT,outB])
  return out
