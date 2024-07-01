SET QUOTED_IDENTIFIER ON
GO

DECLARE @SQL NVARCHAR(MAX)=
(
 select  
	'ALTER DATABASE '+QUOTENAME(d.name)+' MODIFY FILE ( NAME = N''' + mf.name + ''', FILEGROWTH = '+
	case
		when mf.type_desc = 'ROWS' then '256Mb'
		when mf.type_desc = 'LOG' then '128Mb, MAXSIZE = UNLIMITED'
		else '64MB'
	end +');' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) 
 FROM 
    sys.master_files mf 
  JOIN sys.databases d 
   ON mf.database_id = d.database_id 
 WHERE d.database_id > 4 
   AND d.state = 0 -- ONLINE
   and d.is_read_only = 0
   and (
		mf.is_percent_growth = 1 
		or mf.growth * 8.0 / 1024 <= 64 -- autogrowth < 10mb
		)
   and mf.type_desc = 'LOG' -- ROWS , LOG
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'
);
PRINT @SQL
EXEC sp_executesql @SQL;

