RETURN
go

select top 10 * from master.[dbo].[History_WhoIsActive]  cur
where 
		sql_text like '%pMassSendingSendMessages%'
		and query_plan is not null

select min(collection_time),max(collection_time) from dbo.[History_WhoIsActive] with(nolock)



-- последняя активность на сервере
SELECT top 500 
		collection_time as [dt], *
  FROM [dbo].[History_WhoIsActive] -- указываем нужную таблицу 
where 
	1=1
		--database_name = 'Pythoness_OD'
		--SQL_text like '%1C_DWH_NAV%'
		--and blocking_session_id is not null
		--wait_info like '%resource%'
		--and  collection_time between '2024-04-18 00:00' and '2024-04-18 10:18'
  ORDER BY 
		--count(1) desc
		collection_time desc
		--cpu desc



USE master

-- top queries
SELECT TOP 100
	count_big(1) AS 'count'
	--,sql_text
	,SQL_command
	,avg(cast(cpu as bigint)) AS 'avgCPU'
	,avg(reads) AS 'avgReads'
	,avg(writes) AS 'avgWrites'
	--,QueryPlan=(SELECT TOP 1 [query_plan] FROM dbo.[History_WhoIsActive] (READPAST) WHERE sql_text = w.sql_text AND [query_plan] IS NOT null)
FROM    dbo.[History_WhoIsActive] w (READPAST)
GROUP BY 
		--sql_text,
		SQL_command
		
ORDER BY 
		--count(1) desc
		avgCPU desc


-- просмотр плана
SELECT  top 300 collection_time,sql_text,sql_command,query_plan,cpu,reads,writes,
CASE
		WHEN DATEDIFF(hour, w.start_time, w.collection_time) > 576 THEN
			DATEDIFF(second, w.collection_time, w.start_time)
		ELSE DATEDIFF(ms, w.start_time, w.collection_time)
END AS duration,
start_time, w.collection_time
FROM    dbo.[History_WhoIsActive] w (READPAST)
where 
	sql_command  like  '%pcalcClientRiskLevelHistory%' 
	and collection_time between '2024-03-04' and '2024-03-10 23:59:59'
	--and sql_command not like '%ExpiredPassports%'
	--and sql_command not like '%pall]'
	--and sql_command not like '%ppfDocumentAttachmentDataToFile%'
	order by 
			w.collection_time desc
			--writes desc


--drop table master.dbo.[report_History_WhoIsActive_20231225-20231231] 
-- ==================================================================================================================

select min(collection_time),max(collection_time)

FROM    dbo.[History_WhoIsActive] w (READPAST)

select count(*)from dbo.[History_WhoIsActive]

--drop table master.dbo.[report_History_WhoIsActive_20240617-20240623]

