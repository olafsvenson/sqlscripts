USE [master]
GO

-- dependencies of asp_long_running_Regressing_Jobs_Alerts:
 
-- udf_convert_int_time
CREATE or alter FUNCTION [dbo].[udf_convert_int_time] (@time_in INT)
RETURNS TIME
AS
 BEGIN
        DECLARE @time_out TIME
        DECLARE @time_in_str varchar(6)
        SELECT  @time_in_str = RIGHT('000000' + CAST(@time_in AS VARCHAR(6)), 6)
        SELECT  @time_out    = CAST(STUFF(STUFF(@time_in_str,3,0,':'),6,0,':') AS TIME)
  RETURN @time_out
 END
GO
 
-- udf_convert_int_time2ss
CREATE or alter  FUNCTION [dbo].[udf_convert_int_time2ss] (@time_in INT)
RETURNS int
AS
 BEGIN
        DECLARE @time_out int
        select @time_out = datediff(ss, 0,  dbo.udf_convert_int_time(@time_in))
  RETURN @time_out
 END
GO

 
-- <begin stored procedure DDL/>
 
CREATE or alter PROCEDURE sp_long_running_Regressing_Jobs_Alerts
         @history_days int = 7,
         @avg_duration_multiplier float = 1.5,
         @bEmail bit = 0,
         @bSaveToTable bit = 0,
         @RecipientsList Varchar(1000) = 'myName@myCoDomain.com',
         @ignore_zero_durations bit = 0,
		 @mail_profile sysname
 
AS
/* example of usage:
   exec DBA_db..sp_long_running_Regressing_Jobs_Alerts
               @history_days = 45,
               @avg_duration_multiplier = 2,
               @bEmail = 0,
               @bSaveToTable = 0,
               @RecipientsList  = 'myName@myCoDomain.com;'   ,
               @ignore_zero_durations = 1,
			   @mail_profile = 'Dba-Alerts'
 
AUTHOR(s):
Vladimir Isaev;
-- + V.B., S.L;
-- contact@sqlexperts.org
*/      
 
