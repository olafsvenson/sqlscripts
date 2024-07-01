USE ssd
go
select 
    OBJECT_NAME(p.object_id) as table_name, 
    u.type_desc,
    f.file_id,
    f.name,
    f.physical_name,
    f.size,
    f.max_size,
    f.growth,
    u.total_pages,
    u.used_pages,
    u.data_pages,
    p.partition_id,
    p.rows
from sys.allocation_units u 
    join sys.database_files f on u.data_space_id = f.data_space_id 
    join sys.partitions p on u.container_id = p.hobt_id
where 
    u.type in (1, 3) 
	and OBJECT_NAME(p.object_id) NOT LIKE 'sys%'
	-- поиск таблицы
    and OBJECT_NAME(p.object_id) = 's-sqlmv-03_210120'
	-- поиск по файлу
	--and physical_name like 'C:\SQL_DATA\fg2.ndf'
	
GO

SELECT o.[name] AS TableName, i.[name] AS IndexName, fg.[name] AS FileGroupName
FROM sys.indexes i
INNER JOIN sys.filegroups fg ON i.data_space_id = fg.data_space_id
INNER JOIN sys.all_objects o ON i.[object_id] = o.[object_id]
WHERE i.data_space_id = fg.data_space_id AND o.type = 'U'