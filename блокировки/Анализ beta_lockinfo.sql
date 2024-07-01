/*
	use pegasus2008ms 
	USE pegasus2008bb
	use pegasus2008
*/

-- alter index [beta_lockinfo_pk] on master.[guest].[beta_lockinfo] rebuild with(compression=page)
-- alter table master.guest.beta_lockinfo alter column appl nvarchar(256)
  
  go

  SELECT 
	right(l.object, len(l.object) - charindex('dbo.', l.object) - len('dbo.')+1 ) AS [object], 
	l.rsctype,
	lock_escalation_desc, 
	count(1) AS [count],
	Records =  (SELECT SUM (row_count) 
			FROM sys.dm_db_partition_stats 
			WHERE object_name(object_id)=right(l.object, len(l.object) - charindex('dbo.', l.object) - len('dbo.')+1 )  
			AND (index_id=0 or index_id=1)),
	Query = 'ALTER TABLE ['+ right(l.object, len(l.object) - charindex('dbo.', l.object) - len('dbo.')+1 )+'] SET (LOCK_ESCALATION = DISABLE);ALTER INDEX ALL ON ['+right(l.object, len(l.object) - charindex('dbo.', l.object) - len('dbo.')+1 )+'] SET (ALLOW_PAGE_LOCKS = OFF)'
  FROM [guest].[beta_lockinfo] l with (nolock) 
	INNER JOIN sys.tables t ON object_name(t.object_id) = right(l.object, len(l.object) - charindex('dbo.', l.object) - len('dbo.')+1 )
	INNER JOIN sys.schemas s ON  s.schema_id = t.schema_id 
  WHERE l.rsctype IN ('OBJECT','PAGE') AND locktype ='X'
	 AND object LIKE '%dbo%'
	 AND lock_escalation_desc <> 'DISABLE'
	 --AND now < dateadd(hh,-10,getdate())
	-- AND now BETWEEN '2020-12-29' AND '2020-12-30'
  GROUP BY 
		right(l.object, len(l.object) - charindex('dbo.', l.object) - len('dbo.')+1 )
		,rsctype
		,lock_escalation_desc
  ORDER BY count(1) DESC, Records desc

  return

SELECT TOP 100 *
FROM [guest].[beta_lockinfo] l with (nolock)

SELECT  top 20 
right(l.object, len(l.object) - charindex('dbo.', l.object) - len('dbo.')+1 )
  FROM [guest].[beta_lockinfo] l with (nolock) 
  WHERE l.rsctype = 'OBJECT' AND locktype ='X'
 /*
 AND  object NOT LIKE '#%'
  AND object NOT LIKE 'tempdb.<**********>'
  AND object NOT LIKE '%fulltext%'
    AND object NOT LIKE '%cdc%'
	*/
	AND object LIKE '%dbo%'
  AND now < dateadd(hh,-1,getdate())
 -- AND object='Pegasus2008BB.dbo._InfoRg25830'
  order by now DESC


  SELECT 
	right(l.object, len(l.object) - charindex('dbo.', l.object) - len('dbo.')+1 ), 
	count(1) AS [count]
  FROM [guest].[beta_lockinfo] l with (nolock) 
  WHERE l.rsctype='OBJECT' AND locktype ='X'
	-- AND  object NOT LIKE '#%'
	 --AND object NOT LIKE 'tempdb.<**********>'
	-- AND rscsubtype<>'UPDSTATS'
	AND object LIKE '%dbo%'
	 AND now < dateadd(hh,-1,getdate())
  GROUP BY right(l.object, len(l.object) - charindex('dbo.', l.object) - len('dbo.')+1 )
  ORDER BY count(1) DESC


SELECT  [object],count(1)
  FROM [guest].[beta_lockinfo] l with (nolock) 
  WHERE l.rsctype='OBJECT' AND locktype ='X'
  --AND  object NOT LIKE '#%'
  --AND  object LIKE 'Pegasus2008MS.dbo.%'
  AND object NOT LIKE 'tempdb.<**********>'
  AND now < dateadd(hh,-8,getdate())
  group by [object]
  order by count(1) desc


