/*	поиск плана
*/


SELECT TOP 50 databases.name, 
               dm_exec_sql_text.text AS TSQL_Text, 
               dm_exec_query_stats.creation_time,
			   last_execution_time,
               dm_exec_query_stats.execution_count, 
               --dm_exec_query_stats.total_worker_time AS total_cpu_time, 
               --dm_exec_query_stats.total_elapsed_time, 
			   min_elapsed_time/1000 AS [min_elapsed_time],
			   max_elapsed_time/1000 AS [max_elapsed_time],
			   last_elapsed_time/1000 as [last_elapsed_time],
               dm_exec_query_stats.total_logical_reads, 
               dm_exec_query_stats.total_physical_reads,
			   dm_exec_query_plan.query_plan,
			   dm_exec_query_stats.plan_handle,
			   dm_exec_query_stats.statement_start_offset
FROM sys.dm_exec_query_stats
     CROSS APPLY sys.dm_exec_sql_text(dm_exec_query_stats.plan_handle)
     CROSS APPLY sys.dm_exec_query_plan(dm_exec_query_stats.plan_handle)
     INNER JOIN sys.databases ON dm_exec_sql_text.dbid = databases.database_id
WHERE 
	--dm_exec_sql_text.text LIKE N'%Reference90%Reference89%Reference91%'
	--dm_exec_sql_text.text LIKE N'%Document557_VT14033%Document557%Document38836%Document565_VT14207%'
--	dm_exec_sql_text.text LIKE N'%top 31%DocumentJournal15386%Reference252%Reference252%Reference255%'
	--dm_exec_sql_text.text LIKE N'%InfoRg45953%Reference40260_VT4028%Reference37881%'
-- dm_exec_sql_text.text LIKE N'%AccumRgT36637%Fld48969RRef%Period%Fld36632RRef%'
--dm_exec_sql_text.text LIKE N'%AccumRgT36637%InfoRg51906%InfoRg51906%Document556%Reference255%'
--web Питер
--dm_exec_sql_text.text LIKE N'%AccumRgT36657%InfoRg52034%InfoRg52034%Document556%Reference255%'

-- dm_exec_sql_text.text LIKE N'%Document35855%Document35855_VT35890%Document557%Document559%InfoRg44092%Document566%Document556%'
-- dm_exec_sql_text.text LIKE N'%Document35855_VT35890%Document559%InfoRg44092%'
-- dm_exec_sql_text.text LIKE N'%AccumRgT36637%InfoRg51906%InfoRg51906%Document556%Reference255'
-- dm_exec_sql_text.text LIKE N'%000RRef%InfoRg41329%InfoRg41329%'
-- dm_exec_sql_text.text LIKE N'%Document22411%Reference30779%Reference30779%Document22411%Reference30779%Reference30779%Document557%'
-- оплата
-- dm_exec_sql_text.text LIKE N'%Document569_VT14296%Document569%Document573%Document570%Reference255%Reference255%Document569_VT26264%'
-- dm_exec_sql_text.text LIKE N'%Reference43344%Reference91%'
-- выдача партий
-- dm_exec_sql_text.text LIKE N'%Fld41297RRef%Fld41298RRef%InfoRg41296%'
-- утилизация ТС
-- dm_exec_sql_text.text LIKE N'%tt%AccumRg36627%Document556%' 
-- подбор груза создание партий и сверок
-- dm_exec_sql_text.text LIKE N'%Document557_VT38576%Document557%Document569%Reference255%' 
-- dm_exec_sql_text.text LIKE N'%Document556%Reference252%Document556%Reference252%Document556%Reference252%Reference252%Document592%' 
dm_exec_sql_text.text LIKE N'%pfndGetInvestorData%' --Marked = 0x00
--N'%pROStatusSave%'
		--AND dm_exec_query_plan.query_plan IS NOT NULL
	-- dm_exec_query_stats.plan_handle=0x06000600C819201D00991878F6000000010000006E0000000000000000000000000000000000000000000000
ORDER BY 
		--total_elapsed_time DESC
		last_execution_time DESC
option(recompile)


