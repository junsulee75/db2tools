#!/usr/bin/perl

use jsdb2diag ;
use Getopt::Std ;
use LibFunc qw( first_time_stamp last_time_stamp ) ;

=pod

=head1 VERSION

    Version 		: $Revision: 59 $
    Last modified 	: $Date: 2014-05-09 11:49:37 +1000 (Fri, 09 May 2014) $
    URL			: $HeadURL: file:///D:%5CSVN/PerlMod/Snapshots/Database.pm $ ;

=head1 DESCRIPTION

    This program parses the db2diag.log file.  It has features which the command db2diag does not provide.
    Run with no arguments for syntax.

=cut

sub usage {

print <<AUD ;

	jsgrab.pl [-f <filenames>] [-rvsn]
	
	-r : X,[-]Y , show Y lines starting at X , or before X
	-R : X,Y - show lines X to Y
	-s : search regular expression , add -v to ignore expression
	-l : list the timestamps in the provided files
	-p : paragraph with regular expression, add -v to ignore paragraph
	-h : show top X lines
	-t : show tail X lines
	-B : search begins after this pattern
	-E : search ends on this pattern
	-V : verbose , show more messages
	-C : count only
	
	-n : show line number
	# -d : date in format yyyy-mm-dd

	Event strings that can be used with -s

	log archival	=>  started.*archive 
	back up		=>  starting.*backup , backup.*completed
	activate	=>  FirstConnect , TermDbConnect
	cfg changes	=>  cfg.*db
	hadr primary	=>  Primary.*Started. HADR state set to
	
AUD

	exit ;
}

usage if ( @ARGV == 0 ) ;

%options=();
getopts ( 'B:E:Tit:h:s:f:p:r:R:S:vVnCl' ) ;

@FILELIST = () ;
# Get the files in sorted order
if ( defined $opt_f ) {

	foreach $fn ( glob "$opt_f" )  {
	
		if ( -d $fn  ) {
			print "Skipping directory $fn\n" ;
			next ;
		}
	
		if ( $fn =~ m/tar|gz|rar|jpg/ ) {
			print "Skipping binary file $fn\n" ;
			next ;
		}
		my $begin = first_time_stamp($fn) ;
		$H{$begin} = $fn ;
	}

	# Sort according to the start time of the db2diag.log
	foreach ( sort keys %H ) {
		push ( @FILELIST , $H{$_} ) ;
	}
}
else {
	# Use STDIN if there is no files specified.
	$opt_f = "stdin"  ;
}

# Open file, process, and close.
foreach $fn ( @FILELIST ) {

	if ( defined $opt_l ) {
		my $begin = first_time_stamp($fn) ;
		my $end   = last_time_stamp($fn) ;
		my $size  = -s $fn ;
		#printf "FN=%-30s  ( $begin to $end )\n" , "$fn ( $size )" ;
		# junsu	$size to MB
		printf "%-30s  ( $begin to $end )\n" , "$fn ( $size bytes )" ;
		next ;
	}
		
		
	$logfile = new jsdb2diag ( $fn ) or die "cannot open $fn" ;
	$logfile->setopt ( { LINENBR => 1 }  ) if ( defined $opt_n ) ;
	$logfile->setopt ( { VERBOSE => 1 }  ) if ( defined $opt_V ) ;
	$logfile->setopt ( { COUNTONLY => 1 } ) if ( defined $opt_C ) ;
	
	print "[   -------  $fn  --------------   ]\n" if ( defined $opt_V ) ;

	#  set the position to begin the search 
	$logfile->setskip($opt_S) if ( defined $opt_S ) ;
	$logfile->setbegin($opt_B) if ( defined $opt_B ) ;
	$logfile->setend($opt_E) if ( defined $opt_E ) ; 

	$logfile->head($opt_h) if ( defined $opt_h ) ;
	$logfile->tail($opt_t) if ( defined $opt_t ) ;
	
	$logfile->search($opt_s,$opt_v) if ( defined $opt_s ) ;
	$logfile->range($opt_r) if ( defined $opt_r ) ;
	$logfile->Range($opt_R) if ( defined $opt_R ) ;
	
	$logfile->paragraph($opt_p,$opt_v) if ( defined $opt_p ) ;
	
	$logfile->finish() ;
	
}
