# PERL linux x86 libraries  

junsulee@au1.ibm.com    

This is the collection of some perl libraries that are required for my frequently used perl scripts.    
To have consistent libraries reference environment without system dependencies, I gathered some libraries here in this path.   

This is the current included libraries list.    
( Used a clean linuxamd (fedora) system. )       

To use 'cnanm' command, install it in advance by 'root' user.   

```
cpan App::cpanminus
```


```
Library  			: tools that need it. 	: command to get the library   
=======================================================================================================================
Shell.pm 			: snapdiff            	: # cpanm -L /work/perl/PERLLNXLIB Shell.pm
Statistics/Basic.pm 		: snapdiff 		: # cpanm -L /work/perl/PERLLNXLIB Statistics/Basic.pm
Statistics/RankCorrelation.pm	: snapdiff 		: # cpanm -L /work/perl/PERLLNXLIB Statistics/RankCorrelation.pm  
Switch.pm 			: jsgrab.pl		: # cpanm -L /work/perl/PERLLNXLIB Switch.pm
Data::Dumper			: some of my tools	: # cpanm -L /work/perl/PERLLNXLIB Data::Dumper
Excel::Writer::XLSX		: js_delta_db2pd_edu.pl	: # cpanm -L /work/perl/PERLLNXLIB Excel::Writer::XLSX  
Expect.pm			: jsgrab.pl	 	: # cpanm -L /work/perl/PERLLNXLIB Expect.pm   
```

You should add the {extracted path}/lib/perl5 to your PERL5LIB environment variable.       


[Go to top page](../README.md)    
