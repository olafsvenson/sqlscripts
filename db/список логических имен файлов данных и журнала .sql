
-- список логических имен файлов данных и журнала 

SELECT DB_NAME(database_id)AS 'DatabaseName',name,physical_name FROM sys.master_files


USE master;

SELECT DISTINCT DatabaseName,Query='Alter Database [' +DatabaseName+'] set offline'
FROM (

SELECT DB_NAME(f.database_id)AS 'DatabaseName',
		d.state_desc,
		f.name,
		f.physical_name 
FROM sys.master_files f
	INNER JOIN sys.databases d
	ON f.database_id = d.database_id
WHERE f.physical_name LIKE 'G%' AND d.state_desc='offline' --AND f.name LIKE 'uat%'
)a

SELECT DB_NAME(database_id)AS 'DatabaseName',name,physical_name FROM sys.master_files WHERE database_id = DB_ID('svadba_catalog');
SELECT name,physical_name FROM sys.master_files WHERE database_id = DB_ID('livechat');

select db_id()

SELECT name,physical_name FROM sys.master_files WHERE database_id = DB_ID('tempdb')
SELECT name,physical_name FROM sys.master_files WHERE database_id = DB_ID('pegasus2008ms');
SELECT name,physical_name FROM sys.master_files WHERE database_id = DB_ID('tempdb');
SELECT name,physical_name FROM sys.master_files WHERE database_id = DB_ID('tmpdb');

SELECT name,physical_name FROM sys.master_files WHERE database_id = DB_ID('svadba_c');
SELECT name,physical_name FROM sys.master_files WHERE database_id = DB_ID('svadba_l');

SELECT name,physical_name FROM sys.master_files WHERE database_id = DB_ID('lovinga_catalog');
SELECT name,physical_name FROM sys.master_files WHERE database_id = DB_ID('trackingsystem');
SELECT name,physical_name FROM sys.master_files WHERE database_id = DB_ID('help-desk');
SELECT name,physical_name FROM sys.master_files WHERE database_id = DB_ID('svadba_c_archive');

SELECT name,physical_name FROM sys.master_files WHERE database_id = DB_ID('statforhd');
sp_who2

SELECT name,physical_name FROM sys.master_files WHERE physical_name like 'g:\%'


--ALTER DATABASE [tempdb] 
--MODIFY FILE (NAME = tempdev, FILENAME = 'e:\tempdb\tempdb.mdf');
--GO

--ALTER DATABASE [tempdb] 
--MODIFY FILE (NAME = templog, FILENAME = 'e:\tempdb\templog.ldf');

SELECT * FROM sys.master_files

SELECT name,physical_name FROM sys.master_files WHERE database_id = DB_ID('tempdb')


SELECT name,log_reuse_wait_desc
FROM sys.databases
WHERE database_id > 4 AND name='Pegasus2008MS'
ORDER BY name