RETURN

SET ANSI_NULLS, QUOTED_IDENTIFIER ON;
GO

, ClientApp = CASE LEFT(Deadlock.Process.value('@clientapp', 'varchar(100)'), 29)
						WHEN 'SQLAgent - TSQL JobStep (Job '
							THEN 'SQLAgent Job: ' + (SELECT name FROM msdb..sysjobs sj WHERE substring(Deadlock.Process.value('@clientapp', 'varchar(100)'),32,32)=(substring(sys.fn_varbintohexstr(sj.job_id),3,100))) + ' - ' + SUBSTRING(Deadlock.Process.value('@clientapp', 'varchar(100)'), 67, len(Deadlock.Process.value('@clientapp', 'varchar(100)'))-67)
						ELSE Deadlock.Process.value('@clientapp', 'varchar(100)')
						END 

-- обнуление даты
DateAdd(day,0,DateDiff(day,0,dateofadded))

Server 'LinkToAceess' is not configured for DATA ACCESS.
--Solution is so simple; just enable your data access to linked server with following command.
exec sp_serveroption [LinkToAceess],'Data Access','true'

--“ак же замечу, что на том же int вместо IDENTITY(1,1) хорошей практикой €вл€етс€ использование IDENTITY(-2147483648, 1).

	RIGHT('0' + CAST(seconds / 3600 AS VARCHAR),2) + ':' +
	RIGHT('0' + CAST(seconds / 60 % 60 AS VARCHAR),2) + ':' +
	RIGHT('0' + CAST(seconds % 60 AS VARCHAR),2)

 --is not defined as a remote login at the server.
EXEC sp_addlinkedsrvlogin 'SQLSERVER2', 'true'

-OutputVerboseLevel 4 -Output C:\TEMP\mergeagent.log

--¬ соответствующем джобе, в командной строке запуска агента добавьте параметры: -OutputVerboseLebvel 2 -Output <файл> 

sp_configure "allow_updates", 1
reconfigure with override
go


--SQL Server blocked access to procedure 'sys.xp_cmdshell' of component 'xp_cmdshell' because this component is turned off as part of the security configuration for this server. A system administrator can enable the use of 'xp_cmdshell' by using sp_configure. For more information about enabling 'xp_cmdshell', see "Surface Area Configuration" in SQL Server Books Online.
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

EXEC sp_configure 'xp_cmdshell',1
GO
RECONFIGURE
GO


sp_configure 'in-doubt xact resolution',2
--Presume abort. Any MS DTC in-doubt transactions are presumed to have aborted.
Go

EXEC sp_configure 'show advanced options', 1
RECONFIGURE
GO
EXEC sp_configure 'ad hoc distributed queries', 1
RECONFIGURE
GO


     EXEC sp_configure 'remote admin connections', 1;
     GO
     RECONFIGURE
     GO

-----------

if object_id('tempdb..#tmp') is not null drop table #tmp

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[AW_SvadbaAdmin_SearchForActivation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[AW_SvadbaAdmin_SearchForActivation]
GO

DROP PROCEDURE IF EXISTS Sales.usp_OrderInfoTV
  GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[t2]') AND type in (N'U'))
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tblMen]') AND type in (N'U'))
DROP TABLE 
GO

if columnproperty(object_id('dbo.BlockedUsers'), 'DateOfAdded', 'ColumnId') is null

if indexproperty(object_id(N'dbo.v_PresentationEnabledClients'), N'IX_v_PresentationEnabledClients_ModifiedID', 'IndexID') is null

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[InstantNotifications].[Notifications]') AND name = N'IX_Notifications_UserID')

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Remove_TestClients_Charge')
EXEC msdb.dbo.sp_delete_job @job_name = N'Remove_TestClients_Charge', @delete_unused_schedule=1
GO


------------

-- Ќедел€ - сама€ крупна€ единица измерени€ времени с посто€нной продолжительностью. 
DECLARE @D DEC(15,0)=87959876579;
SELECT DATEADD(SECOND,@D%(7*24*3600),DATEADD(WEEK,ROUND(@D/(7*24*3600),0,1),GETDATE()));


WITH(NOEXPAND, NOLOCK)

sp_help 'tbl'
ALTER DATABASE [svadba_c] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO

DBCC SHRINKDATABASE (billing,30)

DBCC SHRINKFILE (calls_file,10)



