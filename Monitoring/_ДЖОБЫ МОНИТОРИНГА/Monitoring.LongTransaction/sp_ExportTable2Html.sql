USE [master]
GO

/****** Object:  StoredProcedure [dbo].[sp_ExportTable2Html]    Script Date: 16.02.2023 16:25:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE or alter PROCEDURE [dbo].[sp_ExportTable2Html]
	@TableName [varchar](max),
	@UseStandartStyle BIT = 1,
	@Alignment VARCHAR(10) = 'left',
	@OrderBy VARCHAR(MAX) = '',
	@Script VARCHAR(MAX) OUTPUT
AS
BEGIN

SET NOCOUNT ON
	
	DECLARE
	@query NVARCHAR(MAX),
	@Database sysname,
	@Tabel sysname
	
	IF (LEFT(@TableName, 1) = '#')
	BEGIN
		SET @Database = 'tempdb.'
		SET @Tabel = @TableName
	END
	ELSE 
	BEGIN
		SET @Database = LEFT(@TableName, CHARINDEX('.', @TableName))
		SET @Tabel = SUBSTRING(@TableName, LEN(@TableName) - CHARINDEX('.', REVERSE(@TableName)) + 2, LEN(@TableName))
	END
	
	SET @query = '
	SELECT ORDINAL_POSITION, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE
	FROM ' + @Database + 'INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_NAME = ''' + @Tabel + '''
	ORDER BY ORDINAL_POSITION'
	
	IF (OBJECT_ID('tempdb..#Columns') IS NOT NULL) DROP TABLE #Columns
	CREATE TABLE #Columns (
		ORDINAL_POSITION int, 
		COLUMN_NAME sysname, 
		DATA_TYPE nvarchar(128), 
		CHARACTER_MAXIMUM_LENGTH int,
		NUMERIC_PRECISION tinyint, 
		NUMERIC_SCALE int
		)
	
	INSERT INTO #Columns
	EXEC(@query)
	
	IF (@UseStandartStyle = 1)
	BEGIN
	SET @Script = '<html>
		<head>
		<title>Title</title>
		<style type="text/css">
		table { padding:0; border-spacing: 0; border-collapse: collapse;  }
		thead { background: #00B050; border: 1px solid #ddd; }
		th { padding: 10px; font-weight: bold; border: 1px solid #000; color: #fff;}
		tr { padding: 0; }
		td { padding: 5px; border: 1px solid #cacaca; margin:0; text-align:' + @Alignment + '; }
		</style>
		</head>'
	END

SET @Script = ISNULL(@Script, '') + '
	<table>
	<thead>
	<tr>'

-- Заголовок таблицы
	DECLARE 
	@curColumns INT = 1, 
	@totalColumns INT = (SELECT COUNT(*) FROM #Columns), 
	@ColunmnName sysname,
	@ColumnType sysname

	WHILE(@curColumns <= @totalColumns)
	BEGIN
		SELECT @ColunmnName = COLUMN_NAME
		FROM #Columns
		WHERE ORDINAL_POSITION = @curColumns

		SET @Script = ISNULL(@Script, '') + '
		<th>' + @ColunmnName + '</th>'

		SET @curColumns = @curColumns + 1
	END

	SET @Script = ISNULL(@Script, '') + '
	</tr>
	</thead>
	<tbody>'

-- Содержание таблицы
DECLARE @Str VARCHAR(MAX)

	SET @query = '
	SELECT @Str = (
	SELECT '

	SET @curColumns = 1

	WHILE(@curColumns <= @totalColumns)
	BEGIN
		SELECT 
		@ColunmnName = COLUMN_NAME,
		@ColumnType = DATA_TYPE
		FROM 
		#Columns
		WHERE 
		ORDINAL_POSITION = @curColumns

	IF (@ColumnType IN ('int', 'bigint', 'float', 'numeric', 'decimal', 'bit', 'tinyint', 'smallint', 'integer'))
	BEGIN
		SET @query = @query + '
		ISNULL(CAST([' + @ColunmnName + '] AS VARCHAR(MAX)), '''') AS [td]'
	END
	ELSE BEGIN
		SET @query = @query + '
		ISNULL([' + @ColunmnName + '], '''') AS [td]'
	END

	IF (@curColumns < @totalColumns)
		SET @query = @query + ','
		SET @curColumns = @curColumns + 1
	END

	SET @query = @query + '
	FROM ' + @TableName + (CASE WHEN ISNULL(@OrderBy, '') = '' THEN '' ELSE ' 
	ORDER BY ' END) + @OrderBy + '
	FOR XML RAW(''tr''), Elements
	)'
	EXEC tempdb.sys.sp_executesql
	@query,
	N'@Str NVARCHAR(MAX) OUTPUT',
	@Str OUTPUT

	SET @Str = REPLACE(@Str, '<tr>', '
	<tr>')
	SET @Str = REPLACE(@Str, '<td>', '
	<td>')
	SET @Str = REPLACE(@Str, '</tr>', '
	</tr>')
	SET @Script = ISNULL(@Script, '') + @Str
	SET @Script = ISNULL(@Script, '') + '
	</tbody>
	</table>'
END
GO


