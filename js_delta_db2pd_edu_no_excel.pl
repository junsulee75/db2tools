#!/usr/bin/perl


##########################################
 # program name : js_delta_db2pd_edu_no_excel.pl
 # Copyright ? 2017 Jun Su Lee. All rights reserved.
 # Author : Jun Su Lee ( junsulee@au1.ibm.com )
 # Description : Calculates Delta CPU time of EDUs from multiple 'db2pd -edus' outputs 
 #               There is other version 'js_delta_db2pd_edu.pl' that produces excel file as well but that version will need related excel perl package to be installed.
 # Note : 
 #  - I know we can do the same with 'db2pd -edus interval=x top=x'
 #    But the reality is we don't always get such flavor of data. (ex. files being collected with 'db2fodc -hang full')
 #    I made this script seeing one of my peer took hours to calculate db2pd -edu delta CPU time manually among many iteration outputs
 #    This script is just for doing that and probably reducing investigation time more than hours

 #    
 # Category : DB2 support
 # Usage
 # js_delta_db2pd_edu.pl -f='db2pd.edu*'
 # Date : Nov.10, 2017
 # Revision History
 # - Nov. 10, 2017 : 
 # - Sep. 09, 2018 : deltaVal decimal processing
 # - Sep. 10, 2018 : Added Excel output logic
 # - Sep. 26, 2018 : Added reset logic curVal and preVal.
 # - Sep. 26, 2018 : Added USER CPU / SYS CPU section seperately
 # - Sep. 26, 2018 : Created new file 'db2_delta_db2pd_edu_no_excel.pl' for the user who want to run as it is without installing excel package
 #  - Nov. 03, 2018 : Found long name EDU pattern. So Changed display format
 #  Usage Example : 
 # 
#$ ls db2pd.edus.*
#db2pd.edus.20171024_192223	db2pd.edus.20171024_192333	db2pd.edus.20171024_192506
#db2pd.edus.20171024_192255	db2pd.edus.20171024_192415	db2pd.edus.20171024_192608
#
#$ js_delta_db2pd_edu.pl -f='db2pd.edus.*'
#.. <snippet>..
#T1 : 2017-10-24-19.22.24.718886
# T2 : 2017-10-24-19.22.56.584887
# T3 : 2017-10-24-19.23.33.778791
# T4 : 2017-10-24-19.24.16.162014
# T5 : 2017-10-24-19.25.07.624447
# T6 : 2017-10-24-19.26.09.510959
# 
#*** Total CPU (USER+SYS) delta value 
#(EDUID/NAME)/Time 	T2	T3	T4	T5	T6	
#54/db2agent	 	0.25 	1.26 	1.25 	1.25 	2.05 	
#53/db2agnta	 	0.00 	0.00 	0.01 	0.00 	0.00 	
#52/db2agnta	 	0.00 	0.01 	0.00 	0.01 	0.00 	
#..<snippet>..
#
#*** USER CPU delta value 
#(EDUID/NAME)/Time 	T2	T3	T4	T5	T6	
#54/db2agent	 	0.22 	0.99 	0.95 	1.00 	1.66 	
#53/db2agnta	 	0.00 	0.00 	0.01 	0.00 	0.00 	
#52/db2agnta	 	0.00 	0.01 	0.00 	0.01 	0.00 
#..<snippet>..
#
#*** SYS CPU delta value 
#(EDUID/NAME)/Time 	T2	T3	T4	T5	T6	
#54/db2agent	 	0.03 	0.27 	0.30 	0.25 	0.39 	
#53/db2agnta	 	0.00 	0.00 	0.00 	0.00 	0.00 	
#52/db2agnta	 	0.00 	0.00 	0.00 	0.00 	0.00 
#..<snippet>..

##########################################

### Format

