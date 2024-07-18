package USEDB ;
use DBI ;
use DBD::DB2 ;

# EDUS - Return a list of EDUS  IDX,PID,TID,NODEID,COUNT
# Level -  Return a list of entries for a given IDX , and a level
# Children - Return the children of an entry
# parent - return the parent of an entry
# Path   - Give the path ( aka stack ) of an entry
# Offset - give the file offset of an entry in FLW

sub new 
{
	my ($class,$fn) = @_ ;
	
	my $self = () ;  

	# $dbh = DBI->connect("dbi:odbc:SAMPLE" ) or die ;
	$dbh = DBI->connect("dbi:DB2:SAMPLE") or die ;
        $dbh->do("set schema db2trc") ;
        $self->{DBH} = $dbh ;
	
        bless ( $self, $class ) ;
        return $self ;
}


sub EDUS
{
	my ( $class ) = @_ ;

	my $dbh = $class->{DBH} ;
	$sth = $dbh->prepare ( "call db2trc.GetEDUs()" ) or die ;
	$sth->execute() or die ;
	return $sth ;
}

# Get all level 0 entries of a given PID/TID/NODE
sub Level
{
	my ( $class , $idx , $level ) = @_ ;
	my $sth ;
	
	my $dbh = $class->{DBH} ;
	$sth = $dbh->prepare ( "call db2trc.Level_Entries($idx,$level)" ) or die ;
	$sth->execute() or die ;
	return $sth ;
}

# Get children of an entry.  This is called by click on a node
sub Children 
{
	my ( $class , $entry ) = @_ ;
	my @entry  = () ;
	my @offset = () ;
	my @parent = () ;
	
	# Entry may be in the form of X.Y.Z.  Only interested in the last one.
	my @l = split /\./ , $entry ;
	$entry = pop ( @l ) ;
	my $dbh = $class->{DBH} ;
	$sth = $dbh->prepare ( "call db2trc.GetChildren(?)" ) or die ;
	$sth->execute($entry) or die ;
	return $sth ;
	
}

#
# Get parent of an entry.  This is called when trying to open a node deep in the tree.  Need to 
# know all the parents and expand it top down.
#
sub Parent 
{
	my ( $class , $entry ) = @_ ;

	my $idx ;
	my $ts ;
	
	my $dbh = $class->{DBH} ;
	$sth = $dbh->prepare ( "call db2trc.GetParent(?,?,?)" ) or die ;
	$sth->bind_param(1, $entry );
	$sth->bind_param_inout (2, \$idx, 4 );
	$sth->bind_param_inout (3, \$ts, 1000 );
	$sth->execute() or die ;
    	$sth->finish ;

	my @l = split /\./,$ts ; @l =  reverse @l ; $ts = join (".",@l) ;  print
	"TS $entry from usedb.Parent = $ts\n" ;

	return $idx , $ts ; 
	
}

#
# Get parent of an entry.  This is called when trying to open a node deep in the tree.  Need to 
# know all the parents and expand it top down.
#
sub Path 
{
	my ( $class , $entry ) = @_ ;

  my $idx ;
	my $ts ;
	
	my $dbh = $class->{DBH} ;
	$sth = $dbh->prepare ( "call db2trc.GetPath(?,?,?)" ) or die ;
	$sth->bind_param(1, $entry );
	$sth->bind_param_inout (2, \$idx, 4 );
	$sth->bind_param_inout (3, \$ts, 1000 );
	$sth->execute() or die ;
  $sth->finish ;

	my @l = split /\./,$ts ; @l =  reverse @l ; $ts = join (".",@l) ; 

	return $idx , $ts ; 
	
}

# return the file offset of an entry
sub Offset
{
	my ( $class , $entry ) = @_ ;
	my $offset ;

	my $dbh = $class->{DBH} ;
	my $sth = $dbh->prepare ( "call db2trc.Entry_Offset(?,?)" ) or die ;
	$sth->bind_param(1, $entry );
	$sth->bind_param_inout(2, \$offset , 20 );
	$sth->execute() or die ;
  $sth->finish ;
	return $offset ;
}

sub allentries_TBD
{
	my ( $class ) = @_ ;
	my $dbh = $class->{DBH} ;
	my $sth = $dbh->prepare ( "select entry , offset , tid from db2trc.flw a , db2trc.pid b where a.idx = b.idx order by entry fetch first 10000 rows only" ) or die ;
	$sth->execute() or die ;
	return $sth ;
}

sub DESTROY {
    my $self = shift;
} 

return 1 ;
