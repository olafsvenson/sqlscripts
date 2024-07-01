-- просмотр
SELECT agrp.[name] AS availability_groups_name
	,agrp.group_id
	,arep.replica_id
	,arep.owner_sid
	,sp.[name] AS owner_name
FROM sys.availability_groups agrp
JOIN sys.availability_replicas arep ON agrp.group_id = arep.group_id
JOIN sys.server_principals sp ON arep.owner_sid = sp.[sid]

-- смена
/*
USE [master]
GO
ALTER AUTHORIZATION ON AVAILABILITY GROUP::[dwh-etl-p-ag] TO sa;
GO
ALTER AUTHORIZATION ON AVAILABILITY GROUP::[SBOLDMart-U-AG] TO sa;
GO
ALTER AUTHORIZATION ON AVAILABILITY GROUP::[CDIDataMart-U-AG] TO sa;
GO
ALTER AUTHORIZATION ON AVAILABILITY GROUP::[DWH-AG-P] TO sa;
GO
ALTER AUTHORIZATION ON AVAILABILITY GROUP::[SbolDatamart_AG] TO sa;
GO
ALTER AUTHORIZATION ON AVAILABILITY GROUP::[CDIDMart-AG-P] TO sa;
GO
*/
--select USER_SID(0x02)