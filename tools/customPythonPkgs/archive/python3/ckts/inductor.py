class inductor():
## initialize
  def __init__(self,model,ports,sim,temperature,mode):
    import re
    self.sim = sim
    self.temps = temperature
    self.model = model
    if sim == 'scs': self.portNames = re.findall(r'\S+',ports); ports = len(self.portNames)
    self.ports = int(ports)
    self.vac = '1'
    self.mode = mode
## simulate    
  def simulate(self,includes,skew,fF,sF,mF):
    import utils, subprocess, tempfile, indUtils, os, numtools, ckt, csvUtils
    engine = '/p/adx/x74c/cad_root11/lynx/17.4.0_64/bin/lynxSpice' if self.sim == 'hsp' else 'spectre'
    simDir = tempfile.mkdtemp(dir='/tmp');     
    simFile = 'ind_'+skew+'.'+self.sim
    if self.sim == 'hsp': 
      sF,fF,mF = map(numtools.getScaleNum,[sF,fF,mF]); sF = 1.0*(mF - fF) / sF
      with open(simDir+'/'+simFile,'wb') as fout: fout.write(indUtils.createHspStr(includes,self.model,self.ports,self.temps,self.vac,[sF,fF,mF],mode=self.mode))
      run = subprocess.Popen('cd '+simDir+'; '+engine+' '+simFile,shell=True,stdout=subprocess.PIPE)
      data = run.communicate()[0]
      results = 'ind_'+skew+'_1.split'
      if not os.path.isfile(simDir+'/'+results): raise IOError('Simulation did not work: '+simDir)
      subprocess.call('cd '+simDir+'; /nfs/pdx/home/jmarulan/work_area/utils/scripts/bin2ascii.pl '+results,shell=True,stdout=subprocess.PIPE)
      ## read the output
      freq,Ire,Iim = indUtils.readOutput(simDir+'/'+os.path.splitext(results)[0]+'.dat')
      ## get LQR
      Q,L,R = indUtils.getQLR(float(self.vac),Ire,Iim,freq,self.mode)
      freq = map(lambda ff: ff/1e9,freq) #make freq in GHz
      return freq,Q,L,R
    if self.sim == 'scs':
      sF,fF,mF = map(numtools.getScaleNum,[sF,fF,mF]);
      scsNameOut,outFName = ckt.createScsFile(simDir,self.model,self.portNames,[],fF,sF,mF)
      with open(scsNameOut,'r+') as fout: fout.seek(0); fout.write('\n'+includes+'\n\n') 
      run = subprocess.Popen('cd '+simDir+'; '+engine+' '+scsNameOut+'; calculateQLSp.py '+outFName+' > '+simFile,shell=True,stdout=subprocess.PIPE)
      data = run.communicate()[0]
      ## read output 
      output = csvUtils.dFrame(simDir+'/'+simFile)
      ## get LQR
      freq,Q,L,R = output['Freq(GHz)'],output['Qdiff'],output['Ldiff(nH)'],output['Rdiff(Ohms)']
      return freq,Q,L,R

     
