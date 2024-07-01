
select top 5 * from [OB2\OB2].[svadba_c].[dbo].tblLetters

select top 5 * from [OB2].[svadba_c].[dbo].[tblLetters]
--[OB2].[svadba_c].[dbo].[tblLetters]
go
[OB2].[svadba_c].[dbo].[tblLetters]

exec sp_tables_ex 'OB2\OB2',@table_name='tblLetters',@table_catalog='svadba_c' 


use svadba_catalog
exec sp_AnWeb_Statistics