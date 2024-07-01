/*
   просмотр памяти , работающей с исп. мех AWE
*/
select sum (awe_allocated_kb) / 1024 as [AWE Allocated Memory in MB] from sys.dm_os_memory_clerks