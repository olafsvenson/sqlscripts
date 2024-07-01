Import-Module dbatools;
Get-DbaDbBackupHistory -SqlInstance 1c-sql.sfn.local -Database 1C_IT_SFN -Last | Restore-DbaDatabase -SqlInstance 1c-u-sql.sfn.local -Database 1C_IT_SFN_TEST -ReplaceDbNameInFile -TrustDbBackupHistory -WithReplace;
Set-DbaDbRecoveryModel  -SqlInstance 1c-u-sql.sfn.local -Database 1C_IT_SFN_TEST -RecoveryModel Simple -Confirm:$false;
Invoke-DbaDbShrink -SqlInstance 1c-u-sql.sfn.local -Database 1C_IT_SFN_TEST -FileType Log;
Remove-DbaDbBackupRestoreHistory -SqlInstance 1c-u-sql.sfn.local -Database 1C_IT_SFN_TEST -Confirm:$false;
Set-DbaDbOwner -SqlInstance 1c-u-sql.sfn.local -Database 1C_IT_SFN_TEST  -TargetLogin SFN\1c-u-app_gmsa$;

#-DestinationFileSuffix "_Test_Dun"