-- https://www.sqlshack.com/understanding-database-backup-encryption-sql-server/
return;
--(1) проверить наличие master key
use [master]
go
SELECT * FROM master.sys.symmetric_keys

/*
SELECT * FROM sys.certificates 
where [name] = 'BackupCert' 

SELECT * FROM sys.dm_database_encryption_keys WHERE encryption_state = 3;
*/
-- (2) Eсли нет, создать с нужным паролем
USE [master];
GO
-- create master key and certificate
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'EGOXRSN6xyz3nErKHtpb'; -- указываем пароль, сохраняем в парольнице как master key db
GO

-- (3) сохранить master key
BACKUP MASTER KEY TO FILE = '\\db-backups-p-01\tmp\master_1c-hf-sql.key'   
    ENCRYPTION BY PASSWORD = 'm6182Ia9viEdgvhOhPsF';  -- указываем пароль, сохраняем в парольнице как master key db file

/*
USE master;  
RESTORE MASTER KEY   
    FROM FILE = 'd:\MSSQL\Data\sql-d-01_master_key.key'   
    DECRYPTION BY PASSWORD = '!@Api1401@2015!!ddd'   -- пароль при сохранении в файл
    ENCRYPTION BY PASSWORD = '!@Api1401@2015!!dd';   -- пароль при создании
GO 
*/
/*
select @@servername
select CHARINDEX('\',@@servername)
select left(@@servername,CHARINDEX('\',@@servername)-1);
*/

-- (4) Создать сертификат для бекапов
CREATE CERTIFICATE [BackupCert]
    WITH SUBJECT = 'Certificate for backups';
GO

-- (5) Сохранить сертификат для беапов в файл (на выходе 2 файла: сертификат и ключ)
-- export the backup certificate to a file
BACKUP CERTIFICATE [BackupCert] TO FILE = '\\db-backups-p-01\tmp\BackupCert_1c-hf-sql.cert'
WITH PRIVATE KEY (
FILE = '\\db-backups-p-01\tmp\BackupCert_1c-hf-sql.key',
ENCRYPTION BY PASSWORD = 'K8yTslpXzZRCOILdzfVo')


-- backup the database with encryption
BACKUP DATABASE DBATest_d
TO DISK = 'd:\MSSQL\Backup\DBATest_D_Encrypted.bak'
WITH ENCRYPTION (ALGORITHM = AES_256, SERVER CERTIFICATE =  [BackupCert_sql-d-01])

USE master;
GO
BACKUP LOG SQLShack
TO DISK = 'g:\Program Files\SQLShackTailLogDB.log'
WITH CONTINUE_AFTER_ERROR,ENCRYPTION (ALGORITHM = AES_256, SERVER CERTIFICATE = SQLShackDBCert)

 
  
-- clean up the instance
 
DROP DATABASE DBATest
GO
DROP CERTIFICATE [BackupCert_from_sql-01];
GO
DROP MASTER KEY;
GO
 



-- recreate master key and certificate
 
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '!@Api1401@2015!!pp';
GO


/*
USE AdventureWorks2022;  
RESTORE MASTER KEY   
    FROM FILE = 'c:\backups\keys\AdventureWorks2022_master_key'   
    DECRYPTION BY PASSWORD = '3dH85Hhk003#GHkf02597gheij04'   
    ENCRYPTION BY PASSWORD = '259087M#MyjkFkjhywiyedfgGDFD';  
GO 
*/


'1c-sql',+
'1c-sql-02',+
'sfn-etl-p-01',+
'sfn-dmart-p-01',+
'sfn-dmart-p-02',+
'lk-dmart-p-01,54831',+
'lk-dmart-p-02,54831',+
'sql-01',+
sql-p-02+
'dwh-p-01',
'dwh-p-02'

nNszMTSRZ6RuS0lFmRhs


-- restore the certificate
CREATE CERTIFICATE [BackupCert_from_1c-sql]
FROM FILE = 'd:\mssql\BackupCert_1c-sql.cert'
WITH PRIVATE KEY (FILE = 'd:\mssql\BackupCert_1c-sql.key',
DECRYPTION BY PASSWORD = 'nNszMTSRZ6RuS0lFmRhs');
GO

CREATE CERTIFICATE [BackupCert_from_1c-sql-02]
FROM FILE = 'd:\mssql\BackupCert_1c-sql-02.cert'
WITH PRIVATE KEY (FILE = 'd:\mssql\BackupCert_1c-sql-02.key',
DECRYPTION BY PASSWORD = 'nzwGflNErOt6mtYOjHwU');
GO


CREATE CERTIFICATE [BackupCert_from_sql-p-02]
FROM FILE = 'd:\mssql\BackupCert_sql-p-02.cert'
WITH PRIVATE KEY (FILE = 'd:\mssql\BackupCert_sql-p-02.key',
DECRYPTION BY PASSWORD = 'V0LHBzQ4MsZGVrP38K6Z');
GO

CREATE CERTIFICATE [BackupCert_from_1c-sql-03]
FROM FILE = 'd:\mssql\BackupCert_1c-sql-03.cert'
WITH PRIVATE KEY (FILE = 'd:\mssql\BackupCert_1c-sql-03.key',
DECRYPTION BY PASSWORD = 'fFta67jFDeEWo0MFGlZi');
GO

SELECT * FROM sys.certificates