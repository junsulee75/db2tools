#!/usr/bin/perl

##########################################
 # Copyright ? 2023 Jun Su Lee. All rights reserved.
 # Author : Jun Su Lee ( junsulee@au1.ibm.com )
 # Description : to grab lines of multiple db2pd -hadr output
 #
 # Category : DB2 support
 # Usage
 # ./hadrgrab.pl -f='filename' -p='functionname'
 # -p : pattern string 
 # Date : 04.May, 2023
 #
 # Revision History
 # - Nov. 30, 2018 : 
##########################################

use Getopt::Long;

my $DEBUG=1;

my @fileList; ## Input file name list
my $fileName; ## Input file name : command line option


## js_split_snapshot.pl -i='MPSBODB.snapshot.*'
GetOptions (
        'f=s' => \$fileName,    # Filename to read
        'p=s' => \$grabPattern, #  pattern to grab
)
or die "Incorrect Usage ! \n";

# get file list
@fileList = glob($fileName);


sub doGrabWork {

        my ( $fn ) = @_ ;

        open FH, $fn or die ;
        print " \n############### Processing file : $fn \n\n";

        while ( <FH> ) {
                #print $_;

                if ( m/^Database\s.+Date\s(.+)$/ ) {
                        $fileTimeStamp = $1;
                        print "$fileTimeStamp " ;
                }

                #print "$grabPattern \n";
                if ( m/$grabPattern/ ) {
                        print $_;
                }       

        }
}


foreach my $inputFile ( @fileList ) {

        doGrabWork $inputFile;

        print "\n";
}
