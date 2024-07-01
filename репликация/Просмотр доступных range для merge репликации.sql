SELECT

SCHEMA_NAME(t.schema_id) AS [schema]
,t.name AS [table]

,p.name AS publication
,r.range_begin

,r.range_end
,r.max_used

,a.pub_range
,a.[range]

,r.max_used + a.pub_range AS max_used__pub_range
,r.range_end - (r.max_used + a.pub_range) AS range_available

,r.next_range_begin

,r.next_range_end

FROM dbo.MSmerge_identity_range r

INNER JOIN dbo.sysmergearticles a ON r.artid = a.artid

INNER JOIN sys.tables t ON t.name = a.name

LEFT JOIN dbo.sysmergepublications p on p.pubid = a.pubid

WHERE is_pub_range = 1

--AND range_end <= max_used + pub_range /* if this condition is met then we already have a problem */

AND r.range_end - (r.max_used + a.pub_range) < 1000000000 