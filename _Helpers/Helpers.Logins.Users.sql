use master
go

set quoted_identifier on;
set nocount on;
go


create or alter proc #AddUser2Role(@DbName sysname, @RoleName sysname,  @UserName sysname)
as

declare @Query nvarchar(max);

set @Query = '
Use ' + QUOTENAME(@DbName)+'

if IS_ROLEMEMBER(''' + @RoleName + ''',''' + @UserName + ''') is null 
begin
	print ''[+] Пользователь '+  quotename(@UserName) + ' добавлен в роль '+QUOTENAME(@RoleName) +'''
	--ALTER ROLE ' + QUOTENAME(@RoleName) +' ADD MEMBER ' + QUOTENAME(@UserName) + '
end 
else
	print ''[-] Пользователь' + quotename(@Username)+ ' уже добавлен в роль '+ QUOTENAME(@RoleName)+'''';

print @Query;
-- exec (@Query)
GO

--exec #AddUser2Role 'PythiaAgent','PythiaUsersRole','SFN\pifrobot-u-svc'

create or alter proc #CreateLogin (@LoginName sysname)
as
declare @Query nvarchar(max);

set @Query = '
IF NOT EXISTS (SELECT 1 FROM master.sys.server_principals WHERE [name] = N''' + @LoginName + ''' and [type] IN (''C'',''E'', ''G'', ''K'', ''S'', ''U''))
begin
	print ''[+] Создание логина ' + Quotename(@LoginName)+'''
	--CREATE LOGIN ' + Quotename(@LoginName) +' FROM WINDOWS WITH DEFAULT_DATABASE=[master]
end
else
	print ''[-] Логин ' + Quotename(@LoginName)+' уже существует''';

	print @Query;
	-- exec(@Query);
GO


exec #CreateLogin 'SFN\pifrobot-u-svc'

/*
IF NOT EXISTS (SELECT 1 FROM master.sys.server_principals WHERE [name] = N'SFN\pifrobot-u-svc' and [type] IN ('C','E', 'G', 'K', 'S', 'U'))
begin
	print '[+] Создание логина [SFN\pifrobot-u-svc]'
	--CREATE LOGIN [SFN\pifrobot-u-svc] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
end
else
	print '[-] Логин [SFN\pifrobot-u-svc] уже существует'

go;
*/

create or alter proc #CreateUser (@DbName sysname, @UserName sysname)
as
declare @Query nvarchar(max);

set @Query = '
Use ' + QUOTENAME(@DbName)+'

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE [name] = N''' + @UserName + ''' and [type] IN (''C'',''E'', ''G'', ''K'', ''S'', ''U'')) 
begin
	print ''[+] Создание пользователя '+  quotename(@UserName) +' в базе ' + quotename(@DbName)+'''
	--CREATE USER ' + quotename(@UserName) + ' FOR LOGIN ' + QUOTENAME(@UserName)+ '
end 
else
	print ''[-] Пользователь ' + quotename(@Username)+ ' уже существует в базе ' + quotename(@DbName)+'''';

print @Query;
-- exec(@Query)
GO


exec #CreateUser 'PythiaAgent','SFN\pifrobot-u-svc'

/*

Use [PythiaAgent]

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE [name] = N'SFN\pifrobot-u-svc' and [type] IN ('C','E', 'G', 'K', 'S', 'U')) 
begin
	print '[+] Создание пользователя [SFN\pifrobot-u-svc] в базе [PythiaAgent]'
	--CREATE USER [SFN\pifrobot-u-svc] FOR LOGIN [SFN\pifrobot-u-svc]
end 
else
	print '[-] Пользователь [SFN\pifrobot-u-svc] уже существует в базе [PythiaAgent]'

*/