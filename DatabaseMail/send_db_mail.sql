EXEC msdb.dbo.sp_send_dbmail
		 @profile_name = 'Sensor'
		,@recipients = 'vzheltonogov@������������'
		,@subject = 'Server has restarted'
		,@body = 'Test msg'
		,@body_format = 'Text'
		