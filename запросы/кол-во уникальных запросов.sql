
select 
   	qt.text
	,r.plan_handle
	,avg(cast( r.total_elapsed_time as bigint)) AS 'avg_total_elapsed_time'
	,count(1) AS [count]
from sys.dm_exec_requests r 
inner join sys.dm_exec_sessions s ON r.session_id=s.session_id
	outer apply sys.dm_exec_sql_text(sql_handle) as qt
group by 
		qt.text
		,r.plan_handle
order by count(1) DESC

/*
DBCC FREEPROCCACHE (0x06000700E9293E25209754593401000001000000000000000000000000000000000000000000000000000000)
ddd
DBCC FREEPROCCACHE (0x060006004F14E909B0FD9C2DF400000001000000000000000000000000000000000000000000000000000000)
DBCC FREEPROCCACHE (0x060006000FDD3A2CB0B168D07F02000001000000000000000000000000000000000000000000000000000000)

	sp_whoisactive

    dbcc freeproccache
	
    select * from sysprocesses where spid = 85

	select * from sys.dm_exec_session_wait_stats WHERE session_id = 101
    order by waiting_tasks_count desc

    kill 199

	EXEC sp_WhoIsActive  @get_transaction_info = 1

	-- CPU
	exec [sp_WhoIsActive] 
	@sort_order = '[cpu] desc' ,
	@output_column_list = '[dd%][session_id][cpu][used_memory][tempdb_current][status][wait_info][blocking_session_id][database_name][sql_text][host_name][program_name][login_name]';

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
