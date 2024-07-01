     /*

		http://sqlcom.ru/dba-tools/what-processor-in-work/

		�����: ��������� ���������
	 */
	 SELECT DB_NAME(ISNULL(s.dbid,1)) AS [��� ���� ������]
          , c.session_id              AS [ID ������]
          , t.scheduler_id            AS [����� ����������]
          , s.text                    AS [����� SQL-�������]
       FROM sys.dm_exec_connections   AS c
CROSS APPLY master.sys.dm_exec_sql_text(c.most_recent_sql_handle) AS s
       JOIN sys.dm_os_tasks t
         ON t.session_id = c.session_id
        AND t.task_state = 'RUNNING'
        AND ISNULL(s.dbid,1) > 4
   ORDER BY c.session_id DESC