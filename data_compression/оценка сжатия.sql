/*
   @schema_name - ��� �����, ���������� ������
   @object_name - ��� ������� ��� ������������� �������
   @index_id - ������������� ������� (�������� NULL �������� ��� ���� �������� � ������� ��� �������������)
   @partition_number - ����� ������� �������, ��� �������� ����� ���� NULL ��� 1 ��� ��������, �� �������� �� �������
   @data_compression - ��� ������������ ������ (NONE,ROW,PAGE)
*/

EXEC sp_estimate_data_compression_savings 'dbo','sins_cloud_messages',NULL,NULL,'columnstore_archive'

EXEC sp_estimate_data_compression_savings 'dbo','RegistrationsAndFirstSalesDWH',NULL,NULL,'page'

select @@version
62 680 944
46 604 312

16[dbo].[sins_mail_messages]