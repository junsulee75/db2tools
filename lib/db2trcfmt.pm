package db2trcfmt ;

# Uses binary search to get the lines belonging to a flow number

sub new 
{
	my ($class,$fn) = @_ ;
	
        my $self = () ;
	$self->{FILE}  = $fn ;
	
	open FH2 , $fn or die "cannot open $fn" ;
	seek FH2 , 0 , 2 ;	# seek to end of file
	$self->{FH2} = *FH2 ;	
	$self->{SIZE} = tell FH2 ;
	
        bless ( $self, $class ) ;
        return $self ;
}

# Get the closest flw entry number given the FH position
sub getnbr 
{
	my ( $pos ) = @_ ;
	
	$rc = seek FH2 , $pos , 0 ; 
	<FH2> if ( $pos > 0 ) ;  # discard first line if pos > 0 
	# print "Seek to $pos - $rc\n" ;
	while ( <FH2> ) {
		# print ;
		if ( m/^(\d+)\s+/ ) {
			$retval = $1 ;
			last ;
		}
	}
	# print "POS = $pos , Retval = $retval\n\n\n\n" ;
	return $retval ;
}

# 
# Print the flow entry given this POS.  Step :
#
#	gobble up the first partial line first.
#	advance until see first entry number
#	absort line until see another entry number
# 	
sub pfmt 
{
	my ( $pos ) = @_ ;
	$rc = seek FH2 , $pos , 0 ; 
	<FH2>  if ( $pos > 0 ) ;  #gobble up partial line if if pos > 0 
	
	$pflag = 0 ;		# increment when we see the flow entry number
	$ln = "" ;
	while ( <FH2> ) {
		$pflag++ if ( m/^(\d+)\s+/ ) ;
		
		$ln .= $_ if ( $pflag == 1 ) ;
		last if ( $pflag == 2 ) ;  # stop if we see 2nd entry number
	}
	chop ($ln) ;
	return $ln ;
}

sub search
{
	my ( $class , $key ) = @_ ;
	
	$top = 0 ;
	$bottom = $class->{SIZE} ;
	
	$cnt = 0 ;
	do {
		$cnt++ ;
		$mid = $top + int ( ($bottom - $top)/2 + 1 )  ;
		
		# mid will never ever hit 0. so since this is just an estimated position
		# if mid is about 80 bytes away, set it to 0 anyway.
		$mid = 0 if ( $mid < 10 ) ;
		
		# get the closest FLW number at this file position
		$rets = getnbr ( $mid ) ;
		# print "RETS = $rets , TOP = $top , BOTTOM = $bottom , MID = $mid , CNT = $cnt\n" ;
		
		# move the top or bottom depending on outcome of comparison against the key 
		# we want
		$bottom = $mid if ( $rets > $key ) ;
		$top    = $mid if ( $rets < $key ) ;
		
	} until ( $top >= $bottom || $rets == $key ) ; 
	
	return ( ( $rets == $key ) ?  pfmt ( $mid ) : "Entry [$key] not found" ) ;
	
}

sub DESTROY {
    my $self = shift;
    # printf("$self dying at %s\n", scalar localtime);
} 

return 1 ;