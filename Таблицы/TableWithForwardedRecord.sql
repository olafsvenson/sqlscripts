-- Create Table List in TV
--USE database_name;
DECLARE @TableList TABLE
(id        INT IDENTITY(1, 1), 
 TableName VARCHAR(255)
);
INSERT INTO @TableList
       SELECT OBJECT_NAME(OBJECT_ID) TableName
       FROM sys.dm_db_partition_stats st
       WHERE index_id = 0 -- index_id / ID of the heap or index the partition is part of / Heap=0 
             AND used_page_count > 10000
       ORDER BY st.row_count DESC;
-- LOOP Table Names through the DMV
DECLARE @counter INT;
SET @counter = 1;
WHILE(@counter <=
(
    SELECT MAX(id)
    FROM @TableList
))
    BEGIN
        DECLARE @colVar VARCHAR(255);
        SELECT @colVar = TableName
        FROM @TableList
        WHERE id = @counter;
        DECLARE @TableForwardedRecord TABLE
        (RowID                  INT IDENTITY(1, 1), 
         table_name             NVARCHAR(255), 
         forwarded_record_count INT
        );
        INSERT INTO @TableForwardedRecord
               SELECT OBJECT_NAME(object_id) AS table_name, 
                      forwarded_record_count
               FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(@colVar), DEFAULT, DEFAULT, 'DETAILED')
               WHERE forwarded_record_count > 10000
                     AND index_id = 0
                     AND page_count > 10000;
        SET @counter = @counter + 1;
    END;
-- read table names ordered by Forwarded Record Count
SELECT *
FROM @TableForwardedRecord
ORDER BY forwarded_record_count DESC;