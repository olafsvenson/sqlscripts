sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'Database Mail XPs', 1;
GO
RECONFIGURE
GO

select @@SERVICENAME

USE [msdb]
GO

DECLARE @pid INT, @acctid INT, @email nvarchar(128), @machinename nvarchar(128)

set @machinename = convert(nvarchar(128),SERVERPROPERTY('MachineName'))

set @email = @machinename+'@sfn-am.ru'



EXEC msdb.dbo.sysmail_add_profile_sp
  @profile_name = 'DBA-Alerts',
  @profile_id = @pid OUTPUT;

EXEC msdb.dbo.sysmail_add_account_sp 
  @account_name = @machinename,
  @email_address = @email,
  @display_name = @machinename,
--  @replyto_address = 'DBAs@mycompany.com',
  @mailserver_name = 'mail.sfn-am.ru',
  @port = 26,
  @enable_ssl = 1,
  @account_id = @acctid OUTPUT;

EXEC msdb.dbo.sysmail_add_profileaccount_sp
  @profile_id = @pid,
  @account_id = @acctid, 
  @sequence_number = 1;
GO 

EXECUTE msdb.dbo.sysmail_add_principalprofile_sp  
    @profile_name = 'DBA-Alerts',  
    @principal_name = 'public',  
    @is_default = 1 ; 


EXEC msdb.dbo.sp_set_sqlagent_properties
   @email_save_in_sent_folder=1, 
   @databasemail_profile=N'DBA-Alerts', 
   @use_databasemail=1
GO

/*
EXEC xp_servicecontrol N'stop',N'SQLServerAGENT'
GO
WAITFOR DELAY '00:00:05'; 
go
EXEC xp_servicecontrol N'start',N'SQLServerAGENT'
GO
*/
/*
Service Started.
Msg 22003, Level 1, State 0
-- проверить что служба стартовала
*/
