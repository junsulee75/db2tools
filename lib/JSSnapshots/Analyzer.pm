package JSSnapshots::Analyzer ;

use JSSnapshots::Cfg ;
use JSSnapshots::Functions qw(commafy ratio hitrate sum_of_diff);
use strict ;
use List::MoreUtils qw(uniq);

my $warn = 1 ;
my $message = {} ;
my $s = "" ;

sub new 
{
	my ( $class , $interval ) = @_ ;
	my $self = () ;
	$self->{INTERVAL} = $interval ;
  	bless ( $self, $class ) ;
  	return $self ;
}

sub set_interval_TBD
{
	my ( $class , $interval ) = @_ ;
	$class->{INTERVAL} = $interval ;
}

sub display_hash
{
	my ( $class , $p , $q , $H ) = @_ ;

	my $interval = $class->{INTERVAL} ;

	foreach my $array ( @$H ) {

		my $hp = $array ;				# hp = hash pointer
		my $w  = $hp->{field} ;			# w = word field

		if ( $w eq 'newline' ) {		# new line
			print "\n" ; 
			next ;
		}

		# check to make sure the field I want exist
		if ( ! exists $p->{$w} ) {
			print "Field [$w] does not exists !!  Check spelling.\n" ;
			exit ;
		}

		my $unit = "" ;
		$unit = "($hp->{unit})" if ( exists $hp->{unit} )  ;

		my $diff = sum_of_diff ( $p , $q , $w ) ;
		printf "\t$w $unit : $p->{$w} to $q->{$w}" ;

		if ( exists $hp->{delta} && $hp->{delta} == 1 ) {
			printf " => %s", commafy($diff) ;
		}

		# cannot commafy.  Once commafy cannot test for high/low value
		if ( exists $hp->{vps} && $hp->{vps} == 1 ) {
			my $vps = int ( $diff / $interval )  ;
			printf " ( %s per second )", commafy($vps) if ( $vps > 0 ) ;
			$hp->{vps} = $vps ;
		}
		print "\n" ;
	}
}

# Provides information about concurrency.
sub concurrency
{
	my ( $class , $title , $p , $q ) = @_ ;
	print "$title\n" ;

	my $H = [
			{ field => 'Locks held currently' , delta => 1 } ,
			{ field => 'Lock waits'   , delta => 0 } ,
			{ field => 'Time database waited on locks (ms)' ,  delta => 1 } ,
			{ field => 'Lock escalations' , delta => 1 } ,
			{ field => 'Lock Timeouts', delta => 1 } ,
			{ field => 'Deadlocks detected' , delta => 1 } ,
	] ;

	display_hash ( $class , $p , $q , $H ) ;
}

# Provide information on the performance of SQL execution
sub sql_performance
{
	my ( $class , $title , $p , $q ) = @_ ;

	print "\n$title\n" ;
	my $H = [
			{ field => 'Rows read' , delta => 1 , vps => 1 } ,
			{ field => 'Rows inserted' , delta => 0 , vps => 1 } ,
			{ field => 'Select SQL statements executed' ,  delta => 1 , vps => 1 } ,
			{ field => 'Update/Insert/Delete statements executed' , delta => 1 , vps => 1 } ,
			{ field => 'Dynamic statements attempted' , delta => 1 , vps => 1 } ,
			{ field => 'Static statements attempted' , delta => 1 , vps => 1 } ,
			{ field => 'Sort overflows' , delta => 1 , vps => 1 } ,
			{ field => 'Commit statements attempted' , delta => 1 , vps => 1 } ,
			{ field => 'newline' } ,
			{ field => 'Data Pages Read' , delta => 1 , vps => 1 } ,
			{ field => 'Index Pages Read' , delta => 1 , vps => 1 } ,
			{ field => 'DataIndexRatio' , unit => '%' } ,
			{ field => 'newline' } ,
	] ;

	display_hash ( $class , $p , $q , $H ) ;

	my $rrrate = $H->[0]->{vps} ;
	printf "\t*** Rows read rate is too high at %s per second\n" , commafy($rrrate)  if ( $rrrate > 1000000 ) ;
	
}

