EXEC msdb.dbo.sp_add_operator @name=N'SQLAlert', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'vzheltonogov@sfn-am.ru', 
		@category_name=N'[Uncategorized]'
GO



-- Create SQL Server Alert for AlwaysOn Role Change
EXEC msdb.dbo.sp_add_alert
@name=N'AlwaysOn - Role Change',
@message_id=1480,
@severity=0,
@enabled=1,
@delay_between_responses=10,
@include_event_description_in=0,
@category_name=N'[Uncategorized]', 
@job_id=N'00000000-0000-0000-0000-000000000000'
GO

EXEC msdb.dbo.sp_add_notification @alert_name=N'AlwaysOn - Role Change', @operator_name=N'SQLAlert', @notification_method = 7;
GO

-- Create SQL Server Alert for AlwaysOn Data Movement Suspended
EXEC msdb.dbo.sp_add_alert
@name=N'AlwaysOn - Data Movement Suspended',
@message_id=35264,
@severity=0,
@enabled=1,
@delay_between_responses=0,
@include_event_description_in=0, 
@category_name=N'[Uncategorized]',
@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'AlwaysOn - Data Movement Suspended', @operator_name=N'SQLAlert', @notification_method = 7;
GO

-- Create SQL Server Alert for AlwaysOn Data Movement Resumed
EXEC msdb.dbo.sp_add_alert
@name=N'AlwaysOn - Data Movement Resumed',
@message_id=35265,
@severity=0,
@enabled=1,
@delay_between_responses=0,
@include_event_description_in=0,
@category_name=N'[Uncategorized]',
@job_id=N'00000000-0000-0000-0000-000000000000'
GO

EXEC msdb.dbo.sp_add_notification @alert_name=N'AlwaysOn - Data Movement Resumed', @operator_name=N'SQLAlert', @notification_method = 7;
GO