--(@P1 varbinary(16))SELECT T1._Fld25775_TYPE, T1._Fld25775_S, T1._Fld25775_RTRef, T1._Fld25775_RRRef, T1._Fld25776, T1._Fld25777, T1._Fld25778, T1._Fld25779, T1._Fld25819 FROM dbo._InfoRg25774 T1 WHERE ((T1._Fld48912RRef = @P1)) AND (0x00) = 0x01
--(@P1 varbinary(16),@P2 nvarchar(4000),@P3 datetime2(3),@P4 datetime2(3),@P5 varbinary(16),@P6 nvarchar(4000),@P7 datetime2(3),@P8 datetime2(3),@P9 varbinary(16))SELECT TOP 1 T1.Q_001_F_001RRef, T4._Fld13982RRef, T4._Fld13983RRef, T4._Fld14004RRef, T4._Fld14005RRef, T4._Number, T4._Fld32039, T1.Q_001_F_000_, T1.Q_001_F_002_00_, T1.Q_001_F_002_01RRef FROM (SELECT 1.0 AS Q_001_F_000_, T2._IDRRef AS Q_001_F_001RRef, T2._Date_Time AS Q_001_F_002_00_, T2._IDRRef AS Q_001_F_002_01RRef FROM dbo._Document556 T2 WHERE ((T2._Fld48969RRef = @P1)) AND ((T2._Marked = 0x00) AND (T2._Number = @P2) AND ((T2._Date_Time >= @P3) AND (T2._Date_Time <= @P4))) UNION ALL SELECT 2.0, T3._IDRRef AS IDRRef, T3._Date_Time AS Date_Time_, T3._IDRRef AS IDRRef FROM dbo._Document556 T3 WHERE ((T3._Fld48969RRef = @P5)) AND ((T3._Marked = 0x00) AND (T3._Fld32039 = @P6) AND ((T3._Date_Time >= @P7) AND (T3._Date_Time <= @P8)))) T1 LEFT OUTER JOIN dbo._Document556 T4 ON (T1.Q_001_F_001RRef = T4._IDRRef) AND (T4._Fld48969RRef = @P9) ORDER BY (T1.Q_001_F_000_), (T1.Q_001_F_002_00_) DESC, (T1.Q_001_F_002_01RRef) DESC

IF OBJECT_ID (N'tempdb..#t', N'U') IS NOT NULL
	DROP TABLE #t;	

SELECT  e.session_id,text
INTO #t
from sys.dm_exec_requests e
inner join sys.dm_exec_sessions s ON e.session_id=s.session_id
	cross apply sys.dm_exec_sql_text(sql_handle) as qt
where e.session_id > 50 AND e.session_id <> @@spid
	and text LIKE '%_AccumRgT36637 T2%'

-- SELECT * FROM mastee..sysprocesses WHERE spid= 
--SELECT * FROM #t 


DECLARE @id int
DECLARE curProcesses CURSOR FAST_FORWARD FOR SELECT TOP 30 session_id  FROM #t
             
OPEN curProcesses

FETCH NEXT FROM curProcesses INTO @id
WHILE @@FETCH_STATUS = 0
BEGIN
  
	  DECLARE @q NVARCHAR(100)

	  SET @q='kill ' + CAST(@id AS NVARCHAR(10))
	  PRINT @q
	  EXEC(@q)

	  FETCH NEXT FROM curProcesses INTO @id
END  
CLOSE curProcesses
DEALLOCATE curProcesses

