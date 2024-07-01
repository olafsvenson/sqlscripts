IF ((SELECT COUNT(*) FROM sys.server_event_sessions WHERE [name] = 'History_Locks') > 0) DROP EVENT SESSION [History_Locks] ON SERVER 
GO


CREATE EVENT SESSION History_Locks ON SERVER
ADD EVENT sqlserver.lock_timeout (
ACTION (sqlserver.sql_text, sqlserver.tsql_stack)
)
,ADD EVENT sqlserver.locks_lock_waits (
ACTION (sqlserver.sql_text, sqlserver.tsql_stack)
)
ADD TARGET package0.event_file(SET filename=N'History_Locks.xel',max_file_size=(3),max_rollover_files=(1))
--ADD TARGET package0.ring_buffer WITH (MAX_DISPATCH_LATENCY = 30 SECONDS);
GO
ALTER EVENT SESSION History_Locks ON SERVER STATE = START;
GO