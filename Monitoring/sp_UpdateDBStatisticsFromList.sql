USE [master]
GO

/****** Object:  StoredProcedure [dbo].[sp_UpdateDBStatisticsFromList]    Script Date: 23.09.2015 10:00:42 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_UpdateDBStatisticsFromList]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_UpdateDBStatisticsFromList]
GO

/****** Object:  StoredProcedure [dbo].[sp_UpdateDBStatisticsFromList]    Script Date: 23.09.2015 10:00:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_UpdateDBStatisticsFromList]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

CREATE PROCEDURE [dbo].[sp_UpdateDBStatisticsFromList] 
AS
BEGIN


set nocount on
declare @i int=0, @db_name sysname, @compability_level INT, @query NVARCHAR(max)


DECLARE curCursor CURSOR FAST_FORWARD read_only FOR 
		SELECT name, compatibility_level FROM sys.databases s
			INNER JOIN monitoring.dbo.OptimizeDBIndexesList l ON l.DB_NAME = s.name
		ORDER BY l.id
												
               
OPEN curCursor

FETCH NEXT FROM curCursor INTO @db_name, @compability_level

WHILE @@FETCH_STATUS = 0
	begin

		SET @query = ''
			print ''''*** Processing DB [#] ***''''

			USE [#]
			exec sp_MSForEachTable ''''UPDATE STATISTICS ? WITH FULLSCAN, INDEX''''
		''

		SET @query = REPLACE(@query, ''#'', @db_name)

		EXEC(@query)

		PRINT N''Executed: '' + @query;

	FETCH NEXT FROM curCursor INTO @db_name, @compability_level	
	END

CLOSE curCursor
DEALLOCATE curCursor	

end' 
END
GO


