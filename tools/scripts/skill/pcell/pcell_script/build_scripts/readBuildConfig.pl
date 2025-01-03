#!/usr/intel/bin/perl 
#!/usr/intel/pkgs/perl/5.6.1/bin/perl -d:DProf
#!/usr/intel/pkgs/perl/5.6.1/bin/perl -d:ptkdb
# for profiling:  /usr/intel/pkgs/perl/5.6.1/bin/dprofpp tmon.out

use YAML;
use strict;
use Cwd;
#use warnings;
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# Filename: bssc                        Project: Foundry
#
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# (C) Copyright Intel Corporation, 2010
# Licensed material -- Program property of Intel Corporation
# All Rights Reserved
#
# This program is the property of Intel Corporation and is furnished
# pursuant to a written license agreement. It may not be used, reproduced,
# or disclosed to others except in accordance with the terms and conditions
# of that agreement.
#
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# Original Author: Mike Farabee
#
# Known bugs:  None
#
# Enhancements: Nothing needed
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# RCS Information:
#
#   $Author: achoudh1 $
#   $Source: /nfs/ch/disks/ch_ciaf_disk049/sync_vault/server_vault/Projects/fdk73/oalibs/common/custom/build_scripts/readBuildConfig.pl.rca $
#     $Date: Thu Sep 20 16:55:12 2012 $
# $Revision: 1.1 $
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#######################################################
#                  GLOBALS
#######################################################
my $VERSION = '$Revision: 1.1 $';
$VERSION =~ s/\$//g;
my $scriptName = $0;
$scriptName=~ s/.*\///g;
local $main::DEBUG=""; 
my $defaultFile = $scriptName;
$defaultFile =~ s/\..*$//;
$defaultFile .= ".yaml";
my $TEST=0;



#######################################################
#                  Help Message       
#######################################################

my $help_message = <<HERE
	SYNTAX: $scriptName 

    Description: 

HERE
;
$help_message =~ s/\t/    /g; # Replace tabs with 4 spaces

# Prints hash, array ,hash of hash, or any combination. Optional 2nd arg is the name of the hash
# usage example: printAny(\%data,"data");
#                printAny(\@data,"data");
sub printAny {
	my ($data,$dataname)=@_;
	my ($key,$index)=(undef) x 2;
	if(ref $data eq "ARRAY"){
		if($dataname eq "" && ref $data eq "ARRAY"){
			$dataname="ARRAY";
		}
		for($index=0;$index<=$#{@$data};++$index){
			if(ref $$data[$index] eq "HASH"){
				&printAny(\%{$$data[$index]},"$dataname\[$index\]");
			}elsif(ref $$data[$index] eq "ARRAY"){
				&printAny(\@{$$data[$index]},"$dataname\[$index\]");
			}else{
	 			print STDERR "$dataname\[$index\]=$$data[$index]\n";
			}
		}
	}
	if(ref $data eq "HASH"){
		if($dataname eq "" && ref $data eq "HASH"){
			$dataname="HASH";
		}
		foreach $key (keys %$data){
			if(ref $$data{$key} eq "HASH"){
				&printAny(\%{$$data{$key}},"$dataname\{$key\}");
			}elsif(ref $$data{$key} eq "ARRAY"){
				&printAny(\@{$$data{$key}},"$dataname\{$key\}");
			}else{
			 print STDERR "$dataname\{$key\}=$$data{$key}\n";
			}
   	 	}
    }
}


=pod
The following is for Debug
=cut


# can salt the dPrint statements throughout the code and turn them
# on and off with changing the values in the $main::DEBUG Variable
# The first argument can be a key word to specify when the print happens
# If this key is undef , it will always print when debug is on
# usage: dPrint("key","Data to %s","print");
my $deBugOn = sub  {
	my ($level,$string,@args) =@_;
	my($pkg,$file,$line)=caller();
	if(!defined $level || $main::DEBUG eq $level){
		printf(STDERR "-DEBUG- line $line: $string\n",@args);
	}
};
my $deBugOff = sub {};
if(!defined $main::DEBUG || $main::DEBUG eq "") {*dPrint=$deBugOff;} else {*dPrint= $deBugOn;}



