USE master
Go
CREATE PROCEDURE sp_KillDatabaseUsers @DBName varchar(100)
AS     
/*

Description: This stored procedure can be used to kill all the connected users in the SQL Server database. This SP code is compatible to SQL Server 2005 / 2008
Author:                 Ashish Kumar Mehta for www.SQL-Server-Performance.com

*/
SET NOCOUNT ON     
     
DECLARE @strSQL varchar(255)     
PRINT '————————–'     
PRINT 'Killing Database Users'     
PRINT '————————–'     
     
CREATE TABLE #DatabaseUsers   
(     
UserSession int,   
DatabaseID int,   
DatabaseName varchar(100)   
)     

INSERT INTO #DatabaseUsers    
SELECT DISTINCT (request_session_id) AS UserSession ,    
       resource_database_id AS DatabaseID,   
       db_name(resource_database_id) AS DatabaseName    
FROM master.sys.dm_tran_locks    
WHERE resource_type = 'DATABASE'    
AND resource_database_id = db_id(@DBName)   
     
DECLARE DBUserCursor CURSOR READ_ONLY     
FOR SELECT UserSession,DatabaseID FROM #DatabaseUsers WHERE DatabaseName = @DBName     
     
DECLARE @UserSession varchar(10)     
DECLARE @DatabaseID varchar(100)     
   
OPEN DBUserCursor     
     
FETCH NEXT FROM DBUserCursor INTO @UserSession, @DatabaseID     
WHILE (@@fetch_status <> -1)     
BEGIN     
 IF (@@fetch_status <> -2)     
 BEGIN     
 PRINT 'Killed SPID ' + @UserSession     
 SET @strSQL = 'KILL ' + @UserSession     
 EXEC (@strSQL)     
 END     
 FETCH NEXT FROM DBUserCursor INTO  @UserSession, @DatabaseID     
END     
     
CLOSE DBUserCursor     
DEALLOCATE DBUserCursor     
   
DROP table #DatabaseUsers  