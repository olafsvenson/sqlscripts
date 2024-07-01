 
 $primary ="lk-dmart-p-02:54831"
 $secondary="lk-dmart-p-01:54831"


 Copy-DbaAgentJob -Source $primary -Destination $secondary -ExcludeJob 'Maintenance.AlwaysOn.Sync','cdc.SberbankCSDDataMart_capture','cdc.SberbankCSDDataMart_cleanup','cdc.CDIDataMart_capture','cdc.CDIDataMart_cleanup','cdc.SBOLDataMart_capture','cdc.SBOLDataMart_cleanup','cdc.SBOLDataMartPSI_capture','cdc.SBOLDataMartPSI_cleanup','Backup.Diff','Backup.Full','Backup.Log','Backup.Full.Pythoness_Transport_Archive','History.WhoIsActive','HistoryXE','HistoryXE.Report','History.Blocking','Maintenance.CheckDb','Maintenance.FreeProcCache','Maintenance.Rebuild','Maintenance.Update Statistics','Maintenance.Очистка msdb','Monitoring','Monitoring.Jobs','Monitoring.LongTransactions','Monitoring.CheckLog','syspolicy_purge_history','AlwaysOn.Sync','AlwaysOn.CheckPrimary' -Force
 Copy-DbaLogin -Source $primary -Destination $secondary -ExcludeSystemLogins