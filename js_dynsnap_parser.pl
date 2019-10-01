#!/usr/bin/perl

use Getopt::Long;
use Getopt::Std;
use File::Basename;
use Excel::Writer::XLSX; # For excel

my $prog  = basename($0);

=pod

=head1 VERSION

    Version 		: $Revision: 1.0 $
    Last modified 	: $Date: 2019-09-21 (Fri, 05 July 2019) $
    Author : Jun Su Lee ( junsulee@au1.ibm.com )
    URL			: $HeadURL: https://github.com/junsulee75/db2tools $ ;

=head1 SYNOPSIS

	Usage :
	js_dynsnap_parser.pl -f <Dynamic snapshot filename>  

	example : 
	js_dynsnap_parser.pl -f 'dynsnap.out'

=head1 DESCRIPTION

    This program helps to create a excel output parsing one DB2 dynamic snapshot file
    for analysis like finding top SQL with interested value like average elapsed time, rows read etc.

=head1 Author
	Jun Su Lee ( junsulee@au1.ibm.com (company)  / lee.junsu@gmail.com (private) / https://www.linkedin.com/in/junsulee )

	
	Type 'q' to exit this page.
=cut

my @fileList; # filelist from user command input parameter. But in this program, we just want to use one file.
my $DEBUG=0;

sub usage{

	
	print <<AUD ;

    Usage :
	$prog -f <Dynamic snapshot filename>  

	example : 
	$prog -f 'dynsnap.out' 

AUD
	exit;
}

sub usage_perldoc{
	system( "pod2text -w `tput cols` $0 | less" ) ;
	#system( "perldoc -t $0" ) ;

	exit;	
	
}

&usage if( scalar(@ARGV) < 1 ) ;

GetOptions(
	    "filename=s" => \$fileName,      
	    "debug=i" => \$DEBUG      
	    )
or die "Incorrect usage ! \n";

print "$fileName\n";
@fileList = glob($fileName);

##### Variables
my $DEBUG_M = "====> DEBUG :";
my $numExec = 0; #reset value 
my $rowCnt = 0;  #row count
my $totExecTime = 0;  my $avgExecTime = 0;  
my $sortNum = 0;
my $sortOverflowNum = 0;
my $totSortTime = 0 ; my $avgSortTime = 0;
my $bufDataLogicalRead=0; my $bufDataPhyRead=0; my $bufDataHit=0;
my $bufIdxLogicalRead=0; my $bufIdxPhyRead=0; my $bufIdxHit=0;
my $rowsRead=0; my $rowsWritten=0; my $avgRowsRead=0;
my $sqlStatement ;  

sub doParse {
	my ( $fn ) = @_ ;

	open FH, $fn or die ;
    my $excelFilename = "$fn.xlsx";
    my $excelOutput = Excel::Writer::XLSX->new( $excelFilename ); ### Excel

	# format to highlight caculated columns
	my $format1 = $excelOutput->add_format();
	$format1->set_bold();
	$format1->set_color('blue');

	#$excelOutput->set_size(1200,800); ## Window size  -> Not working
	$worksheet1 = $excelOutput->add_worksheet($fn); ## create a worksheet

	## Print column name on the Excel worksheet
	$worksheet1->write( 'A1', 'Num' ); $worksheet1->set_column(0,0,5); ## 0
	$worksheet1->write( 'B1', 'Avg Exec Time(sec.ms)', $format1 ); $worksheet1->set_column(1,0,20);  ## 1
	$worksheet1->write( 'C1', 'NumExec' ); $worksheet1->set_column(2,0,10); ## 2
	$worksheet1->write( 'D1', 'TotExecTime(sec.ms)' ); $worksheet1->set_column(3,0,20); ## 3 

	$worksheet1->write( 'E1', 'AvgRowsRead', $format1 ); $worksheet1->set_column(4,0,20); ## 4
	$worksheet1->write( 'F1', 'RowsRead' ); $worksheet1->set_column(5,0,10); ## 5 
	$worksheet1->write( 'G1', 'RowsWritten' ); $worksheet1->set_column(6,0,10); ## 6

	$worksheet1->write( 'H1', 'Avg Sort Time(ms)', $format1 ); $worksheet1->set_column(7,0,15); ## 7
	$worksheet1->write( 'I1', 'SortNum' ); #8
	$worksheet1->write( 'J1', 'SortOverflow' ); $worksheet1->set_column(9,0,13); ## 9
	$worksheet1->write( 'K1', 'TotSortTime(ms)' ); $worksheet1->set_column(10,0,12); ## 10

	$worksheet1->write( 'L1', 'DataBPHitRatio(%)', $format1 ); $worksheet1->set_column(11,0,15); ## 11
	$worksheet1->write( 'M1', 'DataLogicalRead' ); $worksheet1->set_column(12,0,13); ## 12
	$worksheet1->write( 'N1', 'DataPhysicalRead' ); $worksheet1->set_column(13,0,13); ## 13

	$worksheet1->write( 'O1', 'IndexBPHitRatio(%)', $format1 ); $worksheet1->set_column(14,0,15); ## 16
	$worksheet1->write( 'P1', 'IndexLogicalRead' ); $worksheet1->set_column(15,0,13); ## 14
	$worksheet1->write( 'Q1', 'IndexPhysicalRead' ); $worksheet1->set_column(16,0,13); ## 15
	$worksheet1->write( 'R1', 'SQLStmt' ); $worksheet1->set_column(17,0,100); ##  17
	print "############# File = $fn\n\n";

	$numExec = 0; #reset value 
	$rowCnt = 0; ## each data index
	$totExecTime = 0;
	$avgExecTime = 0;
	$rowsRead = 0;
	$sortNum = 0;
	$sortOverflowNum = 0;
	$sqlStatement = "";
	$totSortTime = 0; $avgSortTime = 0;
	$bufDataLogicalRead=0; $bufDataPhyRead=0; $bufDataHit=0;
	$bufIdxLogicalRead=0; $bufIdxPhyRead=0; $butIdxHit=0;
	$rowsRead=0; $avgRowsRead = 0 ;

	while ( <FH> ) {

		print $_ if $DEBUG;
        if ( m/Number of executions\s+=\s+(\d+)/ ) { # There is one space starting each line. So I don't use ^.
			$numExec = $1;
			$rowCnt++; # add count meeting the 1st atribute
			$worksheet1->write($rowCnt,0, $rowCnt  ); # 0 : num
			$worksheet1->write($rowCnt,2, $numExec  ); # 2 : number of execution
        } elsif (m/Total execution time \(sec\.microsec\)=\s+(\d+\.\d+)/){ # no space before = 'equal'
			$totExecTime = $1; print "$DEBUG_M TotalExecTime : |$totExecTime| \n" if $DEBUG;
			$worksheet1->write($rowCnt,3, $totExecTime  ); # 3 

			# calculate and print average execution time 	
			if ($numExec > 0) { # not to divide by zero
				$avgExecTime = $totExecTime / $numExec ; print "$DEBUG_M TotalExecTime : |$totExecTime| / |$numExec| = |$avgExecTime| \n" if $DEBUG;
				#$worksheet1->write($rowCnt,1, sprint("%.6f", $avgExecTime) ); # 1 <- Round number to 6 decimal places : ERROR
				$worksheet1->write($rowCnt,1, $avgExecTime ); # 1 <- TODO : Round number to 6 decimal places
			}
		} elsif ( m/Rows read\s+=\s+(\d+)/ ) {
				$rowsRead = $1; print "$DEBUG_M Rows read : |$rowsRead| \n" if $DEBUG;
				$worksheet1->write($rowCnt,5, $rowsRead  ); # 5 : Rows read
				if($numExec > 0) {
					#$avgRowsRead = 0; # do reset just in case previous data is remained and this time 
					$avgRowsRead = $rowsRead / $numExec ;
					$worksheet1->write($rowCnt,4, $avgRowsRead   ); #4  : Avg rows lead
					print "$DEBUG_M AvgRowsRead : |$rowsRead| / |$numExec| = |$avgRowsRead| \n" if $DEBUG;
				}
		} elsif ( m/Statement sorts\s+=\s+(\d+)/ ){
				$sortNum = $1;
				$worksheet1->write($rowCnt,8, $sortNum  ); # 8	: vSortNum
		} elsif ( m/Statement sort overflows\s+=\s+(\d+)/ ){
				$sortOverflowNum = $1;
				$worksheet1->write($rowCnt,9, $sortOverflowNum  ); # 9 : vSortOverflow
		} elsif ( m/Total sort time\s+=\s+(\d+)/ ){
				$totSortTime = $1;
				if ($sortNum > 0) {
					$avgSortTime = $totSortTime / $sortNum; 
					$worksheet1->write($rowCnt,7, $avgSortTime  ); # 7 : vAvgSortTime
				}
				$worksheet1->write($rowCnt,10, $totSortTime  ); # 10 : totSortTime
		} elsif ( m/Buffer pool data logical reads\s+=\s+(\d+)/ ){
				$bufDataLogicalRead = $1;
				$worksheet1->write($rowCnt,12, $bufDataLogicalRead  ); # 12 : Buffer pool data logical reads
		} elsif ( m/Buffer pool data physical reads\s+=\s+(\d+)/ ){
				$bufDataPhyRead = $1;
				$worksheet1->write($rowCnt,13, $bufDataPhyRead  ); # 13 : Buffer pool data physical reads
				if ( ($bufDataLogicalRead + $bufDataPhyRead) > 0 ){
					$bufDataHit = $bufDataLogicalRead / ($bufDataLogicalRead + $bufDataPhyRead) * 100;
					$worksheet1->write($rowCnt,11, $bufDataHit  )	; # 11. Buffer pool data hit ratio
				}
		} elsif ( m/Buffer pool index logical reads\s+=\s+(\d+)/ ){
				$bufIdxLogicalRead = $1;
				$worksheet1->write($rowCnt,15, $bufIdxLogicalRead  ); # 15 : Buffer pool indexlogical reads
		} elsif ( m/Buffer pool index physical reads\s+=\s+(\d+)/ ){
				$bufIdxPhyRead = $1;
				$worksheet1->write($rowCnt,16, $bufIdxPhyRead  ); # 16 : Buffer pool index physical reads
				if ( ($bufIdxLogicalRead + $bufIdxPhyRead) > 0 ){
					$bufIdxHit = $bufIdxLogicalRead / ($bufIdxLogicalRead + $bufIdxPhyRead) * 100;
					$worksheet1->write($rowCnt,14, $bufIdxHit  )	; # 14 : Index bufferpool hit ratio
				}
		} elsif ( m/Rows written\s+=\s+(\d+)/ ){
				$rowsWritten = $1;
				$worksheet1->write($rowCnt,6, $rowsWritten  ); # 6 : Rows written:w

		} elsif ( m/^ Statement text\s+=\s(.+)/ ) {
				$sqlStatement = $1; print "$DEBUG_M Statement : |$sqlStatement| \n" if $DEBUG;
				$worksheet1->write_string($rowCnt,17, $sqlStatement  ); # 17 : Statement
		}

	}

    # close input and excel file
	close FH;
    $excelOutput.close();
}

foreach $inputFile ( @fileList ) {
	doParse $inputFile ;
	print "\n";
}


