#!/usr/bin/env python2.7
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
# Description:
#   Type >> 
##############################################################################

import win32com.client, re, sys,time, os

outlook = win32com.client.Dispatch("Outlook.Application").GetNamespace("MAPI")
inbox = outlook.GetDefaultFolder(6)
messages = inbox.Items
temp = messages.GetFirst()
while temp:
	if re.search(r'IFS Scheduled Report:Template',temp.Subject,flags=re.I): break			
	temp = messages.GetNext()

with open(os.path.join('C:\Users\jmarulan\Documents\Intel Docs\HSD Tickets','test.txt'),'wb') as outF: 
	result = '\n'.join([ii for ii in temp.body.split('\n\r')])
	outF.write(result)	
