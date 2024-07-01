use [AINotification]

exec sp_addsubscription @publication = N'AINotification_P2P', @subscriber = N'rafr1\rafr1', @destination_db = N'AINotification', 
@subscription_type = N'Push', @sync_type = N'initialize with backup', @article = N'all', @update_mode = N'read only', @backupdevicetype = 'disk',
@backupdevicename = '', @subscriber_type = 0
GO

exec sp_addpushsubscription_agent @publication = N'AINotification_P2P', @subscriber = N'rafr1\rafr1', @subscriber_db = N'AINotification', 
@job_login = null, @job_password = null, @subscriber_security_mode = 0, @subscriber_login = N'repladmin', @subscriber_password = '654321', 
@frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, 
@frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20110202, @active_end_date = 99991231,
@enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO

------------------------------------------------------------------------------------------------------------------------------------------------
use [anastasiadb_tours]

exec sp_addsubscription @publication = N'anastasiadb_tours_P2P', @subscriber = N'rafr1\rafr1', @destination_db = N'anastasiadb_tours', 
@subscription_type = N'Push', @sync_type = N'initialize with backup', @article = N'all', @update_mode = N'read only', @backupdevicetype = 'disk',
@backupdevicename = '', @subscriber_type = 0
GO

exec sp_addpushsubscription_agent @publication = N'anastasiadb_tours_P2P', @subscriber = N'rafr1\rafr1', @subscriber_db = N'anastasiadb_tours', 
@job_login = null, @job_password = null, @subscriber_security_mode = 0, @subscriber_login = N'repladmin', @subscriber_password = '654321', 
@frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, 
@frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20110202, @active_end_date = 99991231,
@enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO

------------------------------------------------------------------------------------------------------------------------------------------------
use [help-desk]

exec sp_addsubscription @publication = N'help-desk_P2P', @subscriber = N'rafr1\rafr1', @destination_db = N'help-desk', 
@subscription_type = N'Push', @sync_type = N'initialize with backup', @article = N'all', @update_mode = N'read only', @backupdevicetype = 'disk',
@backupdevicename = '', @subscriber_type = 0
GO

exec sp_addpushsubscription_agent @publication = N'help-desk_P2P', @subscriber = N'rafr1\rafr1', @subscriber_db = N'help-desk', 
@job_login = null, @job_password = null, @subscriber_security_mode = 0, @subscriber_login = N'repladmin', @subscriber_password = '654321', 
@frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, 
@frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20110202, 
@active_end_date = 99991231, @enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO

------------------------------------------------------------------------------------------------------------------------------------------------
use [livechat]

exec sp_addsubscription @publication = N'livechat_P2P', @subscriber = N'rafr1\rafr1', @destination_db = N'livechat', 
@subscription_type = N'Push', @sync_type = N'initialize with backup', @article = N'all', @update_mode = N'read only', @backupdevicetype = 'disk',
@backupdevicename = '', @subscriber_type = 0
GO

exec sp_addpushsubscription_agent @publication = N'livechat_P2P', @subscriber = N'rafr1\rafr1', @subscriber_db = N'livechat', 
@job_login = null, @job_password = null, @subscriber_security_mode = 0, @subscriber_login = N'repladmin', @subscriber_password = '654321', 
@frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, 
@frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20110202, 
@active_end_date = 99991231, @enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO

------------------------------------------------------------------------------------------------------------------------------------------------
use [paymentsystem]

exec sp_addsubscription @publication = N'paymentsystem_P2P', @subscriber = N'rafr1\rafr1', @destination_db = N'paymentsystem', 
@subscription_type = N'Push', @sync_type = N'initialize with backup', @article = N'all', @update_mode = N'read only', @backupdevicetype = 'disk',
@backupdevicename = '', @subscriber_type = 0
GO

