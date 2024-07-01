

SELECT CAST(d.DeadlockGraph AS XML)
FROM (
	SELECT XEventData.XEvent.value('(data/value)[1]', 'varchar(max)') as DeadlockGraph
	FROM (
		SELECT CAST(target_data AS XML) AS TargetData
		FROM sys.dm_xe_session_targets st
		JOIN sys.dm_xe_sessions s
			ON s.address = st.event_session_address
		WHERE name = 'system_health'
	) AS Data
	CROSS APPLY
		TargetData.nodes ('//RingBufferTarget/event') AS XEventData (XEvent)
	WHERE XEventData.XEvent.value('@name', 'varchar(4000)') = 'xml_deadlock_report'
) AS d
WHERE d.DeadlockGraph LIKE '%2020-02-28%'; -- тут указываете дату, на которую нужно получить xml output для дедлоков