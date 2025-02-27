SET NOCOUNT ON
GO
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--SELECT object_id FROM sys.objects WHERE name = 'tblApartmentDescriptions' --669245439
--SELECT object_id FROM sys.objects WHERE name = 'tblApartments' --501576825
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--создать процедуру генерации процедуры delete для P2P-репликаций
USE [master]
GO

IF OBJECT_ID('dbo.spP2P_GenerateDeleteProcedure') IS NOT NULL
	DROP PROCEDURE dbo.spP2P_GenerateDeleteProcedure
GO

CREATE PROCEDURE dbo.spP2P_GenerateDeleteProcedure
	@object_id					INT,
	@generateNameOnly			BIT = 0,
	@prefix						NVARCHAR(20) = N'P2P_d_',
	@suffix						NVARCHAR(20) = N'',
	@procname					NVARCHAR(261) = NULL OUTPUT
AS
	SET NOCOUNT ON

	DECLARE
		@sql				NVARCHAR(MAX) = N'',
		@sqlPart			NVARCHAR(MAX),
		@standardDelete		NVARCHAR(MAX),
		@checkDelete		NVARCHAR(MAX),
		@logError			NVARCHAR(MAX),
		@fullTableName		NVARCHAR(261),
		@HasCompositePK		BIT = 0,
		@HasNonPKColumns	BIT = 0,
		@HasUniqueColumns	BIT = 0,
		@HasNonIdentityPK	BIT = 0,
		@lineBreak			CHAR(1) = CHAR(13),
		@tabBreak			CHAR(1) = '',
		@complexCheck		BIT = 0

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
		pk_num			INT,
		is_primary_key	BIT,
		is_identity		BIT,
		is_rowguid		BIT,
		par_name		AS N'@c' + CONVERT(NVARCHAR(10), column_num),
		pk_name			AS N'@pkc' + CONVERT(NVARCHAR(10), pk_num)
	)

	DECLARE @unique_columns TABLE
	(
		name			sysname,
		par_name		NVARCHAR(20)
	)

	DECLARE @pk_nonidentity_columns TABLE
	(
		name			sysname,
		par_name		NVARCHAR(20)
	)

	SET @fullTableName = QUOTENAME(OBJECT_SCHEMA_NAME(@object_id)) + N'.' + QUOTENAME(OBJECT_NAME(@object_id))
	SET @checkDelete = ''
	SET @logError = ''

	INSERT INTO @columns (
		column_num, name, typeName, max_length, [precision], scale, pk_num,
		is_primary_key, is_identity, is_rowguid
	)
	SELECT
		column_num, name, typeName, max_length, [precision], scale, pk_num,
		is_primary_key, is_identity, is_rowguid
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

	--генерировать параметры - новые значения столбцов
	SET @sqlPart = ''

	SELECT @sqlPart += N'	' + pk_name + N' ' + UPPER(typename) +
		CASE
			WHEN typeName IN ('varchar', 'varbinary', 'binary') AND c.max_length > 0 THEN '(' + CONVERT(NVARCHAR(4), c.max_length) + ')'
			WHEN typeName IN ('nvarchar') AND c.max_length > 0 THEN '(' + CONVERT(NVARCHAR(4), c.max_length / 2) + ')'
			WHEN typeName IN ('varchar', 'nvarchar', 'varbinary', 'binary') AND c.max_length < 0 THEN '(MAX)'
			WHEN typeName IN ('datetime2') THEN '(' + CONVERT(nchar(1), c.scale) + ')'
			WHEN typeName IN ('decimal', 'numeric') THEN '(' + CONVERT(NVARCHAR(2), c.[precision]) + ',' + CONVERT(NVARCHAR(2), c.scale) + ')'
			ELSE ''
		END + 
		N',' + @lineBreak
	FROM @columns c
	WHERE c.is_primary_key = 1
	--перечислять столбцы нужно в порядке их следования в таблице, а не первичном ключе
	ORDER BY c.pk_num

	SET @sqlPart = LEFT(@sqlPart, LEN(@sqlPart) - 2)

	SET @sql += N'CREATE PROCEDURE ' + QUOTENAME(OBJECT_SCHEMA_NAME(@object_id)) + N'.' + QUOTENAME(@procname) + @lineBreak + @sqlPart + N'
