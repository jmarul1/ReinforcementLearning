#!/usr/bin/perl

$FILE = $ARGV[0];
$runtype = $ARGV[1];
open $ffp,"<$FILE" or die "cannot open input celllist :$!\n";
open $ofp,">${FILE}_${runtype}_extracted" or die "cannot open the result file: $!\n";

foreach $CELLD(<$ffp>) {
@cell_data = split(/ /,$CELLD);
chomp($cell_data[0]);
$CELL = $cell_data[0];
print "Opening $ENV{WARD}/pds/logs/$CELL.$runtype.iss.log.sum\n";
open $fp,"<$ENV{WARD}/pds/logs/$CELL.$runtype.iss.log.sum" or warn "cannot open iss file - $CELL.$runtype.iss.log.sum: $!\n";

my $found = 0;
print $ofp "$CELL,";
foreach $line(<$fp>) {

	chomp($line);

	if($line =~ /TOTAL/) {
		$found = 0;
	}

	if($found == 1) {
		@fields = split(/\s+/,$line);
		print $ofp "$fields[1],";
	}
	if($line =~ /^#Errors/) {
                $found = 1;
        }

}
print $ofp "\n";

close($fp);

}

close($ffp);
close($ofp);
