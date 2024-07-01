--Ежедневный скрипт – обработка очереди статистик
USE Pegasus2008MS
GO

set nocount on

DECLARE  @FinalHour int = 6 --заканчиваем обработку в 6 утра
		,@FinalMinute int = 30
        ,@FinalDate datetime2
   
             

SET @FinalDate = dateadd(day, datediff(day, 0, GETDATE()), 0)
--select @FinalDate 



IF datepart(hour, GETDATE()) > @FinalHour -- перенесем на следующие сутки (например, отсечка на 5 часов, а сейчас 23. 23 > 5, при этом нам надо, чтобы перестроение завершилось не сейчас, а на следующий календарный день)
       SET @FinalDate = DATEADD(day, 1, @FinalDate )       

--установим дату, когда нужно прекратить выполнение скрипта          
SET @FinalDate = DATEADD(hour, @FinalHour, @FinalDate )  
SET @FinalDate = DATEADD(minute, @FinalMinute, @FinalDate )  



--select @FinalDate 

DECLARE
       @index_name nvarchar(128),
	   @table_name nvarchar(128),
	   @sql nvarchar(500),
	   @StartDate datetime,
	   @FinishDate datetime,
	   @lock_result int;


	   
DECLARE todo CURSOR STATIC FOR
	select 
		'UPDATE STATISTICS [' + list.[TableName] + ']([' + list.[Name] + ']) WITH FULLSCAN', -- TODO: заменить на quotename
		list.[Name],
		list.[TableName]
	from sfp_statistics_current list
	where list.[StartDT] is null -- берем не обработанные записи
		and list.[Name] not in ('sfp_statistics_current', 'sfp_statistics_history') --на всякий случай
	order by
		list.[Id] asc -- по возрастанию, потому что при заполнениии этой таблицы сначала вставляются с самыми большими показателями


OPEN todo; 

WHILE 1 = 1 
BEGIN
    
	FETCH NEXT FROM todo
	INTO @sql, @index_name, @table_name

	

	IF @@FETCH_STATUS != 0
			BREAK;
	
	-- если вышли за временные ограничения
	IF GETDATE() > @FinalDate 
			BREAK;

	
	/*  При обслуживании статистики блокируется весь объект. 
		Нельзя в параллельном потоке пересчитать другую статистику по той же таблице
		поэтому блокировку проверим по имени таблицы
		проверяем с 0 таймаутом чтобы не ждать, а сразу понять, занято или нет
	*/
	exec @lock_result = sp_getapplock @table_name, 'Exclusive', 'Session', 0
	if @lock_result < 0
		continue 
	
	-- заполняем время старта
	update sfp_statistics_current
		set [StartDT] = GetDate()
	where 
		[TableName] = @table_name
		and [Name] = @index_name		
	   
	begin try
		--print (@sql)
		EXEC (@sql)

		SET @FinishDate = GetDate()

		-- заполняем время окончания
		update sfp_statistics_current
		set [EndDT] =	@FinishDate,
			[LastError] = N''
		where 
			[TableName] = @table_name
			and [Name] = @index_name

	end try
	begin catch
		
		-- при ошибке сохраняем тест
		update sfp_statistics_current
		set [LastError]  = Error_message()
		where 
			[TableName] = @table_name
			and [Name] = @index_name
		 

		--print Error_message()
	end catch
	
	exec sp_releaseapplock @Table_name, 'Session'
END

CLOSE todo;
DEALLOCATE todo;