#Database Member 0 -- Active -- Up 1 days 11:40:29 -- Date 2017-08-05-10.30.57.731828
#
#List of all EDUs for database member 0
#
#db2sysc PID: 39780576
#db2wdog PID: 38469756
#db2acd  PID: 43843604
#
#
#EDU ID    TID                  Kernel TID           EDU Name                               USR (s)         SYS (s) 
#========================================================================================================================================
#10955     10955                100335619            db2agntdp (SAMPLE  ) 0                 1.180120     0.294553
#10698     10698                5636521              db2agntdp (SAMPLE  ) 0                 4.344464     1.246434
#10440     10440                2097433              db2evmgi (DB2DETAILDEADLOCK) 0         0.048993     0.048647
#10183     10183                15532467             db2pcsd (SAMPLE) 0                     2.963820     3.269419
#12        140281986934528      36753                db2thcln 0                             0.000000     0.000000
#11        140281991128832      36752                db2alarm 0                             0.400000     0.070000
#1         140281731081984      36751                db2sysc 0                              0.060000     0.100000
#^^^^^     ^^^^^                ^^^^^^^^^            ^^^^^^^^                               ^^^^^^^^     ^^^^^^^^ 



use Getopt::Long;
use File::Basename;

## when necessary. You can uncomment the following two lines if you have installed the module. 
##JS use Excel::Writer::XLSX; # For excel
##JS use Data::Dumper ;       # only for debugging, comment this when giving to users who don't have this module

my $fileName;
my @fileList; # filelist from user command input parameter

my $DEBUG = 0;

my @Parsed; # All values array of hash that parsed db2pd -edu files. 
my $fileTimestamp;

my @parseFileList; # file list to parse. fileName, $fileTimeStamp
my @sorted_parseFileList; # sorted filelist
my @eduUniqList;

my $curVal; # current Value
my $preVal; # previous Value
my $deltaVal; # delta Value

&usage if( scalar(@ARGV) < 1 ) ;

### -filename='db2pd.edu*' -debug=1
### Or -d=1 -f='db2pd.edus.20171024_1922*'
GetOptions(
	    "start=s" => \$StartTime,
	    "end=s" => \$EndTime, 
	    "filename=s" => \$fileName,      
	    "debug=i" => \$DEBUG      
	    )
or die "Incorrect usage ! \n";

#print "1.filename : $fileName \n";
@fileList = glob($fileName);

sub doParseEduFile {

	my ( $fn ) = @_ ;
	open FH, $fn or die "can't open the file $fn \n\n";

	print "\n ######### Reading $fn \n\n"  ;

	while ( <FH> ) {
		#print "$_" if $DEBUG;

		## get timestamp of db2pd -edu output file. This pattern will come only once per file.
		#if ( m/^Database Member\s.+Date\s(.+)$/ ) {
		if ( m/^Database\s.+Date\s(.+)$/ ) {
			$fileTimeStamp = $1;
			push @parseFileList, { fileName => $fn, fileTimeStamp => $fileTimeStamp };
		}

		### To make it into one pattern, regular expression will be too complicated
		### Therefore, from various tests, I made this as two patterns.
		### pattern #1
		#if ( m/([^ ]+) */ ) {  ## First column 
		#if ( m/^(\d+) *(\d+) */ ) { ## EDU id, TID
		#if ( m/^(\d+) *(\d+) *(\d+) *(\w+) */ ) { ## EDU id, TID, Kernel TID, EDU Name
		#if ( m/^(\d+) *(\d+) *(\d+) *(\w+) .+ (\d+.\d+) */ ) { ## EDU id, TID, Kernel TID, EDU Name, SYS
		#if ( m/^(\d+) *(\d+) *(\d+) *(\w+) .+ (\d+.\d+) .+/ ) { ## EDU id, TID, Kernel TID, EDU Name, USR
		#if ( m/^(\d+) *(\d+) *(\d+) *(\w+) .+ (\d+.\d+)\s*(\d+.\d+) / ) { ## EDU id, TID, Kernel TID, EDU Name, USR, SYS : Failed
		if ( m/^(\d+)\s+(\d+)\s+(\d+)\s+(\w+)\s.+\s+(\d+\.\d\d\d\d\d\d)\s+(\d+\.\d\d\d\d\d\d)/ ) { ## EDU id, TID, Kernel TID, EDU Name, USR, SYS : Success. But does not match some lines. 
		#       ^^^^^   ^^^^^   ^^^^^   ^^^^^
		#       EDUID   TID     KTID    NAME


			# To compute total CPU and add
			$tmpUserCPU = $5;
			$tmpSysCPU  = $6;
			$tmpTotCPU  = $tmpUserCPU+$tmpSysCPU;

			#When reading as it is
			#push @Parsed, { fileName => $fn, fileTimeStamp => $fileTimeStamp, eduID => $1, TID => $2, kernelTID => $3, eduName => $4, usrCPU => $5, sysCPU => $6 };
			
			push @Parsed, { fileName => $fn, fileTimeStamp => $fileTimeStamp, eduID => $1, TID => $2, kernelTID => $3, eduName => $4, usrCPU => $tmpUserCPU, sysCPU => $tmpSysCPU, totCPU => $tmpTotCPU };
		} 

		### pattern #2
## db2lfr.0 : <== in case we have such pattern, it does not match 1st if statement pattern.
#27        140281924019968      36803                db2lfr.0 (AIWDB) 0                     0.000000     0.000000

		elsif (  m/^(\d+)\s+(\d+)\s+(\d+)\s+(\w+.\d)\s.+\s+(\d+\.\d\d\d\d\d\d)\s+(\d+\.\d\d\d\d\d\d)/ ) { ### 
		#	                            ^^^^^^^

			# To compute total CPU and add
			$tmpUserCPU = $5;
			$tmpSysCPU  = $6;
			$tmpTotCPU  = $tmpUserCPU+$tmpSysCPU;

			#push @Parsed, { fineName => $fn, eduID => $1, TID => $2, kernelTID => $3, eduName => $4, usrCPU => $5, sysCPU => $6 };
			push @Parsed, { fileName => $fn, fileTimeStamp => $fileTimeStamp, eduID => $1, TID => $2, kernelTID => $3, eduName => $4, usrCPU => $tmpUserCPU, sysCPU => $tmpSysCPU, totCPU => $tmpTotCPU };
		}
		else {
			print "Non matched Line ==========>  $_" if $DEBUG;
		}
	}

	close FH;
}


