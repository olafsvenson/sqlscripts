EXEC sp_configure 'show advanced options',1
GO
RECONFIGURE
GO
 
EXEC sp_configure 'Agent XPs',1
GO
RECONFIGURE
GO
 
EXEC sp_configure 'show advanced options',0
GO
RECONFIGURE
GO