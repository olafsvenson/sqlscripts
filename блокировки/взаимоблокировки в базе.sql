
/*
   позволяет получить информацию о взаимоблокировках в базе
*/

SELECT l.resource_type, 
       l.resource_associated_entity_id, 
       OBJECT_NAME(sp.object_id) AS ObjectName, 
       l.request_status, 
       l.request_mode, 
       request_session_id, 
       l.resource_description
FROM sys.dm_tran_locks l
     LEFT JOIN sys.partitions sp ON sp.hobt_id = l.resource_associated_entity_id
WHERE l.resource_database_id = DB_ID();