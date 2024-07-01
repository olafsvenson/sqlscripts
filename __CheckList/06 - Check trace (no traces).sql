IF @@SERVERNAME IN (
	'RU02',
	'RU02\RU02',
	'SRV04',
	'SRV06',
	'INFRAPBX',
	'devdb',
	'devdb\rsnew',
	'AMOSTAT\SQLSTAT2',
	'OBSTAT\SQLSTAT3'
	
) OR
EXISTS (
	SELECT * FROM ::fn_trace_getinfo(default) 
	where Property=2 	-- �������� ��� �������� ���� � ������
		and Value is not null						-- �� ������ ������
		and Cast(Value as varchar(4000)) not like '%\MSSQL\Log\log_%'	-- �� ��� �� ���������
)
BEGIN
	SELECT TOP 0 ''
END ELSE BEGIN
	SELECT @@servername
END

/* -- ��������� ����� ������ ��������
	SELECT * FROM ::fn_trace_getinfo(default) 
	where Property=2 	-- �������� ��� �������� ���� � ������
		and Value is not null						-- �� ������ ������
		and Cast(Value as varchar(4000)) not like '%\MSSQL\Log\log_%'	-- �� ��� �� ���������
*/
   
   
