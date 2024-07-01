RETURN
;
/*
IF OBJECT_ID (N'ssd.dbo.[03082020]', N'U') IS NOT NULL
	DROP TABLE ssd.dbo.[03082020];	


-- Вариант №1 (медленный)
;
WITH events_cte AS
(
    SELECT 
		--xevents.event_data.value('(event/@timestamp)[1]', 'datetime2') AS [datetime_utc],
		CONVERT(datetime2,SWITCHOFFSET(CONVERT(datetimeoffset,xevents.event_data.value('(event/@timestamp)[1]', 'datetime2')),DATENAME(TzOffset, SYSDATETIMEOFFSET()))) AS datetime_local,
       	xevents.event_data.value('(event/@name)[1]', 'varchar(50)') AS event_type,
		xevents.event_data.value('(event/action[@name="session_id"]/value)[1]', 'bigint') AS session_id,
		xevents.event_data.value('(event/data[@name="statement"]/value)[1]', 'nvarchar(4000)') AS statement,
		xevents.event_data.value('(event/data[@name="duration"]/value)[1]', 'bigint')/1000 AS duration_ms,
		xevents.event_data.value('(event/data[@name="cpu_time"]/value)[1]', 'bigint')/1000 AS cpu_time_ms,
		xevents.event_data.value('(event/data[@name="physical_reads"]/value)[1]', 'bigint') AS physical_reads,
		xevents.event_data.value('(event/data[@name="logical_reads"]/value)[1]', 'bigint') AS logical_reads,
		xevents.event_data.value('(event/data[@name="writes"]/value)[1]', 'bigint') AS writes,
		xevents.event_data.value('(event/data[@name="row_count"]/value)[1]', 'bigint') AS row_count,
		xevents.event_data.value('(event/action[@name="database_name"]/value)[1]', 'varchar(255)') AS database_name,
		xevents.event_data.value('(event/action[@name="client_hostname"]/value)[1]', 'varchar(255)') AS client_hostname,
		xevents.event_data.value('(event/action[@name="client_app_name"]/value)[1]', 'varchar(255)') AS client_app_name
    FROM sys.fn_xe_file_target_read_file
    (
        'J:\Data\EE\LongRunningQuery*.xel'
    ,   'J:\Data\EE\LongRunningQuery*.xem'
    ,   NULL
    ,   NULL) AS fxe
    CROSS APPLY (SELECT CAST(event_data as XML) AS event_data) AS xevents
)
SELECT *
INTO sputnik.dbo.[04082020]
FROM events_cte AS E
*/
-- Вариант №2
IF OBJECT_ID('tempload_ee', 'U') IS NOT NULL 
  DROP TABLE tempload_ee; 

-- convert all .xel files in a given folder to a single-column table
-- (alternatively specify an individual file explicitly)
select event_data = convert(xml, event_data)
	into tempload_ee
from sys.fn_xe_file_target_read_file(N'c:\Program Files\Microsoft SQL Server\MSSQL15.PYTHIA\MSSQL\History_Deadlocks*.xel', null, null, null); -- 




IF OBJECT_ID('#t', 'U') IS NOT NULL 
  DROP TABLE #t; 

IF OBJECT_ID('[LongRunningQuery]', 'U') IS NOT NULL 
  DROP TABLE [LongRunningQuery]; 
  

-- create multi-column table from single-column table, explicitly adding needed columns from xml
SELECT 
  --ts    = event_data.value(N'(event/@timestamp)[1]', N'datetime'),
	CONVERT(datetime2,SWITCHOFFSET(CONVERT(datetimeoffset,event_data.value(N'(event/@timestamp)[1]', N'datetime2')),DATENAME(TzOffset, SYSDATETIMEOFFSET()))) AS datetime_local,
	event_data.value('(event/@name)[1]', 'varchar(50)') AS event_type,
	event_data.value('(event/action[@name="session_id"]/value)[1]', 'bigint') AS session_id,
	event_data.value('(event/data[@name="statement"]/value)[1]', 'nvarchar(max)') AS statement,
	event_data.value('(event/data[@name="duration"]/value)[1]', 'bigint')/1000 AS duration_ms,
	event_data.value('(event/data[@name="cpu_time"]/value)[1]', 'bigint')/1000 AS cpu_time_ms,
	event_data.value('(event/data[@name="physical_reads"]/value)[1]', 'bigint') AS physical_reads,
	event_data.value('(event/data[@name="logical_reads"]/value)[1]', 'bigint') AS logical_reads,
	event_data.value('(event/data[@name="writes"]/value)[1]', 'bigint') AS writes,
	event_data.value('(event/data[@name="row_count"]/value)[1]', 'bigint') AS row_count,
	event_data.value('(event/action[@name="database_name"]/value)[1]', 'varchar(255)') AS database_name,
	event_data.value('(event/action[@name="client_hostname"]/value)[1]', 'varchar(255)') AS client_hostname,
	event_data.value('(event/action[@name="client_app_name"]/value)[1]', 'varchar(255)') AS client_app_name
  --into [LongRunningQuery]
  into tempdb.dbo.[1C_DWH_NAV_query2]
