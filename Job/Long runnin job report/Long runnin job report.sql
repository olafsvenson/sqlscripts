
IF (OBJECT_ID('tempdb..##LongRunningJobReport') IS NOT NULL) DROP TABLE ##LongRunningJobReport

SELECT jobs.name AS [Job_Name]
,CONVERT(VARCHAR(30), ja.start_execution_date, 121) AS [Start_execution_date]
--, ja.stop_execution_date
--,[Duration_secs]
,RIGHT('0' + CAST(DATEDIFF(s, ja.start_execution_date, getdate()) / 3600 AS VARCHAR),2) + ':' +
	RIGHT('0' + CAST((DATEDIFF(s, ja.start_execution_date, getdate()) / 60) % 60 AS VARCHAR),2) + ':' +
	RIGHT('0' + CAST(DATEDIFF(s,ja.start_execution_date, getdate()) % 60 AS VARCHAR),2) as [Duration]
INTO ##LongRunningJobReport
FROM msdb.dbo.sysjobs jobs
LEFT JOIN (
	SELECT *
	FROM msdb.dbo.sysjobactivity
	WHERE session_id = (SELECT MAX(session_id) FROM msdb.dbo.syssessions)
		AND start_execution_date IS NOT NULL
		AND stop_execution_date IS NULL
) AS ja ON ja.job_id = jobs.job_id
CROSS APPLY (
	SELECT DATEDIFF(ss, ja.start_execution_date, GETDATE()) AS [Duration_secs]
) AS ca1
WHERE --jobs.name = 'test' AND
	Duration_secs > 3600 -- 60min

DECLARE @HTML VARCHAR(MAX)

EXEC sp_ExportTable2Html
    @TableName = '##LongRunningJobReport', -- varchar(max)
    @Script = @HTML OUTPUT -- varchar(max)

	DECLARE @sub NVARCHAR(MAX) = 'Long running job(s) detected on: ' + @@SERVERNAME

EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'DBA-ALerts', -- sysname
    @recipients = 'vzheltonogov@sberfn.ru', -- varchar(max)
    @subject = @sub, -- nvarchar(255)
    @body = @HTML, -- nvarchar(max)
    @body_format = 'html'

