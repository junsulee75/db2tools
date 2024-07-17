#!/usr/bin/perl

##########################################
 # Copyright ? 2021 Jun Su Lee. All rights reserved.
 # Author : Jun Su Lee ( junsulee@au1.ibm.com )
 # Description : 
 # Read csv like files (Db2 SQL del output or any csv with comma separated), then print delta values for a pointed Nth column.  
 # It just reads lines and display delta values between the lines.   
 # Therefore it's important to give correct order inputs. This script is not responsible for that.    
 # As of now, this script supports only one column for each line to process.        
 #
 # Category : DB2 support
 # Date : Sep.22, 2021
 #
 # Revision History
 # - Nov. 30, 2018 : 
##########################################

use Getopt::Long;
use File::Basename;

use Data::Dumper ;  # only for debugging purpose  

my $fileName;
my $colNum;  # To run c++filt or not. This is only for Linux platform. By default, 0 (Not running). Use this only for Linux trap files.
my $keyword;
my $splitDelimiter=",";   # By default, comma (,)

my $DEBUG;

my @Parsed; # Parsed inputs
my $fileTimestamp;

my $curVal; # current Value
my $preVal; # previous Value
my $deltaVal; # delta Valu

my $lineString;

&usage if( scalar(@ARGV) < 1 ); 

GetOptions(
        "filename=s" => \$fileName,
        "column=i" => \$colNum,
        "keyword=s" => \$keyword,
        "splitDelimiter=s" => \$splitDelimiter,
        "debug=i" => \$DEBUG
)
        or die "Incorrect usage ! \n";

@fileList = glob($fileName);


sub doParseCSVFile {
	my ( $fn ) = @_ ;
        open FH, $fn or die "can't open the file $fn \n\n";

        print "\n\n== Parsing the file : $fn : ==\n\n";
	my $colVal;
	while ( <FH> ) {
		#print $_;

		# If keyword is set, it filters the lines. If not set, basically read all lines from each file
		if ( m/$keyword/ ) {
			$lineString = $_;  
			#my @columns = split(',', $lineString) ;   
			my @columns = split($splitDelimiter, $lineString) ;   
			$colVal = $columns[$colNum-1] ; ## minus one as the index starts from zero
			#print $lineString;

			push @Parsed, { fileName => $fn, col1 => $colVal};
		}
	}
	#push @Parsed, { fileName => $fn, col1 => $colVal};

}



foreach my $inputFile (@fileList){
        doParseCSVFile $inputFile;

}

## Sort by filename assuming file names have timestamps.  
@Parsed = sort { $a->{fileName} cmp $b->{fileName} } @Parsed;
print "=======================================================> Parsed : Sorted by file name\n" if $DEBUG;
print Data::Dumper->Dump ( [ @Parsed ], [ 'Parsed' ] ) if $DEBUG; 


print "============== RESULT =======\n" ;

my $cnt=0;
# Reading the saved array
for my $p1 (@Parsed) {

	#print "$p1->{fileName}\n";
	$curVal= $p1->{col1};

	if ($cnt > 0) { # skip to calculate and print the 1st input
		$deltaVal= $curVal - $preVal;
		#print "$p1->{fileName} %15.2f\n", $deltaVal ;
		print "DEBUG : $curVal - $preVal = $deltaVal \n" if $DEBUG;

		my $result = sprintf("%15d", $deltaVal); # formatting 
		print "$p1->{fileName} : $result \n" ;
	}
	$preVal = $curVal;
	$cnt++;
}

sub usage{
	$prog  = basename($0);
	print "Usage:\n";
	print "-f <filenames>\n";
	print "-c <Nth column>\n";
	print "-k <keyword to grep if any. If not set, reading all lines from files.>\n";
	print "-s <CSV delimiter character. By default, comma.>\n";
	print "-d <debug mode> -- 1:debug\n";
	print "example : \n";
	print "$prog -f 'mon_get_workload.del*' -c=4 -k 'SYSDEFAULTUSERWORKLOAD'\n";	

}

