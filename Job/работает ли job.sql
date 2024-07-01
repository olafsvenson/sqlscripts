USE [msdb]
GO
/****** Object:  StoredProcedure [usp_GetJobExecutionStatus]    Script Date: 06/06/2011 09:48:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [usp_GetJobExecutionStatus]
@jname sysname 
AS
SET NOCOUNT ON
DECLARE @is_sysadmin INT
  DECLARE @job_owner   sysname
DECLARE @Ret INT
DECLARE @job_state nvarchar(50)



  CREATE TABLE #xp_results (job_id                UNIQUEIDENTIFIER NOT NULL,
                            last_run_date         INT              NOT NULL,
                            last_run_time         INT              NOT NULL,
                            next_run_date         INT              NOT NULL,
                            next_run_time         INT              NOT NULL,
                            next_run_schedule_id  INT              NOT NULL,
                            requested_to_run      INT              NOT NULL, -- BOOL
                            request_source        INT              NOT NULL,
                            request_source_id     sysname          NULL,
       running               INT              NOT NULL, -- BOOL
                            current_step          INT              NOT NULL,
                            current_retry_attempt INT              NOT NULL,
                            job_state             INT              NOT NULL)

  SELECT @is_sysadmin = ISNULL(IS_SRVROLEMEMBER(N'sysadmin'), 0)
  SELECT @job_owner = SUSER_SNAME()

  INSERT INTO #xp_results
  EXECUTE master.dbo.xp_sqlagent_enum_jobs @is_sysadmin, @job_owner
IF @jname IS NULL 
	BEGIN
	SELECT sj.Name,xpr.job_state,
	case xpr.job_state 
		WHEN  0 THEN 'Not idle or suspended'
		WHEN  1 THEN 'Executing'
		WHEN  2 THEN 'Waiting For Thread'
		WHEN  3 THEN 'Between Retries'
		WHEN  4 THEN 'Idle'
		WHEN  5 THEN 'Suspended'
		WHEN  6 THEN 'WaitingForStepToFinish'
		WHEN  7 THEN 'PerformingCompletionActions'
		ELSE 'Unknown'  
	END AS 'Status'
	FROM  #xp_results xpr
	INNER JOIN sysjobs sj on xpr.job_id = sj.job_id
	set @ret =  0
END
ELSE
BEGIN	
	SELECT @Ret=xpr.job_state,
	@job_state =case xpr.job_state 
		WHEN  0 THEN 'Not idle or suspended'
		WHEN  1 THEN 'Executing'
		WHEN  2 THEN 'Waiting For Thread'
		WHEN  3 THEN 'Between Retries'
		WHEN  4 THEN 'Idle'
		WHEN  5 THEN 'Suspended'
		WHEN  6 THEN 'WaitingForStepToFinish'
		WHEN  7 THEN 'PerformingCompletionActions'
		ELSE 'Unknown'  
	END
	FROM  #xp_results xpr
	INNER JOIN sysjobs sj on xpr.job_id = sj.job_id
	WHERE  sj.name = @jname
	
	SELECT @jname AS 'Name',@Ret AS job_state,@job_state AS 'Status'
END
	
 -- Clean up
  DROP TABLE #xp_results
return @ret	 