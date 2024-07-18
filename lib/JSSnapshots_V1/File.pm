package JSSnapshots::File ;

use strict;
use DBM::Deep;
use Data::Dumper ;
use String::CRC::Cksum ;
use Compress::Zlib;
use Cwd ;
use Switch;
use Clone 'clone';
use Sys::Hostname;
use Fcntl 'SEEK_SET' ;
use JSSnapshots::DeepHash ;
use JSSnapshots::Functions qw(ratio hitrate commafy sum_of_diff tmdiff delta orderby hashdiff );

################################################################################################################
#
#	Only APPLICATION and BUFFERPOOLS have multiple snapshots.   Database/Dynamic SQL/Table/Tablespace has only one.
#
#	fulltext
#
#		Database	    - fulltext ('DATABASE' , 0 )
#		Bufferpool  	- fulltext ('BUFFERPOOL' , X ) 
#		Application 	- fulltext ('APPLICATION' , X )
#		Table			- fulltext ('TABLE' , 0 ) 
#		Tablespace		- fulltext ('TABLESPACE' , 0 ) 
#		Dyn SQL			- fulltext ('SQL' , 0 ) 
#
#	partialtext -	This show the text that will be evaluated as X=Y.
#
#		Databse 	-  partialtext ( 'DATABASE' , 0 ) ;
#		Bufferpool  -  partialtext ( 'BUFFERPOOL' , X ) ;
#		Application -  partialtext ( 'APPLICATION' , X ) ;
#		Table	    -  partialtext ( 'TABLE' , X ) ;
#		Tablespace  -  partialtext ( 'TABLESPACE' , X ) ;
#		Dyn SQL     -  partialtext ( 'DYNSQL' , X ) ;
#
################################################################################################################

my $cksum = String::CRC::Cksum->new;

sub new
{
    my ( $class , $fn  ) = @_ ;

    my $tmpdir ;

    # determine the temporary directory base on the machine
    switch ( hostname() ) {

        #case "dragon" { $tmpdir   = "/mnt/hgfs/WinD/temp" }
        #case "speedy" { $tmpdir   = "d:/temp" }
        #case "alcatraz" { $tmpdir   = "d:/temp" }
	
	# junsulee 
        case "dragon" { $tmpdir   = "/mnt/hgfs/WinD/temp" }
        case "speedy" { $tmpdir   = "d:/temp" }
        case "alcatraz" { $tmpdir   = "d:/temp" }
	case "junsulee.au.ibm.com" { $tmpdir   = "/Users/kr050496/bin/temp" }
	case "junsulee-2.au.ibm.com" { $tmpdir   = "/Users/kr050496/bin/temp" }
	case "junsuleemacpro.au.ibm.com" { $tmpdir   = "/Users/kr050496/bin/temp" }

        else          { die "unknown localdir" }

    } ;

    my $self = () ;
    $self->{FILE} = $fn ;

    open $self->{FH} , $fn or die "cannot open $fn" ;

    my $cksum = String::CRC::Cksum->new ;
    my $salt =  "$fn" . -s "$fn" ;          # the filename and the size should make it unique
    $cksum->add ( $salt ) ;
    my $dbfile = $cksum->result . ".db" ;
    $dbfile = "$tmpdir/snapshots/$dbfile" ;
    mkdir "$tmpdir/snapshots" if ( ! -d "$tmpdir/snapshot" ) ;

	# my $db = buildhash ( $dbfile , $fn ) ;
	# $self->{'Snapshot timestamp'} = $db->{'Snapshot timestamp'} ;

	# print Data::Dumper->Dump ( [ $db ] , [ 'DB' ] ) ;
=begin AUD
	foreach my $type ( qw/SNAPSHOT DATABASE BUFFERPOOL DYNSQL TABLE TABLESPACE APPLICATION/ ) {
		$self->{$type} = [ split /,/ , uncompress ( $db->{$type} ) ]  ;
		# print Data::Dumper->Dump ( [ $self->{$type} ] , [ $type ] ) ;
	}
=cut

	my $newdbfile = "${dbfile}_new" ;
	print "DICT = $newdbfile\n" ;

	# TODO - buildhash only when necessary
	my $rebuild = ( ! -f $newdbfile ) ? 1 : 0 ;
	$self->{DICT} = new DeepHash ( $newdbfile ) ;
	buildhash_new ( $self->{DICT} , $fn ) if ( $rebuild ) ;

	# Need to clone the HASH.  Otherwise damn slow to read this for every access
	foreach my $w ( qw/DATABASE BUFFERPOOL TABLE TABLESPACE APPLICATION SQL/ ) {
		$self->{$w} = clone ( $self->{DICT}->get($w) ) ;
	}

    bless ( $self, $class ) ;
    return $self ;
}

