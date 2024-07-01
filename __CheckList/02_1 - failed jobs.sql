-- Какие job - не выполнились в последний раз
select sj.name,
	last_run_date,	
	--cast(cast(last_run_date as varchar) as datetime),
	last_run_time,
	sj.description,	
	case so.last_run_outcome
		WHEN 0 THEN 'Fail' 
		WHEN 1 THEN 'Succed'
		WHEN 3 THEN 'Cancel' 
	end Res,
	so.last_outcome_message
from msdb.dbo.sysjobservers so
inner join msdb.dbo.sysjobs sj on so.job_id=sj.job_id
where 
sj.enabled=1
--	and so.last_run_outcome IN (0,3)	--0 = Fail 1 = Succeed 3 = Cancel
and so.last_run_outcome IN (0)		--0 = Fail 1 = Succeed 3 = Cancel
--	and category_id<>3	-- Не берём системные job по БД
order by sj.name
