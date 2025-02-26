/*
 use pegasus2008ms
 use pegasus2008bb
 use pegasus2008
 */
 
SELECT 
    s.NAME as SCHEMA_NAME,
    t.NAME AS OBJ_NAME,
    t.type_desc as OBJ_TYPE,
	i.type_desc,
    i.name as indexName,
	i.index_id,
	p.data_compression_desc,
    sum(p.rows) as RowCounts,
    sum(a.total_pages) as TotalPages, 
    --sum(a.used_pages) as UsedPages, 
    --sum(a.data_pages) as DataPages,
    (sum(a.total_pages) * 8) / 1024 as TotalSpaceMB,
    --(sum(a.used_pages) * 8) / 1024 as UsedSpaceMB, 
    --(sum(a.data_pages) * 8) / 1024 as DataSpaceMB
	i.allow_row_locks,
    i.allow_page_locks,
	i.is_disabled,
	RebiuildSQL=N'ALTER INDEX ['+ i.name + N'] ON ['+t.NAME +N'] REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = ON, DATA_COMPRESSION = PAGE, allow_page_locks=off)'
FROM 
    sys.objects t
INNER JOIN
    sys.schemas s ON t.SCHEMA_ID = s.SCHEMA_ID 
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
WHERE 
	t.NAME NOT LIKE 'dt%' 
	and	t.NAME = 'RG_AllObjects_v4'
	-- and TotalSpaceMB > 10000
	-- and i.OBJECT_ID > 255 
	--AND data_compression_desc='NONE'
	--AND i.type_desc='NONCLUSTERED'
	--AND   i.index_id <= 1
GROUP BY 
    s.NAME, t.NAME, t.type_desc, i.object_id, i.index_id, i.name, i.type_desc, p.data_compression_desc,	i.allow_row_locks,  i.allow_page_locks,i.is_disabled
--HAVING (sum(a.total_pages) * 8) / 1024 > 10000
ORDER BY
    sum(a.total_pages) DESC
;

--SELECT TOP 10 * FROM sys.indexes
--ALTER INDEX [_InfoRg40715_1] ON [_InfoRg40715] REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = ON,DATA_COMPRESSION = PAGE)
--ALTER INDEX [_Add_4113_00133] ON [_InfoRg40715] REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = ON,DATA_COMPRESSION = PAGE)
--ALTER INDEX [_InfoRg40715_2] ON [_InfoRg40715] REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = ON,DATA_COMPRESSION = PAGE)
--ALTER INDEX [_InfoRg52139_2] ON [_InfoRg52139] REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = ON,DATA_COMPRESSION = PAGE)