SELECT 
	CASE @@microsoftversion/ 0x01000000 
		WHEN 6 THEN 'You''ve got to be kidding me.'
		WHEN 7 THEN 'SQL Server 7.0'
		WHEN 8 THEN 'SQL Server 2000'
		WHEN 9 THEN 'SQL Server 2005'
		WHEN 10 THEN 'SQL Server 2008'
		WHEN 11 THEN 'SQL Server 2012'
		WHEN 15 THEN 'SQL Server 2019'
		else 'Time to update your gist, homey.'
	END


	