##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2014, Intel Corporation.  All rights reserved.               #
#                                                                            #
# This is the property of Intel Corporation and may only be utilized         #
# pursuant to a written Restricted Use Nondisclosure Agreement               #
# with Intel Corporation.  It may not be used, reproduced, or                #
# disclosed to others except in accordance with the terms and                #
# conditions of such agreement.                                              #
#                                                                            #
# All products, processes, computer systems, dates, and figures              #
# specified are preliminary based on current expectations, and are           #
# subject to change without notice.                                          #
##############################################################################
#
# Author:
#   Mauricio Marulanda
#
# Description:
#   General file
#
##############################################################################

class varactor():
## initialize
  def __init__(self,model,sim,temperature):
    self.sim = sim
    self.temps = temperature
    self.model = model
    self.vac = '1'
## simulate    
  def simulate(self,includes,freq,skew,fV,sV,mV):
    import utils, subprocess, tempfile, varUtils, os
    self.freq = freq
    engine = 'lynxSpice' if self.sim == 'hsp' else 'spectre'
    simDir = tempfile.mkdtemp(dir='/tmp');        
    simFile = 'var_'+skew+'.'+self.sim
    if self.sim == 'hsp': 
      with open(simDir+'/'+simFile,'wb') as fout: fout.write(varUtils.createHspStr(includes,self.model,self.temps,self.vac,freq,[fV,mV,sV]))
      run = subprocess.Popen('cd '+simDir+'; '+engine+' '+simFile,shell=True,stdout=subprocess.PIPE)
      data = run.communicate()[0]
      results = 'var_'+skew+'_1.split'
      if not os.path.isfile(simDir+'/'+results): raise IOError('Simulation did not work: '+simDir)
      subprocess.call('cd '+simDir+'; /nfs/pdx/home/jmarulan/work_area/utils/scripts/bin2ascii.pl '+results,shell=True,stdout=subprocess.PIPE)
      ## read the output
      volt,Ire,Iim = varUtils.readOutput(simDir+'/'+os.path.splitext(results)[0]+'.dat')
      ## get CQR
      Q,C,R = varUtils.getQCR(float(self.vac),Ire,Iim,self.freq)
      return volt,Q,C,R
