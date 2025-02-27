--EXEC spP2P_script_custom_update 50
--EXEC spP2P_GenerateUpdateProcedure @object_id = 840390063
SET NOCOUNT ON
GO
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--SELECT object_id FROM sys.objects WHERE name = 'tblApartmentDescriptions' --669245439
--SELECT object_id FROM sys.objects WHERE name = 'tblApartments' --501576825
--SELECT object_id FROM sys.objects WHERE name = 'ActualDT' --1418540187
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--создать процедуру генерации процедуры update для P2P-репликаций
USE master
GO

IF OBJECT_ID('dbo.spP2P_GenerateUpdateProcedure') IS NOT NULL
	DROP PROCEDURE dbo.spP2P_GenerateUpdateProcedure
GO

CREATE PROCEDURE dbo.spP2P_GenerateUpdateProcedure
	@object_id					INT,
	@generateNameOnly			BIT = 0,
	@prefix						NVARCHAR(20) = N'P2P_u_',
	@suffix						NVARCHAR(20) = N'',
	@procname					NVARCHAR(261) = NULL OUTPUT
AS

SET NOCOUNT ON
DECLARE
	@sql				NVARCHAR(MAX) = N'',
	@sqlPart			NVARCHAR(MAX),
	@standardUpdate		NVARCHAR(MAX),
	@checkUpdate		NVARCHAR(MAX),
	@logError			NVARCHAR(MAX),
	@maskLength			INT,
	@fullTableName		NVARCHAR(261),
	@AllowUpdatePK		BIT = 0,
	@HasNonPKColumns	BIT = 0,
	@lineBreak			CHAR(1) = CHAR(13),
	@tabBreak			CHAR(1) = ''

--set @procname = N'dbo.' + quotename(@prefix + object_name(@object_id) + @suffix)
SET @procname = @prefix + OBJECT_NAME(@object_id) + @suffix

--если нужно генирировать только наименование, то завершить
IF @generateNameOnly = 1
	RETURN 1

DECLARE @columns TABLE
(
	column_num		INT,
	name			sysname,
	typeName		sysname,
	max_length		INT,
	[precision]		INT,
	scale			INT,
	is_primary_key	BIT,
	is_identity		BIT,
	pk_num			INT,
	is_rowguid		BIT,
	mask_byte		INT,
	mask_bit		INT,
	par_name		AS N'@c' + CONVERT(NVARCHAR(10), column_num),
	pk_name			AS N'@pkc' + CONVERT(NVARCHAR(10), pk_num),
	mask_substring  AS N'SUBSTRING(@bitmap, ' + CONVERT(NVARCHAR(10), mask_byte) + N', 1)',
	--маска для определения факта изменения данного столбца
	mask			AS CONVERT(nvarchar(10), POWER(2, mask_bit))
)

SET @fullTableName = QUOTENAME(OBJECT_SCHEMA_NAME(@object_id)) + N'.' + QUOTENAME(OBJECT_NAME(@object_id))

INSERT INTO @columns (
	column_num, name, typeName, max_length, [precision], scale, pk_num,
	is_primary_key, is_identity, is_rowguid,
	mask_byte,
	mask_bit
)
SELECT
	column_num, name, typeName, max_length, [precision], scale, pk_num,
	is_primary_key, is_identity, is_rowguid,
	mask_byte = (column_num + 7) / 8,
	mask_bit = (column_num - 1) % 8
FROM (
	SELECT
		column_num = ROW_NUMBER() OVER(ORDER BY c.column_id),
		c.name,
		typeName = t.name,
		c.max_length,
		c.[precision],
		c.scale,
		pk_num = ic.key_ordinal,
		is_primary_key = CASE WHEN ic.column_id IS NOT NULL THEN 1 ELSE 0 END,
		c.is_identity,
		is_rowguid = c.is_rowguidcol
	FROM sys.columns c
		INNER JOIN sys.types t
			ON t.user_type_id = c.user_type_id
		LEFT JOIN
			(
				sys.index_columns ic
				INNER JOIN sys.indexes i
					ON i.index_id = ic.index_id
				   AND i.[object_id] = ic.[object_id]
				   AND i.is_primary_key = 1
			)
			ON ic.[object_id] = c.[object_id]
		   AND ic.column_id = c.column_id
	WHERE
		c.object_id = @object_id
		--не включать столбцы timestamp
	AND t.name NOT IN (N'timestamp')
		--не включать вычисляемые столбцы
	AND c.is_computed = 0
) q

--длина маски изменённых столбцов
SET @MaskLength = CEILING(@@ROWCOUNT / 8.0)

--генерировать параметры - новые значения столбцов
SET @sqlPart = ''

