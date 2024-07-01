EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'1C_ZUP_SREFL'
GO
/*
Performing a SQL backup and restore cleanup operation using this method can be very slow for a large msdb database. Running this command on a large set of data without using indexes may take hours or even days to complete. Another issue is that this will block backups as it will lock the msdb system tables.

In terms of scalability system tables will perform poorly if not correctly indexed, however the msdb database backup and restore tracking tables do not have indexes. Creating indexes on the msdb SQL backup and recovery history tables will handle the performance issue. The following script creates indexes on msdb history tables:

USE msdb
GO

-- create indexes on the backupset column

CREATE INDEX IX_backupset_backup_set_iid ON backupset(backup_set_id)
GO
CREATE INDEX IX_backupset_backup_set_uuiid ON backupset(backup_set_uuid)
GO
CREATE INDEX IX_backupset_media_set_iid ON backupset(media_set_id)
GO
CREATE INDEX IX_backupset_backup_finish_date_i ON backupset(backup_finish_date)
GO
CREATE INDEX IX_backupset_backup_start_date_i ON backupset(backup_start_date)
GO

-- create index on the backupmediaset column 

CREATE INDEX IX_backupmediaset_media_set_iid ON backupmediaset(media_set_id)
GO

-- create index on the backupfile column 

CREATE INDEX IX_backupfile_backup_set_iid ON backupfile(backup_set_id)
GO

-- create index on the backupmediafamily column 

CREATE INDEX IX_backupmediafamily_media_set_iid ON backupmediafamily(media_set_id)
GO

-- create indexes on the restorehistory column

CREATE INDEX IX_restorehistory_restore_history_iid ON restorehistory(restore_history_id)
GO
CREATE INDEX IX_restorehistory_backup_set_iid ON restorehistory(backup_set_id)
GO

-- create index on the restorefile column

CREATE INDEX IX_restorefile_restore_history_iid ON restorefile(restore_history_id)
GO

--create index on the restorefilegroup column

CREATE INDEX IX_restorefilegroup_restore_history_iid ON restorefilegroup(restore_history_id)
GO
*/