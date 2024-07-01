Copy-DbaDatabase -Source 1c-sql -Destination 1c-sql-03 -Database 1C_TOIR3 -BackupRestore -SharedPath \\db-backups-p-01\tmp -Force
#-NewName "1C_ZupTaxTestBuynovskiy"
Set-DbaDbOwner -SqlInstance 1c-sql-03 -Database 1C_TOIR3 -TargetLogin SFN\1c-app-03_gmsa$;