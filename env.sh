#### Set things per OS
os="$(uname)"
echo $os

# Get the directory of the script directory  
DB2TOOLDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "db2tools repo path : |$DB2TOOLDIR|"

if [[ $os = "Linux" ]];
then
        platform="$(uname -i)"

        echo "This is $platform"
        if [[ $platform = "x86_64" ]];
        then
                #### External perl lib.
                ## External perl library that I migrated from other linux platform.
                export PERL5LIB=$DB2TOOLDIR/PERLLNXLIB/lib/perl5:$PERL5LIB
                #echo "setting dependent perl libraries :  |$PERL5LIB|"

        elif [[ $platform = "ppc64le" ]];
        then
                echo "$platform"
        fi

elif [[ $os = "AIX" ]];   ## somehow 'uname -i' does not work on AIX.
then
        echo "This is $os"

else
        print "Not Linux/AIX. Where am I then ???"
fi

export PATH=$DB2TOOLDIR:$PATH
export PERL5LIB=$DB2TOOLDIR/lib:$PERL5LIB

echo "PATH : |$PATH|"
echo "PERL5LIB : |$PERL5LIB|"

