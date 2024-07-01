DECLARE @DBName VARCHAR(64) = 'databasename'

DECLARE @ErrorLog AS TABLE([LogDate] CHAR(24), [ProcessInfo] VARCHAR(64), [Text] VARCHAR(MAX))

INSERT INTO @ErrorLog
exec sys.xp_readerrorlog 0, 1, 'Recovery of database', @DBName

SELECT TOP 5
[LogDate]
,SUBSTRING([Text], CHARINDEX(') is ', [Text]) + 4,CHARINDEX(' complete (', [Text]) - CHARINDEX(') is ', [Text]) - 4) AS PercentComplete
,CAST(SUBSTRING([Text], CHARINDEX('approximately', [Text]) + 13,CHARINDEX(' seconds remain', [Text]) - CHARINDEX('approximately', [Text]) - 13) AS FLOAT)/60.0 AS MinutesRemaining
,CAST(SUBSTRING([Text], CHARINDEX('approximately', [Text]) + 13,CHARINDEX(' seconds remain', [Text]) - CHARINDEX('approximately', [Text]) - 13) AS FLOAT)/60.0/60.0 AS HoursRemaining
,[Text]

FROM @ErrorLog ORDER BY [LogDate] DESC

/* 2016

DECLARE @DBName VARCHAR(64) = 'databasename'

DECLARE @ErrorLog AS TABLE([LogDate] CHAR(24), [ProcessInfo] VARCHAR(64), [Text] VARCHAR(MAX))

INSERT INTO @ErrorLog
exec sys.xp_readerrorlog

SELECT TOP 5
	[LogDate]
	,SUBSTRING([Text], CHARINDEX(') is ', [Text]) + 4,CHARINDEX(' complete (', [Text]) - CHARINDEX(') is ', [Text]) - 4) AS PercentComplete
	,CAST(SUBSTRING([Text], CHARINDEX('approximately', [Text]) + 13,CHARINDEX(' seconds remain', [Text]) - CHARINDEX('approximately', [Text]) - 13) AS FLOAT)/60.0 AS MinutesRemaining
	,CAST(SUBSTRING([Text], CHARINDEX('approximately', [Text]) + 13,CHARINDEX(' seconds remain', [Text]) - CHARINDEX('approximately', [Text]) - 13) AS FLOAT)/3600.0 AS HoursRemaining
	,[Text]

FROM @ErrorLog 
where CHARINDEX(@DBName, [Text]) > 0 and CHARINDEX('approximately', [Text]) > 0
ORDER BY [LogDate] DESC 

*/