-- �� ����� job-�� ��� ���������
Select name from msdb.dbo.sysjobs sj 
WHERE sj.notify_email_operator_id=0
ORDER BY Name


--�� ����� job-�� ��� ��������
SELECT * FROM msdb.dbo.sysjobs s 
WHERE (IsNULL(s.[description],'')=''
	OR S.[description]='No description available.'
) 
	AND s.category_id=0	-- ��������� �� ������ �� job-�
	AND NAME<>'syspolicy_purge_history'
	AND NAME<>'Database Mirroring Monitor Job'




/*
-- ���������� ErrorOperator
USE msdb
-- ���������� JobErrorOperator �� ���� job-�� �������  
Declare @id uniqueidentifier ,@StrSQL varchar(4000)
declare curXXX cursor FAST_FORWARD READ_ONLY for
	 Select job_id from sysjobs	 		-- ��� ����� ����� �������� ������ �� job-��
		WHERE notify_email_operator_id=0	-- ��� ��� ���������

open curXXX
fetch next from curXXX into @id
WHILE (@@FETCH_STATUS =0) begin
	Set @StrSQL='EXEC msdb.dbo.sp_update_job @job_id=N'''+Cast(@id as varchar(100))+''', '+
		'@notify_level_email=2, '+
		'@notify_email_operator_name=N''JobErrorOperator'''

	Select @StrSQL	-- Show
	exec (@StrSQL)	-- Action
  fetch next from curXXX into @id
end
close curXXX
deallocate curXXX

*/