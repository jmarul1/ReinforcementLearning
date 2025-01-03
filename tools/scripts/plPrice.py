#!/usr/bin/env python3.7.4
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
# Author:
#   Mauricio Marulanda
##############################################################################
import sys,os, argparse, re, numpy, itertools, plotUtils, csvUtils, pylab as plt, matplotlib.dates, matplotlib.ticker, matplotlib.cm, datetime
## Argument Parsing
argparser = argparse.ArgumentParser(description='Plots CSV')
argparser.add_argument(dest='input', help='CSV')
args = argparser.parse_args()
# Define plotting keywords
xAxis,yAxis = ['DateRng','Price($)']
## Data
dt = csvUtils.dFrame(args.input)
## Prepare Data
dates = datesR = list(map(lambda ff: matplotlib.dates.datestr2num(ff),dt[list(dt.keys())[0]])); yR = dt[list(dt.keys())[1]]
yVals = [numpy.array(dt[ii]) for ii in list(dt.keys())[2:]];
limit = yR.index('-1.0') if '-1.0' in yVals[0] else -1
# trim the real ones
if limit > 0: datesR,yR = datesR[0:limit],yR[0:limit]
# Plot
figs,layout = plt.subplots(); color = lambda ff: ['b','k','c','g','r'][ff%5] 
yR = list(map(float,yR)); 
layout.plot_date(datesR,yR,ms=6,mec=color(4),label='realPrice',fillstyle='none'); 
for ii,prediction in enumerate(yVals): 
 layout.plot_date(dates,prediction.astype(float),ls='solid',lw=1.5,marker=None,label=list(dt.keys())[ii+2],color=color(ii)); 
# setup labels
layout.set_ylabel(yAxis); layout.set_xlabel(xAxis)
formatter = matplotlib.dates.DateFormatter('%m/%y'); 
layout.xaxis.set_major_formatter(formatter); layout.legend(loc='best')
layout.set_ylim(0,max(yR))
beg = matplotlib.dates.datestr2num(numpy.datetime_as_string((numpy.datetime64('today','D') - numpy.timedelta64(180,'D')),'D'))
layout.set_xlim(beg,layout.get_xlim()[1]); 
plt.show()
