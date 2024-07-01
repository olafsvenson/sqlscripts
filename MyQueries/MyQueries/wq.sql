
select r.session_id
    ,s.login_name
    ,s.host_name
	,r.status
	,wait_type
   	,qt.text
	,db_name(r.database_id) AS 'DatabaseName'
	,qt.objectid
	,r.cpu_time
	--,r.total_elapsed_time
	,RIGHT('0' + CAST(DATEDIFF(s, r.start_time, getdate()) / 3600 AS VARCHAR),2) + ':' +
	RIGHT('0' + CAST((DATEDIFF(s, r.start_time, getdate()) / 60) % 60 AS VARCHAR),2) + ':' +
	RIGHT('0' + CAST(DATEDIFF(s, r.start_time, getdate()) % 60 AS VARCHAR),2)
    AS [Total Time]
	,r.percent_complete
	,r.blocking_session_id
	,r.reads
	,r.writes
	,r.logical_reads
	,r.scheduler_id,
	s.row_count
	--,QueryPlan_XML = (SELECT query_plan FROM sys.dm_exec_query_plan(r.plan_handle)) 
from sys.dm_exec_requests r 
inner join sys.dm_exec_sessions s ON r.session_id=s.session_id
	cross apply sys.dm_exec_sql_text(sql_handle) as qt
where r.session_id > 50
order by r.cpu_time DESC

/*
	sp_whoisactive

    dbcc freeproccache

    select * from sysprocesses where spid = 140

	select * from sys.dm_exec_session_wait_stats WHERE session_id = 166
    order by waiting_tasks_count desc

    kill 364

	EXEC master.dbo.sp_Blitz
    EXEC master.dbo.sp_BlitzFirst @ExpertMode = 1
	EXEC master.dbo.sp_BlitzCache @ExpertMode = 1, @Top = 10, @DatabaseName = N'<db>'
	EXEC master.dbo.sp_BlitzWho @ExpertMode = 1
	EXEC master.dbo.sp_BlitzIndex @SkipPartitions = 1 

    select * from 
	    sys.dm_os_waiting_tasks t
    inner join sys.dm_exec_connections c on c.session_id = t.blocking_session_id
    cross apply sys.dm_exec_sql_text(c.most_recent_sql_handle) as h1

    SELECT OBJECT_NAME([object_id])
    FROM sys.partitions
    WHERE partition_id = 72057645947289600

*/