# Provide information about LOBS / CLOBS and 
sub directioperf
{
	my ( $class , $title , $p , $q ) = @_ ;
	
	# get the total sum of differences in direct reads and direct writes. skip if both 0.
	return if ( sum_of_diff ( $p , $q , 'Direct reads' , 'Direct writes' ) == 0 ) ;

	print "\n$title\n" ;
	my $H = [
			{ field => 'Direct reads' , delta => 1 , vps => 1 } ,
			{ field => 'Direct reads elapsed time (ms)' , delta => 1 } ,
			{ field => 'Direct Read Rate' , unit => 'pages/sec' } ,
			{ field => 'newline' } ,
			{ field => 'Direct writes' , delta => 1 , vps => 1 } ,
			{ field => 'Direct write elapsed time (ms)' , delta => 1 } ,
			{ field => 'Direct Write Rate' , unit => 'pages/sec' } ,
			{ field => 'newline'}  ,
	] ;

	display_hash ( $class , $p , $q , $H ) ;
	
=begin AUD
	my $interval = $class->{INTERVAL} ;
	# Dumb inconsistency in snapshot .  Direct reads , Direct reads elapsed time 
	# 'Direct writes' , 'Direct write elapsed time'.  Dumb. The 'Direct write elapsed time' has no 's'
	$p->{'Direct writes elapsed time (ms)'} = $p->{'Direct write elapsed time (ms)'} ;
	$q->{'Direct writes elapsed time (ms)'} = $q->{'Direct write elapsed time (ms)'} ;
	
	foreach my $w ( 'Direct reads' , 'Direct writes' ) {
		my $diff = sum_of_diff ( $p , $q , $w ) ;
		my $vps = int ( $diff / $interval ) ;		# value per second
		printf "\t$w  :  $p->{$w} to $q->{$w}  => %s ( %s per second )\n" , commafy($diff) ,commafy($vps) ;

		my $elapse_time = sum_of_diff ( $p , $q , "$w elapsed time (ms)" ) ; 
		my $t1 = $p->{"$w elapsed time (ms)"} ;
		my $t2 = $q->{"$w elapsed time (ms)"} ;
		my $delta = sum_of_diff ( $p , $q , $w ) ;
		my $vps = ( $elapse_time > 0 ) ?  ( $delta / $elapse_time ) : 0 ;
		
		$s = "" ;
		$s = warnmsg ("LOBS reading/writing less than 3 pages per ms") if ( $vps < 3 ) ;
		printf "\t${s}$w elapsed time $t1 to $t2 => $elapse_time (ms).  $w rate = %.2f pages/ms\n" , $vps ;
	}
=cut

}

# Provides information about logs.  A slow log will result in many COMMIT actives
sub tx_log_perf
{
	my ( $class , $title , $p , $q ) = @_ ;

	print "\n$title\n" ;

	my $H = [
			{ field => 'Log pages read' , delta => 1 , vps => 1 } ,
			{ field => 'Log read time (sec.ns)' , delta => 1 } ,
			{ field => 'Log Read Rate' , unit => 'pages/sec' } ,
			{ field => 'newline'}  ,
			{ field => 'Log pages written' , delta => 1 , vps => 1 } ,
			{ field => 'Log write time (sec.ns)' , delta => 1 } ,
			{ field => 'Log Write Rate' , unit => 'pages/sec' } ,
			{ field => 'newline' } 

	] ;

	display_hash ( $class , $p , $q , $H ) ;

	my $lwr = $q->{'Log Write Rate'} ;
	printf "\t*** Log write rate ( %d ) is less than 2500 pages per second\n" , $lwr if ( $lwr < 2500 )  ;
}


# Provide information about the performance of IO server.
sub ioserver
{
	my ( $class , $title , $p , $q  ) = @_ ; 
	
	my $H = [
			{ field => 'Total Physical Reads' , unit => 'pages' , delta => 1 , vps => 1 } ,
			{ field => 'Physical Read Time'   , unit => 'millisec' , delta => 0 , vps => 0 } ,
			{ field => 'Physical Read Rate'   , unit => 'pages/sec' , delta => 0 , vps => 0 } ,
			{ field => 'newline' } ,			  
			{ field => 'Async Physical Reads' , unit => 'pages' , delta => 1 , vps => 1 } ,
			{ field => 'Async Read Time' 	  , unit => 'millisec' , delta => 0 , vps => 0 } ,
			{ field => 'Async Read Rate' 	  , unit => 'pages/sec' , delta => 0 , vps => 0 } ,
			{ field => 'newline' } ,
			{ field => 'Sync Physical Reads' , unit => 'pages' , delta => 1 , vps => 1 } ,
			{ field => 'Sync Read Time'		 , unit => 'millisec' , delta => 0 , vps => 0 } ,
			{ field => 'Sync Read Rate'		 , unit => 'pages/sec' , delta => 0 , vps => 0 } ,
			{ field => 'newline' } ,
			{ field => 'Async Ratio'		, unit => '%' , delta => 1 , vps => 0 } ,
	] ;

	my $interval = $class->{INTERVAL} ;
	print "\n$title\n" ;

	display_hash ( $class , $p , $q , $H ) ;

	printf "\t*** Async ratio = %.2f %% is less than 80 %\n" , $q->{'Async Ratio'}  if ( $q->{'Async Ratio'} < 80 ) ;

}

