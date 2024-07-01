USE msdb;

DECLARE @collection_set_id int;
DECLARE @collection_set_uid uniqueidentifier

EXEC dbo.sp_syscollector_create_collection_set
    @name = N'Queries that Execute Most Often',
    @collection_mode = 0,
    @description = N'T',
    @logging_level=1,
    @days_until_expiration = 14,
    @schedule_name=N'CollectorSchedule_Every_30min',
    @collection_set_id = @collection_set_id OUTPUT,
    @collection_set_uid = @collection_set_uid OUTPUT
SELECT @collection_set_id,@collection_set_uid

DECLARE @collector_type_uid uniqueidentifier
SELECT @collector_type_uid = collector_type_uid FROM syscollector_collector_types 
WHERE name = N'Generic T-SQL Query Collector Type';

DECLARE @collection_item_id int
EXEC sp_syscollector_create_collection_item
@name= N'Query Most Often Stats',
@parameters=N'
<ns:TSQLQueryCollector xmlns:ns="DataCollectorType">
<Query>
  <Value>
  SELECT TOP 10 
 [Execution count] = execution_count
,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
          ELSE qs.statement_end_offset END - qs.statement_start_offset)/2)
,[Parent Query] = qt.text
,DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
ORDER BY [Execution count] DESC
  </Value>
  <OutputTable>most_often_query</OutputTable>
</Query>
 </ns:TSQLQueryCollector>',
    @collection_item_id = @collection_item_id OUTPUT,
    @frequency = 5, -- This parameter is ignored in cached mode
    @collection_set_id = @collection_set_id,
    @collector_type_uid = @collector_type_uid
SELECT @collection_item_id
   
GO
