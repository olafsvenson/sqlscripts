
select r.session_id
    ,s.login_name
    ,s.host_name
	,r.status
   	,qt.text
	,db_name(qt.dbid) AS 'dbid'
	,qt.objectid
	,r.cpu_time
	,r.total_elapsed_time
	,r.percent_complete
	,r.blocking_session_id
	,r.reads
	,r.writes
	,r.logical_reads
	,r.scheduler_id
	--,QueryPlan_XML = (SELECT query_plan FROM sys.dm_exec_query_plan(r.plan_handle)) 
from sys.dm_exec_requests r 
inner join sys.dm_exec_sessions s ON r.session_id=s.session_id
	cross apply sys.dm_exec_sql_text(sql_handle) as qt
where r.session_id > 50
order by r.cpu_time DESC

/*
select * from sysprocesses where spid = 56

kill 

*/