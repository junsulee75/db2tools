package db2diag ;

$TRUE  = 1 ;
$FALSE = 0 ;

use constant YES => 1 ;
use constant NO  => 0 ;

sub new 
{
	my ($class,$fn ) = @_ ;
	
    my $self = () ;
	$self->{FILE}  = $fn ;

	if ( $fn eq "stdin" ) {
		$self->{STDIN} = $TRUE ;
		*FH = *STDIN ;
	} else {
		$self->{STDIN} = $FALSE ;
		open FH , $fn or die "cannot open $fn" ;
	}
	
	$self->{FH} = *FH ;
	$self->{START_LINE} = 1 ;
	$self->{CURR_LINENUMBER} = 0 ;

	my @l = stat $fn ;
	$self->{END}  = $l[7] ;
	$self->{SIZE} = $l[7] ;
		
        bless ( $self, $class ) ;
        return $self ;
}

sub setopt {
	
	my ( $class , $opt ) = @_ ;
	
	foreach $k ( keys %$opt ) {
		$class->{$k} = $opt->{$k} 
	}
}

sub tail 
{

	my ( $class , $nlines ) = @_ ;
	$backleap = 5000 ;
	
	# cannot tail on STDIN
	die "-t not applicable reading from STDIN" if ( $class->{STDIN} == $TRUE ) ;
	die "-t not applicable with -n" if ( defined $class->{LINENBR} ) ;
	
	local *FH = $class->{FH} ;
	%OFFSET = () ;
	
	# start by going backwards 5000 bytes. 
	# if file is smaller than 5000 bytes, start at 0.
	$startpos = $class->{END} - $backleap ;
	$startpos = 0 if ( $startpos < 0 ) ;
	
	#   algorithm is as follows
	#
	#   1 go to END and move back by 5000 bytes
	#   2 dischard half line
	#   3 read each line and keep in OFFSET{x} where x is the position of each new line
	#   4 if we have exceeded the number of lines we want, stop. 
	#   5 otherwise - go back by another 5000 bytes, and start step 2
	#

	# set backleap to smaller value if file is small
	for ( $loc = $startpos ; $loc <= $class->{END} ; $loc -= $backleap ) {
		seek FH , $loc , 0 ;		# seek to location
		<FH> ;				# skip probably first half line
		
		do
		{
			$pos = tell FH ; 
			$ln = <FH> ;
			if ( defined $ln ) {
				$OFFSET{$pos}++  ;
				# print $ln ;
			}
		} until ( ! defined $ln || $OFFSET{$pos} > 1 || $pos >= $class->{END} ) ;
		# break out the do until on the following conditions 
		#	1 - read did not give any line
		#	2 - hit the END position
		#	3 - seen this line before
		
		last if ( keys(%OFFSET) > $nlines  )  ;
	}
	
	@offset = sort { $a <=> $b } keys %OFFSET ;	# get the list of offsets
	splice(@offset, 0, @offset - $nlines);   	# retain only the last nlines
	
	foreach $offset ( @offset ) {
	 	seek FH , $offset , 0 ;
	 	$ln = <FH> ; 
	 	print $ln ;
	}

}

#------------------------------------------------
# Print nlines lines beginning at start
#------------------------------------------------
sub head 
{
	my ( $class , $nlines  ) = @_ ;
	
	for ( my $i = 0 ; $ln = getline ( $class ) ; $i++ ) {
		print_str ( $class , $ln ) ;
		last if ( $i == $nlines ) ;
	}
	
}

#------------------------------------------------
# Print the string with line number
#------------------------------------------------
sub print_str
{
	my ( $class , $str ) = @_ ;

	$str = $class->{CURR_LINENUMBER} . " : $str" if ( defined $class->{LINENBR} ) ;
	print $str ;

}

#----------------------------------------------------------------------------
#	EOF occurs when end of real file/STDIN, or matches the OPT_E pattern
#	??? how do i return a line that match EOF and still raise the flag as true ?
#----------------------------------------------------------------------------
sub getline
{
	my ( $class ) = @_ ;
	local *FH = $class->{FH} ;
	
	my $ln = <FH> ;	
	$class->{CURR_LINENUMBER}++ ;
	
	# return UNDEF if hit end pattern
	return undef if ( exists $class->{OPT_E} && $ln =~ m/$class->{OPT_E}/i ) ;
	return $ln ;
}


sub search
{
	my ( $class , $matchstr , $ignorestr ) = @_ ;
	
	my $dt ;
	$matchcnt = 0 ;

	# get a line from the input file
	while ( my $ln = getline ( $class ) ) {
	
		if ( $ln =~ m/^(\d+\-\d+\-\d+.*?)\s+/ ) {
			$dt = $1 ;
			$dt = substr($dt,0,10) . " " . substr($dt,11,15) ;
		}
		
		my $printflag = NO ;
		
		# print "LN=$ln" if ( $class->{FILE} eq "stdin" ) ;
		
		# set printflag to YES if it matches
		$printflag = YES if ( $ln =~ m/$matchstr/i ) ;
		
		# set printflag to YES if suppose to ignore
		$printflag = NO if ( defined $ignorestr && $ln =~ m/$ignorestr/i  ) ;
		
		if ( $printflag == YES ) {
		
			my $str = ( $class->{FILE} eq "stdin" ) ? $ln : "$dt => $ln" ;
			# if not COUNTONLY , proceed print the string
			if ( ! defined $class->{COUNTONLY} ) {
				print_str ($class,$str) ;
			}
			$matchcnt++ ;
			
		}
	
	}
	print "$class->{FILE} : Number of matches = $matchcnt\n" if ( defined $class->{VERBOSE} || defined $class->{COUNTONLY} ) ;
}

