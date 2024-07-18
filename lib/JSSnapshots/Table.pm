package JSSnapshots::Table ;

use JSSnapshots::Cfg ;
use JSSnapshots::Functions qw(ratio hitrate orderby hashdiff resolve_formula_fields inputcheck);
use strict ;
use List::MoreUtils qw(uniq);

=pod

=head1 VERSION
	Version 	: $Revision: 59 $
	Last modified 	: $Date: 2014-05-09 11:49:37 +1000 (Fri, 09 May 2014) $
	URL		: $HeadURL: file:///D:%5CSVN/PerlMod/Snapshots/Table.pm $ ;

=cut

my $section = "table" ;
my $cfg = new Cfg() ; 

sub new 
{
	my ( $class , $xls  ) = @_ ;
	
  	my $self = () ;
	# my $section = "dbsnap" ;
	$self->{XLS} = $xls ;
  	bless ( $self, $class ) ;
  	return $self ;
}

# Flush the keys/values of $p to column number. 
sub flush_to_xls
{
	my ( $class , $xlsrow , $p ) = @_ ;
	my $xls = $class->{XLS} ;
	
	my $xlscol = 0 ;
	foreach my $key ( keys %$p ) {
	
		$xls->write ( 0 , $xlscol , $key ) ;				# write the column header
		my $lookup = $cfg->get( "common", $key ) ;			# test if this field is a lookup/formula field
		if ( defined $lookup ) {
			$xls->comment ( 0 , $xlscol , $lookup ) ;								# insert comment
			$xls->setformat ( 0 , $xlscol , { color => 'red' , bold => 1 } ) ;		# bold/red for the comment
			$xls->setformat ( $xlsrow , $xlscol , { color => 'red' } ) ;			# red for the value
		}
		# print "Writing out key = $key , [$xlsrow,$xlscol] , Value = $p->{$key}\n" ;
		$xls->write ( $xlsrow , $xlscol++ , $p->{$key} ) ;
	}
}

sub print_summary
{
	my ( $class , $J ) = @_ ;
	
	my $xls = $class->{XLS} ;
	
	# Flush J to 'summary' worksheet
	$xls->worksheet("Summary");
	my @columns = ( 'Tablename' , $cfg->List ( $section , "columns" ) ) ;		# get column names
	my $row = 1 ;
	foreach my $table ( sort keys %$J ) {
		my $newtable = 1 ;
		foreach my $h ( @{ $J->{$table} } ) {
			resolve_formula_fields ( $h , @columns ) ;
			my $H = orderby ( $h , @columns ) ;
			$H->{'Tablename'} = "" if ( $newtable == 0 ) ;
			$class->flush_to_xls ( $row , $H ) ;
			$row++;
			$newtable = 0 ;
		}
	}
	
}

sub print_summary_delta
{
	my ( $class , $J ) = @_ ;
	
	my $xls = $class->{XLS} ;
	
	# Flush J to 'summary' worksheet
	$xls->worksheet("Summary_delta");
	my @delta = ( 'Tablename' , $cfg->List ( $section , "delta" ) ) ;		# get column names
	my $row = 1;
	foreach my $table ( sort keys %$J ) {
		my @arr = @{ $J->{$table} } ;
		my $s = @arr ;
		my $newtable = 1 ;
		for ( my $i = 1 ; $i < @arr ; $i++ ) {
			# get the differences in values
			my $H = hashdiff ( $arr[$i-1], $arr[$i] ) ;
			resolve_formula_fields ( $H , @delta ) ;
			$H = orderby ( $H , @delta ) ;
			$H->{'Tablename'} = "" if ( $newtable == 0 ) ;
			# print Data::Dumper->Dump ( [ $H ] , [ "Flushing row $row" ] ) ;
			$class->flush_to_xls ( $row , $H ) ;
			$row++;
			$newtable = 0 ;
		}
		$row++ ;
	}
}

sub summary {

	my ( $class , @filelist  ) = @_ ;
	
	inputcheck( scalar @filelist , 2 ) ;       # need at least 2 files
	my $J = {} ;
	foreach my $fp (  @filelist ) {
	
		for ( my $tableid = 0 ;; $tableid++ ) {
			
			# get the table snapshot record for each file
			my $p = $fp->record ( "TABLE" , $tableid ) ;
			
 			last if ( ! exists $p->{'Table Schema'} ) ;
			
			# skip system files
			# next if ( $p->{'Table Schema'} =~ m/^SYS/ ) ;
			
			$p->{'Tablename'} = "$p->{'Table Schema'}.$p->{'Table Name'}" ;
			print "Doing File = $p->{FILE} , TABLE = $p->{'Tablename'}\n" ;
			
			# J is of the form : J->{tablename} -> an array of snapshot records
			my $tabname = $p->{'Tablename'} ;
			push ( @{ $J->{$tabname}  } , $p ) ;
			
		}
	}
	
	$class->print_summary ( $J ) ;
	$class->print_summary_delta ( $J ) if ( @filelist > 1 ) ;
}

sub progress
{
	my ( $class , $tabname , @filelist  ) = @_ ;
	
	$tabname = uc($tabname) ;		# tablename is always in uppercase
    my @columns = $cfg->List ( $section , "progress" ) ;     # get column names
    my $PREV ;      #   previous value holder

	foreach my $fp (  @filelist ) {
	
		my $p = $fp->record_by_name ( 'TABLE' , 'Table Name'  , $tabname ) ;
 		next if ( ! %$p ) ;     # skip if empty hash

		print "Tabname = $p->{'Table Schema'}.$p->{'Table Name'}, File = $p->{FILE} , Snapshot timestamp = $p->{'Snapshot timestamp'}\n" ;
        foreach my $field ( @columns ) {
            printf "\t$field = $p->{$field} ( %s )\n" , $p->{$field} - $PREV->{$field} ;
            $PREV->{$field} = $p->{$field} ;
        }
        print "\n" ;
	}
	
}
return 1 ;

