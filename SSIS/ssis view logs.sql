SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

 SELECT top 50
		o.operation_id EXECUTION_ID
    ,convert(datetimeoffset,OM.message_time,109) TIME
    ,D.message_source_desc ERROR_SOURCE
    ,OM.message ERROR_MESSAGE
    ,CASE ex.STATUS
        WHEN 4 THEN 'Package Failed'
        WHEN 7 THEN CASE EM.message_type 
            WHEN 120 THEN 'package failed' 
            WHEN 130 THEN 'package failed' ELSE 'Package Succeed'END
        END AS STATUS
FROM SSISDB.CATALOG.operation_messages AS OM 
INNER JOIN SSISDB.CATALOG.operations AS O ON O.operation_id = OM.operation_id
INNER JOIN SSISDB.CATALOG.executions AS EX ON o.operation_id = ex.execution_id
INNER JOIN (VALUES (- 1,'Unknown'),(120,'Error'),(110,'Warning'),(130,'TaskFailed')) EM(message_type, message_desc) ON EM.message_type = OM.message_type
INNER JOIN (VALUES 
 (10,'Entry APIs, such as T-SQL and CLR Stored procedures')
,(20,'External process used to run package (ISServerExec.exe)')
,(30,'Package-level objects')
,(40,'Control Flow tasks')
,(50,'Control Flow containers')
,(60,'Data Flow task')
    ) D(message_source_type, message_source_desc) ON D.message_source_type = OM.message_source_type
WHERE 
OM.message like '%incorrect checksum%'
	--ex.execution_id = 2585171
--AND OM.message_type IN (120,130,-1);
order by [time] desc