-- Включение трейсов trace для любой версии SQL

declare
	@versionMajor	int,
	@sql			varchar(8000)
select @versionMajor = @@microsoftversion/256/256/256	-- Версия SQL

declare @rc int
declare @TraceID int
--максимальный размер отдельного файла 1 ГБ
declare @maxfilesize bigint
Set  @maxfilesize= 1024
declare @now datetime 
Set @now = getdate()
--время окончания установить на 00:01 следующего, чтобы не потерять данные между окончание этого трэйса и началом следующего
declare @stopTime datetime 
Set @stopTime = dateadd(mi, 1, dateadd(day, 1, convert(nvarchar(10), @now, 120)))
--путь к папке трэйса
declare @folder nvarchar(200) 
Set @folder = N'D:\SQL_Traces\' + @@servicename + N'\'
--путь к файлк трэйса
declare @fileName nvarchar(245) 
Set @fileName = @folder + N'daily_' + replace(convert(nvarchar(20), @now, 120), ':', '')
select @fileName

--включить трэйс с опцией rollover
exec @rc = sp_trace_create @TraceID output, 2, @fileName, @maxfilesize, @stopTime
if (@rc != 0)
	return

-- События
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


-- Настроить фильтры
declare @intfilter int
declare @bigintfilter bigint

--исключить sp_reset_connection (TextData not like '%sp_reset_connection%'
exec sp_trace_setfilter @TraceID, 1, 0, 7, N'%sp_reset_connection%'
--исключить события с пустым TextData
if @versionMajor>8 begin	-- Версия SQL выше 2000
	exec sp_trace_setfilter @TraceID, 1, 0, 1, NULL
end 

--включить события с CPU >= 200
set @intfilter = 200
exec sp_trace_setfilter @TraceID, 18, 0, 4, @intfilter

--исключить события с пустым CPU
if @versionMajor>8 begin	-- Версия SQL выше 2000
	set @intfilter = NULL
	exec sp_trace_setfilter @TraceID, 18, 0, 1, @intfilter
end	

-- Запустить трэйс
exec sp_trace_setstatus @TraceID, 1


/*	-- Отключение трейса
SELECT * FROM ::fn_trace_getinfo(default)
exec sp_trace_setstatus <@TraceID>,0	-- Stop
exec sp_trace_setstatus <@TraceID>,2	-- Close



SELECT * INTO #temp_trc FROM fn_trace_gettable('\\DB1\SQLTrace\AMO2\daily 2011-02-28 000000.trc', default);

drop table  #temp_trc

select duration,cpu,textdata,loginname,starttime,endtime,applicationname from #temp_trc order by starttime desc where starttime between '2011-02-25 08:00:00' and '2011-02-25 10:00:00' /*and loginname <> 'repladmin'*/ order by starttime desc--order by duration desc--order by starttime desc --duration DESC

select * from #temp_trc order by starttime desc --duration DESC

*/