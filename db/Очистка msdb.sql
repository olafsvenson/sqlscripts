-- (1) ���� ������������ ��� ������� �������� ��������� sysmail_delete_mailitems_sp � sysmail_delete_log_sp:

DECLARE @DateBefore DATETIME 
SET @DateBefore = DATEADD(DAY, -7, GETDATE())

EXEC msdb.dbo.sysmail_delete_mailitems_sp @sent_before = @DateBefore --, @sent_status = 'sent'
EXEC msdb.dbo.sysmail_delete_log_sp @logged_before = @DateBefore

-- ��������
SELECT count(1) FROM msdb.dbo.sysmail_mailitems with (nolock) 


-- (2) ������� ���������� ������� SQL Server Agent ����� ����������� � msdb. ����� ������� � ���� ���������� ����� � ��� ���������� �� ������ ������ ��������, ������� � �������� ��� ������������ ������� sp_purge_jobhistory:

DECLARE @DateBefore DATETIME 
SET @DateBefore = DATEADD(DAY, -7, GETDATE())

EXEC msdb.dbo.sp_purge_jobhistory @oldest_date = @DateBefore

-- (3) ��� ����� ���������, ��� ���������� � ��������� ������, ������� ���������� � msdb. ������ ������ � ��������� ������� ����� ������� sp_delete_backuphistory:

DECLARE @DateBefore DATETIME 
SET @DateBefore = DATEADD(DAY, -120, GETDATE())

EXEC msdb.dbo.sp_delete_backuphistory @oldest_date = @DateBefore