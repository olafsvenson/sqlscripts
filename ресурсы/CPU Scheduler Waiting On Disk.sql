SELECT  COUNT(*) Schedulers,
        AVG(work_queue_count) AS [Avg Work Queue Count],
        AVG(pending_disk_io_count) AS [Avg Pending DiskIO Count],
        SUM(work_queue_count) AS [SUM Work Queue Count],
        SUM(pending_disk_io_count) AS [SUM Pending DiskIO Count]
FROM sys.dm_os_schedulers WITH (NOLOCK)
WHERE scheduler_id < 255;