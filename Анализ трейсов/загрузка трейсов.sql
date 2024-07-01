SELECT * FROM ::fn_trace_getinfo(default)
exec sp_trace_setstatus <@TraceID>,0	-- Stop
exec sp_trace_setstatus <@TraceID>,2	-- Close


SELECT *
INTO #trc 
FROM fn_trace_gettable('\\sql02\SQL_Trace\SQL3\daily 2010-11-21 000000.trc', default);

DROP TABLE #temp_trc

SELECT * INTO traces_2014_01_09 FROM fn_trace_gettable('C:\SQL_Traces\dailyLong 2014-01-09 133501.trc', default);

SELECT COUNT(*) FROM #temp_trc 

SELECT Top 1000 t.CPU, t.CPU/1000,StartTime,EndTime,* from  #temp_trc t order by t.CPU desc
-- (17230 row(s) affected)
-- (21108 row(s) affected)
-- (21272 row(s) affected)

-- 59610

SELECT * 
INTO traces1
FROM #temp_trc


ALTER TABLE [dbo].[traces1] ALTER COLUMN [TextData] VARCHAR(8000)

SELECT MAX(dataLENgth(TextData)) FROM [dbo].[traces1] WHERE 

DELETE  FROM [dbo].[traces1] WHERE LEN(TextData) > 40000000
41839822


CREATE INDEX CI_indx ON [dbo].[traces1] (textData)
sp_help '#temp_trc'

SELECT 	Top 100 
		Cast(TextData as varchar(max)) AS 'Query',
		Sum(t.CPU) AS [CPU в микросекундах],
		SUM(t.CPU/1000) [CPU в милисекундах]
from   [dbo].[traces1] t 
group by Cast(TextData as varchar(max))
order by SUM(t.CPU) desc



-- Группировка по объектам
Select ObjectName,COUNT(*) ,SUM(CPU)
from traces_2014_01_09  t
group by ObjectName
order by SUM(CPU)  desc


-- Группировка по логинам
SELECT LoginName,COUNT(*),SUM(CPU) from  #temp_trc 
group by LoginName
order by SUM(CPU) desc


-- Выбрать все события с текстом
SELECT LoginName,T.StartTime,CPU,Reads,Writes,Duration,* from #temp_trc T  where TextData  like '%SendAutomaticInvitations%' order by T.Starttime desc