### Parsing files and make filename/timestamp list
foreach my $inputFile (@fileList) {

	doParseEduFile $inputFile;

}

### sort the file list by timestamp
@parseFileList = sort { $a->{fileTimeStamp} cmp $b->{fileTimeStamp} } @parseFileList; 


### Check the parsed data (for Debug)
##JS print "=======================================================> Parsed\n" if $DEBUG;
##JS print Data::Dumper->Dump ( [ @Parsed ], [ 'Parsed' ] ) if $DEBUG ;
##JS print "=======================================================> parseFileList\n" if $DEBUG;
##JS print Data::Dumper->Dump ( [ @parseFileList ], [ 'parseFileList' ] ) if $DEBUG ;

### Create Excel output file
##JS my $excelOutput = Excel::Writer::XLSX->new( 'js_delta_db2pd_edu_output.xlsx' ); ### Excel
#$excelOutput->set_size(1200, 800); ## Excel file window size : not working for excel of mac
#Add 3 worksheets
##JS$worksheet1 = $excelOutput->add_worksheet('TOTAL (USER+SYS)'); ## Excel
##JS$worksheet2 = $excelOutput->add_worksheet('USER'); ## Excel
##JS$worksheet3 = $excelOutput->add_worksheet('SYS'); ## Excel
##JS
##JS
##JS### print 1st line with time stamp
##JS#print "Total CPU (USER+SYS) delta value \n"; ## plain output
##JS$worksheet1->write( 'A1', 'Total CPU (USER+SYS) delta value' ); ## Excel
##JS$worksheet1->set_column(0,0,30); ## Excel : 1st column width
##JS$worksheet2->write( 'A1', 'Total CPU (USER) delta value' ); ## Excel
##JS$worksheet2->set_column(0,0,30); ## Excel : 1st column width
##JS$worksheet3->write( 'A1', 'Total CPU (SYS) delta value' ); ## Excel
##JS$worksheet3->set_column(0,0,30); ## Excel : 1st column width
##JS
##JS### 2nd line, 1st column
##JS$worksheet1->write(1,0, '(EDUID/EDU NAME) / FileStamp ' ); ## Excel
##JS$worksheet2->write(1,0, '(EDUID/EDU NAME) / FileStamp ' ); ## Excel
##JS$worksheet3->write(1,0, '(EDUID/EDU NAME) / FileStamp ' ); ## Excel


