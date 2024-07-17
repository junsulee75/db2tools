[Go to main page](https://github.ibm.com/junsulee/db2tools)

js_db2mon_cf_check.pl  
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

* Example analysis scenario #01   

- Customer provides db2mon taken every 5 minutes whole day. (More than 200 db2mon output files.)
-  roughly saying they had pureScale performance issue around some time slot.
- I am firstly interested in checking pureScale network area considering the customer is using GDPC.
- I pick up one of popular pureScale CF operation 'setLockState' and see the following from my script. 
- Here it proves that there is network side delay.
  Increase in turn around time (col3/col5) while the times are consistent in CF side (col13/col23).

```
[184:au379509@ecurep]:/ecurep/sf/TS001/532/TS001532403/2018-10-26/db2monRoCE25.tar_unpack $ /users/a/u/au379509/github/db2tools/js_db2mon_check.pl -f='db2mon*' -i='SetLockState'

..
*** SetLockState / ProcessSetLockState 
 Col1 : FileName : 
 Col2 : RT_TotReq(0-128) : Round-trip CF command execution : TOTAL_CF_REQUESTS 
 Col3 : RT_AvgTime(0-128): Round-trip CF command execution : AVG_CF_REQUEST_TIME_MICRO
 Col4 : RT_TotReq(1-128) : Round-trip CF command execution : TOTAL_CF_REQUESTS 
 Col5 : RT_AvgTime(1-128): Round-trip CF command execution : AVG_CF_REQUEST_TIME_MICRO
 Col11 : CF_TotReq(128)  : CF-side command execution : TOTAL_CF_REQUESTS
 Col12 : CF_PctTot(128)  : CF-side command execution : PCT_TOTAL_CF_CMD
 Col13 : CF_AvgTime(128)  : CF-side command execution : AVG_CF_REQUEST_TIME_MICRO
 Col21 : CF_TotReq(129)  : CF-side command execution : TOTAL_CF_REQUESTS
 Col22 : CF_PctTot(129)  : CF-side command execution : PCT_TOTAL_CF_CMD
 Col23 : CF_AvgTime(129)  : CF-side command execution : AVG_CF_REQUEST_TIME_MICRO

       FileName      Col2      Col3      Col4      Col5     Col11     Col12     Col13     Col21     Col22     Col23
..
db2mon.10251725    321600     19.86    285156    417.42   1437931     31.08      2.28    735774     30.31      2.31
db2mon.10251730    238158   5626.43    205363   9764.08   1005060     25.80      2.89    546363     30.36      2.36
db2mon.10251735    113852  10607.64     74020  24204.20    438359     18.23      3.01    290899     29.22      2.50
db2mon.10251740    207577   4266.41    150768  12341.99    805844     17.43      2.84    444180     30.62      2.38
db2mon.10251745    103379  14811.38     71825  18873.09    390639     12.24      2.96    237523     31.05      2.57
db2mon.10251750     58689  24307.66     48722  21085.15    239819      8.59      3.00    134900     26.70      2.67
db2mon.10251755    132912  17029.77    118719  14107.82    538204     16.46      2.94    288862     27.02      2.49
db2mon.10251800    128548  16960.02    196684  10570.35    682059     23.05      2.90    292325     30.94      2.51
db2mon.10251805    114459  13986.91     91495  11223.77    454209     19.09      2.87    248585     26.26      2.52
db2mon.10251810    103852    121.26     68004    527.53    413302     20.77      2.52    243192     28.81      2.44
db2mon.10251815    133861    270.34     98347    648.97    555902     21.11      2.39    324108     29.71      2.34
db2mon.10251820    219277    247.79    184085    670.67    960475     24.73      2.34    490958     30.25      2.38
db2mon.10251825    337976    293.34    340721    702.98   1599021     27.74      2.30    747565     31.18      2.29
db2mon.10251830    303546    149.40    286093    583.07   1406356     27.91      2.32    709085     30.24      2.29
db2mon.10251835    313609     29.76    285646    425.40   1436667     30.45      2.37    727328     30.50      2.34
..
```

Benefit)
Imagine you want to do the same manually.
 ( Opening each file by 'vi' and check the interested things. 
   Approx. 30 seconds for the fast hands x 200 outputs. => More than 1.5 hours)
Using the script, 1 second. So we may save 1~2 hours for the same kind of work.

[Go to main page](https://github.ibm.com/junsulee/db2tools) 