-- Убрать подписку с этой статьи
exec sp_dropsubscription   @publication =  'MoronFilials'
     ,  @article =  'ExLek2Serii' 	
     ,  @subscriber =  'All'	-- У всех подписчиков
     ,  @destination_db =  'Moron' 
  
-- Убрать саму статью
exec sp_droparticle  @publication =  'MoronFilials'
     ,  @article =  'ExLek2Serii'




-- MERGE REPLICATION
sp_dropmergearticle [ @publication= ] 'publication'
        , [ @article= ] 'article' 
    [ , [ @ignore_distributor= ] ignore_distributor 
    [ , [ @reserved= ] reserved 
    [ , [ @force_invalidate_snapshot= ] force_invalidate_snapshot ]
    [ , [ @force_reinit_subscription = ] force_reinit_subscription ]
    [ , [ @ignore_merge_metadata = ] ignore_merge_metadata ]


  

exec sp_dropsubscription   @publication =  'MoronFilials'
     ,  @article =  'ExLekNak' 
     ,  @subscriber =  'All'
     ,  @destination_db =  'Moron' 

exec sp_droparticle  @publication =  'MoronFilials'
     ,  @article =  'ExLekNak'

exec sp_dropsubscription   @publication =  'MoronFilials'
     ,  @article =  'ExNaklad' 
     ,  @subscriber =  'All'
     ,  @destination_db =  'Moron' 

exec sp_droparticle  @publication =  'MoronFilials'
     ,  @article =  'ExNaklad'



/*
-- Удалить колонку в таблице в репликации и переинициализтровать табличку

exec sp_articlecolumn @publication = N'Moron',
	 @article = N'Lek2Serii',
	 @column = N'Flags',
	 @operation = N'drop',
	 @force_reinit_subscription=1
*/