declare @AlertSizeGB int; set @AlertSizeGB = 20 -- по старинке для sql2000
DECLARE @t TABLE (ServerName NVARCHAR(100),SIZE INT)
-- Задаём размер в Гб.
INSERT INTO @T VALUES ('SQL1\SQL1',100)
INSERT INTO @T VALUES ('SQL2\SQL2',100)
INSERT INTO @T VALUES ('SQL3\SQL3',100)
INSERT INTO @T VALUES ('SQL4\SQL4',80)
INSERT INTO @T VALUES ('OB1\OB1',75)
INSERT INTO @T VALUES ('OB2\OB2',75)
INSERT INTO @T VALUES ('AMO1\AMO1',75)
INSERT INTO @T VALUES ('AMO2\AMO2',75)
INSERT INTO @T VALUES ('AFR1\AFR1',50)
INSERT INTO @T VALUES ('AFR2\AFR2',50)
INSERT INTO @T VALUES ('USA06\POS2',15)
INSERT INTO @T VALUES ('SQLStat',100) 
INSERT INTO @T VALUES ('SRV05\ADHD',40) 
INSERT INTO @T VALUES ('SRV06',10) 
INSERT INTO @T VALUES ('WebLVG',15) 
INSERT INTO @T VALUES ('SQLArchive\Arch',50) 


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

select distinct d.*, isnull(t.size, @AlertSizeGB) as AlertSizeGB--, db.name as DBName
from #fixedDrives d
	inner join sysaltfiles f
		on	f.filename like d.drive+':%'
	inner join sysdatabases db
		ON db.dbid = f.dbid
	LEFT JOIN @t AS t
		ON t.ServerName=@@SERVERNAME  
where d.MBFree < IsNUll(t.SIZE, @AlertSizeGB) * 1000 -- Если не указан точный размер свободного пространства, то проверяем на значение по умолчанию 20 Gb
