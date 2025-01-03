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
#   Useful functions for working with Design Mirror
#
##############################################################################

def checkout(inFile):
  import subprocess, sys, os
  if os.path.isfile(inFile): print >> sys.stderr,'Path file does not exist: '+iiFile; return False
  test = subprocess.call('dssc co -noc -l '+inFile,shell=True)
  if test == 0: return True
  else: return False 

def overlay(inFile,version):
  import subprocess, sys, os
  if os.path.isfile(inFile): print >> sys.stderr,'Path file does not exist: '+iiFile; return False
  test = subprocess.call('dssc co -overlay '+str(version)+' '+inFile,shell=True)
  if test == 0: return True
  else: return False 
  
def cancel(inFile):
  import subprocess, sys, os
  if os.path.isfile(inFile): print >> sys.stderr,'Path file does not exist: '+iiFile; return False
  test = subprocess.call('dssc cancel -force '+inFile,shell=True)
  if test == 0: return True
  else: return False   

def checkin(inFile,comment):
  import subprocess, sys, os  
  if os.path.isfile(inFile): print >> sys.stderr,'Path file does not exist: '+iiFile; return False
  test = subprocess.call('dssc ci -comm "'+comment+'" '+inFile,shell=True)
  if test == 0: return True
  else: return False 
