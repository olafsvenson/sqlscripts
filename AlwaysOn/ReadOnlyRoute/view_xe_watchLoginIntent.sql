DROP TABLE IF EXISTS #tmp

SELECT IDENTITY( INT, 1, 1 ) rowId, file_offset, CAST( event_data AS XML ) AS event_data
INTO #tmp
FROM sys.fn_xe_file_target_read_file( 'xe_watchLoginIntent*.xel', NULL, NULL, NULL )

ALTER TABLE #tmp ADD PRIMARY KEY ( rowId );
CREATE PRIMARY XML INDEX _pxmlidx_tmp ON #tmp ( event_data );


-- Pair up the login and read_only_route_complete events via xxx
DROP TABLE IF EXISTS #users

SELECT
    rowId,
    event_data.value('(event/@timestamp)[1]', 'DATETIME2' ) AS [timestamp],
    event_data.value('(event/action[@name="username"]/value/text())[1]', 'VARCHAR(100)' ) AS username,
    event_data.value('(event/action[@name="attach_activity_id_xfer"]/value/text())[1]', 'VARCHAR(100)' ) AS attach_activity_id_xfer,
    event_data.value('(event/action[@name="attach_activity_id"]/value/text())[1]', 'VARCHAR(100)' ) AS attach_activity_id
INTO #users
FROM #tmp l
WHERE l.event_data.exist('event[@name="login"]') = 1
  AND l.event_data.exist('(event/action[@name="username"]/value/text())[. = "SqlUserShouldBeReadOnly"]') = 1


DROP TABLE IF EXISTS #readonly

SELECT *,
    event_data.value('(event/@timestamp)[1]', 'DATETIME2' ) AS [timestamp],
    event_data.value('(event/data[@name="route_port"]/value/text())[1]', 'INT' ) AS route_port,
    event_data.value('(event/data[@name="route_server_name"]/value/text())[1]', 'VARCHAR(100)' ) AS route_server_name,
    event_data.value('(event/action[@name="username"]/value/text())[1]', 'VARCHAR(100)' ) AS username,
    event_data.value('(event/action[@name="client_app_name"]/value/text())[1]', 'VARCHAR(100)' ) AS client_app_name,
    event_data.value('(event/action[@name="attach_activity_id_xfer"]/value/text())[1]', 'VARCHAR(100)' ) AS attach_activity_id_xfer,
    event_data.value('(event/action[@name="attach_activity_id"]/value/text())[1]', 'VARCHAR(100)' ) AS attach_activity_id
INTO #readonly
FROM #tmp
WHERE event_data.exist('event[@name="read_only_route_complete"]') = 1


SELECT *
FROM #users u
    LEFT JOIN #readonly r ON u.attach_activity_id_xfer = r.attach_activity_id_xfer

SELECT u.username, COUNT(*) AS logins, COUNT( DISTINCT r.rowId ) AS records
FROM #users u
    LEFT JOIN #readonly r ON u.attach_activity_id_xfer = r.attach_activity_id_xfer
GROUP BY u.username