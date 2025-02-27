SET NOCOUNT ON
GO
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--SELECT object_id FROM sys.objects WHERE name = 'tblBlogs' --840390063
--SELECT object_id FROM sys.objects WHERE name = 'tblCities' --1877581727
--SELECT object_id FROM sys.objects WHERE name = 'tblApartmentDescriptions' --669245439
--SELECT object_id FROM sys.objects WHERE name = 'tblApartments' --501576825
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--создать процедуру генерации процедуры insert для P2P-репликаций
USE [master]
GO

IF OBJECT_ID('dbo.spP2P_GenerateInsertProcedure') IS NOT NULL
	DROP PROCEDURE dbo.spP2P_GenerateInsertProcedure
GO

CREATE PROCEDURE dbo.spP2P_GenerateInsertProcedure
	@object_id					INT,
	@generateNameOnly			BIT = 0,
	@prefix						NVARCHAR(20) = N'P2P_i_',
	@suffix						NVARCHAR(20) = N'',
	@procname					NVARCHAR(261) = NULL OUTPUT
AS
	SET NOCOUNT ON

	DECLARE
		@sql				NVARCHAR(MAX) = N'',
		@sqlPart			NVARCHAR(MAX),
		@standardInsert		NVARCHAR(MAX),
		@checkInsert		NVARCHAR(MAX),
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
	SET @checkInsert = ''
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

	SELECT @sqlPart += N'	' + par_name + N' ' + UPPER(typename) +
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
	--перечислять столбцы нужно в порядке их следования в таблице, а не первичном ключе
	ORDER BY c.column_num

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
	WHERE i.is_unique = 1
	  AND i.is_primary_key = 0
	  AND o.is_ms_shipped = 0
	  AND o.object_id = @object_id

	IF (SELECT COUNT(1) FROM @unique_columns) > 0
		SET @HasUniqueColumns = 1
		
	--определить наличие ключа, не являющегося identity-полем
	INSERT INTO @pk_nonidentity_columns (name, par_name)
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
	WHERE i.is_primary_key = 1
	  AND c.is_identity = 0
	  AND o.is_ms_shipped = 0
	  AND o.object_id = @object_id
	  
	IF (SELECT COUNT(1) FROM @pk_nonidentity_columns) > 0
		SET @HasNonIdentityPK = 1

	-- Генерация INSERT
	IF (@HasUniqueColumns = 0 AND @HasNonIdentityPK = 0)
	BEGIN
		--генерация insert
		SET @standardInsert = '    INSERT INTO ' + @fullTableName + ' ('
		SET @sqlPart = ''
		
		--генерировать перечисление стобцов для insert
		SELECT @sqlPart += @lineBreak + '		' + QUOTENAME(name) + ','
		FROM @columns
		ORDER BY column_num
		
		-- убрать запятую в конце выражения вставки в последнее поле
		SET @sqlPart = LEFT(@sqlPart, LEN(@sqlPart) - 1)
		
		SET @standardInsert += @sqlPart + @lineBreak + '	)' + @lineBreak + '    VALUES ('

		--генерировать выборку значений для вставки
		SET @sqlPart = ''
		
		SELECT @sqlPart += @lineBreak + '		' + par_name + ','
		FROM @columns
		ORDER BY column_num
		
		-- убрать запятую в конце выражения вставки в последнее поле
		SET @sqlPart = LEFT(@sqlPart, LEN(@sqlPart) - 1)
		
		SET @standardInsert += @sqlPart + @lineBreak + '	)' + '
