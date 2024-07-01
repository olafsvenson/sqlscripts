USE master;
GO
IF OBJECT_ID('dbo.fn_hadr_database_is_primary','FN') IS NOT NULL
DROP FUNCTION dbo.fn_hadr_database_is_primary
GO
CREATE FUNCTION dbo.fn_hadr_database_is_primary (@DBName sysname)
RETURNS bit
AS
BEGIN
DECLARE @description sysname;
SELECT
@description = hars.role_desc
FROM
sys.DATABASES d
INNER JOIN sys.dm_hadr_availability_replica_states hars ON d.replica_id = hars.replica_id
WHERE
database_id = DB_ID(@DBName);
IF @description = 'PRIMARY'
RETURN 1;
RETURN 0;
END;
GO