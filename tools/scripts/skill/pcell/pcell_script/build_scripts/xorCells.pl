#!/usr/intel/bin/perl 
#!/usr/intel/pkgs/perl/5.6.1/bin/perl -d:DProf
#!/usr/intel/pkgs/perl/5.6.1/bin/perl -d:ptkdb
# for profiling:  /usr/intel/pkgs/perl/5.6.1/bin/dprofpp tmon.out

use strict;
use oa::design;


#use warnings;
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# Filename: xorCells.pl                        Project: FDK
#
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# (C) Copyright Intel Corporation, 2011
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
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# RCS Information:
#
#   $Author: achoudh1 $
#   $Source: /nfs/ch/disks/ch_ciaf_disk049/sync_vault/server_vault/Projects/fdk73/oalibs/common/custom/build_scripts/xorCells.pl.rca $
#     $Date: Thu Sep 20 16:55:12 2012 $
# $Revision: 1.1 $
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#######################################################
#                  GLOBALS
#######################################################
my $VERSION = '$Revision: 1.1 $';
$VERSION =~ s/\$//g;
my $scriptName = $0;
$scriptName=~ s/.*\///g;
local $main::DEBUG=""; 
#######################################################
#                  Help Message       
#######################################################

my $help_message = <<HERE
	SYNTAX: $scriptName [-h] -l1 <library #1> -l2 <library #2> -c <cell>  [-libdef <lib.defs>]\n

       -h         Help message. Also displayed, if no argument exist
		          on command line.
       -libdef <lib.defs> : reads alternate lib.defs file.
                  default: ./cds.lib
       -l1 <library>: specified the first library to find
       -l2 <library>: specified the second library to find
       -c <cell>: specified the cell name

    Description:
        Run xor on two cells of the same name (differnt libraries)
        output will be in ./icv_XOR/<cell>


    Examples:
        $scriptName -l1 intel73tech -l2 intel73tech_pycell -c n70ring

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
# Subroutine: openLibDef
# Description: Reads default lib.defs unless an override lib.def is specified
# By default it will look at: ./lib.defs and then ~/lib.defs
#######################################################
sub openLibDef{
my ($libDefOverride)=@_;

    if(!defined $libDefOverride){
        eval {
            &oa::oaLibDefList::openLibs();
            1;
        } or do {
            #print STDERR $@;
        }
    }else{
        eval{
            &oa::oaLibDefList::openLibs($libDefOverride);
            1;
        } or do {
            #print STDERR $@;
        }
    }
}

#######################################################
# Subroutine: findLibraryPath
# Description: 
#######################################################
sub findLibraryPath{
    my ($hashPtr)=@_;
    my ($list,$memberIter,$member,$nameScalar,$name,$path,$ns)=(undef)x7;
    my ($allList,$listIter)=(undef)x2;
    $ns = new oa::oaNativeNS;
    $nameScalar = new oa::oaScalarName();

    $listIter =new oa::oaIter::oaLibDefList(&oa::oaLibDefList::getLibDefLists()); 
    while($list = $listIter->getNext()){

        $memberIter =new oa::oaIter::oaLibDefListMem($list->getMembers()); 
        while($member = $memberIter->getNext()){
            if($member->getType == $oa::oacLibDefType){
                $member->getLibName($nameScalar); 
                $nameScalar->get($ns,$name);
                $member->getLibPath($path);
                $$hashPtr{$name}=$path;
            }
        }
    }
}



#######################################################
#######################################################
#                       MAIN
#######################################################
#######################################################

my $outfile =undef;
my ($techLibName,$ns,$libDefOverride,$command)=(undef)x4;
my ($lib1,$lib2,$cell,$layerMapFile,$objectMapFile)=(undef)x5;
my %libHash=();
my $techLibName = "intel73tech";
my ($rundir)=(undef)x1;

$rundir="./icv_XOR";

&dPrint(undef,"In DEBUG Mode:");  

print STDERR "IN $0: @ARGV\n";
#$ARGV[0]= "-help"  if $#ARGV <0; # displays help message id no args are defined
while ($ARGV[0]){
    if ($ARGV[0] =~ /^-h(.*)/){  #
        print STDERR "$help_message";
        exit 1;
    }elsif($ARGV[0] =~ /^-ver(.*)/){ #
		print "$scriptName: $VERSION\n";
		exit;
    }elsif($ARGV[0] =~ /^-tech/){ #
        shift;
        $techLibName= $ARGV[0];
    }elsif($ARGV[0] =~ /^-l1/){ #
        shift;
        $lib1= $ARGV[0];
    }elsif($ARGV[0] =~ /^-l2/){ #
        shift;
        $lib2= $ARGV[0];
    }elsif($ARGV[0] =~ /^-c/){ #
        shift;
        $cell= $ARGV[0];
    }elsif($ARGV[0] =~ /^-libdef(.*)/){ #
        shift;
        $libDefOverride= $ARGV[0];
    }
    shift;
}

if (defined $outfile){
	open(OUTFILE, ">$outfile")|| die "Can't open:  $outfile";
	select(OUTFILE);
}
    # It is necessary to initialize the design before opening the lib defs
    oa::oaDesignInit();
    $ns = new oa::oaNativeNS;
    &openLibDef($libDefOverride);
    &findLibraryPath(\%libHash);
    $layerMapFile=$libHash{$techLibName}."/".$techLibName.".layermap";
    $objectMapFile=$libHash{$techLibName}."/".$techLibName.".objectmap";

    if(!-e "$rundir/$cell"){
        mkdir("$rundir/$cell");
    }
    if(exists $libHash{$techLibName}){

#icv_lvl ${cell}_${lib1}.gds ${cell}_${lib2}.gds -lf "$ENV{INTEL_RUNSETS}/PXL/p12723_icv_lvl_assign.rs"  -c $cell
    $command = <<HERE
strmout -library "$lib1" -topCell "$cell" -view "layout" -techLib "intel73tech" -runDir "$rundir/$cell" -strmFile "${cell}_${lib1}.gds" -logFile "strmout.log" -layerMap "$layerMapFile" -objectMap "$objectMapFile"

strmout -library "$lib2" -topCell "$cell" -view "layout" -techLib "intel73tech" -runDir "$rundir/$cell" -strmFile "${cell}_${lib2}.gds" -logFile "strmout.log" -layerMap "$layerMapFile" -objectMap "$objectMapFile"
pushd "$rundir/$cell"
icv_lvl ${cell}_${lib1}.gds ${cell}_${lib2}.gds  -c $cell

HERE
;
    system($command);
        
    }

close OUTFILE if defined ($outfile);
