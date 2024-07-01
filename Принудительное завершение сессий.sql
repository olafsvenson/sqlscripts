DECLARE @DatabaseName nvarchar(50)
SET @DatabaseName = N'service'

DECLARE @SQL varchar(max)
SET @SQL = ''
SELECT @SQL = @SQL + 'Kill ' + Convert(varchar, SPId) + ';' FROM MASTER..SysProcesses WHERE DBId = DB_ID(@DatabaseName) AND SPId = @@SPId
EXEC(@SQL)

-----------------
ALTER DATABASE dbName SET SINGLE_USER WITH ROLLBACK IMMEDIATE


-------------------




declare @l_spid varchar(4)
,@l_hostname varchar(20)
,@dbname varchar(256)

select @dbname = 'YOUR DATABASE NAME HERE'
declare kill_cursor scroll cursor
for
select convert(varchar(4), spid), hostname from master..sysprocesses with (nolock)
where db_name(dbid) = @dbname

open kill_cursor
select @@cursor_rows

fetch next from kill_cursor into
@l_spid
,@l_hostname
while (@@fetch_status = 0 )
begin
select @l_hostname Killed
exec ( 'kill ' + @l_spid)
fetch next from kill_cursor into
@l_spid
,@l_hostname
end
close kill_cursor
deallocate kill_cursor


RESTORE STATEMENT HERE