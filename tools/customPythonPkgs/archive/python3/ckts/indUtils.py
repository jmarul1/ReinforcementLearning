##############################################################################
# Intel Top Secret                                                           #
##############################################################################

def createHspStr(include,model,ports,temp,vac,freq,mode='diff'):
  cts = ' '.join(['10' for ii in range(ports - 2)])
  hspTxt = '''* simulate Y-par
.option speedmode=0 level=23 shrink=1.00 genK=0
.temp '''+temp+''' 
'''+include+'''
vpp p_ehv 0 dc=0 ac='''+(vac if mode =='diff' else '0')+''',0 
vnn n_ehv 0 dc=0 ac='''+vac+''',180 
T-xyz p_ehv n_ehv '''+cts+' N='+str(ports)+' '+model+''' level=1
.AC LIN '''+(' '.join(map(str,freq)))+'''
.print ac ir(vpp) ii(vpp) ir(vnn) ii(vnn) 
.END\n'''
  return hspTxt

def readOutput(dataFile):
  import re, numpy
  numExp = '([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)';       
  ## open the file and get the results
  with open(dataFile) as fidIn:
    freq=[]; IreP = []; IimP = []; IreN = []; IimN = []; fetch=0
    for line in fidIn:
      if re.search(r'^\s*"\s*curve',line,flags=re.I): fetch+=1; continue
      test = re.search(r'^\s*'+numExp+'\s+'+numExp, line, flags=re.I)
      if test and fetch == 1: freq.append(float(test.group(1))); IreP.append(-1e-3*float(test.group(2)))#current comes in mA, making them Amps
      if test and fetch == 2: IimP.append(-1e-3*float(test.group(2))) #current comes in mA, making them Amps
      if test and fetch == 3: IreN.append(1e-3*float(test.group(2))) #current comes in mA, making them Amps      
      if test and fetch == 4: IimN.append(1e-3*float(test.group(2))) #current comes in mA, making them Amps            
    Ire = numpy.mean([IreP,IreN],axis=0).tolist(); Iim = numpy.mean([IimP,IimN],axis=0).tolist();
    return freq,Ire,Iim

# Calculate Q,L, and R
def getQLR(vac,Ire,Iim,Freqs,mode):
  import math
  Qdiff=[]; Ldiff=[]; Rdiff=[]
  for freq,re,im in zip(Freqs,Ire,Iim):
    factor = 2 if mode == 'diff' else 1
    try: zd = factor*vac/complex(re,im)
    except ZeroDivisionError: zd=float('inf')
    Qdiff.append(zd.imag/zd.real); Rdiff.append(zd.real)
    Ldiff.append(1e9*zd.imag/(2*math.pi*freq)) #make inductance in nH    
  return Qdiff,Ldiff,Rdiff
