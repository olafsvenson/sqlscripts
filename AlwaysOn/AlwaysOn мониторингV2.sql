select  
	db_name(database_id) AS db,
	-- ������ ������� �� ��������
	log_send_queue_size/1024/1024 as [������ ������� �� �������� ==>],--log_send_queue_sizeGB
	-- �������� �������� 
	log_send_rate/1024 AS [�������� ��������MB/s ==>],--log_send_rateMB/s ==>
	-- ������ ���� �� �������
	redo_queue_size/1024 AS [==> ������ ���� �� �������MB], --  redo_queue_sizeMB
	last_received_time as [==> last_received_time],
	-- �������� ���������� �� �������
	redo_rate/1024 AS [==> �������� ������� MB/s],--redo_rateMB/s
	last_commit_time AS [==> last_commit_time],
	-- ��������� ����� ��� ������� ���������
	--(redo_queue_size / iif(redo_rate > 0, redo_rate, 1)) / 60 AS [== > est_redo_completion_time_min <==],
	RIGHT('0' + CAST((redo_queue_size / iif(redo_rate > 0, redo_rate, 1)) / 3600 AS VARCHAR),2) + ':' +
	RIGHT('0' + CAST((redo_queue_size / iif(redo_rate > 0, redo_rate, 1)) / 60 % 60 AS VARCHAR),2) + ':' +
	RIGHT('0' + CAST((redo_queue_size / iif(redo_rate > 0, redo_rate, 1)) % 60 AS VARCHAR),2) AS [== > ��������� ����� ������������� <==]-- est_redo_completion_time_with_current_speed
from sys.dm_hadr_database_replica_states
where 
	log_send_queue_size IS NOT NULL

/*

	select log_send_queue_size,  log_send_rate, redo_rate,* from sys.dm_hadr_database_replica_states where group_database_id = 'MYDB_GUID'
*/

--2020-02-03 20:26:41.150

-- 11:44 2020-02-03 20:35:15.980
-- 13:06 2020-02-03 20:41:49.627
-- 16:05 2020-02-04 03:52:19.507	66:45:09