-- второй вариант
;with cte
as
(
	SELECT *,
	CASE
			WHEN DATEDIFF(hour, w.start_time, w.collection_time) > 576 THEN
				DATEDIFF(second, w.collection_time, w.start_time)
			ELSE DATEDIFF(ms, w.start_time, w.collection_time)
			END AS duration,
			case
				when sql_command like 'execute \[dataflow\].\[pexpOperationsToLK\]%' ESCAPE '\' then 'exec [dataflow].[pexpOperationsToLK]' 
				when sql_command like '%EXECUTE \[compliance\].\[pUNListLoad\]%' ESCAPE '\' then 'EXECUTE [compliance].[pUNListLoad]' 
				when sql_command like 'exec Analytics.pexpCompensationROT%' then 'exec Analytics.pexpCompensationROT' 
				when sql_command like 'execute \[dataflow\].\[pexpAutoPrintedFilesToLK\]%' ESCAPE '\' then 'execute [dataflow].[pexpAutoPrintedFilesToLK]' 
				when sql_command like 'execute \[dataflow\].\[pexpAccountCloseOperationsToLK\]%' ESCAPE '\' then 'execute [dataflow].[pexpAccountCloseOperationsToLK]' 
				when sql_command like 'execute \[dataflow\].\[pexpAccountOperationsToLK\]%' ESCAPE '\' then 'execute [dataflow].[pexpAccountOperationsToLK]' 
				when sql_command like 'set fmtonly off; exec \[dataflow\].\[pexpAnalyticsPifClaims\]%' ESCAPE '\' then 'exec [dataflow].[pexpAnalyticsPifClaims]' 
				when sql_command like 'execute  \[dataflow\].\[pexpClientsToLK\]%' ESCAPE '\' then 'execute [dataflow].[pexpClientsToLK]' 
				when sql_command like 'execute  \[dataflow\].\[pexpUserAccountPersonData\]%' ESCAPE '\' then 'execute [dataflow].[pexpUserAccountPersonData]' 
				when sql_command like 'execute  \[dataflow].\[pexpSBOLDataMartPifClaims\]%' ESCAPE '\' then 'execute [dataflow].[pexpSBOLDataMartPifClaims]' 
				when sql_command like 'exec \[dbo\].\[pkernTrusteeRead\]%' ESCAPE '\' then 'exec [dbo].[pkernTrusteeRead]' 
				when sql_command like 'exec ppfDocumentReadBlob%' ESCAPE '\' then 'exec ppfDocumentReadBlob' 
				when sql_command like 'exec \[sbrfOU\].\[pOUnitStatesRead\]%' ESCAPE '\' then 'exec [sbrfOU].[pOUnitStatesRead]' 
				when sql_command like 'execute  \[dataflow\].\[pexpAccountsToLK\]%' ESCAPE '\' then 'execute  [dataflow].[pexpAccountsToLK]' 
				when sql_command like 'execute \[dataflow\].\[pexpSBOLDataMartPifInvestmentPayments\]%' ESCAPE '\' then 'execute [dataflow].[pexpSBOLDataMartPifInvestmentPayments]' 
				when sql_command like '%exec \[dataflow\].\[pexpCDIDataMartPIFIAContact\]%' ESCAPE '\' then 'exec [dataflow].[pexpCDIDataMartPIFIAContact]' 
				when sql_command like 'execute  \[dataflow\].\[pexpSBOLDataMartClientDocumentsHistory\]%' ESCAPE '\' then 'execute [dataflow].[pexpSBOLDataMartClientDocumentsHistory]' 
				when sql_command like 'execute  \[dataflow\].\[pexpSBOLDataMartCurrencyRates\]%' ESCAPE '\' then 'execute [dataflow].[pexpSBOLDataMartCurrencyRates]' 
				when sql_command like 'exec \[Pythoness_buf\].\[check\].\[pBalanceDifference\]%' ESCAPE '\' then 'exec [Pythoness_buf].[check].[pBalanceDifference]' 
				when sql_command like 'exec \[dbo\].\[ppfDocumentMarkAsPrintedByUID\]%' ESCAPE '\' then 'exec [dbo].[ppfDocumentMarkAsPrintedByUID]' 
				when sql_command like 'exec \[dbo\].\[ppfDocumentReadByUID\]%' ESCAPE '\' then 'exec [dbo].[ppfDocumentReadByUID]' 
				when sql_command like 'execute \[dataflow\].\[pexpSberbankCSDDataMartPifAgentsCompensation\]%' ESCAPE '\' then 'exec [dataflow].[pexpSberbankCSDDataMartPifAgentsCompensation]' 
				when sql_command like 'exec \[dataflow\].\[pCheckFile2NDFLDataById\]%' ESCAPE '\' then 'exec [dataflow].[pCheckFile2NDFLDataById]' 
				when sql_command like 'exec \[dataflow\].\[pexp2NDFLToLK\]%' ESCAPE '\' then 'exec [dataflow].[pexp2NDFLToLK]' 
				else sql_command
			end as case_command
	FROM   dbo.[History_WhoIsActive] w (READPAST)
	where collection_time between '2024-06-24' and '2024-06-30 23:59:59'  -- поменять здесь
	and (cast(sql_command  as nvarchar(max)) not like '%DatabaseBackup%' and cast(sql_command  as nvarchar(max)) not like '%IndexOptimize%' and cast(sql_command  as nvarchar(max)) not like '%sys.sp_MScdc_capture_job%' and cast(sql_command  as nvarchar(max)) not like '%sp_trace_getdata%' and  cast(sql_command  as nvarchar(max)) not like '%sp_server_diagnostics%' and  cast(sql_command  as nvarchar(max)) not like '%sys.sp_reset_connection;1%')
	
)
 SELECT 
	count_big(1) AS 'count'
	--,sql_command
		,case_command as [sql_command]
	--,case
	--	when cast(sql_command as nvarchar(512)) like '%pexpOperationsToLK' then '1'
	--	else sql_command
	--end as case_command
	,iif(avg(cast(duration as bigint)) > 0, avg(cast(duration as bigint)), 0) AS 'avgDurationMS'
	,avg(cast(trim(replace(isnull(cpu,0),',','')) as bigint)) AS 'avgCPU'
	,avg(cast(trim(replace(isnull(reads,0),',','')) as bigint)) AS 'avgReads'
	,avg(cast(trim(replace(isnull(writes,0),',','')) as bigint)) AS 'avgWrites'
	,iif(sum(cast(duration as bigint)) > 0, sum(cast(duration as bigint)), 0) AS 'sumDurationMS'
	,sum(cast(trim(replace(isnull(cpu,0),',','')) as bigint)) AS 'sumCPU'
	,sum(cast(trim(replace(isnull(reads,0),',','')) as bigint)) AS 'sumReads'
	,sum(cast(trim(replace(isnull(writes,0),',','')) as bigint)) AS 'sumWrites'
	--,QueryPlan=(SELECT TOP 1 [query_plan] FROM dbo.[History_WhoIsActive] (READPAST) WHERE sql_text = w.sql_text AND [query_plan] IS NOT null)
