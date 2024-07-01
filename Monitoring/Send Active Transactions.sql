USE [msdb]
GO
GO

/****** Object:  Job [Send Active Transactions]    Script Date: 06.04.2017 18:07:53 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Send Active Transactions')
EXEC msdb.dbo.sp_delete_job @job_name = N'Send Active Transactions', @delete_unused_schedule=1
GO


/****** Object:  Job [Send Active Transactions]    Script Date: 07.04.2017 13:46:56 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 07.04.2017 13:46:56 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Send Active Transactions', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Описание недоступно.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQLAlert', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [send_report]    Script Date: 07.04.2017 13:46:56 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'send_report', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE Monitoring
go

IF OBJECT_ID (N''Monitoring.dbo.ActiveTransactionJob'', N''U'') IS NOT NULL
	DROP TABLE Monitoring.dbo.ActiveTransactionJob;

select 
     r.session_id
    ,s.login_name
    ,s.host_name
	,r.status
   	,qt.text
	,db_name(s.database_id) AS ''DBName''
	,qt.objectid
	,r.cpu_time
	,r.total_elapsed_time / 1000 AS ''total_elapsed_time''
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

CREATE INDEX IX_logical_reads ON Monitoring.dbo.ActiveTransactionJob(logical_reads DESC)

DECLARE @headerHtml NVARCHAR(max),@recordsHtml NVARCHAR(max),@footerHtml NVARCHAR(max)

SET @recordsHtml=''''

SET @headerHtml = 
N''<H1>Active transaction Report</H1>'' +
    N''<table border="1">'' +
    N''<tr>''+
	N''<th>SessionID</th>'' +
	N''<th width= 100 >Login</th>'' +
	N''<th width= 150 >Host</th>'' +
	N''<th width= 50 >Status</th>'' +
	N''<th width= 150 >Query</th>'' +
	N''<th width= 50 >DatabaseName</th>'' +
	N''<th>ObjectId</th>'' +
	N''<th>CpuTime</th>'' +
	N''<th>TotalElamsedTimeIsSec</th>'' +
	N''<th>PercentComplete</th>'' +
	N''<th>BlockingSessionId</th>'' +
	N''<th>Reads</th>'' +
	N''<th>Writes</th>'' +
	N''<th>LogicalReads</th>'' +
	N''<th>ShedulerId</th>'' +
	N''</tr>'';

SELECT 
	@recordsHtml += CASE
						WHEN logical_reads / 100000 > 0 THEN  N''<tr style="background-color:#ffb841"><td>''      
						ELSE
						   N''<tr><td>''
					END 
				    + CAST(session_id AS NVARCHAR(3)) + N''</td>''+
				   N''<td>''+ login_name + N''</td>''+
				   N''<td>''+ host_name  + N''</td>''+
				   N''<td>''+ status + N''</td>''+
				   N''<td>''+ text + N''</td>''+
				   N''<td>''+ DBName + N''</td>''+
				   N''<td>''+ ISNULL(CAST(objectid AS NVARCHAR(15)),''0'') + N''</td>''+
				   N''<td>''+ CAST(cpu_time AS NVARCHAR(15)) + N''</td>''+
				   N''<td>''+ CAST(total_elapsed_time AS NVARCHAR(15)) + N''</td>''+
				   N''<td>''+ CAST(percent_complete AS NVARCHAR(3)) + N''</td>''+
				   N''<td>''+ CAST(blocking_session_id AS NVARCHAR(3)) + N''</td>''+
				   N''<td>''+ CAST(reads AS NVARCHAR(15)) + N''</td>''+
				   N''<td>''+ CAST(writes AS NVARCHAR(15)) + N''</td>''+
				   N''<td>''+ CAST(logical_reads AS NVARCHAR(15)) + N''</td>''+
				   N''<td>''+ CAST(scheduler_id AS NVARCHAR(3)) + N''</td>''
FROM Monitoring.dbo.ActiveTransactionJob
order by logical_reads DESC

SET @footerHtml = ''</table>''

SET @headerHtml = @headerHtml + @recordsHtml + @footerHtml




	DECLARE @subj NVARCHAR(100) =''Monitoring: Active transaction ''+ @@servername
	

	exec msdb.dbo.sp_send_dbmail
	@profile_name	= N''sql_mail'',
	@recipients		= N''vzheltonogov@urbgroup.ru'',
	@subject		= @subj,
	@body = @headerHtml,
	@body_format	= ''html'',
	@importance		= ''High'',
	--@query = @tableHtml,
	--@attach_query_result_as_file = 1,
	@exclude_query_output = 1,
	@query_no_truncate = 1,
	@query_attachment_filename=''Report.html''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

USE [msdb]
GO

/****** Object:  Alert [CPU Alert]    Script Date: 10.04.2017 13:50:52 ******/
EXEC msdb.dbo.sp_delete_alert @name=N'CPU Alert'
GO

/****** Object:  Alert [CPU Alert]    Script Date: 10.04.2017 13:50:52 ******/
EXEC msdb.dbo.sp_add_alert @name=N'CPU Alert', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=120, 
		@include_event_description_in=1, 
		@notification_message=N'Load CPU > 80% in last 2 minutes.', 
		@category_name=N'[Uncategorized]', 
		@wmi_namespace=N'\\.\ROOT\CIMV2', 
		@wmi_query=N'SELECT * from __InstanceModificationEvent WITHIN 120 WHERE TargetInstance ISA ''Win32_Processor'' and TargetInstance.LoadPercentage > 80', 
		@job_name=N'Send Active Transactions'
GO

USE [msdb]
GO

/****** Object:  Alert [Long Transaction Alert]    Script Date: 10.04.2017 13:51:36 ******/
EXEC msdb.dbo.sp_delete_alert @name=N'Long Transaction Alert'
GO

/****** Object:  Alert [Long Transaction Alert]    Script Date: 10.04.2017 13:51:36 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Long Transaction Alert', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=0, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'Transactions|Longest Transaction Running Time||>|180', 
		@job_name=N'Send Active Transactions'
GO

