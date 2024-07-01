declare @cmd1 varchar(500)
declare @cmd2 varchar(500)
declare @cmd3 varchar(500)

set @cmd1 ='IF (''?'' NOT IN (''distribution'',''master'', ''tempdb'', ''msdb'', ''model'', ''distribution'')) print ''*** Processing DB [?] ***'''

--set @cmd2 = 'IF (''?'' NOT IN (''distribution'',''master'', ''tempdb'', ''msdb'', ''model'', ''distribution'')) EXECUTE (''alter database [?] SET RECOVERY simple '')'
set @cmd2 = 'IF (''?'' NOT IN (''distribution'',''master'', ''tempdb'', ''msdb'', ''model'', ''distribution'')) EXECUTE ('' sp_removedbreplication ''''?'''' '')'
--set @cmd2 = 'IF (''?'' NOT IN (''distribution'',''master'', ''tempdb'', ''msdb'', ''model'', ''distri--bution'')) EXECUTE (''DBCC CHECKDB([?]) '')'

exec sp_MSForEachDb @command1=@cmd1,@command2=@cmd2

