-- The server principal owns one or more server role(s) and cannot be dropped.

SELECT sp1.name AS ServerRoleName, 
       sp2.name AS RoleOwnerName
       FROM sys.server_principals AS sp1
       JOIN sys.server_principals As sp2
       ON sp1.owning_principal_id=sp2.principal_id
       WHERE sp2.name='sfn\vzheltonogov.adm' --Change the login name



	   USE [master]
GO
ALTER AUTHORIZATION ON SERVER ROLE :: [Readonly] TO [sa] --Change The ServerRole Name and login Name
GO
ALTER AUTHORIZATION ON SERVER ROLE :: [AnotherServerRole-Test] TO [sa] --Change The ServerRole Name and login Name
GO