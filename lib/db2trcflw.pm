package db2trcflw ;

use Switch;
# use DBM::Deep ;
use USEDB ;
use XLS ;
use Data::Dumper ;
use Compress::Zlib ;



my $H = {} ;
my @orderedlist = () ;
my @Level0 = () ;
my $db ;
my $temp ;
my $curline ;
my $kk = {} ;
my $TREE = {} ;
my $L  = {} ;  # Hash for levels of various EDUs
my $COMPRESSION=1 ;


my $DBG_pstruct = 0 ;

sub new 
{
	my ($class,$fn) = @_ ;
	
  my $self = () ;      
	$self->{FILE}  = $fn ;
	
	open FLW , $fn or die "cannot open $fn" ;
	
	# seek to end of file to get size
	seek FLW , 0 , 2 ;	
	$self->{SIZE} = tell FLW ;
	$self->{DBH} = new USEDB() ;
 
        bless ( $self, $class ) ;
        return $self ;
}

sub getdbh
{
	my ($class,$fn) = @_ ;
	return $class->{DBH} ;
}

#------------------------------------------------------------------------------
#  Determine the level of the tree hierarch by counting the number of |
#------------------------------------------------------------------------------
sub nlevel
{
	my ( $ln ) = @_ ;
	my $count = 0 ;
	$count++ while $ln =~ /\|/g;
	return $count ;
}

sub spinmsg
{
	my ( $entry ) = @_ ;
	$c = chr(124) if ( ! defined $c ) ;
	print "Initial Parsing .......$entry $c\r" ;
	switch ( ord($c) ) {
		case 124 { $c = chr(47) }
		case 47  { $c = chr(45) }
		case 45  { $c = chr(92) } 
		case 92  { $c = chr(124) }
	} ;
}

#------------------------------------------------------------------------------
#  Gives the percentage
#------------------------------------------------------------------------------
sub percent
{
	my ( $x , $total ) = @_ ;
	my $pct = ( $x / $total ) * 100 ;
	my $rets = sprintf "%.2f",$pct ;
	return $rets ;
}

#------------------------------------------------------------------------------
#      Parse the FLW file and insert each PID entry into PID table, and 
#      each flw entry into the FLW table
#------------------------------------------------------------------------------
sub doflw
{
	my ( $class ) = @_ ;

	$sz = $class->{SIZE} ;
	
	my $H = {} ;
	
	open F2 , "> f2.unl" or die "cannot open f2.unl" ;
	
	# seek to beginning
	seek FLW , 0 , 0 ;	# seek to begin of file
	$IDX = -1 ;
	while ( <FLW> ) {
	
		print "FLW : $offset of $sz : " . percent($offset,$sz) . "\r" ;
		if ( m/pid = (\d+) tid = (\d+) node = (-?\d+)/ ) {

			$IDX++ ;
			$pid  = $1 ;
			$tid  = $2 ;
			$node = $3 ;
			$H->{$IDX}->{PID} = $pid ;
			$H->{$IDX}->{TID} = $tid ;
			$H->{$IDX}->{NODEID} = $node ;
	 		next ;
		}
	
		if ( m/^(\d+)\s+/ ) {
			$currlevel = nlevel($_) ;
			$entry = $1 ;
			
			$H->{$IDX}->{eduname} = $1 if ( m/eduname (\w+)/ );
			
			#-- peek next line to determine if this is a parent
			$curpos = tell FLW ;
			$nxtln = <FLW> ;
			seek FLW , $curpos , 0 ;
			$nxtlnlevel = nlevel($nxtln) ;
			$parent = ( $nxtlnlevel > $currlevel ) ? 1 : 0 ;
			
			print F2 "$IDX,$entry,$offset,$currlevel,$parent\n" ;
			$cnt++ ;
			# last if ( $cnt > 10000 ) ;
		}

		$offset = tell FLW ;
	}
	print "\n" ;
	close F2 ;
	
	open F1 , "> f1.unl" or die "cannot open f1.unl" ;
	foreach my $k ( keys %$H ) {
		printf F1 "%d,%d,%d,%d,%s\n" , $k , $H->{$k}->{PID} , $H->{$k}->{TID} ,$H->{$k}->{NODEID} , $H->{$k}->{eduname} ;
	}
	close F1 ;
	exit ;
}

# Return an orderedlist of EDUs
sub ListX
{
	my ( $class ) = @_ ;
	my $edus = $db->{EDU} ;
	return keys %$edus ;
}

# Get the number of entries for a given EDU
sub GetCountX
{
	my ( $class , $thread ) = @_ ;
	my $edus = $db->{EDU} ;
	return $edus->{$thread}->{COUNT} ;
}

# Return the LEVEL0 entries for a given EDU
sub Level0
{
	my ( $class , $idx , $lvl ) = @_ ;
	my $p = $db->{EDU}->{$edu} ;
	return split(",",$p->{LEVEL0}) ;
}

