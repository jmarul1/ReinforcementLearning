import os, sys, subprocess as sb

## MAIN CLASS for CRISP
class crispClass():
  #create all the files
  def __init__(self,tempDir,gdsObj,qcap,time,nb=''):
    import crispUtils 
    self.dir = tempDir; self.cell = gdsObj[0]; self.time = time
    self.float = os.path.realpath(self.dir+'/'+self.cell+'.floatlist'); 
    with open(self.float,'wb') as fout: fout.write('FLOAT\nFloat\nfloat\nSYN\nSyn\nsyn\ngenerated\n')
    self.cntl = os.path.realpath(self.dir+'/'+self.cell+'.cntl')
    with open(self.cntl,'wb') as fout: fout.write(crispUtils.createcntl(gdsObj,qcap,self.float,time,nb))
    temp = self.dir+'/'+self.cell+'.input.gds'
    if os.path.isfile(temp): sb.call('rm -f '+temp,shell=True)
    os.symlink(gdsObj[1], self.dir+'/'+self.cell+'.input.gds')
    print self
  #run crisp and put the log in the CWD
  def run(self,crispExe): 
    os.putenv('NIKE_TECH_DIR',os.getcwd()+'/'+self.dir); logFile = os.getcwd()+'/'+self.cell+'.crisp.log'
    cmd = 'cd '+self.dir+'; '+crispExe+' '+self.cntl+' >& '+logFile; 
    sys.stderr.write('Running '+os.path.relpath(logFile)+' for ~'+str(self.time)+' minute(s) per port\n')
    self.pid = sb.Popen(cmd,shell=True)
    return self.pid
  #read the results and return 
  def readData(self,netFile='allNets.summary'):
    import os, crispUtils
    ff = self.dir+'/crisp5/'+self.cell+'/'+netFile
    return crispUtils.readFile(ff,self.mfactor) #dictionary
    
   
