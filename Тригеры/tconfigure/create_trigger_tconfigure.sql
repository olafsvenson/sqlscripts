USE [master]
GO

/****** Object:  DdlTrigger [tconfigure]    Script Date: 30.09.2021 11:23:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*
	Тригер на изменение конфигурации SQL Server (изменение параметров через sp_configure).
	Фиксирует все изменения параметров в таблице аудита в БД sputnik.
	Не работает ROLLBACK, т.к. судя по всему ALTER_INSTANCE работает вне этой транзакции.
	По умолчанию этот триггер должен быть включен.
*/
create trigger [tconfigure] on all server
with execute as 'sputnik_audit_writer'
for ALTER_INSTANCE
as
begin
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	declare @edata xml;
	--declare @ChangeState varchar(5);
	set @edata=EventData();
/*
	set @ChangeState='GRANT';
	--Запрещаем изменение настроек под sa!
	if @edata.value('(/EVENT_INSTANCE/LoginName)[1]', 'sysname') in ('sa','pecom\ivanov.an')
	begin
		set @ChangeState='DENY';
		ROLLBACK;
	end;
	else
*/
	--Аудит всех изменений в таблицу!!Кроме изменений параметра "show advanced options"
	if @edata.value('(/EVENT_INSTANCE/Parameters/Param)[1]','nvarchar(50)')<>'show advanced options'
		insert into sputnik.adt.jconfigure (tt, PName, PNewValue, POldValue, LoginName, spid, Host, HostName, Host_pid, ProgramName)
		values (
				@edata.value('(/EVENT_INSTANCE/PostTime)[1]', 'datetime2(3)'),
				@edata.value('(/EVENT_INSTANCE/Parameters/Param)[1]','nvarchar(50)'),
				@edata.value('(/EVENT_INSTANCE/Parameters/Param)[2]','int'),
				(select cast(value_in_use as int) from sys.configurations where name=@edata.value('(/EVENT_INSTANCE/Parameters/Param)[1]','nvarchar(50)')),
				@edata.value('(/EVENT_INSTANCE/LoginName)[1]', 'sysname'),
				@edata.value('(/EVENT_INSTANCE/SPID)[1]', 'smallint'),
				(select client_net_address from sys.dm_exec_connections where session_id=@edata.value('(/EVENT_INSTANCE/SPID)[1]', 'smallint')),
				HOST_NAME(), -- могут быть неточные данные, т.к. берутся из строки соединения!
				HOST_ID(),
				APP_NAME()
		);
	--if @ChangeState='DENY'
	--	RAISERROR(N'Запрещено изменять конфигурацию SQL Server под [sa]', 2, 1);
end

GO

ENABLE TRIGGER [tconfigure] ON ALL SERVER
GO


