USE master
GO

-- таймауты
;with cte as
(
	SELECT  *  
	FROM [master].[dbo].[History_TimeoutsXE] 
	where 
			Dt_Event > dateadd(dd,-1,getdate()) -- за последний день
		--	database_name='pythoness_sbol'
)
select top 100 *
from cte
where client_app_name not in (
								'Microsoft SQL Server Management Studio'
								,'Microsoft SQL Server Management Studio - Transact-SQL IntelliSense'
								,'Среда Microsoft SQL Server Management Studio - IntelliSense для языка Transact-SQL'
								)
ORDER BY dt_event desc


/* с группировкой


-- таймауты
IF (OBJECT_ID('tempdb..##History_TimeoutsXE') IS NOT NULL) DROP TABLE ##History_TimeoutsXE
;with cte as
(
	SELECT  *  
	FROM [dbo].[History_TimeoutsXE] 
	where Dt_Event > dateadd(dd,-1,getdate()) -- за последний день
)
select TOP 10 
			   count(1) as [count],
   			   [Last_Dt_Event]=(select top 1 max(Dt_Event) FROM [dbo].[History_TimeoutsXE] where  
																								   [server_instance_name] = cte.[server_instance_name]
																								  and [database_name] = cte.[database_name] 
																								  and [session_nt_username] = cte.[session_nt_username]
																								  and [nt_username] = cte.[nt_username]
																								  and [client_hostname] = cte.[client_hostname]
																								  and [client_app_name] = cte.[client_app_name])
			--  ,[session_id]
			 -- ,[duration]
			  ,[server_instance_name]
			  ,[database_name]
			  ,[session_nt_username]
			  ,[nt_username]
			  ,[client_hostname]
			  ,[client_app_name]
			  ,[query]=(select top 1 [sql_text] from [dbo].[History_TimeoutsXE] where  
																					    [server_instance_name] = cte.[server_instance_name]
																					   and [database_name] = cte.[database_name] 
																					   and [session_nt_username] = cte.[session_nt_username]
																					   and [nt_username] = cte.[nt_username]
																					   and [client_hostname] = cte.[client_hostname]
																					   and [client_app_name] = cte.[client_app_name])
--into [##History_TimeoutsXE] 
from cte
where client_app_name not in (
								'Microsoft SQL Server Management Studio'
								,'Microsoft SQL Server Management Studio - Transact-SQL IntelliSense'
								,'Среда Microsoft SQL Server Management Studio - IntelliSense для языка Transact-SQL'
								
								)
group by   --[Dt_Event]
		  --,[session_id]
		  --,[duration]
		  [server_instance_name]
		  ,[database_name]
		  ,[session_nt_username]
		  ,[nt_username]
		  ,[client_hostname]
		  ,[client_app_name]
ORDER BY [count] desc

*/

-- системные ошибки

;with cte as
(
SELECT 
	   [Dt_Event]
      ,[session_id]
      ,[database_name]
      ,[session_nt_username]
      ,[client_hostname]
      ,ClientApp = CASE LEFT(client_app_name, 29)
						WHEN 'SQLAgent - TSQL JobStep (Job '
							THEN 'SQLAgent Job: ' + (SELECT name FROM msdb..sysjobs sj WHERE substring(client_app_name,32,32)=(substring(sys.fn_varbintohexstr(sj.job_id),3,100))) + ' - ' + SUBSTRING(client_app_name, 67, len(client_app_name)-67)
						ELSE client_app_name
						END 
      ,[error_number]
      ,[severity]
      ,[state]
      ,[sql_text]
      ,[message]
  FROM [dbo].[History_SystemErrorsXE]
  where 
	--database_name='pythoness_sbol'
	Dt_Event > dateadd(dd,-1,getdate()) -- за последний день
  
  )
  select  count(1) as [Count]
	   ,[Last_DT_Event]=(select top 1 max([dt_Event]) from [dbo].[History_SystemErrorsXE] where [message] = cte.[message] 
																			and [database_name] = cte.[database_name] 
																			and [session_nt_username] = cte.[session_nt_username]
																			and [client_hostname] = cte.[client_hostname]
																			and [ClientApp] = cte.[ClientApp]
																			and [error_number] = cte.[error_number]
																			and [severity]=cte.[severity]
																			and [state] = cte.[state]
																			)
	  ,[database_name]
      ,[session_nt_username]
      ,[client_hostname]
      ,[ClientApp]
	  ,[error_number]
      ,[severity]
      ,[state]
	  ,[query]=(select top 1 sql_text from [dbo].[History_SystemErrorsXE] where [message] = cte.[message] 
																			and [database_name] = cte.[database_name] 
																			and [session_nt_username] = cte.[session_nt_username]
																			and [client_hostname] = cte.[client_hostname]
																			and [ClientApp] = cte.[ClientApp]
																			and [error_number] = cte.[error_number]
																			and [severity]=cte.[severity]
																			and [state] = cte.[state]
																			)
      ,[message]
  from cte
  where ClientApp not in (
							'SQLAgent Job: History_Blocking - Step 1'
							,'SQLAgent Job: History_WhoIsActive - Step 1'
							,'Microsoft SQL Server Management Studio - Query'
							,'Red Gate Software - SQL Tools'
							,'Среда Microsoft SQL Server Management Studio - запрос'
							)
  group by 
	   [database_name]
      ,[session_nt_username]
      ,[client_hostname]
      ,[ClientApp]
	  ,[error_number]
      ,[severity]
      ,[state]
      ,[message]
  order by [count] desc

GO




-- дедлоки
;with cte as
(
SELECT  * 
FROM [dbo].[History_DeadlocksXE] 
--where dt_log > dateadd(dd,-1,getdate()) -- за последний день
)
select *
from cte
where processClientApp not in ('Red Gate Software - SQL Tools')
ORDER BY dt_log desc

-- дедлоки полученные из XE System_Health
SELECT TOP (1000) *  FROM [dbo].[History_SystemDeadlocksXE] ORDER BY dt_log


/*
alter table master.guest.beta_lockinfo alter column appl nvarchar(256)

String or binary data would be truncated in table 'master.guest.beta_lockinfo', column 'appl'. Truncated value: 'SQL Agent - TSQL JobStep (Job [Pythoness_Transport_SEND_SBFAShare [Pythoness_Transport]] [Akomlev]] '.
*/