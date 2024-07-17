[Go to main page](https://github.ibm.com/junsulee/db2tools) 

js_dynsnap_parser.pl  
===========

	Usage :
  ```
	js_dynsnap_parser.pl -f <Dynamic snapshot filename>  
  ```
	example : 
  ```
	js_dynsnap_parser.pl -f 'dynsnap.out'
  ```
    This program helps to create a excel output parsing one DB2 dynamic snapshot file
    for analysis like finding top SQL with interested value like average elapsed time, rows read etc.   


* Example analysis scenario #01   

Run the script with one dynamic SQL snapshot file.  

```
$ ls
dynsnap.out

$ js_dynsnap_parser.pl -f 'dynsnap.out'

$ ls
dynsnap.out		dynsnap.out.xlsx
```

![alt text][logo1]

[logo1]: images/dynsnap_01.png "dynsnap_01.png : when opened the generated excel"

And you can sort with any interested columns order.

![alt text][logo2]

[logo2]: images/dynsnap_02_sort.png "dynsnap_02_sort.png : Sorting by an interseted column"

Then, enjoy investigation.

![alt text][logo3]

[logo3]: images/dynsnap_03_sorted.png "dynsnap_02_sorted.png : Sorted"

[Go to main page](https://github.ibm.com/junsulee/db2tools) 