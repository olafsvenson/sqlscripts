return;
USE [SberbankCSDDataMart]
use [CDIDataMart]
use [SBOLDataMart]
use [SBOLDataMartPSI]
go

select name, is_cdc_enabled from sys.databases where database_id = db_id() 

/*
sys.sp_cdc_change_job [ [ @job_type = ] 'job_type' ]  
    [ , [ @maxtrans = ] max_trans ]   
    [ , [ @maxscans = ] max_scans ]   
    [ , [ @continuous = ] continuous ]   
    [ , [ @pollinginterval = ] polling_interval ]   
    [ , [ @retention ] = retention ]   
    [ @threshold = ] 'delete threshold'
*/
sys.sp_cdc_change_job @job_type ='capture', @maxtrans = 100000, @maxscans = 10, @continuous = 0

exec sys.sp_cdc_help_jobs   

select * from  sys.dm_cdc_log_scan_sessions 
--where end_time='1900-01-01 00:00:00.000'
ORDER BY start_time DESC

USE Pegasus2008ur
GO  
EXEC sys.sp_cdc_enable_db  
GO

USE MyDB  
GO  
EXEC sys.sp_cdc_disable_db  
GO  

-- указываем имя базы
USE db_name 

-- создаем джобы CDC
exec sys.sp_cdc_add_job 'capture', @start_job = 0
GO
exec sys.sp_cdc_add_job 'cleanup', @start_job = 0
GO
-- восстанавливаем конфигурацию
exec sys.sp_cdc_change_job @job_type ='capture', @maxtrans = 1000, @maxscans = 10, @continuous = 0


--Выполнить один раз

-- меняем расписание для "CDC capture agent schedule."
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
PRINT @SQL
EXEC sp_executesql @SQL;

  
EXEC msdb.dbo.sp_stop_job  @job_name='cdc.Pegasus2008_capture'
