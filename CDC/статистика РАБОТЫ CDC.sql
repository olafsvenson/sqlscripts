USE [SberbankCSDDataMart]
GO
-- смотреть нижнюю строку
SELECT *
from sys.dm_cdc_log_scan_sessions 

 -- 2ой вариант
USE [SBOLDataMart]
GO 
SELECT session_id, start_time, end_time, duration, scan_phase,  
    error_count,last_commit_time, last_commit_cdc_time,tran_count, start_lsn, current_lsn, end_lsn,   
    last_commit_lsn,  log_record_count, schema_change_count,  
    command_count, first_begin_cdc_lsn, last_commit_cdc_lsn,   
    latency, empty_scan_count, failed_sessions_count  
FROM sys.dm_cdc_log_scan_sessions  
WHERE session_id = (SELECT MAX(b.session_id) FROM sys.dm_cdc_log_scan_sessions AS b);  
GO 