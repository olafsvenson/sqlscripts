/*
1 - удаляем всех подписчиков
2 - удаляем все публикации 
*/
-- удаляем регистрацию БД из репликации
exec sp_replicationdboption
          @dbname = 'svadba_catalog'
        , @optname = N'publish'
        , @value = N'false';



exec sp_removedbreplication 'svadba_catalog'

