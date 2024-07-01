 -- диагностика
 -- PAGEIOLATCH_*
 exec master..sp_BlitzCache @DatabaseName ='Pegasus2008', @SortOrder = 'cpu',@top = 50
 ,@ExportToExcel = 1
 ,@MinimumExecutionCount = 100

 -- WRITELOG
 sp_BlitzFirst @Seconds = 0, @ExpertMode = 1

 EXEC sp_BlitzQueryStore @DatabaseName = 'Pegasus2008', @Top = 10,@StartDate = '20210609'

 sp_BlitzWho
