--SELECT name
--FROM sys.databases
--WHERE name LIKE 'Pegasus2008%'

--USE Pegasus2008ab
--GO
----exec sys.sp_cdc_help_jobs  
--exec sys.sp_cdc_change_job @job_type ='capture', @maxtrans = 1000, @maxscans =10, @continuous =0

-- меняем настройки
DECLARE @SQL2 NVARCHAR(MAX)=
(
    SELECT 'USE ['+name+'] exec sys.sp_cdc_change_job @job_type =''capture'', @maxtrans = 1000, @maxscans =10, @continuous =0;'
    FROM sys.databases
	WHERE name LIKE 'Pegasus2008%' AND state_desc='ONLINE'
    
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'
);
print @sql2
EXEC sp_executesql @SQL2;

-- меняем расписание
DECLARE @SQL NVARCHAR(MAX)=
(
    SELECT 'EXEC msdb..sp_update_schedule @schedule_id = '+cast (schedule_id AS varchar(3))
    +',@freq_type = 4 /*Daily*/
    ,@freq_interval = 1 /*Every Day*/
    ,@freq_subday_type = 4 /*min*/
    ,@freq_subday_interval = 5 /*5 min*/
    ,@active_start_time = 000000
    ,@active_end_time = 235959;'
    FROM msdb.dbo.sysschedules
    WHERE name='CDC capture agent schedule.'
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'
);
--print @sql
EXEC sp_executesql @SQL;

-- останавливаем джобы, чтобы они стартанули по расписанию
DECLARE @SQL3 NVARCHAR(MAX)=
(
  SELECT 'EXEC msdb.dbo.sp_stop_job  @job_name=''cdc.'+name+'_capture'';'
    FROM sys.databases
	WHERE name LIKE 'Pegasus2008%' AND state_desc='ONLINE'
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'
);
print @sql3
EXEC sp_executesql @SQL3;


--EXEC msdb.dbo.sp_stop_job  @job_name='cdc.Pegasus2008BB_capture'
