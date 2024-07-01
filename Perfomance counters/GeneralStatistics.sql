SELECT  *  FROM sys.dm_os_performance_counters 
WHERE object_name = 'MSSQL$PYTHIA:Databases'
and counter_name='Transactions/sec'


