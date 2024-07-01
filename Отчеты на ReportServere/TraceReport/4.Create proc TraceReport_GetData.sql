
IF OBJECT_ID ( 'dbo.TraceReport_GetData', 'P' ) IS NOT NULL 
    DROP PROCEDURE dbo.TraceReport_GetData;
GO

CREATE PROC TraceReport_GetData (
 @db_name VARCHAR(1000),
 @date_begin DATETIME, 
 @date_end DATETIME, 
 @value_type INT
 )
 as
 begin

 /*
	value_type

	0 - sumCPU
	1 - avgCPU
	2 - sumDurationSec
	3 - avgDurationMs
	4 - avgReads
	5 - avgWrites
	6 - Count

	SET @value_type = 3
	SET @db_name = 'buh2_0'
	SET @date_begin = '2014-28-07'
	SET @date_end = '2014-05-08'

*/

/*
DECLARE @query nvarchar(1000) = 'SELECT
	   [DatabaseName], 
	   [DateOfAdded],'
	   + CASE
			WHEN @value_type = 0 THEN '[sumCpu]'
			WHEN @value_type = 1 THEN '[avgCpu]'
			WHEN @value_type = 2 THEN '[sumDurationSec]'
			WHEN @value_type = 3 THEN '[avgDurationMs]'
			WHEN @value_type = 4 THEN '[avgReads]'
			WHEN @value_type = 5 THEN '[avgWrites]'
			WHEN @value_type = 6 THEN '[Count]'
		END
	+'as Value      
  FROM [dbo].[TraceReport_WorkloadByDatabases]
  WHERE DatabaseName in (@db_name)
	and DateOfAdded between @date_begin and @date_end
  GROUP BY DatabaseName,Dateofadded,' + CASE
											WHEN @value_type = 0 THEN '[sumCpu]'
											WHEN @value_type = 1 THEN '[avgCpu]'
											WHEN @value_type = 2 THEN '[sumDurationSec]'
											WHEN @value_type = 3 THEN '[avgDurationMs]'
											WHEN @value_type = 4 THEN '[avgReads]'
											WHEN @value_type = 5 THEN '[avgWrites]'
											WHEN @value_type = 6 THEN '[Count]'
										END
  +'ORDER BY DatabaseName,dateofadded'
  
  EXEC sp_executesql @query, N'@db_name nvarchar(500), @date_begin datetime, @date_end datetime', @db_name = @db_name, @date_begin = @date_begin, @date_end = @date_end
  */

SELECT
	   [DatabaseName], 
	   [DateOfAdded],
	   + CASE
			WHEN @value_type = 0 THEN [sumCpu] 
			WHEN @value_type = 1 THEN [avgCpu]
			WHEN @value_type = 2 THEN [sumDurationSec]
			WHEN @value_type = 3 THEN [avgDurationMs]
			WHEN @value_type = 4 THEN [avgReads]
			WHEN @value_type = 5 THEN [avgWrites]
			WHEN @value_type = 6 THEN [Count]
		END as Value
	
  FROM [dbo].[TraceReport_WorkloadByDatabases]
  WHERE DatabaseName in (@db_name)
	and DateOfAdded between @date_begin and @date_end
  GROUP BY DatabaseName,Dateofadded, CASE
											WHEN @value_type = 0 THEN [sumCpu]
											WHEN @value_type = 1 THEN [avgCpu]
											WHEN @value_type = 2 THEN [sumDurationSec]
											WHEN @value_type = 3 THEN [avgDurationMs]
											WHEN @value_type = 4 THEN [avgReads]
											WHEN @value_type = 5 THEN [avgWrites]
											WHEN @value_type = 6 THEN [Count]
										END
  ORDER BY DatabaseName,dateofadded


END
go

GRANT EXECUTE ON dbo.TraceReport_GetData TO TraceReportUser
go