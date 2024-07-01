/*
   @schema_name - имя схемы, содержащей объект
   @object_name - имя таблицы или представления индекса
   @index_id - идентификатор индекса (значение NULL задается для всех индексов в таблице или представлении)
   @partition_number - номер раздела объекта, это значение может быть NULL или 1 для объектов, не разбитых на разделы
   @data_compression - тип оцениваемого сжатия (NONE,ROW,PAGE)
*/

EXEC sp_estimate_data_compression_savings 'dbo','sins_cloud_messages',NULL,NULL,'columnstore_archive'

EXEC sp_estimate_data_compression_savings 'dbo','RegistrationsAndFirstSalesDWH',NULL,NULL,'page'

select @@version
62 680 944
46 604 312

16[dbo].[sins_mail_messages]