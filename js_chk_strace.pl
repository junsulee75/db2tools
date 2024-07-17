#!/usr/bin/perl


##########################################
 # program name : js_chk_strace.pl
 # Copyright ? 2020 Jun Su Lee. All rights reserved.
 # Author : Jun Su Lee ( junsulee@au1.ibm.com )
 # Description : checking linux strace output with time option.
 #  ex) strace -tt -F -T -o strace.out time ./db2locssh nitdbo01 hostname
 
 # Note : 
 #  
 # Category : DB2 support
 # Usage
 # js_view_stacks.pl -f='FODC_Trap*/*trap.txt'
 # Date : Feb.21, 2019
 # Revision History
 # - Aug. 24, 2019 : Split each stack with empty rows
 # 
##########################################

# format
# 9004  16:11:24.978954 read(7, "Name:\tkworker/0:0\nUmask:\t0000\nSt"..., 2048) = 905 <0.000023>

use Getopt::Long;
use File::Basename;

my $fileName;
my @fileList;
my $pattern;
my $DEBUG;
my $totalTime;
my $totalCnt=0;

sub usage{
	print <<AUD ;

    Usage :
	$prog -f <filename> -p <Regular experesson pattern to grep>

	example : 
	$prog -f 'strace.out_time' -p 'read('

AUD
	exit;
}

&usage if( scalar(@ARGV) < 2 ); 

GetOptions(
	"filename=s" => \$fileName,
	"pattern=s" => \$pattern,
	"debug=i" => \$DEBUG
)
	or die "Incorrect usage ! \n";

@fileList = glob($fileName);

sub doParseStrace {
	my ( $fn ) = @_ ;
	open FH, $fn or die "can't open the file $fn \n\n";

	print "\n\n== $fn : ==\n\n";
	while ( <FH> ) {

		## 
		if ( m/$pattern.+(\d+\.\d+)/ ) {
			print $_;
            $deltaTime=$1;
            $totalTime=$totalTime + $1;
            $totalCnt=$totalCnt + 1;
            print "$pattern : $deltaTime\n";

		}
	
	}
	print "\n";

}

foreach my $inputFile (@fileList){
	doParseStrace $inputFile;
}

print "========================================\n";
print "Pattern  :  totalCount : totalTime\n";
print "$pattern : $totalCnt : $totalTime\n";