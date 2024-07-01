/* https://www.mssqltips.com/sqlservertip/1411/verbose-sql-server-agent-logging/
The following statement sets the output file for every job / step on your SQL server. The files will be stored in the usual log dircetory,
the filename will be _Step__.log (e.g. Log_DatabaseBackup_Step_1_20190129_103700.txt or Index_Optimize_Step_4_20190112_100000.txt).
The statement can be executed multiple times (e.g. after creating a new job or renaming an existing one)
*/
-- Caution: output_file_name is a nvarchar(200), if the JobName (and / or the LogPath) is to long, the statement will fail
--select c2.output_file_name
-- d:\MSSQL\Logs\Monitoring.CheckLog_Step_$(ESCAPE_SQUOTE(STEPID))_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt
/*
UPDATE sj
   SET output_file_name = c2.output_file_name
*/
select c2.output_file_name
  FROM msdb.dbo.sysjobsteps sj
 INNER JOIN msdb.dbo.sysjobs AS s
    ON s.job_id = sj.job_id
 CROSS JOIN (SELECT CAST(SERVERPROPERTY('ErrorLogFileName') AS NVARCHAR(1024)) ErrorLogFileName,
                    ISNULL(CAST(SERVERPROPERTY('ProductMajorVersion') AS VARCHAR(10)), 0) ProductMajorVersion
            ) calc
 CROSS APPLY (SELECT CASE WHEN calc.ProductMajorVersion >= 11
                          THEN CAST('e:\MSSQL\Logs\' AS NVARCHAR(1024))
                          ELSE SUBSTRING(calc.ErrorLogFileName, 1, LEN(calc.ErrorLogFileName) - CHARINDEX('\', REVERSE(calc.ErrorLogFileName))) + '\'
                     END
                   + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                             CASE WHEN s.name LIKE 'DatabaseBackup - USER_DATABASES - LOG%'
                                  THEN 'Log_DatabaseBackup'
                                  ELSE s.name
                             END, ' ', '_'), '/', '-'), '\', '-'), ':', '_'), '?', '_'), '*', '_')
                   + '_Step_$(ESCAPE_SQUOTE(STEPID))_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt' AS output_file_name
               ) c2
 WHERE (sj.output_file_name <> c2.output_file_name
    OR sj.output_file_name IS NULL)
	and s.name not in ('Maintenance.AlwaysOn.Sync','AlwaysOn.CheckPrimary','cdc.SberbankCSDDataMart_capture','cdc.SberbankCSDDataMart_cleanup','cdc.CDIDataMart_capture','cdc.CDIDataMart_cleanup','cdc.SBOLDataMart_capture','cdc.SBOLDataMart_cleanup','cdc.SBOLDataMartPSI_capture','cdc.SBOLDataMartPSI_cleanup','Backup.Diff','Backup.Full','Backup.Log','Backup.Full.Pythoness_Transport_Archive','History.WhoIsActive','HistoryXE','HistoryXE.Report','History.Blocking','Maintenance.CheckDb','Maintenance.FreeProcCache','Maintenance.Rebuild','Maintenance.Update Statistics','Maintenance.Очистка msdb','Maintenance.ShrinkAll','Monitoring','Monitoring.Jobs','Monitoring.LongTransactions','Monitoring.CheckLog','syspolicy_purge_history')