# Move backwards until we see a new line character, and then read the line
sub get_flwentry
{
	my ( $pos ) = @_ ;
	for ( my $i = $pos ; seek FH , $i , 0  ; $i-- ) {
		$c = getc(FH);
		last if ( ord($c) == 0xA ) ;
	}
	$loc = tell FH ;
	$curline = <FH> ;
	$curline =~ m/^(\d+)\s/ ;
	my $retv = $1 ;
	return ($retv,$loc) ;
}

sub getline 
{
	my ( $pos ) = @_ ;
	seek FH , $pos , 0 ;
	my $curline = <FH> ; chomp($curline) ;
	return $curline ;
}

sub search
{
	my ( $class , $str ) = @_ ;
	my $rets ;
	my $svloc = tell FLW ;
	seek FLW , $offset , 0 ;
	while ( <FLW> ) {
		$rets .= $_ if ( m/$str/i ) ;
	}
	return $rets ;
}

sub text
{
	my ( $class , $offset ) = @_ ;
	seek FLW , $offset , 0 or die "cannot see to $offset in function [text]" ;
	my $ln = <FLW> ;	
	chomp($ln) ;
	return $ln ;
}

# determine if a FLW entry has children.  this will enable/disable the 'expand' icon
sub has_children 
{
	my ( $class , $edu , $entry ) = @_ ;
	
	# return 0 ;
	
	my $curpos  = $FLWCACHE->{$entry}->{POS} ;
	# print "Entry = $entry , POS = $curpos\n" ;
	my $curline = getline($curpos) ;	# to advance FH
	my $curlvl  = nlevel($curline) ;
	
	my $nxtln   = <FH> ;
	my $nxtlvl  = nlevel($nxtln) ;
	
	# print "Edu = $edu , Entry = $entry , $curpos , curlvl = $curlvl , $nxtlvl\n" ;
	
	# @l = $L->{$edu}->{
	return ( $curlvl == $nxtlvl ) ? 0 : 1 ;
}

# Get an entry line from FLW.  First find the offset, then seek and read the line
sub entry_line 
{
	my ( $class , $entry ) = @_ ;
	my $offset = $class->{DBH}->Offset($entry) ;
	return $class->text ( $offset ) ;
}

sub range
{
	my ( $class , $from , $to ) = @_ ;
	my $dbh = $class->{DBH}->{DBH} ;
	my $H = {} ;
	my $ref ;
	my $sql = "select * from FLW where entry >= $from and idx = ( select idx from FLW where entry = $from ) order by entry" ;
	my $sth = $dbh->prepare ( $sql ) or die ;
	$sth->execute() or die ;
	while ( $ref = $sth->fetchrow_hashref() ) {
		$H->{$ref->{ENTRY}} = $ref->{OFFSET} ;
		last if ( $ref->{ENTRY} == $to ) ;
	}
	$sth->finish ;
	
	$sql = "select B.EDUNAME from FLW A , PID B where entry = ? and A.idx = B.idx ;" ;
	my $sth = $dbh->prepare ( $sql ) or die ;
	foreach my $e ( sort { $a <=> $b } keys %$H ) {
		$marker = "" ;
		if ( ! exists $H->{$e+1} ) {
			my $ne = $e + 1 ;
			$sth->execute($ne) or die ;
			$ref = $sth->fetchrow_hashref() ;
			$marker = "   ===> ($ne : $ref->{EDUNAME})" ;
		}
		printf "%s $marker\n" , $class->text ( $H->{$e} ) ;
	}
}

