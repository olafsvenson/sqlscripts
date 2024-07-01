-- https://en.dirceuresende.com/blog/sql-server-how-to-create-error-and-exception-monitoring-in-your-database-using-extended-events-xe/
IF ((SELECT COUNT(*) FROM sys.server_event_sessions WHERE [name] = 'SystemErrors') > 0) DROP EVENT SESSION [SystemErrors] ON SERVER 
GO

CREATE EVENT SESSION [SystemErrors] ON SERVER 
ADD EVENT sqlserver.error_reported (
    ACTION(client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text)

    -- Adicionado manualmente, pois não é possível filtrar pela coluna "Severity" pela interface
    WHERE severity > 10
)
ADD TARGET package0.event_file(SET filename=N'SystemErrors.xel',max_file_size=(3),max_rollover_files=(1))
WITH (STARTUP_STATE=ON) -- Será iniciado automaticamente com a instância
GO

-- Ativando a sessão (por padrão, ela é criada desativada)
ALTER EVENT SESSION [SystemErrors] ON SERVER STATE = START
GO