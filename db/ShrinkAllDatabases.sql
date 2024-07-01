SET QUOTED_IDENTIFIER ON
GO
DECLARE @SQL NVARCHAR(MAX)=
(
	select  
	   'USE [' + d.NAME + N']' + CHAR(13) + CHAR(10) 
		+ 'DBCC SHRINKFILE (N''' + mf.name + N''' , 0, TRUNCATEONLY)' 
		+ CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) 
	FROM 
			 sys.master_files mf 
		JOIN sys.databases d 
			ON mf.database_id = d.database_id 
	WHERE d.database_id > 4 
			AND d.state = 0 -- ONLINE
		 and mf.type_desc = 'LOG' -- ROWS , LOG
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'
);
PRINT @SQL
EXEC sp_executesql @SQL;




-- Старый вариант
set nocount on
declare @i int=0, @db_name sysname,@file_name sysname,@query NVARCHAR(max)


DECLARE curCursor CURSOR FAST_FORWARD read_only FOR 
select   d.NAME,mf.name
FROM 
         sys.master_files mf 
    JOIN sys.databases d 
        ON mf.database_id = d.database_id 
WHERE d.database_id > 4 
		AND d.state = 0 -- ONLINE
	 and mf.type_desc = 'LOG' -- ROWS , LOG
												
               
OPEN curCursor

FETCH NEXT FROM curCursor INTO @db_name, @file_name

WHILE @@FETCH_STATUS = 0
	begin
	
	SET @query=     'USE [' + @db_name + N']' + CHAR(13) + CHAR(10) 
    + 'DBCC SHRINKFILE (N''' + @file_name + N''' , 0, TRUNCATEONLY)' 
    + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) 	

	PRINT @query

	EXEC(@query)
 
				
	FETCH NEXT FROM curCursor INTO @db_name, @file_name	
	END

CLOSE curCursor
DEALLOCATE curCursor	




select  
   'USE [' + d.NAME + N']' + CHAR(13) + CHAR(10) 
    + 'DBCC SHRINKFILE (N''' + mf.name + N''' , 0, TRUNCATEONLY)' 
    + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) 
FROM 
         sys.master_files mf 
    JOIN sys.databases d 
        ON mf.database_id = d.database_id 
WHERE d.database_id > 4 
		AND d.state = 0 -- ONLINE
	 and mf.type_desc = 'LOG' -- ROWS , LOG







