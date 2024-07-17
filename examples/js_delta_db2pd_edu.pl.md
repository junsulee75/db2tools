[Go to main page](https://github.ibm.com/junsulee/db2tools) 

js_delta_db2pd.edu.pl  
===========

Calculates Delta CPU time of EDUs from multiple 'db2pd -edus' outputs and also generate the excel output.   
In case you don't have perl excel library in the system,    there is other version 'js_delta_db2pd_edu_no_excel.pl'   that skips the excel part and only dump text based output.  
 
  Note : 
   - I know we can do the same with 'db2pd -edus interval=x top=x'.  
     But the reality is we don't always get such flavor of data. (ex. files being collected with 'db2fodc -hang full')  
     I made this script seeing one of my peer took hours to calculate db2pd -edu delta CPU time manually among many iteration outputs.  
     This script is just for doing that and probably reducing investigation time more than hours
 
``` example
js_delta_db2pd_edu.pl -f='db2pd.edu*'
```   

* Example analysis scenario #01   

Calculates CPU delta time from mutlple 'db2pd -edus' samples.  

```
 $ js_delta_db2pd_edu.pl -f='db2pd.edu*' > edu_delta.txt

T1 : 2018-11-16-16.12.38.734640
 T2 : 2018-11-16-16.20.27.330274
 T3 : 2018-11-16-16.27.05.074552
 T4 : 2018-11-16-16.39.36.432892
 T5 : 2018-11-16-16.46.13.118645

*** Total CPU (USER+SYS) delta value
     EDUID             EDUNAME              T2              T3              T4              T5
      1763            db2agent           6.53           5.29          29.37          16.97
      1762            db2agent           7.78          13.47          12.64          13.95
      1761            db2agent           9.72          10.28          27.19           6.07
      1760           db2agntdp          15.60           5.92          29.54          15.92
      1759            db2agent           7.69           0.01           3.74           0.00
      1758            db2agent          18.22           0.00           0.00           0.00
      1757            db2agent          16.20          11.63          21.87          10.51
      1756            db2agent           0.03           0.02           7.48           8.45
      1755            db2agent          13.15           8.54          18.84          13.24
      1754            db2agent           0.02           0.02           0.34           0.02
      1753            db2agent          14.58           8.99          16.03           7.57
      1752            db2agent           9.13           7.54          14.93          16.65
…snippet
```

* Example analysis scenario #02   

Calculates CPU delta time from two samples of 'db2pd -edus'.   (For example, within 'DB2PD' directory from 'db2fodc -full hang' collection.)   

```
 $ js_delta_db2pd_edu.pl -f='db2pd_edu*' 

....

2019-09-02-12.07.17.350389
2019-09-02-12.08.56.923593

 (EDUID/EDU NAME) / Total CPU (USER+SYS) delta value => Matching Kernel TID
74828/db2agent    8.202687 
74723/db2agent    8.190241 
146287/db2agent   8.17356  
99669/db2agent    8.127787 
40238/db2agent    8.117247 
83024/db2agent    8.082274 
62903/db2agent    8.068237 
33050/db2agent    8.066191 
118650/db2agent   8.064444 
64556/db2agent    8.06117  
82767/db2agent    8.044612 
70612/db2agent    8.037202 
145862/db2agent   8.010971 
66501/db2agent    8.002488 
84756/db2agent    7.95241  
93012/db2agent    7.952152 
132309/db2agent   1.358199
...
```


This will generate excel file output together.

If you open the excel, it will have 3 worksheets.  
(Total) USER+SYS / USER / SYS      

![alt text][logo1]

[logo1]: images/edu_delta_01.png "edu_delta_01.png : when opened the generated excel"

And if you sort by a interested column, 

![alt text][logo2]

[logo2]: images/edu_delta_02_sort.png "edu_delta_02_sort.png : Sorting by an interseted column"

It shows the top CPU consumer EDUs.  

![alt text][logo3]

[logo3]: images/edu_delta_03_sorted.png "edu_delta_03_sorted.png : Sorted"

[Go to main page](https://github.ibm.com/junsulee/db2tools) 