USE master
GO
SET QUOTED_IDENTIFIER ON
go
IF (OBJECT_ID('dbo.History_TimeoutsXE') IS NULL)
BEGIN
 
    -- DROP TABLE dbo.History_TimeoutsXE
    CREATE TABLE dbo.History_TimeoutsXE (
        [Dt_Event]            DATETIME,
        [session_id]           INT,
        [duration]             BIGINT,
        [server_instance_name] VARCHAR(100),
        [database_name]        VARCHAR(100),
        [session_nt_username]  VARCHAR(100),
        [nt_username]          VARCHAR(100),
        [client_hostname]      VARCHAR(100),
        [client_app_name]      VARCHAR(100),
       -- [num_response_rows]    INT,
        [sql_text]             XML
    ) 
	    CREATE CLUSTERED INDEX CI_History_TimeoutsXE_Dt_Event ON dbo.History_TimeoutsXE(Dt_Event) WITH(DATA_COMPRESSION=PAGE)

 
END
 
 
DECLARE @TimeZone INT = DATEDIFF(HOUR, GETUTCDATE(), GETDATE())
DECLARE @Dt_Ultimo_Evento DATETIME = ISNULL((SELECT MAX(Dt_Event) FROM dbo.History_TimeoutsXE WITH(NOLOCK)), '1990-01-01')
 
 
IF (OBJECT_ID('tempdb..#Events') IS NOT NULL) DROP TABLE #Events 
;WITH CTE AS (
    SELECT CONVERT(XML, event_data) AS event_data
    FROM sys.fn_xe_file_target_read_file(N'Monitor_Timeout*.xel', NULL, NULL, NULL)
)
SELECT
    DATEADD(HOUR, @TimeZone, CTE.event_data.value('(//event/@timestamp)[1]', 'datetime')) AS Dt_Event,
    CTE.event_data
INTO
    #Events
FROM
    CTE
WHERE
    DATEADD(HOUR, @TimeZone, CTE.event_data.value('(//event/@timestamp)[1]', 'datetime')) > @Dt_Ultimo_Evento
    
 
INSERT INTO dbo.History_TimeoutsXE
SELECT
    A.Dt_Event,
    xed.event_data.value('(action[@name="session_id"]/value)[1]', 'int') AS [session_id],
    xed.event_data.value('(data[@name="duration"]/value)[1]', 'bigint') AS [duration],
    xed.event_data.value('(action[@name="server_instance_name"]/value)[1]', 'varchar(100)') AS [server_instance_name],
    xed.event_data.value('(action[@name="database_name"]/value)[1]', 'varchar(100)') AS [database_name],
    xed.event_data.value('(action[@name="session_nt_username"]/value)[1]', 'varchar(100)') AS [session_nt_username],
    xed.event_data.value('(action[@name="nt_username"]/value)[1]', 'varchar(100)') AS [nt_username],
    xed.event_data.value('(action[@name="client_hostname"]/value)[1]', 'varchar(100)') AS [client_hostname],
    xed.event_data.value('(action[@name="client_app_name"]/value)[1]', 'varchar(100)') AS [client_app_name],
  --  xed.event_data.value('(action[@name="num_response_rows"]/value)[1]', 'int') AS [num_response_rows],
    TRY_CAST(xed.event_data.value('(action[@name="sql_text"]/value)[1]', 'varchar(max)') AS XML) AS [sql_text]
FROM
    #Events A
    CROSS APPLY A.event_data.nodes('//event') AS xed (event_data)