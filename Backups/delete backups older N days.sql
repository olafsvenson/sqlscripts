DECLARE @query nvarchar(200)

SET @query = 'EXECUTE master.dbo.xp_delete_file 0,N''\\1c-d-sql\Backup\1c-u-sql\1C_Avancore_PIF_Dzhevlakh\FULL'',N''bak'',N'''+CAST(DATEADD(dd,-2,GETDATE()) AS NVARCHAR(200))+''',1' -- -2 дн€
--SET @query = 'EXECUTE master.dbo.xp_delete_file 0,N''\\1c-d-sql\Backup\1c-u-sql\'',N''bak'',N'''+CAST(DATEADD(dd,-2,GETDATE()) AS NVARCHAR(200))+''',1' -- -2 мес€ца
--select @query
exec (@query)

