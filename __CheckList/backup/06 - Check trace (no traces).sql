IF NOT EXISTS (
	SELECT * FROM ::fn_trace_getinfo(default) 
	where Property=2 	-- �������� ��� �������� ���� � ������
		and Value is not null						-- �� ������ ������
		and Cast(Value as varchar(4000)) not like '%\MSSQL\Log\log_%'	-- �� ��� �� ���������
)
SELECT @@servername

/* -- ��������� ����� ������ ��������
	SELECT * FROM ::fn_trace_getinfo(default) 
	where Property=2 	-- �������� ��� �������� ���� � ������
		and Value is not null						-- �� ������ ������
		and Cast(Value as varchar(4000)) not like '%\MSSQL\Log\log_%'	-- �� ��� �� ���������
*/
   
   
