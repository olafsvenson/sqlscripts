-- https://en.dirceuresende.com/blog/sql-server-how-to-generate-deadlock-history-monitoring-for-routine-failure-analysis/
USE [master]
GO
SET QUOTED_IDENTIFIER ON
go
 
IF (OBJECT_ID('dbo.History_SystemDeadlocksXE') IS NULL)
BEGIN
	-- drop table dbo.History_SystemDeadlocksXE
    CREATE TABLE dbo.History_SystemDeadlocksXE (
        Dt_Log DATETIME,
        Ds_Log XML
    )
    CREATE CLUSTERED INDEX CI_SystemDeadlocksXE_Dt_Log ON dbo.History_SystemDeadlocksXE(Dt_Log) WITH(DATA_COMPRESSION=PAGE)
END
 
 
DECLARE @Ultimo_Log DATETIME = ISNULL((SELECT MAX(Dt_Log) FROM dbo.History_SystemDeadlocksXE WITH(NOLOCK)), '1900-01-01')
 
INSERT INTO dbo.History_SystemDeadlocksXE
SELECT
    xed.value('@timestamp', 'datetime2(3)') as CreationDate,
    xed.query('.') AS XEvent
FROM
(
    SELECT 
        CAST([target_data] AS XML) AS TargetData
    FROM 
        sys.dm_xe_session_targets AS st
        INNER JOIN sys.dm_xe_sessions AS s ON s.[address] = st.event_session_address
    WHERE 
        s.[name] = N'system_health'
        AND st.target_name = N'ring_buffer'
) AS [Data]
CROSS APPLY TargetData.nodes('RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData (xed)
WHERE
    xed.value('@timestamp', 'datetime2(3)') > @Ultimo_Log
ORDER BY 
    CreationDate DESC