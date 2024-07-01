/*
	https://dba.stackexchange.com/questions/188102/who-is-using-my-worker-threads-sql-server-2014-hadr
*/
declare @max int
select @max = max_workers_count from sys.dm_os_sys_info

select 
    @max as 'TotalThreads',
    sum(active_Workers_count) as 'CurrentThreads',
    @max - sum(active_Workers_count) as 'AvailableThreads',
    sum(runnable_tasks_count) as 'WorkersWaitingForCpu',
    sum(work_queue_count) as 'RequestWaitingForThreads' ,
    sum(current_workers_count) as 'AssociatedWorkers'
from  
    sys.dm_os_Schedulers where status='VISIBLE ONLINE'