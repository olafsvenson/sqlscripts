USE kboi
go
SELECT TOP 20
    qsq.query_id,
    qsq.last_execution_time,
    qsqt.query_sql_text
FROM sys.query_store_query qsq
    INNER JOIN sys.query_store_query_text qsqt
        ON qsq.query_text_id = qsqt.query_text_id
WHERE
    qsqt.query_sql_text LIKE '%GetCargoInfoLight%'
	AND qsq.last_execution_time > dateadd(hh,-6,getdate())
ORDER BY 
		last_execution_time desc

	
	
	