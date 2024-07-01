IF OBJECT_ID('tempdb.dbo.#dbsize') IS NOT NULL
    DROP TABLE #dbsize


CREATE TABLE [#dbsize](
	[TYPE] [nvarchar](60) NULL,
	[FILE_Name] [sysname] NOT NULL,
	[FILEGROUP_NAME] [sysname] NULL,
	[File_Location] [nvarchar](260) NULL,
	[FILESIZE_MB] [decimal](10, 2) NULL,
	[USEDSPACE_MB] [decimal](10, 2) NULL,
	[FREESPACE_MB] [decimal](10, 2) NULL,
	[FREESPACE_%] [decimal](10, 2) NULL,
	[AutoGrow] [varchar](84) NULL
)


DECLARE @SQL NVARCHAR(MAX)

SELECT @SQL = STUFF((
    SELECT '
	USE [' + d.name + ']
INSERT INTO [#dbsize] ([TYPE],[FILE_Name],[FILEGROUP_NAME],[File_Location],[FILESIZE_MB],[USEDSPACE_MB],[FREESPACE_MB]
           ,[FREESPACE_%]
           ,[AutoGrow])
SELECT 
    [TYPE] = A.TYPE_DESC
    ,[FILE_Name] = A.name
    ,[FILEGROUP_NAME] = fg.name
    ,[File_Location] = A.PHYSICAL_NAME
    ,[FILESIZE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0)
    ,[USEDSPACE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0 - ((SIZE/128.0) - CAST(FILEPROPERTY(A.NAME, ''SPACEUSED'') AS bigINT)/128.0))
    ,[FREESPACE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, ''SPACEUSED'') AS bigINT)/128.0)
    ,[FREESPACE_%] = CONVERT(DECIMAL(10,2),((A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, ''SPACEUSED'') AS bigINT)/128.0)/(A.SIZE/128.0))*100)
    ,[AutoGrow] = ''By '' + CASE is_percent_growth WHEN 0 THEN CAST(growth/128 AS VARCHAR(10)) + '' MB -'' 
        WHEN 1 THEN CAST(growth AS VARCHAR(10)) + ''% -'' ELSE '''' END 
        + CASE max_size WHEN 0 THEN ''DISABLED'' WHEN -1 THEN '' Unrestricted'' 
            ELSE '' Restricted to '' + CAST(max_size/(128*1024) AS VARCHAR(10)) + '' GB'' END 
        + CASE is_percent_growth WHEN 1 THEN '' [autogrowth by percent, BAD setting!]'' ELSE '''' END
FROM sys.database_files A 
	LEFT JOIN sys.filegroups fg ON A.data_space_id = fg.data_space_id 
order by A.TYPE desc, A.NAME, [FREESPACE_MB] desc; 
'
 FROM sys.databases d
    WHERE d.[state] = 0
	and [name] not like '%(%)%'
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '')

EXEC sys.sp_executesql @SQL



--INSERT INTO [dbo].[dbsize]
--           ([dt]
--           ,[TYPE]
--           ,[FILE_Name]
--           ,[File_Location]
--           ,[FILESIZE_MB]
--           ,[USEDSPACE_MB]
--           ,[FREESPACE_MB]
--           ,[FREESPACE_%]
--           ,[AutoGrow])
select 
	 getdate() as 'dt'
	,[TYPE] 
    ,[FILE_Name]
    --,[FILEGROUP_NAME]
    ,[File_Location]
    ,[FILESIZE_MB]
    ,[USEDSPACE_MB]
    ,[FREESPACE_MB]
    ,[FREESPACE_%]
    ,[AutoGrow]
--into dbsize
from #dbsize
--WHERE
	--TYPE ='LOG'
--	#dbsize.File_Location LIKE 'e:\%'
order by 
FILESIZE_MB DESC
--[FREESPACE_MB] desc
--ORDER BY file_name