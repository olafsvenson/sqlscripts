EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

EXEC sp_configure 'xp_cmdshell',1
GO
RECONFIGURE
GO


-- EXEC sys.xp_cmdshell 'mkdir c:\testdir\'
