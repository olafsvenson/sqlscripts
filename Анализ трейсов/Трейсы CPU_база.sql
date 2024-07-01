IF
	(SELECT COUNT (DISTINCT traceID) FROM ::fn_trace_getinfo(default)) > 20  -- ���� ������� ������ 20, ������ ������ � ��� ����������� �� �����
	
BEGIN
			
	RAISERROR ('Warning: Trace count >20', 16, 1)
				
		DECLARE @subj NVARCHAR(100) ='Too many traces on '+ @@servicename
		DECLARE @bodytext NVARCHAR(100) ='Warning: Trace count > 20'
		exec msdb.dbo.sp_send_dbmail
		@profile_name	= N'sql_mail',
		@recipients		= N'vzheltonogov@urbgroup.ru',
		@subject		= @subj,
		@body = @bodytext,
		@body_format	= 'TEXT',
		@importance		= 'High'
		RETURN
END
-- 
declare @rc int
declare @TraceID int

--������������ ������ ���������� ����� 1 ��
declare @maxfilesize bigint = 1024
declare @now datetime = getdate()

--����� ��������� ���������� �� 23:59:30, ����� �� �������� ������ ����� ��������� ����� ������ � ������� ����������
DECLARE @time TIME ='23:59:30'
declare @stopTime datetime = DateAdd(day,0,DateDiff(day,0,GETDATE())) + @time

--���� � ����� ������
declare @folder nvarchar(200) = N'F:\SQL_Traces\' + @@servicename + N'\'

--���� � ����� ������
declare @fileName nvarchar(245) = @folder + N'dailyCPU ' + replace(convert(nvarchar(20), @now, 120), ':', '')
select @fileName

IF 
NOT EXISTS (SELECT * FROM ::fn_trace_getinfo(default) WHERE cast (VALUE AS VARCHAR(MAX)) LIKE '%dailyCPU%') --���� ���� ������ � ����� �����, ���������
BEGIN

--�������� ����� � ������ rollover
exec @rc = sp_trace_create @TraceID output, 2, @fileName, @maxfilesize, @stopTime
if (@rc != 0)
	return

-- �������
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 10, 15, @on
exec sp_trace_setevent @TraceID, 10, 8, @on
exec sp_trace_setevent @TraceID, 10, 16, @on
exec sp_trace_setevent @TraceID, 10, 1, @on
exec sp_trace_setevent @TraceID, 10, 9, @on
exec sp_trace_setevent @TraceID, 10, 17, @on
exec sp_trace_setevent @TraceID, 10, 25, @on
exec sp_trace_setevent @TraceID, 10, 2, @on
exec sp_trace_setevent @TraceID, 10, 10, @on
exec sp_trace_setevent @TraceID, 10, 18, @on
exec sp_trace_setevent @TraceID, 10, 34, @on
exec sp_trace_setevent @TraceID, 10, 11, @on
exec sp_trace_setevent @TraceID, 10, 35, @on
exec sp_trace_setevent @TraceID, 10, 12, @on
exec sp_trace_setevent @TraceID, 10, 13, @on
exec sp_trace_setevent @TraceID, 10, 6, @on
exec sp_trace_setevent @TraceID, 10, 14, @on
exec sp_trace_setevent @TraceID, 12, 15, @on
exec sp_trace_setevent @TraceID, 12, 8, @on
exec sp_trace_setevent @TraceID, 12, 16, @on
exec sp_trace_setevent @TraceID, 12, 1, @on
exec sp_trace_setevent @TraceID, 12, 9, @on
exec sp_trace_setevent @TraceID, 12, 17, @on
exec sp_trace_setevent @TraceID, 12, 6, @on
exec sp_trace_setevent @TraceID, 12, 10, @on
exec sp_trace_setevent @TraceID, 12, 14, @on
exec sp_trace_setevent @TraceID, 12, 18, @on
exec sp_trace_setevent @TraceID, 12, 11, @on
exec sp_trace_setevent @TraceID, 12, 35, @on
exec sp_trace_setevent @TraceID, 12, 12, @on
exec sp_trace_setevent @TraceID, 12, 13, @on


-- ��������� �������
declare @intfilter int
declare @bigintfilter bigint

--��������� sp_reset_connection (TextData not like '%sp_reset_connection%'
exec sp_trace_setfilter @TraceID, 1, 0, 7, N'%sp_reset_connection%'
--��������� ������� � ������ TextData
exec sp_trace_setfilter @TraceID, 1, 0, 1, NULL

--�������� ������� � CPU >= 200
set @intfilter = 200
exec sp_trace_setfilter @TraceID, 18, 0, 4, @intfilter

--��������� ������� � ������ CPU
set @intfilter = NULL
exec sp_trace_setfilter @TraceID, 18, 0, 1, @intfilter

-- ������ �� ���� buh2_0
exec sp_trace_setfilter @TraceID, 35, 0, 6, N'buh2_0'

-- ��������� �����
exec sp_trace_setstatus @TraceID, 1
END