--Are you sure that the statistics where up-to-date? This will make sure.    
DBCC updateusage ('sql911');
   go


exec sp_monitor

dbcc useroptions


-- Monitor the logs

DBCC SQLPERF(LOGSPACE) WITH no_infomsgs;
go


ALTER INDEX pk_sales_02 ON sales02
	rebuild WITH (online = ON);



-- Drop the vartext column & regain the space
/*
You can regain the disk space only if you drop one of the following:

    * varchar
    * nvarchar
    * varbinary
    * text
    * ntext
    * image
    * xml 
*/
ALTER TABLE sales02
DROP COLUMN vartext;
go

DBCC CLEANTABLE ('sql911','sales02',0);
Go





-- attach
CREATE DATABASE billing
ON (FILENAME='c:\billing_data.mdf')
FOR ATTACH
GO

-- присоединение только файла данных
CREATE DATABASE billing
ON (FILENAME='c:\billing_data.mdf')
FOR ATTACH_REBUILD_LOG
GO

ALTER DATABASE SET ONLINE
GO

ALTER DATABASE SET recovery simple
GO

BACKUP DATABASE [svadba_catalog] TO  DISK = N'nul' WITH NOFORMAT, NOINIT,  
NAME = N'svadba_catalog-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 1
GO
BACKUP LOG [svadba_catalog] TO  DISK = N'nul' WITH NOFORMAT, NOINIT,  NAME = N'svadba_catalog-Transaction Log  Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO

BACKUP DATABASE [livechat] TO  DISK = N'\\sql3\SQL_Backups\SQL3\large (full)\livechat\livechat_backup_2013_10_02_part1.bak',
DISK = N'M:\SQL3_Data\livechat_backup_2013_10_02_part2.bak'
 WITH NOFORMAT, 
NOINIT,  NAME = N'livechat_backup_2013_10_02_014421_7054276', SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 1
GO



RESTORE DATABASE [uppezsm_apatova] FROM DISK = N'\\sql3\SQL_Backups\SQL3\large (full)\livechat\livechat_backup_2013_10_02_part1.bak',
--DISK = N'\\SQL3\SQL3_Data\livechat_backup_2013_10_02_part2.bak' WITH  FILE = 1, 
/*
MOVE N'LiveChat_dat' TO N'E:\Databases\data\LiveCopy\livechat.mdf',  
MOVE N'livechat_log_2' TO N'E:\Databases\data\LiveCopy\livechat_2.ldf',  
MOVE N'livechat_Data_3' TO N'E:\Databases\data\LiveCopy\livechat_3.mdf',  
MOVE N'livechat_log_4' TO N'E:\Databases\data\LiveCopy\livechat_4.ldf', 
*/
STANDBY = N'F:\SQL_Data\livechat\livechat_standby.tuf',  NOUNLOAD,  REPLACE,  STATS = 1


-- восстановление Ћог шиппинга полсе добавлени€ нового файла
RESTORE LOG LogShipTest
FROM DISK = 'C:\LogShipCopy\LogShipTest_20130503075309.trn'
WITH
       STANDBY='C:\LogShipCopy\LogShipTest_RollbackUndo.bak',
       MOVE N'LogShipData2' TO N'C:\Program Files\Microsoft SQL Server\MSSQL11.SQL2012_LS2\MSSQL\DATA\LogShipData2.ndf';

-- перемещение файлов
ALTER DATABASE billing 
MODIFY FILE (NAME = Billing_data, FILENAME = 'c:\billing_data2.mdf');
GO

-- разрешени€ апредоставл€емые дл€ все объектов
select * from sys.fn_builtin_permissions(default)


-- проверка разрешени€ у текущего пользовател€
SELECT HAS_PERMS_BY_NAME(null,null,'VIEW SERVER STATE');

-- есть ли доступ к базе
select HAS_DBACCESS('billing');

-- дл€ каких таблиц тек Ѕƒ у тек польз есть разрешени€ SELECT
SELECT HAS_PERMS_BY_NAME(db_name(),'OBJECT','SELECT') as Have_Select,* from sys.tables;


--
exec sp_helplogins 'RESCUE\vint' 

-- 
GRANT CREATE DATABASE, CREATE TABLE TO [EWSCUE\VINT]

REVOKE CREATE TABLE TO [EWSCUE\VINT]
REVOKE INSERT, UPDATE, DELETE FROM [Rescue\vint]
DENY  INSERT, UPDATE, DELETE FROM [Rescue\vint]

