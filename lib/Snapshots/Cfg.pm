package Cfg ;
use File::Copy;

sub new 
{
	my ( $class ) = @_ ;
    my $self = () ;
	
	# use the all.cfg if it exists in current directory
	#foreach ( 'D:/Mytools/PerlMod/Snapshots/all.cfg' , '/mnt/hgfs/WinD/mytools/perlmod/Snapshots/all.cfg' , 'all.cfg' ) {
	foreach ( '/Users/kr050496/bin/lib/Snapshots/all.cfg' , 'all.cfg' ) {
		$self->{FILE} = $_ if ( -f $_ ) ;
		copy ( $_ , 'all.cfg' ) if ( ! -f 'all.cfg' ) ;
	}

	my $dict = {} ;
	my $section  ;
	open FH , $self->{FILE} or die "cannot open $self->{FILE}" ;
	while ( <FH> ) {
		
		chomp ; 
		next if ( m/^#/ ) ;			# skip comments
		next if ( m/^$/ ) ;			# skip blank lines
		
		$section = $1 if ( m/\[(\w+)\]/ ) ; 
		
		if ( m/\s+=\s+/  ) {
			my ( $k , $v ) = split /\s+=\s+/ ;
			$dict->{$section}->{$k} = $v ;
		}
	}
	$self->{DICT} = $dict ;
    bless ( $self, $class ) ; 
    return $self ; 
}

sub get
{
	my ( $class , $section , $key ) = @_ ;
	my $dict = $class->{DICT} ;
	return $dict->{$section}->{$key} ;
}

# from the file all.cfg
# [xxx]
#
# f1 = a , b , c , d
# f2 = e , f , g , h
# Str ( xxx , f1 ) returns the string "a,b,c,d"
#
sub Str
{
	my ( $class , $sect , $var ) = @_ ;
	
	# ignore lines beginning with # , and drop out when the FH is pointing at the section i want
	open FH , $class->{FILE} or die "File $class->{FILE} missing" ;
	while ( <FH> ) {
		chomp ;
		next if ( m/^#/ ) ;
		last if ( m/\[$sect\]/ ) ;
	}

	# ignore lines beginning with #.  drop out when it sees the string i want
	while ( <FH> ) {
		chomp ;
		next if ( m/^#/ ) ;
		last if ( m/^$var\s+=/ ) ;
	}
	my ( $k , $v ) = split /\s+=\s+/ ;
	close FH ;
	return $v ;
}

sub Section
{
	my ( $class , $sect ) = @_ ;
	
	# ignore lines beginning with # , and drop out when the FH is pointing at the section i want
	open FH , $class->{FILE} or die "File $class->{FILE} missing" ;
	while ( <FH> ) {
		chomp ;
		next if ( m/^#/ ) ;
		last if ( m/\[$sect\]/ ) ;
	}
	
	my $ln = "" ;
	while ( <FH> ) {
		$ln .= $_ ;
		last if ( m/\[\w+\]/ ) ;
	}	
	close FH ;
	return $ln ;
}

# get the list of "a = b , c , d , e" and return the result as a array list [ b,c,d,e ]
sub List
{
	my ( $class , $sect , $var ) = @_ ;
	
	my $str = $class->Str($sect,$var) ;
	die "Unable to resolve '$var' in section '$sect'" if ( $str eq "" ) ;
	my @l = split /,/ , $str ;
	map { s/^\s+|\s+$//g } @l ;
	return @l ;
}

# seems obselete
sub Lookup_TBD
{
	my ( $class , $name ) = @_ ;
	# ignore lines beginning with # , and drop out when the FH is pointing at the section i want
	open FH , $class->{FILE} or die "File $class->{FILE} missing" ;
	while ( <FH> ) {
		chomp ;
		next if ( m/^#/ ) ;
		last if ( m/^$name\s+=/ ) ;
	}
	my ( $k , $v ) = split /\s+=\s+/ ;
	# print "Lookup [$name] : Key = [$k] , Value = [$v]\n" ;
	close FH ;
	return $v ;
}

return 1 ;
