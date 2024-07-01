
SELECT    
	sys.dm_exec_connections.session_id AS SPID, 
      sys.dm_exec_connections.connect_time AS Connect_Time, 
      DB_NAME(dbid) AS DatabaseName, 
      loginame AS LoginName, 
      sys.dm_exec_connections.auth_scheme as Auth_Scheme,
      sys.dm_exec_connections.net_transport AS Net_Transport,
      sys.dm_exec_connections.protocol_type as Protocol_Type,
      sys.dm_exec_connections.client_net_address as Client_Net_Address,
      sys.dm_exec_connections.local_net_address as Local_Net_Address,
      sys.dm_exec_connections.local_tcp_port as Local_TCP_Port
FROM sys.sysprocesses 
Right Outer JOIN sys.dm_exec_connections
ON sys.sysprocesses.spid=sys.dm_exec_connections.session_id
Order By Auth_Scheme, Net_Transport;