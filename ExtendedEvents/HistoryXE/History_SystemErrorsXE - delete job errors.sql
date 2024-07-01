use master
go

declare @job_id nvarchar(100)

SELECT top 1 @job_id = (substring(sys.fn_varbintohexstr(sj.job_id),3,100))  FROM msdb..sysjobs sj WHERE name ='History_WhoIsActive'

create nonclustered index IX_error_number_severity_state_client_app_name_filtered on [dbo].[History_SystemErrorsXE]
(
  [error_number]
 ,[severity]
 ,[state]
 ,[client_app_name]
) 
where 
		[error_number] = 7955
		and [severity] = 16
		and [state] = 2
		--and[client_app_name] = 'SQLAgent - TSQL JobStep (Job 0x'+@job_id +' : Step 1)'
--include([Dt_Event]
--      ,[session_id]
--      ,[database_name]
--      ,[session_nt_username]
--      ,[client_hostname]
--	   ,[sql_text]
--      ,[message])
with(data_compression=page)--,drop_existing=on



select count(1)
from [dbo].[History_SystemErrorsXE] --with (index=IX_error_number_severity_state_client_app_name)
where 
		[error_number] = 7955
		and [severity] = 16
		and [state] = 2
		and[client_app_name] = 'SQLAgent - TSQL JobStep (Job 0x8150C1E74B2865489C6AA936D88AE4E8 : Step 1)'




Invalid SPID 65 specified.
8150c1e74b2865489c6aa936d88ae4e8



SELECT top 1 (substring(sys.fn_varbintohexstr(sj.job_id),3,100)) as id
FROM msdb..sysjobs sj
WHERE name ='History_WhoIsActive'

SELECT top 100 *
  FROM [dbo].[History_SystemErrorsXE]
  order by dt_event desc

  select count(1) from [dbo].[History_SystemErrorsXE]

  ---------------------------------------------

  set nocount off
 
 declare @job_id nvarchar(100)
 
 SELECT top 1 @job_id = (substring(sys.fn_varbintohexstr(sj.job_id),3,100)) FROM msdb..sysjobs sj WHERE name = 'History_WhoIsActive'

--select top 10 * 
delete 
from [dbo].[History_SystemErrorsXE] 
where 
		[error_number] = 7955
		and [severity] = 16
		and [state] = 2
		and[client_app_name] = 'SQLAgent - TSQL JobStep (Job 0x'+@job_id +' : Step 1)'

		SQLAgent - TSQL JobStep (Job 0x8150C1E74B2865489C6AA936D88AE4E8 : Step 1)
		SQLAgent - TSQL JobStep (Job 0x8150C1E74B2865489C6AA936D88AE4E8 : Step 1)



EXEC sp_spaceused N'dbo.History_SystemErrorsXE';


truncate table [guest].[beta_lockinfo]