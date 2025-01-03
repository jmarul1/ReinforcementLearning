#!/bin/bash

## Author	: Abdelmeged, Ramy Gamal <ramy.gamal.abdelmeged@intel.com>
## Description	: Translate the dotProcess in Numbers to English 
## Usage	: ./num2eng_trans.sh <dot_process>
##		: example : ./eng2num_trans.sh 21 icv (output is : _drdotTwentyOne)
##		            ./eng2num_trans.sh 21 ICV (output is : _drdotTwentyOne)
##		            ./eng2num_trans.sh 21 cal (output is : dotTwentyOne)
##		            ./eng2num_trans.sh 21     (output is : dotTwentyOne)
##		: No limit to the supported dots
## Date		: 12/18/2017


if [[ $# -eq 0 ]];then
   print "Error: No Arguments, please spacify a dot in numbers, and tool name"
   exit
fi

echo $1 $2 | awk '
BEGIN {	# Initialize variables...
	# Final single digits:
	fd[0] = "Zero"; fd[1] = "One"; fd[2] = "Two"; fd[3] = "Three"
	fd[4] = "Four"; fd[5] = "Five"; fd[6] = "Six"; fd[7] = "Seven"
	fd[8] = "Eight"; fd[9] = "Nine"
	# Leading single digits:
	ld[1] = "One"; ld[2] = "Two"; ld[3] = "Three"; ld[4] = "Four"
	ld[5] = "Five"; ld[6] = "Six"; ld[7] = "Seven"; ld[8] = "Eight"
	ld[9] = "Nine"
	# Final teens:
	ft[10] = "Ten"; ft[11] = "Eleven"; ft[12] = "Twelve"
	ft[13] = "Thirteen"; ft[14] = "Fourteen"; ft[15] = "Fifteen"
	ft[16] = "Sixteen"; ft[17] = "Seventeen"; ft[18] = "Eighteen"
	ft[19] = "Nineteen"
	# Leading teens:
	lt[10] = "Ten"; lt[11] = "Eleven"; lt[12] = "Twelve"
	lt[13] = "Thirteen"; lt[14] = "Fourteen"; lt[15] = "Fifteen"
	lt[16] = "Sixteen"; lt[17] = "Seventeen"; lt[18] = "Eighteen"
	lt[19] = "Nineteen"
	# Final tens:
	fT[2] = "Twenty"; fT[3] = "Thirty"; fT[4] = "Forty"
	fT[5] = "Fifty"; fT[6] = "Sixty"; fT[7] - "Seventy"
	fT[8] = "Eighty"; fT[9] = "Ninety"
	# Leading tens:
	lT[2] = "Twenty"; lT[3] = "Thirty"; lT[4] = "Forty"; lT[5] = "Fifty"
	lT[6] = "Sixty"; lT[7] = "Seventy"; lT[8] = "Eighty"; lT[9] = "Ninety"
	# Units:
	u[2] = "Thousand"; u[3] = "Million"; u[4] = "Billion"; u[5] = "Trillion"
	u[6] = "Quadrillion"; u[7] = "Quintillion"; u[8] = "Sextillion"
	u[9] = "Septillion"; u[10] = "Octillion"; u[11] = "Nonillion"
	u[12] = "Decillion"; u[13] = "Undecillion"
	# The last entry above will only be used in overflow diagnostics.  If
	# more entries are added, remember that one extra entry must be added.
	# The following maximum u[] subscript must be updated if more entries
	# are added above.
	ucnt = 13
}

# Function to print US English string corresponding to 3 digit numeric string.
function p3(units, gcnt, gnum,    d1, d2, d3, d23) {
	# If we have a zero and this is not the last group, nothing to print...
	if(g[gnum] == 0 && gnum < gcnt) return(1)
	# Grab inividual digits and last two digits...
	d1 = int(g[gnum] / 100)
	d23 = g[gnum] % 100
	d2 = int(d23 / 10)
	d3 = d23 % 10
	# Hundreds to print?
	if(d1)
		printf("%sHundred%s", ld[d1],
			d23 ? "" : (gcnt == gnum) ? "th\n" : "" units \
				(t[gnum] ? "" : "th\n"))
	# Print last two digits...
	if(d23 || (d1 == 0 && gnum == gcnt))
		if(d2 == 1) 
			# 10-19:
			printf("%s", (gnum == gcnt) ? ft[d23] "\n" : \
				lt[d23] "" units (t[gnum] ? "" : "th\n"))
		else if(d2)
			# 20-99:
			if(d3)	# [2-9][1-9]:
				printf("%s%s", lT[d2],
					(gnum == gcnt) ? fd[d3] "\n" : \
					ld[d3] "" units \
					(t[gnum] ? "" : "th\n"))
			else	# [2-9]0:
				printf("%s", (gnum == gcnt) ? fT[d2] "\n" : \
					lT[d2] "" units \
					(t[gnum] ? "" : "th\n"))
		else	# 0-9:
			printf("%s", (gnum == gcnt) ? fd[d3] "\n" : ld[d3] "" \
				units (t[gnum] ? "" : "th\n"))
	return(t[gnum])
}
# Process the One field from each line in an input file...
{	# Show original input...
	#printf("Input:\"%s\"\n", $0)
	# Check for non-digits
	if(match($1, /[^[:digit:]]/)) {
		print "Only digits are alloweed."
		next
	}
	# Strip leading 0s
	if(match($1, /^0+/)) {
		$1 = (RLENGTH == length($1)) ? "0" : substr($1, RLENGTH + 1)
		#printf("Updated input:\"%s\"\n", $0)
	}
	#RG: Added the dot to the start of the result
	#ICV/icv will add _drdot, others (Cal/PVS) will add dot
	#printf ("Ramy: tool name is \"%s\"\n", $2)
	if(($2 == "icv") || ($2 == "ICV") )
	  printf ("_drdot")
	else
	  printf ("dot")
	  
	# Split into groups of three digits...
	ng = int((length($1) + 2) / 3)
	if(ng == 0) next	# skip eimpty lines
	if(ng >= ucnt) {	# Too big to handle?
		printf("Can only handle numbers less than one %s.\n",
			u[ucnt])
		next
	}
	gw = length($1) - (ng - 1) * 3
	off = 1
	for(i = 1; i <= ng; i++) {
		g[i] = substr($1, off, gw)
		t[i] = substr($1, off + gw) + 0
		off += gw
		gw = 3
	}
	# Process the groups of digits...
	for(i = 1; p3(u[ng + 1 - i], ng, i); i++);
	exit 
}'
