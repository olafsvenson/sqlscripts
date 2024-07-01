SELECT
    col.name, col.collation_name
FROM 
    sys.columns col
WHERE
    object_id = OBJECT_ID('[dbo].[OptimizeDBIndexesList]')


	ALTER TABLE YourTableName
  ALTER COLUMN OffendingColumn
    VARCHAR(100) COLLATE Latin1_General_CI_AS NOT NULL


DECLARE @tableName VARCHAR(MAX)
SET @tableName = 'affiliate'
--EXEC sp_columns @tableName
SELECT  'Alter table ' + @tableName + ' alter column ' + col.name
        + CASE ( col.user_type_id )
            WHEN 231
            THEN ' nvarchar(' + CAST(col.max_length / 2 AS VARCHAR) + ') '
          END + 'collate Latin1_General_CI_AS ' + CASE ( col.is_nullable )
                                                    WHEN 0 THEN ' not null'
                                                    WHEN 1 THEN ' null'
                                                  END
FROM    sys.columns col
WHERE   object_id = OBJECT_ID(@tableName)    


/*

Identify the fields for which it is throwing this error and add following to them: COLLATE DATABASE_DEFAULT

There are two tables joined on Code field:

...
and table1.Code = table2.Code
...

Update your query to:

...
and table1.Code COLLATE DATABASE_DEFAULT = table2.Code COLLATE DATABASE_DEFAULT
*/