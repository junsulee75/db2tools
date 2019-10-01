#!/usr/bin/perl

use Expect ; ## sudo cpan Expect
use strict ; 
use File::Basename;
use Getopt::Long;

my $myEmail = "junsulee\@au1.ibm.com"; ## TODO : change to your email address
my $prog  = basename($0);
my $caseNum;
my $fileToDownload;
my $requesterID;
my $DEBUG;

=pod

=head1 VERSION

	IBM INTERNAL ONLY
    Version 		: $Revision: 1.0 $
    Last modified 	: $Date: 2019-09-25 
    Author : Jun Su Lee ( junsulee@au1.ibm.com )
    URL			: $HeadURL: https://github.ibm.com/junsulee/my_ibm_daily_work $ ;

=head1 SYNOPSIS

	Usage :
	js_cp_wlist.pl -c <SFCaseNumber> -f <path string after case number> -u <torolab machine userid for dir under /TMP>

	example : 
	js_cp_wlist.pl -c TS002790222 -f "2019-09-27/TS002790222.db2pd.tar" -u junsulee

=head1 DESCRIPTION

    This program automates the requested whitelist copy work.

=head1 DEPENDENCY

	Expect  ( Install by 'sudo cpan Expect')

=head1 Author
	Jun Su Lee ( junsulee@au1.ibm.com 

	Type 'q' to exit this page.
=cut


sub usage{
	print <<AUD ;

    Usage :
	$prog -c <SFCaseNumber> -f <path string after case number> -u <torolab machine userid for dir under /TMP>

	example : 
	$prog -c TS002790222 -f "2019-09-27/TS002790222.db2pd.tar" -u junsulee

AUD
	exit;
}

&usage if( scalar(@ARGV) < 1 ) ;

## TODO : Necessary machine lists, Change to your id and password for each system 
my %mach = (
	'bug'	=> [ "bugdbug.torolab.ibm.com" , "junsulee" , $ENV{BUG_PW} ]  ,  ## For password, change  $ENV{BUG_PW}  to "your password"
	'ecurep'	=> [ "ecurep.mainz.de.ibm.com" , "au379509" , $ENV{IBM_PW} ]  ,  ## For password, change  $ENV{BUG_PW}  to "your password"
) ;

GetOptions(
	    "caseNum=s" => \$caseNum,
	    "fileToDownload=s" => \$fileToDownload, 
	    "userID=s" => \$requesterID,      
	    "debug=i" => \$DEBUG      
	    )
or die "Incorrect usage ! \n";

print "$prog $caseNum $fileToDownload $requesterID \n" if $DEBUG;
my $caseNum1 = substr($caseNum, 0, 5);
my $caseNum2 = substr($caseNum, 5, 3);
print "Filepath : |/ecurep/sf/$caseNum1/$caseNum2/$caseNum/$fileToDownload|\n";
my $downloadFile="/ecurep/sf/$caseNum1/$caseNum2/$caseNum/$fileToDownload"; # file path on ecurep
my $downloadPath1="/home/castle/wlfiles/$caseNum"; # file path to download on bugdbug whilelist
my $downloadPath2="/TMP/$requesterID/$caseNum";    # file path to download on big /TMP

####### Login to bugdbug 
my $x = "bug";
print "X=$x\n" ;

# bugdbug access info
my ( $bugip , $buguid , $bugpw ) = @{$mach{$x}} ;

print "IP = $bugip , UID = $buguid , PW = $bugpw\n" if $DEBUG ;

print "Jun Su [DEBUG] : Preparing to run \"ssh $buguid\@$bugip\"\n\n" if $DEBUG;

# create an Expect object by spawning another process
my $exp = Expect->spawn("ssh $buguid\@$bugip", ) or die "Cannot spawn ssh: $!\n";

print "\nJun Su [DEBUG] : Executed ssh !!! \n" if $DEBUG;

# not needed with ssh login 
#$exp->expect(10, '-re','login:') ;
#$exp->send ( "$uid\n" ) ;

$exp->expect(10, '-re','assword:') ; 
$exp->send ( "$bugpw\n" ) ;

#$exp->interact() ;

# create directory on bugdbug
$exp->expect ( 2, '-re' , '^$' ) ;
$exp->send ( "\nmkdir -p $downloadPath1\n" ) ;

# scp file from ecurep
$x = "ecurep";
my ( $ecurepip , $ecurepid , $ecureppw ) = @{$mach{$x}} ;
$exp->expect ( 2, '-re' , '^$' ) ;
$exp->send ( "\nscp $ecurepid\@$ecurepip:/ecurep/sf/$caseNum1/$caseNum2/$caseNum/$fileToDownload /home/castle/wlfiles/$caseNum \n" ) ;

$exp->expect(10, '-re','assword:') ; 
$exp->send ( "$ecureppw\n" ) ;

$exp->expect ( 2, '-re' , '^$' ) ;
$exp->send ( "\nls $downloadPath1\n" ) ;

$exp->expect ( 2, '-re' , '^$' ) ;
$exp->send ( "\nmkdir -p $downloadPath2\n" ) ;

# copy file to /TMP
$exp->expect ( 2, '-re' , '^$' ) ;
$exp->send ( "\ncp $downloadPath1/* $downloadPath2\n" ) ;

# give permission
$exp->expect ( 2, '-re' , '^$' ) ;
$exp->send ( "\nchmod -Rf 777 $downloadPath2\n" ) ;

$exp->expect ( 2, '-re' , '^$' ) ;
$exp->send ( "\nls $downloadPath2\n" ) ;

#$exp->interact() ;

$exp->expect(2, '-re','$ ') ;
$exp->send ( "exit\n" ) ;

print "\n\n======= Sumary ===========\n\n";
print "$myEmail, $requesterID\n";
system("date");
print "$bugip:$downloadPath1\n";
print "$downloadPath2\n\n";

print "Update this wiki page with above information.\n";
print "https://w3-connections.ibm.com/wikis/home?lang=en-us#!/wiki/W9e008ebc2893_42d2_9f20_2c1b9d5b3007/page/Access%20to%20Whitelisted%20Systems\n";

print "===============================\n";
