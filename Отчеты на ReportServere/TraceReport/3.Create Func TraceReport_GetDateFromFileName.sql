  IF OBJECT_ID (N'dbo.TraceReport_GetDateFromFileName', N'FN') IS NOT NULL
    DROP FUNCTION dbo.TraceReport_GetDateFromFileName;
	GO

  CREATE FUNCTION dbo.TraceReport_GetDateFromFileName
  (
	@file_name varchar(1000)
   )
  RETURNS DATE
  begin
	IF (PATINDEX('dailyLong%', @file_name) > 0)
	BEGIN
		
		RETURN SUBSTRING(@file_name,LEN('dailyLong')+2,11)
	END
	
	RETURN NULL;  
  END

go
GRANT EXECUTE ON dbo.TraceReport_GetDateFromFileName TO TraceReportUser
go
