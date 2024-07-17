#!/usr/bin/perl


##########################################
 # program name : viewstacks.pl
 # Copyright ? 2019 Jun Su Lee. All rights reserved.
 # Author : Jun Su Lee ( junsulee@au1.ibm.com )
 # Description : Not a big thing. Initially created for my personal purpose grabbing stack pattern from multiple FODC directories.
 #               Just check stack patterns in one shot with preferred formatting from multiple trap/stack files from multiple FODC_trap directories.
 #               By peers' request, revised some features.
 # Note :
 # - This script assumes c++filt command is set to PATH environment variable.
 # Category : DB2 support
 # Usage
 # viewstacks.pl -f='FODC_Trap*/*trap.txt'
 # Date : Feb.21, 2019
 # Revision History
 # - Aug. 24, 2019 : Split each stack with empty rows
 # - May. 04, 2021 : Add c++filt for Linux if wanted.
 # - Aug. 29, 2023 : File name change ( js_view_stacks.pl => viewstacks.pl ).
 # - Oct. 31, 2023 : Changed c++filt commands from c++ function name => echo function | c++filt so that it works on AIX too.
 # - Jan.   , 2024 : Pick up c++filt path on ecurep AIX hosts. 
 # - Mar. 26, 2024 : Dealing with the pattern 'IPRA.$<function name>' (Alvaro's request)  
 #  
 # Request
 #  - hygiene team) AIX
 #
 # Self note
 # - For ecurep aix, only the host 'itcaix15' had the installed /usr/vacpp/bin/c++filt on old AIX OS version. 
 #   Since ecurep team upgraded AIX OS for all ecurep aix hosts, c++filt command is available from /opt/IBM/xlC/16.1.0/bin.    
 # - In ecurep linux, no need to consider PATH environment as it is located at /usr/bin/c++filt
 # - stack pattern may be different depending on OS or even Db2 versions. Will check one by one when exception patterns are reported.   
 # - May need to handle static function as the function name would not appear in
##########################################

### Input Format. Let's list up all found formats.
## pattern #1 : Usual
#<StackTrace>
#-----FUNC-ADDR---- ------FUNCTION + OFFSET------
#0x00002B7D42E19786 _Z25ossDumpStackTraceInternalmR11OSSTrapFileiP7siginfoPvmm + 0x0356
# ...static function below
#0x0000003B8CC0F7E0 address: 0x0000003B8CC0F7E0 ; dladdress: 0x0000003B8CC00000 ; offset in lib: 0x000000000000F7E0 ;
#...
#</StackTrace>
#


######## start of code

use Getopt::Long;
use File::Basename;

my $fileName;
my $CFILT=1;  # To run c++filt or not. By default, 1 (demangle and remove parameters )   
my @fileList;
my $DEBUG;

my $prog  = basename($0);


sub usage{
        
        print <<AUD ;

    To show stack patterns from db2 trap or stack files. (only for AIX/Linux86/ppcle. Make sure to run this on the same platform where the trap files come from. )  
    Usage 1:
        By default, demangle function names and remove parameters information.  
        $prog -f '<stack or trap files>'

        example : 
        $prog -f '*trap.txt'    
        ...
        IPRA.sqloReadVendorRC
        sqloInvokeVendorFunction
        pdVendorCallWrapper
        pdInvokeCalloutScriptViaVendorAPI
        sqlsDumpSingleQueryDiagnosticsFor955
        sqlsGet955DiagMessage
        ibm_cde::query::WorkUnitPoolInfo::increaseWorkUnitPoolRes
        ... 

    Usage 2 : to print demangled name as it is keeping parameters information together. 
       example : 
        $prog -f '*trap.txt' -c=2
        ...
        IPRA.sqloReadVendorRC(SQLO_VENDOR_HANDLE* const,const int)
        sqloInvokeVendorFunction
        pdVendorCallWrapper
        pdInvokeCalloutScriptViaVendorAPI
        sqlsDumpSingleQueryDiagnosticsFor955(sqlrr_cb*,char*,pdOutageType_t)
        sqlsGet955DiagMessage(SQLS_MEMCONSUMER,STMM_OpAllocMonitor*,char*,unsigned long)
        ibm_cde::query::WorkUnitPoolInfo::increaseWorkUnitPoolRes(unsigned long,unsigned long,bool)
        ...

    Usage 3 : to print as it is without demangling
        example : 
         $prog -f '*trap.txt' -c=0
        ...
        IPRA.$sqloReadVendorRC__FCP18SQLO_VENDOR_HANDLECi
        sqloInvokeVendorFunction
        pdVendorCallWrapper
        pdInvokeCalloutScriptViaVendorAPI
        sqlsDumpSingleQueryDiagnosticsFor955__FP8sqlrr_cbPc14pdOutageType_t
        sqlsGet955DiagMessage__F16SQLS_MEMCONSUMERP19STMM_OpAllocMonitorPcUl
        increaseWorkUnitPoolRes__Q3_7ibm_cde5query16WorkUnitPoolInfoFUlT1b
        checkWorkUnitPoolUsage__Q3_7ibm_cde5query16WorkUnitPoolInfoFv
        evaluate__Q3_7ibm_cde5query9EvaluatorFbT1RQ4_7ibm_cde5query9Evaluator21EvaluatorRestartStatePQ3_7ibm_cde5query19OptPredicateTracker
        ... 

     MISC info : You may run against all stacks on multiple directory. Then you may easily sense if those are same patterns or not.   
        example : 
         $prog -f 'FODC_*/*trap.txt'  

AUD
        exit;
}

