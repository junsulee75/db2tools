#!/usr/bin/perl


##########################################
 # program name : js_split_snapshot.pl
 # Copyright © 2018 Jun Su Lee. All rights reserved.
 # Author : Jun Su Lee ( junsulee@au1.ibm.com )
 # Description : Split a file that has multiple snapshot type into separate files.
 #               Sometimes I need to do this to run a script that needs same kind of snapshot input.
 # Category : DB2
 # Usage : js_split_snapshot.pl -i='XXXX.snapshot.*'
 # CreatDate
 # Revision History
 # - Jan.  25, 2018 : Change to use File handle pointer. Tips from Chee Hoe.
##########################################


use Getopt::Long;

my $DEBUG=1;

my @fileList; ## Input file name list
my $fileName; ## Input file name : command line option


## js_split_snapshot.pl -i='MPSBODB.snapshot.*'
GetOptions (
	'i=s' => \$fileName,	# Filename to read
)
or die "Incorrect Usage ! \n";

# get file list
@fileList = glob($fileName);


sub doSplitWork {

	my ( $fn ) = @_ ;

	open FH, $fn or die ;
	print " \n############### Processing file : $fn \n\n";

		my $fileFlag = 1;
		my $fileHandle;

		open DB_FD, ">$fn.dbsnap.txt" or die("Fail to open $fn.dbsnap.txt\n");
		open APP_FD, ">$fn.appsnap.txt" or die("Fail to open $fn.appsnap.txt\n");
		open BP_FD, ">$fn.bpsnap.txt" or die("Fail to open $fn.bpsnap.txt.\n");
		open DYN_FD, ">$fn.dynsnap.txt" or die("Fail to open $fn.dynsnap.txt.\n");
		open TABLE_FD, ">$fn.tablesnap.txt" or die("Fail to open $fn.tablesnap.txt.\n");
		open LOCK_FD, ">$fn.locksnap.txt" or die("Fail to open $fn.locksnap.txt.\n");
		open TBS_FD, ">$fn.tbssnap.txt" or die("Fail to open $fn.tbssnap.txt.\n");
		open DBM_FD, ">$fn.dbmsnap.txt" or die("Fail to open $fn.dbmsnap.txt.\n");

		while ( <FH> ) {

			$fileHandle = *DB_FD if ( m/Database Snapshot/ ) ;
			$fileHandle = *APP_FD if ( m/Application Snapshot/ ) ; 
			$fileHandle = *BP_FD if ( m/Bufferpool Snapshot/ ) ;
			$fileHandle = *DYN_FD if ( m/Dynamic SQL Snapshot Result/ ) ;
			$fileHandle = *TABLE_FD  if ( m/Table Snapshot/ ) ; 
			$fileHandle = *LOCK_FD if ( m/Database Lock Snapshot/ ) ;
			$fileHandle = *TBS_FD if ( m/Tablespace Snapshot/ ) ;
			$fileHandle = *DBM_FD if ( m/Database Manager Snapshot/ ) ;

			print $fileHandle $_ if (defined $fileHandle );

		}

		close DB_FD;
		close APP_FD;
		close BP_FD;
		close DYN_FD;
		close TABLE_FD;
		close LOCK_FD;
		close TBS_FD;
		close DBM_FD;

}


foreach my $inputFile ( @fileList ) {

	doSplitWork $inputFile;

	print "\n";
}


### my personal note : what to do next
#while ( <FH> ) {
#
#            $handle = *DB_FD if ( m/Database Snapshot/ )  ;
#            $handle = *APP_FD if ( m/Application Snapshot/ ) ;
#            $handle = *BP_FD if ( m/Bufferpool Snapshot/ ) ;
#            $handle = *DYN_FD if ( m/Dynamic SQL Snapshot Result/ ) ;
#            $handle = *TABLE_FD if ( m/Table Snapshot/ ) ;
#            $handle = *LOCK_FD if ( m/Database Lock Snapshot/ ) ;
#            $handle = *TBS_FD if ( m/Tablespace Snapshot/ ) ;
#            $handle = *DBM_FD if ( m/Database Manager Snapshot/ ) ;
#
#            print $handle $_ if ( defined $handle ) ;
#
#        } 


#print $handle $_ if ( defined $handle ) ;   <=== first line is blank.  so $handle is NULL ... so must do this test. 
#
#11:41:30 AM:   
#
#11:41:50 AM: otherwise .. after <FH> ,  do this to skip blank lines 
#
#11:41:56 AM: next if ( m/^$/ ) ; 
