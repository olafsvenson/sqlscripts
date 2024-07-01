-- Еженедельный скрипт – подготовка очереди обработки статистик
USE pegasus2008ms
go
set nocount on

if object_id('sfp_statistics_current') is null
       CREATE TABLE sfp_statistics_current (
             ID INT PRIMARY KEY identity(1, 1)
             ,[Name] NVARCHAR(128)
             ,[TableName] NVARCHAR(256)
             ,[StartDT] DATETIME
             ,[EndDT] DATETIME
			 ,[LastError] nvarchar(512) null
             )
GO

if object_id('sfp_statistics_history') is null
       CREATE TABLE sfp_statistics_history (
             ID INT PRIMARY KEY identity(1, 1)
             ,[Name] NVARCHAR(128)
             ,[TableName] NVARCHAR(256)
             ,[LastDT] DATETIME
			 ,[Duration] int
			 ,[LastError] nvarchar(512) null
			 ,[Archived] int not null constraint def_archived default 0 
             )

GO



DECLARE @Name NVARCHAR(128)
       ,@TableName NVARCHAR(128)
       ,@DT DATETIME
       ,@Duration int;


/*	первоначальное заполнение
	получаем список индексов
*/
if not exists(select top 1 1 from sfp_statistics_history)
       insert into sfp_statistics_history ([Name], [TableName], [LastDT])
       select 
             i.name,
             t.name,
             GetDate()
       from sys.indexes i
             inner join sys.tables  t
				inner join sys.schemas s -- исключим объекты Change Data Capture
					on t.schema_id = s.schema_id
						and s.name != 'cdc'
             on i.object_id = t.object_id
				and t.name not in ('sfp_statistics_current', 'sfp_statistics_history') -- на всякий случай


-- переносим в архив ранее обработанные записи
DECLARE statistics_cursor CURSOR STATIC
FOR
SELECT  [Name]
       ,[TableName]
       ,[EndDT]
       ,datediff(ss, [StartDt], [EndDt]) as [Duration]
FROM sfp_statistics_current
WHERE [EndDT] IS NOT NULL

OPEN statistics_cursor

       FETCH NEXT
       FROM statistics_cursor
       INTO @name
             ,@tablename
             ,@DT
			 ,@duration

       WHILE @@FETCH_STATUS = 0
       BEGIN
             IF EXISTS (
                           SELECT 1
                           FROM sfp_statistics_history
                           WHERE [Name] = @name
                                  AND [TableName] = @tablename
                           )
                    UPDATE sfp_statistics_history
                    SET LastDT = @DT,
                          Duration = @duration
                    WHERE [Name] = @name
                           AND [Tablename] = @tablename
             ELSE
                    INSERT INTO sfp_statistics_history (
                            [Name]
                           ,[Tablename]
                           ,[LastDT]
                           ,[Duration]
                           )
                    VALUES (
                            @name
                           ,@tablename
                           ,@DT
                           ,@duration
                           )

             FETCH NEXT
             FROM statistics_cursor
             INTO @name
                 ,@tablename
                 ,@DT
                 ,@duration
END

CLOSE statistics_cursor;
DEALLOCATE statistics_cursor;

-- перенесли, теперь очищаем текущую очередь задач
TRUNCATE TABLE sfp_statistics_current

-- заполняем текущую очередь задач
INSERT INTO sfp_statistics_current (
        [Name]
       ,[TableName]
       )
SELECT t.[Name]
      ,t.[TableName]
FROM (
       -- [1] RecordSet - статистика использования индексов
       SELECT I.[Name] AS [Name]
             ,OBJECT_NAME(S.[object_id]) AS [TableName]
             ,ROW_NUMBER() OVER (
                    ORDER BY USER_SEEKS + USER_SCANS + USER_LOOKUPS -- сортируем по использованию
                    ) AS [Value] 
       FROM SYS.DM_DB_INDEX_USAGE_STATS AS S
       INNER JOIN SYS.INDEXES AS I ON I.[object_id] = S.[object_id]
             AND I.INDEX_ID = S.INDEX_ID
	   inner join sys.objects o
			on o.object_id = i.object_id
			and o.type = 'U' -- таблицы
	   inner join sys.schemas sch -- исключим объекты Change Data Capture
			on sch.schema_id = o.schema_id
			and sch.name != 'cdc'
       
       UNION ALL
       
       -- [2] RecordSet -- число изменений с момента пересчета статистик
	   /*
       SELECT i.NAME
             ,o.name [TableName]
             ,ROW_NUMBER() OVER (
                    ORDER BY i.rowmodctr
                    ) AS Value
       FROM sys.sysindexes i
       inner join sys.objects o
			on o.object_id = i.id
			and o.type = 'U' --таблицы
	   inner join sys.schemas sch --исключим объекты Change Data Capture
			on sch.schema_id = o.schema_id
			and sch.name != 'cdc'
       */
	   -- системная таблица sys.sysindexes deprecated поэтому новый вариант
	   SELECT 
		s.[name] as [Name],
		t.[name] as [TableName],
		ROW_NUMBER() OVER (
                    ORDER BY [sp].[modification_counter]
                    ) AS [Value]
			FROM [sys].[stats] s
		CROSS APPLY [sys].[dm_db_stats_properties]([s].[object_id],[s].[stats_id]) sp
		INNER JOIN [sys].[tables] t
			ON [s].[object_id] = [t].[object_id] 
	    where SCHEMA_NAME(t.schema_id) != 'cdc' -- исключим объекты Change Data Capture

       UNION ALL
       
       -- [3] RecordSet -- дата последнего пересчета 
       SELECT stat.[Name]
             ,stat.[TableName]
             ,ROW_NUMBER() OVER (
                    ORDER BY stat.[LastDT] DESC
                    ) AS [Value]
       FROM sfp_statistics_history stat
	   --проверим, что объекты существуют -- таблицы и индексы могли переименовать или удалить
	   inner join sys.objects o
			on stat.TableName = o.name
			and o.type = 'U'
	   inner join sys.indexes i
			on i.object_id = o.object_id
			and i.name = stat.[Name]
      ) T
where 
       t.[Name] is not null
	   and t.[TableName] not in ('sfp_statistics_current', 'sfp_statistics_history') 
GROUP BY 
		t.[Name]
       ,t.[TableName]
ORDER BY SUM(t.[Value]) DESC




/*
	Функционал по архивным записям не закончен
*/

-- Пометим как "архивные" записи о тех таблицах и индексах, которые были удалены из базы
update sfp_statistics_history
set Archived = 1
from sfp_statistics_history sr
left join sys.tables tbl 
	on sr.tableName = tbl.name
left join sys.indexes ndx
	on ndx.Name = sr.name
		and ndx.object_id = tbl.object_id
where Archived = 0
	and ndx.Name is null


-- И наоборот, вернем из архива те объекты, которые вернулись обратно
update sfp_statistics_history
set Archived = 0
from sfp_statistics_history sr
inner join sys.tables tbl 
	on sr.tableName = tbl.name
inner join sys.indexes ndx
	on ndx.Name = sr.name
		and ndx.object_id = tbl.object_id
where Archived = 1
	
