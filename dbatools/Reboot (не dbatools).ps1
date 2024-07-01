$Servers = @()
$Servers = @(
"1C-D-SQL",
"1C-U-SQL"

)
$Servers.foreach({Restart-Computer -ComputerName $_ -force -verbose})