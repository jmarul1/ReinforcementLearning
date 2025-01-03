### Decipher the dimensions from the file names for varios devices

def getParamDims(fBaseName):
  import re; from . import mix
  fBaseName = mix.cleanUpFile(fBaseName)
  shuttle,deemb,rem = mix.shuttleDut(fBaseName) # extract shuttle info first
  paramDimDt,rem = mix.getParamsFromName(rem)   # get the geometry and skew
  if shuttle: paramDimDt['shuttle'] = shuttle;  # get the shuttle if exists
  if deemb: paramDimDt['deemb'] = deemb         # get the deembedded if exists
  if rem != '':
    if shuttle: paramDimDt['dut'] = rem.strip('_'); #put everything in the dut if shuttle
    else:     paramDimDt['other'] = rem.strip('_')
  return list(paramDimDt.keys()),list(paramDimDt.values())


