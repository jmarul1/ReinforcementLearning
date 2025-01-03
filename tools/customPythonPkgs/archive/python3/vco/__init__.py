import tempfile, numtools, subprocess, os, re, math, numpy, scipy.interpolate, socket ; from . import utils, netlists

################
### GM CELL  ###
################
class gmcell():

  def __init__(self,tech,xtrW='10u',xtrL='90n',xtrNF='1',tfrW='230n',tfrL='650n',mimNX='10',mimNY='10',pins=['ip','in','tail','en','vdd','vss'],**kwards):
    ## self.inputs, self.outputs are dictionaries which contain the variables          
    self.pP,self.nP,self.tailP,self.enP,self.vddP,self.vssP = pins;    self.tech = tech;      self.pgP,self.ngP = 'ipg','ing'
    self.body = f'''//gmcell
XMN1_gm ({self.nP} {self.ngP} {self.tailP} {self.vssP}) {netlists.transistor(tech,'n',xtrW,xtrL,xtrNF)}
XMN0_gm ({self.pP} {self.pgP} {self.tailP} {self.vssP}) {netlists.transistor(tech,'n',xtrW,xtrL,xtrNF)}
R1_gm ({self.ngP} {self.enP} {self.vddP}) {netlists.resistor(tech,tfrW,tfrL)}
R0_gm ({self.pgP} {self.enP} {self.vddP}) {netlists.resistor(tech,tfrW,tfrL)}
C1_gm ({self.nP} {self.pgP}) {netlists.capacitor(tech,mimNX,mimNY)}
C0_gm ({self.pP} {self.ngP}) {netlists.capacitor(tech,mimNX,mimNY)}'''   
  
  def runSim(self,freq,vdd=1,vbias=1,ven=0,**kwards): 
    ## add include files, simulation parameters, and options
    f = numtools.getScaleNum(freq); f1,f2 = f*0.95,f*1.05
    header = '**MAIN**\nsimulator lang = spectre\n' + utils.getIncludes(self.tech)
    subckt = utils.idealBalun(); footer = utils.getOptions()
    biasing = f'V4 ({self.tailP} {self.vssP}) vsource dc=0 type=dc\nV3 ({self.vssP} 0) vsource dc=0 type=dc\nV2 ({self.vddP} {self.vssP}) vsource dc={vdd} type=dc\nV1 (bias {self.vssP}) vsource dc={vbias} type=dc\nV0 ({self.enP} {self.vssP}) vsource dc={ven} type=dc'
    sims = f'I0 (diffout bias {self.nP} {self.pP}) ideal_balun\nPORT0 (diffout {self.vssP}) port r=50 type=sine\nsp sp ports=[PORT0] start={f1} stop={f2} annotate=status file="output.s1p" datafmt=touchstone' 
    self.netlist = f'{header}\n{subckt}\n{self.body}\n{biasing}\n{sims}\n{footer}'
    ## Create the file
    self.tempDir = tempfile.mkdtemp(); self.scs = tempfile.mkstemp(dir=self.tempDir,suffix='.scs')[1]
    with open(self.scs,'w') as fOut: fOut.write(self.netlist)
    ## Run
    subprocess.run(f'cd {self.tempDir}; spectre -f psfascii {self.scs}',shell=True,capture_output=True,timeout=10*60) #wait 10 minutes
    return self.tempDir

  def readOutput(self):
    outF = f'{os.path.splitext(self.scs)[0]}.raw/sp.sp';   numExp = '([+-]?\d+(?:\.\d*)?(?:[eE][+-]?\d+)?)'
    with open(outF) as fin:
      fetch = impedence = False; gmLst = []
      for line in fin:
        test = re.search(f'\w+:r"\s+{numExp}',line)
        if test: impedence = float(test.group(1))
        if re.search(r'\s*^VALUE',line): fetch = True; continue
        if fetch and impedence:
          test = re.search(f'"[sS]11".*?{numExp}\s+{numExp}', line) # real  imaginary
          if test: sp = float(test.group(1)) + 1j*float(test.group(2)); yp = (1/impedence)*(1-sp)/(1+sp); gmLst.append(yp.real);# print(yp.real)
    return sum(gmLst)/len(gmLst)

