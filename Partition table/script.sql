return


USE master;
GO




IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'PartDb')
DROP DATABASE [PartDb]
GO

/*

CREATE DATABASE [PartDb]
ON 
( NAME = PartDb_dat,
    FILENAME = 'C:\vint\DB\PartDb.mdf',
    SIZE = 5,
    MAXSIZE = 50,
    FILEGROWTH = 5 )
LOG ON
( NAME = PartDb_log,
    FILENAME = 'C:\vint\DB\PartDb.ldf',
    SIZE = 1MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB ) ;
GO
*/


-- на devdb-2k8\web03
CREATE DATABASE [PartDb] ON  PRIMARY 
( NAME = N'PartDb', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10_50.WEB03\MSSQL\DATA\PartDb.mdf' , SIZE = 2048KB , FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'PartDb_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10_50.WEB03\MSSQL\DATA\PartDb_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10%)
GO

use [PartDB]
Go

/* Добавление файловых групп

ALTER DATABASE AdventureWorksDW ADD FILEGROUP [Filegroup_2001] 
GO 
ALTER DATABASE AdventureWorksDW ADD FILEGROUP [Filegroup_2002] 
GO 
ALTER DATABASE AdventureWorksDW ADD FILEGROUP [Filegroup_2003] 
GO 
ALTER DATABASE AdventureWorksDW ADD FILEGROUP [Filegroup_2004] 
GO

*/

/* Добавление файлов в файловую группу
ALTER DATABASE AdventureWorksDW
  ADD FILE
  (NAME = N'data_2001',
  FILENAME = N'C:\mssql2005\data\data_2001.ndf',
  SIZE = 5000MB,
  MAXSIZE = 10000MB,
  FILEGROWTH = 500MB)
  TO FILEGROUP [Filegroup_2001] 
GO 
ALTER DATABASE AdventureWorksDW
  ADD FILE
  (NAME = N'data_2002',
  FILENAME = N'D:\mssql2005\data\data_2002.ndf',
  SIZE = 5000MB,
  MAXSIZE = 10000MB,
  FILEGROWTH = 500MB)
  TO FILEGROUP [Filegroup_2002]
GO 
ALTER DATABASE AdventureWorksDW
  ADD FILE
  (NAME = N'data_2003',   
  FILENAME = N'E:\mssql2005\data\data_2003.ndf',   
  SIZE = 5000MB,   
  MAXSIZE = 10000MB,   
  FILEGROWTH = 500MB) 
  TO FILEGROUP [Filegroup_2003] 
GO 
ALTER DATABASE AdventureWorksDW
  ADD FILE 
  (NAME = N'data_2004',
  FILENAME = N'F:\mssql2005\data\data_2004.ndf',
  SIZE = 5000MB,
  MAXSIZE = 10000MB,
  FILEGROWTH = 500MB)
  TO FILEGROUP [Filegroup_2004]
GO
*/




/****** Object:  Table [dbo].[PartTable]    Script Date: 03/04/2011 15:23:31 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PartTable]') AND type in (N'U'))
DROP TABLE [dbo].[PartTable]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NonPartTable]') AND type in (N'U'))
DROP TABLE [dbo].[NonPartTable]
GO

/****** Object:  PartitionScheme [PartTablePScheme]    Script Date: 03/04/2011 16:03:53 ******/
IF  EXISTS (SELECT * FROM sys.partition_schemes WHERE name = N'PartTablePScheme')
DROP PARTITION SCHEME [PartTablePScheme]
GO

/****** Object:  PartitionFunction [PartDbRange]    Script Date: 03/04/2011 16:03:39 ******/
IF  EXISTS (SELECT * FROM sys.partition_functions WHERE name = N'PartDbRangePfn')
DROP PARTITION FUNCTION [PartDbRangePfn]
GO




CREATE PARTITION FUNCTION [PartDbRangePfn](datetime) 
AS RANGE right
FOR VALUES (N'2011-02-01 00:00:00', N'2011-03-01 00:00:00', 
N'2011-04-01 00:00:00', N'2011-05-01 00:00:00');


CREATE PARTITION SCHEME [PartTablePScheme] 
AS PARTITION [PartDbRangePfn] 
--TO ( [Primary], [Primary], [Primary], [Primary], [Primary])
ALL TO ([PRIMARY])


USE [PartDb]
GO



-- создаем таблицу секционированную таблицу
create table PartTable (
	[id] int identity(1,1) not null,
	[DateOfInsert] datetime not null,
	[data] int 
) ON PartTablePScheme(DateOfInsert)

create table NonPartTable (
	[id] int identity(1,1) not null,
	[DateOfInsert] datetime not null,
	[data] int 
)

CREATE CLUSTERED INDEX PartTableIndx
ON PartTable(DateOfInsert) ON PartTablePScheme(DateOfInsert);


CREATE CLUSTERED INDEX NonPartTableIndx ON NonPartTable(DateOfInsert);


--  AND [DateofInsert] IS NOT null

ALTER  TABLE [NonPartTable]  WITH CHECK  
ADD CONSTRAINT [CK_NonPartTable_DateOfInsert] CHECK  ([DateOfInsert]>=('2011-04-01 00:00:00') AND [DateOfInsert]<('2011-05-01 00:00:00') ) 


--ALTER  TABLE [DBO].[SalesOrderHeaderOLD]  WITH CHECK  ADD CONSTRAINT [CK_SalesOrderHeaderOLD_ORDERDATE] CHECK  ([ORDERDATE]>=('2003-01-01 00:00:00') AND [ORDERDATE]<('2004-01-01 00:00:00'));

/*
-- если таблица уже существует
ALTER TABLE PartTable
ADD CONSTRAINT PartTablePK
   PRIMARY KEY CLUSTERED (DateOfInsert, ID)
  ON PartTablePScheme(DateOfInsert)
GO
*/


--truncate table PartTable

DECLARE @StartTime datetime = cast('2011-01-01 01:00:00' as datetime)
DECLARE @EndTime datetime = cast('2011-05-30 00:00:00' as datetime)




declare @CurTime datetime = @StartTime


 
 
while (@CurTime <= @EndTime)
begin
	--print 'iter'
	
	insert into PartTable(DateOfInsert,data) values(@CurTime,1)
	
	
	
	SET @CurTime=dateadd(dd,1,@CurTime)
end




-- Добавить разбивку
ALTER PARTITION SCHEME PartTablePScheme NEXT USED [Primary];
ALTER PARTITION FUNCTION PartDbRangePfn() SPLIT RANGE ('2011-02-01 00:00:00');



-- Удалить
ALTER PARTITION FUNCTION PartDbRangePfn() MERGE RANGE ('2011-02-01 00:00:00');



-- просмотр
SELECT *, $Partition.PartDbRangePfn(DateOfInsert) AS [Partition] FROM [PartTable] ORDER BY [Partition]


SELECT * FROM sys.partitions WHERE OBJECT_ID = OBJECT_ID('PartTable')


SELECT  $partition.PartDbRangePfn('2011-05-29')


-- Switch the data from partition 4 into the SalesOrderHeaderOLD table
ALTER TABLE PartTable SWITCH PARTITION 4 TO NonPartTable;


-- Switch the data from SalesOrderHeaderOLD back to partition 4
ALTER TABLE NonPartTable SWITCH TO PartTable PARTITION 4; 


truncate table NonPartTable

select * from NonPartTable
select * from PartTable

--([DateOfInsert]>='2011-05-01 01:00:00' AND [DateOfInsert]<='2011-05-30 00:00:00')
insert into NonPartTable values('2011-05-01 01:00:00.000',2)