my $cnt1=1; ## will be number of files/filestamps + 1
### 2nd line, input filestamp from 2nd column
for my $p (@parseFileList) {
	print "T$cnt1 : $p->{fileTimeStamp}\n "; ## plain output
##JS	$worksheet1->write(1,$cnt1, $p->{fileTimeStamp}  ); ## Excel
##JS	$worksheet1->set_column(1,$cnt1,26); ## Excel : 2nd column width
##JS	$worksheet2->write(1,$cnt1, $p->{fileTimeStamp}  ); ## Excel
##JS	$worksheet2->set_column(1,$cnt1,26); ## Excel : 2nd column width
##JS	$worksheet2->write(1,$cnt1, $p->{fileTimeStamp}  ); ## Excel
##JS	$worksheet2->set_column(1,$cnt1,26); ## Excel : 2nd column width
	$cnt1++;
}
print "\n"; 

##################################################################
####### Print USER CPU part on terminal and on 2nd Excel worksheet 
##################################################################
print "*** Total CPU (USER+SYS) delta value \n"; ## plain output
#print "\(EDUID\/NAME)\/Time \t"; ## plain output
#printf "%30s","\(EDUID\/NAME)\/Time "; ## plain output
printf "%10s","EDUID"; ## plain output
#print " \/ "; ## plain output
printf "%20s","EDUNAME"; ## plain output

### print timestamp line on terminal output, but printing from 2nd timestamp as 1st one does not have delta
for ($tmpCnt = 2; $tmpCnt < $cnt1; $tmpCnt++) {
		#print "T$tmpCnt\t";
	#printf "%16s","T$tmpCnt";
	printf "%15s","T";
	printf "%1d","$tmpCnt";

}

print "\n"; 

### Create the array of hash with eduID and eduName, then make it unique.
### I will go though parsedList with this key
for my $p (@Parsed) {

	push @eduUniqList, { eduID => $p->{eduID}, eduName => $p->{eduName} };
}
#print "==========> before unique processing \n";
#print Data::Dumper->Dump ( [ @eduUniqList ], [ 'eduUnitList' ] ) if $DEBUG ;
## Unique processing by eduID
my %seen;
@eduUniqList = grep { ! $seen{$_->{eduID} }++ } @eduUniqList;
##JS print "========================================================> after unique processing of eduUniqList \n" if $DEBUG;
##JS print Data::Dumper->Dump ( [ @eduUniqList ], [ 'eduUnitList' ] ) if $DEBUG ; 

my $cnt2=2;
## for each edu id, print the delta value of Total CPU.
for my $p1 (@eduUniqList){
	#print "$p1->{eduID}\/$p1->{eduName}\t "; # print 1st column with eduID/eduName
	#printf "%30s","$p1->{eduID} \/ $p1->{eduName} "; # print 1st column with eduID/eduName
	printf "%10d","$p1->{eduID}"; # print 1st column with eduID/eduName
	#print " \/ "; # print 1st column with eduID/eduName
	printf "%20s","$p1->{eduName}"; # print 1st column with eduID/eduName
	#print "\t"; # Skipping printing 2nd column as there will be no delta value for 1st timestamp

## JS	$worksheet1->write($cnt2,0, "$p1->{eduID}/$p1->{eduName}"  ); ## Excel

	# loop from the second file	
	for ($loop_index = 1;$loop_index <= $#parseFileList; $loop_index++) {
		#print "$parseFileList[$loop_index]->{fileTimeStamp}\t ";

		# Get the totCPU of the current timestamp
		for my $p3 (@Parsed) {
			if ( $p3->{eduID} == $p1->{eduID} and $p3->{fileTimeStamp} eq $parseFileList[$loop_index]->{fileTimeStamp} ){
				#print "$p3->{eduID}/$p1->{eduID}\t"; # To debug if eduID is same
				$curVal = $p3->{totCPU};
				#print "$curVal\t";
			}
		}
		# Get the totCPU of the previous timestamp
		for my $p3 (@Parsed) {
			if ( $p3->{eduID} == $p1->{eduID} and $p3->{fileTimeStamp} eq $parseFileList[$loop_index-1]->{fileTimeStamp} ){
				#print "$p3->{eduID}/$p1->{eduID}\t"; # To debug if eduID is same
				$preVal = $p3->{totCPU};
				#print "$preVal\t";
			}
		}

		$deltaVal = $curVal - $preVal;
		#print "$deltaVal ";
		#$deltaVal=sprintf ("%.2f", $deltaVal);
		#print "$deltaVal ";
		printf "%15.2f",$deltaVal;
		print "($curVal - $preVal)" if $DEBUG;
		#print "\t";

## JS		$worksheet1->write($cnt2,$loop_index+1, $deltaVal  ); ## Excel

		## These variables are global. So I should reset these before the next loop. Otherwise same value will come up in case there is no value on the loop turn
		$curVal = 0;$preVal=0; 
		
	}
	$cnt2++; ## Excel, the next row number position
	print "\n";
}

