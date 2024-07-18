package Snapshots::Tablespace ;

use Snapshots::Cfg ;
use Snapshots::Functions qw(ratio tmdiff hitrate orderby hashdiff resolve_formula_fields commafy inputcheck);
use strict ;
use xls ;
use List::MoreUtils qw(uniq);

my $section = "tablespace" ;
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
	$xls->worksheet("Summary");
	my @columns = $cfg->List ( $section , "columns" ) ;		# get column names
	
	# Go through each tablespace and write to excel
	my $xlsrow = 1;
	foreach my $tbspc ( sort keys %$J ) {
		my $newtable = 1 ;
		foreach my $h ( @{ $J->{$tbspc} } ) {
			resolve_formula_fields ( $h , @columns ) ;
			my $H = orderby ( $h , @columns ) ;
			$H->{'Tablespace name'} = "" if ( $newtable == 0 ) ;
			$class->flush_to_xls ( $xlsrow , $H ) ;
			$xlsrow++;
			$newtable = 0 ;
		}
	}
}

sub print_summary_delta
{
	my ( $class , $J ) = @_ ;
	
	my $xls = $class->{XLS} ;
	
	# Go through each tablespace, find the diff and write to excel
	$xls->worksheet("Summary_delta");
	my @delta  = $cfg->List ( $section , "delta" ) ;		# get column names
	
	my $xlsrow = 1;
	foreach my $tbspc ( sort keys %$J ) {
		my @arr = @{ $J->{$tbspc} } ;
		my $new = 1 ;
		for ( my $i = 1 ; $i < @arr ; $i++ ) {
			# get the differences in values
			my $H = hashdiff ( $arr[$i-1], $arr[$i] ) ;
			resolve_formula_fields ( $H , @delta ) ;
			# $q has ALL fields and unordered.  i only want some fields and in my order	
			$H = orderby ( $H , @delta ) ;
			
			$H->{'Tablespace name'} = "" if ( $new == 0 ) ;
			$class->flush_to_xls ( $xlsrow , $H ) ;
			$xlsrow++;
			$new = 0 ;
		}
		$xlsrow++  ;			 # add a blank row so the tablespace names is aligned with the summary XLS.
	}
	
}

sub summary
{
	my ( $class , @filelist  ) = @_ ;
	
	inputcheck( scalar @filelist , 2 ) ;		# need at least 2 files

	my $J = {} ;
	foreach my $fp ( @filelist  ) {
			
		for ( my $tbspcnum = 0 ;; $tbspcnum++ ) {
		
			# If this field does not exist, means hit end of tablespaces and exit
			my $p = $fp->record ( 'TABLESPACE' , $tbspcnum ) ;
			# print Data::Dumper->Dump ( [ $p ] , [ 'P' ] ) ; exit ;
			
			last if ( ! exists $p->{'Tablespace name'} ) ;
			
			# skip system spaces
			# next if  ( $p->{'Tablespace name'} =~ m/^SYS/  ) ;
			
			print "Doing File = $p->{FILE} , Tablespace $tbspcnum ($p->{'Tablespace name'})\n" ;
			
			# J is of the form : J->{Tablespace name} -> an array of snapshot records
			my $tbspcid = $p->{'Tablespace ID'} ;
			push ( @{ $J->{$tbspcid}  } , $p ) ;
		}
	}
	
	$class->print_summary ( $J ) ;
	$class->print_summary_delta ( $J ) if ( @filelist > 1 ) ;
}

sub progress
{
	my ( $class , $tbspc , @filelist  ) = @_ ;
	
	$tbspc = uc($tbspc) ;		# tablename is always in uppercase

    my @columns = $cfg->List ( $section , "progress" ) ;     # get column names
    my $PREV ;      #   previous value holder

	foreach my $fp (  @filelist ) {
	
		my $p = $fp->record_by_name ( 'TABLESPACE' , 'Tablespace name' , $tbspc ) ;
		next if ( ! %$p ) ;		# skip if empty hash

		resolve_formula_fields ( $p , @columns ) ;

		print "Tabspace name = $tbspc , File = $p->{FILE} , Snapshot timestamp = $p->{'Snapshot timestamp'}\n" ;

        foreach my $field ( @columns ) {
        	printf "\t$field = $p->{$field} ( %s )\n" , commafy ( $p->{$field} - $PREV->{$field} ) ;
            $PREV->{$field} = $p->{$field} ;
        }
        print "\n" ;
	}
	
}
return 1 ;

