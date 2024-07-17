#!/usr/bin/perl

use Getopt::Long;
use File::Basename;

my @fileList; ## Input file name list
my $fileName; ## Input file name : command line option

usage() if ( @ARGV == 0 );

GetOptions(
	    "filename=s" => \$fileName,      
	    "debug=i" => \$DEBUG      
	    ) ;

@fileList = glob($fileName);

sub dowork {
	my ( $fn ) = @_ ;
	my $cnt = 0 ;

	my $curAct;  ## To check only current activity statement
	open FH , $fn or die ;
	print "#########\nFile = $fn\n\n" ;
	while ( <FH> ) {


		if ( m/^Event Type/ ) {	
			print "############################## \n";
			print $_;
		}


		if ( m/^Event Timestamp/ ) {	
			print $_;
		}
		if ( m/^Current Activities of Participant No/ ) {	
			print $_;

			$curAct = 1;

		}

		if ( m/^Stmt text/ ) {	
			if ($curAct == 1) {

				print $_;
			}
		}
		if ( m/^Past Activities of Participant No/ ) {
			$curAct = 0;
		}


	}
	close FH ;
}


foreach my $inputFile (@fileList) {
#foreach $fn ( glob "lockreport*" ) {
#foreach $fn ( glob "18-01-10-13-39-32" ) {
	dowork $inputFile ;
	print "\n" ;
}


sub usage{

	$prog  = basename($0);
	
	print <<EOF;
	$prog <options>
	-f : File names
	-d : debug mode ( 0 : disable, 1 : Enable )
	Example)
	$prog -f 'lockreport*' 
EOF
    exit;

}
