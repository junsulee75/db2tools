#!/usr/bin/perl

##########################################
 # program name : js_locktimeout.pl
 # Copyright © 2018 Jun Su Lee. All rights reserved.
 # Modifier : Jun Su Lee ( junsulee@au1.ibm.com )
 # Description : Too many db2locktimeout files too check ? and wants to lock holder/waiters SQLs at a glance ? run this then. 
 # Category : DB2
 # Usage
 # Date : January 12, 2018
 # Revision History
 # Usage example
 #
#$ ls -tlr db2locktimeout* |wc -l
#     360
#
#$ js_locktimeout.pl |more
#
##########
#File = db2locktimeout.0.103697.2018-01-11-09-12-40
#
#Database:           SWTAPP
#   Lock Specifics: (obj={2;266}, rid=d(0;81;10), x000000000051000A)
#        Requestor
#                   Application Handle:      [0-13860]
#                   Application ID:          xx
#                   Application Name:        xx
#
#                [ 0 ] SELECT xx
#
#        Owner
#                   Application Handle:      [0-13859]
#                   Application ID:          xx
#                   Application Name:        xx
#
#                   List of Active SQL Statements:   
#
#                [ 1 ] SELECT xx
##########
#File = db2locktimeout.0.105018.2018-01-10-13-39-32
#..<snippet>..



##########################################


sub dowork {
	my ( $fn ) = @_ ;
	my $cnt = 0 ;
	open FH , $fn or die ;
	print "#########\nFile = $fn\n\n" ;
	while ( <FH> ) {



		if ( m/^Database/ ) {	
			print $_;
		}


		if ( m/Lock Specifics/ ) {	
			print $_;
		}

		if ( m/Lock Requestor/ ) {
			print "\tRequestor\n" ;
		}

		if ( m/Lock Owner/ ) {
			print "\n\tOwner\n" ;
		}

		if ( m/Statement:\s+(.*)/ ) {
			$stmt = $1 ;
			print "\t\t[ $cnt ] $stmt\n" ;
			$cnt++ ;
		}

		if ( m/List of Active/ ) {
			print "\t\t$_\n" ;
		}
		
		if ( m/Application ID/ ) {
			print "\t\t$_" ;
		}
		
		if ( m/Application Handle/ ) {
			print "\t\t$_" ;
		}
	
		if ( m/Application Name/ ) {
			print "\t\t$_\n" ;
		}

	}
	close FH ;
}


foreach $fn ( glob "db2locktimeout*" ) {
#foreach $fn ( glob "db2locktimeout.0.104761.2018-01-10-13-39-32" ) {
	dowork $fn ;
	print "\n" ;
}
