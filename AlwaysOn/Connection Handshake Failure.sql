/* Connection Handshake Failure
Database Mirroring login attempt by user ‘Domain\user.’ failed with error: ‘Connection handshake failed. The login ‘Domain\user’ does not have CONNECT permission on the endpoint. State 84.’. [CLIENT: 10.0.0.0]
*/
GRANT CONNECT ON ENDPOINT::hadr_endpoint TO [SFN\dwh-etl-u_gMSA$]
GO

ALTER AUTHORIZATION ON ENDPOINT::hadr_endpoint TO [SFN\dwh-etl-u_gMSA$];


SELECT e.name as mirror_endpoint_name, s.name AS login_name
, p.permission_name, p.state_desc as permission_state, e.state_desc endpoint_state
FROM sys.server_permissions p
INNER JOIN sys.endpoints e ON p.major_id = e.endpoint_id
INNER JOIN sys.server_principals s ON p.grantee_principal_id = s.principal_id
WHERE p.class_desc = 'ENDPOINT' AND e.type_desc = 'DATABASE_MIRRORING'