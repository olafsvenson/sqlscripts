select * from 
sys.dm_os_waiting_tasks t
inner join sys.dm_exec_connections c on c.session_id = t.blocking_session_id
cross apply sys.dm_exec_sql_text(c.most_recent_sql_handle) as h1

SELECT OBJECT_NAME([object_id])
    FROM sys.partitions
    WHERE partition_id = 72057645947289600