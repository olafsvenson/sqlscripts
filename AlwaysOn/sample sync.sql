/*
This script creates a job to copy and sync all logins in a 3 node Availability Group test environment.
User accepts all risks.  Always test in a test environment first.
Ryan J. Adams
https://www.ryanjadams.com/go/AGSync
 
In order for this to work you HAVE to install dbatools from http://dbatools.io
This MUST be done on all replicas.
Run this from an elevated PowerShell to install it.
Try this first
    Install-Module dbatools
If that doesn't work try this
    Invoke-Expression (Invoke-WebRequest -UseBasicParsing https://git.io/vn1hQ)
 
The last option will not make it available to the SQLAgent service account so copy it from your profile to its profile.
Copy the dbatools folder 
FROM   C:\Users\MyProfile\Documents\WindowsPowerShell\Modules
TO   C:\Users\SQLAgentProfile\Documents\WindowsPowerShell\Modules
     
  ***** UPDATE *****
     Copy it here instead so that all users can access it.
     C:\Windows\System32\WindowsPowerShell\v1.0\Modules
  ******************
 
--Here is what the code does after you install DBATOOLS
This will create a function to determine if the node it is running on is currently the primary.  It only creates this function on SQL2012.
It then creates a job with 3 steps.  The first uses the function to determine if it is primary. If it is we continue and if not we raise an error to exit the job.
That job step is set to quit reporting success even if it fails.
Step 2 copies any logins from the partner that do not already exist including all permissions.
Step 3 sync permissions for all existing logins.
 
YOU NEED TO CHANGE THE TARGET DB, SOURCE INSTANCE, AND DESTINATION INSTANCE IN THE JOB STEPS
THE JOB MUST RUN UNDER AN ACCOUNT THAT IS SYSADMIN ON ALL REPLICAS.  IT CAN BE THE SQL AGENT SERVICE ACCOUNT OR A PROXY ACCOUNT.
 
*/
 

USE [master];
GO
 
IF (SELECT LEFT(CONVERT(VARCHAR(2),SERVERPROPERTY('ProductVersion')),2)) = 11 --This function exists on versions above 2012 and below 2012 AGs did not exist.
--This proc alone was written by Patrick Keisler
BEGIN
    IF OBJECT_ID(N'dbo.fn_hadr_is_primary_replica', N'FN') IS NOT NULL
        DROP FUNCTION dbo.fn_hadr_is_primary_replica;
     
    DECLARE @SQL nvarchar(MAX) 
    SET @SQL = '
    CREATE FUNCTION dbo.fn_hadr_is_primary_replica (@DatabaseName SYSNAME)
    RETURNS TINYINT
    WITH EXECUTE AS CALLER
    AS
    /********************************************************************
        File Name:    fn_hadr_is_primary_replica.sql
        Applies to:   SQL Server 2012
        Purpose:      To return either 0, 1, 2, or -1 based on whether this
                    @DatabaseName is a primary or secondary replica.
        Parameters:   @DatabaseName - The name of the database to check.
        Returns:      0 = Resolving
                    1 = Primary
                    2 = Secondary
                    -1 = Database does not exist
        Author:       Patrick Keisler
        Version:      1.0.1 - 07/03/2015
        Help:         http://www.patrickkeisler.com/
        License:      Freeware
    ********************************************************************/
    BEGIN
        DECLARE @HadrRole TINYINT;
        IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @DatabaseName)
        BEGIN
            -- Return role status from sys.dm_hadr_availability_replica_states
            SELECT @HadrRole = ars.role
            FROM sys.dm_hadr_availability_replica_states ars
            INNER JOIN sys.databases dbs
                ON ars.replica_id = dbs.replica_id
            WHERE dbs.name = @DatabaseName
            -- @DatabaseName exists but does not belong to an AG so return 1
            IF @HadrRole IS NULL SET @HadrRole = 1
            RETURN @HadrRole
        END
        ELSE
        BEGIN
            -- @DatabaseName does not exist so return -1
            SET @HadrRole = -1
        END
    RETURN @HadrRole
    END'
    EXECUTE sp_executesql @SQL;
