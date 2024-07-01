-- просмотр
select 'ALTER LOGIN ' + QuoteName(name) + ' WITH CHECK_POLICY = ON, CHECK_EXPIRATION=OFF;'
from sys.sql_logins 
where is_policy_checked = 0


-- изменение
DECLARE @SQL NVARCHAR(MAX)=
(
	select 'ALTER LOGIN ' + QuoteName(name) + ' WITH CHECK_POLICY = ON, CHECK_EXPIRATION=OFF;'
	from sys.sql_logins 
	where is_policy_checked = 0 
	FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'
);

PRINT @SQL
--EXEC sp_executesql @SQL;