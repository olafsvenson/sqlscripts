RETURN

E:\DATA\TempDB\

use master


SELECT name,physical_name FROM sys.master_files WHERE database_id = DB_ID('tempdb')

alter database tempdb
modify file(
name = tempdev,
filename = N'd:\mssql\tempdb\tempdb.mdf')
go

alter database tempdb
modify file(
name = templog,
filename = N'd:\mssql\tempdb\tempdb.ldf')
go


alter database tempdb
modify file(
name = temp2,
filename = N'd:\mssql\tempdb\tempdb_mssql_2.ndf')
GO
alter database tempdb
modify file(
name = temp3,
filename = N'd:\mssql\tempdb\tempdb_mssql_3.ndf')
GO

alter database tempdb
modify file(
name = temp4,
filename = N'd:\mssql\tempdb\tempdb_mssql_4.ndf')
GO

alter database tempdb
modify file(
name = temp5,
filename = N'd:\mssql\tempdb\tempdb_mssql_5.ndf')
GO

alter database tempdb
modify file(
name = temp6,
filename = N'd:\mssql\tempdb\tempdb_mssql_6.ndf')
GO

alter database tempdb
modify file(
name = temp7,
filename = N'd:\mssql\tempdb\tempdb_mssql_7.ndf')
GO

alter database tempdb
modify file(
name = temp8,
filename = N'd:\mssql\tempdb\tempdb_mssql_8.ndf')
GO

alter database tempdb
modify file(
name = tempdb2,
filename = N'e:\DATA\TempDB\tempdb2.ndf')
GO

alter database tempdb
modify file(
name = tempdb3,
filename = N'e:\DATA\TempDB\tempdb3.ndf')
GO

alter database tempdb
modify file(
name = tempdb4,
filename = N'e:\DATA\TempDB\tempdb_mssql_4.ndf')
GO

--

alter database tempdb
modify file(
name = tempdb5,
filename = N'e:\Data\TempDB\tempdb_mssql_5.ndf')
GO

alter database tempdb
modify file(
name = temp6,
filename = N'd:\DATA\TempDB\tempdb_mssql_6.ndf')
GO
alter database tempdb
modify file(
name = tempdb7,
filename = N'e:\Data\TempDB\tempdb7.ndf')
GO

alter database tempdb
modify file(
name = tempdb8,
filename = N'e:\Data\TempDB\tempdb8.ndf')
GO

alter database tempdb
modify file(
name = tempdb9,
filename = N'E:\Data\TempDB\tempdb9.ndf')
GO

alter database tempdb
modify file(
name = tempdb10,
filename = N'E:\Data\TempDB\tempdb10.ndf')
GO

alter database tempdb
modify file(
name = tempdb11,
filename = N'E:\Data\TempDB\tempdb_mssql_11.ndf')
GO


alter database tempdb
modify file(
name = tempdev2,
filename = N'e:\DATA\TempDB\tempdev2.ndf')
GO


--tempdev
--templog
--tempdev2
--tempdev3
tempdev4
tempdev5
tempdev6
tempdev7
tempdev8
tempdev9
tempdev10
tempdev11
tempdev12