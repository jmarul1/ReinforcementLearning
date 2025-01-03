#! /usr/intel/pkgs/ruby/1.8.4/bin/ruby
##############################################################################
## Intel Top Secret                                                         ##
##############################################################################
## Copyright (C) 2009, Intel Corporation.  All rights reserved.             ##
##                                                                          ##
## This is the property of Intel Corporation and may only be utilized       ##
## pursuant to a written Restricted Use Nondisclosure Agreement             ##
## with Intel Corporation.  It may not be used, reproduced, or              ##
## disclosed to others except in accordance with the terms and              ##
## conditions of such agreement.                                            ##
##                                                                          ##
## All products, processes, computer systems, dates, and figures            ##
## specified are preliminary based on current expectations, and are         ##
## subject to change without notice.                                        ##
##############################################################################

require 'erbpp'
require 'getoptlong'


###############################################################################
# USAGE
##############################################################################

# Create the usage message
#
usage = "epp.rb [--process <name>] <in-file> [out-file]

Replaces the following tags embedded in a text file:
<%= expr %> with the return result of the expression given
<% expr %> is evaluated but no return value is printed

-p, --process   Access the global technology for the given process and store in
                a variable called 'gtech'.
-v, --var       Preset variable which may be required in the ERB file.  Multiple
                variables may be set by specifying this option more
                than once.
-d, --debug     Show debug messages.
-h, --help      Show the usage.

"

#
# Get options from command line
#
_opts = GetoptLong.new(['--help', '-h', GetoptLong::NO_ARGUMENT],
                      ['--process', '-p', GetoptLong::OPTIONAL_ARGUMENT],
                      ['--var', '-v', GetoptLong::OPTIONAL_ARGUMENT],
                      ['--debug', '-d', GetoptLong::NO_ARGUMENT])

# Create an ERB object now
$_erb = ERBPP::ErbFile.new

_opts.each do |opt, arg|
  case opt
  when '--help'
    abort usage
  when '--process'
    $_erb.process = arg
  when '--debug'
    $_erb.debug = true
  when '--var'
    vname, vvalue = arg.split(/\=/, 2)
    unless vname and vvalue and not vname.empty?
      abort "Invalid variable format: #{opt} #{arg}\n" +
        "Expecting: #{opt} var=value"
    end
    if m = vvalue.match(/^(true|false|nil)$/)
      vvalue = eval(m[1])
    end
    warn "--var #{vname} = #{vvalue}" if $_erb.debug
    $_erb.vars[vname] = vvalue
  end
end

# Show usage if infile is not given
_infile, _outfile = ARGV
abort usage unless _infile

$_erb.filename = _infile


###############################################################################
# MAIN IMPLEMENTATION
##############################################################################

# Helper functions to get to the ERB object easier
def gtech ; $_erb.gtech ; end
def vars(*args) ; $_erb.vars(*args) ; end
def load_controller(*args) ; $_erb.load_controller(*args) ; end
def do_not_edit(*args) ; $_erb.do_not_edit(*args) ; end
def include_erb(*args) ; $_erb.include_erb(*args) ; end
def process ; gtech.name ; end

# Capture the binding at this point.  Everything above will be accessible
# to ERB which is why variables have the "_" prefix.
$_erb.eval_binding = binding

outf = _outfile ? File.open(_outfile, 'w') : $stdout
outf.puts($_erb.readlines)
outf.close unless outf == $stdout
