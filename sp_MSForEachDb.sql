declare @cmd1 varchar(500)
declare @cmd2 varchar(500)
declare @cmd3 varchar(500)

set @cmd1 ='IF (''?'' NOT IN (''master'', ''msdb'', ''model'' )) print ''*** Processing DB [?] ***'''

--set @cmd2 = 'IF (''?'' NOT IN (''distribution'',''master'', ''tempdb'', ''msdb'', ''model'', ''distribution'')) EXECUTE (''alter database [?] SET RECOVERY full '')'
set @cmd2 = 'IF (''?'' NOT IN (''master'', ''msdb'', ''model'',''tempdb'')) EXECUTE (''DBCC SHRINKDATABASE ([?], 0, TRUNCATEONLY) '')'
--set @cmd2 = 'IF (''?'' NOT IN (''distribution'',''master'', ''tempdb'', ''msdb'', ''model'', ''distri--bution'')) EXECUTE (''DBCC CHECKDB([?]) '')'

exec sp_MSForEachDb @command1=@cmd1,@command2=@cmd2


