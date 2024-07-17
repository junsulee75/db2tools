[Go to main page](https://github.ibm.com/junsulee/db2tools) 
# viewstacks.pl   

[Download](https://github.ibm.com/junsulee/db2tools/blob/master/viewstacks.pl)    

- Imagine you have tends of FODC directories or multiple DPF partitions have FODC directories.      
  And you want to grab  the stack part only and check the majority of stack patterns.     

- Also you want to reduced the number of characters by demangled function name.    


Run the tool to learn how to use.   

```
$ viewstacks.pl

    To show stack pattern from db2 trap or stack files. (only for AIX/Linux86/ppcle. Make sure to run this on the same platform where the trap files come from. )
    Usage 1:
        By default, demangle function names and remove parameters information.
        viewstacks.pl -f '<stack or trap files>'

        example :
        viewstacks.pl -f '*trap.txt'
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
        viewstacks.pl -f '*trap.txt' -c=2
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
         viewstacks.pl -f '*trap.txt' -c=0
        ...
        IPRA.
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
         viewstacks.pl -f 'FODC_*/*trap.txt'
```
