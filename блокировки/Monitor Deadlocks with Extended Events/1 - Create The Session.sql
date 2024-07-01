/*
	http://michaeljswart.com/2016/01/monitor_deadlocks/
*/
CREATE EVENT SESSION [capture_deadlocks] ON SERVER 
ADD EVENT sqlserver.xml_deadlock_report( ACTION(sqlserver.database_name) ) 
ADD TARGET package0.asynchronous_file_target(
  SET filename = 'capture_deadlocks.xel',
      max_file_size = 10,
      max_rollover_files = 5)
WITH (
    STARTUP_STATE=ON,
    EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY=15 SECONDS,
    TRACK_CAUSALITY=OFF
    )
 
ALTER EVENT SESSION [capture_deadlocks] ON SERVER
    STATE=START;