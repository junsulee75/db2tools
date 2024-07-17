#!/usr/bin/perl

##########################################
 # program name : js_chk_dmpbufp.pl
 # Copyright © 2018 Jun Su Lee. All rights reserved.
 # Modifier : Jun Su Lee ( junsulee@au1.ibm.com )
 # Description : Check object id from db2pd -dmpbufp output

 # Category : DB2
 # Usage
 # Date : January 18, 2018
 # Revision History
 #  - Aug. 18 ,  2018 : Add logic to grab object information in rows
 #  Usage example :

#$ js_chk_dmpbufp.pl -i='13369778.000.db2pd.fmt'
#
# ############ Checking the file : 13369778.000.db2pd.fmt 
#
#PageNum PoolID ObjectID ObjectType = 183450 85 137 0
#PageNum PoolID ObjectID ObjectType = 46351 85 25 0
#PageNum PoolID ObjectID ObjectType = 133351 85 25 0
#PageNum PoolID ObjectID ObjectType = 72451 85 25 1
#PageNum PoolID ObjectID ObjectType = 2 85 19 1
#PageNum PoolID ObjectID ObjectType = 375152 85 25 1
#..<snippet>..

##########################################


### Pattern
#x0000  pageKey.pageID.pkPageNum      183450
#x0004  pageKey.pageID.pkPoolID       85
#x0006  pageKey.pageID.pkObjectID     137
#x0008  pageKey.pageID.pkObjectType   0

use strict;
use Getopt::Long;

my @fileList;
my $fileName;

## Global variables to have the values temporarily, this set should be printed out
my $pkPageNum;
my $pkPoolID;
my $pkObjectID;
my $pkObjectType;

GetOptions (
        'i=s' => \$fileName,
) 
or die "Incorrect usage !\n";

@fileList = glob($fileName);

sub doChkDmpbufp {


        my ( $fn ) = @_ ;

        
        open FH, $fn or die "\n\nNo such file $fn\n";
        print "\n ############ Checking the file : $fn \n\n";

        #print "PageNum PoolID ObjectID ObjectType \n";
        while ( <FH> )  {

                if ( m/^x0000\s+pageKey\.pageID\.pkPageNum\s+(\d+)/ ) {
                        #print "aaa=$1\n";
                        $pkPageNum = $1;
                }

                if ( m/^x0004\s+pageKey\.pageID\.pkPoolID\s+(\d+)/ ) {
                        $pkPoolID = $1;
                }

                if ( m/^x0006\s+pageKey\.pageID\.pkObjectID\s+(\d+)/ ) {
                        $pkObjectID = $1;
                }

                if ( m/^x0008\s+pageKey\.pageID\.pkObjectType\s+(\d+)/ ) {
                        $pkObjectType = $1;
                        print "PageNum PoolID ObjectID ObjectType = $pkPageNum $pkPoolID $pkObjectID $pkObjectType\n";

                        ## reset the values after printing out
                        $pkPageNum="";
                        $pkPoolID="";
                        $pkObjectID="";
                        $pkObjectType="";        
                }

        
        }
        close FH;
}
                


foreach my $inputFile ( @fileList ) {

        doChkDmpbufp $inputFile;
        print "\n";
}
