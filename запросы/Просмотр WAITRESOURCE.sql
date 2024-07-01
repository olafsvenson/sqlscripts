select r.session_id
     ,s.login_name
     ,s.host_name
	,r.status
   	,qt.text
	,db_name(qt.dbid) AS 'dbid'
	,qt.objectid
	,r.cpu_time
	,r.total_elapsed_time
	,r.percent_complete
	,r.blocking_session_id
	,r.reads
	,r.writes
	,r.logical_reads
	,r.scheduler_id
	--,QueryPlan_XML = (SELECT query_plan FROM sys.dm_exec_query_plan(r.plan_handle)) 
	--,r.plan_handle
	,r.wait_resource
from sys.dm_exec_requests r 
inner join sys.dm_exec_sessions s ON r.session_id=s.session_id
	cross apply sys.dm_exec_sql_text(sql_handle) as qt

where r.session_id > 50
order by r.cpu_time DESC
SELECT @@version
return
-- SELECT * FROM master..sysprocesses WHERE spid= 
-- dbcc freeproccache()
-- kill 

OBJECT: 7:943342425:0 
PAGE: 7:1:70849577                                                                                                                                                                                                                                                      
use[tempdb] 


SELECT * FROM sys.databases                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
SELECT DB_NAME(5)

2:8:5674811

7:3:50645856
7:1:23902971
5:1:1123371

DBCC traceon (3604)
GO
DBCC page (2,1,43)
go
DBCC traceoff (3604)

SELECT DB_NAME(5)
USE sputnik
SELECT OBJECT_NAME(128)

_Reference27034_VT27191

USE master
SELECT * FROM sysobjvalues

_InfoRg41385
-- Metadata: ObjectId = 1349579846   
_Document557

select object_name( 1349579846)

checkpoint



KEY: 5:72057594069450752 (ffffffffffff)


SELECT * FROM sys.partitions WHERE hobt_id = 591585

129:72057610760683520
-- KEY: 5:72057594069450752 (ffffffffffff)

SELECT o.name,o.type_desc
FROM sys.objects  o 
inner join sys.partitions p
	on o.object_id=p.object_id
where p.hobt_id = 72057599157010432

select * from sys.databases