sub buildhash_new
{
	my ( $db , $fn ) = @_ ;

	my $TS ; 		# timestamp
	my $X = {

		Database 	=> { start => 'Database name' , 		finish => 'Memory usage for database' }  ,
		Bufferpool	=> { start => 'Bufferpool name' , 		finish => 'Post-alter size' } ,
		Tablespace	=> { start => 'Tablespace name' , 		finish => 'Number of files closed' } ,
		Table		=> { start => 'Table Schema' , 			finish => 'Page Reorgs' } ,
		Application => { start => 'Application handle' , 	finish => 'Workspace Information' } ,
		SQL			=> { start => 'Number of executions' , 	finish => 'Statement text' }

	} ;
 
	print "Phase 1 : Scanning $fn\n" ;

	my $type	;	# the current type of snapshot seen - DATAABASE , BUFFERPOOL , APPLICATION etc

	open FH , $fn or die ;
	while ( <FH> ) {
	
		my $loc = tell FH ;
		$loc -= length ($_) ;
	
		$type = $1 if ( m/(\w+) Snapshot/ ) ;

		# skip until hit snapshots
		next if ( ! defined $type ) ;
	
		my $ptr = $X->{$type} ;
		$ptr->{tmp} = $loc if ( m/$ptr->{start}/ ) ;	# save the location temporarily if see a starting pattern
		$TS = $_ if ( m/Snapshot timestamp/ ) ;         # save the snapshot timestamp , cos tablespace/table does not have it inside the record

		if ( m/$ptr->{finish}/ ) {
			push ( @ { $ptr->{records} } , [ $ptr->{tmp} , $loc ] ) ;	# note the start/finish file offset

			# TODO - this needs only to be done once.
			chomp $TS ;
			( $ptr->{TimeStamp } = $TS ) =~ s/Snapshot.*\s+=\s+// ;
		}

	}
	close FH ;

	print "Phase 2 : Writing out\n" ;
	foreach my $k ( keys %$X ) {
		$db->set ( uc($k) , $X->{$k} ) ;
	}


=begin AUD
	print Data::Dumper->Dump ( [ $X ]  , [ 'X' ] ) ;
	$db->dump() ; exit ;
=cut

}


sub buildhash
{
   	my ( $dbfile , $fn ) = @_ ;

    # hash file already exist.  do not rebuild
    unlink $dbfile ;
    return DBM::Deep->new( $dbfile )  if ( -f $dbfile ) ;

	my @snapshot = () ;
	my @dynsql = () ;
	my @table = () ;
	my @apps = () ;
	my @tablespace = () ;
	my @bufferpool = () ;
	my @database = () ;
	
	my $type = "" ;
	my $TS ;
	
	print "Phase 1 : Scanning $fn\n" ;
	
	open FH , $fn or die ;
	while ( <FH> ) {
	
		my $loc = tell FH ;
		$loc -= length ($_) ;
	
		$TS = $_ if ( m/Snapshot timestamp/ ) ;         # save the snapshot timestamp , cos tablespace/table does not have it inside the record

		if ( m/(\w+) Snapshot/ ) {
			$type = $1 ;
			push ( @snapshot , $loc ) ;
		}
	
		# Entry / exit points for Database snapshots
		push ( @database , $loc ) if ( $type eq 'Database' && m/Database name|Memory usage for database/ ) ;
	
		# Entry / exit points for Bufferpool snapshots
		push ( @bufferpool , $loc ) if ( $type eq 'Bufferpool' && m/Bufferpool name|Post-alter size/ ) ;
	
		# Entry / exit points for DYNSQL snapshots
		push ( @dynsql , $loc ) if ( $type eq 'SQL' && m/Number of executions|Statement text/ ) ;
	
		# Entry / exit points for Table snapshots
		push ( @table , $loc ) if ( $type eq 'Table' && m/Table Schema|Page Reorgs/ ) ;
	
		# Entry / exit points for Application snapshots
		push ( @apps , $loc ) if ( $type eq 'Application' && m/Application handle|Workspace Information/ ) ;
	
		# Entry / exit points for Tablespaces snapshots
		push ( @tablespace , $loc ) if ( $type eq 'Tablespace' && m/Tablespace name|Number of files closed/ ) ;

	}

	print "Phase 2 : Writing to $dbfile\n" ;
    my $db = DBM::Deep->new( $dbfile ) ;

	chomp $TS ;
	( $db->{'Snapshot timestamp'} = $TS ) =~ s/Snapshot.*\s+=\s+// ;
	$db->{SNAPSHOT}  	= compress ( join(",",@snapshot ) ) ;
	$db->{DATABASE}  	= compress ( join(",",@database ) ) ;
	$db->{BUFFERPOOL} 	= compress ( join(",",@bufferpool ) )  ;
	$db->{DYNSQL}    	= compress ( join(",",@dynsql ) ) ;
	$db->{TABLE}    	= compress ( join(",",@table ) ) ;
	$db->{TABLESPACE}   = compress ( join(",",@tablespace ) ) ;
	$db->{APPLICATION}  = compress ( join(",",@apps ) ) ;
	print "Phase 2 : done\n" ;
	close FH ;

	return $db ;
}


