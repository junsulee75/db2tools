#!/usr/bin/perl


## Test
##########################################
 # program name : js_db2mon_cf_check.pl
 # Copyright ? 2018 Jun Su Lee. All rights reserved.
 # Author : Jun Su Lee ( junsulee@au1.ibm.com )
 # Description : Parse db2mon files and display "Round-trip CF command" and CF-side command execution 
 #
 # Category : DB2 support
 # Usage
 # js_db2mon_cf_check.pl -f='filename' -i='functionname'
 # Date : Oct.30, 2018
 #
 # Revision History
 # - Nov. 30, 2018 : 
##########################################

use Getopt::Long;
use File::Basename;
use Data::Dumper ;       # only for debugging, comment this when giving to users who don't have this module

my $fileName;
my @fileList; # filelist from user command input parameter
my $inputfunction;
my $cfInputFunction;
my @Parsed;
my @parseFileList; # file list to parse. fileName, $fileTimeStamp


my $tmpMember;
my $tmpCF;
my $tmpRTtotCFReq;
my $tmpRTavgTime;

my $RTtotCFReq0_128 ;
my $RTavgTime0_128 ;
my $RTtotCFReq1_128 ;
my $RTavgTime1_128 ;

my $RTtotCFReq0_129 ;
my $RTavgTime0_129 ;
my $RTtotCFReq1_129 ;
my $RTavgTime1_129 ;

my $tmpCF2 ;
my $tmpCFReq2 ;
my $tmpCFPct2 ;
my $tmpCFTime2 ;

my $CFtotReq128;
my $CFtotPct128;
my $CFavgTime128;
my $CFtotReq129;
my $CFtotPct129;
my $CFavgTime129;

my $DEBUG = 0;

## if no input option, display the usage and exit
usage() if ( @ARGV == 0 );

GetOptions(
	    "start=s" => \$StartTime,
	    "end=s" => \$EndTime, 
	    "filename=s" => \$fileName,      
	    "inputfunction=s" => \$inputfunction,
	    "debug=i" => \$DEBUG      
	    ) ;

#print "1.filename : $fileName \n";
@fileList = glob($fileName);

#if ( $inputfunction eq "SetLockState" ){
#if ( $inputfunction eq "SetLockStateMultiple" ){
if ( $inputfunction eq "SetLockState" or $inputfunction eq "SetLockStateMultiple" ){
	$cfInputFunction = "ProcessSetLockState";
}else{
	$cfInputFunction = $inputfunction;
}


	print "\n ##### $inputfunction / $cfInputFunction   \n" ;

sub doParseDb2monFile {

	my ( $fn ) = @_ ;
	open FH, $fn or die "can't open the file $fn \n\n";

	print "\n ######### $fn \n" ;

	## Reset the value not to be used from the previous file parsing
		
	$tmpMember="";$tmpCF="";$tmpRTtotCFReq="";$tmpRTavgTime="";
	$RTtotCFReq0_128="" ;$RTavgTime0_128="" ; $RTtotCFReq1_128="" ; $RTavgTime1_128="" ;
	$RTtotCFReq0_129="" ;$RTavgTime0_129="" ; $RTtotCFReq1_129="" ; $RTavgTime1_129="" ;
	$tmpCF2="" ; $tmpCFReq2="" ; $tmpCFPct2="" ;$tmpCFTime2="" ; 
	$CFtotReq128=""; $CFtotPct128=""; $CFavgTime128=""; 
	$CFtotReq129=""; $CFtotPct129=""; $CFavgTime129="";

	while ( <FH> ) {

		 

		# Round-trip CF command execution 
		if ( m/^\s+([0-1])\s+(12[8-9])\s$inputfunction\s+(\d+)\s+(\d+\.\d+)/ ) {
			print $_ ;
			$tmpMember = $1;
			$tmpCF = $2;
			$tmpRTtotCFReq = $3;
			$tmpRTavgTime = $4;

			if ( $tmpMember == 0 and $tmpCF == 128 ){
				$RTtotCFReq0_128 = $tmpRTtotCFReq;
				$RTavgTime0_128 =  $tmpRTavgTime;
			}elsif ( $tmpMember == 1 and $tmpCF == 128 ){
				$RTtotCFReq1_128 = $tmpRTtotCFReq;
				$RTavgTime1_128 =  $tmpRTavgTime
			}elsif ( $tmpMember == 0 and $tmpCF == 129 ){
				$RTtotCFReq0_129 = $tmpRTtotCFReq;
				$RTavgTime0_129 =  $tmpRTavgTime
			}
			
		}
		if ( m/^\s+(12[8-9])\s$cfInputFunction\s+(\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)/ ) {
			print $_;
			$tmpCF2 = $1;
			$tmpCFReq2 = $2;
			$tmpCFPct2 = $3;
			$tmpCFTime2 = $4;

			if ( $tmpCF2 == 128 ){
				$CFtotReq128 = $tmpCFReq2;
				$CFtotPct128 = $tmpCFPct2;
				$CFavgTime128 = $tmpCFTime2;
			}elsif ( $tmpCF2 == 129 ){
				$CFtotReq129 = $tmpCFReq2;
				$CFtotPct129 = $tmpCFPct2;
				$CFavgTime129 = $tmpCFTime2;
			}

		}
	}

	push @Parsed, { 
		fileName => $fn,
	        RTtotCFReq0_128 => $RTtotCFReq0_128,	
		RTavgTime0_128 => $RTavgTime0_128,   
	        RTtotCFReq1_128 => $RTtotCFReq1_128,	
		RTavgTime1_128 => $RTavgTime1_128,

	        RTtotCFReq0_129 => $RTtotCFReq0_129,	
		RTavgTime0_129 => $RTavgTime0_129,   

		CFtotReq128 => $CFtotReq128,
		CFtotPct128 => $CFtotPct128,
		CFavgTime128 => $CFavgTime128,

		CFtotReq129 => $CFtotReq129,
		CFtotPct129 => $CFtotPct129,
		CFavgTime129 => $CFavgTime129
	};



}

