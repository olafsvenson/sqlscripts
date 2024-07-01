USE msdb 
GO
EXEC dbo.sp_add_alert @name=N'Connection handshake failed Error: Sev 10', 
      @message_id=0, 
      @severity=10, 
      @enabled=1, 
      @delay_between_responses=120, 
      @include_event_description_in=1, 
      @event_description_keyword=N'Connection handshake failed'
GO
EXEC dbo.sp_add_alert @name=N'Connection handshake failed Error: Sev 16', 
      @message_id=0, 
      @severity=16, 
      @enabled=1, 
      @delay_between_responses=120, 
      @include_event_description_in=1, 
      @event_description_keyword=N'Connection handshake failed'
GO
EXEC dbo.sp_add_notification @alert_name=N'Connection handshake failed Error: Sev 10', @operator_name=N'SQLAlert', @notification_method = 1
GO 
EXEC dbo.sp_add_notification @alert_name=N'Connection handshake failed Error: Sev 16', @operator_name=N'SQLAlert', @notification_method = 1
GO   