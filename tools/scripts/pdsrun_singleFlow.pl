#!/usr/bin/perl

$numArgs = $#ARGV + 1;
if($numArgs != 3)
{
  print "\nUSAGE: pdsrun_FC.pl <file_name> \n";
  print "Ex: pdsrun_singleFlow.pl FLOWNAME DATAFORMAT fileinput.txt \n";
  print "Format in fileinput.txt \n<filename> <local/batch>\n\n";
  print "For Batch process, check these env variables before running the script: NBCLASS  NBPOOL   NBQSLOT\n\n";

  exit 0;
}
$flowname = $ARGV[0]; 
$inpformat = $ARGV[1];
$CellsFile = $ARGV[2];
open(InFile, $CellsFile);
@cellList = <InFile>;
close(InFile);
foreach $cell(@cellList)
{
	chomp($cell);
	if($cell =~ /^\s*#/)
	{
		next ;
	}
	($topcellname, $runmode, $runcmp, $runcheck, $dyndisk) = split(/\s+/, $cell);
        $cellName = $topcellname; 	
	$inputtype = $inpformat;
	$iss_flow = $flowname;
	if ($runmode eq "") {
		$runmode = "batch";
	}
	print "\n$ENV{'PDSBATCHLINE'}\n\n" ;	
$pdsCmd = "_pypdsbuilder -laytopcell ".$cellName ." -libspec ".$cellName . " -saveworkdir no -autotail no -mailuser yes -trcpin top -runmode ". $runmode;
$pdsCmd = $pdsCmd. " -mode ". $iss_flow . " -inputtype " . $inputtype;

	if ($iss_flow =~ /trc/i)
	{
		if ($runcmp =~ /no/i)
		{
			# Do nothing 
		}
		else
		{
			$pdsCmd = $pdsCmd. " -verifytool yes";
			#$pdsCmd = $pdsCmd. " -snname " .$ENV{'WARD'}."/netlist/mkisp/".$cellName .".sn";
		}
		if ($runcheck =~ /no/i)
		{
			$pdsCmd = $pdsCmd. " -topframe nocheck ";
		}
		
	}
	if ($iss_flow =~ /cellall/i)
        {	
		if ($runcmp =~ /no/i)
                {
                        # Do nothing
                }
                else
		{
                	$pdsCmd = $pdsCmd. " -verifytool yes";
			#$pdsCmd = $pdsCmd. " -snname " .$ENV{'WARD'}."/netlist/mkisp/".$cellName .".sn";
		}
		if ($runcheck =~ /no/i)
		{
			$pdsCmd = $pdsCmd. " -topframe nocheck ";
	        }
        }

	if ($inputtype  =~ /oas/i)
	{
		#$pdsCmd = $pdsCmd. " -oasname " .$ENV{'WARD'}."/pds/oas/".$cellName .".oas";
	}	

	if ($dyndisk =~ /yes/i)
        {
                $pdsCmd = $pdsCmd. " -ddisk yes";
        }
        else
        {
                $pdsCmd = $pdsCmd. " -ddisk no";
        }

	print "\n\n$pdsCmd\n\n";
	system $pdsCmd; 
}

