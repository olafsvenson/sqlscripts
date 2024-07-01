/*
http://sqlcom.ru/helpful-and-interesting/login-failed-for-xxx/

	Поиск по EE
	select [name], description, object_type from sys.dm_xe_objects where [name] = 'login'
*/
CREATE EVENT SESSION [LoginFailureTrace] ON SERVER
ADD EVENT sqlserver.errorlog_written( ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid))
ADD TARGET package0.event_file(SET filename=N'LoginFailureTrace',max_file_size=(128))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_MULTIPLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO