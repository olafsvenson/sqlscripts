
-- Загрузка полных трейсов с партиционированием fulltrace
use FullTracesSQL 

set nocount on
--читайте все комментарии, включающие символы !!!
declare
	--!!!задайте путь к папке с трэйсами, не включая завершающий слэш
	@traceFolder nvarchar(260) = N'D:\Traces\AMO2',
	--!!!задайте название секционированной таблицы для полного трэйса
	@fullTraceTableName sysname = N'dbo.__FullTraceAMO2_profiler_20120206',
	--!!!задайте ПРЕФИКС таблицы для часового трэйса. СУФФИКСОМ будет дата и час в формате yyyyMMddHH
	@hourTraceTablePrefix sysname = N'dbo.__FullTraceAMO2_profiler_',
	--!!!задайте минимальную дату трэйса. NULL - не ограничена
	@MinDate datetime = null,
	--!!!задайте максимальную дату трэйса. NULL - не ограничена
	@MaxDate datetime = NUll

	--!!! В зависмости от COllation на сервере итоговая таблица создаётся с Collation сервера

	
declare @tab table
(
	name	nvarchar(260),
	depth	int,
	isFile	bit,
	TableName	sysname null,
	StartTime	datetime,
	EndTime		as dateadd(hour, 1, StartTime)
)
declare @sql nvarchar(max)
declare @StartTime datetime

--считать все файлы из папки
insert into @tab (name, depth, isFile)
exec xp_dirtree @tracefolder, 1, 1

--удалить все ненужные файлы
delete from @tab
	where
		--есть символ подчёркивания (это rollover файл)
		name like '%\_%' escape '\'
		--не трэйс-файл
		or name not like '%.trc'
		--не файл
		or isFile = 0
--вычислить дату начала файла трэйса и имя таблицы для этого файла
update @tab
set
	@StartTime = stuff(right(left(name, len(name)-6),15), 14, 0, N':'),
	StartTime = @StartTime,
	TableName = @hourTraceTablePrefix + convert(nchar(8), @StartTime, 112) + convert(nchar(2), @StartTime, 108)

--удалить трэйсы, не попадающие в заданный диапазон
delete from @tab where not (StartTime between isnull(@MinDate, '17530101') and isnull(@MaxDate, '99991231'))
----------------------------------------------------------------------------------------------------
--Select * from @tab
--Select * from sys.partition_functions
----------------------------------------------------------------------------------------------------

--создать функцию и схему секционирования
if not exists(select 1 from sys.partition_functions where name = 'pfTrace')
begin
	select @StartTime = min(StartTime) from @tab
	if @StartTime is not null
	begin
		--создаём функцию с одной секцией
		create partition function pfTrace(datetime) as range right for values(@StartTime)
		--создаём схему секционирования, основанную на функции. все секции будут в primary
		create partition scheme psTrace as partition pfTrace all to ([primary])
	end
end

--создать таблицу для полного трэйса при необходимости
if object_id(@fullTraceTableName) is null
begin
	--структуры секционированной таблицы и таблицы часового трэйса должны быть идентичны,
	--поэтому все столбцы ДОЛЖНЫ быть nullable
	set @sql = N'CREATE TABLE ' + @fullTraceTableName + N'
