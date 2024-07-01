IF ((SELECT COUNT(*) FROM sys.server_event_sessions WHERE [name] = 'Deadlocks') > 0) DROP EVENT SESSION [Deadlocks] ON SERVER 
GO

CREATE EVENT SESSION [Deadlocks] ON SERVER 
ADD EVENT sqlserver.xml_deadlock_report(
    ACTION(sqlserver.client_app_name, sqlserver.client_hostname, sqlserver.database_name, sqlserver.plan_handle, sqlserver.session_id, sqlserver.session_server_principal_name, sqlserver.sql_text)
)
ADD TARGET package0.event_file(SET filename = N'Deadlocks.xel')
WITH (MAX_MEMORY=4096 KB, EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS, MAX_DISPATCH_LATENCY=30 SECONDS, MAX_EVENT_SIZE=0 KB, MEMORY_PARTITION_MODE=NONE, TRACK_CAUSALITY=OFF, STARTUP_STATE=ON)
GO

ALTER EVENT SESSION Deadlocks ON SERVER STATE = START
GO