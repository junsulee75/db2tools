#!/usr/bin/perl

##########################################
 # program name : js_chk_dart.pl
 # Copyright © 2018 Jun Su Lee. All rights reserved.
 # Modifier : Jun Su Lee ( junsulee@au1.ibm.com )
 # Description : Check db2dart output and list up corrupted table/index names. 
 #               When db2dart file is big and there are many corruptions, you may want to list up the currupted data/index object data/index object quickly
 # Category : DB2
 # Usage
 # Date : January 12, 2018
 # Revision History
 # Todo : Emp page check
 # 2018-12-04 : pool / obj was swapped. So changed it accordingly
 # 2018-10-11 : Fixed the issue mixing up the result between objects. Set variables as global and reset them every table inspection start. Input by Shashank.
 # 2018-05-02 : Changed to case insensitive 'Error:' to 'Error/i'
 #
 #
 #
 # Usage example : 
# # $ js_chk_dart.pl -i='DB2DART.RPT*'
# 
################ Checking the file ############# : DB2DART.RPT
#
#Tabname =  | Data pool = 103 , Obj = 1 (1) | Index = 103 , Obj = 1 (1)
#Tabname =  | Data pool = 275 , Obj = 1 (1) | Index = 275 , Obj = 1 (1)
#Tabname =  | Data pool = 226 , Obj = 2 (1) | Index = 226 , Obj = 2 (1)
#Tabname =  | Data pool = 4 , Obj = 22 (1) | Index = 4 , Obj = 22 (1)


###########################################

use Getopt::Long;

my $DEBUG=0;

my @fileList; ## Input file name list
my $fileName; ## Input file name : command line option

## put the following as global variable
my $see_error=0;
my $dataerror=0;
my $indexerror=0;
my $doing="";
my $tabname="";
my $datapool="";
my $datatabid="";
my $idxpool="";
my $idxtabid="";


## js_chk_dart.pl -i='<db2dart output file>'
GetOptions (
	'i=s' => \$fileName,	# Filename to read
	"debug=i" => \$DEBUG      
)
or die "Incorrect Usage ! \n";


# get file list
@fileList = glob($fileName);


print "\n";
print " NOTE : \n";
print "   1. Tabname will be shown since Db2 V10.5 db2dart output. \n";
print "   2. This script only reports object that has 'Error/error' on its Data or Index part. \n";
print "   3. '1' means having Error. '0' means no Error. \n";
print "   4. This script does not check 'extent map' error for now as it gives false alarm sometime. \n";
print "\n";



sub doChkDart { 


	my ( $fn ) = @_ ;

	open FH, $fn or die ;
	print " \n############### Checking the file ############# : $fn \n\n";


	#open FH , "OVIHPVS.RPT_primary" or die ;
	
	while ( <FH> ) {

		# Depending on version, table name may not come up on this pattern of lines.
		# i.e) V10.5 shows table name, V9.7 does not.
		#
		# When starting each 'Table inspection start', reset all variable not to be mixed up between multiple objects.
		# Sometimes it happened.	
		if ( m/Table inspection start: (.*)$/ ) {
			$see_error = 0 ;
			$dataerror = 0 ;
			$indexerr = 0 ;
			$doing = "" ;

			$tabname = $1 ;
			# print "TAB = $tabname\n" ;
			$datapool="";
			$datatabid="";
			$idxpool="";
			$idxtabid="";

			next ;
		}
	
		if ( m/Data inspection.*: (\d+)\s+.*: (\d+)/ ) {
			$doing = "DATA" ;
			$datapool = $2 ;
			$datatabid = $1 ;
			print "Data Pool = $datapool , ID = $datatabid\n" if $DEBUG;
			next ;
		}
	
		if ( m/Index inspection.*: (\d+)\s+.*: (\d+)/ ) {
			$doing = "INDEX" ;
			$idxpool = $2 ;
			$idxtabid = $1 ;
			print "Index Pool = $idxpool , ID = $idxtabid\n" if $DEBUG;
			next ;
		}
	
		#if ( m/Error:/ ) {
		if ( m/Error/i ) {
			$see_error = 1 ;
			$dataerror = 1 if ( $doing eq "DATA" ) ;
			$indexerr = 1 if ( $doing eq "INDEX" ) ;
			while ( <FH> ) {
				last if ( m/inspection.*end/ ) ;
			}
		}
	
		if ( m/Table inspection end/ ) {
			if ( $see_error == 1 ) {
				print "Tabname = $tabname | Data pool = $datapool , Obj = $datatabid ($dataerror) | Index = $idxpool , Obj = $idxtabid ($indexerr)\n" ;
	
			}
		}
	}
	close FH ;

}



foreach my $inputFile ( @fileList ) {

	doChkDart $inputFile;

	print "\n";
}