SELECT @sqlPart += N'	' + par_name + N' ' + UPPER(typeName) +
	CASE
		WHEN typeName IN ('varchar', 'varbinary', 'binary') AND c.max_length > 0 THEN '(' + CONVERT(nvarchar(4), c.max_length) + ')'
		WHEN typeName IN ('nvarchar') AND c.max_length > 0 THEN '(' + CONVERT(nvarchar(4), c.max_length / 2) + ')'
		WHEN typeName IN ('varchar', 'nvarchar', 'varbinary', 'binary') AND c.max_length < 0 THEN '(MAX)'
		WHEN typeName IN ('datetime2') THEN '(' + CONVERT(nchar(1), c.scale) + ')'
		WHEN typeName IN ('decimal', 'numeric') THEN '(' + CONVERT(nvarchar(2), c.[precision]) + ',' + CONVERT(nvarchar(2), c.scale) + ')'
		ELSE ''
	END +
	N' = NULL,' + @lineBreak
FROM @columns c
--перечислять столбцы нужно в порядке их следования в таблице, а не первичном ключе
ORDER BY c.column_num

SET @sql += N'CREATE PROCEDURE ' + QUOTENAME(OBJECT_SCHEMA_NAME(@object_id)) + N'.' + @procname + @lineBreak + @sqlPart

--генерировать параметры - старые значения столбцов первичного ключа
SET @sqlPart = N''
SELECT @sqlPart += N'	' + pk_name + N' ' + UPPER(typeName) +
	CASE
		WHEN typeName IN ('varchar', 'varbinary', 'binary') AND c.max_length > 0 THEN '(' + CONVERT(nvarchar(4), c.max_length) + ')'
		WHEN typeName IN ('nvarchar') AND c.max_length > 0 THEN '(' + CONVERT(nvarchar(4), c.max_length / 2) + ')'
		WHEN typeName IN ('varchar', 'nvarchar', 'varbinary', 'binary') AND c.max_length < 0 THEN '(MAX)'
		WHEN typeName IN ('datetime2') THEN '(' + CONVERT(nchar(1), c.scale) + ')'
		WHEN typeName IN ('decimal', 'numeric') THEN '(' + CONVERT(nvarchar(2), c.[precision]) + ',' + CONVERT(nvarchar(2), c.scale) + ')'
		ELSE ''
	END +
	N' = NULL,' + @lineBreak
FROM @columns c
WHERE is_primary_key = 1
--перечислять столбцы нужно в порядке их следования в таблице, а не первичном ключе
ORDER BY c.column_num

--добавить параметр - маску обновления
SET @sql += @sqlPart + N'	@bitmap BINARY(' + CONVERT(nvarchar(4), @MaskLength) + N')
AS
BEGIN
'

SELECT @AllowUpdatePK = 0, @HasNonPKColumns = 1

--определить наличие первичного ключа, пригодного для update
IF EXISTS (SELECT 1 FROM @columns WHERE is_primary_key = 1 AND is_identity = 0 AND is_rowguid = 0)
	SET @AllowUpdatePK = 1
	
--определить отсутствие других столбцов, кроме столбцов первичного ключа
IF NOT EXISTS (SELECT 1 FROM @columns WHERE is_primary_key = 0 AND is_identity = 0 AND is_rowguid = 0)
	SET @HasNonPKColumns = 0

-- генерировать проверку на существование записи
SET @checkUpdate = ''

SELECT @checkUpdate = '	IF EXISTS (SELECT 1 FROM ' + @fullTableName + ' WHERE '
SELECT @checkUpdate += QUOTENAME(name) + ' = ' + pk_name + ' AND '
FROM @columns
WHERE is_primary_key = 1
ORDER BY pk_num

SET @checkUpdate = LEFT(@checkUpdate, LEN(@checkUpdate) - 4)

SET @checkUpdate += ')' + @lineBreak + '	BEGIN'

SET @sql += @checkUpdate

--генерация кода для вставки в таблицу логгирования
SET @logError = ''

