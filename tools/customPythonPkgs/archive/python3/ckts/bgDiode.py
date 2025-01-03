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

class bgdiode():
  def __init__(self,model,sim,temperatures):
    self.sim = sim
    self.temps = temperatures
    self.model = model
  def simulate(self,includes,simDir,tipo,prefix='',monteCarlo=False):
    import cktUtils, subprocess, tempfile
    storage = tempfile.TemporaryFile()
    simFile = prefix+'_bgd_'+tipo+'.'+self.sim
    if self.sim == 'hsp': 
      with open(simDir+'/'+simFile,'wb') as fout: fout.write(cktUtils.createHspStr(includes,self.model,self.temps,tipo,monteCarlo))
      run = subprocess.Popen('cd '+simDir+'; hspice '+simFile,shell=True,stdout=storage,stderr=subprocess.PIPE)
      data = run.communicate()[0]
      storage.seek(0); 
      output = cktUtils.getParam(storage,'vemitbase|gainbeta',monteCarlo); storage.close()
    return output
    
