/* поле runstatus
The running status:

1 = Start.
2 = Succeed.
3 = In progress.
4 = Idle.
5 = Retry.
6 = Fail.
*/ 

IF db_id('distribution') IS NOT NULL
BEGIN
SELECT @@servicename AS 'ServerName'
      ,a.[name]
      ,a.[publisher_db]
      ,[status] =CASE
       WHEN h.[runstatus]=1 THEN 'Start'
       WHEN h.[runstatus]=2 THEN 'Succeed'
       WHEN h.[runstatus]=3 THEN 'In progress'
       WHEN h.[runstatus]=4 THEN 'Idle'
       WHEN h.[runstatus]=5 THEN 'Retry'
       WHEN h.[runstatus]=6 THEN 'Fail'
       END
      ,h.[time]
      ,e.[error_text]
      --,DATEDIFF(hh,GETDATE(),h.time)
      ,error_id
FROM [distribution].[dbo].[MSlogreader_agents] a with (nolock) 
INNER JOIN [distribution].[dbo].[MSlogreader_history] h  with (nolock) 
ON a.id=h.agent_id
LEFT JOIN [distribution].[dbo].[MSrepl_errors] e  with (nolock) 
ON h.error_id=e.id

WHERE 
h.runstatus=5
--AND DATEDIFF(hh,h.time,getdate()) <= 1 

END


