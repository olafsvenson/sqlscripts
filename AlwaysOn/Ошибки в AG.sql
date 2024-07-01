SELECT agr.replica_server_name, 
   agr.[endpoint_url],
   agrs.connected_state_desc, 
   agrs.last_connect_error_description, 
   agrs.last_connect_error_number, 
   agrs.last_connect_error_timestamp 
FROM sys.dm_hadr_availability_replica_states agrs 
JOIN sys.availability_replicas agr ON agrs.replica_id = agr.replica_id
WHERE agrs.is_local = 1