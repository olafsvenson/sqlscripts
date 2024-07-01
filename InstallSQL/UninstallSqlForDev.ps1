#Uninstalls a standard CashConverter SQL Server local installation.
# Also removes all database files. i.e. should be a clean uninstall
# Install SQL from command line help - https://msdn.microsoft.com/en-us/library/ms144259.aspx
$sw = [Diagnostics.Stopwatch]::StartNew()
$currentUserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name;
$SqlServerIsoImagePath = "???\Downloads\Microsoft\SQL Server 2016 Developer Edition\en_sql_server_2016_developer_x64_dvd_8777069.iso"

#Mount the installation media, and change to the mounted Drive.
$mountVolume = Mount-DiskImage -ImagePath $SqlServerIsoImagePath -PassThru
$driveLetter = ($mountVolume | Get-Volume).DriveLetter
$drivePath = $driveLetter + ":"
push-location -path "$drivePath"

#Install SQL Server locally with our default settings. 
# Assumes only the Sql Engine and LocalDB were installed
.\Setup.exe /q /ACTION=UNINSTALL /FEATURES=SQLEngine, LocalDB /INSTANCENAME=MSSQLSERVER

#Dismount the installation media.
pop-location
Dismount-DiskImage -ImagePath $SqlServerIsoImagePath

#Clear out the orphaned database files
# As per the install script INSTANCENAME=MSSQLSERVER & INSTANCEDIR="C:\Program Files\Microsoft SQL Server"
Remove-Item -Recurse -Force "C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\"


#print Time taken to execute
$sw.Stop()
"Sql install script completed in {0:c}" -f $sw.Elapsed;