declare @AlertSizeGB int; set @AlertSizeGB = 20 -- по старинке для sql2000
DECLARE @T TABLE (ServerName NVARCHAR(100),SIZE INT,DiskName  NVARCHAR(100))
-- Задаём размер в Гб.
INSERT INTO @T VALUES ('SQL1\SQL1',50,Null)
INSERT INTO @T VALUES ('SQL1\SQL1',50,'h:\System_DB\')
INSERT INTO @T VALUES ('SQL2\SQL2',100,Null)
INSERT INTO @T VALUES ('SQL2\SQL2',50,'I:\System_DB\')
INSERT INTO @T VALUES ('SQL3\SQL3',100,Null)
INSERT INTO @T VALUES ('SQL3\SQL3',50,'m:\System_DB\')
INSERT INTO @T VALUES ('SQL4\SQL4',80,Null)
INSERT INTO @T VALUES ('OB1\OB1',75,Null)
INSERT INTO @T VALUES ('OB2\OB2',75,Null)
INSERT INTO @T VALUES ('AMO1\AMO1',75,Null)
INSERT INTO @T VALUES ('AMO2\AMO2',75,Null)
INSERT INTO @T VALUES ('AMO1\AMO1',25,'i:\System_DB\')
INSERT INTO @T VALUES ('AMO2\AMO2',20,'J:\System_DB\')
INSERT INTO @T VALUES ('AF1\AF1',20,'M:\')	-- Системный диск с tempdb
INSERT INTO @T VALUES ('AF2\AF2',20,'N:\')	-- Системный диск с tempdb
INSERT INTO @T VALUES ('AF1\AF1',60,Null)
INSERT INTO @T VALUES ('AF2\AF2',60,Null)
INSERT INTO @T VALUES ('USA06\POS2',15,Null)
INSERT INTO @T VALUES ('SQLStat',80,Null) 
INSERT INTO @T VALUES ('SQLStat',20,'C:\')	-- Только диск C:
INSERT INTO @T VALUES ('SRV05\ADHD',40,Null) 
INSERT INTO @T VALUES ('SRV06',10,Null) 
INSERT INTO @T VALUES ('WebLVG',15,Null) 
INSERT INTO @T VALUES ('SQLArchive\Arch',50,Null) 
INSERT INTO @T VALUES ('AMOSTAT\SQLSTAT2',50,Null) 
INSERT INTO @T VALUES ('OBSTAT\SQLSTAT3',50,Null) 
/*
INSERT INTO @T VALUES ('DWH-ETL-U-01',10,'C:\')
INSERT INTO @T VALUES ('DWH-ETL-U-02',10,'C:\')
INSERT INTO @T VALUES ('sfn-dmart-i-01',10,'C:\')
INSERT INTO @T VALUES ('sfn-dmart-u-01',10,'C:\')
INSERT INTO @T VALUES ('sfn-dmart-u-02',10,'C:\')
INSERT INTO @T VALUES ('sql-i-01',10,'C:\')
INSERT INTO @T VALUES ('dwh-u-01',10,'C:\')
*/


use master

if object_id('tempdb..#Res') is not null drop table #Res
CREATE TABLE #Res (
	drive	nvarchar(100),
	MBFree	INT,
	AlertSizeGB int 
	)


if @@microsoftversion>=171051771	-- Больше чем 10.50.2811 2008R2 SP2
BEGIN
	if object_id('tempdb..#d') is not null drop table #d
	CREATE TABLE #D (dbid INT,DbName VARCHAR(250),Drive VARCHAR(500),MbFree int)

	-- Динамический код и varchar 4000, потому что SQL2000 не компилит запрос если есть CROSS APPLY
	-- Используем dm_os_volume_stats для того, чтобы видеть примонтированные диски
	DECLARE @SQLStr VARCHAR(4000)
	SET @SQLStr= 
		'SELECT dbid,DB_Name(dbid) AS DBName,volume_mount_point AS Drive,available_bytes/1024/1024 AS MbFree
		FROM master.dbo.sysaltfiles af
			CROSS APPLY sys.dm_os_volume_stats(af.dbid,af.fileid)
		WHERE DB_Name(dbid) IS NOT NULL
		'

	INSERT into #D	
		EXEC (@SQLStr)

/*
	SELECT dbid,DB_Name(dbid) AS 'DBName',volume_mount_point AS 'Drive',available_bytes/1024/1024 AS 'MbFree'
	INTO #d
	FROM master.dbo.sysaltfiles af
		CROSS APPLY sys.dm_os_volume_stats(af.dbid,af.fileid)
	WHERE DB_Name(dbid) IS NOT NULL
*/
	INSERT INTO #Res
	SELECT Cast(Drive AS VARCHAR(100)) AS 'Drive',Cast(MBFree AS INT) AS 'MBFree',isnull(IsNULL(t2.size,t.size), @AlertSizeGB) as 'AlertSizeGB' --,DBName
	FROM #D D
		LEFT JOIN @T AS t ON t.ServerName=@@SERVERNAME AND t.DiskName is NULL		-- Если не указан диск
		LEFT JOIN @T AS t2 ON t2.ServerName=@@SERVERNAME AND t2.DiskName=d.drive	-- Если указали точный диск
	where d.MbFree < IsNUll(IsNULL(t2.size,t.size), @AlertSizeGB) * 1000

END
ELSE BEGIN
     	
if object_id('tempdb..#fixedDrives') is not null
	drop table #fixedDrives

create table #fixedDrives
(
	drive	nvarchar(100),
	MBFree	int
)
insert into #fixedDrives
exec dbo.xp_fixeddrives

INSERT INTO #Res
select distinct d.*, isnull(IsNULL(t2.size,t.size), @AlertSizeGB) as AlertSizeGB--, db.name as DBName
from #fixedDrives d
	inner join sysaltfiles f
		on	f.filename like d.drive+':\%'
	inner join sysdatabases db
		ON db.dbid = f.dbid
	LEFT JOIN @T AS t ON t.ServerName = @@SERVERNAME AND t.DiskName is NULL		-- Если не указан диск
	LEFT JOIN @T AS t2 ON t2.ServerName = @@SERVERNAME AND t2.DiskName = d.drive+':\'	-- Если указали точный диск
where d.MBFree < IsNUll(IsNULL(t2.size,t.size), @AlertSizeGB) * 1000 -- Если не указан точный размер свободного пространства, то проверяем на значение по умолчанию 20 Gb

END

SELECT Distinct * FROM #Res
