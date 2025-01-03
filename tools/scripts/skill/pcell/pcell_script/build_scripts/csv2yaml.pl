#!/usr/intel/bin/perl 
#!/usr/intel/pkgs/perl/5.6.1/bin/perl -d:DProf
#!/usr/intel/pkgs/perl/5.6.1/bin/perl -d:ptkdb
# for profiling:  /usr/intel/pkgs/perl/5.6.1/bin/dprofpp tmon.out


use strict;
#use warnings;
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# Filename: csv2yaml.pl                        Project: Foundry
#
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# (C) Copyright Intel Corporation, 2012
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
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# RCS Information:
#
#   $Author: achoudh1 $
#   $Source: /nfs/ch/disks/ch_ciaf_disk049/sync_vault/server_vault/Projects/fdk73/oalibs/common/custom/build_scripts/csv2yaml.pl.rca $
#     $Date: Wed Oct 17 20:01:27 2012 $
# $Revision: 1.3 $
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#######################################################
#                  GLOBALS
#######################################################
my $VERSION = '$Revision: 1.3 $';
$VERSION =~ s/\$//g;
my $scriptName = $0;
$scriptName=~ s/.*\///g;
my $EXITCODE = 0;
#######################################################
#                  Help Message       
#######################################################

my $help_message = <<HERE
    SYNTAX: $scriptName [-h][-v] -process <#> [-yamlpath <path>] [-cell <cell> ...] <csv file>\n

       -p , -process <#>         Process to build. This can be entered as 4 or p4. This will match the rows in the csv table
       -y , -yamlpath <path>     The path for the resulting yaml files.
                                  default: Current working directory
       -c , -cell  <cell> ...    Allows only generating yaml files for specific cells specified.
       -h , -help                Help message. Also displayed, if no argument exist on command line.
	   -v , -version             Prints version # of program.

    Example:

        Create properybag yaml files for all cells in CSV file for the dot4 process
        $scriptName  -p 4 -y ./build/p4/work/probbags/mos  mos.csv

        Only create yaml files for 3 cells
        $scriptName  -p 4 -y ./build/p4/work/probbags/mos  -c n -c pll -c nll  mos.csv

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

sub numerically {$a <=> $b;}
sub reverse_numerically {$b <=> $a;}

#######################################################
#       readCSV
# Description: CVS reader that stores data into an array
# Also builds a second array for any process ID related rows
#######################################################
sub readCSV{
    my ($infile,$myArray,$processMatrix)=@_;
    my ($lineNo,$char,$string,$doubleQuoteCounter,$singleQuoteCounter,$pmLineNo)=(undef)x6;
    my @data=();
    my @result=();
    if (! -e $infile){
        print STDERR "ERROR: $infile can't open for read!\n";
        exit 1;
    }

    my $fh= open(FILE, $infile)|| die "Can't open:  $infile";
    $lineNo=0;
    $pmLineNo=0;

    while(<FILE>) {
        chomp;
        s/^M//;
        s/\\/\\\\/g; # double blackslash all backslashes
        @data=split('');
        $doubleQuoteCounter=0;
        $singleQuoteCounter=0;
        $string="";
        @result=();
        foreach $char (@data){
            if($char eq '"'){
                $string= $string . $char;
                if($doubleQuoteCounter==0){
                    ++$doubleQuoteCounter;
                }else{
                    --$doubleQuoteCounter;
                }
            }elsif($char eq '\''){
                $string= $string . $char;
                if($singleQuoteCounter==0){
                    ++$singleQuoteCounter;
                }else{
                    --$singleQuoteCounter;
                }
            }elsif($char eq ',' && $doubleQuoteCounter ==0 && $singleQuoteCounter==0){
                $string =~ s/\"\"\"/\\\"/g;# convert 3 quotes to backslash quote
                if($string !~ /^\"\"$/){ # Special case for empty string
                    $string =~ s/\"\"/\\\"/g;# convert 2 quotes to backslash quote
                }
                push(@result,$string);
                $string="";
            }else{
                $string= $string . $char;
            }
        }
        $string =~ s/\"\"\"/\\\"/g; # convert 3 quotes to backslash quote
        if($string !~ /^\"\"$/){ # Special case for empty string
            $string =~ s/\"\"/\\\"/g; # convert 2 quotes to backslash quote
        }
        push(@result,$string);
        if($result[0] =~ /^p[0-9]+$/ ){
            push(@{$$processMatrix{$result[0]}},@result);
            ++$pmLineNo;
        }else{
            push(@{$$myArray[$lineNo]},@result);
            ++$lineNo;
        }
    }
    close FILE;
}

