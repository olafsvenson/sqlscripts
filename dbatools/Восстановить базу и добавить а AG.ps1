# Данный скрипт копирует базу на сервер и добавляет ее в AG, на secondary не должно быть баз Add-DbaAgDatabase не умеет восстанавливать с replace

$source = 'dwh-etl-u-01'
$primary = 'dwh-etl-u-02'
$secondary = 'dwh-etl-u-01'
$database = 'SSISDB'
$share = '\\sql-u-01\migration'
$agName = 'dwh-etl-u-ag'

$database | ForEach-Object {

    # копируем базу с тестового сервера используя последние бекапы, базы должны быть уже забекаплены
   # Copy-DbaDatabase -Source $source -Destination $primary -Database $_ -UseLastBackup -BackupRestore -KeepCDC -WithReplace;

    # устанавливаем на primary Full Recovery
    Set-DbaDbRecoveryModel  -SqlInstance $primary -Database $_ -RecoveryModel Full -Confirm:$false;
    # устанавливаем владельца SA
    Set-DbaDbOwner -SqlInstance $primary -Database $_ -TargetLogin sa;

    # бекапим базу на primary для переноса на secondary
    Backup-DbaDatabase -SqlInstance  $primary -Path $share -Database $_ -Type Full;
    # бекапим логи
    Backup-DbaDatabase -SqlInstance  $primary -Path $share -Database $_ -Type Log;

    # восстанавливаем базу на secondary, используя бекапы из прошлого шага
    Add-DbaAgDatabase -SqlInstance $primary  -AvailabilityGroup $agName -Database $database -Secondary $secondary -UseLastBackup;
}

Get-DbaAgDatabase -SqlInstance $primary -AvailabilityGroup $agName | Format-Table