##################################################################
####### Print USER CPU part on terminal and on 2nd Excel worksheet 
##################################################################
print "\n\n*** USER CPU delta value \n"; ## plain output
#print "\(EDUID\/NAME)\/Time \t"; ## plain output
#printf "%30s","\(EDUID\/NAME)\/Time "; ## plain output
printf "%10s","EDUID"; ## plain output
#print " \/ "; ## plain output
printf "%20s","EDUNAME"; ## plain output


### print timestamp line on terminal output, but printing from 2nd timestamp as 1st one does not have delta
for ($tmpCnt = 2; $tmpCnt < $cnt1; $tmpCnt++) {
		#print "T$tmpCnt\t";
	#printf "%16s","T$tmpCnt";
	printf "%15s","T";
	printf "%1d","$tmpCnt";

}

print "\n";
my $cnt2=2;
## for each edu id, print the delta value of Total CPU.
for my $p1 (@eduUniqList){
	#print "$p1->{eduID}\/$p1->{eduName}\t "; # print 1st column with eduID/eduName
	#printf "%30s","$p1->{eduID} \/ $p1->{eduName} "; # print 1st column with eduID/eduName
	printf "%10d","$p1->{eduID}"; # print 1st column with eduID/eduName
	#print " \/ "; # print 1st column with eduID/eduName
	printf "%20s","$p1->{eduName}"; # print 1st column with eduID/eduName
	#print "\t"; # Skipping printing 2nd column as there will be no delta value for 1st timestamp

## JS	$worksheet2->write($cnt2,0, "$p1->{eduID}/$p1->{eduName}"  ); ## Excel

	# loop from the second file	
	for ($loop_index = 1;$loop_index <= $#parseFileList; $loop_index++) {
		#print "$parseFileList[$loop_index]->{fileTimeStamp}\t ";

		# Get the totCPU of the current timestamp
		for my $p3 (@Parsed) {
			if ( $p3->{eduID} == $p1->{eduID} and $p3->{fileTimeStamp} eq $parseFileList[$loop_index]->{fileTimeStamp} ){
				#print "$p3->{eduID}/$p1->{eduID}\t"; # To debug if eduID is same
				$curVal = $p3->{usrCPU};
				#print "$curVal\t";
			}
		}
		# Get the totCPU of the previous timestamp
		for my $p3 (@Parsed) {
			if ( $p3->{eduID} == $p1->{eduID} and $p3->{fileTimeStamp} eq $parseFileList[$loop_index-1]->{fileTimeStamp} ){
				#print "$p3->{eduID}/$p1->{eduID}\t"; # To debug if eduID is same
				$preVal = $p3->{usrCPU};
				#print "$preVal\t";
			}
		}

		$deltaVal = $curVal - $preVal;
		#print "$deltaVal ";
		#$deltaVal=sprintf ("%.2f", $deltaVal);
		#print "$deltaVal ";
		printf "%15.2f",$deltaVal;
		print "($curVal - $preVal)" if $DEBUG;
		#print "\t";

## JS		$worksheet2->write($cnt2,$loop_index+1, $deltaVal  ); ## Excel

		## These variables are global. So I should reset these before the next loop. Otherwise same value will come up in case there is no value on the loop turn
		$curVal = 0;$preVal=0; 
		
	}
	$cnt2++; ## Excel, the next row number position
	print "\n";
}


