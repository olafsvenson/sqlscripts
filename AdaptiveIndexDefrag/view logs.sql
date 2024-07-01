USE msdb 
go
exec msdb..usp_AdaptiveIndexDefrag_CurrentExecStats @dbname = 'Pegasus2008'



SELECT * 
FROM [dbo].[tbl_AdaptiveIndexDefrag_Analysis_log] with (nolock) 
--WHERE objectname='_Reference227'

SELECT DISTINCT [operation] FROM [dbo].[tbl_AdaptiveIndexDefrag_Analysis_log] with (nolock) 
SELECT * FROM  with (nolock) 

SELECT *FROM msdb.[dbo].[tbl_AdaptiveIndexDefrag_Working] 
--WHERE 
	--objectname='[_AccumRg53563]'
	--FRAGMENTATION > 70 AND defragdate IS NOT null

ORDER BY 
		--scanDate DESC
		defragDate desc

SELECT TOP 50 * FROM [dbo].[tbl_AdaptiveIndexDefrag_log] with (nolock) 
--WHERE objectname='[_AccumRg53563]'
--WHERE datetimestart IS null
ORDER BY 
	indexdefrag_id DESC

SELECT * FROM [dbo].[tbl_AdaptiveIndexDefrag_Stats_log]  with (nolock) 
SELECT * FROM [dbo].[tbl_AdaptiveIndexDefrag_Stats_Working] with (nolock) 

 
 select DATEPART(weekday, GETDATE())