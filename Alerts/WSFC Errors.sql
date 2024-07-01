USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'WSFC Error Number 41009', 
		@message_id=41009, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=0, 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'WSFC Error Number 41009', @operator_name=N'SQLAlert', @notification_method = 1
GO



USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'WSFC Error Number 19421', 
		@message_id=19421, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=0, 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'WSFC Error Number 19421', @operator_name=N'SQLAlert', @notification_method = 1
GO


USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'WSFC Error Number 19407', 
		@message_id=19407, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=0, 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'WSFC Error Number 19407', @operator_name=N'SQLAlert', @notification_method = 1
GO