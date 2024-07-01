
DECLARE @SQL NVARCHAR(MAX)=
(
 select 'EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N''' + name+ ''';'+char(10)+char(13)
 from sys.databases
 where 
 database_id > 4
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'
);
PRINT @SQL
EXEC sp_executesql @SQL;


