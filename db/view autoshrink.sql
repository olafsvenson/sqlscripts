SELECT [name] AS DatabaseName,
 CONVERT(varchar(10),DATABASEPROPERTYEX([Name] , 'IsAutoShrink')) AS AutoShrink,
 'ALTER DATABASE ['+[name]+'] SET AUTO_SHRINK OFF'
FROM master.dbo.sysdatabases
WHERE name like'Pegasus2008%'
AND DATABASEPROPERTYEX([Name] , 'IsAutoShrink') = 1
Order By DatabaseName