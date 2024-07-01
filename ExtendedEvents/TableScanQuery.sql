CREATE EVENT SESSION [TableScanQuery]
ON SERVER
    ADD EVENT sqlserver.scan_started
    (SET collect_database_name = (1)
     ACTION
     (
         sqlserver.query_hash,
         sqlserver.query_plan_hash,
         sqlserver.sql_text
     )
    ),
    ADD EVENT sqlserver.scan_stopped
    (SET collect_database_name = (1))
    ADD TARGET package0.event_file
    (SET filename = N'TableScanQuery.xel')
WITH
(
    MAX_MEMORY = 4096KB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 3 SECONDS,
    MAX_EVENT_SIZE = 0KB,
    MEMORY_PARTITION_MODE = NONE,
    TRACK_CAUSALITY = ON,
    STARTUP_STATE = ON
);
GO