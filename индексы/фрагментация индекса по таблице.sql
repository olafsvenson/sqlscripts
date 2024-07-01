SELECT OBJECT_NAME(OBJECT_ID), 
       index_id, 
       index_type_desc, 
       index_level, 
       avg_fragmentation_in_percent, 
       avg_page_space_used_in_percent, 
       page_count
FROM sys.dm_db_index_physical_stats(DB_ID(N'lkdatamart'), OBJECT_ID('Document'), NULL, NULL, 'SAMPLED')   -- change Db name
ORDER BY avg_fragmentation_in_percent DESC;

ALTER INDEX ALL ON [_Reference255] REBUILD
ALTER INDEX ALL ON [_Reference252] rebuild
