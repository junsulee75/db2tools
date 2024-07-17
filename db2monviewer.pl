#!/usr/bin/perl

use Getopt::Long;
use Getopt::Std;
use File::Basename;

=pod

=head1 VERSION

    Version 		: $Revision: 1.0 $
    Last modified 	: $Date: 2014-05-09 11:49:37 +1000 (Fri, 05 July 2019) $
    URL			: $HeadURL: https://github.com/junsulee75 $ ;

=head1 DESCRIPTION

    This program parses multiple db2mon output files 
	and provide features to look some interest information in one shot without opening files manually or multiple grep/awk/sed effort.

=cut


my @fileList; # filelist from user command input parameter


sub usage{

	$prog  = basename($0);
	print <<AUD ;

    Usage :
	$prog -f <filename> -s <section> -k <partion SQL keyword>
	-f '<filenames>'
	-s 'section name>'
	  'Top SQL statements by execution time '
	  'Top SQL statements by execution time, aggregated by PLANID'
	  'Wait time breakdown for top SQL statements by execution time '
	  'Top SQL statements by time spent waiting'
	  'IO statistics per stmt - top statements by execution time'

	  -k <partial SQL keyword to search>
	 ...
	-d <debug mode> -- 1:debug
	example : 
	$prog -f 'db2mon*' -s 'Top SQL statements by execution time ' -k 'call TSRQC00.USP_GET_MERCHANT_DTL'	


AUD
	exit;
}


$DEBUG=0;

&usage if( scalar(@ARGV) < 1 ) ;

GetOptions(
	    "section=s" => \$sectionToFind,
	    "keyword=s" => \$sqlKeyword, 
	    "filename=s" => \$fileName,      
	    "debug=i" => \$DEBUG      
	    )
or die "Incorrect usage ! \n";

@fileList = glob($fileName);

sub doSearch {
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

		# Marking on the section
		#if ( m/Top SQL statements by execution time / ) {
		if ( m/$sectionToFind/ ) {
			print $_;
			$foundSection = 1;
		}

		if ( $foundSection == 1 and m/^MEMBER/ ) {
			print $_;
		}

		# Once the serch keyworld is found, unmake on the section
		if ( $foundSection == 1 and m/$sqlKeyword/ ) {
			print $_;
			$foundSection = 0;
		}
			
	}

	close FH;
}


foreach $inputFile ( @fileList ) {
	doSearch $inputFile ;
	print "\n";
}





