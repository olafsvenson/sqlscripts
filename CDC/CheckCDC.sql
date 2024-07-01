Select is_CDC_Enabled ,name from sys.databases where is_CDC_Enabled=1 
USE pegasus2008
Select name from sys.tables WHERE is_tracked_by_cdc = 1