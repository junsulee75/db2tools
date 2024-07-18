


##########################################
 # Package name : JSPerlLib
 # Copyright © 2017 Jun Su Lee. All rights reserved.
 # Author : Jun Su Lee ( junsulee@au1.ibm.com )
 # Description : Jun Su's Perl common functions.
 # Category : 
 # Usage
 # Date : August 20, 2017
 # Revision History
##########################################

## addLineTail($strFileName,$strLine)  : Add a line at the end of a file
## printFile($strFileName)  : Add a line at the end of a file




package JSPerlLib ;
use Switch ;

my $DEBUG = 0;

## Add a line at the end of a file 
## addLineTail($strFileName,$strLine)
sub addLineTail
{
	my ($self,$strFileName,$strLine) = @_;
	print "$strFileName   $strLine\n" if $DEBUG;

	open DATAFILE, ">>$strFileName" or die("Can't find the $strFileName\n");
	print DATAFILE "$strLine\n";
	close DATAFILE;

	return 0;
}

## Just read and print the File
## printFile($strFileName)
sub printFile
{
	my ($self,$ResultFile) = @_;
	my $ReadVar;
	
	open(RESULT_FD,"< $ResultFile") or die("Can't find the $ResultFile.\n");

	printf "\n\n************** Reading %s, Pls be patient !! \n\n", $ResultFile ;
	while(defined($ReadVar=<RESULT_FD>)) {
		chomp $ReadVar;
		print "$ReadVar\n" ;
	}
	
	close(RESULT_FD);
	printf("DEBUG : result_read end \n") if $DEBUG;
	return 0;
}





@ISA = qw(Exporter) ;
@EXPORT_OK = qw(first_time_stamp last_time_stamp roundup gendata) ;

require Exporter ;
use vars qw(@ISA @EXPORT_OK) ;

# Get the first timestamp of a db2diag.log file
sub first_time_stamp 
{
	my ( $fn ) = @_ ;
	open FH , $fn or die "cannot open $fn\n" ;
	
	my $dt ;
	# Get the first timestamp
	while ( <FH> ) {
		if ( m/^(\d+-\d+-\d+.*?)\s+/ ) {
			$dt = $1 ;
			$dt = substr($dt,0,10) . " " . substr($dt,11,15) ;
			last ;
		}
	}
	close FH ;
	return $dt ;
}

# Get the last timestamp of a db2diag.log file
sub last_time_stamp
{
	my ( $fn ) = @_ ;
	
	my $sz = -s $fn ;
	my $dt ;
	open FH , $fn or die "cannot open $fn\n" ;
	# Get the last timestamp
	seek FH , $sz - 5000 , 0  ;
	while ( <FH> ) {
		if ( m/^(\d+-\d+-\d+.*?)\s+.*LEVEL/ ) {
			$dt = $1 ;
			$dt = substr($dt,0,10) . " " . substr($dt,11,15) ;
		}
	}
	return $dt ;
}

sub roundup
{
   my $number = int ( shift ) ;
   my $round = shift ;

   if ($number % $round) {
      return (1 + int($number/$round)) * $round;
   }
   else {
      return $number;
   }
}

# This function gen is called only by gendata.  See comment on gendata
my @chars = ("A".."Z", "a".."z" , "0".."9") ;
my @numbs = ( "0".."9" ) ;

sub gen
{
    my ( $type ) = @_ ;

    my $string;

    if ( $type =~ m/C(\d+)/ ) {
        $len = $1 ;
        $string .= $chars[rand @chars] for 1..$len ;
        # $string = "\'$string\'" ;
    }

    if ( $type =~ m/N(\d+)/ ) {
        $len = $1 ;
        $string .= $numbs[rand @numbs] for 1..$len ;
    }

    my $string1 ;
    my $string2 ;
    if ( $type =~ m/D(\d+),(\d+)/ ) {
        $len1 = $1 ; $len2 = $2 ;	# Len1 = total digits.  Len2 = number of decimal.  E.g.  19.234 is D5,3
=begin AUD
        $len1 = 3 if ( $len1 > 3 ) ;
        $len2 = 2 if ( $len2 > 2 ) ;
        $string1 .= $numbs[rand @numbs] for 1..$len1 ;
        $string2 .= $numbs[rand @numbs] for 1..$len2 ;
        $string = ( $len2 == 0 ) ? $string1 : "$string1.$string2" ;
=cut
		my $left = $len1 - $len2 ;
		my $right = $len2 ;
        $string1 .= $numbs[rand @numbs] for 1..$left ;
        $string2 .= $numbs[rand @numbs] for 1..$right ;
        $string = "$string1.$string2" ;
		
    }
    return $string ;
}

# Function to generate some random number
#
# Input  : gendata ( qw/int char(29) char(39) decimal(5,3)/ ) ;
# Output : an array of random number or strings

sub gendata
{
    my ( @columns ) =  @_ ;

    my @fld = () ;
    foreach my $col ( @columns ) {

        switch ( $col ) {

            case m/CHAR\((\d+)\)/i  {
                $col =~ m/CHAR\((\d+)\)/i ;
                $len = $1 ;
                push ( @fld , gen("C$len") ) ;
            }

            case m/DECIMAL\((\d+),(\d+)\)/i {
                $col =~ m/DECIMAL\((\d+),(\d+)\)/i ;
                $len1 = $1 ; $len2 = $2 ;
                $genvalue = gen("D$len1,$len2") ;
                push ( @fld , $genvalue ) ;
            }

            case m/^INT[EGER]*/i {
                $genvalue = gen("N7") ;
                push ( @fld , $genvalue ) ;
            }

            case m/^SMALLINT/i  {
                $genvalue = gen("N4") ;
                push ( @fld , $genvalue ) ;
            }

            else {
                print "Unknown column type - $col\n" ;
                exit ;
            }
        }

    }
    return @fld ;
}


return 1 ;
