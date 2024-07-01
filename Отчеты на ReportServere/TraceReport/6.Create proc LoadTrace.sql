

IF OBJECT_ID ( 'dbo.TraceReport_LoadTraces', 'P' ) IS NOT NULL 
    DROP PROCEDURE dbo.TraceReport_LoadTraces;
GO

CREATE PROC dbo.TraceReport_LoadTraces
as
begin
DECLARE @SrcPath varchar(1000)='D:\SQL_Traces\MSSQLSERVER\'

/*
	ѕолучаем список трейсов в директории
*/

IF OBJECT_ID('tempdb..#DirectoryTree')IS NOT NULL
      DROP TABLE #DirectoryTree;

CREATE TABLE #DirectoryTree (
       id int IDENTITY(1,1)
     -- ,fullpath varchar(2000)
      ,trace_file nvarchar(512)
      ,depth int
      ,isfile bit);


INSERT #DirectoryTree(trace_file,depth,isfile)
	EXEC master.sys.xp_dirtree @SrcPath,1,1;



set nocount on
declare @i int=0, @trace_file nvarchar(512)

-- загружаем в таблицу файлы, которые ранее не загружались
DECLARE curCursor CURSOR FAST_FORWARD read_only FOR 
SELECT d.trace_file
FROM  #DirectoryTree d 
left JOIN TraceReport_LoadedTraces l
ON d.trace_file = l.File_name
WHERE 
	l.File_name IS null -- не загруженные трейсы
	AND d.trace_file LIKE 'dailyLong%'
	AND d.trace_file NOT LIKE '%[_]%'
	AND d.trace_file NOT LIKE 'dailyLong '+CAST (YEAR(GETDATE()) AS NVARCHAR(4))+'-'+	
								CASE 
									WHEN LEN(CAST (Month(GETDATE()) AS VARCHAR(10))) = 1 THEN '0' + CAST (Month(getdate()) AS VARCHAR(10)) -- если одна цифра, то добавл€ем в начало 0
									ELSE CAST (Month(getdate()) AS VARCHAR(10))
								END + '_' +
								CASE 
									WHEN LEN(CAST (DAY(getdate()) AS VARCHAR(10))) = 1 THEN '0' + CAST (DAY(getdate()) AS VARCHAR(10)) 
									ELSE  CAST (DAY(getdate()) AS VARCHAR(10)) 
							END
							+'%'                          
 	
               
OPEN curCursor

FETCH NEXT FROM curCursor INTO @trace_file

WHILE @@FETCH_STATUS = 0
	begin
	
	IF OBJECT_ID('tempdb..#tmp_trace')IS NOT NULL
      DROP TABLE #tmp_trace;


BEGIN tran

	BEGIN TRY

	PRINT @trace_file
	      
	-- загружаю трейсы
	SELECT * 
	INTO #tmp_trace
	FROM fn_trace_gettable(@SrcPath + @trace_file, default);

	
	
	 -- «агружаю статистику по базе в итоговую таблицу
	 INSERT INTO [dbo].[TraceReport_WorkloadByDatabases]([DateOfAdded],[DatabaseName],[sumCPU],[avgCPU],[sumDurationSec],[avgDurationMs],[avgReads],[avgWrites],[Count])
	 select dbo.TraceReport_GetDateFromFileName(@trace_file),
			DatabaseName, 
			sumCPU = sum(CPU)/1000, 
			avgCPU = avg(CPU), 
			sumDurationSec=sum(Duration)/1000000, 
			avgDurationMs = avg(Duration)/1000, 
			avgReads = avg(Reads), 
			avgWrites = avg(Writes), 
			[Count] = count(*)
		from #tmp_trace
			WHERE DatabaseName IS NOT null
  	 group by DatabaseName
	

	-- заношу им€ файла в таблицу загруженных трейсов
	INSERT INTO [dbo].[TraceReport_LoadedTraces]([File_Name])
		 VALUES  (@trace_file)
	
	  
	COMMIT
	END TRY

		BEGIN CATCH
			DECLARE @error_message	nvarchar(2048) = ERROR_MESSAGE()

			IF XACT_STATE() != 0
				ROLLBACK TRANSACTION
			
			--вернуть ошибку в приложение
			RAISERROR(@error_message, 16, 1)

		END CATCH
				
	FETCH NEXT FROM curCursor INTO @trace_file	
	END

CLOSE curCursor
DEALLOCATE curCursor	
end








