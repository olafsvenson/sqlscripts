EXEC msdb.dbo.sp_send_dbmail
		 @profile_name = 'Sensor'
		,@recipients = 'vzheltonogov@ûâëïôêôòåşêã'
		,@subject = 'Server has restarted'
		,@body = 'Test msg'
		,@body_format = 'Text'
		