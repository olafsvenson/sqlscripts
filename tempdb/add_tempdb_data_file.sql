USE [master]
GO
E:\temp_db\tempdb_mssql_4.ndf
SELECT name,physical_name FROM sys.master_files WHERE database_id = DB_ID('tempdb')

ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb5', FILENAME = N'D:\MSSQL\SysData\MSSQL15.MSSQLSERVER\MSSQL\DATA\tempdb_mssql_5.ndf' , SIZE = 1536MB , FILEGROWTH = 64MB )
GO
/*
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb4', FILENAME = N'e:\DATA\TempDB\tempdb4.ndf' , SIZE = 1536MB , FILEGROWTH = 256MB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'temp5', FILENAME = N'D:\DATA\TempDB\tempdb_mssql_5.ndf' , SIZE = 256MB , FILEGROWTH = 64MB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'temp6', FILENAME = N'd:\DATA\TempDB\tempdb6.ndf' , SIZE = 256MB , FILEGROWTH = 64MB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb7', FILENAME = N'd:\DATA\TempDB\tempdb_mssql_7.ndf' , SIZE = 256MB , FILEGROWTH = 64MB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb8', FILENAME = N'd:\DATA\TempDB\tempdb_mssql_8.ndf' , SIZE = 256MB , FILEGROWTH = 64MB )
GO

ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb9', FILENAME = N'e:\DATA\TempDb\tempdb19.ndf' , SIZE = 1536MB , FILEGROWTH = 256MB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb10', FILENAME = N'e:\DATA\TempDb\tempdb20.ndf' , SIZE = 1536MB , FILEGROWTH = 256MB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb11', FILENAME = N'e:\DATA\TempDb\tempdb11.ndf' , SIZE = 1536MB , FILEGROWTH = 256MB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb22', FILENAME = N'e:\DATA\TempDb\tempdb22.ndf' , SIZE = 1536MB , FILEGROWTH = 256MB )
GO

ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb6', FILENAME = N'd:\DATA\TempDb\tempdb6.ndf' , SIZE = 39108KB , FILEGROWTH = 256MB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb7', FILENAME = N'd:\DATA\TempDb\tempdb7.ndf' , SIZE = 39108KB , FILEGROWTH = 256MB )
GO


ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb13', FILENAME = N'f:\DATA\TempDb\tempdb13.ndf' , SIZE = 37GB , FILEGROWTH = 64MB,MAXSIZE = 48GB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb14', FILENAME = N'f:\DATA\TempDb\tempdb14.ndf' , SIZE = 37GB , FILEGROWTH = 64MB,MAXSIZE = 48GB  )
GO

ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb15', FILENAME = N'f:\DATA\TempDb\tempdb15.ndf' , SIZE = 37GB , FILEGROWTH = 64MB,MAXSIZE = 48GB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb16', FILENAME = N'f:\DATA\TempDb\tempdb16.ndf' , SIZE = 37GB , FILEGROWTH = 64MB,MAXSIZE = 48GB  )
GO

ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb17', FILENAME = N'f:\DATA\TempDb\tempdb17.ndf' , SIZE = 37GB , FILEGROWTH = 64MB,MAXSIZE = 48GB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb18', FILENAME = N'f:\DATA\TempDb\tempdb18.ndf' , SIZE = 37GB , FILEGROWTH = 64MB,MAXSIZE = 48GB  )
GO

ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb19', FILENAME = N'f:\DATA\TempDb\tempdb19.ndf' , SIZE = 37GB , FILEGROWTH = 64MB,MAXSIZE = 48GB )
GO
ALTER DATABASE [tempdb] ADD FILE ( NAME = N'tempdb20', FILENAME = N'f:\DATA\TempDb\tempdb20.ndf' , SIZE = 37GB , FILEGROWTH = 64MB,MAXSIZE = 48GB  )
GO*/