--into master.dbo.[report_History_WhoIsActive_20240624-20240630] -- поменять здесь
FROM  cte 
GROUP BY 
		--sql_text,
		case_command
ORDER BY 
		--count(1) desc
		avgCPU desc
		--avgReads desc




-- сравнение с предыдущим периодом	
select  prev.count as [prev_Count]
	,prev.SQL_command as [prev_SQLCommand]
	--,prev.sumDurationMS as [prev_sumDurationMS]
	,prev.sumCPU as [prev_sumCPU]
	--,prev.sumReads as [prev_sumReads]
	--,prev.sumWrites as [prev_sumWrites]
	,cur.count as [cur_Count]
	,cur.sql_command as [cur_SQLCommand]
	--,cur.sumDurationMS as [cur_sumDurationMS]
	,cur.sumCPU as [cur_sumCPU]
	--,cur.sumReads as [cur_sumReads]
	--,cur.sumWrites as [cur_sumWrites]
	-- (cur.avgCpu/iif(prev.avgCpu = 0, 1, prev.avgCpu))*100 as [avgCpu%] -- Разницу между значениями делим на первоначальное и умножаем на 100
from master.dbo.[report_History_WhoIsActive_20240617-20240623] cur 
	left join master.dbo.[report_History_WhoIsActive_20240610-20240616] prev  
	on left(cur.SQL_command, 800) = left (prev.SQL_command, 800) -- 80
where   
		cur.sumCPU > prev.sumCPU
		--cur.sumDurationMS > prev.sumDurationMS 
		---cur.avgReads > prev.avgReads
		--cur.sumWrites > prev.sumWrites
		--cur.Count > prev.count
		--and cur.sql_command like'%ppfGetDocumentListForPrinting%'
order by 
		cur.sumCPU desc
		--cur.sumDurationMS desc
		--cur.sumReads desc
		--cur.sumWrites desc
		--cur.count desc


-- ============ После переключения нод
select sum(count) as [count]
	   ,[sql_command]
	   ,avg(avgDurationMS) as [avgDurationMS]
	   ,avg(avgCPU) as [avgCPU]
	   ,avg(avgReads) as [avgReads]
	   ,avg(avgWrites) as [avgWrites]
	   ,sum(sumDurationMS) as [sumDurationMS]
	   ,sum(sumCPU) as [sumCPU] 
	   ,sum(sumReads) as [sumReads]
	   ,sum(sumWrites) as [sumWrites]

from (
select * from [report_History_WhoIsActive_20231113-20231119_p1]
union all
select * from [report_History_WhoIsActive_20231113-20231119]
) a
GROUP BY 
		--sql_text,
		sql_command
order by avgCPU desc


-- поиск нужного запроса

select --top 10
	   collection_time as [dt], 
	   [session_id]
      ,[sql_text] --='ppfDocumentMarkAsPrintedByUID'
      ,[sql_command]--='ppfDocumentMarkAsPrintedByUID'
      ,[login_name]
      ,[wait_info]
      ,[tasks]
      ,[tran_log_writes]
      ,[CPU]
      ,[tempdb_allocations]
      ,[tempdb_current]
      ,[blocking_session_id]
      ,[blocked_session_count]
      ,[reads]
      ,[writes]
      ,[context_switches]
      ,[physical_io]
      ,[physical_reads]
      ,[query_plan]--=''
      ,[used_memory]
      ,[max_used_memory]
      ,[requested_memory]
      ,[granted_memory]
      ,[status]
      ,[tran_start_time]
      ,[implicit_tran]
      ,[open_tran_count]
      ,[percent_complete]
      ,[host_name]
      ,[database_name]
      ,[program_name]
      ,[additional_info]=''
      ,[memory_info]
      ,[start_time]
      ,[login_time]
      ,[request_id]
    
