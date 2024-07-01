DECLARE @JobName sysname = '05.2. Обслуживание индексов. Реиндексация (КД ??)'

IF EXISTS
(
	SELECT 
		sj.name,
		DATEDIFF(SECOND,aj.start_execution_date,GetDate()) AS Seconds
	FROM msdb..sysjobactivity aj
		JOIN msdb..sysjobs sj on sj.job_id = aj.job_id
	WHERE aj.stop_execution_date IS NULL -- job hasn't stopped running
		AND aj.start_execution_date IS NOT NULL -- job is currently running
		AND sj.name = @JobName -- имя джоба
		and not EXISTS
		( -- make sure this is the most recent run
			select 1
			from msdb..sysjobactivity new
			where new.job_id = aj.job_id
			and new.start_execution_date > aj.start_execution_date
		)
)
BEGIN
	-- если джоб запущен, то останавливаем его
	exec msdb..sp_stop_job   @job_name = @JobName 

	RAISERROR(@JobName, 16, 1)
end