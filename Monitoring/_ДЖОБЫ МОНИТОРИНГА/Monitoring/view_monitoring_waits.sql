use master
go

SELECT 
	   dense_rank() over (order by dt desc) as [n]
	  ,cast([dt] as date) as [dt]
      ,[WaitType]
      ,[Wait_S]
      ,[WaitCount]
      ,[Percentage]
FROM [master].[dbo].[Monitoring_waits]
order by 
		[n] asc
	   ,[Percentage] desc

  --where dt between '2022-12-15' and '2022-12-16'
--  group by cast([dt] as date) 
  
  
  
  
	--cast([dt] as date) desc