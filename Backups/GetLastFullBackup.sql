use master
go

IF OBJECT_ID ( 'GetLastFullBackup', 'P' ) IS NOT NULL
    DROP PROCEDURE GetLastFullBackup;
GO  


Create proc GetLastFullBackup (
								@dbname sysname
								, @path nvarchar(256) output
								)
as
SELECT   TOP 1
	   @path = msdb.dbo.backupmediafamily.physical_device_name   
FROM   msdb.dbo.backupmediafamily  
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id  
WHERE  msdb.dbo.backupset.type = 'D' 
	   and msdb.dbo.backupset.is_copy_only = 0
	   AND msdb.dbo.backupset.database_name = @dbname
ORDER BY  msdb.dbo.backupset.backup_start_date DESC