sub numerically {$a <=> $b;}
sub reverse_numerically {$b <=> $a;}

#######################################################
#       Subroutine
#######################################################
sub  getCells {
    my ($configPtr,$hashPtr,$name)=@_;
    my @results=();
    my ($key,$cell)=(undef)x2;
    if(ref $configPtr eq "HASH"){
        foreach $key ( keys %$configPtr){
            &getCells(\%{$$configPtr{$key}},$hashPtr, $name."/".$key);
        }
    }else{
        foreach $cell (@$configPtr){
            push(@{$$hashPtr{$name}},$cell);
        }
    }
}



#######################################################
#######################################################
#                       MAIN
#######################################################
#######################################################

my @infiles=();
my @list=();
my ($outfile,$yamlFile,$process,$field,$subfield,$item,$action,$library)=(undef)x8;
my ($package,$cell,$root,$base)=(undef)x4;
my $buildConfigPtr=undef;
my %top=undef;
my %cellList=();
my @actions=();
my %flag=();

&dPrint(undef,"In DEBUG Mode:");  

print STDERR "IN $0: @ARGV\n";
$ARGV[0]= "-help"  if $#ARGV <0; # displays help message id no args are defined
while ($ARGV[0]){
    if ($ARGV[0] =~ /^-h(.*)/){  #
        print STDERR "$help_message";
        exit 0;
    }elsif($ARGV[0] =~ /^-v(.*)/){ #
		print "$scriptName: $VERSION\n";
		exit;
    }elsif($ARGV[0] =~ /^-p(.*)/){ #
        shift;
        $process= $ARGV[0];
        if($process !~ /^p/){
            $process= "p".$process;
        }
    }elsif($ARGV[0] =~ /^-l(.*)/){ #
        shift;
        $library= $ARGV[0];
    }elsif($ARGV[0] =~ /^-f(.*)/){ #
        shift;
        $field= $ARGV[0];
    }elsif($ARGV[0] =~ /^-s(.*)/){ #
        shift;
        $subfield= $ARGV[0];
    }elsif($ARGV[0] =~ /^-a(.*)/){ #
        shift;
        push(@actions, $ARGV[0]);
    }elsif($ARGV[0] =~ /^-o(.*)/){ #
        shift;
        $outfile= $ARGV[0];
    }else{
        $yamlFile = $ARGV[0];
    }
    shift;
}

if (defined $outfile){
	open(OUTFILE, ">$outfile")|| die "Can't open:  $outfile";
	select(OUTFILE);
}


$buildConfigPtr = YAML::LoadFile($yamlFile);
foreach $action ( @actions){
    if(exists $$buildConfigPtr{process}{$process}{build_packages}{$action}){
        foreach $package (@{$$buildConfigPtr{process}{$process}{build_packages}{$action}}){
            &getCells(\%{$$buildConfigPtr{process}{$process}{package_definitions}{$package}},\%cellList,$package);
        }
                foreach $field ( keys %cellList){
                    $root=$field;
                    $root =~ s/.+\///g;
                    if($action eq "cdf"){
                        printf("%s/loadCdf.csh -p %s -l %s cdf.skill/%s/fdk73Cdf_%s.cdf ","../build_scripts",$process,$library,$field,$root );
                    }elsif( $action eq "propbag"){
                        printf("%s/loadPropbag.csh -p %s -l %s  -y %s  propbag.dir/%s/%s.csv ","../build_scripts",$process,$library, "$ENV{PWD}/build/$process/work/propbags/$root",$field,$root);
                    }elsif($action eq "pycell" ){
                        $base=$field;
                        $base =~ s/\/.+//g;
                        if(!exists $flag{$base}){
                            printf("%s/pycell_compile.csh -p %s -l %s %s\n","../build_scripts",$process,$library,$base);
                            $flag{$base}=1;
                        }
                    }else{
                        printf("load_%s -p %s -l %s ",$action,$process,$library,$package);
                    }
                    if( $action ne "pycell"){
                        foreach $cell ( @{$cellList{$field}}){
                            printf(" -c %s",$cell);
                        }
                        printf("\n");
                    }
                }
    }

}


#&printAny($buildConfigPtr);

close OUTFILE if defined ($outfile);
