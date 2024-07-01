IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='locks_test')
DROP EVENT SESSION [locks_test2] ON SERVER
GO

CREATE EVENT SESSION [locks_test2] ON SERVER 
--ADD EVENT sqlserver.lock_acquired(
--ACTION(sqlserver.database_name,sqlserver.sql_text)
--WHERE ([sqlserver].[equal_i_sql_unicode_string]([sqlserver].[database_name],N'Pegasus2008MS') 
--		AND [duration]>(20000000)) -- 20сек
--		)

ADD EVENT sqlserver.lock_timeout(
    WHERE ([duration]>(20000000) AND [resource_0]<>(0)))
ADD TARGET package0.event_file(SET filename=N'locks_test2')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

ALTER EVENT SESSION [locks_test2] ON SERVER STATE = START
GO

IF OBJECT_ID('tempdb.dbo.#blocking', 'U') IS NOT NULL 
  DROP TABLE #blocking; 

-- convert all .xel files in a given folder to a single-column table
-- (alternatively specify an individual file explicitly)
select event_data = convert(xml, event_data)
	into #blocking
from sys.fn_xe_file_target_read_file(N'locks_test2*.xel', null, null, null);


-- SELECT * FROM #blocking

IF OBJECT_ID('tempdb.dbo.#blocking_analys', 'U') IS NOT NULL 
  DROP TABLE #blocking_analys; 



-- create multi-column table from single-column table, explicitly adding needed columns from xml
SELECT 
  --ts    = event_data.value(N'(event/@timestamp)[1]', N'datetime'),
	CONVERT(datetime2,SWITCHOFFSET(CONVERT(datetimeoffset,event_data.value(N'(event/@timestamp)[1]', N'datetime2')),DATENAME(TzOffset, SYSDATETIMEOFFSET()))) AS datetime_local,
	event_data.value('(event/@name)[1]', 'varchar(50)') AS event_type,
	event_data.value('(event/action[@name="session_id"]/value)[1]', 'bigint') AS session_id,
	event_data.value('(event/data[@name="statement"]/value)[1]', 'nvarchar(max)') AS statement,
	event_data.value('(event/data[@name="duration"]/value)[1]', 'bigint')/1000 AS duration_ms,
	event_data.value('(event/data[@name="cpu_time"]/value)[1]', 'bigint')/1000 AS cpu_time_ms,
	event_data.value('(event/data[@name="physical_reads"]/value)[1]', 'bigint') AS physical_reads,
	event_data.value('(event/data[@name="logical_reads"]/value)[1]', 'bigint') AS logical_reads,
	event_data.value('(event/data[@name="writes"]/value)[1]', 'bigint') AS writes,
	event_data.value('(event/data[@name="row_count"]/value)[1]', 'bigint') AS row_count,
	event_data.value('(event/action[@name="database_name"]/value)[1]', 'varchar(255)') AS database_name,
	event_data.value('(event/action[@name="client_hostname"]/value)[1]', 'varchar(255)') AS client_hostname,
	event_data.value('(event/action[@name="client_app_name"]/value)[1]', 'varchar(255)') AS client_app_name
  into #blocking_analys
FROM #blocking


SELECT *
FROM #blocking_analys

