SELECT J.[name] 
       ,[step_name]
      ,[message]
      ,[run_status]
      ,[run_date]
      ,[run_time]
      ,[run_duration]
  FROM [msdb].[dbo].[sysjobhistory] JH
  JOIN [msdb].[dbo].[sysjobs] J
  ON JH.job_id= J.job_id
  WHERE [message] like '%incorrect checksum%'