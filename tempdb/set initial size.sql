-- https://www.mssqltips.com/sqlservertip/4829/tempdb-size-resets-after-a-sql-server-service-restart/
USE master
go
-- configured size
SELECT 
name, file_id, type_desc, size * 8 / 1024 [TempdbSizeInMB]
FROM sys.master_files
WHERE DB_NAME(database_id) = 'tempdb'
ORDER BY type_desc DESC, file_id 
GO

-- current size
SELECT 
name, file_id, type_desc, size * 8 / 1024 [TempdbSizeInMB]
FROM tempdb.sys.database_files 
ORDER BY type_desc DESC, file_id
GO

SELECT name,physical_name FROM sys.master_files WHERE database_id = DB_ID('tempdb')

USE [master]
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdev2', MAXSIZE = UNLIMITED)
GO


--Manually set tempdb database size
USE [master]
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdev', SIZE = 2048MB , FILEGROWTH = 64MB )
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'templog', SIZE = 2048MB , FILEGROWTH = 64MB )
GO
--ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdb', SIZE = 1024MB , FILEGROWTH = 64MB )
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'temp2', SIZE = 500MB , FILEGROWTH = 64MB )
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'temp3', SIZE = 2048MB , FILEGROWTH = 64MB )
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'temp4', SIZE = 2048MB , FILEGROWTH = 64MB )
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'temp5', SIZE = 2048MB , FILEGROWTH = 64MB )
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'temp6', SIZE = 2048MB , FILEGROWTH = 64MB )
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'temp7', SIZE = 1024MB , FILEGROWTH = 64MB )
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'temp8', SIZE = 1024MB , FILEGROWTH = 64MB )
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdb9', SIZE = 1024MB , FILEGROWTH = 64MB )
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdb10', SIZE = 1024MB , FILEGROWTH = 64MB )
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdb11', SIZE = 1024MB , FILEGROWTH = 64MB )
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'templog1', SIZE = 1024MB , FILEGROWTH = 64MB )
GO


DBCC FREEPROCCACHE
GO
DBCC DROPCLEANBUFFERS
go
DBCC FREESYSTEMCACHE ('ALL')
GO
DBCC FREESESSIONCACHE
GO


use [master];
GO
USE [tempdb]
GO
DBCC SHRINKFILE (N'templog' , EMPTYFILE)
GO

USE [tempdb]
GO
ALTER DATABASE [tempdb]  REMOVE FILE [templog]
GO

USE [tempdb]
GO
DBCC SHRINKFILE (N'tempdb3' , 512)
GO
USE [tempdb]
GO
DBCC SHRINKFILE (N'tempdb' , 512)
GO

USE [tempdb]
GO
DBCC SHRINKFILE (N'tempdb10' , 512)
GO
USE [tempdb]
GO
DBCC SHRINKFILE (N'tempdb11' , 512)
GO
USE [tempdb]
GO
DBCC SHRINKFILE (N'tempdb2' , 512)
GO
USE [tempdb]
GO
DBCC SHRINKFILE (N'tempdb3' , 512)
GO
USE [tempdb]
GO
DBCC SHRINKFILE (N'tempdb4' , 512)
GO
USE [tempdb]
GO
DBCC SHRINKFILE (N'tempdb5' , 512)
GO
USE [tempdb]
GO
DBCC SHRINKFILE (N'tempdb6' , 512)
GO
USE [tempdb]
GO
DBCC SHRINKFILE (N'tempdb7' , 512)
GO

USE [tempdb]
GO
DBCC SHRINKFILE (N'tempdb8' , 512)
GO
USE [tempdb]
GO
DBCC SHRINKFILE (N'tempdb9' , 512)
GO

USE [tempdb]
GO
DBCC SHRINKFILE (N'tempdev' , 512)
GO


ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdb13', SIZE = 30000MB )
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdb14', SIZE = 30000MB )
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdb15', SIZE = 30000MB )
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdb16', SIZE = 30000MB )
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdb17', SIZE = 30000MB )
GO
ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdb18', SIZE = 30000MB )
GO






/*
Step 3 - Fill up tempdb
The code below will consume about 9GB of space in the tempdb database which causes the tempdb data files to auto-grow.
*/
CREATE TABLE #LargeTempTable (col1 char(3000) default 'a', col2 char(3000) default 'b')

SET NOCOUNT ON;
DECLARE @i INT = 1

BEGIN TRAN
 WHILE @i <= 950000
 BEGIN
  INSERT INTO #LargeTempTable DEFAULT VALUES
  SET @i += 1
 END

COMMIT TRAN

DROP TABLE #LargeTempTable