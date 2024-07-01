use IISLogs
--граница, ранее которой будут удаляться строки
declare @bound datetime = dateadd(month, -6, convert(date, getutcdate()))
--номер секции, соответствующий границе
declare @firstPartiton int = $partition.pfByDate(@bound)

--для каждой непустой старой секции генерировать код переключения секции в специальную таблицу dbo.IISLog_truncate и последующей  её очистки.
--таблица dbo.IISLog_truncate должна иметь структуру, аналогичную таблице dbo.IISLog, включая индексы и настройки сжатия индексов.
declare @sql nvarchar(max) = N''
select @sql += N'alter table dbo.IISLog switch partition '+CONVERT(nvarchar(10), partition_number) + N' to dbo.IISLog_truncate; truncate table dbo.IISLog_truncate;'+NCHAR(10)
	from sys.partitions
	where
		object_id = object_id(N'dbo.IISLog')
		--куча или кластерный индекс (взаимоисключающие).
		and index_id in (0,1)
		--есть строки
		and rows > 0
		--секции с более старыми данными
		and partition_number < @firstPartiton

--если найдены секции для очистки, то очистить
if @sql != N''
	exec (@sql)
