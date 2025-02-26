USE [master]
GO

DECLARE
	@sql				NVARCHAR(MAX),
	@sql_create			NVARCHAR(MAX),
	@db_name			sysname

SET @sql_create = '
IF OBJECT_ID(''dbo.P2P_ErrorsLog'') IS NOT NULL
	DROP TABLE dbo.P2P_ErrorsLog

CREATE TABLE P2P_ErrorsLog (
	DateOfAdded DATETIME NOT NULL,
	Article NVARCHAR(100) NOT NULL,
	OperationType NVARCHAR(10) NOT NULL,
	ErrorProcString NVARCHAR(MAX) NOT NULL
)'
	
DECLARE curDB CURSOR LOCAL FAST_FORWARD FOR
	SELECT name
	FROM sys.databases
	WHERE is_published = 1
--      AND name = 'apartments'
OPEN curDB

FETCH NEXT FROM curDB INTO @db_name
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @sql = 'USE ' + QUOTENAME(@db_name) + @sql_create
	EXEC(@sql)

	FETCH NEXT FROM curDB INTO @db_name
END
GO