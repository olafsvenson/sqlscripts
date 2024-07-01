SELECT  
    local_tcp_port,session_id,connect_time,net_transport ,num_reads ,num_writes,client_net_address ,
	(select text from sys.dm_exec_sql_text(most_recent_sql_handle)) as Query
FROM sys.dm_exec_connections 
order by connect_time  desc