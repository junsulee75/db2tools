package WEBRETAIN ;
use LWP ;
use HTML::TableExtract;

#
#	A module to logon to Webretain and retrieve PMRs from Q
#
#	new - specify userid/pw to logon
#	queue - return a list of PMRs in a given Q.  use HTML::TableExtract to extract the list of PMRs.
#	gettext - get the text of a PMR
#

# my $retain = 'http://tanyaez.pok.dst.ibm.com/WebRetain/' ;
my $retain = 'http://longspeakz.boulder.ibm.com/WebRetain' ;

sub new
{
	my ($class , $id , $pw ) = @_ ;

	my $self = () ;

	my $browser = LWP::UserAgent->new;

	$self->{BROWSER}  = $browser ;
	bless ( $self, $class ) ;

	$browser->cookie_jar({});   # enable cookie
	$url = "$retain/DispatcherServlet?oper=retainweb" ;
	
	my $response = $browser->get( $url );

	$url = "$retain/DispatcherServlet" ;
	
	$response = $browser->post( $url ,
	[
	oper		=> 'auth' ,
	userid 		=>	$id ,
	password	=>  $pw ,
	timezone	=> 15 ,
	daylightSavings	=> 'D' ,
	redirectURL			=> null ,
	redirectToLogon		=> null ,
	submit				=> 'Submit'
	],
	);

	die "Can't get $url -- ", $response->status_line unless $response->is_success;

	return $self ;
}

# get list of PMRs from a given Q , such as WSDBCH,61A
sub queue
{
	my ( $class , $qname ) = @_ ;
	my ( $q1 , $q2 ) = split /,/,$qname ;
	my @pmrs = () ;

	my $url = "$retain/DispatcherServlet" ;
	
	$response = $class->{BROWSER}->post( $url,
	[
	oper		=> 'queueBrowse' ,
	queue 		=>	$q1 ,
	center		=>  $q2 ,
	type		=>  'Software' ,
	submit		=> 'Submit'
	],
	);

	# The list of PMRs is in a nest table at level 1 - first table hence count = 0. Return an array point to list of rows
	$te = HTML::TableExtract->new( depth => 1 , count => 0  );
	$te->parse($response->content);
	my @rows = () ;
	foreach $ts ($te->tables) {
		foreach $row ( $ts->rows) {
			push ( @rows , $row ) ;
		}
	}
	
	shift @rows ;
	return @rows ;

}

# Retrieve the PMR into a memory
sub gettext
{
	my ( $class , $pmr ) = @_ ;

	my ( $t1 , $t2 , $t3 ) = split/,/,$pmr ;

	$url = "$retain/DispatcherServlet?oper=pmrDisplay&pmrnumber=$t1&branch=$t2&country=$t3&library=current&type=Software" ;

	my $response = $class->{BROWSER}->get( $url ) ;
	return $response->content ;
	
}

# Give the url for a given PMR on webretain
sub getpmrlink
{
	my ( $class , $pmr ) = @_ ;
	my ( $x , $y , $z ) = split /,/,$pmr ;
    return "$retain/DispatcherServlet?oper=pmrDisplay&pmrnumber=$x&branch=$y&country=$z&type=S" ;
}

1 ;
