--------------------------------------------------------------------------------- 
--Database Backups for all databases For Previous Week 
--------------------------------------------------------------------------------- 
SELECT 
	CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
	msdb.dbo.backupset.database_name, 
	msdb.dbo.backupset.backup_start_date, 
	msdb.dbo.backupset.backup_finish_date, 
	msdb.dbo.backupset.expiration_date, 
	CASE msdb..backupset.type 
	WHEN 'D' THEN 'Database' 
	WHEN 'L' THEN 'Log' 
	END AS backup_type, 
	msdb.dbo.backupset.backup_size, 
	msdb.dbo.backupmediafamily.logical_device_name, 
	is_copy_only,
	msdb.dbo.backupmediafamily.physical_device_name, 
	msdb.dbo.backupset.name AS backupset_name, 
	msdb.dbo.backupset.description 
FROM msdb.dbo.backupmediafamily 
INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 3) -- здесь указываем кол-во дней
--and database_name ='Pegasus2008ms'
ORDER BY 
	msdb.dbo.backupset.database_name, 
	msdb.dbo.backupset.backup_finish_date 
	--\\pecom.local\Backups\SQL\LOG\S-SQLMV-03\Pegasus2008MS\Pegasus2008MS_Log_2020-03-16_13.11.33.BAK
	\\pecom.local\Backups\SQLDCRBI\daily\S-MV-DSR\EXTEMPORE\EXTEMPORE_Diff_2020-05-25_00.31.15.BAK