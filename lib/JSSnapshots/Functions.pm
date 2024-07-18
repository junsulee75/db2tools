package JSSnapshots::Functions ;

@ISA = qw(Exporter) ;
@EXPORT_OK = qw(ratio hitrate decimal commafy sum_of_diff tmdiff delta orderby hashdiff evalstr resolve_formula_fields inputcheck) ;

require Exporter ;
use vars qw(@ISA @EXPORT_OK) ;
use Carp qw(cluck);
use MyTime ;
use JSSnapshots::Cfg ;

use String::CRC::Cksum;
use Tie::IxHash ;
use Parse::RecDescent ;
use File::Slurp ;

my $gramfile ;

# depending whether i ran from Windows or Linux
#$gramfile = 'D:/Mytools/PerlMod/Snapshots/grammar' if ( -f 'D:/Mytools/PerlMod/Snapshots/grammar' ) ;
#$gramfile = '/mnt/hgfs/WinD/mytools/perlmod/Snapshots/grammar' if ( -f '/mnt/hgfs/WinD/mytools/perlmod/Snapshots/grammar' ) ;

#$gramfile = 'D:/Mytools/PerlMod/Snapshots/grammar' if ( -f 'D:/Mytools/PerlMod/Snapshots/grammar' ) ;
$gramfile = '/Users/kr050496/bin/lib/JSSnapshots/grammar' ;

print "Grammar file = $gramfile\n" ;

my $grammar = read_file ( $gramfile ) ;

my $parser = Parse::RecDescent->new($grammar);

my $cfg = new Cfg() ;

## Ratio of X/Y.  Default to $default if Y denominator is 0
sub ratio
{
	my ( $default , $x , $y , $decimal ) = @_ ;
	my $t = $default ;									# set the default return value
	$decimal ||= 4 ;									# set decimal places to 4 if undefined
	$t = sprintf "%.${decimal}f" , ( $x / $y ) if ( $y > 0 ) ;   # return ratio ONLY if denomitor is not 0
	return $t ;
}

sub decimal
{
	my ( $x , $places ) = @_ ;
	$places = $places || 0 ;
	$val = sprintf "%.${places}f" , $x ;
	return ( $val ) ;
}

## HitRate = x / ( x + y ) . 
sub hitrate 
{
	my ( $x , $y ) = @_ ;
	return 0 if ( $x+$y == 0 ) ;
	$val = sprintf "%.4f" , $x / ( $x + $y ) ;
	return ( $val ) ;
}

sub commafy
{
	my ( $number ) = @_; # with commas, should be "1,234,567" 
		
	# do only the left part
	my ( $lp , $rp ) = split /\./,$number ;
	$lp =~ s/(\d)(?=(\d{3})+(\D|$))/$1\,/g;
	return "$lp.$rp" if ( defined $rp ) ;
	return $lp ;
}

# return the difference in values of 2 hash , $p , $q with same fields @w.  The return result is a total of the differences.
sub sum_of_diff 
{
	my ( $p , $q , @words ) = @_ ;
	my $total = 0 ;
	foreach my $w ( @words ) {
		$total += $q->{$w} - $p->{$w}  ;
	}
	return $total ;
}

sub tmdiff 
{
	my ( $t0 , $t1 ) = @_ ;
	
	# assume time string contains /
	my $datefmt = "mm/dd/yyyy hh:min:ss.ns"  ;

	# if t0 contains hypen , change the / to hypens. . e.g 02-02-2017 16:22:38.970452
	$datefmt =~ s/\//\-/g if ( $t0 =~ m/\-/ ) ;

	my $tm = new MyTime( $datefmt ) ;
	return sprintf "%f" , $tm->diff( $t0 , $t1 ) ;
}

# given a ordered list of columns , return of key=>values in an order hash
sub orderby  {
	my ( $record , @columns ) = @_ ;
	my $H = {} ;
	tie %$H , 'Tie::IxHash' ;
	map { $H->{$_} = $record->{$_} } @columns ;
	return $H ;	
}

# get the difference in values between p and q of the same key, and return a new hash.  Fields to SKIP doing the diff
my $SKIP = {
	'Application handle'	=> 1 , 	'Snapshot timestamp'	=> 1 , 	'FILE'					=> 1 ,	'Application status'	=> 1 , 
	'UOW completion status'	=> 1 , 	'Bufferpool name'		=> 1 ,	'Tablespace name'		=> 1 ,	'Tablename'				=> 1 ,
	'Memory Pool Type'		=> 1 ,
} ;
sub hashdiff  {
	my ( $p , $q ) = @_ ;
	my $H = {} ;
	foreach ( keys %$q ) {
		my $v = $q->{$_} ;
		$H->{$_} = ( exists $SKIP->{$_} ) ?  $q->{$_} :  $q->{$_} - $p->{$_} ;
	}
	return $H ;
}


# Given a hash pointer p, evaluate a string.  E.g.  A = B + C ,  p->{A} = p->{B} + p->{C}
my $LUC = {} ;				# LUC = look up cache
sub evalstr 
{
	my ( $p , $colname , $lookup ) = @_ ;

=begin AUD
	print "Evaluating $colname = $lookup\n" ;
	# look for key fields (kf) and substitute it with value , replace the fields in the formula with actual values
	foreach my $kf ( sort { length($b) <=> length($a) } keys %$p ) {		
		my $dq = quotemeta($kf) ;							# need quote meta to match , some fields has ( or / strings
		$lookup =~ s/$dq/$p->{$kf}/g ; 
	}
=cut

	# if the column does not exist, call parser to get the formula and save it in cache.
	$LUC->{$colname}  = $parser->startrule($lookup) if ( ! exists $LUC->{$colname} ) ;
	$p->{$colname} = eval $LUC->{$colname} ;

	if ( ! defined $p->{$colname} ) {
		print FH "Failed to resolve column = [$colname] , formula = [$lookup]\n" ;
	}
}


# The fields that does not have values, likely a formula.  Resolve it.  Hash the Lookup, so 
# do not need to call parser every invocation.
sub resolve_formula_fields {

	my ( $p , @columns ) = @_ ;

	open FH , "> /tmp/eval.log" ;
	print FH "Columns = " . join ( ' : ' , @columns ) . "\n\n" ;
	# Resolve all the lookup fields.
	foreach my $colname ( @columns ) {
		my $lookup = $cfg->get( "common", $colname ) ;		# get the formula
		evalstr ( $p , $colname , $lookup ) if ( defined $lookup )  ;
	}
	close FH ;
}

# Check to make sure more at least X files is provided.
sub inputcheck
{
    my ( $cnt , $min , $max ) = @_ ;

    if ( $cnt < $min ) {
        printf "Option needs at least $min file, Provided $cnt\n" ;
        exit ;
    }

	if ( defined $max && $cnt > $max ) {
        printf "Option needs at least $min and max $max files. Provided $cnt\n" ;
		exit ;
	}
}


return 1 ;

