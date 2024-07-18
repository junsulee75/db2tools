package DeepHash ;

use DB_File ;
use MLDBM qw( DB_File Storable ) ;
use Data::Dumper ;

# This module serve as a front end to the database package.  create an object base on the specified path
sub new 
{
	my ( $class , $dbpath  ) = @_ ;
	
    my $self = () ;
	$self->{DBPATH} = $dbpath ;

	tie my %db , 'MLDBM', $dbpath , O_CREAT|O_RDWR, 0640 or die $!;
	$self->{DB} = \%db ;
	
	bless ( $self, $class ) ;
	return $self ;
}

# Set the key with a record.
sub set
{
	my ( $class , $key , $record ) = @_ ;
	my $db = $class->{DB} ;
	$db->{$key} = $record ;
}

# Get the value with a key
sub get 
{
	my ( $class , $key ) = @_ ;
	my $db = $class->{DB} ;
	return $db->{$key} ;
}

# Dump the entire hash tree, or just a key
sub dump 
{
	my ( $class , $key ) = @_ ;

	my $db = $class->{DB} ;
	if ( defined $key ) {
		print Data::Dumper->Dump ( [ $db->{$key} ] , [ $key ] ) ;
	} else {
		print Data::Dumper->Dump ( [ $db ] , [ 'ALL' ] ) ;
	}
}

# Give the handle of the DB file
sub get_handle
{
	my ( $class ) = @_ ;
	return $class->{DB} ; 
}

# This is useful to give a random key that does not clash with existing keys.  
sub random_key 
{
	my ( $class ) = @_ ;
	my $db = $class->{DB} ;
	
	# Generate a random number until it does not exist in the DB
	my $random_number = 0 ;
	for ( ; ; ) {
		$random_number = int ( rand() * 100000000 ) ;
		next if ( exists $db->{$random_number} ) ;
		last ;
	}
	return $random_number ;
}

#  This function is *ONLY* useful if all the indexes is a running number.  It searches thru the key and 
# return the next higher number.
sub nextseq
{
	my ( $class ) = @_ ;
	my $db = $class->{DB} ;
	
	my $idx = 0 ;
	for ( $idx = 0 ;; $idx++ ) {
		next if (  exists $db->{$idx} ) ;
		last ;
	}
	return $idx ;
}

# Return all the keys of the hash
sub getkeys
{
	my ( $class ) = @_ ;
	my $db = $class->{DB} ;
	
	my @arr = sort { $b <=> $a } keys %$db ;
	return @arr ;
}


return 1 ;
