
--DROP TABLE IF EXISTS #errorLog;  -- this is new syntax in SQL 2016 and later
if object_id('tempdb..#errorLog') is not null
	drop table #errorLog

CREATE TABLE #errorLog (LogDate DATETIME, ProcessInfo VARCHAR(64), [Text] VARCHAR(MAX));

INSERT INTO #errorLog
EXEC sp_readerrorlog -- specify the log number or use nothing for active error log

SELECT * 
FROM #errorLog a
WHERE EXISTS (SELECT * 
              FROM #errorLog b
              WHERE [Text] like '%killed%'
                AND a.LogDate = b.LogDate
                AND a.ProcessInfo = b.ProcessInfo)
ORDER BY LogDate desc