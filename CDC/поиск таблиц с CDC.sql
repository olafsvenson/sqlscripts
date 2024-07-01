SELECT Name As DataBaseName, is_cdc_enabled FROM sys.databases Where is_cdc_enabled = 1
SELECT Name AS TableName, is_tracked_by_cdc FROM sys.tables Where is_tracked_by_cdc = 1