#######################################################
#       reorgHash
# Description: Initially when the CSV was loaded, it was thrown into a two dimensional array
#   This routine reorders the data into a hash for ease of creating the yaml.
#   It also breaks the hierarchical (delimited) name into separate hash elements
#######################################################
sub reorgHash {
    my ($top,$process,$processMartix,$hashOut,$delimiter)=@_;
    my ($key,$index,$cellIndex,$seg,$tmp,$validRowflag)=(undef)x6;
    my %cellList=();
    # create cell list from first row
    $index=0;
	foreach $key (@{$$top[0]}){
        if($key ne "" && $key !~ /^[\s]*cell[\s]*$/i && $key !~ /^-.*-$/){
            $cellList{$index}=$key;
        }
        if($key eq "_propbag_"){
            $validRowflag=$index;
        }
        ++$index;
    }

    $index=1;
    while($index < scalar(@$top)){
        # Only work on valid lines from the cell list
	    foreach $cellIndex (keys %cellList){

            # Only process row is it is a valid property bag field
            if($$top[$index][$validRowflag] !~ /^\s*$/ ){
                # break up key into separate hash elements
                if($$top[$index][$cellIndex] ne "" && $$processMartix{$process}[$cellIndex] ne "" ){
                    $tmp=\%{$$hashOut{$cellList{$cellIndex}}};
                    foreach $seg (split($delimiter,$$top[$index][0])){
                        $tmp=\%{$$tmp{$seg}};
                    }
                    # Now that the multi-dimensioned hash is build, add the value
                    if(exists $$tmp{value}){
                        printf(STDERR "-E- Error: duplicate cell data (%s) %s\n",$cellList{$cellIndex},$$top[$index][0]);
                        $EXITCODE = 1;
                    }
                    $$tmp{value}=$$top[$index][$cellIndex];
                }
            }
        }
        ++$index
    }
}

#######################################################
#       printYamlItems
# Description: Recursive routine that walks through the hash
#  and prints the yaml lines
#######################################################
sub printYamlItems{
    my ($hash,$indent)=@_;
    my ($key)=(undef)x1;
	foreach $key (sort keys %$hash){
        if(exists $$hash{$key}{"value"}){
            # quote the value if it is a string, do not quote, if already quoted
            if($$hash{$key}{"value"} =~ /^\d+$/ || $$hash{$key}{"value"} =~ /^\"/ ){
                printf("%s%s: %s\n",$indent,$key,$$hash{$key}{"value"});
            }else{
                if(lc($$hash{$key}{"value"}) eq "t" || lc($$hash{$key}{"value"}) eq "true"){
                    printf("%s%s: %s\n",$indent,$key,$$hash{$key}{"value"});
                }elsif(lc($$hash{$key}{"value"}) eq "nil" || lc($$hash{$key}{"value"}) eq "false"){
                    printf("%s%s: %s\n",$indent,$key,$$hash{$key}{"value"});
                }else{
                    printf("%s%s: \"%s\"\n",$indent,$key,$$hash{$key}{"value"});
                }
            }
        }else{
            printf("%s%s:\n",$indent,$key);
            &printYamlItems(\%{$$hash{$key}},$indent."    ");
        }

    }

}

#######################################################
#       printYaml
# Description: Writes the yaml output to a file with the name of the cell
#   This is done by opening a FILEHANDLE and seleting the handle.
#   Any normal prints will now go to this file
#######################################################
sub printYaml {
    my ($hash,$yamlPath,$cellList)=@_;
    my ($cell)=(undef)x1;

    if(! -e $yamlPath){
        system("/bin/mkdir -p $yamlPath");
    }

	foreach $cell (keys %$hash){
        if($$cellList{"CELLCOUNT"} == 0 ||  exists $$cellList{$cell}){
            open(OUTFILE, ">".$yamlPath."/".$cell.".yaml")|| die "Can't open: ".$yamlPath."/".$cell.".yaml";
            select(OUTFILE);
            &printYamlItems(\%{$$hash{$cell}},"");
            close OUTFILE;
        }
    }
}

#######################################################
#######################################################
#                       MAIN
#######################################################
#######################################################
my ($infile)=("")x1;
my ($yamlPath,$process)=(undef)x2;
my @topArray=();
my %newHash=();
my %processMatrix=();
my $delimiter = '\.';
my %cellList=();

$cellList{"CELLCOUNT"}=0;
$yamlPath=".";


#print STDERR "IN $0: @ARGV\n";
$ARGV[0]= "-help"  if $#ARGV <0; # displays help message id no args are defined
while ($ARGV[0]){
    if ($ARGV[0] =~ /^-h(.*)/){  #
        print STDERR "$help_message";
        exit 1;
    }elsif($ARGV[0] =~ /^-v(.*)/){ #
		print "$scriptName: $VERSION\n";
		exit 0;
    }elsif($ARGV[0] =~ /^-p(.*)/){ #
        shift;
        $process=$ARGV[0];
        if($process =~ /^[0-9]+$/){
            $process = "p" . $process;
        }
    }elsif($ARGV[0] =~ /^-c(.*)/){ #
        ++$cellList{"CELLCOUNT"};
        shift;
        $cellList{$ARGV[0]}=1;
    }elsif($ARGV[0] =~ /^-y(.*)/){ #
        shift;
        $yamlPath=$ARGV[0]
    }else{
		$infile=$ARGV[0];
    }
    shift;
}

&readCSV($infile,\@topArray,\%processMatrix);

if(!exists $processMatrix{$process}){
    printf(STDOUT "Undefined process (%s) in spreadsheet\n",$process);
    exit 1;
}

&reorgHash(\@topArray,$process,\%processMatrix,\%newHash,$delimiter);
&printYaml(\%newHash,$yamlPath,\%cellList);

exit $EXITCODE
