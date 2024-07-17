#!/usr/bin/perl

##########################################
 # program name : js_chk_latch.pl
 # Copyright © 2018 Jun Su Lee. All rights reserved.
 # Modifier : Jun Su Lee ( junsulee@au1.ibm.com )
 # Description : Check db2pd -latch output and count latch waits for each holder and latch name
 #               Sometimes necessary when the db2pd -latch output is big and want to get a rough look at once
 # Category : DB2
 # Usage
 # 1. print all
 #    js_chk_latch.pl -i='<db2pd -latch output files>'
 # 2. Printing only if there are waiters
 #    js_chk_latch.pl -i='<db2pd -latch output files>' -w=1  
 # Date : Feb. 16, 2018
 # Revision History
 # Feb 28, 2018 : Commented this line "$cnt = 0 if ( $tmpWaiter == 0 );" as it gives 0 waiter count in the output always

 ### Usage example : 

#$ js_chk_latch.pl -i='db2pd_latches.out' -w=1
#
# ######## Checking the file : db2pd_latches.out 
#
#Holder EDU ID : 307160, # of waiters : 671, Latch name : SQLO_LT_SQLB_HASH_BUCKET_GROUP_HEADER__groupLatch
#Holder EDU ID : 342612, # of waiters : 671, Latch name : SQLO_LT_SQLB_HASH_BUCKET_GROUP_HEADER__groupLatch
#Holder EDU ID : 419652, # of waiters : 671, Latch name : SQLO_LT_SQLB_HASH_BUCKET_GROUP_HEADER__groupLatch
#Holder EDU ID : 0, # of waiters : 1, Latch name : SQLO_LT_SQLB_BPD__bpdLatch_SX
#Holder EDU ID : 272788, # of waiters : 676, Latch name : SQLO_LT_SQLB_HASH_BUCKET_GROUP_HEADER__groupLatch
#Holder EDU ID : 376069, # of waiters : 676, Latch name : SQLO_LT_SQLB_HASH_BUCKET_GROUP_HEADER__groupLatch
#...snippet..


##########################################


### Input file Pattern
#0x0A000202B5B75280 307160     306427     sqlbufix.C           1034       SQLO_LT_SQLB_HASH_BUCKET_GROUP_HEADER__groupLatch 1         
#0x0A000202B5B75280 307160     216251     sqlbufix.C           1034       SQLO_LT_SQLB_HASH_BUCKET_GROUP_HEADER__groupLatch 1         
#0x0A000202B5B75280 307160     219848     sqlbufix.C           1034       SQLO_LT_SQLB_HASH_BUCKET_GROUP_HEADER__groupLatch 1         
#0x0A000202B5B75280 307160     224987     sqlbufix.C           1034       SQLO_LT_SQLB_HASH_BUCKET_GROUP_HEADER__groupLatch 1         
#0x0A000202B5B75280 307160     226786     sqlbufix.C           1034       SQLO_LT_SQLB_HASH_BUCKET_GROUP_HEADER__groupLatch 1   
#0x0A000202B5B75280 342612     306427     /view/db2_v105fp8_aix64_s160901_special_35869/vbs/engn/sqb/inc/sqlbslat.h 1343       SQLO_LT_SQLB_HASH_BUCKET_GROUP_HEADER__groupLatch 1         
#0x0A000202B5B75280 342612     216251     /view/db2_v105fp8_aix64_s160901_special_35869/vbs/engn/sqb/inc/sqlbslat.h 1343       SQLO_LT_SQLB_HASH_BUCKET_GROUP_HEADER__groupLatch 1         



use Getopt::Long;

my $DEBUG=0;
my $waiterOnly=0;

my @fileList ;
my $filename ;

 
GetOptions (
	'i=s' => \$filename,
	"debug=i" => \$DEBUG, 
	"w=i" => \$waiterOnly   
)
or die "Incorrect Usage ! \n";

@filelist = glob($filename);

sub doChkLatch {

	my ( $fn ) = @_ ;
	open FH, $fn or die ;
	print "\n ######## Checking the file : $fn \n\n";

	$holder = "";
	$waiter = "";
	$latch  = "";
	$cnt  = 1;
	$lineNum = 0; ## Number of line matching the given pattern. To skip printing the first line.

	while ( <FH> )	{

		#if ( m/^0x.*?\s(\d+)\s/ ) { ## holder
		#if ( m/^0x.*?\s(\d+).*?\s(\d+)/ ) { ## Holder, Waiter
		#if ( m/^0x.*?\s(\d+).*?\s(\d+).*?(\d+)/ ) { ## Holder, waiter, LOC

		if ( m/^0x.*?\s(\d+).*?\s(\d+).*?\d+\s+(.*[A-Za-z])?\s/ ) { ## Holder, waiter, Latchname

		#if ( m/^0x.*?\s(\d+).*?\s(\d+).*?\d+\s+(.*\w)?\s/ ) { ## Holder, waiter, Latchname '\w' print the end column too

			$lineNum++; ## adding count for the matching line

			# save the reading values into variables. Those will be lost once used.
			$tmpHolder = $1;
			$tmpWaiter	= $2;
			$tmpLatch  = $3;

			#print "|$tmpHolder| |$tmpWaiter| |$tmpLatch|\n" if $DEBUG;	

			# If holder id and latch name is same as the previous line, 
			if ( ($tmpHolder == $holder) && ($tmpLatch eq $latch) ) {
				$cnt++;
			}else{ # If different, print the current result for the same Holder ID and latch name
				# The very first line will come to here.
				if ( $lineNum > 1 ) { # but skipping the first line as no previous line to compare

					# if waiter EDU is 0, then that means no waiter with this, setting cnt to 0 before printing
					### Commenting the next line as it give 0 always
					#$cnt = 0 if ( $tmpWaiter == 0 );
				
					# If waierOnly is 1, only print EDUs that have waiters.	
					if ($cnt == 0 ) { 
						if( $waiterOnly == 0 ) {
							print "Holder EDU ID : $holder, # of waiters : $cnt, Latch name : $latch\n";
						}
					}else{
						print "Holder EDU ID : $holder, # of waiters : $cnt, Latch name : $latch\n";
					}
				}
			
				# Change values to new value to compare on the next loop	
				$holder = $tmpHolder;
				$waiter = $tmpWaiter;
				$latch  = $tmpLatch;
			
				if ( $waiter == 0 ) {
					 $cnt = 0;
				} else {
					$cnt = 1;
				} # If new one and that is not 0, set cnt as 1 as starting count, on the next loop, that will be reset to 0 if no waiters
			}
			print "|$tmpHolder| |$tmpWaiter| |$tmpLatch|\n" if $DEBUG;	
		}
	
	}

	close FH;
}


foreach my $inputFile ( @filelist ) {

	doChkLatch $inputFile;

	print "\n";

}
