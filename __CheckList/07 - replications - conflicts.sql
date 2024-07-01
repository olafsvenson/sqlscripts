--Ошибки агентов

declare @agentAlerts table
(
	publisher			sysname null,
	publisher_db		sysname null,
	publication			sysname null,
	subscriber			sysname null,
	subscriber_db		sysname null,
	agent_type			sysname null,
	article				sysname null,
	time				datetime,
	alert_error_text	ntext
)
if object_id('msdb.dbo.sysreplicationalerts') is not null
begin
insert into @agentAlerts (publisher, publisher_db, publication, subscriber, subscriber_db, agent_type, article, time, alert_error_text)
select a.publisher, a.publisher_db, a.publication, a.subscriber, a.subscriber_db,
		agent_type = case a.agent_type
			when 1 then N'Snapshot Agent'
			when 2 then N'Log Reader Agent'
			when 3 then N'Distribution Agent'
			when 4 then 'Merge Agent'
		end,
		a.article, a.time, a.alert_error_text
	from
	(
		select publisher, publisher_db, publication, subscriber, subscriber_db, article, last_time = max(time)
			from msdb.dbo.sysreplicationalerts
			group by publisher, publisher_db, publication, subscriber, subscriber_db, article
	) q
	inner join msdb.dbo.sysreplicationalerts a on
		a.publisher = q.publisher
		and a.publisher_db = q.publisher_db
		and isnull(a.publication, N'') = isnull(q.publication, N'')
		and a.subscriber = q.subscriber
		and a.subscriber_db = q.subscriber_db
		and isnull(a.article, N'') = isnull(q.article, N'')
		and a.time = q.last_time
	where a.error_id != 0
	ORDER BY a.time DESC
end
select Task = N'Ошибки агентов', publisher, publisher_db, publication, subscriber, subscriber_db, agent_type, article, time, alert_error_text
from @agentAlerts

--Ошибки агентов
declare @distHistory table
(
	agent_id int NOT NULL,
	runstatus int NOT NULL,
	start_time datetime NOT NULL,
	time datetime NOT NULL,
	duration int NOT NULL,
	comments ntext NOT NULL,
	xact_seqno varbinary(16) NULL,
	current_delivery_rate float NOT NULL,
	current_delivery_latency int NOT NULL,
	delivered_transactions int NOT NULL,
	delivered_commands int NOT NULL,
	average_commands int NOT NULL,
	delivery_rate float NOT NULL,
	delivery_latency int NOT NULL,
	total_delivered_commands int NOT NULL,
	error_id int NOT NULL,
	updateable_row bit NOT NULL
)
if object_id('distribution.dbo.MSdistribution_history') is not null
begin
insert into @distHistory
		(agent_id, runstatus, start_time, time, duration, comments, xact_seqno, current_delivery_rate, current_delivery_latency, delivered_transactions, delivered_commands, average_commands, delivery_rate, delivery_latency, total_delivered_commands, error_id, updateable_row)

select h.agent_id, h.runstatus, h.start_time, h.time, h.duration, h.comments, h.xact_seqno, h.current_delivery_rate, h.current_delivery_latency, h.delivered_transactions, h.delivered_commands, h.average_commands, h.delivery_rate, h.delivery_latency, h.total_delivered_commands, h.error_id, h.updateable_row
	from
	(
		select agent_id, max_time = max(time)
			from distribution.dbo.MSdistribution_history
			--не учитываем работающие агенты, чтобы найти предыдущую по времени запись
			where runstatus != 3
			group by agent_id
	) q
	inner join distribution.dbo.MSdistribution_history h on
		h.agent_id = q.agent_id
		and h.time = q.max_time
	where h.runstatus in (5,6)
	ORDER BY h.time DESC
end
if @@servername <> 'devdb'
	select Task = N'История агентов дистрибъюции', agent_id, runstatus, start_time, time, duration, comments, xact_seqno, current_delivery_rate, current_delivery_latency, delivered_transactions, delivered_commands, average_commands, delivery_rate, delivery_latency, total_delivered_commands, error_id, updateable_row
		from @distHistory

--Конфликты репликации
if object_id('tempdb..#conflicts') is not null
	drop table #conflicts
create table #conflicts
(
	db_name		sysname,
	publication	sysname
)
declare
	@database	sysname,
	@sql		varchar(8000)

declare curDb cursor local fast_forward for
select name
	from master.dbo.sysdatabases
	where databaseproperty(name, 'IsMergePublished') = 1
		and (status & 512) =0 -- Offline
		and (status & 1024) =0 -- ReadOnly
open curDb

while 1 = 1
begin
	fetch next from curDb into @database
	if @@fetch_status != 0
		break
	set @sql = 'use ' + quotename(@database) + ';
	if object_id(''dbo.MSmerge_conflicts_info'') is not null
	begin
		select distinct db_name(), p.name
			from dbo.MSmerge_conflicts_info c
			inner join dbo.sysmergepublications p on
				p.pubid = c.pubid
	end
	else if object_id(''dbo.MSmerge_delete_conflicts'') is not null
	begin
		select distinct db_name(), p.name
			from dbo.MSmerge_delete_conflicts c
			inner join dbo.sysmergepublications p on
				p.pubid = c.pubid
	end
'
	--print @sql
	insert into #conflicts(db_name, publication)
	exec (@sql)
end
close curDb
deallocate curDb

select Task = N'Конфликты репликации', db_name, publication from #conflicts

if object_id('tempdb..#conflicts') is not null
	drop table #conflicts



IF db_id('distribution') IS NOT NULL
BEGIN
SELECT @@servicename AS 'ServerName'
      ,a.[name]
      ,a.[publisher_db]
      ,[status]  =CASE
       WHEN h.[runstatus]=1 THEN 'Start'
       WHEN h.[runstatus]=2 THEN 'Succeed'
       WHEN h.[runstatus]=3 THEN 'In progress'
       WHEN h.[runstatus]=4 THEN 'Idle'
       WHEN h.[runstatus]=5 THEN 'Retry'
       WHEN h.[runstatus]=6 THEN 'Fail'
       END
      ,h.[time]
      ,e.[error_text]
      --,DATEDIFF(hh,GETDATE(),h.time)
      ,error_id
FROM [distribution].[dbo].[MSlogreader_agents] a with (nolock)
INNER JOIN [distribution].[dbo].[MSlogreader_history] h  with (nolock)
ON a.id=h.agent_id
LEFT JOIN [distribution].[dbo].[MSrepl_errors] e  with (nolock)
ON h.error_id=e.id
WHERE
h.runstatus in (5,6)
AND DATEDIFF(d,h.time,getdate()) <= 2 -- за последние 2 дня

END