AS
BEGIN'

	SELECT @HasCompositePK = 0, @HasNonPKColumns = 1, 
		   @HasUniqueColumns = 0, @HasNonIdentityPK = 0

	--определить наличие составного первичного ключа
	IF (SELECT COUNT(1) FROM @columns WHERE is_primary_key = 1) > 1
		SET @HasCompositePK = 1
		
	--определить отсутствие других столбцов, кроме столбцов первичного ключа
	IF NOT EXISTS (SELECT 1 FROM @columns WHERE is_primary_key = 0 AND is_identity = 0 AND is_rowguid = 0)
		SET @HasNonPKColumns = 0

	--определить наличие полей с уникальным индексом
	INSERT INTO @unique_columns (name, par_name)
	SELECT c.name, col.par_name
	FROM sys.indexes i
		INNER JOIN sys.objects o
			ON i.object_id = o.object_id
		INNER JOIN sys.index_columns ic
			ON i.object_id = ic.object_id
		   AND i.index_id = ic.index_id
		INNER JOIN sys.columns c
			ON ic.column_id = c.column_id
		   AND ic.object_id = c.object_id
		INNER JOIN @columns col
			ON c.name = col.name COLLATE Cyrillic_General_BIN
	WHERE i.is_unique_constraint = 1
	  AND o.is_ms_shipped = 0
	  AND o.object_id = @object_id

	IF (SELECT COUNT(1) FROM @unique_columns) > 0
		SET @HasUniqueColumns = 1
		
	--определить наличие ключа, не являющегося identity-полем
	INSERT INTO @pk_nonidentity_columns (name, par_name)
	SELECT c.name, col.pk_name
	FROM sys.indexes i
		INNER JOIN sys.objects o
			ON i.object_id = o.object_id
		INNER JOIN sys.index_columns ic
			ON i.object_id = ic.object_id
		   AND i.index_id = ic.index_id
		INNER JOIN sys.columns c
			ON ic.column_id = c.column_id
		   AND ic.object_id = c.object_id
		INNER JOIN @columns col
			ON c.name = col.name COLLATE Cyrillic_General_BIN
	WHERE i.is_primary_key = 1
	  AND c.is_identity = 0
	  AND o.is_ms_shipped = 0
	  AND o.object_id = @object_id
	  
	IF (SELECT COUNT(1) FROM @pk_nonidentity_columns) > 0
		SET @HasNonIdentityPK = 1

	-- Генерация DELETE с проверкой
	IF EXISTS (SELECT 1 FROM @columns WHERE is_primary_key = 1)
	BEGIN
		SET @checkDelete = ''
		
		-- генерировать проверку на существование записи
		SELECT @checkDelete = '	IF EXISTS (SELECT 1 FROM ' + @fullTableName + ' WHERE '
		SELECT @checkDelete += QUOTENAME(name) + ' = ' + pk_name + ' AND '
		FROM @columns
		WHERE is_primary_key = 1
		ORDER BY pk_num
		
		SET @checkDelete = LEFT(@checkDelete, LEN(@checkDelete) - 4)
		
		SET @checkDelete += ')' + @lineBreak + '	BEGIN' + @lineBreak
		
		IF @complexCheck = 1 SET @tabBreak = CHAR(9)
		--генерация delete
		SET @standardDelete = @tabBreak + '		DELETE FROM ' + @fullTableName + @lineBreak + '		WHERE '
		SET @sqlPart = ''
		
		--генерировать перечисление стобцов для delete
		SELECT @sqlPart += QUOTENAME(name) + ' = ' + pk_name + ' AND '
		FROM @columns c
		WHERE is_primary_key = 1
		ORDER BY pk_num
		
		-- убрать запятую в конце выражения вставки в последнее поле
		SET @sqlPart = LEFT(@sqlPart, LEN(@sqlPart) - 4)
		
		SET @standardDelete += @sqlPart + @lineBreak + @tabBreak + '	END'
		
		--генерация кода для вставки в таблицу логгирования
		SET @logError += '
	ELSE
	BEGIN
		INSERT INTO P2P_ErrorsLog (DateOfAdded, Article, OperationType, ErrorProcString)
		VALUES (GETDATE(), '''

		SET @logError += OBJECT_NAME(@object_id) + ''', ''delete'', ''EXEC ' + @procname + ' ' 
		
		SELECT @logError += pk_name + ' = ''' +
			CASE
				WHEN typeName IN ('varchar', 'nvarchar', 'char', 'nchar', 'date', 'text', 'ntext', 'datetime', 'datetime2', 'smalldatetime') THEN ' + '''''''' + CAST(' + pk_name + ' AS NVARCHAR(MAX)) + '''''''' + '
				ELSE ' + CAST(' + pk_name + ' AS NVARCHAR(MAX)) + '
			END
			+ ''', '
		FROM @columns
		WHERE is_primary_key = 1
		ORDER BY pk_num
				
		SET @logError = LEFT(@logError, LEN(@logError) - 5)
		
		SET @logError += ')
	END
END
			'

		SET @sql += @lineBreak + @checkDelete + @standardDelete + @logError
	END

	--удалить процедуру
	IF OBJECT_ID(@procname) IS NOT NULL
		EXEC(N'DROP PROCEDURE ' + @procname)

	--создать процедуру
	EXEC sp_executesql @sql
GO

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
/*
Процедура перегенерации хранимой процедуры delete для P2P-репликации.
Вызывается автоматически при изменении структуры таблицы, участвующей в репликации
*/

IF OBJECT_ID('dbo.spP2P_script_custom_delete') IS NOT NULL
	DROP PROCEDURE dbo.spP2P_script_custom_delete
GO

CREATE PROCEDURE dbo.spP2P_script_custom_delete
	--Идентификатор статьи репликации. Параметр обязательно должен иметь наименование @artid
	@artid	INT
AS
--проверить наличие репликации вообще
IF OBJECT_ID(N'dbo.sysarticles') IS NULL
	RETURN 0
--получить идентификатор реплицируемой таблицы
DECLARE @object_id INT
SELECT @object_id = [objid] FROM dbo.sysarticles WHERE artid = @artid
--проверить наличие соответствующей статьи
IF @object_id IS NULL
	RETURN 0
	
--перегенерировать хранимую процедуру delete для таблицы
EXEC dbo.spP2P_GenerateDeleteProcedure @object_id = @object_id
GO

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--создать процедуры в каждой реплицируемой БД
USE [master]
GO

DECLARE
	@delete_proc_sql	NVARCHAR(MAX),
	@custom_script_proc	NVARCHAR(MAX),
	@sql				NVARCHAR(MAX),
	@db_name			sysname
--получить текст процедуры из БД master, чтобы создать её на всех реплицируемых БД

SELECT
	@delete_proc_sql = replace(OBJECT_DEFINITION(object_id('dbo.spP2P_GenerateDeleteProcedure')), '''', ''''''),
	@custom_script_proc = replace(OBJECT_DEFINITION(object_id('dbo.spP2P_script_custom_delete')), '''', '''''')
	
DECLARE curDB CURSOR LOCAL FAST_FORWARD FOR
	SELECT name
	FROM sys.databases
	WHERE is_published = 1
OPEN curDB

FETCH NEXT FROM curDB INTO @db_name
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @sql = N'USE ' + QUOTENAME(@db_name)+'
IF OBJECT_ID(''dbo.spP2P_script_custom_delete'') IS NOT NULL
	DROP PROCEDURE dbo.spP2P_script_custom_delete'
	EXEC (@sql)
	
	SET @sql = N'USE ' + QUOTENAME(@db_name)+'
IF OBJECT_ID(''dbo.spP2P_GenerateDeleteProcedure'') IS NOT NULL
	DROP PROCEDURE dbo.spP2P_GenerateDeleteProcedure'
	EXEC (@sql)
	
	SET @sql = 'USE ' + QUOTENAME(@db_name)+'
EXEC('''+@delete_proc_sql+''')'
	EXEC(@sql)
	
	SET @sql = 'USE ' + QUOTENAME(@db_name)+'
EXEC('''+@custom_script_proc+''')'
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

IF OBJECT_ID('dbo.spP2P_script_custom_delete') IS NOT NULL
	DROP PROCEDURE dbo.spP2P_script_custom_delete
GO

IF OBJECT_ID('dbo.spP2P_GenerateDeleteProcedure') IS NOT NULL
	DROP PROCEDURE dbo.spP2P_GenerateDeleteProcedure
GO