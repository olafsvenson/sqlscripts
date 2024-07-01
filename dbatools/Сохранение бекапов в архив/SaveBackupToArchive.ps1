#Import-Module dbatools;

$User = "BackupsArchiveUser"


# это захешированный пароль
# чтобы его получить нужно выполнить следующий код
# ВАЖНО: ВЫПОЛНЯТЬ ЭТОТ КОД ИЗ ПОД СЕАНСА ПОЛЬЗОВАТЕЛЯ КТО В ДАЛЬНЕЙШЕМ БУДЕМ ЗАПУСКАТЬ ЭТОТ СКРИПТ
#$SecureString =  ConvertTo-SecureString "пароль" -AsPlainText -Force
#$EncryptedPW = ConvertFrom-SecureString -SecureString $SecureString
#сохраняем хэш пароля в файл, что бы затем его вставить сюда
#Set-Content -Path "C:\Scripts\mypw.txt" -Value $EncryptedPW
$Encrypted ="01000000d08c9ddf0115d1118c7a00c04fc297eb0100000073f05822f5417a41b1013cae8055adb600000000020000000000106600000001000020000000ab549b2ab13444a716b8482eee46cc596c48c429c25beccabc13775eb34dc1d7000000000e8000000002000020000000f1a62136d08230f5a4ecf7a70702aa4261dcb2e7996273b35aafb65477cadbee30000000f0b0055fb95343cf6b23340b64d83c01c188f37157b73595ac0e8027f95141339e441a4d01026195f40e4d35d9b8f18c4000000007c5b5fd47da9b652c696031616413611f29e305644af566ec08a5064ec8007f122ef6240f931efdf93d05ba315e83fb783bb500f507d88d29eaf1dc38048c21"

$PWord = ConvertTo-SecureString -String $Encrypted

# Если не нужно получать хэш пароля, то пароль можно указать в явном виде в скрипте
#$PWord = ConvertTo-SecureString "ПАРОЛЬ" -AsPlainText -Force


# На основании Username и Password созздаем обьект PSCredential
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord


$Servers = ('1c-sql','sfn-etl-p-01','sfn-dmart-p-01','sfn-dmart-p-02','lk-dmart-p-01,54831','lk-dmart-p-02,54831','sql-01');
#$Servers = ('sfn-etl-p-01');

$ExcludeDatabasesGlobal = ('master', 'model', 'msdb', 'distribution', '1C_OSBU_DEV_Timofeev', '1C_OSBU_TEST_Buynovskiy','sqlwatch');


foreach ($Server in $Servers) 
{
   $Destination = '\\db-backups-p-01\Backups\_Archive\'

   $Destination = Join-Path -Path $destination  -ChildPath ($server -replace (',54831' ,''))
  
   If(!(test-path $Destination))
    {
      New-Item -ItemType Directory -Force -Path $Destination
    } 

   Get-DbaDbBackupHistory -SqlInstance $server -SqlCredential $Credential -ExcludeDatabase $ExcludeDatabasesGlobal -LastFull | Select-Object path | Copy-Item -Destination $Destination
}


