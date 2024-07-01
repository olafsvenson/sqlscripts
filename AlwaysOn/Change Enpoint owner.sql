-- https://www.dbi-services.com/blog/availability-group-endpoint-ownership/
USE master;
go

SELECT 
	SUSER_NAME(principal_id) AS endpoint_owner,name AS endpoint_name
FROM sys.database_mirroring_endpoints;

USE master;
go

ALTER AUTHORIZATION ON ENDPOINT::Hadr_endpoint TO sa;
GRANT CONNECT ON ENDPOINT::Hadr_endpoint TO [SFN\dwh-etl-p_gMSA$]