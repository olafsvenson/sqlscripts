Import-Module dbatools;

$Servers = 'lk-dmart-p-01,54831'

foreach ($Server in $Servers) 
{
    Test-DbaLastBackup -Destination db-restore-p-01 -SqlInstance  $Server -MaxTransferSize 4194304 -BufferCount 24 | Select-Object -Property RestoreStart, SourceServer, Database, BackupFiles, RestoreResult,DBCCResult | Write-DbaDbTableData -SqlInstance db-restore-p-01 -Database master  -Table TestRestoreStatus -AutoCreateTable
}