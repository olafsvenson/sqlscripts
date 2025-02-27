/*
------ Sample backup command (default is copy_only)
BACKUP DATABASE SVSWeb TO DISK = '\\sdsstore\tempstore\AGTDBAs\WREL-19919\SVSWeb_20220805_CO.bak' WITH COMPRESSION, COPY_ONLY, STATS = 10
------ Sample restore command
RESTORE DATABASE WFGOnlineCMSRedesign FROM 
DISK = '\\crdgasqlbu\wfgmodcompass_sql_dump\crdbwfgomod\\WFGOnlineCMSStage\WFGOnlineCMSStage_backup_2016_06_13_1430_CO.BAK'
WITH MOVE 'Orchard_AlphaMyWFG'    TO 'E:\Program Files\Microsoft SQL Server\CRDBWFGOM\MSSQL10_50.CRDBWFGOMOD\MSSQL\DATA\WFGOnlineCMSRedesign.mdf'
	,MOVE 'Orchard_AlphaMyWFG_log' TO 'E:\Program Files\Microsoft SQL Server\CRDBWFGOM\MSSQL10_50.CRDBWFGOMOD\MSSQL\DATA\WFGOnlineCMSRedesign_0.ldf'
	,STATS = 10
*/
/*
------ Backup/Restore progress
SELECT r.session_id,r.command,CONVERT(NUMERIC(6,2),r.percent_complete) AS [Percent Complete],
		CONVERT(VARCHAR(20),DATEADD(ms,r.estimated_completion_time,GetDate()),20) AS [ETA Completion Time],
		CONVERT(NUMERIC(10,2),r.total_elapsed_time/1000.0/60.0) AS [Elapsed Min],
		CONVERT(NUMERIC(10,2),r.estimated_completion_time/1000.0/60.0) AS [ETA Min],
		CONVERT(NUMERIC(10,2),r.estimated_completion_time/1000.0/60.0/60.0) AS [ETA Hours],
		CONVERT(VARCHAR(1000),(SELECT SUBSTRING(text,r.statement_start_offset/2,
								CASE WHEN r.statement_end_offset = -1 THEN 1000 
								ELSE (r.statement_end_offset-r.statement_start_offset)/2 END)
								FROM sys.dm_exec_sql_text(sql_handle)))
FROM sys.dm_exec_requests r WHERE command IN ('RESTORE DATABASE','BACKUP DATABASE')
*/
/*
------ Restore information
SELECT rh.restore_date, rh.destination_database_name, rh.user_name AS restore_user_name, 
	bus.name AS backup_name, bus.user_name AS backup_user_name, bus.backup_finish_date,
	bus.type AS backup_type, bus.server_name, bmf.physical_device_name
FROM restorehistory rh
JOIN backupset bus
	ON rh.backup_set_id = bus.backup_set_id
JOIN backupmediaset bms
	ON bms.media_set_id = bus.media_set_id
JOIN backupmediafamily bmf
	ON bmf.media_set_id = bus.media_set_id
WHERE 1=1
  AND rh.destination_database_name = 'bi_admin'
*/

USE msdb
GO
SELECT TOP 1000 backupset.database_name, backupset.type, 
		backupset.name, backupmediafamily.physical_device_name, backupset.backup_finish_date,
		backupmediafamily.logical_device_name, backupmediafamily.device_type, 
		CAST(backupset.backup_size/1024/1024 as int) AS Size_in_MB,
		datediff(minute,backupset.backup_start_date,backupset.backup_finish_date) backuptime_minutes, is_copy_only
FROM backupset
JOIN backupmediafamily
	ON backupset.media_set_id = backupmediafamily.media_set_id
WHERE 1=1
   AND backupset.type in ('D') -- Full (D), Differential (I) or Log (L) 
 --AND physical_device_name NOT LIKE 'VNB%' -- Ignore backups going to tape
-- AND backupset.database_name like 'pegasys%' -- Only backups for a specific DB or group of DBs
ORDER BY backupset.backup_finish_date DESC, backupset.database_name DESC


