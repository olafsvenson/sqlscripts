declare @AlertSizeGB int; set @AlertSizeGB = 20 -- по старинке для sql2000
DECLARE @t TABLE (ServerName NVARCHAR(100),SIZE INT,DiskName  NVARCHAR(10))
-- Задаём размер в Гб.
INSERT INTO @T VALUES ('SQL1\SQL1',100,Null)
INSERT INTO @T VALUES ('SQL2\SQL2',100,Null)
INSERT INTO @T VALUES ('SQL3\SQL3',100,Null)
INSERT INTO @T VALUES ('SQL4\SQL4',80,Null)
INSERT INTO @T VALUES ('OB1\OB1',75,Null)
INSERT INTO @T VALUES ('OB2\OB2',75,Null)
INSERT INTO @T VALUES ('AMO1\AMO1',75,Null)
INSERT INTO @T VALUES ('AMO2\AMO2',75,Null)
INSERT INTO @T VALUES ('AF1\AF1',20,'M')
INSERT INTO @T VALUES ('AF2\AF2',20,'N')
INSERT INTO @T VALUES ('AF1\AF1',60,Null)
INSERT INTO @T VALUES ('AF2\AF2',60,NUll)
INSERT INTO @T VALUES ('USA06\POS2',15,Null)
INSERT INTO @T VALUES ('SQLStat',80,Null) 
INSERT INTO @T VALUES ('SQLStat',40,'C')	-- Только диск C:
INSERT INTO @T VALUES ('SRV05\ADHD',40,Null) 
INSERT INTO @T VALUES ('SRV06',10,Null) 
INSERT INTO @T VALUES ('WebLVG',15,Null) 
INSERT INTO @T VALUES ('SQLArchive\Arch',50,Null) 
INSERT INTO @T VALUES ('AMOSTAT\SQLSTAT2',50,Null) 
INSERT INTO @T VALUES ('OBSTAT\SQLSTAT3',50,Null) 

use master
if object_id('tempdb..#fixedDrives') is not null
	drop table #fixedDrives
create table #fixedDrives
(
	drive	char(1),
	MBFree	int
)
insert into #fixedDrives
exec dbo.xp_fixeddrives


select distinct d.*, isnull(IsNULL(t2.size,t.size), @AlertSizeGB),t2.size,t.size as AlertSizeGB--, db.name as DBName
from #fixedDrives d
	inner join sysaltfiles f
		on	f.filename like d.drive+':%'
	inner join sysdatabases db
		ON db.dbid = f.dbid
	LEFT JOIN @t AS t ON t.ServerName=@@SERVERNAME AND t.DiskName is NULL		-- Если не указан диск
	LEFT JOIN @t AS t2 ON t2.ServerName=@@SERVERNAME AND t2.DiskName=d.drive	-- Если указали точный диск
where d.MBFree < IsNUll(IsNULL(t2.size,t.size), @AlertSizeGB) * 1000 -- Если не указан точный размер свободного пространства, то проверяем на значение по умолчанию 20 Gb



