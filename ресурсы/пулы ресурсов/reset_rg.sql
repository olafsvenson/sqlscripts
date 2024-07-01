/*    http://www.rsdn.ru/article/db/ResourceGovernor.xml

										�������� reset_rg

   1. ��������� Resource Governor, ������������ ��� ����� ��������� ����� ����������� � ���������������� �������.
   2. ������� �������� kill ��� ������, ������������ � ���������������� ������� ��������.
   3. ������� ��� ���������������� ������ �� ����������.
   4. ������������ �������� ���������� ������ default �� ���������.
   5. ������� ��� ���������������� ���� ��������.
   6. ������������ �������� ���������� ���� default �� ���������.
   7. ���������� �� ������������� �������, ��������� � ������������ RG, � �������� ��������������.
   8. ��������� ��������� ���������, �������� �������������� RG.

���� �������� @kill_session ����� 1, ��������� ����������� ������� ��� �����������, ���������� � ���������������� �������. �������, ������� ���� ���������� � �������, ����� ������������� �����-�� ����� �� ����� ����������. ��� ���� ����� ������������� �������� ���������� ������ �� ����-���������� (�������� ��������� �� ����� ��� ������� � @spin_timeout).

	exec dbo.reset_rg 1


*/

create proc dbo.reset_rg (
  @kill_sessions    bit = 1  -- ������������� ��������� �������� ������
)
as begin

set nocount on

declare
  -- ����� ��� ������������ �������
  @str_buffer    varchar(500)      
  
  --======= ���������� ��� ������ � �������� =======--
  -- ������� ������ � �����
  , @spid        int
  -- ������������ ����� �������� �� spin-���������� � ��������    
  , @spin_timeout    int      = 30
  -- ���-�� ������� spin-���������� �� "���������"  
  , @spin_count_limit  tinyint    = 5  
  -- ���-�� ��������� ������� spin-����������  
  , @spin_count    tinyint    = 0  
  -- ����� ����� � spin-����������  
  , @start_spining  datetime
  -- ������� ����, ��� ��� ���. ������ ��� ���� ������� ������� kill  
  , @kill_pending    bit          

  --======= ���������� ��� ������ � �������� =======--
  -- ������������� ������� ������ ��������
  , @group_id      int    
  -- ��� ������� ������ ��������      
  , @group_name    sysname        
  
  --======= ���������� ��� ������ � ������ =======--
  -- ������������� �������� ����
  , @pool_id      int          
  -- ��� �������� ����
  , @pool_name    sysname        
  
  

/* 
  ��� ��� �� ���������� ���������� �� ���������������� �����,
  �� ���� ������ �������� ���� � default, ���� � internal.
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
    N'��������� �������� � ������ ���������������� ������ ��������.', 16, 1)
  goto the_end  
end

-- ��������� Resource Governor, ����� ����� ����������� ��� �� �����
-- ������� � ���������������� ������ ��������

alter resource governor disable

-- ���� ������ @kill_sessions ���������, 
-- �������� � ��������� ����� ��� �������� ����������, 
-- ������������ � ���������������� �������

-- ���� @kill_sessions = 0 � ������ ����, �� ���������� �������.

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
    raiserror (N'� ���������������� ������� ���� ������.', 16, 1)
    goto the_end
  end
  
  if (@spid is null) goto reset_metadata

  select
    @start_spining = getdate()
    , @kill_pending = 0
    , @spin_count = 0
    
  -- ������������� ��������� ������� ������ 
  -- � ��� �� spin-����������, ���� ��� ��������
  while (exists(
    select * 
      from sys.dm_exec_sessions 
      where session_id = @spid)) begin
  
    set @spin_count+=1
    
    if (@kill_pending = 0) begin  
      set @str_buffer = 'kill ' + cast(@spid as varchar)
      exec (@str_buffer)
      set @kill_pending = 1
      print '[' + cast(@spid as varchar) + N'] ��������� ����������� �������'
    end 
    
    print '[' + cast(@spid as varchar) + N'] ������ �� ��� ����, ����� � �����'
    
    if (@spin_count > @spin_count_limit)
      waitfor delay '00:00:01'
    
    if (DATEDIFF(ss, @start_spining, GETDATE()) > @spin_timeout) begin
      raiserror (
        N'����� �������� �������, ������ [%d] ��� � �� ������', 16, 1, @spid)
      goto the_end
    end
      
  end
  
  print '[' + cast(@spid as varchar) + N'] ������ ����������� � ��� ���� ' + char(134)
  
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
          quotename(@group_name) + N' ������ �������� ���������� ' + char(134) 
      end else
        break
    end  

    -- ��������������� �������� �� ��������� ��� ������ default
    
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
        
        print quotename(@pool_name) + N' ��� �������� ��������� ' + char(134) 
      end else
        break
    end    

    -- ��������������� �������� �� ��������� ��� ���� default    
    alter resource pool [default]
    with (
      min_cpu_percent = 0
      , max_cpu_percent = 100
      , min_memory_percent = 0
      , max_memory_percent = 100
    )

    -- ���������� �������-�������������
    alter resource governor
    with (classifier_function = null)  
    
  commit
  
  -- ��������� ��������� � �������� Resource Governor  
  alter resource governor reconfigure

the_end:
  -- �������� �����
end
go
