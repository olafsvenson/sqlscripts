/*
	http://michaeljswart.com/2016/01/monitor_deadlocks/
*/

declare @filenamePattern sysname;
 
SELECT @filenamePattern = REPLACE( CAST(field.value AS sysname), '.xel', '*xel' )
FROM sys.server_event_sessions AS [session]
JOIN sys.server_event_session_targets AS [target]
  ON [session].event_session_id = [target].event_session_id
JOIN sys.server_event_session_fields AS field 
  ON field.event_session_id = [target].event_session_id
  AND field.object_id = [target].target_id    
WHERE
    field.name = 'filename'
    and [session].name= N'capture_deadlocks'
 
SELECT deadlockData.*
FROM sys.fn_xe_file_target_read_file ( @filenamePattern, null, null, null) 
    as event_file_value
CROSS APPLY ( SELECT CAST(event_file_value.[event_data] as xml) ) 
    as event_file_value_xml ([xml])
CROSS APPLY (
    SELECT 
        event_file_value_xml.[xml].value('(event/data/value/deadlock/process-list/process/@spid)[1]', 'int') as first_process_spid,
        event_file_value_xml.[xml].value('(event/@name)[1]', 'varchar(100)') as eventName,
        event_file_value_xml.[xml].value('(event/@timestamp)[1]', 'datetime') as eventDate,
        event_file_value_xml.[xml].query('//event/data/value/deadlock') as deadlock    
  ) as deadlockData
WHERE deadlockData.eventName = 'xml_deadlock_report'
ORDER BY eventDate DESC