
CREATE EVENT SESSION [xe_watchLoginIntent] ON SERVER 
ADD EVENT sqlserver.login
    ( ACTION ( sqlserver.username ) ),
ADD EVENT sqlserver.read_only_route_complete
    ( ACTION ( 
        sqlserver.client_app_name,
        sqlserver.client_connection_id,
        sqlserver.client_hostname,
        sqlserver.client_pid,
        sqlserver.context_info,
        sqlserver.database_id,
        sqlserver.database_name,
        sqlserver.username 
        ) ),
ADD EVENT sqlserver.read_only_route_fail
    ( ACTION ( 
        sqlserver.client_app_name,
        sqlserver.client_connection_id,
        sqlserver.client_hostname,
        sqlserver.client_pid,
        sqlserver.context_info,
        sqlserver.database_id,
        sqlserver.database_name,
        sqlserver.username 
        ) )
ADD TARGET package0.event_file( SET filename = N'xe_watchLoginIntent' )
WITH ( 
    MAX_MEMORY = 4096 KB, 
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS, 
    MAX_DISPATCH_LATENCY = 30 SECONDS,
    MAX_EVENT_SIZE = 0 KB, 
    MEMORY_PARTITION_MODE = NONE, 
    TRACK_CAUSALITY = ON,   --<-- relate events
    STARTUP_STATE = OFF      --<-- ensure sessions starts after failover
)