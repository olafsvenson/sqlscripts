DECLARE 
    @Path_Default_Trace VARCHAR(500) = (SELECT [path] FROM sys.traces WHERE is_default = 1)
    
DECLARE
    @Index INT = PATINDEX('%\%', REVERSE(@Path_Default_Trace))
 
DECLARE
    @FullPath_Default_Trace VARCHAR(500) = LEFT(@Path_Default_Trace, LEN(@Path_Default_Trace) - @Index) + '\log.trc'
 
 
SELECT
    A.DatabaseName,
    A.[Filename],
    ( A.Duration / 1000 ) AS 'Duration_ms',
    A.StartTime,
    A.EndTime,
    ( A.IntegerData * 8.0 / 1024 ) AS 'GrowthSize_MB',
    A.ApplicationName,
    A.HostName,
    A.LoginName
FROM
    ::fn_trace_gettable(@FullPath_Default_Trace, DEFAULT) A
WHERE
    A.EventClass >= 92
    AND A.EventClass <= 95
    AND A.ServerName = @@servername 
ORDER BY
    A.StartTime DESC