
--DROP TABLE IF EXISTS dbo.#t


			SELECT 
				CASE database_id 
					WHEN 32767 THEN 'ResourceDb' 
					ELSE db_name(database_id) 
				END AS [Database],
				convert(numeric(10,2),sum (case when is_modified=0 then 1 else 0 end)/128.) [Clean_MB],
				convert(numeric(10,2),sum (case when is_modified=1 then 1 else 0 end)/128.) [Dirty_MB],
				convert(numeric(10,2),sum (1)/128.) [Total_MB]
				--INTO #t
			FROM sys.dm_os_buffer_descriptors
			GROUP BY database_id
			ORDER BY convert(numeric(10,2),sum (1)/128.) DESC
option (maxdop 1, recompile)


--SELECT sum(Total_MB)
--FROM #t



SELECT
    databases.name AS database_name,
    COUNT(*) * 8 / 1024 AS mb_used
FROM sys.dm_os_buffer_descriptors
INNER JOIN sys.databases
ON databases.database_id = dm_os_buffer_descriptors.database_id
GROUP BY databases.name
ORDER BY COUNT(*) DESC;