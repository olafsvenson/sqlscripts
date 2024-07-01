USE [msdb]
GO


IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'sp_delete_backuphistory')
EXEC msdb.dbo.sp_delete_job @job_name=N'sp_delete_backuphistory', @delete_unused_schedule=1
GO
IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'sp_purge_jobhistory')
EXEC msdb.dbo.sp_delete_job @job_name=N'sp_purge_jobhistory', @delete_unused_schedule=1
GO
IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'syspolicy_purge_history')
EXEC msdb.dbo.sp_delete_job @job_name=N'syspolicy_purge_history', @delete_unused_schedule=1
GO
IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'Maintenance.Очистка msdb')
EXEC msdb.dbo.sp_delete_job @job_name=N'Maintenance.Очистка msdb', @delete_unused_schedule=1
GO