from [dbo].[History_WhoIsActive]  cur with(nolock)
where 
		--sql_command like N'%pCheckFile2NDFLDataById%'
	--	sql_command like '%ppfDocumentMarkAsPrintedByUID%'
		--sql_command like '%ppfDocumentReadByUID%'
		--sql_text like N'%узнать%'
		sql_command like N'%45420b4e-3270-11ef-908d-0050560a3442%'
		and collection_time between '2024-06-24' and '2024-06-30 23:59:59'
		--and login_name <> 'SFN\vzheltonogov.adm'
order by 
		collection_time desc

==============================================================================================================================================


-- ====================================================================================






select min(collection_time), max(collection_time) from [dbo].[History_WhoIsActive] with(nolock)

-- последняя активность
select top 5000
	login_name,collection_time as [dt],
	CASE
		WHEN DATEDIFF(hour, w.start_time, w.collection_time) > 576 THEN
			DATEDIFF(second, w.collection_time, w.start_time)
		ELSE DATEDIFF(ms, w.start_time, w.collection_time)
		END AS duration,
	   [session_id],[sql_text],[sql_command],[status],[wait_info],[blocking_session_id],[tran_log_writes],[CPU],[reads],[writes],[physical_reads],[used_memory],[tempdb_allocations]
      ,[tempdb_current],[login_name],[query_plan],[tran_start_time],[open_tran_count],[percent_complete],[host_name],[database_name],[program_name],[additional_info],[start_time],[login_time]
      ,[request_id],[collection_time]
from [dbo].[History_WhoIsActive] w
where 
--sql_command like '%exec dbo.pSendMessageEmployeeId%'
   --SELECT TOP (5) DocumentBodyXML, *    FROM [Pythoness_SBOL].[support].[vDocuments]    where --[DocumentTypeCode] = 'Ф19а' and    convert(varchar(max), [DocumentBodyXML]) like '%Foreign%'    --convert(varchar(max), [DocumentBodyXML]) like '%SalesMan%'    order by [_DateCreate] DESC
--and sql_command not in( 'sys.sp_reset_connection;1','sys.sp_MScdc_capture_job','tempdb.dbo.RG_WhatsChanged_v4;1','msdb.dbo.sp_readrequest;1','EXEC sp_server_diagnostics 10','EXEC sp_server_diagnostics 20')
--and 
--collection_time between '2023-11-25 09:00' and '2023-11-25 09:59:59' 
-- ожидания на Tempdb
--and wait_info like '%tempdb%gam%'
-- and query_plan is not null
	--and collection_time between '2023-07-30 22:50:00' and '2023-07-30 23:05:54' -- n25
	--collection_time between '2023-01-11 14:43:23' and '2023-01-11 14:57:40' -- n50
	--collection_time between '2023-01-11 15:00:23' and '2023-01-11 15:25:10' -- n75
	--collection_time between '2023-01-11 16:44:23' and '2023-01-11 17:04:55' -- n75_2
	--collection_time between '2023-01-11 18:09:00' and '2023-01-11 18:15:00' -- n75_IX
--and collection_time > dateadd(hh,-12,getdate())
--and sql_text like 'update statistics%'
--and collection_time between '2023-07-05 14:30' and '2023-07-05 15:30'
--and [login_name] ='winter'
--and blocking_session_id is not null
--and sql_command ='Pythoness_buf.dbo.pExpiredPassportsUpdate;1'
order by 
		collection_time desc
		--cpu desc
		--writes desc
		
		
-- сравнение планов по 2-ум периодам
select top 10 * from [dbo].[History_WhoIsActive] cur
where sql_command like '%pMassSendingSendMessages%'
and collection_time between '2023-02-06' and '2023-02-12 23:59:59'
order by reads desc
--union all
select top 10 * from [dbo].[History_WhoIsActive] cur
where sql_command like '%pMassSendingSendMessages%'
and collection_time between '2023-01-30' and '2023-02-05 23:59:59'
order by reads desc

-- список ожиданий
select  
	substring(wait_info,charindex(')',wait_info)+1, len(wait_info) - charindex(wait_info,')')) as [wait_info], count(1)
