-- Текущие блокировки таблиц
DECLARE @Detail TINYINT
SET @Detail=0		-- 0 - агрегированные данные 1 - детализация

SELECT * 
INTO #A
FROM master.dbo.syslockinfo WITH(nolock)

Select 
		distinct
		convert (smallint, req_spid) As spid,
		rsc_dbid As dbid,
		s.name, 
		sp.loginame,
		sp.hostname,
		rsc_indid As IndId,
		substring (v.name, 1, 4) As Type,
		substring (u.name, 1, 8) As Mode,
		substring (x.name, 1, 5) As Status
	INTO #B
	from 	#A as ss,
		master.dbo.spt_values v WITH(nolock),
		master.dbo.spt_values x WITH(nolock),
		master.dbo.spt_values u WITH(nolock),
		sysobjects AS s WITH(nolock),
		master.dbo.sysprocesses sp with(nolock)
	where   ss.rsc_type = v.number
			and v.type = 'LR'
			and ss.req_status = x.number
			and x.type = 'LS'
			and ss.req_mode + 1 = u.number
			and u.type = 'L'
			and s.id = ss.rsc_objid
			AND sp.spid = convert (smallint, req_spid)
----------------
			AND  spid <>@@SPID  -- Исключаем себя
----------------
	order by spid

IF @Detail=0 begin
	SELECT B.LogiName AS LoginName,B.Mode,sd.Name,COUNT(*) 
	FROM #B B
		INNER JOIN master.dbo.sysdatabases sd with(nolock) ON sd.dbid=b.dbid 
	GROUP BY B.LogiName,B.Mode,sd.Name
	ORDER BY COUNT(*)
END
ELSE BEGIN
	SELECT * FROM #B
END

DROP TABLE #A
DROP TABLE #B