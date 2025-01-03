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

latex $1
echo $1 | sed -e 's/\.tex$/\.dvi/1' | xargs dvipdf
echo $1 | sed -e 's/\.tex$/\.pdf/1' | awk '{print $1 " created"}'

## remove files
echo $1 | sed -e 's/\.tex$/\.dvi/1' | xargs rm
echo $1 | sed -e 's/\.tex$/\.aux/1' | xargs rm
echo $1 | sed -e 's/\.tex$/\.log/1' | xargs rm
