$RestoreTime = Get-Date('06:05 25/06/2024')
$result = Restore-DbaDatabase -SqlInstance "sql-pp-01" -Path '\\db-backups-p-01\Backups\sql-p-02$PYTHIA\Pythoness_buf' -MaintenanceSolutionBackup -OutputScriptOnly -RestoreTime $RestoreTime -WithReplace
$result | Out-File -Filepath c:\temp\Pythoness_buf.sql # сохранаяется локально
# Remove-DbaDbBackupRestoreHistory -SqlInstance "sql-pp-01" -Database Pythoness_XML -Confirm:$false