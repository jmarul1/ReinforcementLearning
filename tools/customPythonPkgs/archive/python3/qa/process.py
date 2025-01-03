##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2013, Intel Corporation.  All rights reserved.               #
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
#   Deal with QA
#
##############################################################################

class createrun():
  '''Creates the class object for QA'''
  def __init__(self,rundir,libName,cellName,lnf=False):
    import os
    self.rundir = os.path.realpath(rundir)
    self.lib = libName; self.cell = cellName; self.gds = self.cdl = False; self.lnf=lnf;

  def prepTC(self,flows,cdl='sn'):
    import subprocess, os
    ## prepare the test case gds/cdl|sn|sp pair
    techlib = ' -techlib intel76tech' if os.getenv('DR_PROCESSNAME') == '1276' else ''
    args = ' -lib '+self.lib+' -outdir '+self.rundir+' -- '+self.cell; self.flows = flows; log = ''
    if not self.gds:  ## gds generation
      if self.lnf:
        self.gds = self.rundir+'/'+self.cell+'.lnf'
        test = subprocess.Popen('cp -f '+self.lnf+' '+self.gds,shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
      else:
        self.gds = self.rundir+'/'+self.cell+'.gds';
        test = subprocess.Popen('strmOut.py'+techlib+args,shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE);
      log += '\n'.join([ff.decode() for ff in test.communicate()])
    if 'trclvs' in flows or 'lvs' in flows:  ## cdl generation
      if cdl == 'sp': ## ad rf
        self.cdl = self.rundir+'/'+self.cell+'.sp';
        test = subprocess.Popen('strmCdl.py'+args,shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE);
      elif cdl == 'sn':
        self.cdl = self.rundir+'/'+self.cell+'.sn';
        test = subprocess.Popen('strmNike.py'+args,shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE);
      elif cdl == 'cdl':
        self.cdl = self.rundir+'/'+self.cell+'.cdl';
        test = subprocess.Popen('strmCmdr.py'+args,shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE);
      log += '\n'.join([ff.decode() for ff in test.communicate()]) # do wait for the jobs to finish
    return log

  def runQa(self,timeout,tool='icv',interactive=False): #interactive=True blocks until finish, suitable for multiprocessing
    import subprocess, re
    if re.search(r'^cal',tool):
      args = '-cleanup -flow '+(' '.join(self.flows)) + ((' -cdl '+self.cdl) if self.cdl else '') + ' -batch'
      cmd = f'cd {self.rundir}; runCalibre.py {args} -- {self.gds}'
    else:
      args = '-cleanup -timeout '+timeout+' -flow '+(' '.join(self.flows))+(' -sn '+self.cdl if 'trclvs' in self.flows else '')+' -batch'
      cmd = f'runset.py {args} -- {self.gds}'
    if interactive: test = subprocess.run(cmd,shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    else:           test = subprocess.Popen(cmd,shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)    
    return test #dont wait just return the subprocess handler
