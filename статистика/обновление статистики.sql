--USE pegasus2008su
-- use greenbutton
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


DECLARE @DateNow DATETIME
SELECT @DateNow = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))

DECLARE @SQL NVARCHAR(MAX)
SELECT @SQL = (
    SELECT '
	UPDATE STATISTICS [' + SCHEMA_NAME(o.[schema_id]) + '].[' + o.name + '] [' + s.name + ']
		WITH FULLSCAN' + CASE WHEN s.no_recompute = 1 THEN ', NORECOMPUTE' ELSE '' END + ', maxdop=4;'
	FROM (
		SELECT 
			  [object_id]
			, name
			, stats_id
			, no_recompute
			, last_update = STATS_DATE([object_id], stats_id)
		FROM sys.stats WITH(NOLOCK)
		WHERE auto_created = 0
			AND is_temporary = 0 -- 2012+
	) s
	JOIN sys.objects o WITH(NOLOCK) ON s.[object_id] = o.[object_id]
	JOIN (
		SELECT
			  p.[object_id]
			, p.index_id
			, total_pages = SUM(a.total_pages)
		FROM sys.partitions p WITH(NOLOCK)
		JOIN sys.allocation_units a WITH(NOLOCK) ON p.[partition_id] = a.container_id
		GROUP BY 
			  p.[object_id]
			, p.index_id
	) p ON o.[object_id] = p.[object_id] AND p.index_id = s.stats_id
	JOIN sys.indexes AS i ON p.object_id = i.object_id
	LEFT JOIN INFORMATION_SCHEMA.VIEW_TABLE_USAGE v ON v.TABLE_NAME = o.name
	WHERE o.[type] IN ('U', 'V')
		AND o.is_ms_shipped = 0
		AND (
			  last_update IS NULL AND p.total_pages > 0 -- never updated and contains rows
			OR
			  last_update <= DATEADD(dd, 
				CASE WHEN p.total_pages > 4096 -- > 4 MB
					THEN -1 -- updated 1 days ago
					ELSE 0 
				END, @DateNow)
		)
		AND i.type_desc NOT IN ('CLUSTERED COLUMNSTORE','NONCLUSTERED COLUMNSTORE')
		--AND v.view_name LIKE '%מבחגמם%'
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)')

--PRINT @SQL
EXEC sys.sp_executesql @SQL