END    
		'
		
		SET @sql += @lineBreak + @standardInsert
	END

	-- Генерация INSERT с проверкой
	IF @HasUniqueColumns = 1 OR @HasNonIdentityPK = 1
	BEGIN
		SET @checkInsert = ''
		
		-- генерировать проверку на существование записи
		IF @HasUniqueColumns = 1 AND @HasNonIdentityPK = 0
		BEGIN
			SELECT @checkInsert = '	IF NOT EXISTS (SELECT 1 FROM ' + @fullTableName + ' WHERE '
			SELECT @checkInsert += QUOTENAME(name) + ' = ' + par_name + ' AND '
			FROM @unique_columns
			
			SET @checkInsert = LEFT(@checkInsert, LEN(@checkInsert) - 4)
			
			SET @checkInsert += ')' + @lineBreak + '	BEGIN' + @lineBreak
		END
		ELSE IF @HasUniqueColumns = 0 AND @HasNonIdentityPK = 1
		BEGIN
			SELECT @checkInsert = '	IF NOT EXISTS (SELECT 1 FROM ' + @fullTableName + ' WHERE '
			SELECT @checkInsert += QUOTENAME(name) + ' = ' + par_name + ' AND '
			FROM @pk_nonidentity_columns
			
			SET @checkInsert = LEFT(@checkInsert, LEN(@checkInsert) - 4)
			
			SET @checkInsert += ')' + @lineBreak + '	BEGIN' + @lineBreak
		END
		ELSE IF @HasUniqueColumns = 1 AND @HasNonIdentityPK = 1
		BEGIN
			SELECT @checkInsert = '	IF NOT EXISTS (SELECT 1 FROM ' + @fullTableName + ' WHERE '
			SELECT @checkInsert += QUOTENAME(name) + ' = ' + par_name + ' AND '
			FROM @pk_nonidentity_columns
			
			SET @checkInsert = LEFT(@checkInsert, LEN(@checkInsert) - 4)
			
			SET @checkInsert += ')' + @lineBreak + '	BEGIN' + @lineBreak + '        IF NOT EXISTS (SELECT 1 FROM ' + @fullTableName + ' WHERE '
			
			SELECT @checkInsert += QUOTENAME(name) + ' = ' + par_name + ' AND '
			FROM @unique_columns
			
			SET @checkInsert = LEFT(@checkInsert, LEN(@checkInsert) - 4)
			
			SET @checkInsert += ')' + @lineBreak + '		BEGIN' + @lineBreak
			SET	@complexCheck = 1
		END
		
		IF @complexCheck = 1 SET @tabBreak = CHAR(9)
		--генерация insert
		SET @standardInsert = @tabBreak + '		INSERT INTO ' + @fullTableName + ' ('
		SET @sqlPart = ''
		
		--генерировать перечисление стобцов для insert
		SELECT @sqlPart += @lineBreak + @tabBreak + '			' + QUOTENAME(name) + ','
		FROM @columns
		ORDER BY column_num
		
		-- убрать запятую в конце выражения вставки в последнее поле
		SET @sqlPart = LEFT(@sqlPart, LEN(@sqlPart) - 1)
		
		SET @standardInsert += @sqlPart + @lineBreak + @tabBreak + '		)' + @lineBreak + @tabBreak + '        VALUES ('

		--генерировать выборку значений для вставки
		SET @sqlPart = ''
		
		SELECT @sqlPart += @lineBreak + @tabBreak + '			' + par_name + ','
		FROM @columns
		ORDER BY column_num
		
		-- убрать запятую в конце выражения вставки в последнее поле
		SET @sqlPart = LEFT(@sqlPart, LEN(@sqlPart) - 1)
		
		SET @standardInsert += @sqlPart + @lineBreak + @tabBreak + '		)' + @lineBreak + @tabBreak + '	END'
		
		--генерация кода для вставки в таблицу логгирования
		IF @complexCheck = 1
		BEGIN
			SET @logError += '
		ELSE
		BEGIN
			INSERT INTO P2P_ErrorsLog (DateOfAdded, Article, OperationType, ErrorProcString)
			VALUES (GETDATE(), '''

			SET @logError += OBJECT_NAME(@object_id) + ''', ''insert'', ''EXEC ' + @procname + ' ' 
			
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
			
			SET @logError += ')
		END
	END'
		
			SET @logError += '
	ELSE
	BEGIN
		INSERT INTO P2P_ErrorsLog (DateOfAdded, Article, OperationType, ErrorProcString)
		VALUES (GETDATE(), '''

			SET @logError += OBJECT_NAME(@object_id) + ''', ''insert'', ''EXEC ' + @procname + ' ' 
			
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
			
			SET @logError += ')
	END
END
			'
		
			SET @sql += @lineBreak + @checkInsert + @standardInsert + @logError
		END
		ELSE
		BEGIN
			SET @logError += '
	ELSE
	BEGIN
		INSERT INTO P2P_ErrorsLog (DateOfAdded, Article, OperationType, ErrorProcString)
		VALUES (GETDATE(), '''

			SET @logError += OBJECT_NAME(@object_id) + ''', ''insert'', ''EXEC ' + @procname + ' ' 
			
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
			
			SET @logError += ')
	END
END
			'

			SET @sql += @lineBreak + @checkInsert + @standardInsert + @logError
		END
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
Процедура перегенерации хранимой процедуры insert для P2P-репликации.
Вызывается автоматически при изменении структуры таблицы, участвующей в репликации
*/

IF OBJECT_ID('dbo.spP2P_script_custom_insert') IS NOT NULL
	DROP PROCEDURE dbo.spP2P_script_custom_insert
GO

CREATE PROCEDURE dbo.spP2P_script_custom_insert
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
	
--перегенерировать хранимую процедуру insert для таблицы
EXEC dbo.spP2P_GenerateInsertProcedure @object_id = @object_id
GO

------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--создать процедуры в каждой реплицируемой БД
USE [master]
GO

DECLARE
	@insert_proc_sql	NVARCHAR(MAX),
	@custom_script_proc	NVARCHAR(MAX),
	@sql				NVARCHAR(MAX),
	@db_name			sysname
--получить текст процедуры из БД master, чтобы создать её на всех реплицируемых БД

SELECT
	@insert_proc_sql = replace(OBJECT_DEFINITION(object_id('dbo.spP2P_GenerateInsertProcedure')), '''', ''''''),
	@custom_script_proc = replace(OBJECT_DEFINITION(object_id('dbo.spP2P_script_custom_insert')), '''', '''''')
	
DECLARE curDB CURSOR LOCAL FAST_FORWARD FOR
	SELECT name
	FROM sys.databases
	WHERE is_published = 1
OPEN curDB

FETCH NEXT FROM curDB INTO @db_name
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @sql = N'USE ' + QUOTENAME(@db_name)+'
IF OBJECT_ID(''dbo.spP2P_script_custom_insert'') IS NOT NULL
	DROP PROCEDURE dbo.spP2P_script_custom_insert'
	EXEC (@sql)
	
	SET @sql = N'USE ' + QUOTENAME(@db_name)+'
IF OBJECT_ID(''dbo.spP2P_GenerateInsertProcedure'') IS NOT NULL
	DROP PROCEDURE dbo.spP2P_GenerateInsertProcedure'
	EXEC (@sql)
	
	SET @sql = 'USE ' + QUOTENAME(@db_name)+'
EXEC('''+@insert_proc_sql+''')'
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

IF OBJECT_ID('dbo.spP2P_script_custom_insert') IS NOT NULL
	DROP PROCEDURE dbo.spP2P_script_custom_insert
GO

IF OBJECT_ID('dbo.spP2P_GenerateInsertProcedure') IS NOT NULL
	DROP PROCEDURE dbo.spP2P_GenerateInsertProcedure
GO