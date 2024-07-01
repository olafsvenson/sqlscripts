--Check Lock Pages in Memory
SELECT a.memory_node_id, node_state_desc, a.locked_page_allocations_kb
FROM sys.dm_os_memory_nodes a
INNER JOIN sys.dm_os_nodes b ON a.memory_node_id = b.memory_node_id


-- ���� CONVENTIONAL, �� ���������
SELECT sql_memory_model, sql_memory_model_desc
FROM sys.dm_os_sys_info
