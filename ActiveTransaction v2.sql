USE Monitoring
go

IF OBJECT_ID (N'Monitoring.dbo.ActiveTransactionJob', N'U') IS NOT NULL
	DROP TABLE Monitoring.dbo.ActiveTransactionJob;

select 
     r.session_id
    ,s.login_name
    ,s.host_name
	,r.status
   	,qt.text
	,db_name(s.database_id) AS 'DBName'
	,qt.objectid
	,r.cpu_time
	,r.total_elapsed_time / 1000 AS 'total_elapsed_time'
	,r.percent_complete
	,r.blocking_session_id
	,r.reads
	,r.writes
	,r.logical_reads
	,r.scheduler_id
	--,QueryPlan_XML = (SELECT query_plan FROM sys.dm_exec_query_plan(r.plan_handle)) 
INTO Monitoring.dbo.ActiveTransactionJob
from sys.dm_exec_requests r 
inner join sys.dm_exec_sessions s ON r.session_id=s.session_id
	cross apply sys.dm_exec_sql_text(sql_handle) as qt
where r.session_id > 50 AND r.session_id <> @@Spid
order by r.cpu_time DESC



DECLARE @headerHtml NVARCHAR(max),@recordsHtml NVARCHAR(max),@footerHtml NVARCHAR(max)

SET @recordsHtml=''

SET @headerHtml = 
N'<H1>Active transaction Report</H1>' +
    N'<table border="1">' +
    N'<tr>'+
	N'<th>SessionID</th>' +
	N'<th width= 100 >Login</th>' +
	N'<th width= 100 >Host</th>' +
	N'<th width= 50 >Status</th>' +
	N'<th width= 150 >Query</th>' +
	N'<th width= 50 >DatabaseName</th>' +
	N'<th>ObjectId</th>' +
	N'<th>CpuTime</th>' +
	N'<th>TotalElamsedTimeIsSec</th>' +
	N'<th>PercentComplete</th>' +
	N'<th>BlockingSessionId</th>' +
	N'<th>Reads</th>' +
	N'<th>Writes</th>' +
	N'<th>LogicalReads</th>' +
	N'<th>ShedulerId</th>' +
	N'</tr>';

SELECT 
	@recordsHtml += N'<tr><td>'+ CAST(session_id AS NVARCHAR(3)) + N'</td>'+
				   N'<td>'+ login_name + N'</td>'+
				   N'<td>'+ host_name  + N'</td>'+
				   N'<td>'+ status + N'</td>'+
				   N'<td>'+ text + N'</td>'+
				   N'<td>'+ DBName + N'</td>'+
				   N'<td>'+ ISNULL(CAST(objectid AS NVARCHAR(15)),'0') + N'</td>'+
				   N'<td>'+ CAST(cpu_time AS NVARCHAR(15)) + N'</td>'+
				   N'<td>'+ CAST(total_elapsed_time AS NVARCHAR(15)) + N'</td>'+
				   N'<td>'+ CAST(percent_complete AS NVARCHAR(3)) + N'</td>'+
				   N'<td>'+ CAST(blocking_session_id AS NVARCHAR(3)) + N'</td>'+
				   N'<td>'+ CAST(reads AS NVARCHAR(15)) + N'</td>'+
				   N'<td>'+ CAST(writes AS NVARCHAR(15)) + N'</td>'+
				   N'<td>'+ CAST(logical_reads AS NVARCHAR(15)) + N'</td>'+
				   N'<td>'+ CAST(scheduler_id AS NVARCHAR(3)) + N'</td>'
FROM Monitoring.dbo.ActiveTransactionJob


SET @footerHtml = '</table>'

SET @headerHtml = @headerHtml + @recordsHtml + @footerHtml


--SELECT @headerHtml


	DECLARE @subj NVARCHAR(100) ='Monitoring: Long transaction '+ @@servername
	

	exec msdb.dbo.sp_send_dbmail
	@profile_name	= N'sql_mail',
	@recipients		= N'vzheltonogov@urbgroup.ru',
	@subject		= @subj,
	@body = @headerHtml,
	@body_format	= 'html',
	@importance		= 'High',
	--@query = @tableHtml,
	--@attach_query_result_as_file = 1,
	@exclude_query_output = 1,
	@query_no_truncate = 1,
	@query_attachment_filename='Report.html'