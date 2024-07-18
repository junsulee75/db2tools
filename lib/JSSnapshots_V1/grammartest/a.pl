#!/usr/bin/perl

use Parse::RecDescent ;
use File::Slurp ;

$::RD_ERRORS = 1; # Make sure the parser dies when it encounters an error
$::RD_WARN   = 1; # Enable warnings. This will warn on unused rules &c.
$::RD_HINT   = 1; # Give out hints to help fix problems.


my $grammar = read_file ( 'grammar' ) ;
my $parser = Parse::RecDescent->new($grammar);
$::RD_TRACE = 0 ;

my @a = ( 
	"ratio ( 0 , Total execution time (sec.microsec) , Total user cpu time (sec.microsec) + Total system cpu time (sec.microsec) )" ,
	"tmdiff ( Status change time , Snapshot timestamp )" ,
	"decimal (  Audry )" ,
	"decimal (  Audry + D E F  )" ,
	"decimal (  A B C + D E F , 2 )" ,
	"Async Physical Reads / ( Sync Physical Reads + Async Physical Reads )" ,
	"decimal ( Async Physical Reads / ( Sync Physical Reads + Async Physical Reads ) )" ,
	"decimal ( The string one + the string two )" ,
	"The quick (brown)" ,
	"Total buffer pool write time (milliseconds)" ,
	"The String" ,
	"100.345" ,
	"100 + The String 20" ,
	"100 + ( The String - Another String )" ,
	"( The String - Another String ) + 200.78" ,
	"The String + Something Else" ,
	"The String - Something Else" ,
	"The String + Something Else - Third Item" ,
	"( The String + Something Else )" ,
	"The String * Something Else" ,
	"( The String / Something Else ) + Another Value" ,
	"( The String / Something Else ) + ( Another Value / Divisor )" ,
	"( ( The String / Something Else ) + ( Another Value / Divisor ) )" ,
	"100 + ( ( The String / Something Else ) + ( Another Value / Divisor ) )" ,
	"( ( The String / Something Else ) + ( Another Value / Divisor ) ) + A NEW VALUE" ,
) ;


foreach $str ( @a ) {


	my ( $retv ) = $parser->startrule($str) ;
	if ( ! defined $retv ) {
   		print BAD "Bad Text : length = " . length($str) . "\n$str\n" ;
	}
	print "$str \t\t=> $retv\n" ;

}
