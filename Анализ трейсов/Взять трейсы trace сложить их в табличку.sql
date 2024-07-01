-- Взять трейсы сложить их в табличку
drop table #temp_trc 

SELECT *
INTO #temp_trc 
FROM fn_trace_gettable('G:\Traces\ASQL1\hourly 2012-04-09 050925.trc', default);


SELECT top 1 *  FROM #temp_trc 

-- Последние 1000
SELECT Top 100 LoginName,T.StartTime,CPU,Reads,Writes,Duration,HostName,* from  #temp_trc T 
--where Cast(TextData as varchar(max)) like '%P2P_u_tblClients%'
order by T.StartTime desc
group by Cast(TextData as varchar(max)) 


--drop table #temp_trc 
--delete from #temp_trc  where StartTime<'2011-02-16 06:30:00'	-- Удалить старые записи до оптимизации


SELECT Top 1000 t.CPU, t.CPU/1000,StartTime,EndTime,* from  #temp_trc t order by t.CPU desc


SELECT Top 1000 Cast(TextData as varchar(max)),Sum(t.CPU),SUM(t.CPU/1000) 
from  #temp_trc t 
group by Cast(TextData as varchar(max))
order by SUM(t.CPU) desc



-- Группировка по объектам
Select ObjectName,COUNT(*)as 'Count' ,SUM(CPU)/1000 as 'CPU',sum(Duration)/1000000 as 'Duration'
from #temp_trc t
where DatabaseName=N'svadba_catalog'
group by ObjectName
order by sum(CPU) desc


-- Группировка по логинам
SELECT LoginName,COUNT(*),SUM(CPU) from  #temp_trc 
group by LoginName
order by SUM(CPU) desc


-- Выбрать все события с текстом
SELECT LoginName,T.StartTime,CPU,Reads,Writes,Duration,* from #temp_trc T  where TextData  like '%SendAutomaticInvitations%' order by T.Starttime desc



Select Top 20 SUBSTRING(TextData,1,500),DatabaseName,COUNT(*),Sum(Reads),SUM(Writes),Sum(Duration),SUM(CPU) 
from #temp_trc t
where ObjectName is null
group by DatabaseName,SUBSTRING(TextData,1,500)
order by sum(Duration) desc