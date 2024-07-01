DECLARE @intDBID INT;
SET @intDBID = (SELECT [dbid] 
                FROM master.dbo.sysdatabases 
                WHERE name = 'Octava');

-- Flush the procedure cache for one database only
DBCC FLUSHPROCINDB (22);


DECLARE @id INT = DB_ID()
DBCC FLUSHPROCINDB(@id)