/*
	https://docs.microsoft.com/ru-ru/archive/blogs/alwaysonpro/troubleshooting-redo-queue-build-up-data-latency-issues-on-alwayson-readable-secondary-replicas-using-the-wait_info-extended-event
*/
-- 1) узнаем сессию которая обслуживает REDO для конкретной базы
 SELECT db_name(database_id) as DBName,
    session_id FROM sys.dm_exec_requests
    WHERE command = 'DB STARTUP'

-- 2) создаем ЕЕ для нужной сессии
 CREATE EVENT SESSION [redo_wait_info] ON SERVER 
ADD EVENT sqlos.wait_info(
    ACTION(package0.event_sequence,
        sqlos.scheduler_id,
        sqlserver.database_id,
        sqlserver.session_id)
    WHERE ([opcode]=(1) AND 
        [sqlserver].[session_id]=(41))) 
ADD TARGET package0.event_file(
    SET filename=N'redo_wait_info')
WITH (MAX_MEMORY=4096 KB,
    EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY=30 SECONDS,
    MAX_EVENT_SIZE=0 KB,
    MEMORY_PARTITION_MODE=NONE,
    TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

-- 3) Запускаем сбор данных на 30 сек
ALTER EVENT SESSION [redo_wait_info] ON SERVER STATE=START

WAITFOR DELAY '00:00:30'

ALTER EVENT SESSION [redo_wait_info] ON SERVER STATE=STOP

-- 4)
Анализируем по примерам из статьи