### Parsing files and make filename/timestamp list
foreach my $inputFile (@fileList) {

	doParseDb2monFile $inputFile;

}

print "=======================================================> Parsed\n" if $DEBUG;
print Data::Dumper->Dump ( [ @Parsed ], [ 'Parsed' ] ) if $DEBUG ;


##################################################################
####### Print USER CPU part on terminal and on 2nd Excel worksheet 
##################################################################
print "\n\n*** $inputfunction / $cfInputFunction \n"; ## plain output
print " Col1 : FileName : \n"; ## plain output
print " Col2 : RT_TotReq(0-128) : Round-trip CF command execution : TOTAL_CF_REQUESTS \n"; ## plain output
print " Col3 : RT_AvgTime(0-128): Round-trip CF command execution : AVG_CF_REQUEST_TIME_MICRO\n"; ## plain output
print " Col4 : RT_TotReq(1-128) : Round-trip CF command execution : TOTAL_CF_REQUESTS \n"; ## plain output
print " Col5 : RT_AvgTime(1-128): Round-trip CF command execution : AVG_CF_REQUEST_TIME_MICRO\n"; ## plain output
print " Col6 : RT_TotReq(0-129) : Round-trip CF command execution : TOTAL_CF_REQUESTS \n"; ## plain output
print " Col7 : RT_AvgTime(0-129): Round-trip CF command execution : AVG_CF_REQUEST_TIME_MICRO\n"; ## plain output

print " Col11 : CF_TotReq(128)  : CF-side command execution : TOTAL_CF_REQUESTS\n"; ## plain output
print " Col12 : CF_PctTot(128)  : CF-side command execution : PCT_TOTAL_CF_CMD\n"; ## plain output
print " Col13 : CF_AvgTime(128)  : CF-side command execution : AVG_CF_REQUEST_TIME_MICRO\n"; ## plain output
print " Col21 : CF_TotReq(129)  : CF-side command execution : TOTAL_CF_REQUESTS\n"; ## plain output
print " Col22 : CF_PctTot(129)  : CF-side command execution : PCT_TOTAL_CF_CMD\n"; ## plain output
print " Col23 : CF_AvgTime(129)  : CF-side command execution : AVG_CF_REQUEST_TIME_MICRO\n"; ## plain output
#print "FileName\tRT_TotReq(0-128)\tRT_AvgTime(0-128)\n"; ## plain output
#print "\nFileName\tCol2\tCol3\t\tCol4\tCol5\n"; ## plain output


### Header formatting
print "\n";
printf "%15s","FileName";
printf "%10s","Col2";
printf "%10s","Col3";
printf "%10s","Col4";
printf "%10s","Col5";

printf "%10s","Col6";
printf "%10s","Col7";

printf "%10s","Col11";
printf "%10s","Col12";
printf "%10s","Col13";
printf "%10s","Col21";
printf "%10s","Col22";
printf "%10s","Col23";
print "\n";


for my $p (@Parsed) {
	#print "$p->{fileName}\t";
	printf "%15s",$p->{fileName};
	printf "%10d",$p->{RTtotCFReq0_128};
	printf "%10.2f",$p->{RTavgTime0_128};
	printf "%10d",$p->{RTtotCFReq1_128};
	printf "%10.2f",$p->{RTavgTime1_128};

	printf "%10d",$p->{RTtotCFReq0_129};
	printf "%10.2f",$p->{RTavgTime0_129};
	
	printf "%10d",$p->{CFtotReq128};
	printf "%10.2f",$p->{CFtotPct128};
	printf "%10.2f",$p->{CFavgTime128};
	printf "%10d",$p->{CFtotReq129};
	printf "%10.2f",$p->{CFtotPct129};
	printf "%10.2f",$p->{CFavgTime129};

	print "\n";
}


sub usage{

	$prog  = basename($0);
	
	print <<EOF;

	$prog <options>

	-f : File names
	-i : Interested CF functions
	-d : debug mode ( 0 : disable, 1 : Enable )

	Example)
	$prog -f 'db2mon*' -i 'WriteAndRegisterMultiple'

EOF
    exit;

}




