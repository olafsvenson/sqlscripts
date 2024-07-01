-- ���������� ���������� � ������� �� ��������� ��������
declare @ActualDT table
(
      DatabaseName      sysname,
      DT                datetime,
      DiffMin			int				
      
)
insert into @ActualDT(DatabaseName, DT,DiffMin)
exec sp_MSforeachdb 'use [?]
if object_id(''?.dbo.ActualDT'') is not null
select db_name(),DT,DateDiff(minute,DT,GetDate()) from dbo.ActualDT with(nolock)
'

select * from @ActualDT
where DatabaseName not in ('LiveChatTrace','WorkflowPersistenceStore','AINotification','svadba','svadba system monitoring','AF','AFRContest2011','AWProfile','err-db','OrientBrides') 	-- ��������� ��, ������� �� �����������, � ������������� 1 ���
order by DatabaseName



