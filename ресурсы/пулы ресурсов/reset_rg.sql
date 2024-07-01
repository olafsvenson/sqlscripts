/*    http://www.rsdn.ru/article/db/ResourceGovernor.xml

										Алгоритм reset_rg

   1. Отключить Resource Governor, предотвратив тем самым появление новых подключений в пользовательских группах.
   2. Закрыть командой kill все сессии, существующие в пользовательских группах нагрузки.
   3. Удалить все пользовательские группы из метаданных.
   4. Восстановить значения параметров группы default по умолчанию.
   5. Удалить все пользовательские пулы ресурсов.
   6. Восстановить значения параметров пула default по умолчанию.
   7. Отказаться от использования функции, указанной в конфигурации RG, в качестве классификатора.
   8. Применить сделанные изменения, выполнив реконфигурацию RG.

Если параметр @kill_session равен 1, процедура постарается закрыть все подключения, работающие в пользовательских группах. Сессиям, которые были отправлены в нокдаун, может потребоваться какое-то время на откат транзакций. Для этих целей предусмотрено ожидание завершения сессии на спин-блокировке (ожидание продлится не более чем указано в @spin_timeout).

	exec dbo.reset_rg 1


*/

create proc dbo.reset_rg (
  @kill_sessions    bit = 1  -- Принудительно завершать открытые сессии
)
as begin

set nocount on

declare
  -- Буфер для динамических вызовов
  @str_buffer    varchar(500)      
  
  --======= Переменные для работы с сессиями =======--
  -- Текущая сессия в цикле
  , @spid        int
  -- Максимальное время ожидания на spin-блокировке в секундах    
  , @spin_timeout    int      = 30
  -- Кол-во раундов spin-блокировки до "засыпания"  
  , @spin_count_limit  tinyint    = 5  
  -- Кол-во прошедших раундов spin-блокировки  
  , @spin_count    tinyint    = 0  
  -- Время входа в spin-блокировку  
  , @start_spining  datetime
  -- Признак того, что для тек. сессии уже была вызвана команда kill  
  , @kill_pending    bit          

  --======= Переменные для работы с группами =======--
  -- Идентификатор текущей группы нагрузки
  , @group_id      int    
  -- Имя текущей группы нагрузки      
  , @group_name    sysname        
  
  --======= Переменные для работы с пулами =======--
  -- Идентификатор текущего пула
  , @pool_id      int          
  -- Имя текущего пула
  , @pool_name    sysname        
  
  

/* 
  Так как мы собираемся избавиться от пользовательских групп,
  то сами должны работать либо в default, либо в internal.
*/
if (
  not exists(
    select *
    from sys.dm_exec_sessions
    where 
      session_id = @@SPID
      and (group_id = 1 or group_id = 2)
    )
)begin
  raiserror (
    N'Процедура запущена в сессии пользовательской группы нагрузки.', 16, 1)
  goto the_end  
end

-- Выключаем Resource Governor, чтобы новые подключения уже не могли
-- попасть в пользовательские группы нагрузки

alter resource governor disable

-- Если флажок @kill_sessions выставлен, 
-- отправим в кромешный Адлер все открытые соединения, 
-- существующие в пользовательских группах

-- Если @kill_sessions = 0 и сессии есть, то разразимся ошибкой.

while (1 = 1) begin

  set @spid = null

  select
    @spid = s.session_id
  from sys.dm_exec_sessions s
  inner join sys.resource_governor_workload_groups g on s.group_id = g.group_id
  where
    g.group_id != 1 and g.group_id != 2
  
  if ((@spid is not null) 
    and (@kill_sessions = 0)) 
    begin
    raiserror (N'В пользовательских группах есть сессии.', 16, 1)
    goto the_end
  end
  
  if (@spid is null) goto reset_metadata

  select
    @start_spining = getdate()
    , @kill_pending = 0
    , @spin_count = 0
    
  -- Принудительно завершаем текущую сессию 
  -- и ждём на spin-блокировке, пока она удалится
  while (exists(
    select * 
      from sys.dm_exec_sessions 
      where session_id = @spid)) begin
  
    set @spin_count+=1
    
    if (@kill_pending = 0) begin  
      set @str_buffer = 'kill ' + cast(@spid as varchar)
      exec (@str_buffer)
      set @kill_pending = 1
      print '[' + cast(@spid as varchar) + N'] произведён контрольный выстрел'
    end 
    
    print '[' + cast(@spid as varchar) + N'] сессия всё ещё жива, пульс в норме'
    
    if (@spin_count > @spin_count_limit)
      waitfor delay '00:00:01'
    
    if (DATEDIFF(ss, @start_spining, GETDATE()) > @spin_timeout) begin
      raiserror (
        N'Время ожидания истекло, сессия [%d] так и не умерла', 16, 1, @spid)
      goto the_end
    end
      
  end
  
  print '[' + cast(@spid as varchar) + N'] сессия отправилась в мир иной ' + char(134)
  
end

reset_metadata:

  begin tran
   
    while (1 = 1) begin    
    
      select
        @group_id = null
    
      select top 1
        @group_id = group_id
        , @group_name = name
      from sys.resource_governor_workload_groups
      where
        name != 'internal' 
        and name != 'default'
        
      
      if (@group_id is not null) begin
      
        set @str_buffer = 'drop workload group ' + quotename(@group_name)
        exec (@str_buffer)
        
        if @@error != 0 begin
          rollback
          goto the_end
        end
          
        print 
          quotename(@group_name) + N' группа нагрузки уничтожена ' + char(134) 
      end else
        break
    end  

    -- Восстанавливаем значения по умолчанию для группы default
    
    alter workload group [default]
    with (
      importance = medium
      , request_max_memory_grant_percent = 25
      , request_max_cpu_time_sec = 0
      , request_memory_grant_timeout_sec = 0
      , max_dop = 0
      , group_max_requests = 0
    )
    

    while (1 = 1) begin    
    
      select
        @pool_id = null
    
      select top 1
        @pool_id = pool_id
        , @pool_name = name
      from sys.resource_governor_resource_pools
      where
        name != 'internal' and name != 'default'
        
      if (@pool_id is not null) begin
      
        set @str_buffer = 'drop resource pool ' + quotename(@pool_name)
        exec (@str_buffer)
        
        if @@error != 0 begin
          rollback
          goto the_end
        end
        
        print quotename(@pool_name) + N' пул ресурсов уничтожен ' + char(134) 
      end else
        break
    end    

    -- Восстанавливаем значения по умолчанию для пула default    
    alter resource pool [default]
    with (
      min_cpu_percent = 0
      , max_cpu_percent = 100
      , min_memory_percent = 0
      , max_memory_percent = 100
    )

    -- Сбрасываем функцию-классификатор
    alter resource governor
    with (classifier_function = null)  
    
  commit
  
  -- Применяем настройки и включаем Resource Governor  
  alter resource governor reconfigure

the_end:
  -- Парадный выход
end
go
