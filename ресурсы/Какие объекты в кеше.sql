-- по индексам
select
       count(*)as cached_pages_count,
       obj.name as objectname,
       ind.name as indexname,
       obj.index_id as indexid
from sys.dm_os_buffer_descriptors as bd
    inner join
    (
        select       object_id as objectid,
                           object_name(object_id) as name,
                           index_id,allocation_unit_id
        from sys.allocation_units as au
            inner join sys.partitions as p
                on au.container_id = p.hobt_id
                    and (au.type = 1 or au.type = 3)
        union all
        select       object_id as objectid,
                           object_name(object_id) as name,
                           index_id,allocation_unit_id
        from sys.allocation_units as au
            inner join sys.partitions as p
                on au.container_id = p.partition_id
                    and au.type = 2
    ) as obj
        on bd.allocation_unit_id = obj.allocation_unit_id
left outer join sys.indexes ind 
  on  obj.objectid = ind.object_id
 and  obj.index_id = ind.index_id
where bd.database_id = db_id()
  and bd.page_type in ('data_page', 'index_page')
group by obj.name, ind.name, obj.index_id
order by cached_pages_count DESC



-- по индексам
SELECT
	indexes.name AS index_name,
	objects.name AS object_name,
	objects.type_desc AS object_type_description,
	COUNT(*) AS buffer_cache_pages,
	COUNT(*) * 8 / 1024  AS buffer_cache_used_MB
FROM sys.dm_os_buffer_descriptors
INNER JOIN sys.allocation_units
ON allocation_units.allocation_unit_id = dm_os_buffer_descriptors.allocation_unit_id
INNER JOIN sys.partitions
ON ((allocation_units.container_id = partitions.hobt_id AND type IN (1,3))
OR (allocation_units.container_id = partitions.partition_id AND type IN (2)))
INNER JOIN sys.objects
ON partitions.object_id = objects.object_id
INNER JOIN sys.indexes
ON objects.object_id = indexes.object_id
AND partitions.index_id = indexes.index_id
WHERE allocation_units.type IN (1,2,3)
AND objects.is_ms_shipped = 0
AND dm_os_buffer_descriptors.database_id = DB_ID()
GROUP BY indexes.name,
		 objects.name,
		 objects.type_desc
ORDER BY COUNT(*) DESC;



-- по таблицам
SELECT
	objects.name AS object_name,
	objects.type_desc AS object_type_description,
	COUNT(*) AS buffer_cache_pages,
	COUNT(*) * 8 / 1024  AS buffer_cache_used_MB
FROM sys.dm_os_buffer_descriptors
INNER JOIN sys.allocation_units
ON allocation_units.allocation_unit_id = dm_os_buffer_descriptors.allocation_unit_id
INNER JOIN sys.partitions
ON ((allocation_units.container_id = partitions.hobt_id AND type IN (1,3))
OR (allocation_units.container_id = partitions.partition_id AND type IN (2)))
INNER JOIN sys.objects
ON partitions.object_id = objects.object_id
WHERE allocation_units.type IN (1,2,3)
AND objects.is_ms_shipped = 0
AND dm_os_buffer_descriptors.database_id = DB_ID()
GROUP BY objects.name,
		 objects.type_desc
ORDER BY COUNT(*) DESC;