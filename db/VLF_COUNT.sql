--Находит все файлы логов баз с большим числом виртуальных журналов (>200)
Create Table #stage(
    FileID      int
  , FileSize    bigint
  , StartOffset bigint
  , FSeqNo      bigint
  , [Status]    bigint
  , Parity      bigint
  , CreateLSN   numeric(38)
);
 
Create Table #results(
    Database_Name   sysname
  , VLF_count       int 
);
 
 DECLARE @SqlStr NVARCHAR(MAX)
 SET @SqlStr =  N'Use [?]; 
            Insert Into #stage 
            Exec master..sp_executeSQL N''DBCC LogInfo([?])''; 
 
            Insert Into #results 
            Select DB_Name(), Count(*) 
            From #stage; 
 
            Truncate Table #stage;'
Exec sp_msforeachdb @command1 = @SqlStr
 
Select * 
From #results WHERE VLF_count > 200
Order By VLF_count Desc;
 
Drop Table #stage;
Drop Table #results;



--Находит файлы логов с параметром роста менее 1024 МБ или менее 10%

USE tempdb

CREATE TABLE #TMP(
	DB NVARCHAR(50),
	Fileid INT,
	FileType NVARCHAR(50),
	NAME NVARCHAR(50),
	Phys_name NVARCHAR(255),
	SIZE INT,
	MAX_size INT,
	Growth_mb INT,
	Percent_Growth INT)
	
	INSERT INTO #TMP
	(
		DB,
		Fileid,
		FileType,
		NAME,
		Phys_name,
		[SIZE],
		MAX_size,
		Growth_mb,
		Percent_Growth
	)
	EXEC sp_msforeachdb @command1 = '

DECLARE @DBNAME NVARCHAR(50)
if "[?]" <> "tempdb" and "[?]" <> "master"
BEGIN
USE [?]
SET @DBNAME = "[?]"

SELECT 
@DBNAME As DB,
file_id,
Type_desc,
name,
Physical_name,
size,
max_size,
growth/128 as growth_mb,
is_percent_growth
 FROM sys.database_files df WHERE type =1
 AND ( (growth < 131072 and is_percent_growth = 0)
 OR (growth < 10 and is_percent_growth = 1))
END

'
SELECT * FROM #TMP

DROP TABLE #TMP

