DECLARE
@EmailSubject varchar(100),
@TextTitle varchar(100),
@TableHTML nvarchar(max),
@Body nvarchar(max)
SET @EmailSubject = 'Secondary Replica Status'
SET @TextTitle = 'Availability Group Sync Alert'
SET @TableHTML =
'<html>'+
'<head><style>'+
-- Data cells styles / font size etc
'td {border:1px solid #ddd;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:12pt; width="200"}'+
'</style></head>'+
'<body data-rsssl=1>'+
-- TextTitle style
'<div style="margin-top:15px; margin-left:15px; margin-bottom:15px; font-weight:bold; font-size:13pt; font-family:calibri;">' + @TextTitle +'</div>' +
-- Color and columns names
'<div style="font-family:Calibri; font-size: 12pt; "><table>'+'<tr bgcolor=#00881d>'+
'<td align=left; width="200"><font face="calibri" color=White><b>ServerName</b></font></td>'+ -- Server Name
'<td align=left; width="200"><font face="calibri" color=White><b>DBName</b></font></td>'+ -- DB Name
'<td align=left; width="200"><font face="calibri" color=White><b>AGHealthStatus</b></font></td>'+ -- AG Status
'<td align=left; width="200"><font face="calibri" color=White><b>Log Send Time (Secs)</b></font></td>'+ -- Log Send Size
'<td align=left; width="200"><font face="calibri" color=White><b>Redo Time (Secs)</b></font></td>'+ -- LogSendRate
'<td align=left; width="200"><font face="calibri" color=White><b>Redo Size (KB)</b></font></td>'+ -- RedoSize
'<td align=left; width="200"><font face="calibri" color=White><b>Redo Rate (KB/Secs)</b></font></td>'+ -- RedoRate
'</tr></div>'
-------------------------------------------------------------------------------------------------------------------------------------
----- -- Secondary Replica Stats  --------
-------------------------------------------------------------------------------------------------------------------------------------
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
SecondaryReplicaStats AS (
SELECT 
	ar.replica_server_name AS ServerName, 
	adc.database_name AS DBName, 
	drs.synchronization_health_desc AS AGHealthStatus, 
	(drs.log_send_queue_size/NULLIF(drs.log_send_rate,0)) AS LogSendSecs,
	(drs.redo_queue_size/NULLIF(drs.redo_rate,0)) AS RedoSecs,
	drs.redo_queue_size AS RedoSize,
	ISNULL(drs.redo_rate,0) AS RedoRate
FROM sys.dm_hadr_database_replica_states AS drs
INNER JOIN sys.availability_databases_cluster AS adc 
	ON drs.group_id = adc.group_id AND 
	drs.group_database_id = adc.group_database_id
INNER JOIN sys.availability_groups AS ag
	ON ag.group_id = drs.group_id
INNER JOIN sys.availability_replicas AS ar 
	ON drs.group_id = ar.group_id AND 
	drs.replica_id = ar.replica_id)
----------------------------------------------------------
----------------------------------------------------------

SELECT @Body =(
SELECT
td = ServerName,
td = DBName,
td = AGHealthStatus,
td = LogSendSecs,
td = RedoSecs,
td = RedoSize,
td = RedoRate
FROM
SecondaryReplicaStats
--where (LogSendSecs+RedoSecs)>-1
for XML raw('tr'), elements)
SET @Body = REPLACE(@Body, '<td>', '<td align=left width="200"><font face="calibri">')
SET @TableHTML = @TableHTML + @Body + '</table></div></body></html>'
SET @TableHTML = '<div style="color:Black; font-size:10pt; font-family:Calibri">' + @TableHTML + '</div>'
-------------------------------
----- Sending email --------
-------------------------------
if(@Body is not null)
begin
exec msdb.dbo.sp_send_dbmail
@Profile_name = 'Houston mail',
@Recipients = 'zheltonogov.vs@pecom.ru',
@Body = @TableHTML,
@Subject = @EmailSubject,
@Body_format = 'HTML'
end