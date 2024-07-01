SELECT DB_NAME(dest.[dbid]) AS 'databaseName'
    , OBJECT_NAME(dest.objectid, dest.[dbid]) AS 'procName'
    , MAX(deqs.last_execution_time) AS 'last_execution'
FROM sys.dm_exec_query_stats AS deqs
Cross Apply sys.dm_exec_sql_text(deqs.sql_handle) AS dest
WHERE dest.[TEXT] Like '%tblClients%' -- replace
    And dest.[dbid] IS Not Null  -- exclude ad-hocs
GROUP BY DB_NAME(dest.[dbid])
    , OBJECT_NAME(dest.objectid, dest.[dbid])
ORDER BY databaseName
    , procName
OPTION (MaxDop 1);