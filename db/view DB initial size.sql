--USE tempdb

--GO

SELECT
      d.type_desc
    , d.name
    , d.physical_name
    , current_size_mb = ROUND(d.size * 8. / 1000, 0)
    , initial_size_mb = ROUND(m.size * 8. / 1000, 0) 
    , auto_grow =
        CASE WHEN d.is_percent_growth = 1
            THEN CAST(d.growth AS VARCHAR(10)) + '%'
            ELSE CAST(ROUND(d.growth * 8. / 1000, 0) AS VARCHAR(10)) + 'MB'
        END,
		Shrink_SQL='DBCC SHRINKFILE (N'''+d.name+''', 500)'
FROM sys.database_files d
JOIN sys.master_files m ON d.[file_id] = m.[file_id]
WHERE m.database_id = DB_ID()

--DBCC SHRINKFILE (N'templog', 80000)