EXEC sp_spaceused 'billing.lines'

EXEC sp_statistics ['billing.lines']

EXEC sp_helpdb

EXEC sp_helpindex t

EXEC sp_helpserver

EXEC sp_monitor

EXEC sp_spaceused
56
select * from sys.dm_tran_locks

select @@TOTAL_ERRORS

select DB_NAME(DbId),* from fn_virtualfilestats(null,null)


select * from sys.messages;

RESTORE DATABASE AdventureWorks2008R2
   FROM DISK = 'Z:\SQLServerBackups\AdventureWorks2008R2.bak'
   WITH FILE = 6
      NORECOVERY;
RESTORE DATABASE AdventureWorks2008R2
   FROM DISK = 'Z:\SQLServerBackups\AdventureWorks2008R2.bak'
   WITH FILE = 9
      RECOVERY;
 


EXEC sp_resolve_logins @dest_db='billing' @dest_path ='\\mir\data' @filename='syslogins.dat'

BEGIN TRANSACTION TRN1 WITH MARK 'sample mark' 


BACKUP DATABASE IOTest TO DISK = 'c:\iotest.bak';

BACKUP DATABASE IOTest TO DISK = 'c:\iotest.bak' WITH DIFFERENTAL;

BACKUP LOG IOTest TO DISK = 'c:\iotest_log.bak';

--Restore the full database backup 
RESTORE DATABASE AdventureWorks2008 FROM AdventureWorks2008Backup    
   WITH NORECOVERY;
--Restore the differential database backup 
RESTORE DATABASE AdventureWorks2008 FROM AdventureWorks2008Backup_diff    
   WITH NORECOVERY;
-- Restore the transaction logs with a STOPAT to restore to a point in time. 
RESTORE LOG AdventureWorks2008
   FROM AdventureWorks2008Log1
   WITH NORECOVERY, STOPAT = 'Nov 1, 2008 12:00 AM';
RESTORE LOG AdventureWorks2008
   FROM AdventureWorks2008Log2
   WITH RECOVERY, STOPAT = 'Nov 1, 2008 12:00 AM';
   

RESTORE LOG [svadba_a_archive]
	FROM DISK ='\\aw.local\IPTP_Backup\z\SQL_Backups\AMO2\TranLog\svadba_a_archive\svadba_a_archive_backup_2011_04_26_105756_9358149.trn'   
WITH NORECOVERY


RESTORE DATABASE []   FROM DISK = '\\it-online\backup\sql\SRV05\AMOHD\DB\help-desk\help-desk_backup_2011_08_14_030003_7097549.bak', NORECOVERY
RESTORE DATABASE []   FROM DISK = '	\\it-online\backup\sql\SRV05\AMOHD\TranLog\help-desk\help-desk_backup_2011_08_14_000003_0096391.trn	', NORECOVERY

RESTORE LOG [PayOnlineSystem] FROM DISK = 'H:\LogShiping\SQL2\PayOnlineSystem\PayOnlineSystem_20130322123001.trn' WITH  FILE = 1,
 MOVE N'PayOnlineSystem_NEW' TO N'e:\Databases\data\PayOnlineSystem\PayOnlineSystem_new.mdf',  
 MOVE N'PayOnlineSystem_log_NEW' TO N'e:\Databases\data\PayOnlineSystem\PayOnlineSystem_1_new.ldf',  
 STANDBY = 'E:\Databases\data\PayOnlineSystem\PayOnlineSystem.tuf'

	if @@error<>0
	begin
		rollback tran
		return
	end

begin tran

BEGIN TRY
COMMIT TRANSACTION
END TRY

BEGIN CATCH

			DECLARE
				@error_message	nvarchar(2048) = ERROR_MESSAGE()
			IF XACT_STATE() != 0
				ROLLBACK TRANSACTION
			
			--вернуть ошибку в приложение
			RAISERROR(@error_message, 16, 1)
				
		END CATCH
		
		
		
		
		
		
-- ”даление пачками
		
DELETE FROM [ваша таблица]
WHERE [ID] IN
(SELECT TOP 10000 * FROM [ваша таблица])


-- ¬ 2005

DELETE TOP (10000) 
FROM [ваша таблица] 



SELECT 1