/*PARAMETERS:
@history_days int          (how many days back we use for AVF run duration)
@avg_duration_multiplier   (how many times longer than AVG will qualify job 
                            for producing an alert)
@bEmail                    (send out Alert Email or just print the msg about Regressing jobs)
                           -- 'REGRESSION' is defined here by Duration only
*/
SET NOCOUNT ON
BEGIN
 
        select sj.name,
               sja.start_execution_date,
               sja.stop_execution_date,
               ajt.min_run_duration,
               ajt.max_run_duration,
               ajt.avg_run_duration,
               datediff(ss, start_execution_date, getdate()) as cur_run_duration
        into #Regressing_Jobs
 
        from msdb..sysjobactivity sja
               left join
               (select job_id,
                       avg(dbo.udf_convert_int_time2ss(run_duration)) as avg_run_duration,
                       min(dbo.udf_convert_int_time2ss(run_duration)) as min_run_duration,
                       max(dbo.udf_convert_int_time2ss(run_duration)) as max_run_duration
                       from msdb..sysjobhistory
                       where step_id=0
                       and run_date > CONVERT(varchar(8),GETDATE() - @history_days,112)
                       and ((run_duration <> 0 or @ignore_zero_durations = 0))
                       and run_duration < 240000
                       group by job_id
               )ajt on sja.job_id=ajt.job_id
        join msdb..sysjobs sj on sj.job_id=sja.job_id
        where
               sja.session_id = (SELECT TOP 1 session_id
                                   FROM msdb.dbo.syssessions
                                  ORDER BY agent_start_date DESC)
               AND start_execution_date is not null
               and stop_execution_date is null
               and datediff(ss, start_execution_date, getdate()) >
                   ajt.avg_run_duration * @avg_duration_multiplier
 
        select name as JobName,
               start_execution_date,
               stop_execution_date,
               dateadd(second, min_run_duration, 0) as min_run_duration,
               dateadd(second, max_run_duration, 0) as max_run_duration,
               dateadd(second, avg_run_duration, 0) as avg_run_duration,
               dateadd(second, cur_run_duration, 0) as cur_run_duration
        into #Regressing_Jobs_DurAsDate
        from #Regressing_Jobs
                                            --  waitfor delay '00:00:10'
        declare @sHtml varchar(max) = ''
 
        declare @tableHTML  nvarchar(max) =
               N'<H1>Job(s) taking longer than recent baseline duration
                (in descending avg duration order):</H1>' + Char(13)
               + N'    <table border="1">'           + Char(13)
               + N'    <tr bgcolor="#ddd">'          + Char(13)
               + N'           <th>Start Time</th>'   + Char(13)
               + N'           <th>Job Name</th>'     + Char(13)
               + N'           <th>Host Name</th>'    + Char(13)
               + N'           <th>History Days</th>' + Char(13)
               + N'           <th>Avg Dur Mul</th>'  + Char(13)
               + N'           <th>Min Dur</th>'      + Char(13)
               + N'           <th>Max Dur</th>'      + Char(13)
               + N'           <th>Avg Dur</th>'      + Char(13)
               + N'           <th>Cur Dur</th>'      + Char(13)
               + N'    </tr>'                        + Char(13)
 
        select @tableHTML =  @tableHTML
               + FORMATMESSAGE(
                       '<tr><td>%s</td>'      
                          + Char(13) --start_execution_date
                       + '<td>%s</td>'        + Char(13) --name
                       + '<td>%s</td>'        + Char(13) --@@SERVERNAME
                       + '<td style="text-align:center">%i</td>' 
                          + Char(13) --@history_days
                       + '<td style="text-align:center">%s</td>' 
                          + Char(13) --@avg_duration_multiplier
                       + '<td>%s</td>'        + Char(13) --Min Dur
                       + '<td>%s</td>'        + Char(13) --Max Dur
                       + '<td>%s</td>'        + Char(13) --Avg Dur
                       + '<td>%s</td>'        + Char(13),--Cur Dur
                               convert(varchar, start_execution_date, 120),
                               JobName,
                               @@SERVERNAME,
                               @history_days,
                               convert(varchar, @avg_duration_multiplier),
                               format(min_run_duration, N'HH\hmm\mss\s'),
                               format(max_run_duration, N'HH\hmm\mss\s'),
                               format(avg_run_duration, N'HH\hmm\mss\s'),
                               format(cur_run_duration, N'HH\hmm\mss\s')
                       )
          from #Regressing_Jobs_DurAsDate
          order by avg_run_duration desc, JobName
 
               select @tableHTML = @tableHTML + '</tr></table>' + Char(13)
 
        select @sHtml = @tableHTML
        --select @sHtml
 
        declare @DateStr varchar(30) = convert(varchar,getdate(),121)
        IF @bEmail = 1 and (select count(*) from #Regressing_Jobs) > 0
         begin
              
               declare @sSubject varchar(250)
                   = @@SERVERNAME + ' Job(s) taking longer than recent baseline duration: ' 
                     + @DateStr 
 
               EXEC msdb.dbo.sp_send_dbmail  @profile_name='Dba-Alerts',
                                              @recipients= @RecipientsList,
                                              @subject=@sSubject, 
                                              @body=@sHtml,
                                              @body_format = 'HTML'
 
               print 'email sent: ' + CHAR(13) + @sHtml
        end
 
        IF @bSaveToTable = 1
          begin
               insert into RegressingJobs
				(
				 CaptureDateTime,
				 JobName,
				 start_execution_date,
				 HostName,
				 history_days,
				 avg_duration_multiplier,
                 min_run_duration,
				 max_run_duration,
				 avg_run_duration,
				 cur_run_duration
				)
				select         @DateStr,
				JobName,
				start_execution_date,
				@@SERVERNAME,
				@history_days,   
				@avg_duration_multiplier,
				min_run_duration,
				max_run_duration,
				avg_run_duration,
				cur_run_duration
               from #Regressing_Jobs_DurAsDate
          end
 
        begin
 
         SELECT 'JOBS THAT ARE TAKING LONGER THAN USUAL:  '
         select  @DateStr as CaptureDateTime, JobName, 
            start_execution_date, @@SERVERNAME as 'Server',
                 @history_days as '@history_days', 
                    @avg_duration_multiplier as '@avg_duration_multiplier',
                 min_run_duration, max_run_duration, 
                    avg_run_duration, cur_run_duration
         from    #Regressing_Jobs_DurAsDate
 
        end
 
--all currently running jobs:
       begin
               SELECT ' ALL JOBS THAT ARE CURRENTLY RUNNING:  '
               SELECT
                 -- '',  -- CAST (ja.job_id AS VARCHAR(max)),
                       j.name AS job_name,
                  cast ( ja.start_execution_date as varchar) start_execution_time,  
                  cast ( ja.stop_execution_date  as varchar) stop_execution_time,  
                  -- ISNULL(last_executed_step_id,0)+1 AS current_executed_step_id,
                       Js.step_name step_name
               FROM msdb.dbo.sysjobactivity ja
               LEFT JOIN msdb.dbo.sysjobhistory jh
                       ON ja.job_history_id = jh.instance_id
               JOIN msdb.dbo.sysjobs j
                 ON ja.job_id = j.job_id
               JOIN msdb.dbo.sysjobsteps js
                 ON ja.job_id = js.job_id
                AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
               WHERE ja.session_id =
                    (SELECT TOP 1 session_id
               FROM msdb.dbo.syssessions
           ORDER BY agent_start_date DESC)
               AND start_execution_date is not null
               AND stop_execution_date  is null;
 
        end
END
 
GO