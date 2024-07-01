IF @@SERVERNAME IN (
	'RU02',
	'RU02\RU02',
	'SRV04',
	'SRV06',
	'INFRAPBX',
	'devdb',
	'devdb\rsnew',
	'AMOSTAT\SQLSTAT2',
	'OBSTAT\SQLSTAT3'
	
) OR
EXISTS (
	SELECT * FROM ::fn_trace_getinfo(default) 
	where Property=2 	-- Свойство где хранится путь к трейсу
		and Value is not null						-- Не пустая запись
		and Cast(Value as varchar(4000)) not like '%\MSSQL\Log\log_%'	-- Не лог по умолчанию
)
BEGIN
	SELECT TOP 0 ''
END ELSE BEGIN
	SELECT @@servername
END

/* -- Проверить какие трейсы запущены
	SELECT * FROM ::fn_trace_getinfo(default) 
	where Property=2 	-- Свойство где хранится путь к трейсу
		and Value is not null						-- Не пустая запись
		and Cast(Value as varchar(4000)) not like '%\MSSQL\Log\log_%'	-- Не лог по умолчанию
*/
   
   
