------- Настройки распостранителя
--1)
use [master]
exec sp_adddistributor @distributor = N'SQL2\SQL2', @password = N'lbcnhb,ewbzflvby'
GO

--2)
use [master]
exec sp_adddistributiondb @database = N'distribution3', @data_folder = N'T:\MSSQL10_50.SQL4\MSSQL\Data', @data_file = N'distribution3.MDF', @data_file_size = 5967, @log_folder = N'T:\MSSQL10_50.SQL4\MSSQL\Data', @log_file = N'distribution3.LDF', @log_file_size = 2553, @min_distretention = 0, @max_distretention = 168, @history_retention = 168, @security_mode = 1
GO

--3)
USE [distribution3]
EXEC sp_adddistpublisher @publisher=N'SQL3\SQL3', 
    @distribution_db=N'distribution3', 
    @security_mode = 1;
    
    
    
---- Настройки издателя

-- 4)

use master
exec sp_adddistributor @distributor = N'SQL2\SQL2', @password = N'lbcnhb,ewbzflvby'
GO


-- 5) стандартная настройка репликации




    /*
    Use Master
go
exec Sp_DropServer 'sql3\sql3'
go

Use Master
go
exec Sp_Addserver 'sql3\sql3'
go 


sp_AddRemoteLogin 'sql3\sql3','distributor_admin'


sp_changedistributor_password @password = N'lbcnhb,ewbzflvby'
    
    */