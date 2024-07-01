-- =============================== «агрузка ====================================================
use tempdb;
go

-- им€ аудита дл€ загрузки
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
			CREATE CLUSTERED INDEX CI_EventTime ON AuditHistory([event_time],[object_name]) with (data_compression = page);

end	


		declare @AuditPath nvarchar(260), @MaxEventTime datetime2

		-- получаем пути дл€ указанного аудита
		select @AuditPath = log_file_path + '*.sqlaudit' from sys.server_file_audits where [name] = @AuditName
		
		-- получаем последнюю загруженную дату
		select @MaxEventTime = isnull(max(event_time),'2023-01-01') from AuditHistory
		
		-- загружаем аудит (самый быстрый вариант)
		insert into AuditHistory
		SELECT *
		FROM sys.fn_get_audit_file(@AuditPath, DEFAULT, DEFAULT)
		where event_time > @MaxEventTime
				--and action_id=N'DR'



		/*
		truncate table AuditHistory
		insert into AuditHistory
		SELECT *
		FROM sys.fn_get_audit_file('D:\MSSQL\Audit\AuditSettings_3CE52575-8BF2-44A5-89FD-CB45370C5E13_0_133487056204710000.sqlaudit', DEFAULT, DEFAULT)
		where 
				action_id=N'DR'


		SELECT event_time
	,action_id
	,session_server_principal_name AS UserName
	,server_instance_name
	,database_name
	,schema_name
	,object_name
	,statement
FROM sys.fn_get_audit_file('D:\TestAudits\*.sqlaudit', DEFAULT, DEFAULT)
WHERE action_id IN ( 'SL', 'IN', 'DR', 'LGIF' , '%AU%' )
The action_id = СSLТ shows SELECT statements executed, СINТ Ц inserts, СDRТ Ц dropped objects, СLGIFТ Ц failed logins, С%AU%Т Ц events related to the audit feature, and СUPТ Ц updates
		*/

		-- удал€ем старые данные
		--DELETE FROM AuditHistory WHERE [event_time] < DATEADD(day, -30, GETDATE());

	/*	
		select min([event_time]), max([event_time]) from AuditHistory

	 2023-08-30 10:50:30.4727113	2023-09-11 09:32:45.9116662
	 2023-08-30 10:50:30.4727113	2023-09-11 09:52:19.9759604
	 2023-08-30 10:50:30.4727113	2023-09-11 11:42:55.1785792
	 2023-08-30 10:50:30.4727113	2023-09-11 14:04:55.0290323
	 
	 */
-- ====================================================================================================================================
select top 200 * from AuditHistory 
where 
		[server_principal_name] = 'sfn\dchikirev'
		and len(statement) > 0
		and statement not like '%tcp/ip%'



select top 100 * from AuditHistory 
where
		len([object_name]) > 0


		select count(1)from AuditHistory 
		14 965 073

CREATE CLUSTERED INDEX CI_EventTime ON AuditHistory([event_time]) with (data_compression = page, drop_existing = on,maxdop=1);
CREATE  INDEX IX_object_name_statement_server_principal_name ON AuditHistory([object_name],[statement],[server_principal_name]) with (data_compression = page, maxdop=1);