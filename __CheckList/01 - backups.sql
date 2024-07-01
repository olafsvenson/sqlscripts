-- Ищем БД, последний полный архив которых старше 8 дней
use msdb

declare @versionMajor int
declare @sql varchar(8000)
select @versionMajor = @@microsoftversion/256/256/256

if object_id('tempdb..#result') is not null drop table #result
create table #result
(
	name					sysname,
	type					varchar(100),
	backup_age				varchar(100),
	recovery_model			varchar(100),
	backup_start_date		datetime null,
	backup_finish_date		datetime null,
	backup_size				decimal(20,3),
	compressed_backup_size	decimal(20,3)
)

set @sql = '
select
	db.name,
	type = case bs.type
		when ''D'' then ''Full database''
		when ''I'' then ''Differential database''
		when ''L'' then ''Transaction Log''
		when ''F'' then ''File or filegroup''
		when ''G'' then ''Differential file''
		when ''P'' then ''Partial''
		when ''Q'' then ''Differential partial''
	end,
	backup_age = convert(varchar(10), datediff(hour, bs.backup_start_date, getdate())/24)+ '' days '' + convert(varchar(10), datediff(hour, bs.backup_start_date, getdate())%24) + '' hours'',
	{recovery_model},
	bs.backup_start_date,
	bs.backup_finish_date,
	backup_size = convert(decimal(20, 3), bs.backup_size/1024/1024),
	compressed_backup_size = convert(decimal(20, 3), bs.{compressed}backup_size/1024/1024)
from {from} db
left join
(
	select database_name, type, max_date = max(backup_start_date)
		from dbo.backupset
		group by database_name, type
) q on
	q.database_name = db.name
left join dbo.backupset bs on
	bs.database_name = db.name
	and bs.type = q.type
	and bs.backup_start_date = q.max_date
where
	(
		bs.database_name is null
		/*
		or backup_start_date <=
			 case bs.type
				when ''D'' then dateadd(day, -2, getdate())		--ВОТ ЗДЕСЬ И ВО ВТОРОЙ ВЕТКЕ МЕНЯЕМ КОЛ-ВО ДНЕЙ
			end
		*/		
	)
	{conditions}
order by db.name, type
'
if @versionMajor >= 10 begin
	-- Для SQL2008 и выше
	set @sql = replace(@sql, '{recovery_model}', 'bs.recovery_model')
	set @sql = replace(@sql, '{compressed}', 'compressed_')
	set @sql = replace(@sql, '{from}', 'sys.databases')
	set @sql = replace(@sql, '{conditions}',
		'and db.is_in_standby = 0
		and db.State <> 6 -- Offline
		and db.state_desc <> ''Restoring'' -- БД зеркало в мирроринге
	--	and db.is_read_only = 0	-- Только для чтения БД не архивируем'
	)
end else begin
	-- Для версий ниже 2008
	set @sql = replace(@sql, '{recovery_model}', 'N''unknown. old sql'' as recovery_model')
	set @sql = replace(@sql, '{compressed}', '')
	set @sql = replace(@sql, '{from}', 'master.dbo.sysdatabases')
	set @sql = replace(@sql, '{conditions}',
		'and (db.status & 512) = 0 -- Offline
		and (db.status & 1024) = 0 -- Только для чтения БД не архивируем'
	)
end
insert into #result exec (@sql)

select * from #result where name not in (
	'tempdb',
	'IISLogs',
	'IISLogs_AFR',
	'IISLogs_AMO',
	'IISLogs_OB'
)


--SELECT name