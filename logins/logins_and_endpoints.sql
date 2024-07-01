USE [master]
GO
SELECT pm.class, pm.class_desc, pm.major_id, pm.minor_id, 
   pm.grantee_principal_id, pm.grantor_principal_id, 
   pm.[type], pm.[permission_name], pm.[state],pm.state_desc, 
   pr.[name] AS [owner], gr.[name] AS grantee, e.[name] AS endpoint_name
FROM sys.server_permissions pm 
   JOIN sys.server_principals pr ON pm.grantor_principal_id = pr.principal_id
   JOIN sys.server_principals gr ON pm.grantee_principal_id = gr.principal_id
   JOIN sys.endpoints e ON pm.grantor_principal_id = e.principal_id 
        AND pm.major_id = e.endpoint_id
--WHERE pr.[name] = N'DOMAIN\DBAUser1';


/* Исправление

USE [master]
GO
ALTER AUTHORIZATION ON ENDPOINT::Hadr_endpoint TO rendba;
GO   

*/