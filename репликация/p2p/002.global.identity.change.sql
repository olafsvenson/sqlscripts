--скрипт проверки  identity таблиц из P2P-репликации
use master
go

set nocount on
go

declare
	@db_name	sysname,
	@sql		nvarchar(max)

declare @articles table
(
	db_name		sysname,
	object_name	sysname,
	object_id	INT,
	CurrentID	int
)

--получить все P2P-статьи всех БД
declare curDB cursor local fast_forward for
select name
from sys.databases

open curDB

fetch next from curDB into @db_name
while @@FETCH_STATUS = 0
begin
	set @sql = N'use ' + QUOTENAME(@db_name)+'
if object_id(''dbo.syspublications'') is not null
	select db_name(), Object_Name(a.objid), a.objid, IDENT_CURRENT(Object_Name(a.objid))
	from dbo.sysarticles a
		inner join dbo.syspublications p
			on p.pubid = a.pubid
	where p.options & 1 = 1
	  and a.Name NOT IN (''tblClients'', ''tblMen'')
	  and not exists (
		select 1 from sys.columns c
		where c.object_id = a.objid
		  and c.is_identity = 1
		  and c.system_type_id IN (48, 52)
		)'
	insert into @articles
	exec (@sql)
	
	fetch next from curDB into @db_name
end

SELECT * INTO #articles FROM @articles
--SELECT * FROM @articles
--SELECT * FROM #articles

SELECT 'use '+ [db_name] + ' ' + 'DBCC CHECKIDENT(''' + [object_name] + ''', RESEED, 1505000000)'
FROM #articles WHERE CurrentID < 1400000000

SELECT 'use '+ [db_name] + ' ' + 'DBCC CHECKIDENT(''' + [object_name] + ''', RESEED, ' + CONVERT(nvarchar, FLOOR(CurrentID * 1.05)) + ')'
FROM #articles WHERE CurrentID > 1400000000

drop table #articles
--Select IDENT_CURRENT('dbo.tblCLIENTS')