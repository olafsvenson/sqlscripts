/*
	Запрос показывает задачи, которые в настоящее время находятся в состоянии ожидания
*/

select *
, 1 as sample
, getdate() as sample_time
into #waiting_tasks
from sys.dm_os_waiting_tasks

waitfor delay '00:00:10'

insert #waiting_tasks
select *
, 2
, getdate()
from sys.dm_os_waiting_tasks

-- figure out the deltas
select w1.session_id
, w1.exec_context_id
,w2.wait_duration_ms - w1.wait_duration_ms as d_wait_duration
, w1.wait_type
, w2.wait_type
, datediff(ms, w1.sample_time, w2.sample_time) as interval_ms
from #waiting_tasks as w1 inner join #waiting_tasks as w2 on w1.session_id =
w2.session_id
and w1.exec_context_id = w2.exec_context_id
where w1.sample = 1
and w2.sample = 2
order by 3 desc

-- select * from #waiting_tasks

drop table #waiting_tasks