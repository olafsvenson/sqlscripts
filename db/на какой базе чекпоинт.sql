SELECT Queries.session_id, 
       Queries.command, 
       DBs.name AS DBName, 
       Queries.wait_type
FROM sys.dm_exec_requests AS Queries
     LEFT OUTER JOIN sys.databases AS DBs ON DBs.database_id = Queries.database_id
WHERE Queries.command = 'CHECKPOINT';