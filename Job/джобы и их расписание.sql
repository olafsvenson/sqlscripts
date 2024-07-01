USE msdb
GO 

SELECT 
	SJ.name AS JobName
	,CASE
		WHEN SJ.enabled = 1 THEN 'Enable'
	ELSE 'Disable'
	END AS JobStatus
	,SJ.description AS JobDescription
	,SS.name AS JobScheduleName
	,CASE
		WHEN SS.enabled = 1 THEN 'Enable'
		WHEN SS.enabled = 0 THEN 'Disable'
	ELSE 'Not Schedule'
	END AS JobScheduleStatus
	,SS.active_start_date AS ActiveStartDate
	,SS.active_end_date AS ActiveEndDate
	,SS.active_start_time AS ActiveStartTime
	,SS.active_end_time AS ActiveEndTime
FROM dbo.sysjobs AS SJ
LEFT JOIN dbo.sysjobschedules AS SJS
        ON SJ.job_id = SJS.job_id
LEFT JOIN dbo.sysschedules AS SS
        ON SJS.schedule_id = SS.schedule_id
where SJ.enabled = 1
order by SJ.name
GO