##################################################################
####### Print SYS CPU part on terminal and on 2nd Excel worksheet 
##################################################################
print "\n\n*** SYS CPU delta value \n"; ## plain output
#print "\(EDUID\/NAME)\/Time \t"; ## plain output
#printf "%30s","\(EDUID\/NAME)\/Time "; ## plain output
printf "%10s","EDUID"; ## plain output
#print " \/ "; ## plain output
printf "%20s","EDUNAME"; ## plain output

### print timestamp line on terminal output, but printing from 2nd timestamp as 1st one does not have delta
for ($tmpCnt = 2; $tmpCnt < $cnt1; $tmpCnt++) {
		#print "T$tmpCnt\t";
	#printf "%16s","T$tmpCnt";
	printf "%15s","T";
	printf "%1d","$tmpCnt";

}

print "\n";
my $cnt2=2;
## for each edu id, print the delta value of Total CPU.
for my $p1 (@eduUniqList){
	#print "$p1->{eduID}\/$p1->{eduName}\t "; # print 1st column with eduID/eduName
	#printf "%30s","$p1->{eduID} \/ $p1->{eduName} "; # print 1st column with eduID/eduName
	printf "%10d","$p1->{eduID}"; # print 1st column with eduID/eduName
	#print " \/ "; # print 1st column with eduID/eduName
	printf "%20s","$p1->{eduName}"; # print 1st column with eduID/eduName
	#print "\t"; # Skipping printing 2nd column as there will be no delta value for 1st timestamp

## JS	$worksheet3->write($cnt2,0, "$p1->{eduID}/$p1->{eduName}"  ); ## Excel

	# loop from the second file	
	for ($loop_index = 1;$loop_index <= $#parseFileList; $loop_index++) {
		#print "$parseFileList[$loop_index]->{fileTimeStamp}\t ";

		# Get the totCPU of the current timestamp
		for my $p3 (@Parsed) {
			if ( $p3->{eduID} == $p1->{eduID} and $p3->{fileTimeStamp} eq $parseFileList[$loop_index]->{fileTimeStamp} ){
				#print "$p3->{eduID}/$p1->{eduID}\t"; # To debug if eduID is same
				$curVal = $p3->{sysCPU};
				#print "$curVal\t";
			}
		}
		# Get the totCPU of the previous timestamp
		for my $p3 (@Parsed) {
			if ( $p3->{eduID} == $p1->{eduID} and $p3->{fileTimeStamp} eq $parseFileList[$loop_index-1]->{fileTimeStamp} ){
				#print "$p3->{eduID}/$p1->{eduID}\t"; # To debug if eduID is same
				$preVal = $p3->{sysCPU};
				#print "$preVal\t";
			}
		}

		$deltaVal = $curVal - $preVal;
		#print "$deltaVal ";
		#$deltaVal=sprintf ("%.2f", $deltaVal);
		#print "$deltaVal ";
		printf "%15.2f",$deltaVal;
		print "($curVal - $preVal)" if $DEBUG;
		#print "\t";

## JS		$worksheet3->write($cnt2,$loop_index+1, $deltaVal  ); ## Excel

		## These variables are global. So I should reset these before the next loop. Otherwise same value will come up in case there is no value on the loop turn
		$curVal = 0;$preVal=0; 
		
	}
	$cnt2++; ## Excel, the next row number position
	print "\n";
}



$excelOutput.close(); ## Excel : close file.

	## Array of hash pointers test
	#for my $p (@Parsed) {
	#	next if ( $p->{eduID} != 11 );
	#	print "pointer : $p\n" if $DEBUG;
	#	print "$p->{eduID} : $p->{totCPU}\n" if $DEBUG;
	#}	




sub usage{
	$prog  = basename($0);
	print "Usage:\n";
	print "-f <filenames>\n";
	print "-d <debug mode> -- 1:debug\n";
	print "example : \n";
	print "$prog -f 'db2pd.edus*' -d=1\n";	

}


