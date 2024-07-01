set nocount on

use msdb

if object_id('tempdb..#xp_results') is not null
	drop table #xp_results

create table #xp_results (
	job_id                uniqueidentifier not null,
    last_run_date         int              not null,
    last_run_time         int              not null,
    next_run_date         int              not null,
    next_run_time         int              not null,
    next_run_schedule_id  int              not null,
    requested_to_run      int              not null, -- bool
    request_source        int              not null,
    request_source_id     sysname          collate database_default null,
    running               int              not null, -- bool
    current_step          int              not null,
    current_retry_attempt int              not null,
    job_state             int              not null
  )

declare
	@job_id		uniqueidentifier,
	@job_owner	sysname
--получить действительные состояния задач
insert into #xp_results
execute master.dbo.xp_sqlagent_enum_jobs 1, @job_owner, @job_id

--Задачи с ошибками
select Task = N'Задачи, завершившиеся с ошибкой', q.name, q.lastRunDate, q.nextRunDate, currentTime = getdate(), category = ctg.name, q.is_running
	from
	(
		select
				j.name,
				j.category_id,
				lastStatus =
				(
					select top 1 h.run_status
						from dbo.sysjobhistory h
						where
							h.job_id = j.job_id
							and h.step_id = 0
						order by h.run_date desc, h.run_time desc
				),
				lastRunDate =
				(
					select top 1 lastRunDate = convert(datetime, convert(char(8), h.run_date)+' '+right('00'+convert(varchar(2), h.run_time / 10000),2)+':'+ right('00'+convert(varchar(2), h.run_time / 100 % 100),2)+':'+right('00'+convert(varchar(2), h.run_time % 100), 2), 120)
						from dbo.sysjobhistory h
						where
							h.job_id = j.job_id
							and h.step_id = 0
						order by lastRunDate desc
				),
				--время следующего запуска
				nextRunDate = 
				(
					select top 1 nextRunDate = convert(datetime, convert(char(8), nullif(s.next_run_date, 0))+' '+right('00'+convert(varchar(2), s.next_run_time / 10000),2)+':'+ right('00'+convert(varchar(2), s.next_run_time / 100 % 100),2)+':'+right('00'+convert(varchar(2), s.next_run_time % 100), 2), 120)
						from #xp_results s
						where s.job_id = j.job_id
						order by nextRunDate desc
				),
				is_running = r.running
			from dbo.sysjobs j
			left join #xp_results r on
				r.job_id = j.job_id
			where j.Enabled = 1
	) q
	inner join dbo.syscategories ctg on
		ctg.category_id = q.category_id
	where q.lastStatus = 0
	order by q.name

--задачи, которые не будут исполняться в будущем
select Task = N'Не будут больше исполняться', q.name, q.lastRunDate, q.nextRunDate, currentTime = getdate(), category = ctg.name, q.lastStatus
	from
	(
		select
				j.name,
				j.category_id,
				--статус последнего завершения задачи
				lastStatus =
				(
					select top 1 h.run_status
						from dbo.sysjobhistory h
						where
							h.job_id = j.job_id
							and h.step_id = 0
						order by h.run_date desc, h.run_time desc
				),
				--время последнего запуска
				lastRunDate =
				(
					select top 1 lastRunDate = convert(datetime, convert(char(8), h.run_date)+' '+right('00'+convert(varchar(2), h.run_time / 10000),2)+':'+ right('00'+convert(varchar(2), h.run_time / 100 % 100),2)+':'+right('00'+convert(varchar(2), h.run_time % 100), 2), 120)
						from dbo.sysjobhistory h
						where
							h.job_id = j.job_id
							and h.step_id = 0
						order by lastRunDate desc
				),
				--время следующего запуска
				nextRunDate = 
				(
					select top 1 nextRunDate = convert(datetime, convert(char(8), nullif(s.next_run_date, 0))+' '+right('00'+convert(varchar(2), s.next_run_time / 10000),2)+':'+ right('00'+convert(varchar(2), s.next_run_time / 100 % 100),2)+':'+right('00'+convert(varchar(2), s.next_run_time % 100), 2), 120)
						from #xp_results s
						where s.job_id = j.job_id
						order by nextRunDate desc
				)
			from dbo.sysjobs j
			where
				j.Enabled = 1
				--отсеять те, которые работают в текущий момент
				and not exists(select 1 from #xp_results r where r.job_id = j.job_id and r.running = 1)
	) q
	inner join dbo.syscategories ctg on
		ctg.category_id = q.category_id
	where (q.nextRunDate < dateadd(mi, -1, getdate()) or q.nextRunDate is NULL)
		AND q.name not in (
			'EnableCheckpointsTraceFlag',	-- ДЖОБ КОТОРЫЙ ЗАПУСКАЕТСЯ ПРИ СТАРТЕ SQLServerAgent
			'Reinitialize subscriptions having data validation failures' -- Обнаруживаются все подписки со сбоями при выполнении проверки данных, и они помечаются для повторной инициализации. При следующем запуске агента слияния или агента распространителя к подписчикам применяется новый моментальный снимок.
		)
		
	order by q.name

--задачи, исполняющиеся 3 часа и более
select Task = N'Долго выполняющиеся задачи', j.name, category = ctg.name, CurrentTime = getdate(), q.lastRunTime, Duration = convert(varchar(10), datediff(mi, lastRunTime, getdate()) / 60) + ':' + convert(varchar(10), datediff(mi, lastRunTime, getdate()) % 60)
	from
	(
		select job_id, last_run_date, last_run_time, lastRunTime = convert(datetime, convert(char(8), nullif(last_run_date, 0))+' '+right('00'+convert(varchar(2), last_run_time / 10000),2)+':'+ right('00'+convert(varchar(2), last_run_time / 100 % 100),2)+':'+right('00'+convert(varchar(2), last_run_time % 100), 2), 120)
			from #xp_results
			where running = 1
	) q
	inner join dbo.sysjobs j on
		j.job_id = q.job_id
	inner join dbo.syscategories ctg on
		ctg.category_id = j.category_id
	where
		datediff(hh, lastRunTime, getdate()) >= 3
		and ctg.name not in (N'REPL-LogReader', N'REPL-QueueReader', 'REPL-Distribution')
		and j.name <> 'Replication monitoring refresher for distribution.' -- continuous job. там вечный двиг, то есть цикл, так что чем дольше работает, тем лучше.
		--нет записи о завершении прошлой задачи
		and not exists(select 1
				from dbo.sysjobhistory h
				where
					h.job_id = j.job_id
					and h.step_id = 0
					and h.run_date = q.last_run_date
					and h.run_time = q.last_run_time
			)


if object_id('tempdb..#xp_results') is not null
	drop table #xp_results

--Отключённые задачи репликации
select Task = N'Отключённые задачи репликации', j.name, category = ctg.name, CurrentTime = getdate()
	from dbo.sysjobs j
	inner join dbo.syscategories ctg on
		ctg.category_id = j.category_id
	where
		j.enabled = 0
		and ctg.name like 'REPL%'
		and ctg.name not in ('REPL-Alert Response', 'REPL-Snapshot', 'REPL-Subscription Cleanup')