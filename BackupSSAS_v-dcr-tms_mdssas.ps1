#Подключаем модуль для работы со службами SSAS
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices");
#Подключаемся к серверу SSAS
$serverAS = New-Object Microsoft.AnalysisServices.Server;
$serverAS.connect("v-dcr-bi-asis\mdssas");
##Фильтр по БД - исключаем из бэкапов ненужные базы
##$db_filter=$serverAS.databases | where-object {$_.name -ne "GB_Логистика" -and $_.name -ne "Alfresco" -and $_.name -ne "DWH_3" -and $_.name -ne "GB_Логистика_2"}
$db_filter=$serverAS.databases;
#Задаем настройки резервного копирование (сжатие, перезапись)
$BackupInfo = New-Object Microsoft.AnalysisServices.BackupInfo; 
$BackupInfo.AllowOverwrite=$true;
$BackupInfo.ApplyCompression=$true;

#Путь куда будут выгружаться бэкапы (ежедневные):
#$BackupDir_daily='\\pecom.local\Backups\SQLDCRSSAS\V-DCR-BI-ASIS(MDSSAS)\';
#Путь куда будут выгружаться бэкапы (1 раз в неделю):
$BackupDir_weekly='\\pecom.local\Backups\SQLDCRSSAS\V-DCR-BI-ASIS(MDSSAS)\weekly\';

    #Создаём каталог, если он ещё не существует:
    if (-Not (Test-Path -Path $BackupDir_weekly -pathType container))
    {
            New-Item -ItemType directory -Path $BackupDir_weekly
    }                                        
 
 
    #Выполняем бэкап для всех БД на сервере в цикле
    foreach ($db in $db_filter){
              
            $gd=Get-Date -Format 'yyyy-MM-dd-HH.mm.ss';
            $BackupInfo.File = $BackupDir_weekly+$db.name+'_'+$gd+'.abf';
            $db.Backup($BackupInfo);
    };
    #ротация бэкапов: удаляем все бэкапы старше 1 месяца!
    Get-ChildItem -path $BackupDir_weekly | where {$_.Extension -eq '.abf' -and $_.lastwritetime -lt ((get-date).AddDays(-31))} | remove-item -Force;