# Return a list of index for the given snapshot type
sub typelist
{
	my ( $type ) = @_ ;
	my $H ;

	print "TYPELIST called = $type\n" ;
	my @retlist = () ;
	foreach my $k ( sort { $a <=> $b } keys %$H ) {
		push ( @retlist , $k ) if ( $H->{$k}->{TYPE} eq $type ) ;
	}
	return @retlist ;
}


# The array is a list of offsets  begin,end,begin,end,begin,end ........
sub partialtext_TBD
{
	my ( $class , $type , $idx ) = @_ ;

	local *FH = $class->{FH} ;
	my $array = $class->{$type} ;
	my $startoffset = $array->[$idx*2] ;
	my $endoffset   = $array->[$idx*2 + 1] ;

	$class->text ( $startoffset , $endoffset ) ;
}

# Return the full text of an type,index entry.  Full text need to use the class->SNAPSHOT
# If type = APPLICATION , and IDX = 7 , return the text for the 7th application snapshot
sub fulltext 
{
	my ( $class , $type , $idx ) = @_ ;
	
	local *FH = $class->{FH} ;

	my $records = $class->{$type}->{records} ;
	my ( $start , $end ) = @{ $records->[$idx] }  ;

	my $X = {
		APPLICATION		=> '\s+Application Snapshot$|\s+Database Lock Snapshot' ,
		SQL				=> '^$' ,			# end point is a blank new line
	} ;

	# Specify the ending regex for various type when dumping out full text. 
	my $endpoint = $X->{$type} ;

	if ( ! defined $endpoint ) {
		printf "No endpoint defined for $type !!  See %s" , __FILE__ ;
		exit ;
	}

    seek FH , $start , SEEK_SET ;
	while ( <FH> ) {
		last if ( m/$endpoint/ ) ;
		print ;
	}
	return ;

=begin AUD
	my $array = $class->{SNAPSHOT} ;
	my $i ;
	my $ln ;
	my $matchcnt = -1 ;
	for ( $i = 0 ; $i < @$array ; $i++ ) {
		seek FH , $array->[$i] , 0 ;
		$ln = <FH> ;
		$matchcnt++ if ( $ln =~ m/$type Snapshot/i ) ;
		# print "Matchcnt = $matchcnt , I = $i :  $ln" ;
		last if ( $matchcnt == $idx  ) ;
	}

	if ( $matchcnt != $idx ) {
		print "No match found for type [$type] - Index [$idx] , Matchcount = $matchcnt\n" ;
		return ;
	}
	# print "FOUND : Matchcnt = $matchcnt , I = $i :  $ln" ;

	my $startoffset = $array->[$i] ;
	my $endoffset   = $array->[$i + 1] ;

	$class->text ( $startoffset , $endoffset ) ;
=cut
}


# typelist ( 'Application' ) ;
# fulltext ( 1226 ) ;

# given a line of X = Y , return X , Y
sub keyval
{
    my ( $line ) = @_ ;
    chomp $line ;
    my ( $k , $v ) = split/\s*=\s+/,$line ;
    $k =~ s/^\s+|\s+$//g ;      # remove white space
    $v =~ s/^\s+|\s+$//g ;      # remove trailing white space
    return $k , $v ;
}


