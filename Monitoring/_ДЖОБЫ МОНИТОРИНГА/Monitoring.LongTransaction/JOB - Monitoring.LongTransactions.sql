USE [msdb]
GO

IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'Monitoring.LongTransactions')
EXEC msdb.dbo.sp_delete_job @job_name=N'Monitoring.LongTransactions', @delete_unused_schedule=1
GO

/****** Object:  Job [Monitoring.LongTransactions]    Script Date: 05.05.2023 15:41:00 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Support]]    Script Date: 05.05.2023 15:41:01 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Support]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Support]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monitoring.LongTransactions', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Support]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [long transactions]    Script Date: 05.05.2023 15:41:01 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'long transactions', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
 declare @DurationAlert smallint = 180,
   @HTML VARCHAR(MAX)


 IF (OBJECT_ID(''tempdb..##tmpLongTransactionReport'') IS NOT NULL) DROP TABLE ##tmpLongTransactionReport

select 
	s_er.session_id,s_es.[login_name],
	DB_NAME(s_tdt.database_id) as [DB],
	s_er.start_time AS [Begin Time],
	datediff(SS,s_er.start_time,GETDATE()) as Duration,
	s_tdt.[database_transaction_log_record_count] AS [Log Records],
	s_tdt.[database_transaction_log_bytes_used] AS [Log Bytes],
	s_tdt.[database_transaction_log_bytes_reserved] AS [Log Rsvd],
	s_est.[text] AS [Last T-SQL Text]
  -- s_eqp.[query_plan] AS [Last Plan]
into ##tmpLongTransactionReport
from sys.dm_exec_requests s_er
join sys.dm_tran_database_transactions s_tdt
on s_er.transaction_id = s_tdt.transaction_id
  JOIN sys.[dm_exec_sessions] s_es
      ON s_es.[session_id] = s_er.[session_id]
   JOIN sys.dm_exec_connections s_ec
      ON s_ec.[session_id] = s_er.[session_id]      
   CROSS APPLY sys.dm_exec_sql_text (s_ec.[most_recent_sql_handle]) AS s_est
  -- OUTER APPLY sys.dm_exec_query_plan (s_er.[plan_handle]) AS s_eqp
   where datediff(SS,s_er.start_time,GETDATE()) > @DurationAlert
   and s_est.[text] not like ''%sp_readrequest%''
   and s_est.[text] not like ''%sp_cdc_scan%''
   and s_est.[text] not like ''%sp_replcmds%''
  ORDER BY [Begin Time] ASC 

  if not exists(select 1 from ##tmpLongTransactionReport) return;



EXEC sp_ExportTable2Html
    @TableName = ''##tmpLongTransactionReport'', -- varchar(max)
    @OrderBy=''[Begin Time]'',
    @Script = @HTML OUTPUT -- varchar(max)

 SET @HTML = ''
<h2>Long Transaction report</h2><br/>'' + ISNULL(@HTML, '''') 

 EXEC msdb.dbo.sp_send_dbmail
    @profile_name = ''DBA-Alerts'', -- sysname
    @recipients = ''vzheltonogov@sfn-am.ru'', -- varchar(max)
    @subject = N''Long Transaction report'', -- nvarchar(255)
    @body = @HTML, -- nvarchar(max)
    @body_format = ''html''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'_Monitor_long_tran', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20230216, 
		@active_end_date=99991231, 
		@active_start_time=80000, 
		@active_end_time=205959, 
		@schedule_uid=N'd72f0916-6dfe-4023-b335-0e1ddec16eaa'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


