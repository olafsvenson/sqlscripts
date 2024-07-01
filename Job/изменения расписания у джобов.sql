-- просмотр настроек расписания
SELECT *
FROM MSDB.dbo.sysschedules ss
     INNER JOIN msdb.dbo.sysjobschedules jss 
	 ON jss.schedule_id = ss.schedule_id
WHERE ss.enabled = 1;



-- изменение
declare @sql nvarchar(max) = ''
select @sql = @sql + N'
	exec sp_update_schedule  @schedule_id = ' + cast(sch.schedule_id as varchar)   + N', @freq_subday_type = 4, @freq_subday_interval = 1'
FROM sysjobs JOB 
	left join sysjobschedules jsch
	on job.job_id = jsch.job_id	
	left join sysschedules sch
	on jsch.schedule_id = sch.schedule_id
where job.name = N'08.3 Сбор данных awr. pfc (КД через 15с)'

PRINT @sql
EXEC (@sql)
	

	
-- изменение по имени 
EXEC msdb.dbo.sp_update_schedule  
    @name = 'HistoryXE',  
    @freq_subday_interval=10