package db2snap ;
use CGI ;
use Fcntl; 
use Data::Dumper;
use xls ;

use Cwd ;
use Switch;
use JSSnapshots::Database ;
use JSSnapshots::Bufferpool ;
use JSSnapshots::Tablespace ;
use JSSnapshots::Table ;
use JSSnapshots::Application ;
use JSSnapshots::Html_Table ;
use JSSnapshots::DynSQL ;
use JSSnapshots::Cfg ;

# -- Version 2 - 16 Jan
# -- DS option 
# --		Change Page write/sec for DS to show time for each write call, instead of calls per second
# -- Others
# --    Default rate for cache set to 1 instead of 0 if physical read/write is 0

# This package has to do with reading in get snapshot for all, and parsing thru sections of the snapshots.

sub new 
{
	my ( $class ) = @_ ;

  	my $self = () ;
	$self->{MYTABLE} = new JSSnapshots::Html_Table() ;
  	bless ( $self, $class ) ;
  	return $self ;
}

sub database 
{
	my ( $class , $opt , @filelist ) = @_ ;
		
	if ( $opt eq 'S' ) {
		$class->{XLS} = new xls("Database.xlsx")  ;
		$class->{SECTION} = "dbsnap" ;
			
		my $db = new JSSnapshots::Database( $class->{XLS} ) ;
		$db->summary(@filelist) ;		# write to XLS file
		$db->report(@filelist) ;		# write a report to screen
	}
}

sub tablespace
{
		my ( $class , @filelist ) = @_ ;
		
		$class->{XLS} = new xls("Tablespace.xlsx") ;
		$class->{SECTION} = "tablespace" ;
		
		my $tbsp = new JSSnapshots::Tablespace( $class->{XLS} ) ;		
		$tbsp->summary(@filelist) ;
}

sub tablespace_progress
{
	my ( $class , $tbspc , @filelist ) = @_ ;
	$tbspc =~ s/^n// ;		# strip away the leading h
	my $tbsp = new JSSnapshots::Tablespace() ;
	$tbsp->progress ( $tbspc , @filelist ) ;
}

sub bufferpool 
{
		my ( $class , @filelist ) = @_ ;
		
		$class->{XLS} = new xls("Bufferpool.xlsx") ;
		$class->{SECTION} = "bufferpool" ;
		my $bp = new JSSnapshots::Bufferpool( $class->{XLS} ) ;
		$bp->summary(@filelist) ;
}

sub bufferpool_progress
{
		my ( $class , $bpname , @filelist ) = @_ ;
		
		$bpname =~ s/^n// ;		# strip away the leading h
		my $bp = new JSSnapshots::Bufferpool() ;
		$bp->progress ( $bpname , @filelist) ;
}

sub table
{
	my ( $class , @filelist ) = @_ ;
	$class->{XLS} = new xls("Table.xlsx") ;
	$class->{SECTION} = "table" ;
		
	my $tab = new JSSnapshots::Table( $class->{XLS} ) ;
	$tab->summary(@filelist) ; 		
}

sub table_progress
{
	my ( $class , $tabname , @filelist ) = @_ ;
	$tabname =~ s/^n// ;		# strip away the leading h
	my $tab = new JSSnapshots::Table() ;
	$tab->progress ( $tabname , @filelist ) ;
}

sub app_summary
{
	my ( $class , @filelist ) = @_ ;
		
	$class->{XLS} = new xls("Application.xlsx") ;
	my $app = new JSSnapshots::Application( $class->{XLS} ) ;
	$app->summary(@filelist) ;
}

sub app_executing
{
	my ( $class , @filelist ) = @_ ;

	my $app = new JSSnapshots::Application() ;
	$app->executing(@filelist) ;
}

sub app_handle
{
	my ( $class , $handle , @filelist ) = @_ ;

	$handle =~ s/^h// ;		# strip away the leading h
	foreach my $fp ( @filelist ) {
		print "FILE = $fp->{FILE} ,  $fp->{'Snapshot timestamp'} , Handle = $handle\n\n"  ;
		for ( my $i = 0 ;;  $i++ ) {
			my $p = $fp->record ( 'APPLICATION' , $i ) ;
			if ( $p->{'Application handle'} ==  $handle ) {
				$fp->fulltext ( 'APPLICATION' , $p->{INDEX} ) ;
				last ;
			}
		}
	}
}

sub app_progress
{
	my ( $class , $handle , @filelist ) = @_ ;
	$handle =~ s/^p// ;		# strip away the leading h
	my $app = new JSSnapshots::Application( $class->{MYTABLE} ) ;
	$app->progress ( $handle , @filelist ) ;
}

sub app_lockwaits
{
		my ( $class , @filelist ) = @_ ;
		my $app = new JSSnapshots::Application( $class->{MYTABLE} ) ;
		$app->waiter(@filelist) ;
}

sub app_regex
{
		my ( $class , $expr , @filelist ) = @_ ;
		my $app = new JSSnapshots::Application( $class->{MYTABLE} ) ;
		$app->regex( $expr , @filelist) ;
}

sub app_timediff
{
		my ( $class , @filelist ) = @_ ;
		$class->{XLS} = new xls("AppTime.xlsx") ;
		my $app = new JSSnapshots::Application( $class->{XLS} ) ;
		$app->timediff( @filelist ) ;
}

sub app_summary
{
	my ( $class , @filelist ) = @_ ;
		
	$class->{XLS} = new xls("Application.xlsx") ;
	my $app = new JSSnapshots::Application( $class->{XLS} ) ;
	$app->summary(@filelist) ;
}

sub dynsql
{
	my ( $class , $opt_S , @filelist ) = @_ ;
	my $dynsql = new JSSnapshots::DynSQL() ;


	switch ( $opt_S ) {
	
		case 's'   		{ 
			$class->{XLS} = new xls("DynSQL.xlsx") ;
			my $dynsql = new JSSnapshots::DynSQL( $class->{XLS} ) ;
			$dynsql->summary(@filelist) 
		}
		case 't10' 		{ 
			my $dynsql = new JSSnapshots::DynSQL() ;
			$dynsql->top10 ( @filelist ) ;
		} 
		case /e(\d+)/  	{ 
			$opt_S =~ m/e(\d+)/ ;
			my $entry = $1 ;
			my $dynsql = new JSSnapshots::DynSQL() ;
			$dynsql->show_record ( $entry , @filelist ) ;
		} ;
			
	}


}


sub complete
{
	my ( $class ) = @_ ;

	my $cfg = new Cfg() ; 
	my $defn = $cfg->Section( $class->{SECTION} ) ;
	$class->{XLS}->close() if ( defined $class->{XLS} ) ;
}


return 1 ;
