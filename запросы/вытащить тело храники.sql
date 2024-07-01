1.	
SELECT definition
FROM sys.sql_modules
WHERE object_id = (OBJECT_ID(N'svadba_catalog.dbo.AW_AWClient_Register'));

2.	
SELECT OBJECT_DEFINITION (OBJECT_ID(N'svadba_catalog.dbo.AW_AWClient_Register'));

3.	
EXEC sp_helptext N'svadba_catalog.dbo.AW_AWClient_Register';