# Show Y lines beginning at X.  Y can be +ve or -ve.
sub range
{
	my ( $class , $ln  ) = @_ ;
	
	# parameter 1 has comma
	( $begin, $end ) = split /,/,$ln ;
	
	$end += $begin if ( $end > 0 ) ;
	$begin += $end if ( $end < 0 ) ;
	$end = $begin-$end if ( $end < 0 ) ;

	for ( my $i = 1 ; $i < $end ; $i++ ) {
		$ln = getline($class)  ;
		print_str ( $class , $ln ) if ( $i >= $begin && $i <= $end ) ;
	}

}

# Show Y lines beginning at X.  Y can be +ve or -ve.
sub Range
{
	my ( $class , $ln  ) = @_ ;
	
	# parameter 1 has comma
	( $begin, $end ) = split /,/,$ln ;
	
	for ( my $i = 1 ; $i < $end+1 ; $i++ ) {
		$ln = getline($class)  ;
		print_str ( $class , $ln ) if ( $i >= $begin && $i <= $end ) ;
	}
}


#--------------------------------------------------------------
# display ( or NOT ) a paragraph based on a regular expression
#--------------------------------------------------------------
sub paragraph
{
	my ( $class , $pattern , $ignore ) = @_ ;
	
	# $patt = split /&&/, $pattern ;
	# print "Pattern = [$pattern], Ignore = $ignore\n" ; exit ;
	my $paragraph = "" ;
	my $printflag ;
	while ( my $readln = getline($class)  ) {
		
		# found a new datetime , analyse current paragraph
		if ( $readln =~ m/(^\d+-\d+-\d+.*?)\s+/ ) {
	
			# default is YES if ignore = 1 , and then set it to NO if it matches
			if ( defined $ignore ) {
				$printflag = YES ;
				$printflag = NO if ( $paragraph =~ m/$pattern/i ) ;
			} else {
			# default is NO if ignore = 0 , and then set it to YES print if it matches
				$printflag = NO ;
				$printflag = YES if ( $paragraph =~ m/$pattern/i ) 
			}
			print_str ( $class , $paragraph ) if ( $printflag == YES );
			
			$paragraph = $readln ;
			next ;
		}	
		$paragraph .= $readln ;
	}

	# need to analyze the LAST paragraph !! quick dirty fix
	if ( defined $ignore ) {
		$printflag = YES ;
		$printflag = NO if ( $paragraph =~ m/$pattern/i ) ;
	} else {
		# default is NO if ignore = 0 , and then set it to YES print if it matches
		$printflag = NO ;
		$printflag = YES if ( $paragraph =~ m/$pattern/i )
	}
	print_str ( $class , $paragraph ) if ( $printflag == YES );  
	
	
}


#-------------------------------------------------------------
#  Set the starting position given a skip
#-------------------------------------------------------------
sub setskip
{
	my ( $class , $skip ) = @_ ;
	
	die "-S not comptabile with STDIN" if ( $class->{STDIN} == $TRUE ) ;
	
	local *FH = $class->{FH} ;
	
	$bytes = $skip if ( $skip =~ m/(\d+)$/ ) ;
	$bytes = $1 * 1024 if ( $skip =~ m/(\d+)K$/ ) ;
	$bytes = $1 * 1024 * 1024 if ( $skip =~ m/(\d+)M$/ ) ;
	$bytes = $1 * 1024 * 1024 * 1024 if ( $skip =~ m/(\d+)G$/ ) ;
	
	# print "Skipping $bytes\n" ;
	$rc = seek FH , $bytes , 0 ;
	<FH> if ( $rc == 1 ) ; 			# skip half line

}

# Set the BEGIN flag, and advance to it
sub setbegin
{
	my ( $class , $pattern ) = @_ ;
	
	# Notify that OPTB is specified.
	$class->{OPT_B} = $pattern ;
	
	while ( $ln = getline ( $class ) ) {
		last if ( $ln =~ m/$pattern/i ) ;
	}
	print "-B [$pattern] not found in $class->{FILE}\n" if ( ! defined $ln )  ;
	return ;
}

#-------------------------------------------------------------
#  Set the ending position for scanning
#-------------------------------------------------------------
sub setend
{
	my ( $class , $pattern ) = @_ ;
	$class->{OPT_E} = $pattern ;
}

sub finish
{
	my ( $class ) = @_ ;
	local *FH = $class->{FH} ;
	close FH ;
	delete $class->{FH} if ( $class->{STDIN} == $FALSE ) ;
}

sub DESTROY {
    my $self = shift;
    # printf("$self dying at %s\n", scalar localtime);
} 

return 1 ;
