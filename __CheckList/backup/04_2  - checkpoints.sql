use master
go
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CheckPointLog]') AND type in (N'U'))
begin

-- проверяем, что есть свежие данные 
if exists(select 1 from [master].[dbo].[CheckPointLog]  with (nolock) having max(datestart) <  DATEADD(hh,-3,GETDATE()) ) -- есть данные за последние 3 часа
begin
	select 	DBName,DateStart,cast (datediff(mm,getdate(),DateStart) as int) as 'DurationMin'	from [master].[dbo].[CheckPointLog]  with (nolock) 
end

-- проверяем длительность чекпоинтов
SELECT
		Cast(DBName AS VARCHAR(500)) AS 'DBName'
		,Cast(DateStart AS DATETIME) AS 'DateStart'
		,Cast(DurationMin AS INT) AS 'DurationMin'
  FROM [master].[dbo].[CheckPointLog]  with (nolock) 
  where 
		DurationMin >= 15
		and datestart > DATEADD(dd,-3,GETDATE()) 
  order by DateStart desc, DurationMin desc
  
END
ELSE BEGIN 
	SELECT TOP (0) CAST('' AS VARCHAR(500)) as 'DBName',CAST(0 AS datetime) as 'DateStart',CAST(0 AS int) as 'DurationMin'
end  
 