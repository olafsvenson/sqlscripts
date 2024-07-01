/*
	use pegasus2008su
	use kboi

select * from INFORMATION_SCHEMA.VIEW_TABLE_USAGE WHERE view_NAME = '����������.�����������������������' 
*/
GO

SELECT TOP 50
		-- �-�� ������� ��������� �������� �� �������� �� �������� ����� ������������ ������� (���� ��������� ��������� ���� �-��)
       [TotalCost] = ROUND(avg_total_user_cost * (avg_user_impact/100) * (s.user_seeks + s.user_scans),0), -- �-�� �� ��
       -- ������� ������� ��������, ������� ����� �������� ������� ������������, ���� ������� ��� ������ ������������� ��������. 
	   -- �������� ����������, ��� ��������� ������� � ������� ���������� �� ���� �������, ���� ������� ��� ������ ������������� ��������.
	   [avg_user_impact],
	   	   object_name(d.object_id) AS [Table],
	   -- v.VIEW_NAME as [1CObject],
	   	   -- ������ ������� ����� �� ����������, ��� �������
	   sp.[rows], 
	   -- ���������� �������� ������ � ��������� �� �������� ������������, ��� ������� ��� �� �������������� ��������������� ������ � ������.
	   s.user_seeks, s.user_scans, 
	   -- ���������� ������������� �������(����������� �������) reads & writes
	   ddius.user_lookups, ddius.user_updates,
	   -- ���-�� ��������� ��������, ������� ��� ���������� �� �������
	   [Count_Custom_Indexes] = (SELECT COUNT(*) FROM sys.indexes with (nolock) WHERE object_id = i.object_id AND name LIKE '%IX_custom_%'),
       [create_index_statement] = 'CREATE NONCLUSTERED INDEX IX_custom_'
                        + REPLACE(REPLACE(REPLACE(ISNULL(d.equality_columns,'')+ISNULL(d.inequality_columns,''), '[', ''), ']',''), ', ','_')
						+'_inc' +ISNULL ( replace(REPLACE(replace(replace( LEFT(d.included_columns, 50),'[','_'),']',''),',',''),' ',''),'')
                        + ' ON '
                        + [statement]
                        + ' ( ' + IsNull(d.equality_columns, '')
                        + CASE 
                                WHEN d.inequality_columns IS NULL THEN '' 
                                ELSE
                                        (CASE 
                                                WHEN d.equality_columns IS NULL THEN '' 
                                                ELSE ',' 
                                         END)
                                        + d.inequality_columns 
                                END 
                        + ' ) '
                        + CASE 
                                WHEN d.included_columns IS NULL THEN '' 
                                        ELSE 'INCLUDE (' + d.included_columns + ')' 
                                END
						  + ' with (SORT_IN_TEMPDB = ON, online = '+ CASE
							WHEN SERVERPROPERTY('EngineEdition') = 3 THEN 'ON'
							ELSE 'OFF'
							END +', data_compression = page, allow_page_locks = off, maxdop = 4);'
  FROM sys.dm_db_missing_index_groups g 
  INNER JOIN sys.dm_db_missing_index_group_stats s ON s.group_handle = g.index_group_handle 
  INNER JOIN sys.dm_db_missing_index_details d ON d.index_handle = g.index_handle
  -- �������� ���������� ������������� ������� reads & writes
  inner join sys.dm_db_index_usage_stats ddius ON ddius.object_id = d.object_id 
  INNER JOIN sys.indexes i ON ddius.object_id = i.object_id AND i.index_id = ddius.index_id
  -- �������� ����� 1� ��������
  -- LEFT JOIN INFORMATION_SCHEMA.VIEW_TABLE_USAGE as v ON OBJECT_NAME(d.object_id) = v.TABLE_NAME
  -- �������� ������ ������� �� ����������
  CROSS APPLY [sys].[dm_db_stats_properties]([d].[object_id],1) sp
  WHERE 
	  d.database_id = DB_ID()
	  -- ���� ��������� �������� ��� ������
	  -- �� ��������� ������ � missing
	--  and avg_user_impact > 50   -- ��������� �� �������� Total_Cost
	  -- and s.last_user_seek >= DATEDIFF(month, GetDate(), -1) -- ��������� Seek ��� �� ����� ������
	  -- ���������� ������������� ������� �� ����������� �������
	  and ddius.database_id = d.[database_id] 
	  --AND ddius.index_id = 1 -- clustered 	
	  -- �� ��������� ������ � ���������� ������������  �������
	 -- and  (s.user_seeks + s.user_scans + user_lookups) > user_updates -- ��, �� ������� ���� ����� ���c� ��� ����������
	  -- ��������� �������
	  --AND object_name(d.object_id) ='AF'
ORDER BY 
			[TotalCost] DESC;
			--user_seeks desc, rows DESC

	