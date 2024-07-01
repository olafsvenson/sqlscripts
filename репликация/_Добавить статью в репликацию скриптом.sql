-- Добавить статью в репликацию скриптом
-- После этого надо запустить snapshot agent и репликацию
exec sp_addmergearticle  @publication =  'MyPublication'
     ,  @article =  'tblClients2FacebookClients' 
     ,  @source_object=  'tblClients2FacebookClients' 
     

exec sp_dropmergearticle @publication =  'MyPublication'
        ,  @article=  'tblClients2FacebookClients' 



exec sp_refreshsubscriptions N'MySubsc'


@replicate_ddl = 0



exec sp_changemergepublication  @publication=  'MyPublication'
     ,  @property=  'replicate_ddl' 
     ,  @value=  '1' 
	 ,  @force_invalidate_snapshot = 1
	 ,  @force_reinit_subscription = 1


/*
-- Добавить колонку в таблице в репликации
exec sp_articlecolumn @publication = N'Moron',
	 @article = N'OpisLek',
	 @column = N'KodTemperature',
	 @operation = N'add', 
	 @force_invalidate_snapshot = 1,
	 @force_reinit_subscription = 1

*/
