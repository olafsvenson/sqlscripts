--скрипт регистрации хранимой процедуры, используемой для АВТОМАТИЧЕСКОЙ РЕгенерации (при изменении схемы таблицы) update-процедур P2P-репликации
--запускать на каждом сервере, участвующем в P2P-репликации
SET NOCOUNT ON

USE [master]
GO

DECLARE
	@db_name	sysname,
	@sql		NVARCHAR(MAX)
	
DECLARE @publications TABLE
(
	db_name		sysname,
	publication	sysname
)

--получить все P2P-репликации всех БД
DECLARE curDB CURSOR LOCAL FAST_FORWARD FOR
	SELECT name
	FROM sys.databases
OPEN curDB

FETCH NEXT FROM curDB INTO @db_name
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @sql = N'USE ' + QUOTENAME(@db_name) + '
	IF object_id(''dbo.syspublications'') IS NOT NULL
	SELECT db_name(), name FROM dbo.syspublications WHERE options & 1 = 1'
	
	INSERT INTO @publications
	EXEC (@sql)
	
	FETCH NEXT FROM curDB INTO @db_name
END

--зарегистрировать пользовательские процедуры скриптования для всех P2P-репликаций
SET @sql = ''

SELECT @sql += 'USE ' + QUOTENAME(db_name) + '
EXEC sp_register_custom_scripting @type = ''update'', @value = ''dbo.spP2P_script_custom_update'', @publication = '''+publication+'''
EXEC sp_register_custom_scripting @type = ''insert'', @value = ''dbo.spP2P_script_custom_insert'', @publication = '''+publication+'''
EXEC sp_register_custom_scripting @type = ''delete'', @value = ''dbo.spP2P_script_custom_delete'', @publication = '''+publication+'''

'
FROM @publications

EXEC (@sql)
GO