

IF NOT EXISTS
(
    SELECT permission_name, 
           pr.name
    FROM sys.database_permissions pe
         JOIN sys.database_principals pr ON pe.grantee_principal_id = pr.principal_id
    WHERE pe.class = 1
          AND pe.major_id = OBJECT_ID('[Справочник.споФилиалы]')
          AND pe.minor_id = 0
          AND permission_name = 'select'
          AND pr.name = 'zabbix'
)
	grant SELECT ON [Справочник.споФилиалы] TO zabbix


IF NOT EXISTS
(
    SELECT permission_name, 
           pr.name
    FROM sys.database_permissions pe
         JOIN sys.database_principals pr ON pe.grantee_principal_id = pr.principal_id
    WHERE pe.class = 1
          AND pe.major_id = OBJECT_ID('[Справочник.рсжBCP_НастройкаОбъектовОбмена]')
          AND pe.minor_id = 0
          AND permission_name = 'select'
          AND pr.name = 'zabbix'
)
	grant SELECT ON [Справочник.рсжBCP_НастройкаОбъектовОбмена] TO zabbix


IF NOT EXISTS
(
    SELECT permission_name, 
           pr.name
    FROM sys.database_permissions pe
         JOIN sys.database_principals pr ON pe.grantee_principal_id = pr.principal_id
    WHERE pe.class = 1
          AND pe.major_id = OBJECT_ID('[Справочник.споВремяРаботыПоНакладным]')
          AND pe.minor_id = 0
          AND permission_name = 'select'
          AND pr.name = 'zabbix'
)
	grant SELECT ON [Справочник.споВремяРаботыПоНакладным] TO zabbix

/*
grant SELECT ON [Справочник.споФилиалы] TO zabbix
grant SELECT ON [Справочник.рсжBCP_НастройкаОбъектовОбмена] TO zabbix
grant SELECT ON [Справочник.споВремяРаботыПоНакладным] TO zabbix
*/