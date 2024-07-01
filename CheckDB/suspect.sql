-- 1-ый вариант

use master
go
sp_configure 'allow updates',1
go
reconfigure with override
go
--Для сброса признака suspect выполняем в БД master ХП sp_resetstatus:
sp_resetstatus 'livechat' --deprecated use alter database instead
go
--А теперь запретим прямое изменение системных таблиц:
sp_configure 'allow updates',0
go
reconfigure with override
go 

sp_resetstatus 'Pegasus2008'  
-- 2-ой 

ALTER dat


ALTER DATABASE [Pegasus2008] SET EMERGENCY
ALTER DATABASE [Pegasus2008] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DBCC CHECKDB ('Pegasus2008', REPAIR_ALLOW_DATA_LOSS)
ALTER DATABASE [Pegasus2008] SET MULTI_USER





alter database [DataBaseName] set emergency


SELECT * FROM sys.databases as d where name='livechat'


EXEC sp_resetstatus 'AMO_TrackingSystem'

ALTER DATABASE AMO_TrackingSystem SET EMERGENCY
DBCC checkdb('livechat')
ALTER DATABASE livechat SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DBCC CheckDB ('livechat', REPAIR_ALLOW_DATA_LOSS)
ALTER DATABASE livechat SET multi_user WITH ROLLBACK IMMEDIATE
ALTER DATABASE livechat set online

ALTER DATABASE AMO_TrackingSystem  set offline WITH ROLLBACK IMMEDIATE
ALTER DATABASE AMO_TrackingSystem  set online
ALTER DATABASE svadba_catalog SET EMERGENCY
DBCC checkdb('svadba_catalog')

ALTER DATABASE svadba_catalog SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DBCC CheckDB ('svadba_catalog', REPAIR_ALLOW_DATA_LOSS)

ALTER DATABASE svadba_catalog SET MULTI_USER wITH ROLLBACK immediate

ALTER DATABASE TrackingSystem  set offline WITH ROLLBACK IMMEDIATE
ALTER DATABASE TrackingSystem  set ONLINE




