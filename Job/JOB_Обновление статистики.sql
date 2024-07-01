USE [msdb]
GO

/****** Object:  Job [** Обновление статистики]    Script Date: 17.02.2021 9:33:05 ******/
IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'** Обновление статистики')
EXEC msdb.dbo.sp_delete_job @job_name=N'** Обновление статистики', @delete_unused_schedule=1
GO

/****** Object:  Job [** Обновление статистики]    Script Date: 17.02.2021 9:33:05 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 17.02.2021 9:33:06 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'** Обновление статистики', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Обновление статистики старше 3-х дней', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [update]    Script Date: 17.02.2021 9:33:06 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'update', 
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

DECLARE @DateNow DATETIME
SELECT @DateNow = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))

DECLARE @SQL NVARCHAR(MAX)
SELECT @SQL = (
SELECT  ''
	UPDATE STATISTICS ['' + SCHEMA_NAME(o.[schema_id]) + ''].['' + o.name + ''] ['' + s.name + ''] WITH ''
		+ CASE WHEN s.rows < 20000000 THEN ''FULLSCAN'' ELSE ''SAMPLE 25 PERCENT'' END
	    + CASE WHEN s.no_recompute = 1 THEN '', NORECOMPUTE'' ELSE '''' END + '', MAXDOP = 1;''
	FROM (
		SELECT 
			  st.[object_id]
			, st.name
			, st.stats_id
			, st.no_recompute
			, last_update = STATS_DATE(st.[object_id], [st].[stats_id])
			, [sp].[rows]
		FROM sys.stats st WITH(NOLOCK)
			CROSS APPLY [sys].[dm_db_stats_properties]([st].[object_id],[st].[stats_id]) sp
		WHERE auto_created = 0   -- статистика по индексам
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
		AND (
			  last_update IS NULL AND p.total_pages > 0 -- never updated and contains rows
			OR
			  last_update <= DATEADD(dd, 
				CASE WHEN p.total_pages > 4096 -- > 4 MB
					THEN -3 -- updated 3 days ago
					ELSE 0 
				END, @DateNow)
		) --AND [rows] > 25000000
		AND i.type_desc NOT IN (''CLUSTERED COLUMNSTORE'',''NONCLUSTERED COLUMNSTORE'')
		ORDER BY [rows]
FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)'')

--PRINT @SQL
EXEC sys.sp_executesql @SQL', 
		@database_name=N'Pegasus2008', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'_Обновление статистики', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20210211, 
		@active_end_date=99991231, 
		@active_start_time=231500, 
		@active_end_time=235959, 
		@schedule_uid=N'60b70ec6-f18b-414f-86ff-1b7dd1da9d75'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