&usage if( scalar(@ARGV) < 1 ) ;


GetOptions(
        "filename=s" => \$fileName,
        "cfilt=i" => \$CFILT,
        "debug=i" => \$DEBUG
)
        or die "Incorrect usage ! \n";

@fileList = glob($fileName);


#### default c++filt command 
my $cfiltcmd="c++filt";

#### Check OS 

my  $myos = $^O;  # be careful. It's capital 'o', not zero '0'

if ($myos eq 'aix'){
        $cfiltcmd="/opt/IBM/xlC/16.1.0/bin/$cfiltcmd";   ## ecurep host only for now. itcaix15 and itcaix16
        print "c++filt command : |$cfiltcmd|\n" if $DEBUG;
}

#### Temporoary logic : put full path in case of aix. valid  only in ecurep  host. 
#### TODO : check if c++filt is recongnized, if not, check if aix or linux, if aix, check if the hostname is ecurep AIX, then use /opt/IBM/xlC/16.1.0/bin/c++filt.   for all other systems, give warnings message to find c++filt path and set to PATH.
#### TODO : echo _ZN13SQLO_MEM_POOL10MemTreeGetEmmPP17SqloChunkSubgroupPj |/opt/IBM/xlC/16.1.0/bin/c++filt


sub doParseStackFile {
        my ( $fn ) = @_ ;
        open FH, $fn or die "can't open the file $fn \n\n";

        my $printFlag=0;
        print "\n\n== $fn : ==\n\n";
        while ( <FH> ) {

                ## identifying <StackTrace>
                if ( m/^\<StackTrace\>/ ) {
                        $printFlag=1;
                        print "\n";
                }elsif ( m/^\<\/StackTrace\>/ ) {
                        $printFlag=0;
                        print "\n";
                }


                # Firstly remove the instruction address at left and function offset at right.
                # ex) 
                # 0x00002B42924C450D _ZN15sqlnt_translate26sqlnt_add_column_referenceEP12sqlnt_stringP9sqlnq_pidP9sqlnq_qncP9sqlnq_qunS5_i13SQLNN_BOOLEAN + 0x15cd
                # ==> _ZN15sqlnt_translate26sqlnt_add_column_referenceEP12sqlnt_stringP9sqlnq_pidP9sqlnq_qncP9sqlnq_qunS5_i13SQLNN_BOOLEAN
                if ( m/^0x.*?\s(.+)?\+/ ) {

                        $functionName = $1;

                        if ( $CFILT == 1 || $CFILT == 2 ){  ## only for traps from AIX and Linux platform
                                #system( "c++filt $functionName" ) if $printFlag; # this does not work on AIX. Only for Linux. So need to use below  
                                #system( "echo $functionName |c++filt " ) if $printFlag;  # This way works for both for AIX and Linux
                        
                        
                                # This is to deal with the pattern starting with 'IPRA.$<function name>' . Alvaro's request  
                                # c++filt command ends up leaving the string 'IPRA' only.   
                                # As we still need to know actual function name, manually picking up function and demangle. 
                                # Not sure it's right way but would be fine for technote reference writing purpose.               
                                if ( $functionName =~ m/^IPRA.\$(.+)/ ) {
                                        print "|$functionName|\n" if $DEBUG;                        
                                        $functionName2 = $1;
                                        print "|$functionName2|\n" if $DEBUG;                        

                                        print "IPRA.";
                                        $functionName = $functionName2;
                                        
                                }
                                if ( $CFILT == 2 ) {  ## Demangled form as it is. Keeping paramt
                                        system( "echo $functionName | $cfiltcmd " ) if $printFlag;  
                                }elsif ( $CFILT == 1 ) {  ## Demangle and take out paramter after "("
                                        
                                        # take out parameter information for most simplified. As c++filt is os command, let's do it with cut command at once. 
                                        # Cautious : For the original option "-d\("  , need to use like "-d\\\(" in the 'system' function. 
                                        #system( "echo $functionName | $cfiltcmd |cut -d\( -f1 " ) if $printFlag;  # Error : sh: 0403-057 Syntax error at line 1 : `(' is not expected.
                                        system( "echo $functionName | $cfiltcmd |cut -d\\\( -f1 " ) if $printFlag;  # works. 
                                }
                        }elsif ( $CFILT == 0 ) {
                                print "$functionName\n" if $printFlag;
                        }else { ## actually same option as above, keeping for future usage   
                                print "$functionName\n" if $printFlag;
                        }
                }


                #print "$_" if $printFlag;
        }
        print "\n";

}



foreach my $inputFile (@fileList){
        doParseStackFile $inputFile;
}