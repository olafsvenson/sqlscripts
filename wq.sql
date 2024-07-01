use master
go

select r.session_id
    ,s.login_name
    ,s.host_name
	,r.status
	,wait_type
   	,qt.text
	,db_name(r.database_id) AS 'DatabaseName'
	--,qt.objectid
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
	,s.row_count
	,QueryPlan_XML = (SELECT query_plan FROM sys.dm_exec_query_plan(r.plan_handle)) 
	,r.plan_handle
	--,LEFT(SUBSTRING(CAST(qp.query_plan AS nvarchar(max)), CHARINDEX('PlanGuideName', 
 --   CAST(qp.query_plan AS nvarchar(max))) + 15, 100), 
 --   CHARINDEX('"', SUBSTRING(CAST(qp.query_plan AS nvarchar(max)), 
 --   CHARINDEX ('PlanGuideName', CAST(qp.query_plan AS nvarchar(max))) + 16, 100))) AS PlanGuideName
from sys.dm_exec_requests r 
inner join sys.dm_exec_sessions s ON r.session_id=s.session_id
	cross apply sys.dm_exec_sql_text(sql_handle) as qt
	outer APPLY sys.dm_exec_query_plan(r.plan_handle) qp
where r.session_id > 50 
order by r.cpu_time DESC

/*
	sp_whoisactive

    dbcc freeproccache
	
    select * from sysprocesses where spid = 85

	select * from sys.dm_exec_session_wait_stats WHERE session_id = 101
    order by waiting_tasks_count desc

    kill 808

	EXEC sp_WhoIsActive  @get_plans = 1@get_transaction_info = 1

	exec [sp_WhoIsActive] 
	@sort_order = '[cpu] desc' , @get_plans = 1,
	@output_column_list = '[session_id],[sql_text],[sql_command],[status],[wait_info],[blocking_session_id],[tran_log_writes],[CPU],[reads],[writes],[physical_reads],[used_memory],[tempdb_allocations]
      ,[tempdb_current],[login_name],[query_plan],[tran_start_time],[open_tran_count],[percent_complete],[host_name],[database_name],[program_name],[additional_info],[start_time],[login_time]
      ,[request_id],[collection_time]';



	-- CPU
	exec [sp_WhoIsActive] 
	@sort_order = '[cpu] desc' , @get_plans = 1,
	@output_column_list = '[dd%][session_id][cpu][used_memory][tempdb_current][status][wait_info][blocking_session_id][database_name][sql_text][query_plan][host_name][program_name][login_name]';

	-- Memory
	exec [sp_WhoIsActive] 
	@sort_order = '[used_memory] desc' ,
	@output_column_list = '[dd%][session_id][used_memory][cpu][tempdb_current][status][wait_info][blocking_session_id][database_name][sql_text][host_name][program_name][login_name]';

	-- Tempdb
	exec sp_whoisactive
	@show_sleeping_spids=0,
	@sort_order = '[tempdb_current] desc',
	@output_column_list = '[dd%][session_id][tempdb_current][used_memory][cpu][status][wait_info][blocking_session_id][database_name][sql_text][host_name][program_name][login_name]';



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
