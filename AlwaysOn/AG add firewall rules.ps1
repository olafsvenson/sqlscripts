New-NetFirewallRule -DisplayName "SQLServer default instance" -Direction Inbound -LocalPort 1433 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "SQLServer Browser service" -Direction Inbound -LocalPort 1434 -Protocol UDP -Action Allow
New-NetFirewallRule -DisplayName "SQLServer AG Endpoint" -Direction Inbound -LocalPort 5022 -Protocol TCP -Action Allow