# Provide information about the performance of IO server.
sub iocleaner
{
	my ( $class , $title , $p , $q  ) = @_ ; 
	
	my $H = [
			{ field => 'Total Physical Writes' , unit => 'pages' , delta => 1 , vps => 1 } ,
			{ field => 'Physical Write Time' } ,
			{ field => 'Physical Write Rate' , unit => 'pages/sec' } ,
			{ field => 'No Victim' , delta => 1  , vps =>1 } ,
			{ field => 'LSNGAP Trigger' , delta => 1  , vps =>1 } ,
			{ field => 'Threshold Trigger' , delta => 1  , vps =>1 } ,
			{ field => 'Steal Trigger' , delta => 1  , vps =>1 } ,
			{ field => 'newline' }
	] ;

	my $interval = $class->{INTERVAL} ;
	print "\n$title\n" ;

	display_hash ( $class , $p , $q , $H ) ;

	printf "\t*** Low write rate , less than 2000 pages per second\n" if ( $q->{'Physical Write Rate'} < 10000 ) ; 
	my $novictim = $H->[3]->{vps} ;
	printf "\t*** High 'No Victim' (%s).  Consider setting registry DB2_USE_ALTERNATE_PAGE_CLEANING=ON\n",commafy($novictim) if ( $novictim > 2000 ) ; 

}


# Provide information on the bufferpool hit ratio.
sub bufferpool
{
	my ( $class , $title , $p , $q  ) = @_ ;
		
	my $warnnbr ;

	# skip this if there is no read activity on this BP
	return if ( sum_of_diff ( $p , $q , 'Total Physical Reads' , 'Total Logical Reads' ) == 0  ) ;
	
	my $H = [
			{ field => 'Total Physical Reads' , unit => 'pages' , delta => 1 , vps => 1 } ,
			{ field => 'Total Logical Reads' , unit => 'pages' , delta => 1 , vps => 1 } ,
			{ field => 'BP Hit Ratio' , unit => '%' } ,
			{ field => 'newline' } ,
			{ field => 'Temp Physical Reads' ,  delta => 1 , vps => 1  } ,
			{ field => 'Temp Logical Reads'  ,  delta => 1 , vps => 1  } ,
			{ field => 'Temp BP Hit Ratio' , unit => '%' } ,
			{ field => 'newline' } ,
	] ;

	print "\n$title\n" ;
	display_hash ( $class , $p , $q , $H ) ;

	print  "\t*** BP hit ratio less than 95%\n" if ( $q->{'BP Hit Ratio'} < 95 ) ;
	print  "\t*** Temp BP hit ratio less than 95%\n" if ( $q->{'Temp BP Hit Ratio'} < 95 ) ;

	# Total Physical Reads
	my $vps  = $H->[0]->{vps} ;	 
	printf "\t*** High physical reads at %s per second\n" , commafy($vps) if ( $vps > 300 ) ;
}


sub pkgcache
{
	my ( $class , $title , $p , $q ) = @_ ;
	
	my $H = [
			{ field => 'Package cache lookups' , delta => 1 , vps => 1 } ,
			{ field => 'Package cache inserts' , delta => 1 , vps => 1 } ,
			{ field => 'Package cache high water mark (Bytes)'   , delta => 1 , vps => 1 } ,
			{ field	=> 'Package Efficiency' , unit => '%' } ,
			{ field => 'newline' } ,
			{ field => 'Catalog cache lookups' , delta => 1 , vps => 1 } ,
			{ field => 'Catalog cache inserts' , delta => 1 , vps => 1 } ,
			{ field => 'Catalog cache high water mark' , delta => 1 , vps => 1 } ,
			{ field => 'Catalog Efficiency' , unit => '%' } ,
			{ field => 'newline' } ,
	] ;

	print "\n$title\n" ;
	display_hash ( $class , $p , $q , $H ) ;
}

return 1 ;

