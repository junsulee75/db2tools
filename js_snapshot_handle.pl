#!/usr/bin/perl


##########################################
 # program name : js_snapshot_handle.pl
 # Copyright © 2018 Jun Su Lee. All rights reserved.
 # Author : Jun Su Lee ( junsulee@au1.ibm.com )
 # Description : Creating files picking up interested application handle only
 #               Sometimes it's convenient doing this before grep etc.
 # Category : DB2
 # Usage : js_snapshot_handle.pl -f='app.snap*' -h='23156'
 # CreatDate
 # Revision History
 # - Oct.  11, 2018 : 
##########################################

use Getopt::Long;
use File::Basename;

my @fileList;
my $fileName;
my $appHdl;
my $foundHdl=0;
my $curHdl;
my $DEBUG = 0;

&usage if( scalar(@ARGV) < 2 );

GetOptions (
	'f=s' => \$fileName,
       'h=s' => \$appHdl,
) or die "Incorrect Usage ! ";

@fileList = glob($fileName);

sub getHandle {

	my ( $fn )  = @_ ;
	open FH, $fn or die;

	open OUT_FD, ">$appHdl.$fn.txt" or die("Faile to open $fn.$appHdl.txt.\n");

	while ( <FH> ) {
		if ( m/^Application handle\s+=\s(\d+)/ ) {
			$curHdl = $1;
			print "curHdl : $curHdl |  " if $DEBUG;
			print "appHdl : $appHdl |  \n" if $DEBUG;
			if ( $curHdl eq $appHdl ) {
				$foundHdl = 1;
				# To print first 2 lines for each handle when it matches
				print OUT_FD "            Application Snapshot\n" ;
				print OUT_FD "\n" ;
			}else {
				$foundHdl = 0;
			}
			print "foundHdl : $foundHdl |  \n" if $DEBUG;

		}
		if ( $foundHdl == 1) {

			## During printing the application handle, dont' print the next "Application Snapshot"
			if ( m/^\s+Application Snapshot/ ) {
				print OUT_FD "";			
			}
			else{ 
				 print OUT_FD $_ ;
			}
		}

	}

	close OUT_FD;


}


foreach my $inputFile (@fileList) {
	getHandle $inputFile;

	print "######## Processing $inputFile \n";

}

sub usage{
	$prog  = basename($0);
	print "Usage:\n";
	print "-f <filenames>\n";
	print "-h <application handle> -- 1:debug\n";
	print "-d <debug mode> -- 1:debug\n";
	print "example : \n";
	print "$prog -f 'app.snap.*.txt' -h '23156'\n";	

}

