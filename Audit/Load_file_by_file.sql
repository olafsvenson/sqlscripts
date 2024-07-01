use tempdb;
go


declare 
		@Folder sysname='D:\MSSQL\Audit'
		,@FilePattern nvarchar(256)=N'*.sqlaudit'
		,@FileName nvarchar(256)



-- имя аудита для загрузки
declare @AuditName sysname = 'AuditSettings'		

if object_id('AuditHistory') is null
	begin
		CREATE TABLE AuditHistory  (
			[event_time] [datetime2](7) NOT NULL,
			[sequence_number] [int] NOT NULL,
			[action_id] [varchar](4) NULL,
			[succeeded] [bit] NOT NULL,
			[permission_bitmask] [varbinary](16) NOT NULL,
			[is_column_permission] [bit] NOT NULL,
			[session_id] [smallint] NOT NULL,
			[server_principal_id] [int] NOT NULL,
			[database_principal_id] [int] NOT NULL,
			[target_server_principal_id] [int] NOT NULL,
			[target_database_principal_id] [int] NOT NULL,
			[object_id] [int] NOT NULL,
			[class_type] [varchar](2) NULL,
			[session_server_principal_name] [nvarchar](128) NULL,
			[server_principal_name] [nvarchar](128) NULL,
			[server_principal_sid] [varbinary](85) NULL,
			[database_principal_name] [nvarchar](128) NULL,
			[target_server_principal_name] [nvarchar](128) NULL,
			[target_server_principal_sid] [varbinary](85) NULL,
			[target_database_principal_name] [nvarchar](128) NULL,
			[server_instance_name] [nvarchar](128) NULL,
			[database_name] [nvarchar](128) NULL,
			[schema_name] [nvarchar](128) NULL,
			[object_name] [nvarchar](128) NULL,
			[statement] [nvarchar](4000) NULL,
			[additional_information] [nvarchar](4000) NULL,
			[file_name] [nvarchar](260) NOT NULL,
			[audit_file_offset] [bigint] NOT NULL,
			[user_defined_event_id] [smallint] NOT NULL,
			[user_defined_information] [nvarchar](4000) NULL,
			[audit_schema_version] [int] NOT NULL,
			[sequence_group_id] [varbinary](85) NULL,
			[transaction_id] [bigint] NOT NULL,
			[client_ip] [nvarchar](128) NULL,
			[application_name] [nvarchar](128) NULL,
			[duration_milliseconds] [bigint] NOT NULL,
			[response_rows] [bigint] NOT NULL,
			[affected_rows] [bigint] NOT NULL,
			[connection_id] [uniqueidentifier] NULL,
			[data_sensitivity_information] [nvarchar](4000) NULL,
			[host_name] [nvarchar](128) NULL
			);
		--	CREATE CLUSTERED INDEX CI_EventTime ON AuditHistory([event_time],[object_name]) with (data_compression = page);

end	


if object_id('AuditHistoryLog') is null
	begin
		CREATE TABLE AuditHistoryLog  (
		dt datetime default getdate(),
		log nvarchar(1024)
		);

		CREATE CLUSTERED INDEX CI_Dt ON AuditHistoryLog([dt]) with (data_compression = page);
	end

/*
SELECT *
FROM sys.dm_os_enumerate_filesystem(@Folder, @FilePattern ) fl
-- WHERE creation_time >= @LastRestoreEnd 
ORDER BY creation_time DESC
*/

insert into AuditHistoryLog(log) values (N'Начинаю загрузку ')

-- загружаем каждый файл по отдельности
declare curLoadFiles cursor for 
SELECT top 3 full_filesystem_path
FROM sys.dm_os_enumerate_filesystem(@Folder, @FilePattern ) fl
-- WHERE creation_time >= @LastRestoreEnd 
-- ORDER BY creation_time DESC


open curLoadFiles  
fetch next from curLoadFiles into @FileName  

while @@fetch_status = 0  
begin  


declare @StartTime datetime = getdate()

-- загружаем аудит (самый быстрый вариант)
insert into AuditHistory
SELECT *
FROM sys.fn_get_audit_file(@FileName, DEFAULT, DEFAULT)
--waitfor delay '00:00:02'

insert into AuditHistoryLog(log) values (N'Загрузка завершена: ' + @FileName + ' Длительность '+	RIGHT('0' + CAST(DATEDIFF(s, @StartTime, getdate()) / 3600 AS VARCHAR),2) + ':' +
	RIGHT('0' + CAST((DATEDIFF(s, @StartTime, getdate()) / 60) % 60 AS VARCHAR),2) + ':' +
	RIGHT('0' + CAST(DATEDIFF(s, @StartTime, getdate()) % 60 AS VARCHAR),2))

		
		fetch next from curLoadFiles into @FileName  
end 

close curLoadFiles  
deallocate curLoadFiles 

insert into AuditHistoryLog(log) values (N'Загрузка завершена')