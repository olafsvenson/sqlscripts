SELECT servicename, service_account FROM sys.dm_server_services
where 
		servicename not like 'SQL Server Agent%'
		and servicename not like 'SQL Full-text Filter Daemon Launcher%'
	

GO