from [dbo].[History_WhoIsActive]
where 
	wait_info is not null
	and wait_info not like('%SP_SERVER_DIAGNOSTICS_SLEEP')
and collection_time between '2023-07-05 14:30' and '2023-07-05 15:30' -- n25
group by 
	substring(wait_info,charindex(')',wait_info)+1, len(wait_info) - charindex(wait_info,')'))
order by 
		count(1) desc

-- поиск запросов с нужным ожиданием
select top 500 
	collection_time as [dt],
	CASE
		WHEN DATEDIFF(hour, w.start_time, w.collection_time) > 576 THEN
			DATEDIFF(second, w.collection_time, w.start_time)
		ELSE DATEDIFF(ms, w.start_time, w.collection_time)
		END AS duration,
	   [session_id],[sql_text],[sql_command],[status],[wait_info],[blocking_session_id],[tran_log_writes],[CPU],[reads],[writes],[physical_reads],[used_memory],[tempdb_allocations]
      ,[tempdb_current],[login_name],[query_plan],[tran_start_time],[open_tran_count],[percent_complete],[host_name],[database_name],[program_name],[additional_info],[start_time],[login_time]
      ,[request_id],[collection_time]
from [dbo].[History_WhoIsActive] w
where 1=1
--sql_command not in( 'sys.sp_reset_connection;1','sys.sp_MScdc_capture_job','tempdb.dbo.RG_WhatsChanged_v4;1','msdb.dbo.sp_readrequest;1','EXEC sp_server_diagnostics 10')

	--and collection_time between '2023-01-31 14:14:00' and '2023-01-31 14:20:54' -- n25
	--and collection_time between '2023-01-31 14:33:23' and '2023-01-31 14:40:40' -- n50
	--collection_time between '2023-01-11 15:00:23' and '2023-01-11 15:25:10' -- n75
	--collection_time between '2023-01-11 16:44:23' and '2023-01-11 17:04:55' -- n75_2
	--collection_time between '2023-01-11 18:09:00' and '2023-01-11 18:15:00' -- n75_IX

	--and substring(wait_info,charindex(')',wait_info)+1, len(wait_info) - charindex(wait_info,')')) = 'LCK_M_S'
	--and session_id=93
order by 
		collection_time 

--and 
--wait_info like '%resource_semaphore'

;with cte 
as
(
SELECT top 100 *,
CASE
		WHEN DATEDIFF(hour, w.start_time, w.collection_time) > 576 THEN
			DATEDIFF(second, w.collection_time, w.start_time)
		ELSE DATEDIFF(ms, w.start_time, w.collection_time)
		END AS duration 
FROM    dbo.[History_WhoIsActive] w (READPAST)
where 
 collection_time between '2022-07-15' and '2022-07-15 23:59:59'
 and program_name like 'Service Broker%'
--collection_time > '2022-02-04' -- between '2022-01-17' and '2022-01-23'
--and wait_info like '%resource_semaphore'
)
select duration as dur,* from cte order by duration desc


order by collection_time desc


select *
FROM    dbo.[History_WhoIsActive] w (READPAST)
where 
collection_time between '2022-02-28 06:15' and '2022-02-28 06:20'
order by cpu desc



-- Perfomance Report


-- Запрос для отчета


;with cte
as
(
SELECT    sql_text, sql_command, cpu, reads,writes,
CASE
		WHEN DATEDIFF(hour, w.start_time, w.collection_time) > 576 THEN
			DATEDIFF(second, w.collection_time, w.start_time)
		ELSE DATEDIFF(ms, w.start_time, w.collection_time)
END AS duration
, cast(start_time as  date) as [Day]
FROM    dbo.[History_WhoIsActive] w (READPAST)
where 
			sql_command is not null
			and sql_command not like '%sp_trace%' and sql_command <> 'sys.sp_reset_connection;1' and sql_command <> 'msdb.dbo.sp_readrequest;1' and sql_command not like 'EXECUTE dbo.IndexOptimize%'
			and sql_command <> 'tempdb.dbo.RG_WhatsChanged_v4;1' and sql_command not like '%History%' and sql_command <> 'sys.sp_MScdc_capture_job' and sql_command not like '%xp_readerrorlog%' 
			and sql_command not like '%DatabaseBackup%' and sql_command not like 'BACKUP DATABASE%' and sql_command not like '%DatabaseIntegrityCheck%' and sql_command not like '%COMMIT TRANSACTION%'
			and sql_command not like '%shrinkdatabase%'
)
select sql_text, sql_command, min([Day]) as [minDay], max([Day]) as [maxDay], max(diffDuration) as [maxDiffDuration]
from (
	SELECT    sql_text, sql_command, avg(cast(cpu as bigint)) as[avgCpu], avg(cast(reads as bigint)) as [avgReads],avg(cast(writes as bigint)) as [avgWrites], avg(cast(duration as bigint)) as [avgDuration], [Day]
	,row_number() over (partition by sql_text, sql_command order by [day]) as [RowNum],
	--min(avg(cast(duration as bigint))) over (partition by sql_text, sql_command order by [day]) as [minDuration],
	--max(avg(cast(duration as bigint))) over (partition by sql_text, sql_command order by [day]) as [maxDuration],
	-- определяем разницу между min и max
	-- duration
	max(avg(cast(duration as bigint))) over (partition by sql_text, sql_command order by [day]) - min(avg(cast(duration as bigint))) over (partition by sql_text, sql_command order by [day]) as [diffDuration]
	from cte
	group by  sql_text, sql_command, [Day]

)q
where [diffDuration] > 200 -- те записи, где разница между минимальным и макс значением больше указанного
group by sql_text, sql_command
order by  max(diffDuration) desc

