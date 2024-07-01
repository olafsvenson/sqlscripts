DECLARE @versionNb			int;
DECLARE @EventSessionName	       VARCHAR(256);
DECLARE @DeadlockXMLLookup		VARCHAR(4000);
DECLARE @tsql				NVARCHAR(MAX);
DECLARE @LineFeed			CHAR(2);
 
SELECT	
@LineFeed		= CHAR(13) + CHAR(10),
@versionNb		= (@@microsoftversion / 0x1000000) & 0xff,
@EventSessionName	= ISNULL(@EventSessionName,'system_health')
;
 
IF (@versionNb = 10) 
BEGIN
SET @DeadlockXMLLookup = 'XEventData.XEvent.value(''(data/value)[1]'',''VARCHAR(MAX)'')';
END;
ELSE IF(@versionNb < 10)
BEGIN
RAISERROR('Extended events do not exist in this version',12,1) WITH NOWAIT;
RETURN;
END;	
ELSE 
BEGIN 
SET @DeadlockXMLLookup = 'XEventData.XEvent.query(''(data/value/deadlock)[1]'')';
END;
 
SET @tsql = 'WITH DeadlockData' + @LineFeed + 
		'AS (' + @LineFeed +
		'    SELECT ' + @LineFeed +
		'	    CAST(target_data as xml) AS TargetData' + @LineFeed +
		'    FROM ' + @LineFeed +
		'	    sys.dm_xe_session_targets st' + @LineFeed +
		'    JOIN ' + @LineFeed +
		'	    sys.dm_xe_sessions s ' + @LineFeed +
		'    ON s.address = st.event_session_address' + @LineFeed +
		'    WHERE name   = ''' + 'system_health' + '''' + @LineFeed +
		'    AND st.target_name = ''ring_buffer'' ' + @LineFeed +
	')' + @LineFeed +
		'SELECT ' + @LineFeed +
		'    XEventData.XEvent.value(''@name'', ''varchar(100)'') as eventName,' + @LineFeed +
		'    XEventData.XEvent.value(''@timestamp'', ''datetime'') as eventDate,' + @LineFeed +
		'    CAST(' + @DeadlockXMLLookup + ' AS XML) AS DeadLockGraph ' + @LineFeed +
		'FROM ' + @LineFeed +
		'    DeadlockData' + @LineFeed +
		'CROSS APPLY ' + @LineFeed +
		'    TargetData.nodes(''//RingBufferTarget/event'') AS XEventData (XEvent)' + @LineFeed +
		'WHERE ' + @LineFeed +
		'    XEventData.XEvent.value(''@name'',''varchar(4000)'') = ''xml_deadlock_report''' + @LineFeed +
		';'
		;
EXEC sp_executesql @tsql;