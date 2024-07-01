## Пути для iso
$SqlISOPath = "\\sfn\public\IT\distr\Microsoft\ISO\SW_DVD9_NTRL_SQL_Svr_Ent_Core_2019Dec2019_64Bit_English_OEM_VL_X22-22120.ISO" 
$SqlSPPath = "C:\Distr\SQLServer2016SP2-KB4052908-x64-ENU.exe"
$SqlCUPath = "C:\Distr\SQLServer2016-CU14-SP2-KB4564903-x64.exe"

# проверяем был ли монтирован образ ранее
$ISODrive = (Get-DiskImage -ImagePath $SqlISOPath | Get-Volume).DriveLetter
IF (!$ISODrive) {
    # если нет, то монтируем
    Mount-DiskImage -ImagePath $SqlISOPath -StorageType ISO
}
# получаем букву
$ISODrive = (Get-DiskImage -ImagePath $SqlISOPath | Get-Volume).DriveLetter

$ISODrive = $ISODrive+":"
Write-Host ("ISO Drive is " + $ISODrive)
Set-Location -Path $ISODrive

# Установка SQL сервера
#
# SQL Engine
# /SQLSVCACCOUNT - Указывает стартовую учетную запись для службы SQL Server.
# /SQLSVCPASSWORD - Указывает пароль для SQLSVCACCOUNT.
# 
# АгентSQL Server
# /AGTSVCACCOUNT - Задает учетную запись для службы агента SQL Server.
# /AGTSVCPASSWORD - Задает пароль для учетной записи службы агента SQL Server.

# /SQLSVCACCOUNT=""Администратор"" /SQLSVCPASSWORD=""*****"" /AGTSVCACCOUNT=""Администратор"" /AGTSVCPASSWORD=""*******""

# /SQLTEMPDBDIR="C:\MSSQL\TempDB\\" /SQLUSERDBDIR="C:\MSSQL\Data\\" /SQLUSERDBLOGDIR="C:\MSSQL\Log\\"

Start-Process -wait -FilePath "setup.exe" -ArgumentList "/Q /SkipRules=RebootRequiredCheck /instanceName=mssqlserver /SQLSVCACCOUNT=""NT Authority\System"" /AGTSVCACCOUNT=""NT Authority\System"" /IACCEPTSQLSERVERLICENSETERMS /ENU /UpdateEnabled=0 /ACTION=""install"" /PID=""2C9JR-K3RNG-QD4M4-JQ2HR-8468J"" /FEATURES=SQLEngine,FullText,BC,Conn /INDICATEPROGRESS /SQLSVCSTARTUPTYPE=""Automatic"" /SQLSYSADMINACCOUNTS=""SFN\vzheltonogov"" ""SFN\vzheltonogov.adm"" ""SFN\akomlev"" ""SFN\alebedev"" ""SFN\kpuzakov"" /AGTSVCSTARTUPTYPE=""Automatic"" /SQLCOLLATION=""Cyrillic_General_CI_AS"" /SECURITYMODE=SQL /SAPWD=""Pa$$w0rdPa$$w0rd"" /BROWSERSVCSTARTUPTYPE=""Automatic"" /SQLTEMPDBFILECOUNT=4 /SQLSVCINSTANTFILEINIT=""True"""

Dismount-DiskImage $SqlISOPath

#Start-Process -wait -FilePath  $SqlSPPath -ArgumentList "/q /SkipRules=RebootRequiredCheck /IAcceptSQLServerLicenseTerms /Action=Patch /InstanceName=SQL2016"
#Start-Process -wait -FilePath  $SqlCUPath -ArgumentList "/q /SkipRules=RebootRequiredCheck /IAcceptSQLServerLicenseTerms /Action=Patch /InstanceName=SQL2016"


