IF OBJECT_ID (N'tempdb..#t', N'U') IS NOT NULL
	DROP TABLE #t;	

create table #t
(
    name varchar(500),
    rows bigint,
    reserved varchar(50),
    data varchar(50),
    index_size varchar(50),
    unused varchar(50)
)

declare @t_name varchar(500)
DECLARE t_cursor CURSOR
    FOR select name from sysobjects where xtype = 'U' order by name
OPEN t_cursor
FETCH NEXT FROM t_cursor INTO @t_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    insert into #t exec sp_spaceused @t_name
    FETCH NEXT FROM t_cursor INTO @t_name;
END
CLOSE t_cursor;
DEALLOCATE t_cursor;

SELECT * FROM #t ORDER BY [rows] desc


RETURN


select * 
INTO master..__tables_size
from #t order by rows desc


SELECT count(1) FROM master..__tables_size  with (nolock) 
SELECT * FROM master..__tables_size with (nolock) 
58 133 365

47 647 126

select 
	
	'dbcc checktable('''+name+''') with all_errormsgs',
	'ALTER TABLE ['+name+'] REBUILD WITH (DATA_COMPRESSION = PAGE )'
	, rows
	 --cast(left(reserved, len(reserved)-2) as bigint)/1024.0 reserved,
  --  cast(left(data, len(data)-2) as bigint)/1024.0 data, cast(left(index_size, len(index_size)-2) as bigint)/1024.0 index_size,
  --  cast(left(unused, len(unused)-2) as bigint)/1024.0 unused
from #t 
where rows > 0
and name not like '[_][_]%'
order by [rows] desc

SELECT * FROM SDDATSERV.master.dbo.__tables_size with (nolock) 

SELECT 
		t1.name,
		t1.rows,
		rtrim(replace(t2.reserved,'KB','')) AS 'reserved (data+index) (KB)',
		rtrim(replace(t2.data,'KB','')) AS 'data (KB)',
		rtrim(replace(t2.index_size,'KB','')) AS 'index_size (KB)',
		rtrim(replace(t2.unused,'KB','')) AS 'unused (KB)',
		t2.rows,
		rtrim(replace(t1.reserved,'KB','')) AS 'reserved (data+index) (KB)',
		rtrim(replace(t1.data,'KB','')) AS 'data (KB)',
		rtrim(replace(t1.index_size,'KB','')) AS 'index_size (KB)',
		rtrim(replace(t1.unused,'KB','')) AS 'unused (KB)'
FROM master..__tables_size t1
LEFT JOIN SDDATSERV.master.dbo.__tables_size t2
ON t1.name = t2.name COLLATE SQL_Latin1_General_CP1_CI_AS
ORDER BY t2.rows desc

	SELECT * FROM master..__tables_size t1 with (nolock) 