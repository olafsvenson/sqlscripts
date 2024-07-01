#���������� ������ ��� ������ �� �������� SSAS
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices");
#������������ � ������� SSAS
$serverAS = New-Object Microsoft.AnalysisServices.Server;
$serverAS.connect("v-dcr-bi-asis\mdssas");
##������ �� �� - ��������� �� ������� �������� ����
##$db_filter=$serverAS.databases | where-object {$_.name -ne "GB_���������" -and $_.name -ne "Alfresco" -and $_.name -ne "DWH_3" -and $_.name -ne "GB_���������_2"}
$db_filter=$serverAS.databases;
#������ ��������� ���������� ����������� (������, ����������)
$BackupInfo = New-Object Microsoft.AnalysisServices.BackupInfo; 
$BackupInfo.AllowOverwrite=$true;
$BackupInfo.ApplyCompression=$true;

#���� ���� ����� ����������� ������ (����������):
#$BackupDir_daily='\\pecom.local\Backups\SQLDCRSSAS\V-DCR-BI-ASIS(MDSSAS)\';
#���� ���� ����� ����������� ������ (1 ��� � ������):
$BackupDir_weekly='\\pecom.local\Backups\SQLDCRSSAS\V-DCR-BI-ASIS(MDSSAS)\weekly\';

    #������ �������, ���� �� ��� �� ����������:
    if (-Not (Test-Path -Path $BackupDir_weekly -pathType container))
    {
            New-Item -ItemType directory -Path $BackupDir_weekly
    }                                        
 
 
    #��������� ����� ��� ���� �� �� ������� � �����
    foreach ($db in $db_filter){
              
            $gd=Get-Date -Format 'yyyy-MM-dd-HH.mm.ss';
            $BackupInfo.File = $BackupDir_weekly+$db.name+'_'+$gd+'.abf';
            $db.Backup($BackupInfo);
    };
    #������� �������: ������� ��� ������ ������ 1 ������!
    Get-ChildItem -path $BackupDir_weekly | where {$_.Extension -eq '.abf' -and $_.lastwritetime -lt ((get-date).AddDays(-31))} | remove-item -Force;