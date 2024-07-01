/*
https://www.sqlrx.com/find-the-last-time-databases-or-logs-were-restored/
	*/
WITH LastRestore AS
(SELECT ROW_NUMBER() OVER (PARTITION BY h.destination_database_name ORDER BY h.restore_date DESC) AS RowNum,
	h.restore_date AS RestoreDate, 
	bs.database_name AS DBName, 
	CASE h.restore_type WHEN 'D' THEN 'Database'
	  WHEN 'F' THEN 'File'
	  WHEN 'G' THEN 'Filegroup'
	  WHEN 'I' THEN 'Differential'
	  WHEN 'L' THEN 'Log'
	  WHEN 'V' THEN 'Verifyonly'
	  WHEN 'R' THEN 'Revert'
	  ELSE h.restore_type 
	END AS RestoreType,
	CASE h.recovery WHEN 1 THEN CAST('WITH RECOVERY' AS VARCHAR(20))
		WHEN 0 THEN CAST('NORECOVERY' AS VARCHAR(20))
		ELSE CAST(h.recovery AS VARCHAR(20))
	END AS [Recovery],
	bm.physical_device_name AS RestoredFromFile,
	rf.destination_phys_name AS PhysicalDBFileLocation,
	h.user_name AS RestoredByA
	--,bs.first_lsn AS FirstLSN
	--,bs.last_lsn AS LastLSN
FROM msdb.dbo.restorehistory h 
JOIN msdb.dbo.restorefile rf ON h.restore_history_id = rf.restore_history_id
JOIN msdb.dbo.backupset bs ON h.backup_set_id = bs.backup_set_id
JOIN msdb.dbo.backupmediafamily bm ON bs.media_set_id = bm.media_set_id
)
SELECT *
FROM LastRestore
WHERE RowNum = 1
--AND DBName IN ('Database1','Database2','Database3')
ORDER BY DBName ASC