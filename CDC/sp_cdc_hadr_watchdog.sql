CREATE PROCEDURE sp_cdc_hadr_watchdog
AS
BEGIN

SET NOCOUNT ON

DECLARE @database_name NVARCHAR(255)
DECLARE @SQL NVARCHAR(MAX)

DECLARE cdc_watchdog_dbs CURSOR FAST_FORWARD READ_ONLY 
FOR 
SELECT  D.name
FROM    sys.dm_hadr_availability_replica_states AS A
        JOIN sys.availability_replicas AS B ON B.replica_id = A.replica_id
        JOIN sys.availability_groups AS AG ON AG.group_id = A.group_id
        JOIN sys.availability_databases_cluster AS ADC ON ADC.group_id = A.group_id
        JOIN sys.databases AS D ON D.name = ADC.database_name AND D.is_cdc_enabled = 1
WHERE B.replica_server_name = @@SERVERNAME AND A.role_desc = 'PRIMARY'

OPEN cdc_watchdog_dbs

FETCH NEXT FROM cdc_watchdog_dbs INTO @database_name

WHILE @@FETCH_STATUS = 0
BEGIN

SET @SQL = '
USE ['+@database_name+'];

IF OBJECT_ID(''tempdb..#xp_results'') IS NOT NULL
EXEC (''DROP TABLE #xp_results'')

IF OBJECT_ID(''tempdb..#CDCJobs'') IS NOT NULL
EXEC (''DROP TABLE #CDCJobs'')

CREATE TABLE #CDCJobs(job_id          UNIQUEIDENTIFIER
                    , job_type        CHAR(8)
                    , job_name        NVARCHAR(255)
                    , maxtrans        SMALLINT
                    , maxscans        SMALLINT
                    , continuous      BIT
                    , pollinginterval SMALLINT
                    , retention       SMALLINT
                    , threshold       SMALLINT)

INSERT INTO #CDCJobs
EXEC sys.sp_cdc_help_jobs

DECLARE @job_id_capture UNIQUEIDENTIFIER
DECLARE @job_owner_capture sysname

DECLARE @job_id_cleanup UNIQUEIDENTIFIER

DECLARE @is_running INT

SELECT @job_owner_capture = SP.name, @job_id_capture = S.job_id
FROM #CDCJobs AS CJ
JOIN msdb.dbo.sysjobs AS S ON s.name = CJ.job_name
JOIN sys.server_principals AS SP ON SP.sid = S.owner_sid
WHERE CJ.job_type = ''capture''

SELECT @job_id_cleanup = CJ.job_id
FROM #CDCJobs AS CJ
WHERE CJ.job_type = ''cleanup''

IF @job_id_capture IS NULL
 EXEC sys.sp_cdc_add_job ''capture''

IF @job_id_cleanup IS NULL
 EXEC sys.sp_cdc_add_job ''cleanup''

IF @job_id_capture IS NOT NULL
 BEGIN
  CREATE TABLE #xp_results (job_id             UNIQUEIDENTIFIER NOT NULL,
        last_run_date         INT              NOT NULL,
        last_run_time         INT              NOT NULL,
        next_run_date         INT              NOT NULL,
        next_run_time         INT              NOT NULL,
        next_run_schedule_id  INT              NOT NULL,
        requested_to_run      INT              NOT NULL,
        request_source        INT              NOT NULL,
        request_source_id     sysname          COLLATE database_default NULL,
        running               INT              NOT NULL,
        current_step          INT              NOT NULL,
        current_retry_attempt INT              NOT NULL,
        job_state             INT              NOT NULL)

  INSERT INTO #xp_results
  EXEC master.dbo.xp_sqlagent_enum_jobs  0, @job_owner_capture, @job_id_capture 

  SELECT @is_running = XR.running
  FROM #xp_results AS XR

  IF @is_running = 1
   RETURN
  ELSE
   EXEC msdb.dbo.sp_start_job @job_id = @job_id_capture

 END'

EXEC (@SQL)

    FETCH NEXT FROM cdc_watchdog_dbs INTO @database_name
END

CLOSE cdc_watchdog_dbs
DEALLOCATE cdc_watchdog_dbs