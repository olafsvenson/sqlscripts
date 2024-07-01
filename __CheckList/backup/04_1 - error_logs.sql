-- Просмотр всех записей из лога за последние 3 дня с текстом Error или Fail
--Наиболее частые коды ошибок, остальные смотрим в BOL в топике  "System Error Messages"  
-- 14151 Replication-%s: agent %s failed. %s
-- 14420 The log shipping primary database %s.%s has backup threshold of %d minutes and has not performed a backup log operation for %d minutes. Check agent log and logshipping monitor information.
-- 15457 Configuration option '%ls' changed from %ld to %ld. Run the RECONFIGURE statement to install.
-- 18056 The client was unable to reuse a session with SPID %d, which had been reset for connection pooling. The failure ID is %d. This error may have been caused by an earlier operation failing. Check the error logs for failed operations immediately before this error message.
-- 18456 Login failed for user '%.*ls'.%.*ls%.*ls
--  3041 BACKUP failed to complete the command %.*ls. Check the backup application log for detailed messages.
--  1479 The mirroring connection to "%.*ls" has timed out for database "%.*ls" after %d seconds without a response. Check the service and network connections.
--  8510 Enlist operation failed: %ls. SQL Server could not register with Microsoft Distributed Transaction Coordinator (MS DTC) as a resource manager for this transaction. The transaction may have been stopped by the client or the resource manager.

set nocount on
if object_id('tempdb..#errorLogs') is not null
	drop table #errorLogs
create table #errorLogs
(
	ArchiveNumber	int not null,
	Date			datetime,
	LogSize			bigint
)

insert into #errorLogs
exec master.dbo.xp_enumerrorlogs

declare
	@firstLog	int,
	@startDate	datetime

set @startDate = dateadd(day, -3, getdate())
select @firstLog = max(ArchiveNumber) from #errorLogs where Date >= @startDate

declare @logNum int
set @logNum = @firstLog

declare
	@versionMajor	int

set @versionMajor = @@microsoftversion/256/256/256

if object_id('tempdb..#errors') is not null
	drop table #errors

create table #errors
(
	RowNum				int identity not null primary key,
	LogDate				datetime null,
	ProcessInfo			sysname null,
	[Text]				nvarchar(3500) /*not*/ null,	
	ContinuationRow		int null
)

if @versionMajor >= 9
begin
	while @logNum >= 0
	begin
		insert into #errors(LogDate, ProcessInfo, Text)
		exec master..xp_readerrorlog @logNum
		
		set @logNum = @logNum - 1
	end

	select RowNum,ProcessInfo, LogDate, [Text]
		from #errors
		where
			LogDate >= @startDate
			and
			(
				[Text] LIKE '%error:%' OR [Text] LIKE  '%fail%'	OR [Text] LIKE '%occurrence%'
			)
		order by RowNum desc
end
else
begin
	while @logNum >= 0
	begin
		if @logNum > 0
		begin
			insert into #errors(Text, ContinuationRow)
			exec master..xp_readerrorlog @logNum
		end
		else
		begin
			insert into #errors(Text, ContinuationRow)
			exec master..xp_readerrorlog
		end
		
		set @logNum = @logNum - 1
	end

	select RowNum,ProcessInfo, LogDate, [Text]
		from
		(
			select
					RowNum,ProcessInfo,
					LogDate = case
						when [Text] like '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9]%' then
							convert(datetime, left([Text], 22))
						else @startDate
					end,
					[Text]	
				from #errors
				where
				[Text] LIKE '%error:%' OR [Text] LIKE  '%fail%'	OR [Text] LIKE '%occurrence%' 
		) q
		where q.LogDate >= @startDate
		order by RowNum desc
end
