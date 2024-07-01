$source = "1c-sql.sfn.local"
$destination = "1c-u-sql.sfn.local"
$dbname = "1C_DO_PROD"
$newdbname = "1C_DO_Test_Diadoc"

Import-Module dbatools;

Get-DbaDbBackupHistory -SqlInstance $source -Database $dbname -Last | Restore-DbaDatabase -SqlInstance $destination -Database $newdbname -ReplaceDbNameInFile -TrustDbBackupHistory -WithReplace;
#Copy-DbaDatabase -Source $source  -Destination $destination -BackupRestore -Database $dbname -UseLastBackup -NewName $newdbname -ReuseSourceFolderStructure -Force
Set-DbaDbRecoveryModel  -SqlInstance $destination -Database $newdbname -RecoveryModel Simple -Confirm:$false;
# указать нужный логин для сервера приложений
Set-DbaDbOwner -SqlInstance $destination -Database $newdbname  -TargetLogin SFN\1c-u-app_gmsa$; 
Remove-DbaDbBackupRestoreHistory -SqlInstance $destination -Database $newdbname -Confirm:$false;
Invoke-DbaDbShrink -SqlInstance $destination -Database $newdbname -FileType Log;