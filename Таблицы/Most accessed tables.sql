    /* Most accessed tables. */
 SELECT
       db_name(ius.database_id) [Database],
       t.NAME [Table],
      SUM(ius.user_seeks + ius.user_scans + ius.user_lookups) [#TimesAccessed]
    FROM
       sys.dm_db_index_usage_stats ius INNER JOIN sys.tables t
         ON ius.OBJECT_ID = t.object_id
    --WHERE
      -- database_id = DB_ID('Pegasus2008bb') 
    GROUP BY
       database_id,
       t.name
    ORDER BY
       SUM(ius.user_seeks + ius.user_scans + ius.user_lookups) DESC