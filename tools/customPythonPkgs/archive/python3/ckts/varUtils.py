##############################################################################
# Intel Top Secret                                                           #
##############################################################################

def createHspStr(include,model,temp,vac,freq,volts):
  hspTxt = '''* simulate Y-par
.option speedmode=0 level=23 shrink=1.00
.temp '''+temp+''' 
'''+include+'''
vpp p_ehv 0 dc=vp ac='''+vac+''',0 
vnn n_ehv 0 dc=vp ac='''+vac+''',180 
vctr vnwell_ehv 0 dc=0
T-xyz n_ehv p_ehv vnwell_ehv 0 N=4 '''+model+''' level=2
.op
.acswp vp '''+(' '.join(map(str,volts)))+''' FREQ='''+str(freq)+''' 
.print ac ir(vnn) ii(vnn)
.END\n'''
  return hspTxt

def readOutput(dataFile):
  import re
  numExp = '([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)';       
  ## open the file and get the results
  with open(dataFile) as fidIn:
    volt=[]; Ire = []; Iim = []; fetch=0
    for line in fidIn:
      if re.search(r'^\s*"\s*curve',line,flags=re.I): fetch+=1; continue
      test = re.search(r'^\s*'+numExp+'\s+'+numExp, line, flags=re.I)
#      if test and abs(float(test.group(1))-0)<1e-6: continue #skip the zero voltage
      if test and fetch == 1: volt.append(float(test.group(1))); Ire.append(1e-3*float(test.group(2)))#current comes in mA, making them Amps
      if test and fetch == 2: Iim.append(1e-3*float(test.group(2))) #current comes in mA, making them Amps
    return volt,Ire,Iim

# Calculate Q,C, and R
def getQCR(vac,Ire,Iim,freq):
  import math
  Qdiff=[]; Cdiff=[]; Rdiff=[]
  for re,im in zip(Ire,Iim):
    try: zd = 2*vac/complex(re,im)
    except ZeroDivisionError: zd=float('inf')
    try: yd = 1/zd
    except ZeroDivisionError: yd=float('inf')
    Qdiff.append(-zd.imag/zd.real); Rdiff.append(zd.real)
#    Cdiff.append(1e15*0.5*im/(2*math.pi*freq))
    Cdiff.append(1e15*yd.imag/(2*math.pi*freq))    
  return Qdiff,Cdiff,Rdiff