################
### TANKCELL ###
################
class tankCell():

  def __init__(self,tech,xtrW='10u',xtrL='90n',xtrNF='1',tfrW='230n',tfrL='650n',mimNX='10',mimNY='10',spFile=None,L=None,R=None,pins=['ip','in','bias','vdd','vss'],banks=['vctrl0'],**kwards):
    self.pP,self.nP,self.biasP,self.vddP,self.vssP = pins; self.vctrls = banks; self.tech = tech; vctrls = utils.genVctrls(self.vctrls)
    self.body = f'Rhalf1_tank ({self.vssP} vddhalf {self.vddP}) {netlists.resistor(tech,"230n","1u")}\nRhalf2_tank ({self.vddP} vddhalf {self.vddP}) {netlists.resistor(tech,"230n","1u")}\n'
    for cb,vctrl in enumerate(vctrls):## construct channel by channel
      self.body += f'''//lctank
XMNS{cb}_tank (netleft{cb} {vctrl} netright{cb} {self.vssP}) {netlists.transistor(tech,'n',xtrW,xtrL,xtrNF)}
R{cb}_tank (vddhalf vctrlb{cb} {self.vddP}) {netlists.resistor(tech,"230n","1u")}
XMNI{cb}_tank (vctrlb{cb} {vctrl} {self.vssP} {self.vssP}) {netlists.transistor(tech,'n',"1.168u","30n","1")}
Rpulla{cb}_tank (vctrlb{cb} netleft{cb} vddhalf) {netlists.resistor(tech,tfrW,tfrL)}
Rpullb{cb}_tank (vctrlb{cb} netright{cb} vddhalf) {netlists.resistor(tech,tfrW,tfrL)}
Cleft{cb}_tank ({self.pP} netleft{cb}) {netlists.capacitor(tech,mimNX,mimNY)}
Cright{cb}_tank (netright{cb} {self.nP}) {netlists.capacitor(tech,mimNX,mimNY)}'''
    if spFile or (L and R): self.indInsts,body = utils.inlineInd([self.pP,self.nP,self.biasP],spFile,L,R,suffix='_tank'); self.body+=body

  def runSim(self,freq,vctrls,caponly=False,vdd=1,vbias=1,**kwards): 
    ## add include files, simulation parameters, and options
    f = numtools.getScaleNum(freq); f1,f2 = f*0.95,f*1.05
    header = '**MAIN**\nsimulator lang = spectre\n' + utils.getIncludes(self.tech)
    subckt = utils.idealBalun(); footer = utils.getOptions()
    biasing = f'V3 ({self.vssP} 0) vsource dc=0 type=dc\nV2 ({self.vddP} {self.vssP}) vsource dc={vdd} type=dc\nV1 ({self.biasP} {self.vssP}) vsource dc={vbias} type=dc'
    controls = '\n'.join([f'VC{ii} ({self.vctrls[ii]} {self.vssP}) vsource dc={vc} type=dc' for ii,vc in enumerate(vctrls)])
    sims = f'I0 (diffout {self.biasP} {self.nP} {self.pP}) ideal_balun\nPORT0 (diffout {self.vssP}) port r=50 type=sine\nsp sp ports=[PORT0] start={f1} stop={f2} annotate=status file="output.s1p" datafmt=touchstone' 
    self.netlist = f'{header}\n{subckt}\n{self.body}\n{biasing}\n{controls}\n{sims}\n{footer}'
    ## Create the file
    self.tempDir = tempfile.mkdtemp(); self.scs = tempfile.mkstemp(dir=self.tempDir,suffix='.scs')[1]
    if caponly:
      for inst in self.indInsts: self.netlist = re.sub(f'\n{inst}\s.*?\n',r'\n',self.netlist)
    with open(self.scs,'w') as fOut: fOut.write(self.netlist)
    ## Run
    subprocess.run(f'cd {self.tempDir}; spectre -f psfascii {self.scs}',shell=True,capture_output=True,timeout=10*60) #wait 10 minutes
    return self.tempDir

  def readOutput(self):
    outF = f'{os.path.splitext(self.scs)[0]}.raw/sp.sp';   numExp = '([+-]?\d+(?:\.\d*)?(?:[eE][+-]?\d+)?)'
    with open(outF) as fin:
      fetch = impedence = False; capLst = []; rpLst = []
      for line in fin:
        test = re.search(f'\w+:r"\s+{numExp}',line)
        if test: impedence = float(test.group(1))
        if re.search(r'\s*^VALUE',line): fetch = True; continue
        if fetch and impedence:
          test = re.search(f'"freq".*?{numExp}', line) # freq
          if test: freq = float(test.group(1))
          test = re.search(f'"[sS]11".*?{numExp}\s+{numExp}', line) # real  imaginary
          if test: sp = float(test.group(1)) + 1j*float(test.group(2)); yp = (1/impedence)*(1-sp)/(1+sp); zp = 1/yp; capLst.append(yp.imag/(2*math.pi*freq)); rpLst.append(zp.real)
    return sum(capLst)/len(capLst),sum(rpLst)/len(rpLst) #cap,rp

