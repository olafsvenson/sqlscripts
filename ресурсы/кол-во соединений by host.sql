SELECT host_name, session_id,
       STATUS, 
       COUNT(1) AS [count]
FROM sys.dm_exec_sessions
GROUP BY host_name, session_id,
         STATUS
ORDER BY COUNT(1) DESC;


select * from  sys.dm_exec_sessions