SET @logError += '
	ELSE
	BEGIN
		INSERT INTO P2P_ErrorsLog (DateOfAdded, Article, OperationType, ErrorProcString)
		VALUES (GETDATE(), '''

		SET @logError += OBJECT_NAME(@object_id) + ''', ''update'', ''EXEC ' + @procname + ' '
		
		SELECT @logError += par_name + ' = ''' + ' + CASE WHEN ' + par_name + ' IS NULL THEN ''NULL'' ELSE ' + 
			CASE
				WHEN typeName IN ('image', 'varbinary', 'binary') THEN ''''''''' + CONVERT(NVARCHAR(MAX), CONVERT(VARBINARY(MAX), ' + par_name + '), 1) + ' + ''''''''' END + '
				WHEN typeName IN ('varchar', 'nvarchar', 'char', 'nchar', 'date', 'text', 'ntext', 'datetime', 'datetime2', 'smalldatetime') THEN ''''''''' + CAST(' + par_name + ' AS NVARCHAR(MAX)) + ' + ''''''''' END + '
				ELSE 'CAST(' + par_name + ' AS NVARCHAR(MAX)) END + '
			END
		+ ''', '
		FROM @columns
		ORDER BY column_num
				
		SET @logError = LEFT(@logError, LEN(@logError) - 5)
		
		SET @logError += ' + '', '
		
		SELECT @logError += pk_name + ' = ''' + 
			CASE
				WHEN typeName IN ('image', 'varbinary', 'binary') THEN ''''''''' + CONVERT(NVARCHAR(MAX), CONVERT(VARBINARY(MAX), ' + pk_name + '), 1) + ' + ''''''''' + '
				WHEN typeName IN ('varchar', 'nvarchar', 'char', 'nchar', 'date', 'text', 'ntext', 'datetime', 'datetime2', 'smalldatetime') THEN ''''''''' + CAST(' + pk_name + ' AS NVARCHAR(MAX)) + ' + ''''''''' + '
				ELSE ' + CAST(' + pk_name + ' AS NVARCHAR(MAX)) + '
			END
		+ ''', '
		FROM @columns
		WHERE pk_name IS NOT NULL
		ORDER BY pk_num
		
		SET @logError = LEFT(@logError, LEN(@logError) - 5)
		
		SET @logError += ' + '', @bitmap = ''' + ' + '''''''' + CONVERT(NVARCHAR(MAX), CONVERT(VARBINARY(MAX), @bitmap), 1) + '''''''''
		
		SET @logError += ')
	END'

IF @AllowUpdatePK = 1
	SET @tabBreak = CHAR(9)

IF @HasNonPKColumns = 1 OR @AllowUpdatePK = 0
BEGIN
	--стандартный update с поиском по новым значениям первичного ключа
	SET @standardUpdate = @tabBreak + '		UPDATE ' + @fullTableName + ' SET'
	SET @sqlPart = ''
	
	--генерировать изменение стобцов
	SELECT @sqlPart += @lineBreak + @tabBreak + '			' + QUOTENAME(name) + ' = CASE ' + mask_substring + ' & ' + mask + ' WHEN ' + mask + ' THEN ' + par_name
					   + ' ELSE ' + QUOTENAME(name) + ' END,'
	FROM @columns
	--!!!не включать rowguid и столбцы первичного ключа
	WHERE is_rowguid = 0 AND (is_primary_key = 0 OR @HasNonPKColumns = 0) AND is_identity = 0
	ORDER BY column_num
	
	-- убрать запятую в конце выражения обновления последнего параметра
	SET @sqlPart = LEFT(@sqlPart, LEN(@sqlPart) - 1)
	SET @standardUpdate += @sqlPart
	
	--генерировать условие where
	SET @sqlPart = ''
	
	SELECT @sqlPart += QUOTENAME(name) + ' = ' + pk_name + ' AND '
	FROM @columns
	WHERE is_primary_key = 1
	ORDER BY pk_num
	
	-- убрать AND в конце выражения обновления последнего параметра
	SET @sqlPart = LEFT(@sqlPart, LEN(@sqlPart) - 4)
	
	SET @standardUpdate += @lineBreak + @tabBreak + '		WHERE ' + @sqlPart + @lineBreak + @tabBreak + '	END'
END

--генерировать update для таблиц с изменяющимся первичным ключом
IF @AllowUpdatePK = 1
BEGIN
	--генерировать проверку изменения столбцов первичного ключа
	SET @sqlPart = ''
	
	SELECT @sqlPart += ' (' + mask_substring + ' & ' + mask +
	' = ' + mask + ') OR'
	FROM @columns
	WHERE is_primary_key = 1
	ORDER BY column_num
	
	-- убрать OR в конце выражения обновления последнего параметра
	SET @sqlPart = LEFT(@sqlPart, LEN(@sqlPart) - 3)
	
	SET @sql += '
		IF' + @sqlPart + N'
		BEGIN
			UPDATE ' + @fullTableName + ' SET'
	
	--генерировать изменение стобцов
	SET @sqlPart = ''
	SELECT @sqlPart += @lineBreak + '				' + QUOTENAME(name) + ' = CASE ' + mask_substring + ' & ' + mask + ' WHEN ' + mask + ' THEN ' + par_name
					   + ' ELSE ' + QUOTENAME(name) + ' END,'
	FROM @columns
	--!!!не включать rowguid
	WHERE is_rowguid = 0 AND is_identity = 0
	ORDER BY column_num
	
	-- убрать запятую в конце выражения обновления последнего параметра
	SET @sqlPart = LEFT(@sqlPart, LEN(@sqlPart) - 1)
	SET @sql += @sqlPart
	
	--генерировать условие where
	SET @sqlPart = ''
	
	SELECT @sqlPart += QUOTENAME(name) + ' = ' + pk_name + ' AND '
	FROM @columns
	WHERE is_primary_key = 1
	ORDER BY pk_num
	
	-- убрать AND в конце выражения обновления последнего параметра
	SET @sqlPart = LEFT(@sqlPart, LEN(@sqlPart) - 4)
	
	SET @sql += '
			WHERE ' + @sqlPart + '
		END'

	IF LEN(@standardUpdate) > 0
	BEGIN
		SET @sql += '
		ELSE
		BEGIN ' + @lineBreak + @standardUpdate + '
	END' + @logError
	END
	ELSE
	BEGIN
		SET @sql += '
	END' + @logError
	END
END
ELSE
BEGIN
	SET @sql += @lineBreak + @standardUpdate + @logError
END

SET @sql += @lineBreak + 'END'

--удалить процедуру
IF OBJECT_ID(@procname) IS NOT NULL
	EXEC(N'drop procedure ' + @procname)

--создать процедуру
EXEC sp_executesql @sql
GO

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
IF OBJECT_ID('dbo.spP2P_script_custom_update') is not null
	DROP PROCEDURE dbo.spP2P_script_custom_update
GO
/*
Процедура перегенерации хранимой процедуры update для P2P-репликации.
Вызывается автоматически при изменении структуры таблицы, участвующей в репликации
*/
CREATE PROCEDURE dbo.spP2P_script_custom_update
	--Идентификатор статьи репликации. Параметр обязательно должен иметь наименование @artid
	@artid	INT
AS
--проверить наличие репликации вообще
IF OBJECT_ID(N'dbo.sysarticles') is null
	RETURN 0
--получить идентификатор реплицируемой таблицы
DECLARE @object_id INT
SELECT @object_id = [objid] FROM dbo.sysarticles WHERE artid = @artid
--проверить наличие соответствующей статьи
IF @object_id IS NULL
	RETURN 0
	
--перегенерировать хранимую процедуру update для таблицы
EXEC dbo.spP2P_GenerateUpdateProcedure @object_id = @object_id
GO

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--создать процедуры в каждой реплицируемой БД
USE [master]
GO

DECLARE
	@update_proc_sql	NVARCHAR(MAX),
	@custom_script_proc	NVARCHAR(MAX),
	@sql		NVARCHAR(MAX),
	@db_name	sysname
--получить текст процедуры из БД master, чтобы создать её на всех реплицируемых БД
SELECT
	@update_proc_sql = replace(OBJECT_DEFINITION(object_id('dbo.spP2P_GenerateUpdateProcedure')), '''', ''''''),
	@custom_script_proc = replace(OBJECT_DEFINITION(object_id('dbo.spP2P_script_custom_update')), '''', '''''')
	
DECLARE curDB CURSOR LOCAL FAST_FORWARD FOR
	SELECT name
	FROM  sys.databases
	WHERE is_published = 1
OPEN curDB

FETCH NEXT FROM curDB INTO @db_name
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @sql = N'use ' + QUOTENAME(@db_name)+'
if OBJECT_ID(''dbo.spP2P_script_custom_update'') is not null
	drop procedure dbo.spP2P_script_custom_update'
	EXEC(@sql)
	
	SET @sql = N'use ' + QUOTENAME(@db_name)+'
if OBJECT_ID(''dbo.spP2P_GenerateUpdateProcedure'') is not null
	drop procedure dbo.spP2P_GenerateUpdateProcedure'
	EXEC(@sql)
	
	SET @sql = 'use ' + QUOTENAME(@db_name)+'
exec('''+@update_proc_sql+''')'
	EXEC(@sql)
	
	SET @sql = 'use ' + QUOTENAME(@db_name)+'
exec('''+@custom_script_proc+''')'
	EXEC(@sql)
	
	FETCH NEXT FROM curDB INTO @db_name
END
GO

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--удалить процедуры из БД master
USE [master]
GO

IF OBJECT_ID('dbo.spP2P_script_custom_update') IS NOT NULL
	DROP PROCEDURE dbo.spP2P_script_custom_update
GO

IF OBJECT_ID('dbo.spP2P_GenerateUpdateProcedure') IS NOT NULL
	DROP PROCEDURE dbo.spP2P_GenerateUpdateProcedure
GO