------------------------------
-- Create the Event Session --
------------------------------
 
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='LongRunningQuery')
DROP EVENT SESSION LongRunningQuery ON SERVER
GO
-- Create Event
CREATE EVENT SESSION LongRunningQuery
ON SERVER
ADD EVENT sqlserver.rpc_completed
(
	
	ACTION
(
	package0.collect_system_time
	,sqlserver.client_app_name
	,sqlserver.client_hostname
	,sqlserver.database_name
	,sqlserver.plan_handle
	,sqlserver.query_hash
	,sqlserver.session_id
	,sqlserver.username
)
	
	WHERE (  
			--package0.greater_than_uint64(sqlserver.database_id, ( 4 )) -- исключая системные базы
			  package0.equal_boolean(sqlserver.is_system, ( 0 ))
			 AND [package0].[not_equal_unicode_string]([sqlserver].[database_name],N'distribution') -- исключая базы по имени
		--	 and [package0].[equal_unicode_string]([sqlserver].[database_name],N'Pegasus2008bb') --  включая базы 
			--AND duration > 5000000 -- 5 сек
			--AND duration > 500000 -- 500 мс
			--AND duration > 200000 -- 200 мс
			AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%1C_DWH_NAV%')
			--AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%pexpAutoPrintedFilesWithoutFilesToLK%')

		--	 and [sqlserver].[username] = N'winter'   -- CHANGE TO LOGIN YOU WANT TO MONITOR
			--AND sqlserver.client_hostname <> 'A' --cant use NOT LIKE prior to 2012
)
),
ADD EVENT sqlserver.sql_statement_completed
(
	-- Add action - event property ; can't add query_hash in R2
ACTION
(
	package0.collect_system_time
	,sqlserver.client_app_name
	,sqlserver.client_hostname
	,sqlserver.database_name
	,sqlserver.plan_handle
	,sqlserver.query_hash
	,sqlserver.session_id
	,sqlserver.username
)
	WHERE (  
			--package0.greater_than_uint64(sqlserver.database_id, ( 4 )) -- исключая системные базы
			  package0.equal_boolean(sqlserver.is_system, ( 0 ))
			 AND [package0].[not_equal_unicode_string]([sqlserver].[database_name],N'distribution') -- исключая базы по имени
			-- and [package0].[equal_unicode_string]([sqlserver].[database_name],N'Pegasus2008bb') --  включая базы 
			-- AND duration > 5000000 -- 5 сек
			-- AND duration > 500000 -- 500 мс
			 --AND duration > 200000 -- 200 мс
			AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%1C_DWH_NAV%')
			--AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%pexpAutoPrintedFilesWithoutFilesToLK%')
			-- and [sqlserver].[username] = N'winter'   -- CHANGE TO LOGIN YOU WANT TO MONITOR
			-- AND sqlserver.client_hostname <> 'A'
)
),
--adding Module_End. Gives us the various SPs called.
ADD EVENT sqlserver.module_end
(
	ACTION
(
	package0.collect_system_time
	,sqlserver.client_app_name
	,sqlserver.client_hostname
	,sqlserver.database_name
	,sqlserver.plan_handle
	,sqlserver.query_hash
	,sqlserver.session_id
	,sqlserver.username
)
	WHERE (  
			-- package0.greater_than_uint64(sqlserver.database_id, ( 4 )) -- исключая системные базы
			  package0.equal_boolean(sqlserver.is_system, ( 0 ))
			 AND [package0].[not_equal_unicode_string]([sqlserver].[database_name],N'distribution') -- исключая базы по имени
			-- and [package0].[equal_unicode_string]([sqlserver].[database_name],N'Pegasus2008bb') --  включая базы 
			--AND duration > 5000000 -- 5 сек
			--AND duration > 500000 -- 500 мс
			--AND duration > 200000 -- 200 мс 20000000
			AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%1C_DWH_NAV%')
			--AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'%pexpAutoPrintedFilesWithoutFilesToLK%')
		-- and [sqlserver].[username] = N'winter'   -- CHANGE TO LOGIN YOU WANT TO MONITOR
)
)
-- Add target for capturing the data - XML File
-- You don't need this (pull the ring buffer into temp table),
-- but allows us to capture more events (without allocating more memory to the buffer)
--!!! Remember the files will be left there when done!!!

-- Записываем в файл. 
-- !!! После остановки сессии файлы остаются !!!
ADD TARGET package0.asynchronous_file_target(
												SET filename='D:\MSSQL\Backup\LongRunningQuery.xel', metadatafile='D:\MSSQL\Backup\LongRunningQuery.xem',
												max_file_size=(200), -- 200Mb
												max_rollover_files = 50 -- 5 файлов
											) ,
-- Также записываем в кольцевой буфер
-- Он обнуляется при достижении max_memory, либо при приевышении max_events_limit = 1000 (default)	
ADD TARGET package0.ring_buffer
(	SET max_memory = 131072, /*=128MB*/ /* 1048576 = 1GB*/
	max_events_limit = 5000
)
	WITH (max_dispatch_latency = 30 SECONDS, TRACK_CAUSALITY = ON)
	--WITH (MAX_MEMORY=4096 KB, EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS, MAX_DISPATCH_LATENCY=30 SECONDS, MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE, TRACK_CAUSALITY=ON, STARTUP_STATE=ON)
GO
 
 
 
-- Enable Event, aka Turn It On
ALTER EVENT SESSION LongRunningQuery ON SERVER
STATE=START
GO
 