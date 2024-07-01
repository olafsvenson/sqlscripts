USE [master]
GO
/****** Object:  UserDefinedFunction [dbo].[rgClassifier]    Script Date: 06/17/2013 18:20:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = null)
GO
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

/*
Функция используется регулировщиком ресурсов для определения группы, которой принадлежит сессия.
Возвращает имя группы.
Если группы с таким именем не существует, то будет использоваться группа "default" из пула "default"
*/
ALTER FUNCTION [dbo].[rgClassifier]()
RETURNS sysname WITH SCHEMABINDING
AS
BEGIN
	DECLARE @retval sysname;
	
	IF SUSER_NAME() = N'dbcc_user'
		SET @retval = N'DBCCGroup'
	ELSE IF SUSER_NAME() = N'AINotificationUser'
		SET @retval = N'wgAINotification'
	ELSE IF SUSER_NAME() = N'srv_DKE'
		SET @retval = N'wgAINotification'
	ELSE IF SUSER_NAME() = N'monitoring_reader' or SUSER_NAME() = N'db_reader' or SUSER_NAME() = N'payment_reader'
		SET @retval = N'AnalyticsGroup'
	ELSE
		SET @retval = N'default'
	
	RETURN @retval
END
go
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = dbo.rgClassifier)
GO
ALTER RESOURCE GOVERNOR RECONFIGURE
GO
