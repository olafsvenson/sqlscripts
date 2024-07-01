-- =============================================
-- Description:	���������������� ����������� �������� 
-- =============================================
--DROP PROC [dbo].[OptimizeDBIndexes]

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_OptimizeDBIndexes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[sp_OptimizeDBIndexes]
GO

CREATE PROCEDURE [dbo].[sp_OptimizeDBIndexes]
AS
BEGIN
    -- http://www.sql-server-performance.com/2012/performance-tuning-re-indexing-update-statistics/
    -- ��� �������� � ������������� > 10% ����������� REORGANIZE
    -- ��� �������� � ������������� > 30% ����������� REBUILD 

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
    
	IF OBJECT_ID (N'tempdb..#work_to_do', N'U') IS NOT NULL
	DROP TABLE #work_to_do ;	

	-- Conditionally select tables and indexes from the sys.dm_db_index_physical_stats function
    -- and convert object and index IDs to names.
    SELECT
        object_id AS objectid,
        index_id AS indexid,
        partition_number AS partitionnum,
        avg_fragmentation_in_percent AS frag
    INTO #work_to_do
    FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, 'LIMITED')
    WHERE 
			avg_fragmentation_in_percent > 10.0 
			AND index_id > 0 -- <> HEAP
			AND page_count > 128 -- > 1 MB

    --SELECT * FROM #work_to_do;
	

    -- Declare the cursor for the list of partitions to be processed.
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
        
  	    -- 30 is an arbitrary decision point at which to switch between reorganizing and rebuilding.
        IF @frag < 30.0
            SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REORGANIZE ';
        IF @frag >= 30.0
            SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REBUILD WITH (SORT_IN_TEMPDB = ON)';
        IF @partitioncount > 1
            SET @command = @command + N' PARTITION=' + CAST(@partitionnum AS nvarchar(10));
        
		EXEC (@command);
        PRINT N'Executed: ' + @command;

    END;
    CLOSE cr_partitions;
    DEALLOCATE cr_partitions;
    DROP TABLE #work_to_do;
END
GO




