use master
go

IF OBJECT_ID ('CopyLastFullBackup', 'P') IS NOT NULL
    DROP PROCEDURE CopyLastFullBackup;
GO  

Create proc CopyLastFullBackup (
								@dbname sysname
							   ,@destination nvarchar(512)
							   )
as
set nocount on

declare @last_bak_path nvarchar(260)
		,@ag_role sysname

-- получаем путь последнего бекапа
SELECT TOP 1
	   @last_bak_path = msdb.dbo.backupmediafamily.physical_device_name   
FROM   msdb.dbo.backupmediafamily  
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id  
WHERE  msdb.dbo.backupset.type = 'D' 
	   and msdb.dbo.backupset.is_copy_only = 0
	   AND msdb.dbo.backupset.database_name = @dbname
ORDER BY  msdb.dbo.backupset.backup_start_date DESC

-- определяем первичную ноду AlwaysOn(если есть)
SELECT
	@ag_role = hars.role_desc
FROM
	sys.databases d
	INNER JOIN sys.dm_hadr_availability_replica_states hars ON d.replica_id = hars.replica_id
WHERE
	database_id = DB_ID(@dbname);

if @last_bak_path is not null and @destination is not null and (@ag_role <> N'SECONDARY' or @ag_role is null)
	exec master.sys.xp_copy_files @last_bak_path, @destination
GO