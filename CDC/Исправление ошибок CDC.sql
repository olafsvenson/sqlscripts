/*
Could not update the metadata for database Pegasus2008 to indicate that a Change Data Capture job has been added.
The failure occurred when executing the command 'sp_add_jobstep_internal'. The error returned was 14234: 'The specified '@server' is invalid (valid values are returned by sp_helpserver).'. Use the action and error to determine the cause of the failure and resubmit the request.

*/
select SERVERPROPERTY('ServerName')
select srvname from master.dbo.sysservers


Disable TRIGGER [tconfigure]  ON ALL SERVER
go
EXEC sp_DROPSERVER 'NV-SERVER-2N\SQL2016'
EXEC sp_ADDSERVER 'NV-SERVER-2\SQL2016', 'local'
GO

Enable TRIGGER [tconfigure]  ON ALL SERVER
