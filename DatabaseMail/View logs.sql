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


Если что-то не в порядке, сначала нужно посмотреть на статус письма:

SELECT top 20
	sent_status as [status]
	,* 
FROM msdb.dbo.sysmail_allitems 
--where recipients like '%sberfn.ru'
ORDER BY mailitem_id desc


А затем заглянуть в лог:

SELECT * FROM msdb.dbo.sysmail_event_log order  by log_date desc



--Успешно отправленные письма можно посмотреть таким SQL-запросом:

SELECT sent_account_id, sent_date FROM msdb.dbo.sysmail_sentitems


--Чтобы отправить почтовое сообщение Database Mail, необходимо быть пользователем базы данных msdb и членом роли базы данных DatabaseMailUserRole в базе данных msdb. 
--Чтобы добавить пользователей или группы msdb в эту роль, используйте среду Среда SQL Server Management Studio или выполните следующую инструкцию для пользователя или роли, 
--которым требуется отправить сообщение Database Mail.


USE msdb;

--add our user
CREATE USER  QLickView_user FOR LOGIN  QLickView_user; 

--give this user rights to use dbmail
EXEC msdb.dbo.sp_addrolemember @rolename = 'DatabaseMailUserRole'
    ,@membername = 'SNH\VShevelev';
GO

