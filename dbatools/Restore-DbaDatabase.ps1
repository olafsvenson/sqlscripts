$result = Restore-DbaDatabase -SqlInstance db-restore-p-01 -Path '\\db-backups-p-01\Backups\sql-01$PYTHIA\Pythoness_Transport' -MaintenanceSolutionBackup -OutputScriptOnly
$result | Out-File -Filepath c:\logs\restore.sql


$result = Restore-DbaDatabase -SqlInstance db-restore-p-01 -Path '\\db-backups-p-01\Backups\sql-01$PYTHIA' -DatabaseName Pythoness_Transport -MaintenanceSolutionBackup  -NoRecovery -OutputScriptOnly
$result | Out-File -Filepath c:\logs\restore.sql