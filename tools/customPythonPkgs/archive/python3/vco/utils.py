import re, pandas as pd

def getIncludes(tech):
  if tech == '1231':
    includes = '''
include "$INTEL_PDK/models/core/spectre/p1231_0.scs" section=tttt
include "$INTEL_PDK/models/custom/spectre/intel31custom.scs"
include "$INTEL_PDK/models/custom/spectre/intel31diode.scs"
include "$INTEL_PDK/models/custom/spectre/intel31logic.scs" section=tttt'''  
  else: raise IOError(f'Wrong technology: {tech}')
  return includes

def idealBalun():
  return '''subckt ideal_balun d c p n
  K0 (d 0 p c) transformer n1=2
  K1 (d 0 c n) transformer n1=2
ends ideal_balun'''
  
def getOptions():
  footer = '''
simulatorOptions options reltol=1e-3 vabstol=1e-6 iabstol=1e-12 temp=27 tnom=27 scalem=1.0 scale=1.0 gmin=1e-12 rforce=1 maxnotes=5 maxwarns=5 digits=5 cols=80 pivrel=1e-3 sensfile="../psf/sens.output" checklimitdest=psf 
modelParameter info what=models where=rawfile
element info what=inst where=rawfile
outputParameter info what=output where=rawfile
designParamVals info what=parameters where=rawfile
primitives info what=primitives where=rawfile
subckts info what=subckts where=rawfile
saveOptions options save=allpub '''
  return footer

def genVctrls(ins):
  expIns = []
  for nn in range(len(ins)):
    for ii in range(2**nn): expIns.append(ins[nn])
  return expIns

def inlineInd(pins,spFile=None,L=None,R=None,suffix='',instCount=0):
  pP,nP,ct = pins
  if spFile: ckt = f'\nNPORT{instCount}{suffix} ({pP} 0 {nP} 0 {ct} 0) nport file="{spFile}" interp=spline'; inst = [f'NPORT{instCount}']
  else: L,R = float(L)/2,float(R)/2; ckt = f'\nL{instCount}{suffix} ({pP} {ct}) inductor l={L} r={R}\nL{instCount+1}{suffix} ({ct} {nP}) inductor l={L} r={R}'; inst = [f'L{instCount}',f'L{instCount+1}']
  return inst,ckt
