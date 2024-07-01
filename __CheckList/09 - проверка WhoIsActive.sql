/* Последняя запись в таблицу WhoIsActive больше часа назад */
if object_id('[master].[dbo].[History_WhoIsActive]') is not null 
begin
	SELECT max([collection_time])
	FROM [master].[dbo].[History_WhoIsActive]
	having max([collection_time]) <  dateadd(hh, -1, getdate())	
end
else
	select N'WhoIsActive not installed!!!'
