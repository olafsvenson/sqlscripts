/*
Orphan distributed transactions spid =-2
*/
select DISTINCT request_owner_guid from sys.dm_tran_locks where request_session_id = -2