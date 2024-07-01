-- 1 window 
BEGIN TRANSACTION
  SELECT top 1 * FROM Monitoring_dbsize WITH (TABLOCKX, HOLDLOCK)
    WAITFOR DELAY '00:15:00' -- 5 minutes
ROLLBACK TRANSACTION




-- 2 windows

SELECT * FROM Monitoring_dbsize