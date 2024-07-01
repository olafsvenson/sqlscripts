Use master
GO

--CONFIG
DECLARE @UserName VARCHAR(50) = 'SFN\sec_SQL_role_analytics_DC-AS-UAT'
DECLARE @PrintOnly bit = 0
DECLARE @Add_DataReader bit = 1
DECLARE @Add_DataWriter bit = 1
DECLARE @Add_DDLAdmin bit = 1
DECLARE @Add_CustomPerm bit = 0

-------------------------------------------
DECLARE @dbname VARCHAR(50)
DECLARE @statement NVARCHAR(max)
DECLARE @ParmDefinition NVARCHAR(500);
DECLARE @UserExists bit

DECLARE db_cursor CURSOR
LOCAL FAST_FORWARD
FOR
	SELECT name
	FROM MASTER.dbo.sysdatabases
	WHERE name NOT IN ('master','model','msdb','tempdb','distribution')

	OPEN db_cursor
	FETCH NEXT FROM db_cursor INTO @dbname
	WHILE @@FETCH_STATUS = 0
	BEGIN

		--Check if user already exists in the database
		SET @statement = N'USE ' + QUOTENAME(@dbname) + N';
		IF EXISTS (SELECT [name]
		FROM [sys].[database_principals]
		WHERE [name] = ''' + @UserName + ''')
		set @UserExistsOUT = 1
		else
		set @UserExistsOUT = 0'
		SET @ParmDefinition = N'@UserExistsOUT bit OUTPUT';

		EXEC sp_executesql @statement, @ParmDefinition, @UserExistsOUT = @UserExists OUTPUT

		----Start Creating Script
		SET @statement = 'use '+ QUOTENAME(@dbname) +';'

		--If user doesn't exist then add CREATE statement
		IF @UserExists = 0
			SET @statement = @statement + char(10) + 'CREATE USER ['+ @UserName +'] FOR LOGIN ['+ @UserName +'];'
		
		IF @Add_DataReader = 1
			SET @statement = @statement + char(10) + 'EXEC sp_addrolemember N''db_datareader'', ['+ @UserName +'];'

		IF @Add_DataWriter = 1
			SET @statement = @statement + char(10) + 'EXEC sp_addrolemember N''db_datawriter'', ['+ @UserName +'];'

		IF @Add_DDLAdmin  = 1
			SET @statement = @statement + char(10) + 'EXEC sp_addrolemember N''db_ddladmin'', ['+ @UserName +'];'

		IF @Add_CustomPerm   = 1
		begin
			SET @statement = @statement + char(10) + 'GRANT ALTER ANY APPLICATION ROLE TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT ALTER ANY ASSEMBLY TO  ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT ALTER ANY DATABASE DDL TRIGGER TO  ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT ALTER ANY DATASPACE TO  ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT ALTER ANY MESSAGE TYPE TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT ALTER ANY SCHEMA TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT CREATE AGGREGATE TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT CREATE ASSEMBLY TO  ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT CREATE DATABASE DDL EVENT NOTIFICATION TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT CREATE DEFAULT TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT CREATE FULLTEXT CATALOG TO  ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT CREATE FUNCTION TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT CREATE PROCEDURE TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT CREATE ROLE TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT CREATE RULE TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT CREATE SCHEMA TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT CREATE SERVICE TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT CREATE SYNONYM TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT CREATE TYPE TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT CREATE VIEW TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT CREATE XML SCHEMA COLLECTION TO  ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT REFERENCES TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT SHOWPLAN TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT VIEW DATABASE STATE TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT VIEW DEFINITION TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT SELECT TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT UPDATE TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT INSERT TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT DELETE TO ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'GRANT EXECUTE TO ['+ @UserName +'];'

			SET @statement = @statement + char(10) + 'grant showplan to ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'grant view database state to ['+ @UserName +'];'
			SET @statement = @statement + char(10) + 'grant view definition to ['+ @UserName +'];'
		end


		IF @PrintOnly = 1
			PRINT @statement
		ELSE
			exec sp_executesql @statement

	FETCH NEXT FROM db_cursor INTO @dbname
	END
	CLOSE db_cursor
DEALLOCATE db_cursor



set @statement = 'GRANT VIEW ANY DEFINITION TO ['+@UserName+']'
exec sp_executesql @statement

set @statement = 'GRANT SHOWPLAN TO ['+@UserName+']'
exec sp_executesql @statement

set @statement='USE [msdb];CREATE USER['+@UserName+'] FOR LOGIN [' +@UserName+'];ALTER ROLE [SQLAgentOperatorRole] ADD MEMBER ['+@UserName+']'
exec sp_executesql @statement


