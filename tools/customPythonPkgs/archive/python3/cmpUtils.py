##############################################################################
# Intel Top Secret                                                           #
##############################################################################
# Copyright (C) 2015, Intel Corporation.  All rights reserved.               #
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
#   Sanghyun Seo
#
# Description:
#   Useful functions for file comparison
#
##############################################################################

def modelCmp(path1,path2,comment=[]):
	"""Compare two model files and returns true if matches. Ignores blank lines and comment lines. returns match or mismatch"""
	import os, tempfile, filecmp, re

	fileShelf = open(str(path1[0]),'r')
	fileDev = open(str(path2[0]),'r')
	
# open tempfiles for comparison. 
	tempShelf = tempfile.NamedTemporaryFile(delete=False)
	tempDev = tempfile.NamedTemporaryFile(delete=False)

# write tempfile from path1/2 ignoring lines starting with comment and blank lines
	for line in fileDev:
		line = line.rstrip() + '\n'
		if len(line) > 1 or line != '\n':
			if any(comment):
				checkComment=[]
				for ii in range(len(comment)):
					checkComment.append(re.search('^\s*'+comment[ii],line))
				if not any(checkComment):
					tempDev.write(line)
			else:
				tempDev.write(line)

	for line in fileShelf:
		line = line.rstrip() + '\n'
		if len(line) > 1 or line != '\n':
			if any(comment):
				checkCommentS=[]
				for jj in range(len(comment)):
					checkCommentS.append(re.search('^\s*'+comment[jj],line))
				if not any(checkCommentS):
					tempShelf.write(line)
			else:
				tempShelf.write(line)

	
	tempDev.close()
	tempShelf.close()

# compare the two tempfiles and return match or mismatch
	if filecmp.cmp(str(tempDev.name), str(tempShelf.name)):
		result = 'match'
	else:
		result = 'mismatch'
	
	return result;

