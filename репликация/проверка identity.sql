
-- для проверки

SELECT o.name AS 'table',ic.name AS 'column',MAX(m.range_end) AS 'range_end',ic.last_value AS 'ident_current' FROM sys.identity_columns ic 
INNER JOIN sys.objects o 
		ON ic.object_id=o.object_id
INNER JOIN 	distribution.dbo.MSmerge_identity_range_allocations  m 
		ON o.name=m.article
GROUP BY o.name,ic.name,ic.last_value 
HAVING CAST (ic.last_value AS BIGINT) >= MAX(m.range_end)-- выводить когда тек. identity подошло к макс. значению


 -- вариант 2

SELECT
SCHEMA_NAME(t.schema_id) AS [schema]
,t.name AS [table]
,p.name AS publication
,idn.range_begin
,idn.range_end
,idn.max_used
,art.pub_range
,art.[range]
,idn.max_used + art.pub_range AS max_used__pub_range
,idn.range_end - (idn.max_used + art.pub_range) AS range_available
,idn.next_range_begin
,idn.next_range_end
FROM dbo.MSmerge_identity_range idn
INNER JOIN dbo.sysmergearticles art ON idn.artid = art.artid
INNER JOIN sys.tables t ON t.name = art.name
LEFT JOIN dbo.sysmergepublications p on p.pubid = art.pubid
WHERE is_pub_range = 1
--AND range_end <= max_used + pub_range /* если это условие выполняется, значит уже есть проблемы */
AND idn.range_end - (idn.max_used + art.pub_range) < 1000000000




-- для просмотра значений


SELECT o.name AS 'table',ic.name AS 'column',m.range_begin,m.range_end AS 'range_end',ic.last_value AS 'ident_current'
 FROM sys.identity_columns ic 
	INNER JOIN sys.objects o 
		ON ic.object_id=o.object_id
INNER JOIN 	distribution.dbo.MSmerge_identity_range_allocations  m with (nolock)	
		ON o.name=m.article

