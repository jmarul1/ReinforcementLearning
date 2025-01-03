#!/usr/intel/bin/perl -w

print "\n\nThis script reads a binary file and generates an ascii version of it\n\n";

$args = @ARGV;
unless ($args == 1) {
    die "The usage: bin2ascii.pl <split file name>\n\n";
}
$inFile = shift;

$os = $^O;

if ($os eq "linux") {
    print "Converting the split file into Unix format";
    @fields = split(/\./, $inFile);
    $tmpFile = $fields[0] . ".linux";
    convertAllData($inFile, $tmpFile);
    $inFile = $tmpFile;
}

@data= ();
pickAllData($inFile, \@data);

# access the data
 
$row = @data;
$col = @{$data[0]};
print "number of rows = $row and columns = $col\n";

# put the data sets in an xgraph file for testing

@fields = split(/\./, $inFile);
$outFile = $fields[0] . ".dat";    
open(DATFILE, ">$outFile");
if ($row > 1) {
    for ($i = 0; $i < $row-1; $i++) {
	$ext = $i+1;
	$ext = "curve" . "$ext";
	printf DATFILE "\"$ext\n";
	for ($j = 0; $j <$col; $j++) {
	    printf DATFILE "%8.7e   %8.7e\n", $data[$row-1][$j], $data[$i][$j]; 
	}
	printf DATFILE "\n";
    }
}
if ($row == 1) {
    $ext = $row;
    $ext = "curve" . "$ext";
    printf DATFILE "\"$ext\n";
    for ($j = 0; $j <$col; $j++) {
	printf DATFILE "%8.7e   %8.7e\n", $data[$row-1][$j], $j; 
    }
    printf DATFILE "\n";
}

close(DATFILE);
if ($os eq "linux") {
    system "rm $tmpFile";
}



########################
# Picks the data from the binary file and places it in the array of arrays structure
########################

sub pickAllData {
    my ($inFile, $dataRef) = @_;

# open the file and get its size

    open(INFILE, "<$inFile") || die "Cannot open the file : $inFile \n";
   
    @s = stat(INFILE);
    $fileSize = $s[7];
    print "File size is $fileSize bytes\n";

# determine the number of data sets

    $buf = $val = 0;
    $i = 0;
    until ($val == 1111) {
	$i++;
	seek(INFILE, $i*4, 0);
	read(INFILE, $buf, 4);
	$val = unpack("f", $buf);
	unless (defined($val)) {
	    die "Corrupt split file $inFile \n";
	}
    }
    $dataSet = $i - 1;
    print "Number of data sets = $dataSet\n";

# get all the data sets

    $buffer = 0;
    seek(INFILE, 0, 0);                    # set the pointer at the beginnig of the file!
    read(INFILE, $buffer, $fileSize);      # read all data in the buffer
    $d = $fileSize / 4;                    # number of data points (each data 4 bytes)
    push(@val, unpack("f$d", $buffer));    # val contains all data points
    $b = $d / ($dataSet + 2);              # number of blocks (2 for bondary 1111)

    print "d = $d\n";
    print "b = $b\n";
    $valSize = @val;
    print "val size = $valSize\n";
    #print "@val\n";

    for ($j = 0; $j < $b; $j++) {
	for ($i = 1; $i <= $dataSet; $i++) {
	    $dataRef->[$i-1][$j] = $val[$j*($dataSet+2) + $i];  
	}
    }
    
    return(0);
}

########################
# Converts the data from Linux to Unix format and places it in the array of arrays structure
########################

sub convertAllData {
    my ($inFile, $tmpFile) = @_;

# open the file and get its size

    open(INFILE, "<$inFile") || die "Cannot open the file : $inFile \n";
    open(OUTFILE, ">$tmpFile") || die "Cannot open tmp file : $tmpFile \n";
 
    @s = stat(INFILE);
    $fileSize = $s[7];
    print "File size is $fileSize bytes\n";

    $d = int($fileSize / 4);
    for ($i = 0; $i < $d; $i++) {
	$j = $i * 4;

	# read the bytes from the input file

	seek(INFILE, $j,   0);
        read(INFILE, $v0,  1);
	seek(INFILE, $j+1, 0);
	read(INFILE, $v1,  1);
	seek(INFILE, $j+2, 0);
        read(INFILE, $v2,  1);
	seek(INFILE, $j+3, 0);
	read(INFILE, $v3,  1);

	# rotate the bytes

	$temp = $v0;
	$v0 = $v3;
	$v3 = $temp;
	$temp = $v1;
	$v1 = $v2;
	$v2 = $temp;

	# write the rotated bytes in the output file

	seek(OUTFILE, $j,   0);
        $written = syswrite(OUTFILE, $v0,  1);
        die "Write error\n" unless defined $written;

	seek(OUTFILE, $j+1, 0);
        $written = syswrite(OUTFILE, $v1,  1);
        die "Write error\n" unless defined $written;

	seek(OUTFILE, $j+2, 0);
        $written = syswrite(OUTFILE, $v2,  1);
        die "Write error\n" unless defined $written;

	seek(OUTFILE, $j+3, 0);
	$written = syswrite(OUTFILE, $v3,  1);
        die "Write error\n" unless defined $written;

    }
    close(INFILE);
    close(OUTFILE);
}