/*
0x060007001A9F9539003CC12F4900000001000000250300000000000000000000000000000000000000000000
dbcc freeproccache(	0x06000700F50C5338404044FA6F010000010000009F0200000000000000000000000000000000000000000000	)
dbcc freeproccache(0x0600070027B4AE0A204EFD004400000001000000840300000000000000000000000000000000000000000000	)
dbcc freeproccache(	0x06000700A00E230910F5B0DB8D00000001000000CB0200000000000000000000000000000000000000000000	)
dbcc freeproccache(	0x06000600E81EE609405E92CAE000000001000000A90000000000000000000000000000000000000000000000	)

DBCC FREEPROCCACHE (0x060006006FE16E32B07D6168F2000000010000006E0000000000000000000000000000000000000000000000)

use kboi
exec sp_create_plan_guide_from_handle N'GetCargoInfoLight1'  
    ,0x05000600FD9466606036A15F7D00000001000000000000000000000000000000000000000000000000000000
    , NULL;
	use pegasus2008
exec sp_create_plan_guide_from_handle N'vidacha_partii2'  
    ,0x0600060019880A06E0A823F6E5000000010000005E0000000000000000000000000000000000000000000000
    , NULL;
	exec sp_create_plan_guide_from_handle N'vidacha_partii3'  
    ,0x0600060019880A06E0A823F6E5000000010000005E0000000000000000000000000000000000000000000000
    , NULL;
	exec sp_create_plan_guide_from_handle N'vidacha_partii4'  
    ,0x0600060095FFA01960FF56F3EC000000010000005E0000000000000000000000000000000000000000000000
    , NULL;
	

	  declare @p0 nvarchar(4000),@p1 nvarchar(4000),@p2 nvarchar(4000),@p3 nvarchar(4000),@p4 nvarchar(4000),@p5 nvarchar(4000),@p6 int,@p7 int,@p8 nvarchar(4000),@p9 nvarchar(4000),@TotalCount int    --select @p1=NULL,@p2=NULL,@p3=N'9956036018',@p4=NULL,@p5=N'20',@p6=0,@p7=0,@p8=N'ee426cde-ecb1-44c0-900d-befb153f7652',@p9=N'd7202309cd9666757938acbdc8a302f5a0c67a5ce54e58f3b32f5e0167b6fad3'    exec [dbo].[pBoClientSearch]   @FullName=@p1                                                                                 , @Email=null                                                                                 , @AccountNumber='9956036018'                                                                                 , @Login=null                                                                                 , @Secret=N'20'                                                                                 , @OffSet=0                                                                                 , @Limit=0                                                                                 , @BoLogin=N'ee426cde-ecb1-44c0-900d-befb153f7652'                                                                                 , @BoSession=N'd7202309cd9666757938acbdc8a302f5a0c67a5ce54e58f3b32f5e0167b6fad3'                                                                                 , @TotalCount=@TotalCount out                     --   with recompile                                                                                   select @TotalCount    --declare @p13 int  --set @p13=NULL  --exec sp_executesql N'@p0 @FullName=@p1  --                                                                               , @Email=@p2  --                                                                               , @AccountNumber=@p3  --                                                                               , @Login=@p4  --                                                                               , @Secret=@p5  --                                                                               , @OffSet=@p6  --                                                                               , @Limit=@p7  --                                                                               , @BoLogin=@p8  --                                                                               , @BoSession=@p9  --                                                                               , @TotalCount=@TotalCount OUT  --',N'@p0 nvarchar(4000),@p1 nvarchar(4000),@p2 nvarchar(4000),@p3 nvarchar(4000),@p4 nvarchar(4000),@p5 nvarchar(4000),@p6 int,@p7 int,@p8 nvarchar(4000),@p9 nvarchar(4000),@TotalCount int output',@p0=N'[dbo].[pBoClientSearch]',@p1=NULL,@p2=NULL,@p3=N'9956036018',@p4=NULL,@p5=N'20',@p6=0,@p7=0,@p8=N'ee426cde-ecb1-44c0-900d-befb153f7652',@p9=N'd7202309cd9666757938acbdc8a302f5a0c67a5ce54e58f3b32f5e0167b6fad3',@TotalCount=@p13 output  --select @p13
	EXEC sp_control_plan_guide @operation = 'DROP', @name = N'Reference90'
GO

*/


