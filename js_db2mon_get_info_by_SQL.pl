#!/usr/bin/perl


##########################################
 # program name : js_db2mon_get_info_by_SQL.pl
 # Copyright ? 2018 Jun Su Lee. All rights reserved.
 # Author : Jun Su Lee ( junsulee@au1.ibm.com )
 # Description : Getting SQL pattern from an interested section only from multiple db2mon files
 #   Imagine you have event few or hundreds of db2mon output files and you want to see performance pattern for a interested SQL statement in a one shot.   
 # This is the script that can help.  
 # It can be also used for grep some strings pattern under a db2mon output section.   
 #
 # Category : DB2 support
 # Date : Oct.30, 2018
 #
 # Revision History
 # - Jan. 13, 2021 :  Fixed the but showing garbage data even after the interested section
##########################################
 #
use Getopt::Long;
use File::Basename;

## Partial SQL st===rt part to search
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
	my $foundSection = 0; ## Flag saying we found the section keyword
        my $secondSectionTitleBar = 0; ## Flag saying it reached 2nd Section title bar
	$foundSQL = 0;
	$foundCaptureTIme = 0;

	open FH, $fn or die ;

	print "############# File = $fn\n\n";

	while ( <FH> ) {

		## Found the interested section
		#if ( m/Top SQL statements by execution time / ) {
		if ( m/$sectionToFind/ ) {
			print "1 => $foundSection | $secondSectionTitleBar \n" if $DEBUG;
			print $_;
			$foundSection = 1;
			$secondSectionTitleBar = 0;
		}

		## Print the column line. Mostly start with the first column 'MEMBER'
		if ( $foundSection == 1 and m/^MEMBER/ ) {
			print "2 => $foundSection | $secondSectionTitleBar  \n " if $DEBUG;
			print $_;
		}

		## Found the keyword under the section
		if ( $foundSection == 1 and m/$sqlKeyword/ ) {
			print "3 => $foundSection | $secondSectionTitleBar  \n " if $DEBUG;
			print $_;
			#$foundSection = 0;
		}

		## Every section is like the following format. When we reach every new section, need to reset flag.
		## ======   <===== here !!
		## Section name
		## ====== 	
		## This if block and the next if block should be this order. Swapping will return nothing making $foundSection to be 0 always	
		if (  $secondSectionTitleBar == 1 and m/^=======/ ) {
			print "5 => $foundSection | $secondSectionTitleBar  \n " if $DEBUG;
			$foundSection = 0;
			$secondSectionTitleBar = 0;
		}

		## This is when reaching 2nd bar of a section title 
		## ======
		## section name
		## ======   <==== here !!
		if ( $foundSection == 1 and m/^=======/ ) {
			print "4 => $foundSection | $secondSectionTitleBar  \n " if $DEBUG;
			#print $_ if $DEBUG ;
			$secondSectionTitleBar = 1;
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


