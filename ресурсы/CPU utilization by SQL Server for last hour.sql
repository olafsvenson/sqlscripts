-- Загрузка CPU за последний час

DECLARE @ticks_ms BIGINT
SELECT @ticks_ms = ms_ticks
FROM sys.dm_os_sys_info;
SELECT TOP 60 id
    ,dateadd(ms, - 1 * (@ticks_ms - [timestamp]), GetDate()) AS EventTime
    ,ProcessUtilization as '%SQL CPU'
    ,SystemIdle '%Idle CPU'
    ,100 - SystemIdle - ProcessUtilization AS 'Others = (100%-SQL-Idle)'
FROM (
    SELECT record.value('(./Record/@id)[1]', 'int') AS id
    ,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
                          AS SystemIdle
    ,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') 
                          AS ProcessUtilization
        ,timestamp
    FROM (
        SELECT timestamp
            ,convert(XML, record) AS record
        FROM sys.dm_os_ring_buffers
        WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
            AND record LIKE '%SystemHealth%'
        ) AS sub1
    ) AS sub2
ORDER BY id DESC