#!/bin/csh
##############################################################################
# Intel Top Secret							     #
##############################################################################
# Copyright (C) 2015, Intel Corporation.  All rights reserved.  	     #
#									     #
# This is the property of Intel Corporation and may only be utilized	     #
# pursuant to a written Restricted Use Nondisclosure Agreement  	     #
# with Intel Corporation.  It may not be used, reproduced, or		     #
# disclosed to others except in accordance with the terms and		     #
# conditions of such agreement. 					     #
#									     #
# All products, processes, computer systems, dates, and figures 	     #
# specified are preliminary based on current expectations, and are	     #
# subject to change without notice.					     #
##############################################################################
# Author:
#   Mauricio Marulanda
##############################################################################

set inputs = $#argv
foreach ii (`seq 1 1 $inputs`)
  #create the eps file and erase it
  set name = `echo $argv[$ii] | sed 's/.png$//I'`
  pngtogd2 $argv[$ii] $name.gd2 cs 1
  gd2togif $name.gd2 $name.gif
  convert $name.gif $name.eps
  rm $name.gd2 $name.gif
  set temp = `python -c 'import os,sys; print os.path.splitext(sys.argv[1])[0]' $argv[$ii]`
  epstopdf $temp.eps
  rm $temp.eps
  echo $temp.pdf
end
