SELECT @@servername
SELECT @@servicename

SELECT @@SERVERNAME                 AS oldname,
       Serverproperty('Servername') AS actual_name


EXEC sp_dropserver 'TESTING'
GO

EXEC sp_addserver 'CO-SQL-01', 'local'

GO