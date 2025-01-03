#!/usr/intel/bin/perl

use strict; 
use warnings;

use Getopt::Long;
use File::Basename;
use File::Find qw(find);

our $nFileCount = 0;
our @aJMPColumnTracker;
our $nDataPrintIndex = 0;

my $sPrintString;
my @sFilesForParsing;
	
push @sFilesForParsing, list_dir(@ARGV);

my $sTotalFiles = scalar(@sFilesForParsing);
my $nIndex;

for($nIndex = 0; $nIndex <$sTotalFiles; $nIndex++)
{
	&parse_file($sFilesForParsing[$nIndex]);
}


sub parse_file
{
	my $FullFilePath = $_[0];
	
	my $sFileName = basename($FullFilePath);
	my $sFileNameOutput = $sFileName;
	my $line;
	my $sDevice;
	
	$sFileNameOutput =~ s/.citi/_DAISY.citi/;
	$sDevice = $sFileName;
	$sDevice =~ s/.citi//;
	
	open(DB, $FullFilePath) || die "Can't open $FullFilePath $!\n";
	open(OUTPUT,">$sFileNameOutput") or die ("Cannot open file : $!");
	
	print $FullFilePath."\n";
	
	print OUTPUT "\# $sFileName WXXX XxYy\n";
	print OUTPUT "\# $sDevice SH OP\n";
	while(<DB>)
	{
		$line = $_;
		chomp($line);
		if($line =~ /\S+[E][+]\S+/)
		{
			$line =~ /(\S+)[E][+](\S+)/;
			$line = $1*10**$2;
		}
		if ($line =~ /VAR Vd_array/)
		{
			$line =~ s/Vd_array/VDS/;
		}
		if ($line =~ /VAR Vg_array/)
		{
			$line =~ s/Vg_array/VGS/;
		}
		if($line eq "DATA Id_array MAG" )
		{
			$line = "DATA IDS MAG";
		}
		if($line eq "DATA Ig_array MAG" )
		{
			$line = "DATA IGS MAG";
		}		
		if($line eq "DATA s11meas RI" )
		{
			$line = "DATA S[1,1] RI";
		}
		if($line eq "DATA s12meas RI" )
		{
			$line = "DATA S[1,2] RI";
		}
		if($line eq "DATA s21meas RI" )
		{
			$line = "DATA S[2,1] RI";
		}
		if($line eq "DATA s22meas RI" )
		{
			$line = "DATA S[2,2] RI";
		}		
		print OUTPUT $line."\n";
		
	}
	close(DB);
	close(OUTPUT);

}

sub list_dir {
        my @dirs = @_;
        my @files;
        find({ wanted => sub { push @files, glob "\"$_/*.citi\"" } , no_chdir => 1 }, @dirs);
        return @files;
}

sub getMethods {
	my $typeinfo = $_[0];
	my $attr = $typeinfo->_GetTypeAttr();
	
	open(DEBUG, ">debug.txt") || die "Can't open debug.txt $!\n";
	
	for (my $i = 0; $i< $attr->{cFuncs}; $i++) {
		my $desc = $typeinfo->_GetFuncDesc($i);
		# the call conversion of method was detailed in %$desc
		my $funcname = @{$typeinfo->_GetNames($desc->{memid}, 1)}[0];
		#say $funcname;
		print DEBUG "$funcname\n";
	}
	
	close(DEBUG);
	return;
}

sub getfullpath {

    my $dir  = dirname($_[0]);
    my $file = basename($_[0]);
    chomp(my $pwd = `cd`);     # Remember where we started out from so we can return
    chdir $dir;
    chomp(my $filedir = `cd`); # Get the full path (DOS method)
    chdir $pwd;                # Go back to the starting directory
    my $FileName = "$filedir\\$file";
    return($FileName);
} # end of sub getfullpath