(
[TextData] [ntext] collate Cyrillic_General_CI_AS NULL,
	[BinaryData] [image] NULL,
	[DatabaseID] [int] NULL,
	[TransactionID] [bigint] NULL,
	[LineNumber] [int] NULL,
	[NTUserName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[NTDomainName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[HostName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[ClientProcessID] [int] NULL,
	[ApplicationName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[LoginName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[SPID] [int] NULL,
	[Duration] [bigint] NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[Reads] [bigint] NULL,
	[Writes] [bigint] NULL,
	[CPU] [int] NULL,
	[Permissions] [bigint] NULL,
	[Severity] [int] NULL,
	[EventSubClass] [int] NULL,
	[ObjectID] [int] NULL,
	[Success] [int] NULL,
	[IndexID] [int] NULL,
	[IntegerData] [int] NULL,
	[ServerName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[EventClass] [int] NULL,
	[ObjectType] [int] NULL,
	[NestLevel] [int] NULL,
	[State] [int] NULL,
	[Error] [int] NULL,
	[Mode] [int] NULL,
	[Handle] [int] NULL,
	[ObjectName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[DatabaseName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[FileName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[OwnerName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[RoleName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[TargetUserName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[DBUserName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[LoginSid] [image] NULL,
	[TargetLoginName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[TargetLoginSid] [image] NULL,
	[ColumnPermissions] [int] NULL,
	[LinkedServerName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[ProviderName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[MethodName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[RowCounts] [bigint] NULL,
	[RequestID] [int] NULL,
	[XactSequence] [bigint] NULL,
	[EventSequence] [bigint] NULL,
	[BigintData1] [bigint] NULL,
	[BigintData2] [bigint] NULL,
	[GUID] [uniqueidentifier] NULL,
	[IntegerData2] [int] NULL,
	[ObjectID2] [bigint] NULL,
	[Type] [int] NULL,
	[OwnerID] [int] NULL,
	[ParentName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[IsSystem] [int] NULL,
	[Offset] [int] NULL,
	[SourceDatabaseID] [int] NULL,
	[SqlHandle] [image] NULL,
	[SessionLoginName] [nvarchar](256)  collate Cyrillic_General_CI_AS NULL,
	[PlanHandle] [image] NULL,
	[GroupID] [int] NULL
		
)
--функция секционирования
on psTrace(EndTime)'
	exec (@sql)
end

--скрипт модификации функции секционирования для трэйсов
--добавить отсутствующие секции и назначить файловую группу для следующей секции
set @sql = ''
select @sql += N'
--добавить секцию
alter partition function pfTrace() split range (''' + convert(nvarchar, StartTime, 120) + N''')
--задать файловую группу для СЛЕДУЮЩЕЙ секции
alter partition scheme psTrace next used [primary]'
	from @tab t
	where not exists(select 1
		from sys.partition_range_values v
		inner join sys.partition_functions f on f.function_id = v.function_id
		where
			f.name = 'pfTrace'
			and v.value = t.StartTime)

--создать секции, чтобы далее можно было получить номер нужной секции при помощи $partition.pfTrace(StartTime)
--print @sql
exec(@sql)


--скрипты загрузки данных на каждый час свой
--для переключения несекционированной таблицы в секционированную нужно добавить ограничение,
--гарантирующее, что в несекционированной таблице есть только данные для целевой секции.
select N'
/*создать и заполнить таблицу часового трэйса*/
select *
into ' + TableName + N'
	from ::fn_trace_gettable(''' + @traceFolder + N'\' + name + N''', default)
	where EndTime >= ''' + convert(nvarchar, StartTime, 120) + N''' and EndTime <''' + convert(nvarchar, EndTime, 120) + N'''

/*ограничиваем EndTime заданным часом и требуем, чтобы EndTime было не NULL (поскольку здесь при select into создаются nullable столбцы)*/
alter table ' + TableName +
N' with check add check (EndTime >= ''' + convert(nvarchar, StartTime, 120) + N''' and EndTime < ''' + convert(nvarchar, EndTime, 120) + N''' and EndTime is not null)
/*переключить несекционированную таблицу на нужную секцию секционированной таблицы*/
alter table ' + TableName + N' switch to ' + @fullTraceTableName + N' partition ' + convert(nvarchar(10), $partition.pfTrace(StartTime)) + 
+' drop table '+TableName
	from @tab 
	


/* -- Посмотреть какие часы уже были загружены
Select DateAdd(Hour,DATEDIFF(Hour,0,FT.StartTime),0),Count(*) 
from  __FullTraceAD_1_20120112 FT with(nolock)
group by DateAdd(Hour,DATEDIFF(Hour,0,FT.StartTime),0)
order by DateAdd(Hour,DATEDIFF(Hour,0,FT.StartTime),0)
*/