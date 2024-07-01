--���������� ������ � ��������� ������� ���������
USE Pegasus2008MS
GO

set nocount on

DECLARE  @FinalHour int = 6 --����������� ��������� � 6 ����
		,@FinalMinute int = 30
        ,@FinalDate datetime2
   
             

SET @FinalDate = dateadd(day, datediff(day, 0, GETDATE()), 0)
--select @FinalDate 



IF datepart(hour, GETDATE()) > @FinalHour -- ��������� �� ��������� ����� (��������, ������� �� 5 �����, � ������ 23. 23 > 5, ��� ���� ��� ����, ����� ������������ ����������� �� ������, � �� ��������� ����������� ����)
       SET @FinalDate = DATEADD(day, 1, @FinalDate )       

--��������� ����, ����� ����� ���������� ���������� �������          
SET @FinalDate = DATEADD(hour, @FinalHour, @FinalDate )  
SET @FinalDate = DATEADD(minute, @FinalMinute, @FinalDate )  



--select @FinalDate 

DECLARE
       @index_name nvarchar(128),
	   @table_name nvarchar(128),
	   @sql nvarchar(500),
	   @StartDate datetime,
	   @FinishDate datetime,
	   @lock_result int;


	   
DECLARE todo CURSOR STATIC FOR
	select 
		'UPDATE STATISTICS [' + list.[TableName] + ']([' + list.[Name] + ']) WITH FULLSCAN', -- TODO: �������� �� quotename
		list.[Name],
		list.[TableName]
	from sfp_statistics_current list
	where list.[StartDT] is null -- ����� �� ������������ ������
		and list.[Name] not in ('sfp_statistics_current', 'sfp_statistics_history') --�� ������ ������
	order by
		list.[Id] asc -- �� �����������, ������ ��� ��� ����������� ���� ������� ������� ����������� � ������ �������� ������������


OPEN todo; 

WHILE 1 = 1 
BEGIN
    
	FETCH NEXT FROM todo
	INTO @sql, @index_name, @table_name

	

	IF @@FETCH_STATUS != 0
			BREAK;
	
	-- ���� ����� �� ��������� �����������
	IF GETDATE() > @FinalDate 
			BREAK;

	
	/*  ��� ������������ ���������� ����������� ���� ������. 
		������ � ������������ ������ ����������� ������ ���������� �� ��� �� �������
		������� ���������� �������� �� ����� �������
		��������� � 0 ��������� ����� �� �����, � ����� ������, ������ ��� ���
	*/
	exec @lock_result = sp_getapplock @table_name, 'Exclusive', 'Session', 0
	if @lock_result < 0
		continue 
	
	-- ��������� ����� ������
	update sfp_statistics_current
		set [StartDT] = GetDate()
	where 
		[TableName] = @table_name
		and [Name] = @index_name		
	   
	begin try
		--print (@sql)
		EXEC (@sql)

		SET @FinishDate = GetDate()

		-- ��������� ����� ���������
		update sfp_statistics_current
		set [EndDT] =	@FinishDate,
			[LastError] = N''
		where 
			[TableName] = @table_name
			and [Name] = @index_name

	end try
	begin catch
		
		-- ��� ������ ��������� ����
		update sfp_statistics_current
		set [LastError]  = Error_message()
		where 
			[TableName] = @table_name
			and [Name] = @index_name
		 

		--print Error_message()
	end catch
	
	exec sp_releaseapplock @Table_name, 'Session'
END

CLOSE todo;
DEALLOCATE todo;


