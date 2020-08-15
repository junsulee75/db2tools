[Go to main page](https://github.com/junsulee75/db2tools)

js_db2mon_get_info_by_SQL.pl  
===========

  Imagine you have event few or hundreds of db2mon output files and you want to see performance pattern for a interested SQL statement in a one shot.   
  This is the script that can help.  
  It can be also used for grep some strings pattern under a db2mon output section.   

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


* Example analysis scenario #01 

Checking a couple of db2mon outputs, I noticed an insert SQL shows high portion of wait time percent. (PCT_WAIT_TIME)
So I want to see the pattern in one shot from multiple samples of db2mon outputs.
Now, I can see, PCT_WAIT_TIME had been high steadily.

```
js_db2mon_get_info_by_SQL.pl -f 'db2mon*' -s 'Top SQL statements by execution time' -k 'INSERT INTO cisods.elc_adr_bak'

MEMBER NUM_EXEC    COORD_STMT_EXEC_TIME AVG_COORD_EXEC_TIME PCT_COORD_STMT_EXEC_TIME TOTAL_CPU_TIME       AVG_CPU_TIME         PCT_WAIT_TIME AVG_SECT_TIME AVG_COL_TIME STMT_TEXT 
*    0      689965               206594                0.29                    92.78             16065125                   23         56.43          0.29         0.00 INSERT INTO cisods.elc_adr_bak  values( ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? )                                                                                             
     0      594904               218608                0.36                    92.67             14486217                   24         56.36          0.36         0.00 INSERT INTO cisods.elc_adr_bak  values( ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? )                                                                                             
     0      245046               271705                1.10                    96.56             12704314                   51         22.87          1.10         0.00 INSERT INTO cisods.elc_adr_bak  values( ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? )                                                                                             
     0      199840               295558                1.47                    96.50             12814651                   64         20.15          1.47         0.00 INSERT INTO cisods.elc_adr_bak  values( ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? )                                                                                             
     0      383946               221630                0.57                    95.96             12993893                   33         38.17          0.57         0.00 INSERT INTO cisods.elc_adr_bak  values( ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? )                                                                                             
     0      601155               195389                0.32                    94.00             16027145                   26         59.21          0.32         0.00 INSERT INTO cisods.elc_adr_bak  values( ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? )   
```


For next, I am curious which portion of wait time is consumed mainly.
From here, I can see at least CF wait time is high portion (PCT_CF) while there might be another wait too.

Checking a couple of db2mon outputs, I noticed an insert SQL shows high Wait.  

```
js_db2mon_get_info_by_SQL.pl -f 'db2mon*' -s 'Wait time breakdown for top SQL statements by execution time' -k 'INSERT INTO cisods.elc_adr_bak'

MEMBER PCT_WAIT PCT_LG_DSK PCT_LG_BUF PCT_LOCK PCT_GLB_LOCK PCT_LTCH PCT_RCLM PCT_CF  PCT_PFTCH PCT_DIAG PCT_POOL_R PCT_DIR_R PCT_DIR_W PCT_FCM STMT_TEXT 
     0    56.43       1.15       0.00     0.00         0.00     0.00     0.00   12.39      0.00     0.00       0.00      0.00      0.00    0.00 INSERT INTO cisods.elc_adr_bak  values( ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? )                                                                                             
     0    56.36       0.66       0.00     0.00         0.00     0.00     0.00   16.01      0.00     0.00       0.00      0.00      0.00    0.00 INSERT INTO cisods.elc_adr_bak  values( ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? )                                                                                             
     0    22.87       0.30       0.00     0.00         0.00     0.00     0.00   18.95      0.00     0.00       0.00      0.00      0.00    0.00 INSERT INTO cisods.elc_adr_bak  values( ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? )                                                                                             
     0    20.15       0.16       0.00     0.00         0.00     0.00     0.00   18.51      0.00     0.00       0.00      0.00      0.00    0.00 INSERT INTO cisods.elc_adr_bak  values( ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? )                                                                                             
     0    38.17       0.36       0.00     0.00         0.00     0.00     0.00   16.76      0.00     0.00       0.00      0.00      0.00    0.00 INSERT INTO cisods.elc_adr_bak  values( ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? )                                                                                             
     0    59.21       0.57       0.00     0.00         0.00     0.00     0.00   21.44      0.00     0.00       0.00      0.00      0.00    0.00 INSERT INTO cisods.elc_adr_bak  values( ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ? )  

```


[Go to main page](https://github.com/junsulee75/db2tools)