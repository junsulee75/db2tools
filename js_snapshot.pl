#!/usr/bin/perl

use JSSnapshots::File;
use JSSnapshots::db2snap;
use Getopt::Std;
use Switch ;

use Carp;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

=head1 VERSION

    Version 		: $Revision: 59 $
    Last modified 	: $Date: 2014-05-09 11:49:37 +1000 (Fri, 09 May 2014) $
    URL			: $HeadURL: file:///D:%5CSVN/PerlMod/Snapshots/Database.pm $ ;

=head1 DESCRIPTION

    This program is the main module to analyse database , application , dynsql ... etc snapshots.

=cut

usage() if ( @ARGV == 0 );

# %options=();
getopts('e:A:D:B:T:HVt:x:S:f:');

sub usage {

    print <<EOF;
js_snapshot.pl -f 'files' <options> <files>

	-D - Database 
		S : summary in database.xls
		r : record number

	-B : 
		S : Buffer pool summary
	
	-A
		S : show application summary in application.xls
		L : show all waiter/holder that are in lockwaits state
		h : show the full text of handle XYZ , -A hXYZ
		e : show all executing threads
	
	-S - 
		s : summary
		t10 : top 10 activity such as rows read , physical reads etc
		e  : show the full text of entry XYZ , e.g. -S e1234
		
	-T - Tablespace
		S : summary in tablespace.xls
	
	-t - Tables
		S : summary.  Output will be in tables.xls
	

EOF
    exit;
}

usage() if ( defined $opt_H );

@filelist = ();
foreach $fn (  glob $opt_f ) {
    push( @filelist, new JSSnapshots::File($fn) );
}

# die "No snapshot files provided" if ( @filelist == 0 );

$snap = new db2snap();

$snap->database( $opt_D, @filelist ) if ( defined $opt_D );

$snap->bufferpool(@filelist) if ( $opt_B eq 'S' );
$snap->bufferpool_progress ( $opt_B , @filelist) if ( $opt_B =~ m/^n/ ) ;

$snap->tablespace(@filelist) if ( $opt_T eq 'S' );
$snap->tablespace_progress( $opt_T , @filelist) if ( $opt_T =~ m/^n\w+/ );

$snap->table(@filelist) if ( $opt_t eq 'S' );
$snap->table_progress( $opt_t , @filelist) if ( $opt_t =~ m/^n\w+/ );

$snap->app_summary(@filelist)   if ( $opt_A eq 'S' );
$snap->app_handle( $opt_A , @filelist)   if ( defined $opt_A && $opt_A =~ m/h(\d+)/ );
$snap->app_progress( $opt_A , @filelist)   if ( $opt_A =~ m/p(\d+)/ );
$snap->app_executing( @filelist)   if ( $opt_A eq 'e' );
$snap->app_lockwaits(@filelist) if ( defined $opt_A && $opt_A eq 'L' );
$snap->app_regex( $opt_e, @filelist )  if ( defined $opt_A && $opt_A eq 'E' && defined $opt_e );

$snap->dynsql( $opt_S , @filelist ) if ( defined $opt_S );

$snap->complete();


exit;
