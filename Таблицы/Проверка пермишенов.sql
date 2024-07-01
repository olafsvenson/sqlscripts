

IF NOT EXISTS
(
    SELECT permission_name, 
           pr.name
    FROM sys.database_permissions pe
         JOIN sys.database_principals pr ON pe.grantee_principal_id = pr.principal_id
    WHERE pe.class = 1
          AND pe.major_id = OBJECT_ID('[����������.����������]')
          AND pe.minor_id = 0
          AND permission_name = 'select'
          AND pr.name = 'zabbix'
)
	grant SELECT ON [����������.����������] TO zabbix


IF NOT EXISTS
(
    SELECT permission_name, 
           pr.name
    FROM sys.database_permissions pe
         JOIN sys.database_principals pr ON pe.grantee_principal_id = pr.principal_id
    WHERE pe.class = 1
          AND pe.major_id = OBJECT_ID('[����������.���BCP_�����������������������]')
          AND pe.minor_id = 0
          AND permission_name = 'select'
          AND pr.name = 'zabbix'
)
	grant SELECT ON [����������.���BCP_�����������������������] TO zabbix


IF NOT EXISTS
(
    SELECT permission_name, 
           pr.name
    FROM sys.database_permissions pe
         JOIN sys.database_principals pr ON pe.grantee_principal_id = pr.principal_id
    WHERE pe.class = 1
          AND pe.major_id = OBJECT_ID('[����������.�������������������������]')
          AND pe.minor_id = 0
          AND permission_name = 'select'
          AND pr.name = 'zabbix'
)
	grant SELECT ON [����������.�������������������������] TO zabbix

/*
grant SELECT ON [����������.����������] TO zabbix
grant SELECT ON [����������.���BCP_�����������������������] TO zabbix
grant SELECT ON [����������.�������������������������] TO zabbix
*/