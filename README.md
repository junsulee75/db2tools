# db2tools


js_delta_db2pd_edu.pl
===========

  Calculates Delta CPU time of EDUs from multiple 'db2pd -edus' outputs 
                This is the version that produces both the plain ascii outputs and excel outputs
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

js_delta_db2pd_edu_no_excel.pl
===========

  Calculates Delta CPU time of EDUs from multiple 'db2pd -edus' outputs 
                There is other version 'js_delta_db2pd_edu.pl' that produces excel file as well but that version will need related excel perl package to be installed.
  Note : 
   - I know we can do the same with 'db2pd -edus interval=x top=x'
     But the reality is we don't always get such flavor of data. (ex. files being collected with 'db2fodc -hang full')
     I made this script seeing one of my peer took hours to calculate db2pd -edu delta CPU time manually among many iteration outputs
     This script is just for doing that and probably reducing investigation time more than hours
 
``` example
js_delta_db2pd_edu_no_excel.pl -f='db2pd.edu*'
```



