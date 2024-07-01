IF OBJECT_ID('tempdb.dbo.#space') IS NOT NULL
    DROP TABLE #space

CREATE TABLE #space (
      database_id INT PRIMARY KEY
    , data_used_size int
    , log_used_size int
)

DECLARE @SQL NVARCHAR(MAX)

SELECT @SQL = STUFF((
    SELECT '
    USE [' + d.name + ']
    INSERT INTO #space (database_id, data_used_size, log_used_size)
    SELECT
          DB_ID()
        , SUM(CASE WHEN [type] = 0 THEN space_used END)
        , SUM(CASE WHEN [type] = 1 THEN space_used END)
    FROM (
        SELECT s.[type], space_used = SUM(FILEPROPERTY(s.name, ''SpaceUsed'') * 8 / 1024)
        FROM sys.database_files s
        GROUP BY s.[type]
    ) t;'
    FROM sys.databases d
    WHERE d.[state] = 0
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '')

EXEC sys.sp_executesql @SQL

SELECT 
	   DB_NAME(S.database_id) AS [Database Name],	
	   S.[name] AS [Logical Name], 
       S.[file_id] AS [File ID], 
       S.[physical_name] AS [File Name], 
       CAST(CAST(G.name AS VARBINARY(256)) AS SYSNAME) AS [FileGroup_Name], 
       ROUND(s.size * 8 / 1024, 0) AS [Initial_Size_mb],
	   DB_sizes.total_size AS [Total_Size_MB],
	   DB_sizes.data_size AS [Data_Size_MB],
	   sp.data_used_size AS [Data_Used_MB],
	   DB_sizes.log_size AS [Log_Size_MB],
	   sp.log_used_size AS [Log_Used_MB],
       CASE
           WHEN S.[max_size] = -1
           THEN 'Unlimited'
           ELSE CONVERT(VARCHAR(10), CONVERT(BIGINT, S.[max_size]) * 8)+' KB'
       END AS [Max Size],
       CASE S.is_percent_growth
           WHEN 1
           THEN CONVERT(VARCHAR(10), S.growth)+'%'
           ELSE CONVERT(VARCHAR(10), S.growth * 8)+' KB'
       END AS [Growth],
       CASE
           WHEN S.[type] = 0
           THEN 'Data Only'
           WHEN S.[type] = 1
           THEN 'Log Only'
           WHEN S.[type] = 2
           THEN 'FILESTREAM Only'
           WHEN S.[type] = 3
           THEN 'Informational purposes Only'
           WHEN S.[type] = 4
           THEN 'Full-text '
       END AS [usage] 
       
FROM sys.master_files AS S
     LEFT JOIN sys.filegroups AS G ON((S.type = 2
                                       OR S.type = 0)
                                      AND (S.drop_lsn IS NULL))
                                     AND (S.data_space_id = G.data_space_id)
LEFT JOIN (
    SELECT
          database_id
        , log_size = SUM(CASE WHEN [type] = 1 THEN size END) * 8 / 1024
        , data_size =SUM(CASE WHEN [type] = 0 THEN size END) * 8 / 1024
        , total_size = SUM(size) * 8 / 1024
    FROM sys.master_files
    GROUP BY database_id
) DB_sizes ON s.database_id = DB_sizes.database_id
LEFT JOIN #space sp ON sp.database_id = s.database_id