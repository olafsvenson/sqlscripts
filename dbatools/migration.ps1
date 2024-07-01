Start-Transcript C:\logs\db-migration-sql-t-01.txt
$sw = [Diagnostics.Stopwatch]::StartNew()

# Если нужна вторизация на серверах
#$sqlCred = Get-Credential vzheltonogov.adm
#-SourceSQLCredential $sqlCred
#-DestinationSqlCredential $sqlCred

Start-DbaMigration -Source sql-u-01 -Destination sql-t-01 -BackupRestore -SharedPath \\sql-u-01\migration -KeepCDC -DisableJobsOnDestination -Force -Exclude Endpoints, ExtendedEvents, PolicyManagement, ResourceGovernor, ServerAuditSpecifications, DataCollector, StartupProcedures, DatabaseMail, SpConfigure, CentralManagementServer, SysDbUserObjects

#print Time taken to execute
$sw.Stop()
"Sql install script completed in {0:c}" -f $sw.Elapsed;
Stop-Transcript
