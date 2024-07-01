DECLARE @CPU_BUSY int, @IDLE int
SELECT @CPU_BUSY = @@CPU_BUSY, @IDLE = @@IDLE WAITFOR DELAY '000:00:01'
SELECT cast((@@CPU_BUSY - @CPU_BUSY)/((@@IDLE - @IDLE + @@CPU_BUSY - @CPU_BUSY) * 1.00) * 100 as int) AS 'CPU Utilization by sqlsrvr.exe'
