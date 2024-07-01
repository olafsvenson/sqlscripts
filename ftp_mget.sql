-- https://www.codeproject.com/Articles/1170393/Download-file-s-from-FTP-Server-using-Command-thro
-- FTP_MGET.sql (Author Saddamhusen Uadanwala)  
-- Transfer all files from an FTP server to local Direcoty using MGET command.  
   
DECLARE @FTPServer varchar(128)  
DECLARE @FTPUserName varchar(128)  
DECLARE @FTPPassword varchar(128)  
DECLARE @SourcePath varchar(128)  
DECLARE @SourceFiles varchar(128)  
DECLARE @DestinationPath varchar(128)  
DECLARE @FTPMode varchar(10)  
   
-- Attributes  
SET @FTPServer = 'ftpserver'  
SET @FTPUserName = 'sfnam'  
SET @FTPPassword = 'ds738TSG3hSY7h38jds3d2GHSK3ds'  
SET @SourcePath = '' -- Folder path/Blank for root directory.  
SET @SourceFiles = 'GL_NZSD_SBR.bak'  
SET @DestinationPath = 'D:\mssql\backup' -- Destination path.  
SET @FTPMode = 'binary' -- binary, ascii or blank for default mode.  
   
DECLARE @Command varchar(1000)  
DECLARE @workfile varchar(128)  
DECLARE @nowstr varchar(25)  
   
-- %TEMP% environment variable.  
DECLARE @tempdir varchar(128)  
CREATE TABLE #tempvartable(info VARCHAR(1000))  
INSERT #tempvartable EXEC master..xp_cmdshell 'echo %temp%'  
SET @tempdir = (SELECT top 1 info FROM #tempvartable)  
IF RIGHT(@tempdir, 1) <> '\' SET @tempdir = @tempdir + '\'  
DROP TABLE #tempvartable  
   
-- Generate @workfile  
SET @nowstr = replace(replace(convert(varchar(30), GETDATE(), 121), ' ', '_'), ':', '-')  
SET @workfile = 'FTP_SPID' + convert(varchar(128), @@spid) + '_' + @nowstr + '.txt'  
   
-- special chars for echo commands.  
select @FTPServer = replace(replace(replace(@FTPServer, '|', '^|'),'<','^<'),'>','^>')  
select @FTPUserName = replace(replace(replace(@FTPUserName, '|', '^|'),'<','^<'),'>','^>')  
select @FTPPassword = replace(replace(replace(@FTPPassword, '|', '^|'),'<','^<'),'>','^>')  
select @SourcePath = replace(replace(replace(@SourcePath, '|', '^|'),'<','^<'),'>','^>')  
IF RIGHT(@DestinationPath, 1) = '\' SET @DestinationPath = LEFT(@DestinationPath, LEN(@DestinationPath)-1)  
   
-- Build the FTP script file.  
select @Command = 'echo ' + 'open ' + @FTPServer + ' > ' + @tempdir + @workfile  
EXEC master..xp_cmdshell @Command  
select @Command = 'echo ' + @FTPUserName + '>> ' + @tempdir + @workfile  
EXEC master..xp_cmdshell @Command  
select @Command = 'echo ' + @FTPPassword + '>> ' + @tempdir + @workfile  
EXEC master..xp_cmdshell @Command  
select @Command = 'echo ' + 'prompt ' + ' >> ' + @tempdir + @workfile  
EXEC master..xp_cmdshell @Command  
IF LEN(@FTPMode) > 0  
BEGIN  
    select @Command = 'echo ' + @FTPMode + ' >> ' + @tempdir + @workfile  
    EXEC master..xp_cmdshell @Command  
END  
select @Command = 'echo ' + 'lcd ' + @DestinationPath + ' >> ' + @tempdir + @workfile  
EXEC master..xp_cmdshell @Command  
IF LEN(@SourcePath) > 0  
BEGIN  
    select @Command = 'echo ' + 'cd ' + @SourcePath + ' >> ' + @tempdir + @workfile  
    EXEC master..xp_cmdshell @Command  
END  
select @Command = 'echo ' + 'mget ' + @SourcePath + @SourceFiles + ' >> ' + @tempdir + @workfile  
EXEC master..xp_cmdshell @Command  
select @Command = 'echo ' + 'quit' + ' >> ' + @tempdir + @workfile  
EXEC master..xp_cmdshell @Command  
   
-- Execute the FTP command via above generated script file.  
select @Command = 'ftp -s:' + @tempdir + @workfile  
create table #a (id int identity(1,1), s varchar(1000))  
print @Command  
insert #a  
EXEC master..xp_cmdshell @Command  
select id, ouputtmp = s from #a  
   
-- drop table.  
drop table #a  
select @Command = 'del ' + @tempdir + @workfile  
print @Command  
EXEC master..xp_cmdshell @Command