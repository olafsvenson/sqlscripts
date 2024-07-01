RETURN;
EXIT;

go

-- Анализ трейсов
--DROP TABLE DWH..SQL_workload_2013_01_16

SELECT * FROM ::fn_trace_getinfo(default)

/*
exec sp_trace_setstatus 2, 0	-- Stop
exec sp_trace_setstatus 2, 2	-- Close

*/

DROP TABLE #t



-- Загрузка трейсов
SELECT * 
INTO #t
FROM fn_trace_gettable('d:\SQL_Traces\MSSQLSERVER\dailyLong 2018-11-27 220000.trc', default);
dailyLong 2018-11-27 220000

CREATE CLUSTERED INDEX [CX_StartTime_endTime_databasename] ON #t ([StartTime],[EndTime],DatabaseName)
CREATE INDEX [CX_StartTime_databasename] ON #t ([StartTime],DatabaseName)
CREATE INDEX [ix_databasename] ON #t(DatabaseName)

SELECT COUNT(*) FROM #t

SELECT StartTime AS s,*
FROM #t
ORDER BY StartTime


SELECT * 
FROM #t
WHERE CAST(TextData AS NVARCHAR(MAX)) = (SELECT CAST(query AS NVARCHAR(MAX)) FROM #t2 WHERE sumcpu=1744)
ORDER BY starttime



SELECT StartTime AS s,*
FROM #t
WHERE 
		StartTime between '2018-11-28 01:00:00'  AND '2018-11-28 02:00:00'
ORDER BY StartTime


drop TABLE tempdb..__heavy_queries_290118

-- Самые тяжелые запросы
SELECT 	Top 10 
		--IDENTITY(INT,1,1)  AS [ID],
		CAST(TextData AS VARCHAR(max)) AS [Query],
		--DB_NAME(DatabaseID) AS [DatabaseID],
		--Databasename,
		--starttime,
		--endtime,
		sum(CPU/1000) AS [sumCPU],
		avg(CPU)/1000  AS [avgCPU],
		sum(Duration)/1000/1000 AS [sumDuration],
		avg(Duration)/1000 AS [avgDuration],
		avg(Reads) AS [avgReads],
		avg(Writes) AS [avgWrites],
		COUNT(1) AS [Count]
--INTO tempdb..__heavy_queries_290118
FROM #t
	--WHERE starttime > '2014-01-16'
	--WHERE 
	--	StartTime between '2018-29-01 8:00:00'  AND '2018-29-01 18:00:00'
	--	--duration BETWEEN 3600000 AND 3700000
	--AND 
	--LoginName != 'SNH\sp-sharepoint'
	----AND TextData LIKE N'%Проведена презентация%'
	----WHERE 
	--	--	starttime between '2014-27-03 09:00' AND '2014-27-03 10:00'
	--	AND DatabaseName = 'crm'
group BY CAST(TextData AS VARCHAR(max)) 
order by 
		--sum(Duration)/1000/1000 
		sum(CPU*1.0)/1000	DESC
		--avg(Duration)/1000 desc


		SELECT * FROM tempdb..__heavy_queries_290118


		SELECT TOP 10 * FROM 	#t
		WHERE CAST (TextData AS VARCHAR(max)) = (SELECT query FROM tempdb..__heavy_queries_290118  WHERE sumcpu = 2317)


		DROP TABLE tempdb..__common_queries_290118
SELECT 	Top 10
		IDENTITY(INT,1,1)  AS [ID],
		CAST(TextData AS VARCHAR(max)) AS [Query],
		--LEFT(TextData,450),
		sum(CPU/1000) AS [sumCPU],
		avg(CPU/1000)  AS [avgCPU],
		sum(Duration)/1000 AS [sumDuration],
		avg(Duration)/1000 AS [avgDuration],
		avg(Reads) AS [avgReads],
		avg(Writes) AS [avgWrites],
		COUNT(1) AS [Count]
INTO tempdb..__common_queries_290118
from #t
	WHERE StartTime between '2018-29-01 8:00:00'  AND '2018-29-01 18:00:00'
	AND DatabaseName = 'crm'
group BY CAST(TextData AS VARCHAR(max)) 
--order by SUM(t.CPU) DESC
order by COUNT(1) DESC


SELECT * FROM tempdb..__common_queries_290118


		SELECT TOP 100 * FROM #t 
		WHERE 
			StartTime between '2017-06-16 13:00:00'  AND '2017-06-16 14:00:00'
		AND LoginName != 'SNH\sp-sharepoint'
		AND TextData LIKE'SELECT TOP 30 T1._IDRRef, T1._Marked, T1._Number, T1._Date_Time, T1._Posted,'''
		ORDER BY cpu desc



SELECT TOP 10

		CAST(TextData AS VARCHAR(max)) AS [Query],
		--DB_NAME(DatabaseID) AS [DatabaseID],
		Databasename,
		--starttime,
		--endtime,
		CPU/1000 AS [CPU],
		Duration/1000 AS [DurationInSec],
		Duration/1000/1000/60 AS [DurationInMin],
		Reads AS [Reads],
		Writes AS [Writes],
		StartTime,
		EndTime,
		DATEDIFF(mi,starttime,endtime) AS [TimeDiff],
		spid
	  FROM #t  
WHERE 
		StartTime between '2017-04-25 14:30:00'  AND '2017-04-25 15:40:00'
		AND databasename =N'crm'
ORDER BY 
		Duration DESC
		--Reads desc
		--cpu desc


SELECT TOP 10
		*
FROM DWH..dailyLong_2014_02_06_stat  ORDER BY avgduration DESC


-- по CPU
SELECT TOP 10 *
FROM #t 
WHERE databasename = N'Zup3_0'
	AND StartTime between '2017-04-19 08:55:00'  AND '2017-04-19 09:25:00'
ORDER BY Duration DESC


SELECT*
  FROM [dbo].[dailyCPU_2014_01_24]
WHERE CAST(TextData AS VARCHAR(max)) = (
				SELECT query FROM [dbo].[dailyCPU_2014_01_24_stat] WHERE id=3
)




-- 03:46

-- просмотр
SELECT 
		ID,
		--replace(replace(Query, char(10), ' '), char(13), ' ') AS [Query_for_Excell],
		Query,
		SumCpu,
		avgCpu,
		sumDuration,
		avgDuration,
		avgReads,
		avgWrites
 FROM SQL_workload_2013_01_16_stat ORDER by sumCPU DESC

 -- Статистика по базе
select 
		DatabaseName, 
		CPU = sum(CPU)/1000, 
		avgCPU = avg(CPU), 
		DurationSec=sum(Duration)/1000000, 
		avgDurationMs = avg(Duration)/1000, 
		avgReads = avg(Reads), 
		avgWrites = avg(Writes), 
		[COUNT] = count(*)
	from #t
		WHERE DatabaseName IN  ('TraceReport')
		--AND starttime between '2014-06-23 00:00' AND '2014-06-23 19:30'
	group by DatabaseName
	order by CPU DESC
  
    

	select 
		DatabaseName, 
		CPU = sum(CPU)/1000, 
		avgCPU = avg(CPU*1.0), 
		Duration=sum(Duration)/1000000, 
		avgDuration = avg(Duration*1.0)/1000, 
		avgReads = avg(Reads*1.0), 
		avgWrites = avg(Writes*1.0), 
		[COUNT] = count(*)
	from DWH..dailyLong_2014_02_06 
	--	WHERE starttime > '2014-01-16'
	group by DatabaseName
	order by CPU desc





	SELECT 	Top 100 
		IDENTITY(INT,1,1)  AS [ID],
		LEFT(CAST(TextData AS VARCHAR(max)),450) AS [Query],
		sum(t.CPU/1000) AS [sumCPU],
		avg(CPU*1.0)/1000  AS [avgCPU],
		sum(Duration)/1000 AS [sumDuration],
		avg(Duration*1.0)/1000 AS [avgDuration],
		avg(Reads) AS [avgReads],
		avg(Writes*1.0) AS [avgWrites],
		COUNT(1) AS [Count]
INTO DWH..DailyLong_2014_01_09_stats 
from DWH..DailyLong_2014_01_09  t
	WHERE 
			--starttime between '2014-01-09' AND '2014-01-10'
			DatabaseName='buh2_0'
group BY CAST(TextData AS VARCHAR(max)) 
order by SUM(t.CPU) DESC



SELECT 
		*
FROM #t
WHERE 	DatabaseName='TraceReport'
ORDER BY cpu DESC



SELECT*
  FROM [dbo].[dailyLong_2014_01_22]
WHERE CAST(TextData AS VARCHAR(max)) = (
				SELECT query FROM [dbo].[dailyLong_2014_01_22_stat] WHERE id= 2
)



SELECT * 
INTO tempdb..dailyLong_2016_10_17
FROM #t

ALTER TABLE  tempdb..dailyLong_2016_10_17
ALTER COLUMN Textdata NVARCHAR(MAX)



