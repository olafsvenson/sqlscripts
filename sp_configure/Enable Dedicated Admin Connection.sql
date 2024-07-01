/*

	https://www.brentozar.com/archive/2011/08/dedicated-admin-connection-why-want-when-need-how-tell-whos-using/

�EXEC sp_configure 'remote admin connections', 1;
 GO
 RECONFIGURE
 GO
*/
SELECT CASE
           WHEN ses.session_id = @@SPID
           THEN 'It''s me! '
           ELSE ''
       END + COALESCE(ses.login_name, '???') AS WhosGotTheDAC, 
       ses.session_id, 
       ses.login_time, 
       ses.STATUS, 
       ses.original_login_name
FROM sys.endpoints AS en
     JOIN sys.dm_exec_sessions ses ON en.endpoint_id = ses.endpoint_id
WHERE en.name = 'Dedicated Admin Connection';