SELECT * FROM ::fn_trace_getinfo(default)


n:\tmp\hourly 2012-01-27 030000.trc


hourly 2012-01-26 230000
hourly 2012-01-27 000000


SELECT * INTO #temp_trc1 FROM fn_trace_gettable('n:\tmp\hourly 2012-01-26 230000.trc', default);
SELECT * INTO #temp_trc2 FROM fn_trace_gettable('n:\tmp\hourly 2012-01-27 000000.trc', default);

drop table  #temp_trc

select duration,cpu,textdata,loginname,starttime,endtime,applicationname from #temp_trc order by starttime desc where starttime between '2011-02-25 08:00:00' and '2011-02-25 10:00:00' /*and loginname <> 'repladmin'*/ order by starttime desc--order by duration desc--order by starttime desc --duration DESC

select * from #temp_trc order by starttime desc --duration DESC




select DatabaseName, ObjectName, CPU = sum(CPU)/1000, avgCPU = avg(CPU*1.0), Duration=sum(Duration)/1000000, avgDuration = avg(Duration*1.0)/1000, avgReads = avg(Reads*1.0), cnt = count(*)
	from dbo.__FullTraceAFR2_New_20120131
	group by DatabaseName, ObjectName
	order by CPU desc


select DatabaseName, ObjectName, CPU = sum(CPU)/1000, avgCPU = avg(CPU*1.0), Duration=sum(Duration)/1000000, avgDuration = avg(Duration*1.0)/1000, avgReads = avg(Reads*1.0), cnt = count(*)
	from dbo.#temp_trc2
	group by DatabaseName, ObjectName
	order by CPU desc



-- по БД
Select DatabaseName,COUNT(*) as 'Count',SUM(Reads) as 'Reads',SUM(writes) as 'Writes',SUM(Duration) as 'Duration',SUM(CPU) as 'CPU'
from dbo.__FullTraceAMO1_New_20120131
group by DatabaseName
order by SUM(CPU)  desc

-- логины
SELECT LoginName,COUNT(*) as 'Count',SUM(Reads) as 'Reads',SUM(writes) as 'Writes',SUM(Duration) as 'Duration',SUM(CPU) as 'CPU'
from dbo.__FullTraceAMO1_New_20120131
group by LoginName
order by SUM(CPU) DESC





-- Запросы с objectname =NUll
Select Top 20 SUBSTRING(TextData,1,50),DatabaseName,COUNT(*),Sum(Reads),SUM(Writes),Sum(Duration),SUM(CPU) 
from dbo.__FullTraceAMO1_New_20120131
where ObjectName is NULL AND SUBSTRING(TextData,1,50) NOT LIKE '%begin tran%'  and  SUBSTRING(TextData,1,50) NOT LIKE '%set quoted_identifier off%' and SUBSTRING(TextData,1,50) NOT LIKE '%if @@trancount > 0 commit tran%'
group by DatabaseName,SUBSTRING(TextData,1,50)
order by SUM(CPU) DESC


-- Запросы с objectname = sp_executesql
Select Top 20 SUBSTRING(TextData,CHARINDEX('sp_executesql',TextData),60),DatabaseName,COUNT(*),Sum(Reads),SUM(Writes),Sum(Duration),SUM(CPU) 
from traces_2014_01_09
where ObjectName ='sp_executesql'
group by DatabaseName,SUBSTRING(TextData,CHARINDEX('sp_executesql',TextData),60)
order by SUM(CPU) desc


-- FULL объекты
Select ObjectName,COUNT(*) as 'Count',SUM(Reads) as 'Reads',SUM(writes) as 'Writes',SUM(Duration) as 'Duration',SUM(CPU) as 'CPU'
from dbo.__FullTraceAMO1_New_20120131
group by ObjectName
order by SUM(CPU)  DESC