use master
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
go


/* NOTE: You have to configure/set the following 3 variables */
DECLARE @AlertingThresholdMinutes tinyint = 1
		,@MailProfile sysname = 'DBA-Alerts'
		,@Recipients sysname = 'vzheltonogov@sfn-am.ru'
		,@LongestRunningTransaction int;


-------------------------------------------------------------
-- определяем пользовательские транзакции
SELECT
        @LongestRunningTransaction = 
                MAX(DATEDIFF(n, dtat.transaction_begin_time, GETDATE())) 
FROM 
        sys.dm_tran_active_transactions dtat 
INNER JOIN sys.dm_tran_session_transactions dtst 
        ON dtat.transaction_id = dtst.transaction_id;


IF ISNULL(@LongestRunningTransaction,0) > @AlertingThresholdMinutes BEGIN 

			IF (OBJECT_ID('tempdb..##tmpCurrentQueries') IS NOT NULL) DROP TABLE ##tmpCurrentQueries

			select r.session_id
				,s.login_name
				,s.host_name
			 ,r.status
			 ,wait_type
				,qt.text
			 ,db_name(r.database_id) AS 'DatabaseName'
			 ,r.cpu_time
			 ,RIGHT('0' + CAST(DATEDIFF(s, r.start_time, getdate()) / 3600 AS VARCHAR),2) + ':' +
			 RIGHT('0' + CAST((DATEDIFF(s, r.start_time, getdate()) / 60) % 60 AS VARCHAR),2) + ':' +
			 RIGHT('0' + CAST(DATEDIFF(s, r.start_time, getdate()) % 60 AS VARCHAR),2)    AS [Total Time]
			 ,r.percent_complete
			 ,r.blocking_session_id
			 ,r.reads
			 ,r.writes
			 ,r.logical_reads
			 ,s.row_count
			into ##tmpCurrentQueries
			from sys.dm_exec_requests r 
			inner join sys.dm_exec_sessions s ON r.session_id=s.session_id
			 cross apply sys.dm_exec_sql_text(sql_handle) as qt
			 outer APPLY sys.dm_exec_query_plan(r.plan_handle) qp
			where r.session_id > 50 and r.session_id <> @@SPID
			order by r.cpu_time DESC


			if not exists(select 1 from ##tmpCurrentQueries) return;

			declare @HTML VARCHAR(MAX)

			EXEC sp_ExportTable2Html
				@TableName = '##tmpCurrentQueries', -- varchar(max)
				@OrderBy='[cpu_time] desc',
				@Script = @HTML OUTPUT -- varchar(max)

			 SET @HTML = '
			<h2>Long running queries report</h2>
			Last 20 records<br/><br/>' + ISNULL(@HTML, '') 

 
			 EXEC msdb.dbo.sp_send_dbmail
				@profile_name = @MailProfile, -- sysname
				@recipients = @Recipients, -- varchar(max)
				@subject = N'Long running queries Report', -- nvarchar(255)
				@body = @HTML, -- nvarchar(max)
				@body_format = 'html'

END