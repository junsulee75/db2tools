# db2tools   

Some of my niche Db2 tool gadgets collection written by myself.  
I am not intending to make great awesome tools   
but my main interested point is saving time if I feel it's better to have a automated script doing same job in the future.   
This repo is for IBM internal analysis purpose.   

js_db2mon_get_info_by_SQL.pl  
===========

  Imagine you have event few or hundreds of db2mon output files and you want to see performance pattern for a interested SQL statement in a one shot.   
  This is the script that can help.  
  It can be also used for grep some strings pattern under a db2mon output section.   
  Actually, it's not limited to SQL but can be used any section with any keyword.     

``` example
Usage:
js_db2mon_get_info_by_SQL.pl -f <filename> -s <section> -k <partial SQL keyword>
-f <filenames>
-s <section name>
  'Top SQL statements by execution time '
  'Top SQL statements by execution time, aggregated by PLANID'
  'Wait time breakdown for top SQL statements by execution time '
  'Top SQL statements by time spent waiting'
  'IO statistics per stmt - top statements by execution time'
 ...
-d <debug mode> -- 1:debug
example : 
js_db2mon_get_info_by_SQL.pl -f 'db2mon*' -s 'Top SQL statements by execution time ' -k 'call TSRQC00.USP_GET_MERCHANT_DTL'
```  

[More detail Example](examples/js_db2mon_get_info_by_SQL.pl.md) 

js_db2mon_cf_chek.pl
===========

In case you have many 'db2mon' outputs and want to see the trend of "Round-trip CF command" and CF-side command execution time of an interested CF function, you may sick of opening each file by vi.  
Also grep/awk would not be easy to get it in one shot.  
Then, this script may help to save the time and get the output quickly.   

``` example
js_db2mon_cf_check.pl

	js_db2mon_cf_check.pl <options>

	-f : File names
	-i : Interested CF functions
	-d : debug mode ( 0 : disable, 1 : Enable )

	Example)
	js_db2mon_cf_check.pl -f 'db2mon*' -i 'WriteAndRegisterMultiple'
```  

Benefit)
Imagine you want to do the same manually.  
 ( Opening each file by 'vi' and check the interested things.   
   Approx. 30 seconds for the fast hands x 200 outputs. => More than 1.5 hours)  
Using the script, 1 second. So we may save 1~2 hours for the same kind of work.

[More detail Example](examples/js_db2mon_cf_check.pl.md) 

js_delta_db2pd_edu.pl
===========

  Calculates Delta CPU time of EDUs from multiple 'db2pd -edus' outputs. 
                This is the version that produces both the plain ascii outputs and excel outputs.
                So to run this you will need to install other excel perl package.
                If you only just want to get plain ascii output without bothering to install this, use other version 'js_delta_db2pd_edu_no_excel.pl' script.
  Note : 
   - I know we can do the same with 'db2pd -edus interval=x top=x'
     But the reality is we don't always get such flavor of data. (ex. files being collected with 'db2fodc -hang full')
     I made this script seeing one of my peer took hours to calculate db2pd -edu delta CPU time manually among many iteration outputs
     This script is just for doing that and probably reducing investigation time more than hours
 
``` example
js_delta_db2pd_edu.pl -f='db2pd.edu*'
```  
[Example](examples/js_delta_db2pd_edu.pl.md) 


js_delta_db2pd_edu_no_excel.pl
===========

  Calculates Delta CPU time of EDUs from multiple 'db2pd -edus' outputs. 
                There is other version 'js_delta_db2pd_edu.pl' that produces excel file as well but that version will need related excel perl package to be installed.
  Note : 
   - I know we can do the same with 'db2pd -edus interval=x top=x'
     But the reality is we don't always get such flavor of data. (ex. files being collected with 'db2fodc -hang full')
     I made this script seeing one of my peer took hours to calculate db2pd -edu delta CPU time manually among many iteration outputs
     This script is just for doing that and probably reducing investigation time more than hours
 
``` example
js_delta_db2pd_edu_no_excel.pl -f='db2pd.edu*'
```   
[Example](examples/js_delta_db2pd_edu_no_excel.pl.md) 

js_dynsnap_parser.pl
===========

   This program helps to create a excel output parsing one DB2 dynamic snapshot file   
   for analysis like finding top SQL with interested value like average elapsed time, rows read etc.    

``` 
	Usage :
	js_dynsnap_parser.pl -f <Dynamic snapshot filename>  

	example : 
	js_dynsnap_parser.pl -f 'dynsnap.out'
```   

[Example](examples/js_dynsnap_parser.pl.md)    

NOTE : Planning to create python version to run within ecurep in near future.   


# js_csv_del_col_delta.pl

Read csv like files (Db2 SQL del output or any csv with comma separated), then print delta values for a pointed Nth column.  
It just reads lines and display delta values between the lines.   
Therefore it's important to give correct order inputs. This script is not responsible for that.    
As of now, this script supports only one column for each line to process.  

``` 
Usage:
-f <filenames>
-c <Nth column>
-k <keyword to grep if any. If not set, reading all lines from files.>
-s <CSV delimiter character. By default, comma.>
-d <debug mode> -- 1:debug
example : 
js_csv_del_col_delta.pl -f 'mon_get_workload.del*' -c=4 -k 'SYSDEFAULTUSERWORKLOAD'
```   

[Example](examples/js_csv_del_col_delta.pl.md)    

NOTE : Planning to enhance to play with multiple columns.    



