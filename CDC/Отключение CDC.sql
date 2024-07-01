-- Показ данных по отслеживаемым объектам
exec sys.sp_cdc_help_change_data_capture

-- Отключение CDC на отдельных таблицах
USE [Pegasus2008MS];  
GO  
EXECUTE sys.sp_cdc_disable_table   
    @source_schema = N'dbo',   
    @source_name = N'_Document584',  
    @capture_instance = N'dbo__Document584';  


USE [Pegasus2008]  
GO  
EXEC sys.sp_cdc_disable_db 
GO   
-----------------------------------------

USE [Pegasus2008MS];  
GO  
SELECT @@spid
/*
EXECUTE sys.sp_cdc_disable_table   
    @source_schema = N'dbo',   
    @source_name = N'_Document566',  
    @capture_instance = N'dbo__Document566';  
	*/

--EXECUTE sys.sp_cdc_disable_table   
--    @source_schema = N'dbo',   
--    @source_name = N'_Document580',  
--    @capture_instance = N'dbo__Document580';  

	--EXECUTE sys.sp_cdc_disable_table   
 --   @source_schema = N'dbo',   
 --   @source_name = N'_Document584',  
 --   @capture_instance = N'dbo__Document584';

	
	--EXECUTE sys.sp_cdc_disable_table   
 --   @source_schema = N'dbo',   
 --   @source_name = N'_Document569',  
 --   @capture_instance = N'dbo__Document569';

--EXECUTE sys.sp_cdc_disable_table   
--    @source_schema = N'dbo',   
--    @source_name = N'_Document570',  
--    @capture_instance = N'dbo__Document570';

	EXECUTE sys.sp_cdc_disable_table   
    @source_schema = N'dbo',   
    @source_name = N'_Document568',  
    @capture_instance = N'dbo__Document568';

--EXECUTE sys.sp_cdc_disable_table   
--    @source_schema = N'dbo',   
--    @source_name = N'_Document22411',  
--    @capture_instance = N'dbo__Document22411';

--EXECUTE sys.sp_cdc_disable_table   
--    @source_schema = N'dbo',   
--    @source_name = N'_Document556_VT40831',  
--    @capture_instance = N'dbo__Document556_VT40831';

	EXECUTE sys.sp_cdc_disable_table   
    @source_schema = N'dbo',   
    @source_name = N'_Document559',  
    @capture_instance = N'dbo__Document559';

	--EXECUTE sys.sp_cdc_disable_table   
 --   @source_schema = N'dbo',   
 --   @source_name = N'_Document561',  
 --   @capture_instance = N'dbo__Document561';

EXECUTE sys.sp_cdc_disable_table   
    @source_schema = N'dbo',   
    @source_name = N'_Document560',  
    @capture_instance = N'dbo__Document560';

EXECUTE sys.sp_cdc_disable_table   
    @source_schema = N'dbo',   
    @source_name = N'_Document557',  
    @capture_instance = N'dbo__Document557';

EXECUTE sys.sp_cdc_disable_table   
    @source_schema = N'dbo',   
    @source_name = N'_Document556',  
    @capture_instance = N'dbo__Document556';

	--EXECUTE sys.sp_cdc_disable_table   
 --   @source_schema = N'dbo',   
 --   @source_name = N'_AccumRg36627',  
 --   @capture_instance = N'dbo__AccumRg36627';