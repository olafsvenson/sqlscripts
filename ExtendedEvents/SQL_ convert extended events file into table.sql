-- convert all .xel files in a given folder to a single-column table
-- (alternatively specify an individual file explicitly)
select event_data = convert(xml, event_data)
	into #eeTable
from sys.fn_xe_file_target_read_file(N'd:\killme\extended events\*.xel', null, null, null);

-- select from the table
select * from #eeTable
-- and click on a hyperlink value to see the structure of the xml

-- create multi-column table from single-column table, explicitly adding needed columns from xml
SELECT 
  ts    = event_data.value(N'(event/@timestamp)[1]', N'datetime'),
  [sql] = event_data.value(N'(event/action[@name="sql_text"]/value)[1]', N'nvarchar(max)'),
  cpu   = event_data.value(N'(event/data[@name="cpu_time"]/value)[1]', N'nvarchar(max)'),
  duration   = event_data.value(N'(event/data[@name="duration"]/value)[1]', N'nvarchar(max)'),
  result  = event_data.value(N'(event/action[@name="result"]/value)[1]', N'int'),
  row_count = event_data.value(N'(event/data[@name="row_count"]/value)[1]', N'nvarchar(max)'),
  spid  = event_data.value(N'(event/action[@name="session_id"]/value)[1]', N'int'),
  physical_reads  = event_data.value(N'(event/action[@name="physical_reads"]/value)[1]', N'int'),
  logical_reads  = event_data.value(N'(event/action[@name="logical_reads"]/value)[1]', N'int'),
  writes  = event_data.value(N'(event/action[@name="writes"]/value)[1]', N'int'),
  user_nm  = event_data.value(N'(event/action[@name="username"]/value)[1]', N'nvarchar(max)')
  into PexTrace_20170526
FROM #eeTable

-- add id
ALTER TABLE PexTrace_20170526
ADD eventId INT IDENTITY;

-- set id as PK
ALTER TABLE PexTrace_20170526
ADD CONSTRAINT PK_PexTrace_20170526 PRIMARY KEY(eventId);

-- now query all you like
SELECT *
FROM PexTrace_20170526
where sql like '%springer%'
order by ts