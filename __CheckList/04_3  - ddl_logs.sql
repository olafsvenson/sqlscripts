use master

declare @exclusions table(ServerName varchar(50))
insert @exclusions values ('devdb')
insert @exclusions values ('devdb\rsnew')
insert @exclusions values ('ru02')
insert @exclusions values ('ru02\ru02')

declare @versionMajor int
declare @res varchar(50)
set @versionMajor = @@microsoftversion / 256 / 256 / 256
set @res = ''

if @versionMajor > 8 and not exists (select * from @exclusions where ServerName = @@servername) begin
	-- для sql2000 не смотрим логи. он не поддерживает триггеры DDL
	if not EXISTS (select * from information_schema.tables where table_name = 'ddl_log' and table_schema = 'dbo' and table_catalog = 'master') begin
		-- отсутствует таблица DDL-лога
		set @res = 'No DDL log table'
	end else if not exists(select * from sys.server_triggers where name = 'ddl_trig_server' and is_disabled = 0) begin
		-- отсутствует DDL триггер, сохраняющий логи DDL
		set @res = 'No DDL trigger or it is disabled'
	end
end

if @res = '' begin
	select top 0 ''
end else begin
	select @res
end

-- Последние 10 действий на серверах
--SELECT TOP 10 * FROM [master].[dbo].[ddl_log] dl WITH(nolock) WHERE dl.UTCDT>DateAdd(day,-1,GETUTCDATE()) AND dl.[Event]<>'UPDATE_STATISTICS' ORDER BY dl.UTCDT desc
