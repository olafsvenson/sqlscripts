-- Adding the transactional pull subscription

/****** Begin: Script to be run at Subscriber ******/
use [svadba]
exec sp_addpullsubscription @publisher = N'SQL1\SQL1', @publication = N'svadba_l_to_svadba(helpdesk)_new', @publisher_db = N'svadba_l', @independent_agent = N'True', @subscription_type = N'pull', @description = N'', @update_mode = N'read only', @immediate_sync = 0

exec sp_addpullsubscription_agent @publisher = N'SQL1\SQL1', @publisher_db = N'svadba_l', @publication = N'svadba_l_to_svadba(helpdesk)_new', @distributor = N'SQL1\SQL1', @distributor_security_mode = 0, @distributor_login = N'repladmin', @distributor_password = N'', @enabled_for_syncmgr = N'False', @frequency_type = 64, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 0, @frequency_subday = 4, @frequency_subday_interval = 5, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0, @alt_snapshot_folder = N'D:\', @working_directory = N'', @use_ftp = N'False', @job_login = null, @job_password = null, @publication_type = 0
GO
/****** End: Script to be run at Subscriber ******/

/****** Begin: Script to be run at Publisher ******/
/*use [svadba_l]
-- Parameter @sync_type is scripted as 'automatic', please adjust when appropriate.
exec sp_addsubscription @publication = N'svadba_l_to_svadba(helpdesk)_new', @subscriber = N'SRV05\ADHD', @destination_db = N'svadba', @sync_type = N'Automatic', @subscription_type = N'pull', @update_mode = N'read only'
*/
/****** End: Script to be run at Publisher ******/

