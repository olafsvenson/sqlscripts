**
sp_configure 'show advanced options', 1; 
GO 
RECONFIGURE; 
GO 
sp_configure 'Database Mail XPs', 1; 
GO 
RECONFIGURE 
GO

/*
TITLE: Microsoft SQL Server Management Studio
------------------------------

An exception occurred while executing a Transact-SQL statement or batch. (Microsoft.SqlServer.ConnectionInfo)

------------------------------
ADDITIONAL INFORMATION:

Mail not queued. Database Mail is stopped. Use sysmail_start_sp to start Database Mail. (Microsoft SQL Server, Error: 14641)

For help, click: http://go.microsoft.com/fwlink?ProdName=Microsoft+SQL+Server&ProdVer=10.50.1600&EvtSrc=MSSQLServer&EvtID=14641&LinkId=20476

------------------------------
BUTTONS:

OK
*/
------------------------------
exec msdb.dbo.sysmail_start_sp


���� ���-�� �� � �������, ������� ����� ���������� �� ������ ������:

SELECT top 20
	sent_status as [status]
	,* 
FROM msdb.dbo.sysmail_allitems 
--where recipients like '%sberfn.ru'
ORDER BY mailitem_id desc


� ����� ��������� � ���:

SELECT * FROM msdb.dbo.sysmail_event_log order  by log_date desc



--������� ������������ ������ ����� ���������� ����� SQL-��������:

SELECT sent_account_id, sent_date FROM msdb.dbo.sysmail_sentitems


--����� ��������� �������� ��������� Database Mail, ���������� ���� ������������� ���� ������ msdb � ������ ���� ���� ������ DatabaseMailUserRole � ���� ������ msdb. 
--����� �������� ������������� ��� ������ msdb � ��� ����, ����������� ����� ����� SQL Server Management Studio ��� ��������� ��������� ���������� ��� ������������ ��� ����, 
--������� ��������� ��������� ��������� Database Mail.


USE msdb;

--add our user
CREATE USER  QLickView_user FOR LOGIN  QLickView_user; 

--give this user rights to use dbmail
EXEC msdb.dbo.sp_addrolemember @rolename = 'DatabaseMailUserRole'
    ,@membername = 'SNH\VShevelev';
GO