WHILE @@ROWCOUNT > 0
	DELETE TOP (1000) [Table]
	WHERE ...
	
	
	
	
	declare
	 @retaindata varchar(17),
	 @retaindays tinyint,
	 @path varchar(100)

set @retaindays=1
select @retaindata=convert(varchar(17),getdate()-@retaindays,1)+' 00:00:00'
select @path='I:\BACKUP\Master'

exec master.dbo.xp_delete_file 0,@path,N'bak',@retaindata




--Estimated execution plan
SET SHOWPLAN_XML ON

--Actual plan
SET STATISTICS XML on


ALTER TABLE [NoNCompressed Table2]
REBUILD WITH (DATA_COMPRESSION = PAGE );

ALTER INDEX [NoNCompressed Table3_Cl_Idx] on [NoNCompressed Table3]
REBUILD WITH (DATA_COMPRESSION = PAGE );


CREATE NONCLUSTERED INDEX IX_SalesPerson_SalesQuota_SalesYTD
    ON Sales.SalesPerson (SalesQuota, SalesYTD);




	GRANT SHOWPLAN TO [a.rokhin]

-- проверка времени в maintenace plan

DATEPART("dw",@[System::StartTime]) == 7


SELECT @@SERVERNAME                 AS oldname,
       Serverproperty('Servername') AS actual_name


-- пермишены дл€ стандартных репортов

+ datareader на базу

use [master]
GO
GRANT VIEW ANY DEFINITION TO [SNH\pleykin]
GO
use [master]
GO
GRANT VIEW SERVER STATE TO  [SNH\pleykin]
GO


exec xp_logininfo 'sdk\zheltonogov', 'all'

Create Trigger prevent_filegrowth
ON ALL SERVER
FOR ALTER_DATABASE
AS

declare @SqlCommand nvarchar(max)
set @SqlCommand = ( SELECT EVENTDATA().value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]','nvarchar(max)') );

if( isnull(charindex('FILEGROWTH', @SqlCommand), 0) > 0 )
begin
RAISERROR ('FILEGROWTH property cannot be altered', 16, 1)
ROLLBACK
end
GO

while 1=1
begin
    delete top (1000) from [TBL] where a=1
    if @@rowcount = 0 break
    waitfor delay '00:00:01' -- € еще обычно добавл€ю задержку чтобы не грузить сильно сервер.
END

SET QUOTED_IDENTIFIER ON
go
USE Pegasus2008
go
DECLARE @SQL NVARCHAR(MAX)=
(
    SELECT 'UPDATE STATISTICS [' + table_schema + '].[' + table_name + '] with fullscan;'
    FROM INFORMATION_SCHEMA.VIEW_TABLE_USAGE
    WHERE View_NAME IN('ƒокумент.спо–ассылкаѕочты»—мс лиентамЌовый.–еквизитыѕолучател€', 
	'ƒокумент.спо–ассылкаѕочты»—мс лиентамЌовый', 
	'–егистр—ведений.∆урналќтправки—ћ—') FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'
);

--PRINT @SQL
EXEC sp_executesql @SQL;


SUBSTRING(replace(replace(stmt.stmt_details.value ('@StatementText', 'nvarchar(max)'), char(13), ' '), char(10), ' '), 1, 8000) 'Statement'

https://docs.microsoft.com/ru-ru/archive/blogs/martijnh/sql-serverhow-to-quickly-retrieve-accurate-row-count-for-table

powershell.exe -noprofile -executionpolicy bypass -file c:\ps\hello.ps1

--USE msdb ;  --GO  --EXEC dbo.sp_cycle_agent_errorlog ;  --GO  --EXEC sp_cycle_errorlog ;  --GO

-- запуск сервера пропуская upgrade скрипты
NET START MSSQLSERVER /T902

net start "SQL Server (MSSQLSERVER)" /m"Microsoft SQL Server Management Studio - Query"

https://sqlperformance.com/2020/09/locking/upsert-anti-pattern



IF DB_ID(@DatabaseName) IS NULL OR DATABASEPROPERTYEX(@DatabaseName, 'Updateability') <> 'READ_WRITE' OR DATABASEPROPERTYEX(@DatabaseName, 'Status') <> 'ONLINE'
	RAISERROR(N'Database "%s" is not found or not accessible or not writeable.', 16, 1, @DatabaseName);
	
	https://github.com/rudi-bruchez


	d:\MSSQL\Logs\AlwaysOn.Sync_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt