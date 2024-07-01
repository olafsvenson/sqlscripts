/*
	����� ������ � LS
*/



--	���� ������ ���������� ��� ������ ����� ����, ������� �� ������� Primary 

select a.name, b.backup_set_id, b.backup_finish_date, b.[type], c.physical_device_name
from master.sys.databases a 
join msdb.[dbo].[backupset] b  
on a.name = b.database_name collate database_default
join msdb.[dbo].[backupmediafamily] c
on b.media_set_id = c.media_set_id
where a.name = '<your_db_name>' 
order by b.backup_finish_date


-- ���� ���������� ��� ���������� ������, ��� ������� �� standby

select a.destination_database_name, a.restore_date, a.restore_type, 
                  a.backup_set_id, b.media_set_id, b.first_lsn, b.last_lsn, d.physical_device_name
from msdb.[dbo].[restorehistory] a
join msdb.[dbo].[backupset] b
on a.destination_database_name = b.database_name
and a.backup_set_id = b.backup_set_id
join msdb.[dbo].[backupmediaset] c
on b.media_set_id = c.media_set_id
join msdb.[dbo].[backupmediafamily] d
on d.media_set_id = b.media_set_id
where a.destination_database_name = '<your_db_name>'
order by a.restore_date


-- � ������ ����� ��������� ���������� ����� �� Standby, ������ � ��������� ������� �� Primary. ���� ��������� ����� � ��������� ����� ��� ���� � ��� �� ���� - �� ���� standby ��������������� � primary. ����� ���������� ����� ����� �������� �������. ���� �� primary � standby �� ���������������� � ���������� ���� �� ������������ - �� ���� ������ ������� �������� ��������. ��������� ��������� ����� �� �����, ��������, �� ������� standby.



-- ����� ������ �� �����
SELECT TOP (30) [agent_id]
      ,[agent_type]
      ,[session_id]
      ,[database_name]
      ,[sequence_number]
      ,[log_time]
      ,[log_time_utc]
      ,[message]
      ,[source]
      ,[help_url]
  FROM [msdb].[dbo].[log_shipping_monitor_error_detail]
  ORDER BY log_shipping_monitor_error_detail.log_time desc