exec sp_addpushsubscription_agent @publication = N'paymentsystem_P2P', @subscriber = N'rafr1\rafr1', @subscriber_db = N'paymentsystem', 
@job_login = null, @job_password = null, @subscriber_security_mode = 0, @subscriber_login = N'repladmin', @subscriber_password = '654321', 
@frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, 
@frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20110202, 
@active_end_date = 99991231, @enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO

------------------------------------------------------------------------------------------------------------------------------------------------
use [phoneintroduction]

exec sp_addsubscription @publication = N'phoneintroduction_P2P', @subscriber = N'rafr1\rafr1', @destination_db = N'phoneintroduction', 
@subscription_type = N'Push', @sync_type = N'initialize with backup', @article = N'all', @update_mode = N'read only', @backupdevicetype = 'disk',
@backupdevicename = '', @subscriber_type = 0
GO

exec sp_addpushsubscription_agent @publication = N'phoneintroduction_P2P', @subscriber = N'rafr1\rafr1', @subscriber_db = N'phoneintroduction', 
@job_login = null, @job_password = null, @subscriber_security_mode = 0, @subscriber_login = N'repladmin', @subscriber_password = '654321', 
@frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, 
@frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20110202, 
@active_end_date = 99991231, @enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO

------------------------------------------------------------------------------------------------------------------------------------------------
use [svadba_a]

exec sp_addsubscription @publication = N'svadba_a_P2P', @subscriber = N'rafr1\rafr1', @destination_db = N'svadba_a', 
@subscription_type = N'Push', @sync_type = N'initialize with backup', @article = N'all', @update_mode = N'read only', @backupdevicetype = 'disk',
@backupdevicename = '', @subscriber_type = 0
GO

exec sp_addpushsubscription_agent @publication = N'svadba_a_P2P', @subscriber = N'rafr1\rafr1', @subscriber_db = N'svadba_a', 
@job_login = null, @job_password = null, @subscriber_security_mode = 0, @subscriber_login = N'repladmin', @subscriber_password = '654321', 
@frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, 
@frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20110202, 
@active_end_date = 99991231, @enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO

------------------------------------------------------------------------------------------------------------------------------------------------
use [svadba_catalog]

exec sp_addsubscription @publication = N'svadba_catalog_P2P', @subscriber = N'rafr1\rafr1', @destination_db = N'svadba_catalog', 
@subscription_type = N'Push', @sync_type = N'initialize with backup', @article = N'all', @update_mode = N'read only', @backupdevicetype = 'disk',
@backupdevicename = '', @subscriber_type = 0
GO

exec sp_addpushsubscription_agent @publication = N'svadba_catalog_P2P', @subscriber = N'rafr1\rafr1', @subscriber_db = N'svadba_catalog', 
@job_login = null, @job_password = null, @subscriber_security_mode = 0, @subscriber_login = N'repladmin', @subscriber_password = '654321', 
@frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, 
@frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20110202, 
@active_end_date = 99991231, @enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO

------------------------------------------------------------------------------------------------------------------------------------------------
use [svadba_l]

exec sp_addsubscription @publication = N'svadba_l_P2P', @subscriber = N'rafr1\rafr1', @destination_db = N'svadba_l', 
@subscription_type = N'Push', @sync_type = N'initialize with backup', @article = N'all', @update_mode = N'read only', @backupdevicetype = 'disk',
@backupdevicename = '', @subscriber_type = 0
GO

exec sp_addpushsubscription_agent @publication = N'svadba_l_P2P', @subscriber = N'rafr1\rafr1', @subscriber_db = N'svadba_l', 
@job_login = null, @job_password = null, @subscriber_security_mode = 0, @subscriber_login = N'repladmin', @subscriber_password = '654321', 
@frequency_type = 64, @frequency_interval = 0, @frequency_relative_interval = 0, @frequency_recurrence_factor = 0, @frequency_subday = 0, 
@frequency_subday_interval = 0, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20110202, 
@active_end_date = 99991231, @enabled_for_syncmgr = N'False', @dts_package_location = N'Distributor'
GO

------------------------------------------------------------------------------------------------------------------------------------------------