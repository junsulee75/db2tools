package JSSnapshots::Bufferpool ;

use JSSnapshots::Cfg ;
use JSSnapshots::Functions qw(ratio hitrate commafy sum_of_diff tmdiff orderby hashdiff resolve_formula_fields inputcheck );
use List::MoreUtils qw(uniq);
use strict ;

my $section = "bufferpool" ;
my $cfg = new Cfg() ; 

sub new 
{
	my ( $class , $xls  ) = @_ ;
	
  	my $self = () ;
	$self->{XLS} = $xls ;
  	bless ( $self, $class ) ;
  	return $self ;
}

# Set options
sub setopt {
	my ( $class , $opt ) = @_ ;
	foreach my $k ( keys %$opt ) {
		$class->{$k} = $opt->{$k} 
	}
}

# Flush the values of $p to column number.  Set the comment with the text of the formula if the field is a lookup field.  Bold/red if it is header, and just red if it is value.
sub flush_to_xls
{
	my ( $class , $xlsrow , $p ) = @_ ;
	my $xls = $class->{XLS} ;
	
	my $xlscol = 0 ;
	foreach my $key ( keys %$p ) {
		$xls->write ( 0 , $xlscol , $key ) ;				# write the column header
		my $lookup = $cfg->get( "common", $key ) ;			# test if this field is a lookup/formula field
		if ( defined $lookup ) {
			$xls->comment ( 0 , $xlscol , $lookup ) ;							# insert comment
			$xls->setformat ( 0 , $xlscol , { color => 'red' , bold => 1 } ) ;	# bold/red for the comment
			$xls->setformat ( $xlsrow , $xlscol , { color => 'red' } ) ;		# red for the value
		}
		# print "Writing out key = $key , [$xlsrow,$xlscol] , Value = $p->{$key}\n" ;
		$xls->write ( $xlsrow , $xlscol++ , $p->{$key} ) ;
	}
}

sub print_summary
{
	my ( $class , $J ) = @_ ;
	
	my $xls = $class->{XLS} ;
	$xls->worksheet("Summary");
	my @columns = $cfg->List ( $section , "columns" ) ;		# get column names
	
	# Go through each bufferpool and write to excel
	my $xlsrow = 1;
	foreach my $bpname ( sort keys %$J ) {
		my $newpool = 1 ;
		foreach my $h ( @{ $J->{$bpname} } ) {
			resolve_formula_fields ( $h , @columns ) ;				# resolve formula fields
			my $H = orderby ( $h , @columns ) ;						# get an ordered list
			$H->{'Bufferpool name'} = "" if ( $newpool == 0 ) ;		# make it look nice in excel
			$class->flush_to_xls ( $xlsrow , $H ) ;					# write out hash values to row
			$xlsrow++;
			$newpool = 0 ;
		}
	}
}

sub print_summary_delta
{
	my ( $class , $J ) = @_ ;
	
	my $xls = $class->{XLS} ;
	
	# Go through each buffer pool , find the diff and write to excel
	$xls->worksheet("Summary_delta");
	my @delta  = $cfg->List ( $section , "delta" ) ;		# get column names

	my $xlsrow = 1;
	foreach my $bpname ( sort keys %$J ) {
		my @arr = @{ $J->{$bpname} } ;
		my $newpool = 1 ;
		for ( my $i = 1 ; $i < @arr ; $i++ ) {
			# get the differences in values
			my $H = hashdiff ( $arr[$i-1], $arr[$i] ) ;			# get the difference between this and previous sample
			resolve_formula_fields ( $H , @delta ) ;			# resolve formula fields
			$H = orderby ( $H , @delta ) ;						# get an ordered list
			
			$H->{'Bufferpool name'} = "" if ( $newpool == 0 ) ;	# make it look nice in excel
			$class->flush_to_xls ( $xlsrow , $H ) ;				# write out hash values to row
			$xlsrow++;
			$newpool = 0 ;
		}
		$xlsrow++  ;	# add a blank row so the tablespace names is aligned with the summary XLS.
	}
}

sub summary
{
	my ( $class , @filelist  ) = @_ ;

	inputcheck( scalar @filelist , 2 ) ;       # need at least 2 files

	my $J = {} ;
	foreach my $fp ( @filelist ) {
		for ( my $poolnum = 0 ;; $poolnum++ ) {
	
			# If this field does not exist, means hit end of buffer pools.
			my $p = $fp->record ( "BUFFERPOOL" , $poolnum ) ;
			last if ( ! exists $p->{'Bufferpool name'} ) ;
			
			print "Doing bufferpool $poolnum ($p->{'Bufferpool name'}) , File = $p->{FILE}\n" ;
			
			# J is of the form : J->{Tablespace name} -> an array of snapshot records
			my $bpname = $p->{'Bufferpool name'} ;
			push ( @{ $J->{$bpname}  } , $p ) ;
		}
	}

	$class->print_summary ( $J ) ;
	$class->print_summary_delta ( $J ) if ( @filelist > 1 ) ;
	
}

sub progress
{
    my ( $class , $bpname , @filelist  ) = @_ ;

    $bpname = uc($bpname) ;       # tablename is always in uppercase

    my @columns = $cfg->List ( $section , "progress" ) ;     # get column names
    my $PREV ;      #   previous value holder

    foreach my $fp (  @filelist ) {

        my $p = $fp->record_by_name ( 'BUFFERPOOL' , 'Bufferpool name' , $bpname  ) ;
        next if ( ! %$p ) ;     # skip if empty hash

        resolve_formula_fields ( $p , @columns ) ;

        print "Bufferpool name = $bpname , File = $p->{FILE} , Snapshot timestamp = $p->{'Snapshot timestamp'}\n" ;

        foreach my $field ( @columns ) {
            printf "\t$field = $p->{$field} ( %s )\n" , $p->{$field} - $PREV->{$field} ;
            $PREV->{$field} = $p->{$field} ;
        }
        print "\n" ;
    }

}


return 1 ;

