WAITFOR DELAY '02:30:00' ---- 2.5 hour Delay

-- Загрузка трейсов
SELECT * 
INTO master..__full_traces_2014_01_09 
FROM fn_trace_gettable('C:\SQL_Traces\hourly 2014-01-10 155341.trc', default);



SELECT TOP 100 
		LEFT(TextData,450)
FROM [dbo].[traces_2014_01_09]
--SELECT COUNT(*) FROM master..__full_traces_2014_01_09

--(17 021 404 row(s) affected)
-- 47 min
--SELECT @@servername

--DROP TABLE master..__full_traces_2014_01_09 
--DROP TABLE master..__full_traces_2014_01_09_stats

--CREATE INDEX IX_indx ON __full_traces_2014_01_09(cpu)
--DROP TABLE __full_traces_2014_01_09_stats

SELECT 	Top 100 
		IDENTITY(INT,1,1)  AS [ID],
		--CAST(TextData AS VARCHAR(max)) AS [Query],
		LEFT(TextData,450)
		sum(t.CPU/1000) AS [sumCPU],
		avg(CPU/1000)  AS [avgCPU],
		sum(Duration)/1000 AS [sumDuration],
		avg(Duration)/1000 AS [avgDuration],
		avg(Reads) AS [avgReads],
		avg(Writes) AS [avgWrites],
		COUNT(1) AS [Count]
INTO __full_traces_2014_01_09_stats
from __full_traces_2014_01_09  t
	--WHERE starttime between '2014-01-09' AND '2014-01-10'
group BY CAST(TextData AS VARCHAR(max)) 
order by SUM(t.CPU) DESC

SELECT COUNT(*) FROM __full_traces_2014_01_09_stats