# Count the number of records for a given type
sub count
{
    my ( $class , $type ) = @_ ;
	return @ { $class->{$type}->{records} } ;
}

# Return the start/end pair for a given type/idx
sub offsets {
	my ( $class, $type , $idx ) = @_ ;
	my @a = @ { $class->{$type}->{records}->[$idx] } ;
	return @a ;
}

# require special handling for sql text.  If sorted = 1, the hash returned will be in the sorted order
sub record
{
    my ( $class , $type , $idx , $sorted ) = @_ ;

    local *FH = $class->{FH} ;

	if ( $class->count($type) == 0 ) {
		print "No records for type $type.  Perhaps there is not $type snapshots in the file ?\n" ;
		exit ;
	}

	# Return NULL hash if out of range.  Buffer/Table/Tablespace relies on this to know it has ended
	return {} if ( $idx+1 > $class->count($type) ) ;

	my ( $start , $end ) = $class->offsets ( $type , $idx ) ;

    # tag every record with item FILE and Snapshot timestamp
    my $H = {} ;
    tie %$H , 'Tie::IxHash' if ( $sorted == 1 ) ;
    $H->{FILE} = $class->{FILE} ;
    $H->{'Snapshot timestamp'} = $class->{$type}->{TimeStamp} ;
    $H->{START} = $start ;
    $H->{END} = $end ;
	$H->{INDEX} = $idx ;

	# print "Doing type=$type , idx=$idx , sorted=$sorted\n" ;
    seek FH , $start , SEEK_SET ;
    while ( <FH> ) {

        if ( m/Statement text/ ) {
			my $stmt = $_ ;
			# statement text is multi-line
			while ( <FH> ) {
				last if ( m/^$/ ) ;
				$stmt .= $_ ;
			}
            $H->{'Statement text'} = $stmt ;	
            $H->{'Statement text'} =~ s/Statement text\s+=\s+|\s+$//g ;	# remove white spaces
            $H->{'Statement text'} =~ s/\s+/ /g ;						#
            $H->{'Statement text'} =~ s/,/, /g ;						# beautify
        } else {
            my ( $k , $v ) = keyval($_) ;
			warn "$type : Key [$k] already exists" if ( exists $H->{$k} && $ENV{WARN} == 1 ) ;
            $H->{$k} = $v if ( defined $v ) ;			
        }
        last if ( tell FH  > $end ) ;
    }

	# Because the field names are inconsistent between DATABASE vs TABLESPACE, need to do some massaging.
	my $namemap = {
		TABLESPACE	=>	[
			{ field => 'Total buffer pool read time (millisec)' , from	=> 'millisec' , to => 'milliseconds' } ,
			{ field => 'Total buffer pool write time (millisec)' , from	=> 'millisec' , to => 'milliseconds' }
		]  ,
	} ;

	my $ptr = $namemap->{$type} ;		# ptr = pointer
	foreach my $hp ( @$ptr ) {			# hp = hash pointer
		my $fld = $hp->{field} ;
		next if ( ! exists $H->{$fld} ) ;	# skip and no adjust if this field to be adjusted does not exist

		my $v = $H->{$fld} ;					# v = value
		$fld =~ s/$hp->{from}/$hp->{to}/g ;
		$H->{$fld} = $v ;
	}

    # print Data::Dumper->Dump ( [ $H ] , [ 'P' ] ) ; exit ;

    return $H ;
}

# Show the text in the offset region between start to end
sub text 
{
	my ( $class , $start , $end ) = @_ ;

	# print "Startoffset = $start , Endoffset = $end\n" ;
    local *FH = $class->{FH} ;
	seek FH , $start, SEEK_SET ;
	while ( <FH> ) {
		print ;
		last if ( defined $end && tell FH > $end ) ;	# stop at end offset if it is defined.  DO NOT CHANGE this.  Verify that partialtext ( 'DYNSQL' , X ) works
	}
}


# Retrieve a record by name
#	type - such as Application , Tablespace , Bufferpool , Table
#	field - such as Table name
#	value - such as EMPLOYEE
#	flag - 1 sorted 
sub record_by_name
{
	my ( $class , $type , $field , $value , $flag ) = @_ ;

	for ( my $i = 0 ;; $i++ ) {
		my $p = $class->record ( $type , $i , $flag ) ;
		last if ( ! exists $p->{$field} ) ;
		return $p if ( $p->{$field} eq $value ) ;
	}
	return {} ;
}

return 1 ;