FROM tempload_ee
GO
/*
-- add id
ALTER TABLE PexTrace_20170526
ADD eventId INT IDENTITY;

-- set id as PK
ALTER TABLE PexTrace_20170526
ADD CONSTRAINT PK_PexTrace_20170526 PRIMARY KEY(eventId);
*/


CREATE CLUSTERED INDEX CI_datetime_local ON tempdb.dbo.[LongRunningQuery](session_id,datetime_local) with(DATA_COMPRESSION=PAGE)

PRINT 'Load done'
--------------------------------------------
CREATE CLUSTERED INDEX CI_datetime_local ON #t(session_id,datetime_local) with(DATA_COMPRESSION=PAGE)

SELECT * 
from tempdb.dbo.[1C_DWH_NAV_query2]
--WHERE database_name='Pegasus2008BB'
ORDER BY datetime_local DESC


SELECT  database_name,COUNT(*) 
from sputnik..[sdc_ee]
--WHERE datetime_local > '2020-11-12 17:40'
GROUP BY database_name
ORDER BY COUNT(*)  DESC


SELECT  * from sputnik..xe_Document33767
WHERE statement LIKE '%INSERT INTO dbo._Document33767_VT48001%'
ORDER BY datetime_local desc



CREATE  INDEX IX_statement ON SSD.dbo.[s-dcr-sql-05_03122019](statement)with(DATA_COMPRESSION=PAGE)

GO

sys.sp_MScdc_cleanup_job

SELECT min(datetime_local),max(datetime_local) FROM master..[LongRunningQuery_n25]
SELECT min(datetime_local),max(datetime_local) FROM master..[LongRunningQuery_n50]
SELECT min(datetime_local),max(datetime_local) FROM master..[LongRunningQuery_n75]
SELECT min(datetime_local),max(datetime_local) FROM master..[LongRunningQuery_n75_ix]

SELECT min(datetime_local) AS [Min_Date],max(datetime_local) AS [Max_Date],Sum(cpu_time_ms) AS [Sum_Cpu] FROM SSD.[dbo].[s-sqlmv-03_201119]
SQLAgent - TSQL JobStep (Job 0x987703D39E09E841950749BC11AE9431 : Step 1)

-- с группировкой
SELECT 
	 Top 15
	 /*CASE 
		WHEN len([statement]) = 0 THEN client_app_name
		when [statement] like '%0x987703D39E09E841950749BC11AE9431%' then 'Job'
		ELSE [statement]
	end AS query, */
	[statement] AS query,
	 database_name AS db,COUNT(*) AS 'count',avg(duration_ms) AS avg_duration_ms,avg(logical_reads) AS avg_reads,avg(writes) AS avg_writes,avg(cpu_time_ms) AS avg_cpu, avg(row_count) AS 'avg_row_count'
	-- ,SampleDT=(SELECT TOP 1 datetime_local from  ssd.dbo.[s-dcr-sql-05_181119_part] q2 WHERE q2.statement = q1.statement)
FROM
   master..[LongRunningQuery] q1
WHERE 1=1
	--datetime_local BETWEEN '2020-07-27 12:10:00' and '2020-07-27 12:30:00'
	--	AND DateAdd(day,0,DateDiff(day,0,getdate()))
		--[statement] NOT LIKE '%#tt328%'
		--[statement] LIKE '%sp_detach_db%'
		-- session_id = 240 and 
		-- len([statement]) > 0
		--and datetime_local > '2019-11-06 17:15' -- поменял фильтр cpu на 200ms
GROUP BY statement, database_name, client_app_name
--HAVING avg(cpu_time_ms) > 41562
ORDER BY 
		--count(*) desc, 
		avg_cpu DESC
		--avg(duration_ms) desc
		--avg(row_count) desc
		--avg(writes)+avg(logical_reads) desc
		--count(*) desc, 
		--avg(cpu_time_ms) DESC
*/

-- список запросов

SELECT 
	 datetime_local,
	 CASE 
		WHEN len([statement]) = 0 THEN client_app_name
		ELSE [statement]
	end AS query, 
	--[statement] AS query,
	 database_name AS db,session_id,duration_ms,logical_reads,writes,cpu_time_ms,row_count
	-- SampleDT=(SELECT TOP 1 datetime_local from  ssd.dbo.[s-dcr-sql-05_131119] q2 WHERE q2.statement = q1.statement)
FROM
   #t q1
WHERE 
	--datetime_local BETWEEN '2020-03-16 16:42:00' and '2020-03-16 16:44:00'
		--datetime_local BETWEEN '2020-03-16 16:00:00' and '2020-03-16 17:00:00'

	--	AND DateAdd(day,0,DateDiff(day,0,getdate()))
		---AND [statement] = 'COMMIT TRANSACTION' 
		--[statement] not LIKE '%#tt%' AND 
		  session_id = 1600
		--and duration_ms > 6000
		--and database_name = 'Pegasus2008MS'
		--and datetime_local > '2019-11-06 17:15' -- поменял фильтр cpu на 200ms
