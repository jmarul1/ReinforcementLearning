#!/usr/intel/pkgs/ruby/1.8.7-p72/bin/ruby

abort "Usage #{$0} <cdslog>" unless ARGV.length == 1
file=ARGV[0]
abort "cdslog does not exist: #{file}" unless File.exists?(file)


bad_patterns = [
                /Failed to open cellview /,
		/Cannot delete a form that is mapped or from within the form/,
                /Could not get gtech device param/,
                /[Ee]rror/,
                /ERROR/, 
                /\\o.*will not load nonexistent (lib)?init/
               ]

bad_flag = nil
File.open(file){|fh|
  fh.each_with_index{|line,lineno|
    bad_patterns.each{|pat|

    if line.match(pat)
      next if line.match(/Cannot delete a form that is mapped or from within the form/)
      next if line.match(/Qt Warning: Qt: Session management error: Could not open network socket/)
      warn "" unless bad_flag
      warn "ERROR FOUND IN CADENCE LOG (#{file}):\n" unless bad_flag
      warn "Line #{lineno}: #{line.chomp}\n"
      bad_flag = 1
    end
    }
  }
}
abort "errors found! Aborting." if bad_flag
exit 0
