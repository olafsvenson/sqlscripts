USE [msdb]
GO

/****** Object:  Job [SQLAlert-Long Transaction]    Script Date: 31.08.2015 11:14:21 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 31.08.2015 11:14:21 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
select @jobId = job_id from msdb.dbo.sysjobs where (name = N'SQLAlert-Long Transaction')
if (@jobId is NULL)
BEGIN
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'SQLAlert-Long Transaction', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Описание недоступно.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
/****** Object:  Step [send_report]    Script Date: 31.08.2015 11:14:21 ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 1)
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
		@command=N'DECLARE @tableHtml NVARCHAR(max)


SET @tableHtml= '' Select 
	N''''<H1>Long transaction Report</H1>'''' +
    N''''<table border="1">'''' +
    N''''<tr><th>SessionID</th>'''' +
	N''''<th>DatabaseName</th>'''' +
	N''''<th>Command</th>'''' +
    N''''<th>StatementText</th>'''' +
	N''''<th>CommandText</th>'''' +
	N''''<th>Wait_type</th>'''' +
    N''''<th>Wait_time</th>'''' +
	N''''<th>MB used</th>'''' +
	N''''<th>MB used system</th>'''' +
	N''''<th>MB reserved</th>'''' +
	N''''<th>MB reserved system</th>'''' +
	N''''<th>Record count</th>'''' +
	N''''</tr>'''' +
	CAST(
			(SELECT 
			td = b.session_id,'''''''',
			td = CAST(Db_name(a.database_id) AS VARCHAR(20)),'''''''',
			td = c.command,'''''''',
			td = Substring(st.TEXT, ( c.statement_start_offset / 2 ) + 1,(( CASE c.statement_end_offset	 WHEN -1 
																				THEN Datalength(st.TEXT)
																				ELSE c.statement_end_offset
																			END  -	c.statement_start_offset ) / 2 ) + 1),'''''''',
		   td = Coalesce(Quotename(Db_name(st.dbid)) + N''''.'''' + Quotename(
		   Object_schema_name(st.objectid,
					st.dbid)) +
					N''''.'''' + Quotename(Object_name(st.objectid, st.dbid)), ''''''''),'''''''',
		   td = c.wait_type,'''''''',
		   td = c.wait_time,'''''''',
		   td = a.database_transaction_log_bytes_used / 1024.0 / 1024.0,'''''''',
		   td = a.database_transaction_log_bytes_used_system / 1024.0 / 1024.0,'''''''',
		   td = a.database_transaction_log_bytes_reserved / 1024.0 / 1024.0,'''''''',
		   td = a.database_transaction_log_bytes_reserved_system / 1024.0 / 1024.0,
		   td = a.database_transaction_log_record_count
	FROM   sys.dm_tran_database_transactions a
		   JOIN sys.dm_tran_session_transactions b
			 ON a.transaction_id = b.transaction_id
		   JOIN sys.dm_exec_requests c
			   CROSS APPLY sys.Dm_exec_sql_text(c.sql_handle) AS st
			 ON b.session_id = c.session_id
	ORDER  BY a.database_transaction_log_bytes_used / 1024.0 / 1024.0 DESC 
	 FOR XML PATH(''''tr''''), TYPE ) 	 AS NVARCHAR(MAX) ) +
    N''''</table>'''' '';


	--	EXEC sp_executesql @tableHtml

		
	DECLARE @subj NVARCHAR(100) =''SQL Monitoring: Long transaction ''+ @@servername
	DECLARE @bodytext NVARCHAR(100) =''Long transaction''

	exec msdb.dbo.sp_send_dbmail
	@profile_name	= N''sql_mail'',
	@recipients		= N''vzheltonogov@urbgroup.ru'',
	@subject		= @subj,
	--@body = @bodytext,
	@body_format	= ''html'',
	@importance		= ''High'',
	@query = @tableHtml,
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


