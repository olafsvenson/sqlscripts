--get output from Adam Machanic's excellent "sp_WhoIsActive" script from http://whoisactive.com
--into logging table, should be scheduled every 30-60 seconds
--relies on sp_WhoIsActive stored proc being present in master database
--logging table hard-coded here to "WhoIsActive" table in Scratch database
--liberally borrowed from https://www.brentozar.com/archive/2016/07/logging-activity-using-sp_whoisactive-take-2/

USE [master]

SET NOCOUNT ON

DECLARE
    --number of days to retain output from sp_WhoIsActive in logging table
    @number_of_days_to_retain INT = 7,
    --logging table name (will be created if does not exist)
    @destination_table NVARCHAR(500) = N'WhoIsActive',
    --logging table database (will not be created if it doesn't exist)
    @destination_database SYSNAME = N'sputnik',
    --dynamic SQL, re-used
    @sql NVARCHAR(4000),
    --does the index on the logging table exist?
    @does_index_exist BIT

--prepend logging table with database and schema
SET @destination_table = @destination_database + N'.dbo.' + @destination_table

--create the logging table if it doesn't exist
IF OBJECT_ID(@destination_table) IS NULL BEGIN
    --get the CREATE TABLE statement to suit output from sp_WhoIsActive
    EXEC master..sp_WhoIsActive @get_transaction_info = 1, @get_outer_command = 1, @get_plans = 1, @return_schema = 1, @format_output = 0, @get_additional_info = 1, @schema = @sql OUTPUT
    --replace with logging table name in returned CREATE TABLE statement
    SET @sql = REPLACE(@sql, N'<table_name>', @destination_table)
    --create the logging table by executing the CREATE TABLE statement
    EXEC(@sql)
END

--logging table exists; now check for index on collection_time column
--index on collection_time makes it easier to delete older data
SET @sql = N'USE ' + QUOTENAME(@destination_database) + N'; IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(@destination_table) AND name = N''cx_collection_time'') SET @does_index_exist = 0'
--check if the index exists, output will be in boolean "@does_index_exist"
EXEC sp_executesql @sql, N'@destination_table NVARCHAR(500), @does_index_exist bit OUTPUT', @destination_table = @destination_table, @does_index_exist = @does_index_exist OUTPUT
--does index exist? If not, create it on the logging table
IF @does_index_exist = 0 BEGIN
  SET @sql = N'CREATE CLUSTERED INDEX cx_collection_time ON ' + @destination_table + ' (collection_time ASC) with (DATA_COMPRESSION = page)'
  EXEC(@sql)
END

SET NOCOUNT OFF

--get output from sp_WhoIsActive into logging table
--  @get_transaction_info: "Enables pulling transaction log write info and transaction duration"
--  @get_outer_command: "Get the associated outer ad hoc query or stored procedure call, if available"
--  @get_plans: "Get associated query plans for running tasks, if available"
--  @format_output: "...outputs all of the numbers as actual numbers rather than text"
--  @get_additional_info: "...he [additional_info] column is an XML column that returns a document with a root node called <additional_info>. What’s inside of the node depends on a number of things..."
EXEC master..sp_WhoIsActive @get_transaction_info = 1, @get_outer_command = 1, @get_plans = 1, @format_output = 0, @get_additional_info = 1, @destination_table = @destination_table

SET NOCOUNT ON

--delete data older than "number of days to retain" variable
SET @sql = N'DELETE FROM ' + @destination_table + N' WHERE [collection_time] < DATEADD(day, -' + CAST(@number_of_days_to_retain AS NVARCHAR(10)) + N', GETDATE())'
EXEC(@sql)