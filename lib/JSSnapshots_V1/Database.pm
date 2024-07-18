package JSSnapshots::Database;
use JSSnapshots::Analyzer ;
use JSSnapshots::Cfg ;
use JSSnapshots::Functions qw(ratio hitrate commafy sum_of_diff tmdiff delta orderby hashdiff resolve_formula_fields inputcheck);
use strict;

my $section = "database" ;
my $cfg = new Cfg() ;

sub new {
    my ( $class, $xls ) = @_;

    my $self = ();
	# $self->{SECTION} = "dbsnap" ;
    $self->{XLS} = $xls;
    bless( $self, $class );
    return $self;
}

# Flush the values of $p to column number
sub flush_to_xls
{
	my ( $class , $colnum , $p ) = @_ ;
	
	my $xls = $class->{XLS} ;
	my $row = 0 ;
	foreach my $key ( keys %$p ) {
		$xls->write ( $row , 0 , $key ) ;
		my $lookup = $cfg->get( "common", $key ) ;
		if ( defined $lookup ) {
			$xls->comment ( $row , 0 , $lookup ) ;
			$xls->setformat ( $row , 0 , { color => 'red' , bold => 1 } ) ;
			$xls->setformat ( $row , $colnum , { color => 'red' } ) ;
		}
		# $p->{$key} = commafy($p->{$key}) if ( $p->{$key} > 1000 ) ;
		$xls->write ( $row++ , $colnum , $p->{$key} ) ;
	}
}

# Write the data to XLS spreadsheet
sub summary {

    my ( $class, @filelist ) = @_;

	inputcheck( scalar @filelist , 2 ) ;		# need at least 2 files

    my $debug = $class->{DEBUG};

    my $xls = $class->{XLS};
    $xls->worksheet("Summary");

	# write out the column names on row 0 and bold/red it if it is a computed field.  Them comment is the formula
    # Each handle is a pointer to a snapshot file
	my @columns = split /\s+,\s+/ , $cfg->get ( $section , "columns" ) ;
	
    for ( my $colnum = 0 ; $colnum <  @filelist ; $colnum++ ) {

		# get the database snapshot record for each file
		my $q =  $filelist[$colnum]->record( "DATABASE" , 0 ) ;

		# resolve derived fields
		resolve_formula_fields ( $q , @columns ) ;

		# $q has ALL fields and unordered.  i only want some fields and in my order	
		my $H = orderby ( $q , @columns ) ;
		
		# flush this column to XLS
		$class->flush_to_xls( $colnum+1 , $H)  ;
	}
	
	$xls->worksheet("Summary-delta");
	
	my @delta = split /\s+,\s+/ , $cfg->get ( $section , "delta" ) ;

	for my $colnum ( 1 .. @filelist-1 ) {
			
		# T0 is previous snapshot , # T1 is current snapshot
		my $t0 = $filelist[$colnum-1]->record ( "DATABASE" , 0 , 1 ) ;
		resolve_formula_fields ( $t0 , @delta ) ;

		my $t1 = $filelist[$colnum]->record ( "DATABASE" , 0 , 1 ) ;
		resolve_formula_fields ( $t1 , @delta ) ;

		# get the differences in values
		my $H = hashdiff ( $t0, $t1 ) ;
		
		# $q has ALL fields.  i only want some fields and in my order	
		my $H = orderby ( $H ,  @delta ) ;
		
		# flush this column to XLS
		$class->flush_to_xls( $colnum , $H)  ;
	}

	
}

sub report
{
	my ( $class, @filelist ) = @_;
	
	inputcheck( scalar @filelist , 2 ) ;		# need at least 2 files

	my $firstfp = $filelist[0] ;
	my $lastfp  = $filelist[@filelist-1] ;

	my @columns = split /\s+,\s+/ , $cfg->get ( $section , "columns" ) ;

	# p is the first record , q is the last record
	my $p = $firstfp->record ( "DATABASE" , 0 ) ;
	# resolve derived fields
	resolve_formula_fields ( $p , @columns ) ;
		
	my $q = $lastfp->record ( "DATABASE" , 0 ) ;
	# resolve derived fields
	resolve_formula_fields ( $q , @columns ) ;
	
	my $interval = tmdiff ( $p->{'Snapshot timestamp'} , $q->{'Snapshot timestamp'} ) ; 
	
	my $analyzer = new JSSnapshots::Analyzer ( $interval ) ;
	
	print "Using sample files :\n\t$p->{FILE} ( $p->{'Snapshot timestamp'} ) and \n\t$q->{FILE} ( $q->{'Snapshot timestamp'} ) , Interval = $interval seconds\n\n" ;
	$analyzer->concurrency( "Concurrency" , $p , $q ) ;
	$analyzer->bufferpool ( "Buffer pool performance" , $p , $q ) ;
	$analyzer->ioserver( "IO server / prefetcher performance" , $p , $q ) ;
	$analyzer->iocleaner( "IO cleaner performance" , $p , $q ) ;
	$analyzer->directioperf ( "Backup , CLOBS , BLOBS processing" , $p , $q ) ;
	$analyzer->tx_log_perf ( "Transaction log performance" , $p , $q ) ;
	$analyzer->pkgcache ( "Package / Catalog Cache Performance" , $p , $q ) ;
	$analyzer->sql_performance ( "SQL Performance" , $p , $q ) ;
}

sub add_mem_type
{
	my ( $fp ) = @_ ;
	my $H = { FILE => $fp->{FILE} , 'Snapshot timestamp' => $fp->{'Snapshot timestamp'} } ;
	
	# Aggregate the memory usage by different types
	for ( my $i = 0  ;; $i++ ) {
		
		my $p = $fp->record ( 'DATABASE_MEMORY' , $i ) ;
			
		last if ( ! exists $p->{'Memory Pool Type'} ) ;
		
		my $type_of_memory = $p->{'Memory Pool Type'} ;
		my $sz = $p->{'Current size (bytes)'} ;
		$H->{$type_of_memory} += $sz ;
		
	}
	
	return $H ;
		
}

return 1;

