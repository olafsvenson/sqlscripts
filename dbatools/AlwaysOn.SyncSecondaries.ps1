Import-Module dbatools;
$SqlInstance = 'lk-dmart-p-01,54831'
$AvailabilityGroupName = 'LK-DMart-AG-P'
 
# internal variables
    $ClientName = 'AG Sync helper'
    $primaryInstance = $null
    $secondaryInstances = @{}
 
 
try {
    # connect to the AG listener, get the name of the primary and all secondaries
        $replicas = Get-DbaAgReplica -SqlInstance $SqlInstance -AvailabilityGroup $AvailabilityGroupName
        $primaryInstance = $replicas | Where Role -eq Primary | select -ExpandProperty name
        $secondaryInstances = $replicas | Where Role -ne Primary | select -ExpandProperty name

    # create a connection object to the primary
        $primaryInstanceConnection = Connect-DbaInstance $primaryInstance -ClientName $ClientName

    # loop through each secondary replica and sync the logins
        $secondaryInstances | ForEach-Object {
        $secondaryInstanceConnection = Connect-DbaInstance $_ -ClientName $ClientName

    # синхронизируем логины    
        Copy-DbaLogin -Source $primaryInstanceConnection -Destination $secondaryInstanceConnection -ExcludeSystemLogins

    # синхронизируем джобы
        Copy-DbaAgentJob -Source $primaryInstanceConnection -Destination $secondaryInstanceConnection -ExcludeJob 'Maintenance.AlwaysOn.Sync','cdc.SberbankCSDDataMart_capture','cdc.SberbankCSDDataMart_cleanup','Backup.Diff','Backup.Full','Backup.Log','History.WhoIsActive','HistoryXE','HistoryXE.Report','Maintenance.CheckDb','Maintenance.FreeProcCache','Maintenance.Rebuild','Maintenance.Update Statistics','Monitoring','Monitoring.Jobs','Monitoring.LongTransactions' -Force
     }
}
catch {
    $msg = $_.Exception.Message
    Write-Error "Error while syncing secondaries for Availability Group '$($AvailabilityGroupName): $msg'"
}
