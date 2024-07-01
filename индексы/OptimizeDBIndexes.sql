/*
	Обходит все базы

	если фрагментация < 30% будет REORGANIZE, иначе REBUILD
*/
set nocount on
declare @i int=0, @db_name sysname, @compability_level INT, @query NVARCHAR(max)


DECLARE curCursor CURSOR FAST_FORWARD read_only FOR 
		SELECT name, compatibility_level FROM sys.databases s
		WHERE database_id > 4	
		ORDER BY database_id
												
               
OPEN curCursor

FETCH NEXT FROM curCursor INTO @db_name, @compability_level

WHILE @@FETCH_STATUS = 0
	begin
	
		
	IF @compability_level < 90
	BEGIN
	
	-- если 2000

	SET @query = '  
		Use [#]
		

		print ''*** Processing DB [#] ***''
		
		exec sp_msforeachtable N''DBCC DBREINDEX (''''?'''')''
	  '

	  SET @query = REPLACE(@query, '#', @db_name)
	
	PRINT @query
	EXECUTE(@query)

	end  
	ELSE
	BEGIN
		
		-- для > 2005 будет более продвинутый алгоритм
		
		set @query = '
				print ''*** Processing DB [?] ***''

				USE [?]
				
				SET NOCOUNT ON;
				DECLARE @objectid int;
				DECLARE @indexid int;
				DECLARE @partitioncount bigint;
				DECLARE @schemaname nvarchar(130);
				DECLARE @objectname nvarchar(130);
				DECLARE @indexname nvarchar(130);
				DECLARE @partitionnum bigint;
				DECLARE @partitions bigint;
				DECLARE @frag float;
				DECLARE @command nvarchar(4000);
    
				IF OBJECT_ID (N''tempdb..#work_to_do'', N''U'') IS NOT NULL
				DROP TABLE #work_to_do;	

				SELECT
					object_id AS objectid,
					index_id AS indexid,
					partition_number AS partitionnum,
					avg_fragmentation_in_percent AS frag
				INTO #work_to_do
				FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, ''LIMITED'')
				WHERE 
						avg_fragmentation_in_percent > 10.0 
						AND index_id > 0 -- <> HEAP
						AND page_count > 128 -- > 1 MB

				DECLARE cr_partitions CURSOR FOR SELECT * FROM #work_to_do;

				OPEN cr_partitions;
				WHILE (1=1)
				BEGIN
					FETCH NEXT
						FROM cr_partitions
						INTO @objectid, @indexid, @partitionnum, @frag;
        
					IF @@FETCH_STATUS < 0 BREAK;
        
					SELECT @objectname = QUOTENAME(o.name), @schemaname = QUOTENAME(s.name)
					FROM sys.objects AS o
					JOIN sys.schemas as s ON s.schema_id = o.SCHEMA_ID
					WHERE o.object_id = @objectid;
        
					SELECT @indexname = QUOTENAME(name)
					FROM sys.indexes
					WHERE  object_id = @objectid AND index_id = @indexid;

					SELECT @partitioncount = count (*)
					FROM sys.partitions
					WHERE object_id = @objectid AND index_id = @indexid;
        
  					-- если фрагментация < 30% будет REORGANIZE, иначе REBUILD
					IF @frag < 30.0
						SET @command = N''ALTER INDEX '' + @indexname + N'' ON '' + @schemaname + N''.'' + @objectname + N'' REORGANIZE '';
					IF @frag >= 30.0
						SET @command = N''ALTER INDEX '' + @indexname + N'' ON '' + @schemaname + N''.'' + @objectname + N'' REBUILD WITH (SORT_IN_TEMPDB = ON)'';
					IF @partitioncount > 1
						SET @command = @command + N'' PARTITION='' + CAST(@partitionnum AS nvarchar(10));
        
					EXEC (@command);
					PRINT N''Executed: '' + @command;

				END;
				CLOSE cr_partitions;
				DEALLOCATE cr_partitions;
				DROP TABLE #work_to_do;
		'

		SET @query = REPLACE(@query, '?', @db_name)

		exec (@query)
		PRINT @query

	end  


	set @i += 1
	print @db_name
	PRINT @compability_level
 
				
	FETCH NEXT FROM curCursor INTO @db_name, @compability_level	
	END

CLOSE curCursor
DEALLOCATE curCursor	