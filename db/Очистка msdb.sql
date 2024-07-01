-- (1) Либо использовать уже готовые хранимые процедуры sysmail_delete_mailitems_sp и sysmail_delete_log_sp:

DECLARE @DateBefore DATETIME 
SET @DateBefore = DATEADD(DAY, -7, GETDATE())

EXEC msdb.dbo.sysmail_delete_mailitems_sp @sent_before = @DateBefore --, @sent_status = 'sent'
EXEC msdb.dbo.sysmail_delete_log_sp @logged_before = @DateBefore

-- Проверка
SELECT count(1) FROM msdb.dbo.sysmail_mailitems with (nolock) 


-- (2) История выполнения заданий SQL Server Agent также сохраняется в msdb. Когда записей в логе становится много с ним становится не сильно удобно работать, поэтому я стараюсь его периодически чистить sp_purge_jobhistory:

DECLARE @DateBefore DATETIME 
SET @DateBefore = DATEADD(DAY, -7, GETDATE())

EXEC msdb.dbo.sp_purge_jobhistory @oldest_date = @DateBefore

-- (3) Еще нужно упомянуть, про информацию о резервных копиях, которая логируются в msdb. Старые записи о созданных бекапах можно удалять sp_delete_backuphistory:

DECLARE @DateBefore DATETIME 
SET @DateBefore = DATEADD(DAY, -120, GETDATE())

EXEC msdb.dbo.sp_delete_backuphistory @oldest_date = @DateBefore