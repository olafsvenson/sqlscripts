SET NOCOUNT ON



DECLARE
@sql      VARCHAR(1000),
@table    CHAR(32),
@msg      VARCHAR(1000),
@ObjectID INT,
@IndexID  INT,
@MinBorderFrag int

--Таблица для результатов команды DBCC SHOWCONTIG
if OBJECT_ID('tempdb..#fraglist') is not null  DROP TABLE #fraglist

CREATE TABLE #fraglist(
ObjectName     CHAR(255),
ObjectId       INT,
IndexName      CHAR(255),
IndexId        INT,
Lvl            INT,
CountPages     INT,
CountRows      INT,
MinRecSize     INT,
MaxRecSize     INT,
AvgRecSize     INT,
ForRecCount    INT,
Extents        INT,
ExtentSwitches INT,
AvgFreeBytes   INT,
AvgPageDensity INT,
ScanDensity    DECIMAL,
BestCount      INT,
ActualCount    INT,
LogicalFrag    DECIMAL,
ExtentFrag     DECIMAL
)

--Выборка имен пользовательских таблиц текущей базы данных
DECLARE cur CURSOR FOR
SELECT so.[name] AS [table]
FROM dbo.sysobjects AS so
WHERE so.type='U'

-- Выставляем порог от которого начинаем дефрагментацию
set @MinBorderFrag = 25

--Заполнение таблицы #fraglist
OPEN cur
FETCH NEXT FROM cur INTO @table
WHILE @@FETCH_STATUS=0
BEGIN
	INSERT INTO #fraglist 
	EXEC ('DBCC SHOWCONTIG (''' + @table + ''') 
	WITH FAST, TABLERESULTS, ALL_INDEXES, NO_INFOMSGS')
	FETCH NEXT FROM cur INTO @table
END
CLOSE cur
DEALLOCATE cur

SELECT * FROM #fraglist



IF OBJECT_ID (N'tempdb..#tables_size', N'U') IS NOT NULL
	DROP TABLE #tables_size;	

create table #tables_size
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
    FOR select name from sysobjects where xtype = 'U' AND id IN (select DISTINCT OBJECTID FROM #fraglist)  order by name -- выбираем только те объекты для которых нет индексов
OPEN t_cursor
FETCH NEXT FROM t_cursor INTO @t_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    insert into #tables_size exec sp_spaceused @t_name
    FETCH NEXT FROM t_cursor INTO @t_name;
END
CLOSE t_cursor;
DEALLOCATE t_cursor;

SELECT 
	s.rows,
	i.*
FROM #fraglist i
	LEFT JOIN #tables_size s
		ON ObjectName = s.name
ORDER BY [rows] DESC,LogicalFrag desc



----   

DECLARE
@sql      VARCHAR(1000),
@table    CHAR(32),
@msg      VARCHAR(1000),
@ObjectID INT,
@IndexID  INT,
@MinBorderFrag int

-- Выставляем порог от которого начинаем дефрагментацию
set @MinBorderFrag = 25

--Дефрагментация индексов пользовательских таблиц

DECLARE cur CURSOR FOR
SELECT ObjectId,IndexId FROM #fraglist
WHERE INDEXPROPERTY(ObjectId, IndexName, 'IndexDepth') > 0
and LogicalFrag >= @MinBorderFrag

OPEN cur
FETCH NEXT FROM cur INTO @ObjectID, @IndexID
WHILE @@FETCH_STATUS=0
BEGIN
  SET @sql='DBCC INDEXDEFRAG (0,'+LTRIM(RTRIM(str(@ObjectID)))+','+LTRIM(RTRIM(str(@IndexID)))+')'
  EXEC (@sql)
  FETCH NEXT FROM cur INTO @ObjectID, @IndexID

END
CLOSE cur
DEALLOCATE cur

-- Octava