sub gensql
{
	open TRC , "> db2trc.sql" or die "cannot open db2trc.sql" ;
	print TRC <<ABC
connect to sample @
set schema db2trc @

drop table PID @
create table PID ( idx int , pid int , tid bigint , node smallint , eduname char(30) ) @

drop table FLW @
create table FLW ( idx int , entry int , offset bigint , level int , parent int ) @

create index e_idx1 on FLW ( idx , entry ) @
create index e_idx2 on FLW ( idx , level , entry ) @
create index e_idx3 on FLW ( entry ) @

drop table FMT @
create table FMT ( entry int , offset  bigint ) @
create index m_idx1 on FMT ( entry ) @

load from f1.unl of del replace into PID nonrecoverable @

load from f2.unl of del replace into FLW nonrecoverable @

runstats on table db2trc.FLW with distribution and detailed indexes all @
--
-- Get the PATH of an entry.  Need to return the V_IDX so I know which edu to highlight on the hlist
drop procedure GetPath ( INTEGER ,  INTEGER , varchar(1000) )   @
create procedure GetPath( INOUT v_entry INTEGER  , INOUT v_idx INTEGER , INOUT v_out varchar(1000) )
RESULT SETS 1
LANGUAGE SQL
BEGIN

	declare v_lvl integer ;
	declare v_parent integer ;
	declare v_max integer default 0 ;
	declare v_node integer ;
	declare v_pid integer ;
	declare v_tid bigint ;
	
	set v_out = rtrim(char(v_entry)) ;
	select idx into v_idx from FLW where entry = v_entry ;
	
	
	while ( v_max is not null )
	do
		select idx , level into v_idx , v_lvl FROM flw where entry = v_entry  ;
		select max(entry) into v_max from FLW where idx = v_idx and level = v_lvl-1 and entry < v_entry and parent = 1 ;
		
		if ( v_max is not null ) then
			set v_out = v_out || '.' || rtrim(char(v_max)) ;
			set v_entry = v_max ;
		end if ;
	end while ;	

	select tid,pid,node into v_tid,v_pid,v_node from PID where idx = v_idx ;
	set v_out = v_out || '.' || rtrim(char(v_tid)) || '.' || rtrim(char(v_pid)) || '.' || rtrim(char(v_node)) ;
	
END 
@

drop procedure Level_Entries ( INTEGER , INTEGER )  @
create procedure Level_Entries( IN v_idx INTEGER , IN v_level INTEGER  )
RESULT SETS 1
LANGUAGE SQL
BEGIN
	
 	declare q1 cursor with return for select * from FLW where idx = v_idx and level = v_level order by entry ;
 	open q1 ;
		
END   
@

drop procedure GetEDUs ()  @
create procedure GetEDUs()
RESULT SETS 1
LANGUAGE SQL
BEGIN
	
 	declare q1 cursor with return for select a.idx,pid,tid,node,count(*) as CNT from db2trc.PID a, db2trc.FLW b where a.idx = b.idx and b.level = 0 group by a.idx,a.pid,a.tid,a.node order by CNT desc ;
 	open q1 ;
		
END   
@

drop procedure GetChildren ( INTEGER )  @
create procedure GetChildren( INOUT v_entry INTEGER  )
RESULT SETS 1
LANGUAGE SQL
BEGIN

	declare v_idx integer ;
	declare v_max bigint ;
	declare v_level integer ;
	declare v_pid integer ;
	declare v_tid integer ;
	
	
	select idx,level into v_idx, v_level from FLW where entry = v_entry ;
	select entry into v_max from flw where entry > v_entry and level = v_level and idx = v_idx 
		order by entry fetch first 1 row only ;
 
	if ( v_max is null ) then
        set v_max = 999999999999 ;
	end if ;
	
	begin
 	declare q1 cursor with return for select * from FLW 
 		where idx = v_idx and level = v_level+1 and
 		entry > v_entry and entry < v_max ;
 	open q1 ;
 	END ;
		
END   
@

drop procedure Entry_Offset ( INTEGER , BIGINT )  @
create procedure Entry_Offset( INOUT v_entry INTEGER , INOUT v_offset BIGINT )
LANGUAGE SQL
BEGIN

	select offset into v_offset from FLW where entry = v_entry ;

END @
	
ABC
;
	close TRC ;
	print "Run : db2 -td@ -vf db2trc.sql" ;
	exit ;
}

# give a list of sequence of entries with TID mixed in
sub profile
{
	my ( $class ) = @_ ;

	@stack = () ;
	open FH , $class->{FILE} or die "cannot open $class->{FILE}" ;
	while ( <FH> ) {
	
		next if ( m/^$/ ) ;
        print if ( /pid =/ ) ;
		
		# skip if NOT entry/exit point 
        next if ( ! m/^\d+.*(entry|exit)/ ) ;
		
		# push/pop stack and get the timing
		
        my $item = {} ;
        $nlevel = nlevel($_) ;
        $_ =~ s/\| //g ;

        $_ =~ m/^(\d+)\s+(\d+\.\d+)\s+(.*)\s+(entry|exit)/ ;
        $item->{index} = $1 ;
        $item->{tm}    = $2 ;
        $item->{func}  = $3 ;
        $type          = $4 ;
        $item->{level} = $nlevel ;

        # print "Type = $type : Level=$item->{level} , $item->{index}-$item->{func}\n" ;

		# ignore level 0 
        next if ( $nlevel == 0 ) ;

        if ( $type eq 'entry' ) {
            push ( @stack , $item ) ;
        } # entry

        if ( $type eq 'exit' ) {

            $caller = pop ( @stack ) ;
            if ( $caller->{func} ne $item->{func} ) {

				## OH SHIT.  Something wrong.  Put it back and hope for the best
				warn "Stack unmatched.  Current entry = $item->{index} ,  Level = $item->{level} , found on stack =  $caller->{index}\n"  ;
				push ( @stack , $caller ) ;
				next ;
            }

			$tmdiff = $item->{tm} - $caller->{tm}  ;
			printf "%8d to %8d : %0.8f - Level %d , %s\n" , $caller->{index} , $item->{index} , $tmdiff , $item->{level} , $caller->{func} ;

			$func = $caller->{func} ;
			$PROFILECNT{$func}++ ;
            $PROFILETM{$func} += $tmdiff ;
					
		} # exit
		
	} # while
	close FH ;

	print "===============\n" ;

	foreach $func ( sort { $PROFILETM{$b} <=> $PROFILETM{$a} } keys %PROFILETM ) {
        printf "Count = %6d , Time = %0.8f , Func = %s\n" , $PROFILECNT{$func} , $PROFILETM{$func} , $func ;
	}
=begin AUD
	

		

		
	
=cut
}

sub DESTROY {
    my $self = shift;
    close FH ;
} 

return 1 ;