USE [master]
go


DECLARE 
			@database_to_restore nvarchar(128) =  N'Taxi2',
			@last_db_backup nvarchar(260)
			

   
SELECT   TOP 1
	   @last_db_backup = msdb.dbo.backupmediafamily.physical_device_name   
FROM   msdb.dbo.backupmediafamily  
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id  
WHERE  msdb..backupset.type = 'D' 
		AND msdb.dbo.backupset.database_name = @database_to_restore 
ORDER BY  msdb.dbo.backupset.backup_start_date DESC


SELECT  @last_db_backup


/*
ALTER DATABASE [UPP_SNH_test] set SINGLE_USER WITH  rollback immediate


RESTORE DATABASE [UPP_SNH_test] FROM  DISK = @last_db_backup WITH  FILE = 1,  MOVE N'UPP_SNH' TO N'D:\DataSql\UPP_SNH_test.mdf',  MOVE N'UPP_SNH_log' TO N'D:\DataSql\UPP_SNH_test_1.LDF',  NOUNLOAD,  REPLACE,  STATS = 5

ALTER DATABASE [UPP_SNH_test] set RECOVERY SIMPLE


USE [upp_snh_test]
GO
ALTER ROLE [db_owner] ADD MEMBER [SNH\pleykin]
GO

DBCC SHRINKFILE (N'UPP_SNH_log' , 0, TRUNCATEONLY)
go
DBCC SHRINKFILE (N'UPP_SNH' , 0, TRUNCATEONLY)
GO
*/