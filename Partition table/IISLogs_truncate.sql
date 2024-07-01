use IISLogs
--�������, ����� ������� ����� ��������� ������
declare @bound datetime = dateadd(month, -6, convert(date, getutcdate()))
--����� ������, ��������������� �������
declare @firstPartiton int = $partition.pfByDate(@bound)

--��� ������ �������� ������ ������ ������������ ��� ������������ ������ � ����������� ������� dbo.IISLog_truncate � �����������  � �������.
--������� dbo.IISLog_truncate ������ ����� ���������, ����������� ������� dbo.IISLog, ������� ������� � ��������� ������ ��������.
declare @sql nvarchar(max) = N''
select @sql += N'alter table dbo.IISLog switch partition '+CONVERT(nvarchar(10), partition_number) + N' to dbo.IISLog_truncate; truncate table dbo.IISLog_truncate;'+NCHAR(10)
	from sys.partitions
	where
		object_id = object_id(N'dbo.IISLog')
		--���� ��� ���������� ������ (�����������������).
		and index_id in (0,1)
		--���� ������
		and rows > 0
		--������ � ����� ������� �������
		and partition_number < @firstPartiton

--���� ������� ������ ��� �������, �� ��������
if @sql != N''
	exec (@sql)
