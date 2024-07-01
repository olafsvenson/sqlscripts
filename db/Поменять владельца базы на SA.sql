-- вариант 1
SELECT 'ALTER AUTHORIZATION ON DATABASE::['+name+'] TO [sa]' FROM sys.databases
where 
		owner_sid<>0x01 -- sa
		--owner_sid=0x010500000000000515000000E7A3401BC6DDD334D54813E8A7090000 -- SFN\vzheltonogov.adm

 
-- вариант 2
DECLARE @SQL NVARCHAR(MAX)=
(
	SELECT 'ALTER AUTHORIZATION ON DATABASE::['+name+'] TO [sa]' FROM sys.databases
	where 
		owner_sid<>0x01 -- sa
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'
);
PRINT @SQL
EXEC sp_executesql @SQL;


 -- вариант 3 dbatools
 Set-DbaDbOwner -SqlInstance sql-u-01, sql-i-01, sql-pp-01, sql-d-01 

 sp_whoisactive