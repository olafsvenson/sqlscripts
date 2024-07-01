SET QUOTED_IDENTIFIER ON
GO
DECLARE @SQL NVARCHAR(MAX)=
(
	select 'Alter database ' + Quotename(name)+ ' SET RECOVERY SIMPLE'
	from sys.databases
	where 
	recovery_model_desc = N'FULL' 
	and database_id > 4
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'
);
PRINT @SQL
EXEC sp_executesql @SQL;


-- старый вариант
select name,recovery_model_desc,
'Alter database ' + Quotename(name)+ ' SET RECOVERY SIMPLE'
from sys.databases
where 
	recovery_model_desc = N'FULL' 
	--and name <> 'SberbankCSDDataMart'
	and database_id > 4




