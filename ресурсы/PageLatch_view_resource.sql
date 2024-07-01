-- https://habr.com/ru/post/654891/
SELECT wt.session_id, wt.wait_type, wt.wait_duration_ms    
, s.name AS schema_name 
, o.name AS object_name 
, i.name AS index_name  
FROM sys.dm_os_buffer_descriptors bd 
JOIN (      
SELECT *          
, CHARINDEX(':', resource_description) AS file_index       
, CHARINDEX(':', resource_description
, CHARINDEX(':', resource_description)) AS page_index          
, resource_description AS rd 
FROM sys.dm_os_waiting_tasks wt    
WHERE wait_type LIKE 'PAGELATCH%'        
) AS wt     
ON bd.database_id = SUBSTRING(wt.rd, 0, wt.file_index)     
AND bd.file_id = SUBSTRING(wt.rd, wt.file_index, wt.page_index)  
AND bd.page_id = SUBSTRING(wt.rd, wt.page_index, LEN(wt.rd))
JOIN sys.allocation_units au ON bd.allocation_unit_id = au.allocation_unit_id
JOIN sys.partitions p ON au.container_id = p.partition_id
JOIN sys.indexes i ON  p.index_id = i.index_id AND p.object_id = i.object_id
JOIN sys.objects o ON i.object_id = o.object_id 
JOIN sys.schemas s ON o.schema_id = s.schema_id