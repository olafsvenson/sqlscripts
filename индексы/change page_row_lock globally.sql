--
-- Script to disable/enable row & page locking on dev/test environment to flush out deadlock issues
-- executes statement like this for each table in the database:
-- ALTER INDEX indexname ON tablename SET ( ALLOW_ROW_LOCKS  = OFF, ALLOW_PAGE_LOCKS  = OFF )
--
-- DO NOT RUN ON A PRODUCTION DATABASE!!!!
--
set nocount on
declare @newoption varchar(3)
--------------------------------------------------------------------
-- Change variable below to 'ON' or 'OFF' --------------------------
--   'OFF' means row & page locking is disabled and everything 
--      triggers a table lock
--   'ON' means row & page locking is enabled and the server chooses
--     how to escalate the locks (this is the default setting)
set @newoption = 'OFF'
--------------------------------------------------------------------

DECLARE    @TableName varchar(300)
DECLARE    @IndexName varchar(300)
DECLARE @sql varchar(max)

DECLARE inds CURSOR FAST_FORWARD FOR
SELECT tablename, indname
FROM (
    select top 100 percent
    so.name as tablename
         , si.indid
         , si.name as indname
         , INDEXPROPERTY( si.id, si.name, 'IsPageLockDisallowed') as IsPageLockDisallowed
         , INDEXPROPERTY( si.id, si.name, 'IsRowLockDisallowed') as IsRowLockDisallowed
    from   sysindexes si
    join sysobjects so on si.id = so.id
    where  si.status & 64 = 0
      and  objectproperty(so.id, 'IsMSShipped') = 0
      and si.name is not null
      and so.name not like 'aspnet%'
      and so.name not like 'auditLog%'
    order by so.name, si.indid
) t

OPEN inds
FETCH NEXT FROM inds INTO @TableName, @IndexName

WHILE @@FETCH_STATUS = 0
BEGIN

    SET @sql = 'ALTER INDEX [' + @IndexName + '] ON [dbo].[' + @TableName + '] SET ( ALLOW_ROW_LOCKS  = ' + @newoption + ', ALLOW_PAGE_LOCKS  = ' + @newoption +' )'
    PRINT @sql
   -- EXEC(@sql)

    FETCH NEXT FROM inds INTO @TableName, @IndexName
END

CLOSE inds
DEALLOCATE inds


PRINT 'Done'