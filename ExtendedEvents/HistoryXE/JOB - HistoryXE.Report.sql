USE master
go

IF OBJECT_ID('sp_ExportTable2Html', 'P') IS NOT NULL  
    DROP PROCEDURE [dbo].[sp_ExportTable2Html];  
go



CREATE PROCEDURE [dbo].[sp_ExportTable2Html]
	@TableName [varchar](max),
	@UseStandartStyle BIT = 1,
	@Alignment VARCHAR(10) = 'left',
	@OrderBy VARCHAR(MAX) = '',
	@Script VARCHAR(MAX) OUTPUT
AS
BEGIN

SET NOCOUNT ON
	
	DECLARE
	@query NVARCHAR(MAX),
	@Database sysname,
	@Tabel sysname
	
	IF (LEFT(@TableName, 1) = '#')
	BEGIN
		SET @Database = 'tempdb.'
		SET @Tabel = @TableName
	END
	ELSE 
	BEGIN
		SET @Database = LEFT(@TableName, CHARINDEX('.', @TableName))
		SET @Tabel = SUBSTRING(@TableName, LEN(@TableName) - CHARINDEX('.', REVERSE(@TableName)) + 2, LEN(@TableName))
	END
	
	SET @query = '
	SELECT ORDINAL_POSITION, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE
	FROM ' + @Database + 'INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_NAME = ''' + @Tabel + '''
	ORDER BY ORDINAL_POSITION'
	
	IF (OBJECT_ID('tempdb..#Columns') IS NOT NULL) DROP TABLE #Columns
	CREATE TABLE #Columns (
		ORDINAL_POSITION int, 
		COLUMN_NAME sysname, 
		DATA_TYPE nvarchar(128), 
		CHARACTER_MAXIMUM_LENGTH int,
		NUMERIC_PRECISION tinyint, 
		NUMERIC_SCALE int
		)
	
	INSERT INTO #Columns
	EXEC(@query)
	
	IF (@UseStandartStyle = 1)
	BEGIN
	SET @Script = '<html>
		<head>
		<title>Title</title>
		<style type="text/css">
		table { padding:0; border-spacing: 0; border-collapse: collapse;  }
		thead { background: #00B050; border: 1px solid #ddd; }
		th { padding: 10px; font-weight: bold; border: 1px solid #000; color: #fff;}
		tr { padding: 0; }
		td { padding: 5px; border: 1px solid #cacaca; margin:0; text-align:' + @Alignment + '; }
		</style>
		</head>'
	END

SET @Script = ISNULL(@Script, '') + '
	<table>
	<thead>
	<tr>'

-- Заголовок таблицы
	DECLARE 
	@curColumns INT = 1, 
	@totalColumns INT = (SELECT COUNT(*) FROM #Columns), 
	@ColunmnName sysname,
	@ColumnType sysname

	WHILE(@curColumns <= @totalColumns)
	BEGIN
		SELECT @ColunmnName = COLUMN_NAME
		FROM #Columns
		WHERE ORDINAL_POSITION = @curColumns

		SET @Script = ISNULL(@Script, '') + '
		<th>' + @ColunmnName + '</th>'

		SET @curColumns = @curColumns + 1
	END

	SET @Script = ISNULL(@Script, '') + '
	</tr>
	</thead>
	<tbody>'

-- Содержание таблицы
DECLARE @Str VARCHAR(MAX)

	SET @query = '
	SELECT @Str = (
	SELECT '

	SET @curColumns = 1

	WHILE(@curColumns <= @totalColumns)
	BEGIN
		SELECT 
		@ColunmnName = COLUMN_NAME,
		@ColumnType = DATA_TYPE
		FROM 
		#Columns
		WHERE 
		ORDINAL_POSITION = @curColumns

	IF (@ColumnType IN ('int', 'bigint', 'float', 'numeric', 'decimal', 'bit', 'tinyint', 'smallint', 'integer'))
	BEGIN
		SET @query = @query + '
		ISNULL(CAST([' + @ColunmnName + '] AS VARCHAR(MAX)), '''') AS [td]'
	END
	ELSE BEGIN
		SET @query = @query + '
		ISNULL([' + @ColunmnName + '], '''') AS [td]'
	END

	IF (@curColumns < @totalColumns)
		SET @query = @query + ','
		SET @curColumns = @curColumns + 1
	END

	SET @query = @query + '
	FROM ' + @TableName + (CASE WHEN ISNULL(@OrderBy, '') = '' THEN '' ELSE ' 
	ORDER BY ' END) + @OrderBy + '
	FOR XML RAW(''tr''), Elements
	)'
	EXEC tempdb.sys.sp_executesql
	@query,
	N'@Str NVARCHAR(MAX) OUTPUT',
	@Str OUTPUT

	SET @Str = REPLACE(@Str, '<tr>', '
	<tr>')
	SET @Str = REPLACE(@Str, '<td>', '
	<td>')
	SET @Str = REPLACE(@Str, '</tr>', '
	</tr>')
	SET @Script = ISNULL(@Script, '') + @Str
	SET @Script = ISNULL(@Script, '') + '
	</tbody>
	</table>'
END
GO

USE [msdb]
GO


IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'HistoryXE.Report')
EXEC msdb.dbo.sp_delete_job @job_name=N'HistoryXE.Report', @delete_unused_schedule=1
GO

USE [msdb]
GO



/****** Object:  Job [HistoryXE.Report]    Script Date: 24.04.2023 10:41:00 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Support]]    Script Date: 24.04.2023 10:41:00 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Support]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Support]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'HistoryXE.Report', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Отчеты за последний день по данным из HistoryEx', 
		@category_name=N'[Support]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [send]    Script Date: 24.04.2023 10:41:01 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'send', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use master
go

DECLARE @HTML VARCHAR(MAX),
		@HTML1 VARCHAR(MAX),
		@HTML2 VARCHAR(MAX),
		@HTML3 VARCHAR(MAX),
		@HTML4 VARCHAR(MAX),
		@HTML5 VARCHAR(MAX)


-- системные ошибки

 IF (OBJECT_ID(''tempdb..##tmpHistory_SystemErrorsXE'') IS NOT NULL) DROP TABLE ##tmpHistory_SystemErrorsXE

 IF (OBJECT_ID(''[History_SystemErrorsXE]'') IS NOT NULL)
 begin
	;with cte as
	(
	SELECT 
			[Dt_Event]
			,[session_id]
			,[database_name]
			,[session_nt_username]
			,[client_hostname]
			,ClientApp = CASE LEFT(client_app_name, 29)
							WHEN ''SQLAgent - TSQL JobStep (Job ''
								THEN ''SQLAgent Job: '' + (SELECT name FROM msdb..sysjobs sj WHERE substring(client_app_name,32,32)=(substring(sys.fn_varbintohexstr(sj.job_id),3,100))) + '' - '' + SUBSTRING(client_app_name, 67, len(client_app_name)-67)
							ELSE client_app_name
							END 
			,[error_number]
			,[severity]
			,[state]
			,[sql_text]
			,[message]
		FROM [dbo].[History_SystemErrorsXE]
		where 
		--database_name=''pythoness_sbol''
		Dt_Event > dateadd(dd,-1,getdate()) -- за последний день
  
		)
		select  count(1) as [Count]
			,[Last_DT_Event]=(select top 1 max([dt_Event]) from [dbo].[History_SystemErrorsXE] where [message] = cte.[message] 
																				and [database_name] = cte.[database_name] 
																				and [session_nt_username] = cte.[session_nt_username]
																				and [client_hostname] = cte.[client_hostname]
																				and [ClientApp] = cte.[ClientApp]
																				and [error_number] = cte.[error_number]
																				and [severity]=cte.[severity]
																				and [state] = cte.[state]
																				)
			,[database_name]
			,[session_nt_username]
			,[client_hostname]
			,[ClientApp]
			,[error_number]
			,[severity]
			,[state]
			,[query]=(select top 1 sql_text from [dbo].[History_SystemErrorsXE] where [message] = cte.[message] 
																				and [database_name] = cte.[database_name] 
																				and [session_nt_username] = cte.[session_nt_username]
																				and [client_hostname] = cte.[client_hostname]
																				and [ClientApp] = cte.[ClientApp]
																				and [error_number] = cte.[error_number]
																				and [severity]=cte.[severity]
																				and [state] = cte.[state]
																				)
			,[message]
	into [##tmpHistory_SystemErrorsXE]
		from cte
		where ClientApp not in (
								''SQLAgent Job: History_Blocking - Step 1''
								,''SQLAgent Job: History_WhoIsActive - Step 1''
								,''Microsoft SQL Server Management Studio - Query''
								,''Red Gate Software - SQL Tools''
								,''Среда Microsoft SQL Server Management Studio - запрос''
								)
		group by 
			[database_name]
			,[session_nt_username]
			,[client_hostname]
			,[ClientApp]
			,[error_number]
			,[severity]
			,[state]
			,[message]
		order by [count] desc
 
 
	EXEC sp_ExportTable2Html
		@TableName = ''##tmpHistory_SystemErrorsXE'', -- varchar(max)
		@OrderBy=''[count] desc'',
		@Script = @HTML1 OUTPUT -- varchar(max)
end

-- таймауты
IF (OBJECT_ID(''tempdb..##History_TimeoutsXE'') IS NOT NULL) DROP TABLE ##History_TimeoutsXE

 IF (OBJECT_ID(''[History_TimeoutsXE]'') IS NOT NULL)
 begin
	;with cte as
	(
		SELECT  *  
		FROM [master].[dbo].[History_TimeoutsXE] 
		where Dt_Event > dateadd(dd,-1,getdate()) -- за последний день
	)
	select TOP 20 *
	into [##History_TimeoutsXE] 
	from cte
	where client_app_name not in (
									''Microsoft SQL Server Management Studio''
									,''Microsoft SQL Server Management Studio - Transact-SQL IntelliSense''
									,''Среда Microsoft SQL Server Management Studio - IntelliSense для языка Transact-SQL''
								
									)
	ORDER BY dt_event desc

	EXEC sp_ExportTable2Html
		@TableName = ''##History_TimeoutsXE'', -- varchar(max)
		@Script = @HTML2 OUTPUT -- varchar(max)

end 

-- дедлоки
IF (OBJECT_ID(''tempdb..##History_DeadlocksXE'') IS NOT NULL) DROP TABLE ##History_DeadlocksXE


IF (OBJECT_ID(''[History_DeadlocksXE]'') IS NOT NULL)
begin

	;with cte as
	(
		SELECT  * 
		FROM [dbo].[History_DeadlocksXE] 
		where dt_log > dateadd(dd,-1,getdate()) -- за последний день
	)
	select TOP 10 *
	into [##History_DeadlocksXE]
	from cte
	where processClientApp not in (''Red Gate Software - SQL Tools'')
	ORDER BY dt_log desc


	EXEC sp_ExportTable2Html
		@TableName = ''##History_DeadlocksXE'', -- varchar(max)
		@Script = @HTML3 OUTPUT -- varchar(max)

end


-- дедлоки полученные из XE System_Health
IF (OBJECT_ID(''tempdb..##History_SystemDeadlocksXE'') IS NOT NULL) DROP TABLE ##History_SystemDeadlocksXE

IF (OBJECT_ID(''[History_SystemDeadlocksXE]'') IS NOT NULL)
begin

	SELECT TOP 10 *  
	into [##History_SystemDeadlocksXE]
	FROM [dbo].[History_SystemDeadlocksXE] 
	where dt_log > dateadd(dd,-1,getdate()) -- за последний день
	ORDER BY dt_log desc

	EXEC sp_ExportTable2Html
		@TableName = ''##History_SystemDeadlocksXE'', -- varchar(max)
		@Script = @HTML4 OUTPUT -- varchar(max)
end


-- perfomance report
/*
IF (OBJECT_ID(''tempdb..##History_PerfomanceReport'') IS NOT NULL) DROP TABLE ##History_PerfomanceReport
;with cte
as
(
SELECT    sql_text, sql_command, cpu, reads,writes,
CASE
		WHEN DATEDIFF(hour, w.start_time, w.collection_time) > 576 THEN
			DATEDIFF(second, w.collection_time, w.start_time)
		ELSE DATEDIFF(ms, w.start_time, w.collection_time)
END AS duration
, cast(start_time as  date) as [Day]
FROM    dbo.[History_WhoIsActive] w (READPAST)
	where 
			sql_command is not null
			and cast(sql_command  as nvarchar(max)) not like ''%sp_trace%'' and cast(sql_command  as nvarchar(max)) <> ''sys.sp_reset_connection;1'' and cast(sql_command  as nvarchar(max)) <> ''msdb.dbo.sp_readrequest;1'' and cast(sql_command  as nvarchar(max)) not like ''EXECUTE dbo.IndexOptimize%''
			and cast(sql_command  as nvarchar(max)) <> ''tempdb.dbo.RG_WhatsChanged_v4;1'' and cast(sql_command  as nvarchar(max)) not like ''%History%'' and cast(sql_command  as nvarchar(max)) <> ''sys.sp_MScdc_capture_job'' and cast(sql_command  as nvarchar(max)) not like ''%xp_readerrorlog%'' 
			and cast(sql_command  as nvarchar(max)) not like ''%DatabaseBackup%'' and cast(sql_command  as nvarchar(max)) not like ''BACKUP DATABASE%'' and cast(sql_command  as nvarchar(max)) not like ''%DatabaseIntegrityCheck%'' and cast(sql_command  as nvarchar(max)) not like ''%COMMIT TRANSACTION%''
			and cast(sql_command  as nvarchar(max)) not like ''%shrinkdatabase%''
)
select sql_text, sql_command, min([Day]) as [minDay], max([Day]) as [maxDay], max(diffDuration) as [maxDiffDuration]
into tempdb..##History_PerfomanceReport
from (
	SELECT    sql_text, sql_command, avg(cast(cpu as bigint)) as[avgCpu], avg(cast(reads as bigint)) as [avgReads],avg(cast(writes as bigint)) as [avgWrites], avg(cast(duration as bigint)) as [avgDuration], [Day]
	,row_number() over (partition by sql_text, sql_command order by [day]) as [RowNum],
	--min(avg(cast(duration as bigint))) over (partition by sql_text, sql_command order by [day]) as [minDuration],
	--max(avg(cast(duration as bigint))) over (partition by sql_text, sql_command order by [day]) as [maxDuration],
	-- определяем разницу между min и max
	max(avg(cast(duration as bigint))) over (partition by sql_text, sql_command order by [day]) - min(avg(cast(duration as bigint))) over (partition by sql_text, sql_command order by [day]) as [diffDuration]
	from cte
	group by  sql_text, sql_command, [Day]

)q
where [diffDuration] > 200 -- те записи, где разница между минимальным и макс значением больше указанного значения
group by sql_text, sql_command
order by  max(diffDuration) desc

EXEC sp_ExportTable2Html
    @TableName = ''##History_PerfomanceReport'', -- varchar(max)
    @OrderBy=''[maxDiffDuration] desc'',
    @Script = @HTML5 OUTPUT -- varchar(max)
*/

	SET @HTML = ''
<h2>System Errors</h2>
Last 10 records<br/><br/>'' + ISNULL(@HTML1, '''') + ''
 
<br/><br/>
<h2>Timeouts</h2>
Last 20 records:<br/><br/>'' + ISNULL(@HTML2, '''') + ''
 
 
<br/><br/>
<h2>Дедлоки</h2>
Last 10 records:<br/><br/>'' + ISNULL(@HTML3, '''') + ''

<br/><br/>
<h2>Дедлоки полученные из XE System_Health</h2>
Last 10 records:<br/><br/>'' + ISNULL(@HTML4, '''')
/*
+ ''
<br/><br/>
<h2>Perfomance Report</h2>
DiffDuration > 200<br/><br/>'' + ISNULL(@HTML5, '''')
*/


	EXEC msdb.dbo.sp_send_dbmail
    @profile_name = ''DBA-Alerts'', -- sysname
    @recipients = ''vzheltonogov@sfn-am.ru'', -- varchar(max)
    @subject = N''HistoryXE Report'', -- nvarchar(255)
    @body = @HTML, -- nvarchar(max)
    @body_format = ''html''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'HistoryXE.Report', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20211109, 
		@active_end_date=99991231, 
		@active_start_time=81500, 
		@active_end_time=235959, 
		@schedule_uid=N'ec9665b3-7d9e-42ab-9ea9-3c62e3d67267'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


