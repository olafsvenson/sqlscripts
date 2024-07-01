IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='AvgQueryDuration')
DROP EVENT SESSION AvgQueryDuration ON SERVER
GO

CREATE EVENT SESSION [AvgQueryDuration] ON SERVER 
ADD EVENT sqlserver.rpc_completed(
	ACTION(package0.collect_system_time)
	WHERE (  package0.greater_than_uint64(sqlserver.database_id, ( 4 )) -- исключая системные базы
			 AND  package0.equal_boolean(sqlserver.is_system, ( 0 ))
			 AND [package0].[not_equal_unicode_string]([sqlserver].[database_name],N'distribution') -- исключая базы по имени
			-- and [package0].[equal_unicode_string]([sqlserver].[database_name],N'Pegasus2008') --  включая базы 
			--AND duration > 5000000 -- 5 сек
			  AND duration > 200000 -- 200 мс
			  and [logical_reads] > 30000
			  AND NOT [client_app_name] like N'PerfExpert Service'
			 -- and [sqlserver].[username] = N'sa' )  -- CHANGE TO LOGIN YOU WANT TO MONITOR
			--AND sqlserver.client_hostname <> 'A'
		  )
	),
ADD EVENT sqlserver.sql_batch_completed(
ACTION(package0.collect_system_time)
	WHERE (  package0.greater_than_uint64(sqlserver.database_id, ( 4 )) -- исключая системные базы
			 AND  package0.equal_boolean(sqlserver.is_system, ( 0 ))
			 AND [package0].[not_equal_unicode_string]([sqlserver].[database_name],N'distribution') -- исключая базы по имени
			-- and [package0].[equal_unicode_string]([sqlserver].[database_name],N'Pegasus2008') --  включая базы 
			--AND duration > 5000000 -- 5 сек
			  AND duration > 200000 -- 200 мс
			  and [logical_reads] > 30000
			  AND NOT [client_app_name] like N'PerfExpert Service'
			 -- and [sqlserver].[username] = N'sa' )  -- CHANGE TO LOGIN YOU WANT TO MONITOR
			--AND sqlserver.client_hostname <> 'A'
		  )
),
ADD EVENT sqlserver.sql_statement_completed(
ACTION(package0.collect_system_time)
	WHERE (  package0.greater_than_uint64(sqlserver.database_id, ( 4 )) -- исключая системные базы
			 AND  package0.equal_boolean(sqlserver.is_system, ( 0 ))
			 AND [package0].[not_equal_unicode_string]([sqlserver].[database_name],N'distribution') -- исключая базы по имени
			-- and [package0].[equal_unicode_string]([sqlserver].[database_name],N'Pegasus2008') --  включая базы 
			--AND duration > 5000000 -- 5 сек
			  AND duration > 200000 -- 200 мс
			 and [logical_reads] > 30000
			 AND NOT [client_app_name] like N'PerfExpert Service'
			 -- and [sqlserver].[username] = N'sa' )  -- CHANGE TO LOGIN YOU WANT TO MONITOR
			--AND sqlserver.client_hostname <> 'A'
		  )
)

ADD TARGET package0.event_file(SET filename=N'AvgQueryDuration',max_file_size=(10), max_rollover_files = 2 )
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=15 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO


ALTER EVENT SESSION [AvgQueryDuration] ON SERVER
STATE=START
GO
 
/*

ALTER EVENT SESSION [AvgQueryDuration] ON SERVER
STATE=STOP
GO
*/

;
WITH events_cte AS
(
 SELECT 
		CONVERT(datetime2,SWITCHOFFSET(CONVERT(datetimeoffset,xevents.event_data.value('(event/@timestamp)[1]', 'datetime2')),DATENAME(TzOffset, SYSDATETIMEOFFSET()))) AS datetime_local,
		xevents.event_data.value('(event/data[@name="duration"]/value)[1]', 'bigint')/1000 AS duration_ms
    FROM sys.fn_xe_file_target_read_file
    (
        'AvgQueryDuration*.xel'
    ,   'AvgQueryDuration*.xem'
    ,   NULL
    ,   NULL) AS fxe
    CROSS APPLY (SELECT CAST(event_data as XML) AS event_data) AS xevents

)
SELECT 
	avg(duration_ms) AS AVGduration_ms
FROM events_cte AS E
	WHERE 
		 datetime_local > dateadd(mi,-1,getdate())

без where 8
c 5
		datediff(mi,
			CONVERT(datetime2,SWITCHOFFSET(CONVERT(datetimeoffset,xevents.event_data.value('(event/@timestamp)[1]', 'datetime2')),DATENAME(TzOffset, SYSDATETIMEOFFSET()))),
			getdate()) =1

			--WHERE 
		--CONVERT(datetime2,SWITCHOFFSET(CONVERT(datetimeoffset,xevents.event_data.value('(event/@timestamp)[1]', 'datetime2')),DATENAME(TzOffset, SYSDATETIMEOFFSET()))) > dateadd(mi,-1,getdate())
