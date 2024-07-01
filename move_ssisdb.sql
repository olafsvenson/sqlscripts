
-- (1)
SELECT name,physical_name FROM sys.master_files WHERE database_id = DB_ID('ssisdb')

/*
	C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\SSISDB.mdf
	C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\SSISDB.ldf
*/

-- (2)
alter database ssisdb
modify file(
name = data,
filename = N'D:\MSSQL\Data\SSISDB.mdf')
go

alter database ssisdb
modify file(
name = log,
filename = N'D:\MSSQL\Data\SSISDB.ldf')
go

-- (3) Остановить службы
-- (4) Перенести файлы
-- (5) Включить службы
