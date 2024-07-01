IF NOT EXISTS (
	SELECT * FROM ::fn_trace_getinfo(default) 
	where Property=2 	-- Свойство где хранится путь к трейсу
		and Value is not null						-- Не пустая запись
		and Cast(Value as varchar(4000)) not like '%\MSSQL\Log\log_%'	-- Не лог по умолчанию
)
SELECT @@servername

/* -- Проверить какие трейсы запущены
	SELECT * FROM ::fn_trace_getinfo(default) 
	where Property=2 	-- Свойство где хранится путь к трейсу
		and Value is not null						-- Не пустая запись
		and Cast(Value as varchar(4000)) not like '%\MSSQL\Log\log_%'	-- Не лог по умолчанию
*/
   
   
