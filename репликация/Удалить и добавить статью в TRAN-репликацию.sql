USE svadba_catalog
GO

-- Убрать подписку с этой статьи
EXEC sp_dropsubscription
	@publication = 'ExportCustomerData',
	@article = 'tblLinkMenChildren',
	@subscriber = 'ALL', 
	@destination_db = 'svadba_catalog' 
  
-- Убрать саму статью
EXEC sp_droparticle
	@publication = 'ExportCustomerData',
	@article =  'tblLinkMenChildren'

-- Добавить статью в репликацию
EXEC sp_addarticle
	@publication = 'ExportCustomerData',
	@article = 'tblLinkMenChildren',
	@source_object = 'tblLinkMenChildren',
	@destination_table = 'tblLinkMenChildren'

EXEC sp_refreshsubscriptions N'ExportCustomerData'

-- После этого надо запустить snapshot agent и репликацию