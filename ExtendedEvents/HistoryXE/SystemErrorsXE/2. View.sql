USE master
go
IF (OBJECT_ID('dbo.History_SystemErrorsXE') IS NULL)
BEGIN

    -- DROP TABLE dbo.History_SystemErrorsXE
    CREATE TABLE dbo.History_SystemErrorsXE (
        Dt_Event DATETIME,
        session_id INT,
        [database_name] VARCHAR(100),
        session_nt_username VARCHAR(100),
        client_hostname VARCHAR(100),
        client_app_name VARCHAR(100),
        [error_number] INT,
        severity INT,
        [state] INT,
        sql_text XML,
        [message] VARCHAR(MAX)
    )

    CREATE CLUSTERED INDEX CI_History_SystemErrorsXE_Dt_Event ON dbo.History_SystemErrorsXE(Dt_Event) WITH(DATA_COMPRESSION=PAGE)

END


DECLARE @TimeZone INT = DATEDIFF(HOUR, GETUTCDATE(), GETDATE())
DECLARE @Dt_Ultimo_Evento DATETIME = ISNULL((SELECT MAX(Dt_Event) FROM dbo.History_SystemErrorsXE WITH(NOLOCK)), '1990-01-01')


IF (OBJECT_ID('tempdb..#Events') IS NOT NULL) DROP TABLE #Events

;WITH CTE AS (
    SELECT CONVERT(XML, event_data) AS event_data
    FROM sys.fn_xe_file_target_read_file(N'History_SystemErrors*.xel', NULL, NULL, NULL)
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


SET QUOTED_IDENTIFIER ON

INSERT INTO dbo.History_SystemErrorsXE
SELECT
    A.Dt_Event,
    xed.event_data.value('(action[@name="session_id"]/value)[1]', 'int') AS [session_id],
    xed.event_data.value('(action[@name="database_name"]/value)[1]', 'varchar(100)') AS [database_name],
    xed.event_data.value('(action[@name="session_nt_username"]/value)[1]', 'varchar(100)') AS [session_nt_username],
    xed.event_data.value('(action[@name="client_hostname"]/value)[1]', 'varchar(100)') AS [client_hostname],
    xed.event_data.value('(action[@name="client_app_name"]/value)[1]', 'varchar(100)') AS [client_app_name],
    xed.event_data.value('(data[@name="error_number"]/value)[1]', 'int') AS [error_number],
    xed.event_data.value('(data[@name="severity"]/value)[1]', 'int') AS [severity],
    xed.event_data.value('(data[@name="state"]/value)[1]', 'int') AS [state],
    TRY_CAST(xed.event_data.value('(action[@name="sql_text"]/value)[1]', 'varchar(max)') AS XML) AS [sql_text],
    xed.event_data.value('(data[@name="message"]/value)[1]', 'varchar(max)') AS [message]
FROM
    #Events A
    CROSS APPLY A.event_data.nodes('//event') AS xed (event_data)