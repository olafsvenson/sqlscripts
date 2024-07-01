--==============================================================================
-- See who is connected to the database.
-- Analyse what each spid is doing, reads and writes.
-- If safe you can copy and paste the killcommand - last column.
-- Marcelo Miorelli
-- 18-july-2017 - London (UK)
-- Tested on SQL Server 2016.
--==============================================================================
USE master
go
SELECT
	KillCommand  = 'Kill '+ CAST(sdes.session_id  AS VARCHAR)
     ,sdes.session_id
    ,sdes.login_time
    ,sdes.last_request_start_time
    ,sdes.last_request_end_time
    ,sdes.is_user_process
    ,encrypt_option
	,sdes.host_name
    ,sdes.program_name
    ,sdes.login_name
    ,sdes.status

    ,sdec.num_reads
    ,sdec.num_writes
    ,sdec.last_read
    ,sdec.last_write
    ,sdes.reads
    ,sdes.logical_reads
    ,sdes.writes

    ,sdest.DatabaseName
    ,sdest.ObjName
    ,sdes.client_interface_name
    ,sdes.nt_domain
    ,sdes.nt_user_name
    ,sdec.client_net_address
    ,sdec.local_net_address
    ,sdest.Query    
FROM sys.dm_exec_sessions AS sdes

INNER JOIN sys.dm_exec_connections AS sdec
        ON sdec.session_id = sdes.session_id

CROSS APPLY (

    SELECT DB_NAME(dbid) AS DatabaseName
        ,OBJECT_NAME(objectid) AS ObjName
        ,COALESCE((
            SELECT TEXT AS [processing-instruction(definition)]
            FROM sys.dm_exec_sql_text(sdec.most_recent_sql_handle)
            FOR XML PATH('')
                ,TYPE
            ), '') AS Query

    FROM sys.dm_exec_sql_text(sdec.most_recent_sql_handle)

) sdest
WHERE sdes.session_id <> @@SPID
  --AND sdest.DatabaseName ='yourdatabasename'
  --and login_name='SFN\elikholat.adm'
  --and client_net_address='10.220.72.154'
ORDER BY sdes.last_request_start_time DESC
--Kill 113
--Kill 75
/*
sp_who2
Kill 241
Kill 84
Kill 77
Kill 112
USE [master]
GO

DROP LOGIN [SFN\iegorov.adm]
GO


USE [master]
GO

DROP LOGIN [SFN\vzheltonogov.adm]
GO
sp_who2
sp_whoisactive @show_sleeping_spids=1
*/