ORDER BY 
		datetime_local desc
		--cpu_time_ms
		--duration_ms desc





SELECT DISTINCT db


-- нагрузка по часам
SELECT   DATEPART(hh, datetime_local) AS [minute], count(1) AS [QueryCount]
--into #t2
FROM
    ssd.dbo.[s-dcr-sql-05_181119] q1
	--WHERE datetime_local BETWEEN '2019-11-19 19:00:00' and '2019-11-19 19:30:00'
GROUP BY 
	DATEPART(hh, datetime_local)
ORDER BY 
	DATEPART(hh, datetime_local)

	SELECT max([QueryCount])
	FROM #t2


-- Базы, средние значения по Кол-ву запросов, CPU, Длительностью запросов, reads, writes
Select 
	 database_name AS db,COUNT(*) AS 'count',avg(cpu_time_ms) AS avg_cpu,avg(duration_ms) AS avg_duration_ms,avg(logical_reads) AS avg_reads,avg(writes) AS avg_writes
from SSD.dbo.[s-sqlmv-03_13032020] q1
WHERE q1.database_name = 'Pegasus2008MS'
group by database_name
order by avg(cpu_time_ms)  DESC



Select 
	 database_name AS db,COUNT(*) AS 'count',sum(cpu_time_ms) AS sum_cpu,sum(duration_ms) AS sum_duration_ms,sum(logical_reads) AS sum_reads,sum(writes) AS sum_writes
from 
	SSD.dbo.[s-sqlmv-03_13032020] 
	WHERE database_name =N'Pegasus2008MS'
group by database_name




exec sp_executesql N'INSERT INTO #tt187 WITH(TABLOCK) (_Q_001_F_000RRef, _Q_001_F_001RRef, _Q_001_F_002RRef, _Q_001_F_003, _Q_001_F_004) SELECT T1._Fld32657RRef, T1._Fld32658RRef, T1._Fld32659RRef, T1._Fld32663, CAST(SUM(T1._Fld32665) AS NUMERIC(27, 8)) FROM dbo._InfoRg32655 T1 INNER JOIN #tt184 T2 WITH(NOLOCK) ON ((T1._Fld32657RRef = T2._Q_001_F_000RRef) AND (T1._Fld32658RRef = T2._Q_001_F_005RRef)) WHERE (T1._Period < @P1) GROUP BY T1._Fld32657RRef, T1._Fld32658RRef, T1._Fld32659RRef, T1._Fld32663 HAVING (CAST(SUM(T1._Fld32665) AS NUMERIC(27, 8)) <> 0.0)',N'@P1 datetime2(3)','2019-11-06 00:00:00'

SELECT *
FROM  ssd.dbo.[s-dcr-sql-05_131119]
WHERE 
	--datetime_local ='2019-11-12 23:48:14.2220000'
	AND [statement] LIKE N'%#tt237%'
	and session_id =1121
	--AND duration_ms > 5000
ORDER BY datetime_local



-- =====================================================================

DECLARE @dt datetime2 = '2019-11-14 11:49:21.0280000'

SELECT *
FROM ssd.dbo.[s-sqlmv-03_141119_part]
WHERE 
	datetime_local BETWEEN dateadd(mi,-10,@dt) AND @dt
	--AND test.dbo.[sqlmvao].database_name='Pegasus2008'
	AND [statement] LIKE N'%#tt237%'
	--AND duration_ms > 5000
	--AND session_id=1619
ORDER BY datetime_local

SQLAgent - TSQL JobStep (Job 0x1DACB57C139FE046B4A9C12E2EA1AC6C : Step 1)
SQLAgent - TSQL JobStep (Job 0x987703D39E09E841950749BC11AE9431 : Step 1)

SELECT * FROM msdb.dbo.sysjobs WHERE Job_ID = 0x1DACB57C139FE046B4A9C12E2EA1AC6C
SELECT * FROM msdb.dbo.sysjobs WHERE Job_ID = 0x987703D39E09E841950749BC11AE9431




SELECT 
	 [statement],min(duration_ms), max(duration_ms),avg(duration_ms)
FROM
   SSD.dbo.[s-sqlmv-03_16032020-part] q1
WHERE 
	datetime_local BETWEEN '2020-03-16 16:00:00' and getdate()
	--	AND DateAdd(day,0,DateDiff(day,0,getdate()))
		AND [statement] = 'COMMIT TRANSACTION' 
		--[statement] not LIKE '%#tt%' AND 
		--AND  session_id = 1731
		--and database_name = 'Pegasus2008MS'
		--and datetime_local > '2019-11-06 17:15' -- поменял фильтр cpu на 200ms
GROUP BY [statement]
