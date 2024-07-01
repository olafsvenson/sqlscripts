USE [msdb]
GO


-- SELECT * FROM dbo.sysjobs where name='SQLAlert-Long Transaction'


IF NOT EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Long Transaction Alert')
EXEC msdb.dbo.sp_add_alert @name=N'Long Transaction Alert', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=60, 
		@include_event_description_in=0, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'Transactions|Longest Transaction Running Time||>|15', 
		@job_name=N'Monitoring.ActiveQueries.Report'
GO




