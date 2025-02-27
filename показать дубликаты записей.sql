

WITH CTE(name,N) 
AS
(
	SELECT name,ROW_NUMBER()OVER(PARTITION BY name ORDER BY name DESC) FROM [svadba_catalog].[dbo].[JOB_ClientsToBeDeleted_Names]
)

select * from cte where n > 1


Select Counts,COUNT(*) from
  (
  select girlID,COUNT(*) as 'Counts' FROM svadba_catalog.dbo.tblGirlsPhoneComments where ConvenientCallTimeFrom > 0 group by GirlID --order by COUNT(*) desc
  ) as A
  group by Counts
  