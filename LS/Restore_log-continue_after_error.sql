RESTORE LOG [svadba_c] 
FROM  DISK = N'\\asql01\LogShipping\svadba_c\svadba_c_20130730103000.trn'
--FROM  DISK = N'E:\Databases\tran_logs\SQL1\svadba_catalog\svadba_catalog_20110921043001.trn'
--FROM  DISK = N'E:\Databases\tran_logs\SQL1\svadba_catalog\svadba_catalog_20110921050004.trn'
--FROM  DISK = N'E:\Databases\tran_logs\SQL1\svadba_catalog\svadba_catalog_20110921053001.trn'
--FROM  DISK = N'E:\Databases\tran_logs\SQL1\svadba_catalog\svadba_catalog_20110921060001.trn'
--FROM  DISK = N'E:\Databases\tran_logs\SQL1\svadba_catalog\svadba_catalog_20110921063002.trn'
WITH  FILE = 1,continue_after_error,STANDBY = N'R:\SQL_Data\svadba_c\svadba_c.tuf',  NOUNLOAD,  STATS = 1
GO




   - 2433491000000472400001
430- 2433507000001415000001
500- 2433528000000345600001


SELECT TOP 10 * FROM msdb..backupset WHERE database_name='svadba_catalog' ORDER BY backup_start_date desc