END
GO
 
USE [msdb];
GO
 
--Before we create the job we need an operator
IF NOT EXISTS(select '1' from msdb..sysoperators where name = 'DBA') 
EXEC msdb.dbo.sp_add_operator @name=N'DBA', 
        @enabled=1, 
        @pager_days=0, 
        @email_address=N'DBA@mycompany.com';
GO
 
--Create the category
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name='Availability Group Sync' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name='Availability Group Sync'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
 
END
 
--Create the job
DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Copy and Sync Logins', 
        @enabled=0, 
        @notify_level_eventlog=2, 
        @notify_level_email=2, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description='If this replica is currently the primary it will copy and sync any new accounts.  It will also sync any permissions changes.  If not the primary it will raise an error.', 
        @category_name='Availability Group Sync', 
        @owner_login_name=N'sa', 
        @notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
 
--Create the Verify Primary Job Step
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Verify Primary', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=3, 
        @on_success_step_id=0, 
        @on_fail_action=1, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'TSQL', 
        @command=N'IF sys.fn_hadr_is_primary_replica(''App1AG_DB1'') <> 1 --If it is NOT the primary
BEGIN
    RAISERROR (N''Node is not primary.  Error raised to exit job gracefully. This error can be safely ignored.'',
    16, -- Severity,  
    1) -- State
END
', 
        @database_name=N'master', 
        @flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
 
--Create the Copy Logins Job Step
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Copy Logins NODE1 to NODE2', 
        @step_id=2, 
        @cmdexec_success_code=0, 
        @on_success_action=3, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'PowerShell', 
        @command=N'C:\Windows\System32\WindowsPowerShell\v1.0\PowerShell.exe  -Command "Copy-DbaLogin -Source Node1 -Destination Node2"', 
        @database_name=N'master', 
        @flags=32
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
 
--Create the Sync Logins Job Step
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Sync Logins NODE1 to NODE2', 
        @step_id=3, 
        @cmdexec_success_code=0, 
        @on_success_action=3, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'PowerShell', 
        @command=N'C:\Windows\System32\WindowsPowerShell\v1.0\PowerShell.exe  -Command "Sync-DbaLoginPermission -source Node1 -destination Node2"', 
        @database_name=N'master', 
        @flags=32
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
 
--Create the Copy Logins Job Step
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Copy Logins NODE1 to NODE3', 
        @step_id=4, 
        @cmdexec_success_code=0, 
        @on_success_action=3, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'PowerShell', 
        @command=N'C:\Windows\System32\WindowsPowerShell\v1.0\PowerShell.exe  -Command "Copy-DbaLogin -Source Node1 -Destination Node3"', 
        @database_name=N'master', 
        @flags=32
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
 
--Create the Sync Logins Job Step
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Sync Logins NODE1 to NODE3', 
        @step_id=5, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'PowerShell', 
        @command=N'C:\Windows\System32\WindowsPowerShell\v1.0\PowerShell.exe  -Command "Sync-DbaLoginPermission -source Node1 -destination Node3"', 
        @database_name=N'master', 
        @flags=32
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
 
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily 7:00PM', 
        @enabled=1, 
        @freq_type=4, 
        @freq_interval=1, 
        @freq_subday_type=1, 
        @freq_subday_interval=0, 
        @freq_relative_interval=0, 
        @freq_recurrence_factor=0, 
        @active_start_date=20160805, 
        @active_end_date=99991231, 
        @active_start_time=190000, 
        @active_end_time=235959, 
        @schedule_uid=N'63580255-7f51-4cd6-ad43-eb8ebc646350'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
 
/************************************
Now we go create the job on NODE2
*************************************/