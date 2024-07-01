--written by MDB and ALM for TheBakingDBA.Blogspot.Com
-- basic XE session creation written by Pinal Dave
-- http://blog.sqlauthority.com/2010/03/29/sql-server-introduction-to-extended-events-finding-long-running-queries/
-- mdb 2015/03/13 1.1 - added a query to the ring buffer's header to get # of events run, more comments
-- mdb 2015/03/13 1.2 - added model_end events, filtering on hostname, using TRACK_CAUSALITY, and multiple events
-- mdb 2015/03/18 1.3 - changed header parse to dynamic, courtesy of Mikael Eriksson on StackOverflow
-- This runs on at 2008++ (tested on 2008, 2008R2, 2012, and 2014). Because of that, no NOT LIKE exclusion
------------------------------
-- Create the Event Session --
------------------------------
 
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='FullTrace')
DROP EVENT SESSION FullTrace ON SERVER
GO
-- Create Event
CREATE EVENT SESSION FullTrace
ON SERVER
-- Add event to capture event
ADD EVENT sqlserver.rpc_completed
(
	-- Add action - event property ; can't add query_hash in R2
	--ACTION (sqlserver.sql_text, sqlserver.tsql_stack, sqlserver.client_app_name,sqlserver.username, sqlserver.client_hostname, sqlserver.session_nt_username,sqlserver.database_id,sqlserver.database_name)
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
	
	WHERE (  package0.greater_than_uint64(sqlserver.database_id, ( 4 )) -- исключая системные базы
			 AND  package0.equal_boolean(sqlserver.is_system, ( 0 ))
			 AND [package0].[not_equal_unicode_string]([sqlserver].[database_name],N'distribution') -- исключая базы по имени
			-- and [package0].[equal_unicode_string]([sqlserver].[database_name],N'Pegasus2008') --  включая базы 
			--AND duration > 5000000 -- 5 сек
		--	AND duration > 50000 -- 200 мс
			-- and [sqlserver].[username] = N'sa' )  -- CHANGE TO LOGIN YOU WANT TO MONITOR
	--AND sqlserver.client_hostname <> 'A' --cant use NOT LIKE prior to 2012
)
	--by leaving off the event name, you can easily change to capture diff events
),
ADD EVENT sqlserver.sql_statement_completed
-- or do sqlserver.rpc_completed, though getting the actual SP name seems overly difficult
(
	-- Add action - event property ; can't add query_hash in R2
	--ACTION (sqlserver.sql_text, sqlserver.tsql_stack, sqlserver.client_app_name, sqlserver.username, sqlserver.client_hostname, sqlserver.session_nt_username, sqlserver.database_id,sqlserver.database_name)
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
	WHERE (  package0.greater_than_uint64(sqlserver.database_id, ( 4 )) -- исключая системные базы
			 AND  package0.equal_boolean(sqlserver.is_system, ( 0 ))
			 AND [package0].[not_equal_unicode_string]([sqlserver].[database_name],N'distribution') -- исключая базы по имени
			-- and [package0].[equal_unicode_string]([sqlserver].[database_name],N'Pegasus2008') --  включая базы 
			--AND duration > 5000000 -- 5 сек
			--  AND duration > 50000 -- 200 мс
			 -- and [sqlserver].[username] = N'sa' )  -- CHANGE TO LOGIN YOU WANT TO MONITOR
	--AND sqlserver.client_hostname <> 'A'
)
),
--adding Module_End. Gives us the various SPs called.
ADD EVENT sqlserver.module_end
(
	--ACTION (sqlserver.sql_text, sqlserver.tsql_stack, sqlserver.client_app_name,	sqlserver.username, sqlserver.client_hostname, sqlserver.session_nt_username)
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
	WHERE (  package0.greater_than_uint64(sqlserver.database_id, ( 4 )) -- исключая системные базы
			 AND  package0.equal_boolean(sqlserver.is_system, ( 0 ))
			 AND [package0].[not_equal_unicode_string]([sqlserver].[database_name],N'distribution') -- исключая базы по имени
			-- and [package0].[equal_unicode_string]([sqlserver].[database_name],N'Pegasus2008') --  включая базы 
			--AND duration > 5000000 -- 5 сек
			--AND duration > 50000 -- 200 мс
		-- and [sqlserver].[username] = N'sa' )  -- CHANGE TO LOGIN YOU WANT TO MONITOR
)
)
-- Add target for capturing the data - XML File
-- You don't need this (pull the ring buffer into temp table),
-- but allows us to capture more events (without allocating more memory to the buffer)
--!!! Remember the files will be left there when done!!!

-- Записываем в файле. 
-- !!! После остановки сессии файлы остаются !!!
ADD TARGET package0.asynchronous_file_target(
												SET filename='D:\Traces\FullTrace.xel', metadatafile='d:\Traces\FullTrace.xem',
												max_file_size=(200), -- 200Mb
												max_rollover_files = 60 -- 5 файлов
											) ,
-- Записываем в кольцевой буфер
-- Он обнуляется при достижении max_memory, либо при приевышении max_events_limit = 1000 (default)	
ADD TARGET package0.ring_buffer
(	SET max_memory = 131072, /*=128MB*/ /* 1048576 = 1GB*/
	max_events_limit = 5000
)
	WITH (max_dispatch_latency = 1 SECONDS, TRACK_CAUSALITY = ON)
GO
 
 
 
---- Enable Event, aka Turn It On
--ALTER EVENT SESSION FullTrace ON SERVER
--STATE=START
--GO
 