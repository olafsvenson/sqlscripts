/*
http://www.sqlskills.com/blogs/paul/survey-how-is-your-tempdb-configured/
*/

SELECT os.Cores, df.Files
FROM
   (SELECT COUNT(*) AS Cores FROM sys.dm_os_schedulers WHERE status = 'VISIBLE ONLINE') AS os,
   (SELECT COUNT(*) AS Files FROM tempdb.sys.database_files WHERE type_desc = 'ROWS') AS df;
GO