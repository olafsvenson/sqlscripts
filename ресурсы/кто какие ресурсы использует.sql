/*
	Запрос периодически опрашивает DMV-представление на проятжении 10-секундного интервала 
	и выводит разницу между первым и вторым запросами
*/


-- Who is using all the resources?
select spid, kpid, cpu, physical_io, memusage, sql_handle, 1 as sample,
getdate() as sampleTime, hostname, program_name, nt_username
into #Resources
from master..sysprocesses

waitfor delay '00:00:10'

Insert #Resources
select spid, kpid, cpu, physical_io, memusage, sql_handle, 2 as sample,
getdate() as sampleTime, hostname, program_name, nt_username
from master..sysprocesses

-- Find the deltas
select r1.spid
, r1.kpid
, r2.cpu - r1.cpu as d_cpu_total
, r2.physical_io - r1.physical_io as d_physical_io_total
, r2.memusage - r1.memusage as d_memusage_total
, r1.hostname, r1.program_name, r1.nt_username
, r1.sql_handle
, r2.sql_handle
from #resources as r1 inner join #resources as r2 on r1.spid = r2.spid
and r1.kpid = r2.kpid
where r1.sample = 1
and r2.sample = 2
and (r2.cpu - r1.cpu) > 0
order by (r2.cpu - r1.cpu) desc

select r1.spid
, r1.kpid
, r2.cpu - r1.cpu as d_cpu_total
, r2.physical_io - r1.physical_io as d_physical_io_total
, r2.memusage - r1.memusage as d_memusage_total
, r1.hostname, r1.program_name, r1.nt_username
into #Usage
from #resources as r1 inner join #resources as r2 on r1.spid = r2.spid
and r1.kpid = r2.kpid
where r1.sample = 1
and r2.sample = 2
and (r2.cpu - r1.cpu) > 0
order by (r2.cpu - r1.cpu) desc
select spid, hostname, program_name, nt_username
, sum(d_cpu_total) as sum_cpu
, sum(d_physical_io_total) as sum_io
from #Usage
group by spid, hostname, program_name, nt_username
order by 6 desc

drop table #resources

drop table #Usage

