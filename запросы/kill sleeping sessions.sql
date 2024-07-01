
	declare @SPID_KILL varchar(6);
	declare C_Tran cursor for
		--Поиск и сброс бездействующих сеансов с открытыми транзакциями!
		SELECT s.session_id
		FROM sys.dm_exec_sessions AS s
		WHERE EXISTS 
			(
			SELECT * 
			FROM sys.dm_tran_session_transactions AS t
			WHERE t.session_id = s.session_id
			)
			AND NOT EXISTS 
			(
			SELECT * 
			FROM sys.dm_exec_requests AS r
			WHERE r.session_id = s.session_id
			)
			--AND DATEDIFF(MINUTE,s.last_request_end_time,GETDATE())>=5;
	open C_Tran;
	fetch next from C_Tran into @SPID_KILL;
	while @@FETCH_STATUS=0
	begin
		--Удаляем все отобранные сессии здесь!
		PRINT('KILL '+@SPID_KILL+';');
		EXEC('KILL '+@SPID_KILL+';');
		fetch next from C_Tran into @SPID_KILL;
	END
	close C_Tran;
	deallocate C_Tran;
	