declare @id int
select @id=OBJECT_ID('tblGirls')
EXEC sys.sp_identitycolumnforreplication @id, 0 -- 0,1 = ��������/���������� ��-��



ALTER TABLE [dbo].[tblgirls] ALTER COLUMN [girlid] ADD NOT FOR REPLICATION