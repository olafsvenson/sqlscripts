--скрипт изменения наименований хранимых процедур (чтобы не было числового суффикса)
--запускать на каждом сервере, участвующем в P2P-репликации
set nocount on
use master
declare
	@db_name	sysname,
	@sql		nvarchar(max)
declare @publications table
(
	db_name		sysname,
	publication	sysname,
	article		sysname
)

--получить все P2P-репликации всех БД
declare curDB cursor local fast_forward for
select name
from sys.databases
where is_published = 1

open curDB

fetch next from curDB into @db_name
while @@FETCH_STATUS = 0
begin
	set @sql = N'use ' + QUOTENAME(@db_name)+'
	if object_id(''dbo.syspublications'') is not null
	select db_name(), p.name, a.name
		from dbo.sysarticles a
		inner join dbo.syspublications p on p.pubid = a.pubid
		--P2P-публикации
		where p.options & 1 = 1'
	insert into @publications
	exec (@sql)
	
	fetch next from curDB into @db_name
end

--задать наименования
set @sql = ''
select @sql += 'use '+QUOTENAME(db_name) + '
exec sp_changearticle @publication = '''+publication +''', @article = '''+article + ''', @property = ''ins_cmd'', @value = ''CALL P2P_i_'+article+'''
exec sp_changearticle @publication = '''+publication +''', @article = '''+article + ''', @property = ''del_cmd'', @value = ''CALL P2P_d_'+article+'''
exec sp_changearticle @publication = '''+publication +''', @article = '''+article + ''', @property = ''upd_cmd'', @value = ''SCALL P2P_u_'+article+'''
'
	from @publications
--print @sql
exec (@sql)
go
