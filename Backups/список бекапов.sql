
set arithabort off
set ansi_warnings off


SELECT f.physical_device_name AS file_location, 
       database_name AS [database_name], 
	   b.backup_start_date AS backup_start,
	   b.backup_finish_date AS backup_end,
       CAST (b.backup_size/1024/1024 AS INT) AS [backup_sizeMB], 
	   cast (compressed_backup_size/1024/1024 as int) AS [compressed_backup_sizeMB],
	   cast (compressed_backup_size/1024/1024/1024 as int)  AS [compressed_backup_sizeGB],
       CAST (DATEDIFF(second, b.backup_start_date, b.backup_finish_date) AS VARCHAR(8))+' '+'SECONDS' AS backup_time_taken, 
	   RIGHT ('0' + CAST(DATEDIFF(s, b.backup_start_date, b.backup_finish_date) / 3600 AS VARCHAR),2) + ':' +
	   RIGHT ('0' + CAST((DATEDIFF(s, b.backup_start_date, b.backup_finish_date) / 60) % 60 AS VARCHAR),2) + ':' +
	   RIGHT ('0' + CAST(DATEDIFF(s, b.backup_start_date, b.backup_finish_date) % 60 AS VARCHAR),2) AS [duration] ,
	   CAST ((b.backup_size / (DATEDIFF(ss, b.backup_start_date, b.backup_finish_date)) / 1048576) AS INT) AS [speed MB/Sec],
	   CASE b.[type]
           WHEN 'D' THEN 'Full'
           WHEN 'I' THEN 'Differential'
           WHEN 'L' THEN 'Transaction LOG'
       END AS backup_type,
	   is_copy_only as [copy_only]
	   ,key_algorithm
	   --,b.database_backup_lsn
	   --,b.first_lsn,
	   --b.last_lsn
--into #t
FROM msdb.dbo.backupset b
     INNER JOIN msdb.dbo.backupmediafamily f ON b.media_set_id = f.media_set_id
	where 
		b.[type] in ('d')
		and database_name='Pif3_Prod_Bogdasarova'
	--AND
		
	--and b.backup_start_date BETWEEN '2024-05-01' AND '2024-05-26' 
	--and b.backup_start_date > '2022-01-17'
	/* -- сравнение бекапов двух дат
	AND (
			b.backup_start_date BETWEEN '2020-06-14' AND '2020-06-15' 
			or b.backup_start_date BETWEEN '2020-05-03' AND '2020-05-04' 
			)
	*/
--WHERE backupset.backup_start_date BETWEEN '2014-02-07' AND '2014-03-07' AND (physical_device_name NOT LIKE '%part2%') and physical_device_name NOT LIKE '%part3%'
ORDER BY BACKUP_START DESC;

--2020-06-14 20:14:54.000
--2020-05-03 20:10:58.000
/*
SELECT TOP 100 * FROM dbo.backupset b

SELECT TOP 100 * FROM dbo.backupmediafamily b

SELECT SUM(BACKUP_SIZE) FROM #t

2924388

drop table #t


select [database_name],min([speed MB/Sec]) as [min_speed],max([speed MB/Sec]) as [max_speed]
from #t
group by [database_name]
order by min([speed MB/Sec])
*/