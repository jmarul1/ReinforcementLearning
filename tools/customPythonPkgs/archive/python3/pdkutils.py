def getCdlIncludes(): 
  import os, subprocess
  includes = []
  if os.getenv('INTEL_RF') and os.getenv('INTEL_PDK'): 
    beVar = os.getenv('INTEL_LAYERSTACK') if os.getenv('INTEL_LAYERSTACK') else ''
    stdCells = subprocess.Popen('find $INTEL_STDCELL/cdl -name \'*cdl\'',shell=True,stdout=subprocess.PIPE)
    stdCells = stdCells.communicate()[0].decode().split('\n')
    stdCells = list(filter(lambda ff: os.path.isfile(ff), stdCells))
    rfCdl = os.getenv('INTEL_PDK')+'/models/custom/cdl/'+beVar+'/intel22rf.cdl'
    if not os.path.isfile(rfCdl): rfCdl = os.getenv('INTEL_RF')+'/libraries/rf/cdl/be22/intel22rf.cdl'
    includes = stdCells + [rfCdl,
                           os.getenv('INTEL_PDK')+'/models/custom/cdl/'+beVar+'/intel22custom.cdl']
  return includes
