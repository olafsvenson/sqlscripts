use master
GO

exec sp_MSForEachDb '
use [?]

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[ActualDt]'') AND type in (N''U''))
select DB_NAME(),DT from actualDt'


