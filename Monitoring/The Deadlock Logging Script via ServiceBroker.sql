/* 
http://michaeljswart.com/2016/09/build-your-own-tools

The Deadlock Logging Script
Here’s the tool!

Create the Database
*/

USE master;
 
IF (DB_ID('DeadlockLogging') IS NOT NULL)
BEGIN
    ALTER DATABASE DeadlockLogging SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DeadlockLogging;
END
 
CREATE DATABASE DeadlockLogging WITH TRUSTWORTHY ON;
GO

-- Create the Service Broker Objects
-- I’ve never used Service Broker before, so a lot of this comes from examples found in Books Online.

use DeadlockLogging;
 
CREATE QUEUE dbo.LogDeadlocksQueue;
 
CREATE SERVICE LogDeadlocksService
    ON QUEUE dbo.LogDeadlocksQueue 
    ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
 
CREATE ROUTE LogDeadlocksRoute
    WITH SERVICE_NAME = 'LogDeadlocksService',
    ADDRESS = 'LOCAL';
 
-- add server level notification
IF EXISTS (SELECT * FROM sys.server_event_notifications WHERE [name] = 'LogDeadlocks')
    DROP EVENT NOTIFICATION LogDeadlocks ON SERVER;
 
DECLARE @SQL NVARCHAR(MAX);
SELECT @SQL = N'
    CREATE EVENT NOTIFICATION LogDeadlocks 
    ON SERVER 
    FOR deadlock_graph -- name of SQLTrace event type
    TO SERVICE ''LogDeadlocksService'', ''' + CAST(service_broker_guid as nvarchar(max))+ ''';'
FROM sys.databases 
WHERE [name] = DB_NAME();
EXEC sp_executesql @SQL;
GO
--The dynamic SQL is used to fetch the database guid of the newly created database.

--a Place to Store Deadlocks

-- Create a place to store the deadlock graphs along with query plan information
CREATE SEQUENCE dbo.DeadlockIdentity START WITH 1;
 
CREATE TABLE dbo.ExtendedDeadlocks 
(
    DeadlockId bigint not null,
    DeadlockTime datetime not null,
    SqlHandle varbinary(64),
    StatementStart int,
    [Statement] nvarchar(max) null,
    Deadlock XML not null,
    FirstQueryPlan XML
);
 
CREATE CLUSTERED INDEX IX_ExtendedDeadlocks 
    ON dbo.ExtendedDeadlocks(DeadlockTime, DeadlockId);
GO

-- The Procedure That Processes Queue Messages

CREATE PROCEDURE dbo.ProcessDeadlockMessage
AS
  DECLARE @RecvMsg NVARCHAR(MAX);
  DECLARE @RecvMsgTime DATETIME;
  SET XACT_ABORT ON;
  BEGIN TRANSACTION;
 
    WAITFOR ( 
        RECEIVE TOP(1)
            @RecvMsgTime = message_enqueue_time,
            @RecvMsg = message_body
        FROM dbo.LogDeadlocksQueue
    ), TIMEOUT 5000;
 
    IF (@@ROWCOUNT = 0)
    BEGIN
      ROLLBACK TRANSACTION;
      RETURN;
    END
 
    DECLARE @DeadlockId BIGINT = NEXT VALUE FOR dbo.DeadlockIdentity;
    DECLARE @RecsvMsgXML XML = CAST(@RecvMsg AS XML);
    DECLARE @DeadlockGraph XML = @RecsvMsgXML.query('/EVENT_INSTANCE/TextData/deadlock-list/deadlock');
 
    WITH DistinctSqlHandles AS
    (
        SELECT DISTINCT node.value('@sqlhandle', 'varchar(max)') as SqlHandle
        FROM @RecsvMsgXML.nodes('//frame') AS frames(node)            
    )
    INSERT ExtendedDeadlocks (DeadlockId, DeadlockTime, SqlHandle, StatementStart, [Statement], Deadlock, FirstQueryPlan)
    SELECT @DeadlockId,
        @RecvMsgTime,
        qs.sql_handle,
        qs.statement_start_offset,
        [statement],
        @DeadlockGraph, 
        qp.query_plan
    FROM DistinctSqlHandles s
    LEFT JOIN sys.dm_exec_query_stats qs 
        on qs.sql_handle = CONVERT(VARBINARY(64), SqlHandle, 1) 
    OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
    OUTER APPLY sys.dm_exec_sql_text (CONVERT(VARBINARY(64), SqlHandle, 1)) st
    OUTER APPLY ( 
      SELECT SUBSTRING(st.[text],(qs.statement_start_offset + 2) / 2,
          (CASE 
             WHEN qs.statement_end_offset = -1  THEN LEN(CONVERT(NVARCHAR(MAX), st.text)) * 2
             ELSE qs.statement_end_offset + 2
             END - qs.statement_start_offset) / 2)) as sqlStatement([statement]);
 
    -- clean up old deadlocks
    DECLARE @limit BIGINT
    SELECT DISTINCT TOP (500) @limit = DeadlockId 
    FROM ExtendedDeadlocks 
    ORDER BY DeadlockId DESC;
    DELETE ExtendedDeadlocks 
    WHERE DeadlockId < @limit;
 
  COMMIT
 
GO
--Activating the Procedure

ALTER QUEUE dbo.LogDeadlocksQueue
    WITH ACTIVATION
    ( STATUS = ON,
      PROCEDURE_NAME = dbo.ProcessDeadlockMessage,
      MAX_QUEUE_READERS = 1,
      EXECUTE AS SELF
    );
GO
-- Clean Up
-- And when you’re all done, this code will clean up this whole experiment.

use master;
 
if (db_id('DeadlockLogging') is not null)
begin
    alter database DeadlockLogging set single_user with rollback immediate 
    drop database DeadlockLogging
end
 
if exists (select * from sys.server_event_notifications where name = 'DeadlockLogging')
    DROP EVENT NOTIFICATION LogDeadlocks ON SERVER;