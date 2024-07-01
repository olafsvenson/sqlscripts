/*
		http://www.sqlserver-dba.com/2015/08/find-table-scans-in-query-plan-cache.html
*/
-- DECLARE @Table_Name sysname = 'IncomingDocumentOperation';

IF OBJECT_ID('tempdb..#t', 'U') IS NOT NULL
 DROP TABLE tempdb..#t

;WITH XMLNAMESPACES(DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT TOP 100
	--cp.plan_handle
	operators.value('(TableScan/Object/@Schema)[1]','sysname') AS Schema_Name
	,operators.value('(TableScan/Object/@Table)[1]','sysname') AS Table_Name
	,operators.value('(TableScan/Object/@Index)[1]','sysname') AS Index_Name
	,operators.value('@PhysicalOp','nvarchar(50)') AS Physical_Operator
	,cp.usecounts
	,qp.query_plan
INTO #t
FROM sys.dm_exec_cached_plans cp
	CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
	CROSS APPLY query_plan.nodes('//RelOp') rel(operators)
WHERE 
	operators.value('@PhysicalOp','nvarchar(60)') IN ('Table Scan')
	--AND operators.value('(TableScan/Object/@Table)[1]','sysname') = QUOTENAME(@Table_Name,'[')
	/*
	AND operators.value('(TableScan/Object/@Table)[1]','sysname') IN (
				QUOTENAME('IncomingDocumentOperation','['),
				QUOTENAME('OperationalDay','['),
				QUOTENAME('OperationOfInternalDocumentBase','['),
				QUOTENAME('LegalPerson','['),
				QUOTENAME('Subject','['),
				QUOTENAME('OperationWithAmount','['),
				QUOTENAME('InsuranceDebt','[')
				)
	*/
ORDER BY
		cp.usecounts DESC
OPTION(recompile)

-- ÇÀÏÐÎÑ ¹2 - ÓÇÍÀÅÌ ÐÀÇÌÅÐ ÄËß ÒÀÁËÈÖ ÈÇ ÏÐÅÄ. ÇÀÏÐÎÑÀ

IF OBJECT_ID (N'tempdb..#tables_size', N'U') IS NOT NULL
	DROP TABLE #tables_size;	

create table #tables_size
(
    name varchar(500),
    rows bigint,
    reserved varchar(50),
    data varchar(50),
    index_size varchar(50),
    unused varchar(50)
)



declare @t_name varchar(500)
DECLARE t_cursor CURSOR
    FOR select name from sysobjects where xtype = 'U' AND id IN (select DISTINCT OBJECT_ID(Table_Name) FROM #t)  -- âûáèðàåì òîëüêî òå îáúåêòû äëÿ êîòîðûõ íåò èíäåêñîâ
OPEN t_cursor
FETCH NEXT FROM t_cursor INTO @t_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    insert into #tables_size exec sp_spaceused @t_name
    FETCH NEXT FROM t_cursor INTO @t_name;
END
CLOSE t_cursor;
DEALLOCATE t_cursor;

	--SELECT * FROM #tables_size with (nolock) 


SELECT 
	Schema_Name,
	Table_Name,
	Physical_Operator,
	s.[rows] AS [Rows],
	sum(usecounts) AS 'UseCount'
from #t t
	inner JOIN #tables_size s
		ON  QUOTENAME(s.name) = t.Table_Name COLLATE Cyrillic_General_100_CS_AS
--WHERE 
	--[Schema_Name] IS NOT NULL --OR Table_Name NOT IN ('[fn_basecolsofcomputedpkcol]','[sysarticleupdates]','[syssubscriptions]')
	--Table_Name In ('[IncomingDocumentOperation]','[OperationalDay]','[OperationOfInternalDocumentBase]','[LegalPerson]','[Subject]','[OperationWithAmount]','[InsuranceDebt]')
		 --Table_Name NOT LIKE '[fn%'
	--AND s.rows > 5000
GROUP BY Schema_Name, Table_Name,  Physical_Operator, s.[rows]
ORDER BY 
			sum(usecounts) desc,
			[rows] desc
			








/*
SELECT * 
FROM #t with (nolock) 
order by Table_Name,usecounts desc

WHERE 
	--Table_Name=N'[InsuranceDebt]'
--Table_Name In ('IncomingDocumentOperation','OperationalDay','OperationOfInternalDocumentBase','LegalPerson','Subject','OperationWithAmount','InsuranceDebt')
Table_Name In ('[IncomingDocumentOperation]','[OperationalDay]','[OperationOfInternalDocumentBase]','[LegalPerson]','[Subject]','[OperationWithAmount]','[InsuranceDebt]')

*/