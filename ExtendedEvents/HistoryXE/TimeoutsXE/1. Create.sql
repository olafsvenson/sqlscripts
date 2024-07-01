-- https://en.dirceuresende.com/blog/sql-server-how-to-identify-timeout-or-broken-connections-using-extended-events-xe-or-sql-profiler-trace/
IF ((SELECT COUNT(*) FROM sys.server_event_sessions WHERE [name] = 'Timeouts') > 0) DROP EVENT SESSION [Timeouts] ON SERVER 
GO

CREATE EVENT SESSION [Timeouts]
ON SERVER
ADD EVENT sqlserver.attention ( 
    ACTION
    (
        sqlserver.client_app_name,
        sqlserver.client_hostname,
        sqlserver.[database_name],
        sqlserver.nt_username,
      --  sqlserver.num_response_rows,
        sqlserver.server_instance_name,
        sqlserver.server_principal_name,
        sqlserver.server_principal_sid,
        sqlserver.session_id,
        sqlserver.session_nt_username,
        sqlserver.session_server_principal_name,
        sqlserver.sql_text,
        sqlserver.username
    )
)
ADD TARGET package0.event_file ( 
    SET 
        filename = N'Monitor_Timeout.xel', -- Não esqueça de mudar o caminho aqui :)
        max_file_size = ( 50 ), -- Tamanho máximo (MB) de cada arquivo
        max_rollover_files = ( 8 ) -- Quantidade de arquivos gerados
)
WITH
(
    STARTUP_STATE = OFF
)

-- Ativando a sessão (por padrão, ela é criada desativada)
ALTER EVENT SESSION [Timeouts] ON SERVER STATE = START
GO