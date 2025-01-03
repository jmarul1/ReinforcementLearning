#!/usr/bin/env ruby
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

require 'optparse'; require 'ostruct'

##############################################################################
# Argument Parsing
##############################################################################
args = OpenStruct.new({'out'=>'combine.pdf'})
OptionParser.new do |opts|
  opts.banner = "+++ Comines a list of pdfs\nUsage: #{opts.program_name}.rb posArgs [optsArgs]\n\nPositional Arguments:"
  opts.separator "PDFs\tList of pdf files\nOptional Arguments:"
  opts.on('-o','--out combine.pdf','resulting pdf') do |ii| args.out = ii end
  opts.on_tail('-h','--help','Show this message and exit') do puts opts; exit end
end.parse!
if ARGV.any? then args.list = ARGV else raise(ArgumentError,'At least one cellName is required') end
## MAIN
cmd = 'gs -sDEVICE=pdfwrite -dNOPAUSE -dQUIET -dBATCH -sOutputFile='+args.out+' '+args.list.join(' ')
test = IO.popen(cmd)
test.read
p 'Combined input pdfs into '+args.out
