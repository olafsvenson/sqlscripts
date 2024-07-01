
$source = "sql-p-02"
$destination = "sql-pp-01"
$Databases =  "PythiaAudit"
#,"Pythoness_buf","PifCompensation" 
#"Pythoness_Transport"
#"Pythoness_buf","Pythoness"


# Сделать DIFF бекап базы Pythoness_buf на sql-01

#exec [dbo].[DatabaseBackup] @Directory = '\\db-backups-p-01\Backups',@Databases = 'Pythoness, Pythoness_buf, PifCompensation',@Execute = 'Y',@BackupType = 'Diff',@CleanUpTime = 360
#,@AvailabilityGroupDirectoryStructure='{ServerName}${InstanceName}{DirectorySeparator}{DatabaseName}{DirectorySeparator}{BackupType}_{Partial}_{CopyOnly}',@Compress='Y',@LogToTable = 'Y'
#,@MAXTRANSFERSIZE = 2097152, @BUFFERCOUNT = 50, @BLOCKSIZE = 8192


Copy-DbaDatabase -Source $source -Destination $destination -Database $Databases -UseLastBackup -BackupRestore -KeepCDC -WithReplace
# Устанавливаем SIMPLE 
Set-DbaDbRecoveryModel  -SqlInstance $destination -Database $Databases -RecoveryModel Simple -Confirm:$false;
# мапим пользаком с одинаковыми именами, но разными SID
Repair-DbaDbOrphanUser -SqlInstance $destination -Database $Databases
# удаляем историю бекапов, чтобы не ругался zabbix
Remove-DbaDbBackupRestoreHistory -SqlInstance $destination -Database $Databases -Confirm:$false
# устанавливаем владельца баз SA
Set-DbaDbOwner -SqlInstance $destination -Database $Databases -TargetLogin sa;

#Repair-DbaDbOrphanUser -SqlInstance $destination