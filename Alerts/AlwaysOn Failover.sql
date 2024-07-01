USE [msdb]
GO

/****** Object:  Alert [AlwaysOn Failover]    Script Date: 08.11.2023 11:26:06 ******/
EXEC msdb.dbo.sp_add_alert @name=N'AlwaysOn Failover', 
		@message_id=19406, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=0, 
		@event_description_keyword=N'has changed from ''PRIMARY_PENDING'' to ''PRIMARY_NORMAL''', 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO



EXEC msdb.dbo.sp_add_notification @alert_name=N'AlwaysOn Failover', @operator_name=N'SQLAlert', @notification_method = 7;
GO