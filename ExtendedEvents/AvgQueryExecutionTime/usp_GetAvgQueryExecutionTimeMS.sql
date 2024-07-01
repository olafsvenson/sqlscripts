
USE master
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('usp_GetAvgQueryExecutionTimeMs', 'P') IS NOT NULL  
    DROP PROCEDURE usp_GetAvgQueryExecutionTimeMs;  
go

CREATE PROCEDURE usp_GetAvgQueryExecutionTimeMs
AS
set nocount on;

/*
	DECLARE @SessionName sysname
		
	-- берем уже существующий XE от Softpoint (нужно более элегантное решение)
	SELECT  @SessionName= s.name
	FROM sys.dm_xe_session_targets t
		INNER JOIN sys.dm_xe_sessions s ON s.address = t.event_session_address
	WHERE s.name like 'SPA%' OR s.name LIKE 'SP10%'


	DECLARE @Target_File NVarChar(1000)
		, @Target_Dir NVarChar(1000)
		, @Target_File_WildCard NVarChar(1000)

	SELECT @Target_File = CAST(t.target_data as XML).value('EventFileTarget[1]/File[1]/@name', 'NVARCHAR(256)')
	FROM sys.dm_xe_session_targets t
		INNER JOIN sys.dm_xe_sessions s ON s.address = t.event_session_address
	WHERE s.name like @SessionName
		AND t.target_name = 'event_file'

	SELECT @Target_Dir = LEFT(@Target_File, Len(@Target_File) - CHARINDEX('\', REVERSE(@Target_File))) 

	SELECT @Target_File_WildCard = @Target_Dir + '\'  + @SessionName + '_*.xel'
	--PRINT @Target_File_WildCard

	 SELECT 
			avg(xevents.event_data.value('(event/data[@name="duration"]/value)[1]', 'bigint')/1000) AS duration_ms
		FROM sys.fn_xe_file_target_read_file
		(
			@Target_File_WildCard
		,   NULL
		,   NULL
		,   NULL) AS fxe
		CROSS APPLY (SELECT CAST(event_data as XML) AS event_data) AS xevents
		*/
		
;WITH events_cte AS
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
GO
GRANT EXECUTE ON usp_GetAvgQueryExecutionTimeMs TO zabbix

