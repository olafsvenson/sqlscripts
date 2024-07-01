/*
	http://www.nikoport.com/2015/09/22/columnstore-indexes-part-67-clustered-columstore-isolation-levels-transactional-locking/
*/

SELECT dm_tran_locks.request_session_id,
       dm_tran_locks.resource_database_id,
       DB_NAME(dm_tran_locks.resource_database_id) AS dbname,
       CASE
           WHEN resource_type = 'object'
               THEN OBJECT_NAME(dm_tran_locks.resource_associated_entity_id)
           ELSE OBJECT_NAME(partitions.object_id)
       END AS ObjectName,
       partitions.index_id,
       indexes.name AS index_name,
       dm_tran_locks.resource_type,
       dm_tran_locks.resource_description,
       dm_tran_locks.resource_associated_entity_id,
       dm_tran_locks.request_mode,
       dm_tran_locks.request_status
FROM sys.dm_tran_locks
LEFT JOIN sys.partitions ON partitions.hobt_id = dm_tran_locks.resource_associated_entity_id
JOIN sys.indexes ON indexes.object_id = partitions.object_id AND indexes.index_id = partitions.index_id
WHERE resource_associated_entity_id > 0
  AND resource_database_id = DB_ID()
ORDER BY request_session_id, resource_associated_entity_id 