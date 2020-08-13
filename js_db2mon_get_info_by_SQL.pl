#!/usr/bin/perl

use Getopt::Long;
use File::Basename;

## Partial SQL start part to search
## "SELECT T1.ZA_PLAN_ID";

$DEBUG=0;

&usage if( scalar(@ARGV) < 1 ) ;

GetOptions(
	    "section=s" => \$sectionToFind,
	    "keyword=s" => \$sqlKeyword, 
	    "filename=s" => \$fileName,      
	    "debug=i" => \$DEBUG      
	    )
or die "Incorrect usage ! \n";

sub dowork {
	my ( $fn ) = @_ ;

	## Partial SQL start part to search
	#$sqlKeyword="call TSRQC00.USP_GET_MERCHANT_DTL";
	#$sqlKeyword="call TSRQC00.USP_GET_MERCHANT_DTL";
	$foundSection = 0;
	$foundSQL = 0;
	$foundCaptureTIme = 0;

	open FH, $fn or die ;

	print "############# File = $fn\n\n";

	while ( <FH> ) {

		#if ( m/Top SQL statements by execution time / ) {
			if ( m/$sectionToFind/ ) {
			print $_;
			$foundSection = 1;
		}

		if ( $foundSection == 1 and m/^MEMBER/ ) {
			print $_;
		}

		if ( $foundSection == 1 and m/$sqlKeyword/ ) {
			print $_;
			$foundSection = 0;
		}
			
	}

	close FH;
}


foreach $fn ( glob "$fileName" ) {
	dowork $fn ;
	print "\n";
}



sub usage{
	$prog  = basename($0);
	
	print "Usage:\n";
	print "$prog -f <filename> -s <section> -k <partial SQL keyword>\n";
	print "-f <filenames>\n";
	print "-s <section name>\n";
	print "  'Top SQL statements by execution time '\n";
	print "  'Top SQL statements by execution time, aggregated by PLANID'\n";
	print "  'Wait time breakdown for top SQL statements by execution time '\n";
	print "  'Top SQL statements by time spent waiting'\n";
	print "  'IO statistics per stmt - top statements by execution time'\n";
	print " ...\n";
	print "-d <debug mode> -- 1:debug\n";
	print "example : \n";
	print "$prog -f 'db2mon*' -s 'Top SQL statements by execution time ' -k 'call TSRQC00.USP_GET_MERCHANT_DTL'\n";	
	exit;
}


