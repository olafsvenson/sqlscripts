SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

set arithabort off
set ansi_warnings off

DECLARE @startDate DATETIME;


SET @startDate = GETDATE();



SELECT BS.database_name,

	BS.backup_start_date,
    CONVERT(NUMERIC(10, 1), BF.file_size / 1048576.0) AS SizeMB,
	 cast(bs.compressed_backup_size / 1024/1024/1024 AS bigint)  AS compressed_backup_size, 
      DATEDIFF(SECOND, BS.backup_start_date, BS.backup_finish_date) as BackupSeconds,
      CAST(AVG((BF.file_size / (DATEDIFF(ss, BS.backup_start_date, BS.backup_finish_date)) / 1048576)) AS INT) AS [Avg MB/Sec]
FROM msdb.dbo.backupset AS BS
INNER JOIN msdb.dbo.backupfile AS BF ON BS.backup_set_id = BF.backup_set_id
 --INNER JOIN msdb.dbo.backupmediafamily f ON bs.media_set_id = f.media_set_id
WHERE NOT BS.database_name IN ('master',
                               'msdb',
                               'model',
                               'tempdb')
  AND BF.[file_type] = 'D'
  --AND BS.type = 'D'
 -- AND BS.backup_start_date BETWEEN DATEADD(yy, -1, @startDate) AND @startDate
  AND database_name='Pythoness_Transport_archive'
GROUP BY BS.database_name,BS.backup_start_date,
         CONVERT(NUMERIC(10, 1), BF.file_size / 1048576.0),
		 cast(bs.compressed_backup_size / 1024/1024/1024 AS bigint),
         DATEDIFF(SECOND, BS.backup_start_date, BS.backup_finish_date)
ORDER BY BS.backup_start_date DESC

/*

SELECT Bs.database_name
FROM msdb.dbo.backupset AS BS
     INNER JOIN msdb.dbo.backupfile AS BF ON BS.backup_set_id = BF.backup_set_id
   --  INNER JOIN msdb.dbo.backupmediafamily f ON bs.media_set_id = f.media_set_id;
	

	SELECT * FROM msdb.dbo.backupset with (nolock) 
	SELECT * FROM  msdb.dbo.backupmediafamily with (nolock) 

	SELECT * FROM msdb.dbo.backupfile with (nolock) 
	*/
--