-- просмотр статистики процедуры
;with cte
as
(
SELECT    sql_text, sql_command, cpu, reads,writes,
CASE
		WHEN DATEDIFF(hour, w.start_time, w.collection_time) > 576 THEN
			DATEDIFF(second, w.collection_time, w.start_time)
		ELSE DATEDIFF(ms, w.start_time, w.collection_time)
END AS duration
, cast(start_time as  date) as [Day]
FROM    dbo.[History_WhoIsActive] w (READPAST)
)

SELECT    sql_text, sql_command, avg(cast(cpu as bigint)) as[avgCpu], avg(cast(reads as bigint)) as [avgReads],avg(cast(writes as bigint)) as [avgWrites], avg(cast(duration as bigint)) as [avgDuration], [Day]
,row_number() over (partition by sql_text, sql_command order by [day]) as [RowNum],
min(avg(cast(duration as bigint))) over (partition by sql_text, sql_command order by [day]) as [minDuration],
max(avg(cast(duration as bigint))) over (partition by sql_text, sql_command order by [day]) as [maxDuration],
max(avg(cast(duration as bigint))) over (partition by sql_text, sql_command order by [day]) - min(avg(cast(duration as bigint))) over (partition by sql_text, sql_command order by [day]) as [diffDuration]
from cte
where 
		sql_command like '%pImpOrgStructureFromFile%'

group by  sql_text, sql_command, [Day]
order by sql_text, sql_command, [day]



select distinct [HOST_NAME]
from [dbo].[History_WhoIsActive] with(nolock) 

-- кол-во запросов в сутки

select  cast([collection_time] as date) as [dt]
		, count(1) as [count]
from [dbo].[History_WhoIsActive] with(nolock) 
group by cast([collection_time] as date)
order by 
		--count(1) desc
		cast([collection_time] as date) desc


-- блокировки
;with blocking_cte
as
(
	select 
	blocking_session_id
	,count(1) as [blocking_count]
	from [dbo].[History_WhoIsActive] cur
	where sql_command not in( 'sys.sp_reset_connection;1','sys.sp_MScdc_capture_job','tempdb.dbo.RG_WhatsChanged_v4;1','msdb.dbo.sp_readrequest;1','EXEC sp_server_diagnostics 10')
			and collection_time >= dateadd(hh,-2,getdate())
			and blocking_session_id is not null
	group by 
			blocking_session_id
),Queries_cte
as
(
	select 
		collection_time as [dt],sql_text,sql_command,login_name,host_name,wait_info,cpu,reads,writes,session_id,blocking_session_id,query_plan
	from [dbo].[History_WhoIsActive] cur
	where sql_command not in( 'sys.sp_reset_connection;1','sys.sp_MScdc_capture_job','tempdb.dbo.RG_WhatsChanged_v4;1','msdb.dbo.sp_readrequest;1','EXEC sp_server_diagnostics 10')
	and collection_time >= dateadd(hh,-2,getdate())
)
select 
	[dt],sql_text,sql_command,login_name,host_name,wait_info,cpu,reads,writes,session_id,b.blocking_count,query_plan
from Queries_cte q
left join blocking_cte b
	on q.session_id = b.blocking_session_id
where 
		blocking_count > 0
		--and dt >= dateadd(hh,-2,getdate())
order by dt desc


