
/*
   информация о блокировках на серверах
*/

SELECT t1.resource_type, 
       t1.resource_database_id, 
       t1.resource_associated_entity_id, 
       OBJECT_NAME(sp.OBJECT_ID) AS ObjectName, 
       t1.request_mode, 
       t1.request_session_id, 
       t2.blocking_session_id
FROM sys.dm_tran_locks AS t1
     JOIN sys.dm_os_waiting_tasks AS t2 ON t1.lock_owner_address = t2.resource_address
     LEFT JOIN sys.partitions sp ON sp.hobt_id = t1.resource_associated_entity_id;