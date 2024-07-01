USE [msdb]
GO

IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'** Отправить отчеты')
EXEC msdb.dbo.sp_delete_job @job_name=N'** Отправить отчеты', @delete_unused_schedule=1
GO


BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'** Отправить отчеты', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Отчеты на почту', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Отчет о состоянии статистики]    Script Date: 11.02.2021 12:44:33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Отчет о состоянии статистики', 
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

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DROP TABLE IF EXISTS #t
GO

DECLARE @DateNow DATETIME
SELECT @DateNow = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))


go


    SELECT 
		DATEADD(dd, 0, DATEDIFF(dd, 0, last_update)) [stats_last_update], 
		count(1) [count]
	into #t
	FROM 
	(
		SELECT 
			  [object_id]
			, name
			, stats_id
			, no_recompute
			, last_update = STATS_DATE([object_id], stats_id)
		FROM sys.stats WITH(NOLOCK)
		WHERE auto_created = 0
			AND is_temporary = 0 -- 2012+
	) s
	JOIN sys.objects o WITH(NOLOCK) ON s.[object_id] = o.[object_id]
	JOIN (
		SELECT
			  p.[object_id]
			, p.index_id
			, total_pages = SUM(a.total_pages)
		FROM sys.partitions p WITH(NOLOCK)
		JOIN sys.allocation_units a WITH(NOLOCK) ON p.[partition_id] = a.container_id
		GROUP BY 
			  p.[object_id]
			, p.index_id
	) p ON o.[object_id] = p.[object_id] AND p.index_id = s.stats_id
	JOIN sys.indexes AS i ON p.object_id = i.object_id
	WHERE o.[type] IN (''U'', ''V'')
		AND o.is_ms_shipped = 0
		AND i.type_desc NOT IN (''CLUSTERED COLUMNSTORE'',''NONCLUSTERED COLUMNSTORE'')
    GROUP BY DATEADD(dd, 0, DATEDIFF(dd, 0, last_update))
	--ORDER BY DATEADD(dd, 0, DATEDIFF(dd, 0, last_update))

	
DECLARE @all_count int
SELECT @all_count = sum([count]) FROM #t

DECLARE @MAIL_BODY VARCHAR(max)
 
/* HEADER */
SET @MAIL_BODY = ''<table border="1" align="center" cellpadding="2" cellspacing="0" style="color:black;font-family:consolas;text-align:center;">'' +
    ''<caption>''+ replace(@@SERVERNAME,''\sql2016'','''')  +'' база ''+ db_name()+''<br>
	Общее кол-во = ''+cast(@all_count AS nvarchar(50))
	+''</caption>
	<tr> 
	<th>stats_last_update</th>
	<th>count</th>
   </tr>''

/* BODY */   
SELECT 
@MAIL_BODY = @MAIL_BODY +
''<tr>'' +
''<td>'' + isnull(cast([stats_last_update] AS nvarchar(50)),'''')+ ''</td>'' +
''<td>'' + cast([count] AS nvarchar(50)) + ''</td>'' +
''</tr>''
FROM #t
where [stats_last_update] > dateadd(dd,-14,getdate())
ORDER BY [stats_last_update]

SELECT @MAIL_BODY = @MAIL_BODY + ''</table>''

--SELECT @MAIL_BODY


DECLARE @MAIL_SUBJECT VARCHAR(100)

SELECT @MAIL_SUBJECT = ''Statistics report from '' + replace(@@SERVERNAME,''\sql2016'','''')  +'' база ''+ db_name()

EXEC msdb.dbo.sp_send_dbmail
    @profile_name = ''Houston mail'',
    @recipients = ''zheltonogov.vs@pecom.ru'',
    @subject = @MAIL_SUBJECT,
    @body = @MAIL_BODY,
    @body_format=''HTML''
', 
		@database_name=N'Pegasus2008', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'_Отправка отчетов', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20210211, 
		@active_end_date=99991231, 
		@active_start_time=80000, 
		@active_end_time=235959, 
		@schedule_uid=N'30596a0a-4da9-4c42-89fa-a46d93651801'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


