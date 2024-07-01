
WITH History_Locks
AS (
	SELECT CAST(target_data AS xml) AS SessionXML
	FROM sys.dm_xe_session_targets st
	INNER JOIN sys.dm_xe_sessions s ON s.address = st.event_session_address
	WHERE name = 'History_Locks'
)
SELECT
	block.value('@timestamp', 'datetime') AS event_timestamp
	,block.value('@name', 'nvarchar(128)') AS event_name
	,block.value('(data/value)[1]', 'nvarchar(128)') AS event_count
	,block.value('(data/value)[1]', 'nvarchar(128)') AS increment
	,mv.map_value AS lock_type
	,block.value('(action/value)[1]', 'nvarchar(max)') AS sql_text
	,block.value('(action/value)[2]', 'nvarchar(255)') AS tsql_stack
FROM History_Locks b
CROSS APPLY SessionXML.nodes ('//RingBufferTarget/event') AS t(block)
INNER JOIN sys.dm_xe_map_values mv ON block.value('(data/value)[3]', 'nvarchar(128)') = mv.map_key AND name = 'lock_mode'
	WHERE block.value('@name', 'nvarchar(128)') = 'locks_lock_waits' -- Total number of milliseconds SQL Server waited on a row lock
UNION ALL
SELECT
	block.value('@timestamp', 'datetime') AS event_timestamp
	,block.value('@name', 'nvarchar(128)') AS event_name
	,block.value('(data/value)[1]', 'nvarchar(128)') AS event_count
	,NULL
	,mv.map_value AS lock_type
	,block.value('(action/value)[1]', 'nvarchar(max)') AS sql_text
	,block.value('(action/value)[2]', 'nvarchar(255)') AS tsql_stack
FROM History_Locks b
CROSS APPLY SessionXML.nodes ('//RingBufferTarget/event') AS t(block)
INNER JOIN sys.dm_xe_map_values mv ON block.value('(data/value)[2]', 'nvarchar(128)') = mv.map_key AND name = 'lock_mode'
	WHERE block.value('@name', 'nvarchar(128)') = 'lock_timeout'; -- Number of times SQL Server waited on a row lock 


-- быстрый вариант
DECLARE @TimeZone INT = DATEDIFF(HOUR, GETUTCDATE(), GETDATE())
--DECLARE @Dt_Ultimo_Evento DATETIME = ISNULL((SELECT MAX(Dt_Event) FROM dbo.History_SystemErrorsXE WITH(NOLOCK)), '1990-01-01')


IF (OBJECT_ID('tempdb..#Events') IS NOT NULL) DROP TABLE #Events

;WITH CTE AS (
    SELECT CONVERT(XML, event_data) AS event_data
    FROM sys.fn_xe_file_target_read_file(N'History_Locks*.xel', NULL, NULL, NULL)
)
SELECT
    DATEADD(HOUR, @TimeZone, CTE.event_data.value('(//event/@timestamp)[1]', 'datetime')) AS Dt_Event,
    CTE.event_data
INTO
    #Events
FROM
    CTE

	select * from #Events

SELECT
	dt_event
	--block.value('@timestamp', 'datetime') AS event_timestamp
	--,block.value('@session_id', 'int') AS session_id
	--,block.value('@database_name', 'varchar(100)') AS [database_name]
	--,block.value('@session_nt_username', 'varchar(100)') AS session_nt_username
	--,block.value('@client_hostname', 'varchar(100)') AS client_hostname
	--,block.value('@client_app_name', 'varchar(100)') AS client_app_name
	,block.value('@name', 'nvarchar(128)') AS event_name
	,block.value('(data/value)[1]', 'nvarchar(128)') AS event_count
	,block.value('(data/value)[1]', 'nvarchar(128)') AS increment
	--,mv.map_value AS lock_type
	,block.value('(action/value)[1]', 'nvarchar(max)') AS sql_text
	,block.value('(action/value)[2]', 'nvarchar(255)') AS tsql_stack
FROM #Events b
CROSS APPLY b.event_data.nodes('/event') AS t(block)
where block.value('(action/value)[2]', 'nvarchar(255)') is not null
order by dt_event desc

--INNER JOIN sys.dm_xe_map_values mv ON block.value('(data/value)[3]', 'nvarchar(128)') = mv.map_key AND name = 'lock_mode'
--	WHERE block.value('@name', 'nvarchar(128)') = 'locks_lock_waits' -- Total number of milliseconds SQL Server waited on a row lock