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


require 'optparse'; require 'ostruct'; require 'pathname'

## env check ##
begin env = ENV["PROJECT"][-2..-1] 
rescue raise(RuntimeError,'EnvironmentError: Run in an environment 1271/1273/1275')
end

##############################################################################
# Local Classes/Functions
##############################################################################

##############################################################################
# Argument Parsing
##############################################################################
args = OpenStruct.new({'out'=>'.','lmap'=>File.join(ENV['FDK_DISPLAY_DRF_DIR'],ENV['FDK_TECHLIB_NAME']+'.layermap'),'omap'=>File.join(ENV['FDK_DISPLAY_DRF_DIR'],ENV['FDK_TECHLIB_NAME']+'.objectmap'),'view'=>'layout','keeplog'=>false,'color'=>(if env=='75' then true else false end)})
OptionParser.new do |opts|
  opts.banner = "+++ Streams Out using CDesigner\nUsage: #{opts.program_name}.rb posArgs [optsArgs]\n\nPositional Arguments:"
  opts.separator "cellName(s)\tList of cells\nOptional Arguments:"
  opts.on('-l','--lib libName','Library with top views',:require) do |ii| args.lib = ii end
  opts.on('-d','--outdir outPath','Output Directory') do |ii| args.out = ii end
  opts.on('-m','--layermap file','Layer Map File') do |ii| args.lmap = ii;  end
  opts.on('-o','--objectmap file','Object Map File') do |ii| args.omap = ii end
  opts.on('-v','--view vieName','View name of the cell') do |ii| args.view = ii end
  opts.on('-k','--keep','Keep Log') do |ii| args.keeplog = ii end
  opts.on('-c','--coloring','Via Coloring') do |ii| args.color = ii end
  opts.on_tail('-h','--help','Show this message and exit') do puts opts; exit end
end.parse!
if ARGV.any? then args.cell = ARGV else raise(ArgumentError,'At least one cellName is required') end
#########################################################################
# Main
##############################################################################
cdsFile = File.join(ENV['FDK_WORK'],'cds.lib')
if not File.file?(cdsFile) then raise(IOError,'cds.lib is missing or corrupted') end
logFiles = []
for cellName in args.cell 
  gdsF = File.join(args.out,cellName+'.gds')
  cmd = "exportStream -cell #{cellName} -view #{args.view} -logFile #{cellName}.log -lib #{args.lib} -libDefFile #{cdsFile} -gds #{gdsF} -objectMap #{args.omap} -layerMap #{args.lmap}" +
  " -donutNumSides 64 -ellipseNumSides 64 -hierDepth 20 -rectAsBoundary -text cdba -ver 3 -blockageType 0"
  system(cmd)
  logFiles.push(cellName+'.log')
end
if not args.keeplog then IO.popen('sleep 5; rm -f strmOut.cell.automap '+logFiles.join(' ')) end
