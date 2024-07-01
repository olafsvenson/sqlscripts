use master
go

create or alter procedure sp_StopLongRunningJob
						@limit_in_hours tinyint,
						@recipients varchar(max)
as

/*
exec sp_StopLongRunningJob @limit_in_hours = 3, @recipients = 'vzheltonogov@sfn-am.ru'

*/
DECLARE @JobName NVARCHAR(1024), @sql NVARCHAR(2000), @sbj NVARCHAR(80);
DECLARE Job_Cursor CURSOR

FOR SELECT j.name
    FROM msdb.dbo.sysjobs J
         JOIN msdb.dbo.sysjobactivity A ON A.job_id = J.job_id
    WHERE A.run_requested_date IS NOT NULL
          AND A.stop_execution_date IS NULL
          AND A.start_execution_date < DATEADD(hh, (-1) * @limit_in_hours, GETDATE()) -- сколько длится джоб
         -- AND j.name LIKE '%capture'; -- фильтр по имени джоба

OPEN Job_Cursor;
FETCH NEXT FROM Job_Cursor INTO @JobName;
WHILE @@FETCH_STATUS = 0
    BEGIN
		SET @sql = 'exec msdb.dbo.sp_stop_job N''' + @JobName + '''';
		--PRINT @sql; 
		exec (@sql)

		set @sbj = 'Следующие длительные джобы были остановлены на сервере ' + @@SERVERNAME

		exec msdb.dbo.sp_send_dbmail
		@recipients = @recipients
		,@subject = @sbj
		,@body = @JobName


        FETCH NEXT FROM Job_Cursor INTO @JobName;
    END;
CLOSE Job_Cursor;
DEALLOCATE Job_Cursor;
go


