# Have to rename this to reduce conflict with the Time module
package MyTime ;
use DateTime;
use String::Scanf; # imports sscanf()

##  Specify the format on the input string , must have yyyy mm dd min ss ns hh
##  Methods :
##  
##  set_start , set_end , diff
sub new 
{
	my ( $class , $fmt ) = @_ ;
	
      my $self = () ;
  	$self->{FORMAT} = $fmt ;
      bless ( $self, $class ) ; 
      return $self ; 
}

# this function returns a hash of
#	$h{mm} = blah, $h{hh} = blah ....
sub map_format_to_values
{
	my ( $fmt , $str ) = @_ ;
	my %H = ()  ;
	
		# get an array of mm , yy , and the format strings .e.g  [ yyyy , mm , dd , hh , ... ]
		$scanfs = $fmt ;
		$scanfs =~ s/dd|mm|yyyy|hh|min|ss|ns/%s/g ;
		@l1 = sscanf($scanfs, $fmt);
		# print "scanfs = $scanfs , \@l1 = " . join(" : ", @l1 ) . "\n" ;
		
		# get an array of values base on format strings  e.g. [ 2013 , 04 , 10 , 23 , ..... ]
		$scanfs = $fmt ;
		$scanfs =~ s/dd|mm|yyyy|hh|min|ss|ns/%d/g ;
		@l2 = sscanf($scanfs, $str);
		# print "scanfs = $scanfs , str = $str , \@l2 = " . join(" = ", @l2 ) . "\n" ;
		
		# H{mm} = value , H{yyyy} = value ....
		for ( $i = 0 ; $i < @l1 ; $i++ ) {
			my $key   = $l1[$i] ;
			my $value = $l2[$i] ;
			$H{$key} = $value ;
		}

		return %H
}

# Returns the datetime of a string
sub to_datetime
{
	my ( $class , $str ) = @_ ;
	my %H = map_format_to_values ( $class->{FORMAT} , $str ) ;
			
	# do a mm/dd swap if mm > 12
	( $H{mm} , $H{dd} ) = ( $H{dd} , $H{mm} ) if ( $H{mm} > 12 ) ;
	
	# make the nanoseconds into 9 digits
	$H{ns} = sprintf "%.09f" , "0.$H{ns}" ;
	$H{ns} =~ s/^0.// ;

	my $dt = DateTime->new(
   		year       => $H{yyyy} ,
    	month      => $H{mm} ,
     	day        => $H{dd} , 
     	hour       => $H{hh} ,
     	minute     => $H{min} ,
      	second     => $H{ss} ,
      	nanosecond => $H{ns}
  	) ;
 
 	return $dt ;
}

# Returns the epoch time of a string
sub epoch
{
	my ( $class , $str ) = @_ ;
	my %H = map_format_to_values ( $class->{FORMAT} , $str ) ;
			
	# do a mm/dd swap if mm > 12
	( $H{mm} , $H{dd} ) = ( $H{dd} , $H{mm} ) if ( $H{mm} > 12 ) ;
	
	my $dt = DateTime->new(
   		year       => $H{yyyy} ,
    	month      => $H{mm} ,
     	day        => $H{dd} , 
     	hour       => $H{hh} ,
     	minute     => $H{min} ,
      	second     => $H{ss} ,
      	nanosecond => $H{ns} 
  	) ;
 
 	return $dt->epoch() ; 		
}

# Set the start date time
sub set_start_TBD
{
		my ( $class , $str ) = @_ ;
 		$class->{START} = epoch( $class ,$str ) ; 		
}

# Set the ending date time
sub set_end_TBD
{
		my ( $class , $str ) = @_ ;
  		$class->{ENDTM} = epoch($class ,$str) ; 		
}

# Returns the difference in seconds between end and start
sub diff_TBD
{
		my ( $class ) = @_ ;
		return ( $class->{ENDTM} - $class->{START} ) ;
}

sub verbose
{
	my ( $class , $str ) = @_ ;
	
	my %H = map_format_to_values ( $class->{FORMAT} , $str ) ;
		
		print "STR => $str converted to\n" ;
		foreach $k ( keys %H ) {
			print "$k => $H{$k}\n" ;
		}	
}

# change the timestamp into a new format
sub reformat
{
		my ( $class , $newfmt , $str ) = @_ ;
		my %H = map_format_to_values ( $class->{FORMAT} , $str ) ;
		
		foreach ( qw/yyyy mm dd hh min ss ns/ ) {
			$newfmt =~ s/$_/$H{$_}/ ;
		}
		return $newfmt ;
}


# Give the different in time as X.Y where X is seconds, Y is milliseconds
# fmt is something like %d-%d-%d-%d:%d:%d.%d

use Data::Dumper ;

sub diff
{
	my ( $class , $t0 , $t1 ) = @_ ;

	my $dt0 = $class->to_datetime ( $t0 ) ;
	my $dt1 = $class->to_datetime ( $t1 ) ;

    my $duration = $dt0->subtract_datetime_absolute ( $dt1 ) ;
    my $diff = sprintf "%d.%06d" , $duration->seconds() , substr($duration->nanoseconds(),0,6) ;
    return $diff ;
}

return 1 ;
