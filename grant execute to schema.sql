-- 
GRANT EXECUTE ON SCHEMA::features  TO [PECOM\ApplicationReportView]

GRANT CREATE PROCEDURE TO [PECOM\ApplicationReportView]
GRANT ALTER ON SCHEMA::[features] TO [PECOM\ApplicationReportView];

-- через роль
CREATE ROLE db_executor
GRANT EXECUTE ON SCHEMA::schema_name TO db_executor
exec sp_addrolemember 'db_executor', 'Username'


-- к уже имеющимися обьектам
DECLARE @SchemaName varchar(20)
DECLARE @UserName varchar(20)

SET @SchemaName = 'dbo'
SET @UserName = 'user_name'

select 'GRANT EXECUTE ON OBJECT::' + @SchemaName + '.' + P.name  + ' to ' + @UserName
from sys.procedures P
inner join sys.schemas S on P.schema_id = S.schema_id
where S.name = @SchemaName