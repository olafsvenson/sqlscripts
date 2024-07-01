USE master
SET NOCOUNT ON

DECLARE @rootkey varchar(255), @File_Exists int, @value varchar(255), @key varchar(255), @value_name varchar(255)

-- определяем директорию где хранятся дампы
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE'
                                   ,@key ='SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.MSSQLSERVER\CPE'
                                   ,@value_name = 'ErrorDumpDir'
                                   ,@value = @value OUTPUT
-- Проверяем на наличие этого файла
SELECT @value = @value + 'SQLDUMPER_ERRORLOG.log'

EXEC master.dbo.xp_fileexist @value, @File_Exists OUT

IF @File_Exists = 1 
begin
EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Houston mail'
                                   ,@recipients = 'zheltonogov.vs@pecom.ru'
                                   ,@subject = 'Обнаружен новый DUMP'
                                   ,@body = 'Обнаружен новый DUMP'

-- удаляем файл после отправки письма
DECLARE @cmd NVARCHAR(MAX) = 'exec xp_cmdshell ''del "'+ @value+'"'''
--PRINT @cmd
exec(@cmd)
end