################
### FULL VCO ###
################
class vcoCell():

  def __init__(self,tech,pins=['op','on','tail','en','bias','vdd','vss'],banks=['vctrl0'],**kwards):
    self.pP,self.nP,self.tailP,self.enP,self.biasP,self.vddP,self.vssP = pins; self.vctrls = banks; self.tech = tech
    dt = {re.sub('_gm','',kk):val for kk,val in kwards.items()}
    gmPkg = gmcell(tech,pins=[self.pP,self.nP,self.tailP,self.enP,self.vddP,self.vssP],**dt); self.pgP,self.ngP = gmPkg.pgP,gmPkg.ngP
    dt = {re.sub('_tank','',kk):val for kk,val in kwards.items()}
    lctankPkg = tankCell(self.tech,banks=self.vctrls,pins=[self.pP,self.nP,self.biasP,self.vddP,self.vssP],**dt)
    self.body = gmPkg.body +'\n'+ lctankPkg.body

  def runSim(self,vctrls,vdd=1,vbias=1,ven=1,load=None,**kwards): 
    vbias = float(vbias); self.vbias = vbias
    header = '**MAIN**\nsimulator lang = spectre\n' + utils.getIncludes(self.tech); footer = utils.getOptions()
    biasing = f'V4 ({self.tailP} {self.vssP}) vsource dc=0 type=dc\nV3 ({self.vssP} 0) vsource dc=0 type=dc\nV2 ({self.vddP} {self.vssP}) vsource dc={vdd} type=dc\nVpower ({self.biasP} {self.vssP}) vsource dc={vbias} type=dc\nV0 ({self.enP} {self.vssP}) vsource dc={ven} type=dc'
    controls = '\n'.join([f'VC{ii} ({self.vctrls[ii]} {self.vssP}) vsource dc={vc} type=dc' for ii,vc in enumerate(vctrls)])
    ics = f'ic {self.pgP}={vbias-0.1} {self.nP}={vbias-0.1} {self.ngP}={vbias+0.1} {self.pP}={vbias+0.1}'
    sims = f'dcOp dc write="spectre.dc" save=all maxiters=150 maxsteps=10000 annotate=status\nhbAnal ({self.pP} {self.nP}) hb autoharms=yes autotstab=yes oversample=[1] fundfreqs=[(25G)] maxharms=[5] errpreset=moderate oscic=lin oscmethod=onetier annotate=status\
             \nhbnoiseAnal ({self.pP} {self.nP}) hbnoise sweeptype=relative relharmvec=[1] start=10k stop=3G maxsideband=7 noisetype=timeaverage noiseout=[pm] annotate=status'
    self.netlist = f'{header}\n{self.body}\n{biasing}\n{controls}\n{ics}\n{sims}\n{footer}'
    ## Create the file
    self.tempDir = tempfile.mkdtemp(); self.scs = tempfile.mkstemp(dir=self.tempDir,suffix='.scs')[1]
    with open(self.scs,'w') as fOut: fOut.write(self.netlist)
    ## Run
    print(f'runfolder -> {socket.gethostname()}: {self.tempDir}')    
    log = tempfile.TemporaryFile()
    run = subprocess.run(f'cd {self.tempDir}; spectre -f psfascii {self.scs}',shell=True,stdout=log,stderr=log,timeout=10*60) #wait 10 minutes
    return self.tempDir

  def readOutput(self,spotF1,spotF2):
    outF = f'{os.path.splitext(self.scs)[0]}.raw/hbAnal.fi.pss_hb';   numExp = '([+-]?\d+(?:\.\d*)?(?:[eE][+-]?\d+)?)';   
    with open(outF) as fin:
      start = freq = op = on = ivdd = False; fLst,vLst,pLst = [],[],[]
      for line in fin:
        if re.search(r'^\s*VALUE',line): start=True
        if not start: continue
        test = re.search(f'"freq"\s+{numExp}',line)
        if test: freq = test.group(1); continue
        test = re.search(f'"{self.pP}".*?{numExp}\s+{numExp}',line)
        if freq and test: op = float(test.group(1)) + 1j*float(test.group(2))
        test = re.search(f'"{self.nP}".*?{numExp}\s+{numExp}',line)
        if freq and test: on = float(test.group(1)) + 1j*float(test.group(2))
        test = re.search(f'"Vpower:p".*?{numExp}\s+{numExp}',line)
        if freq and test: ivdd = float(test.group(1)) + 1j*float(test.group(2))
        if freq and op and on and ivdd: vLst.append(abs(op-on)); fLst.append(float(freq)); pLst.append(abs(ivdd)*self.vbias); freq = op = on = False
      vppI = numpy.argmax(vLst); output = [fLst[vppI],vLst[vppI],pLst[0]]
    outF = f'{os.path.splitext(self.scs)[0]}.raw/hbnoiseAnal.pm.pnoise_hbnoise';
    with open(outF) as fin:
      start = noise = freq = False; fLst,noiseLst = [],[]
      for line in fin:
        if re.search(r'^\s*VALUE',line): start=True
        if not start: continue
        test = re.search(f'"relative frequency"\s+{numExp}',line)
        if test: freq = float(test.group(1)); continue
        test = re.search(f'"out"\s+{numExp}',line)
        if freq and test: noise = float(test.group(1))
        if freq and noise: fLst.append(freq); noiseLst.append(noise); freq=noise=False
      cubicS = scipy.interpolate.CubicSpline(fLst,noiseLst)
      n1M,n10M = cubicS([spotF1,spotF2]); nInt = cubicS.integrate(10e3,3e9).tolist()
      output += [20*math.log(n1M,10),20*math.log(n10M,10),nInt]
    return output
