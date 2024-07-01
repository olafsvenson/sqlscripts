/* To Remove Log Shipping

   1) On the primary server, execute sp_delete_log_shipping_primary_secondary to delete the information about the secondary database from the primary server.

   2) On the secondary server, execute sp_delete_log_shipping_secondary_database to delete the secondary database.
		
		Note
		If there are no other secondary databases with the same secondary ID, sp_delete_log_shipping_secondary_primary is invoked from sp_delete_log_shipping_secondary_database and deletes the entry for the secondary ID and the copy and restore jobs.

   3) On the primary server, execute sp_delete_log_shipping_primary_database to delete information about the log shipping configuration from the primary server. This also deletes the backup job.

   4) Delete the secondary database from the secondary server if desired.

*/


-- (1) on primary
EXEC master.dbo.sp_delete_log_shipping_primary_secondary
 @primary_database = N'bn_met'
,@secondary_server = N'co-sql-02'
,@secondary_database = N'bn_met'
GO



-- (2) on secondary
EXEC master.dbo.sp_delete_log_shipping_secondary_database @secondary_database =  N'upp_snh'


-- (3) on primary

EXEC master.dbo.sp_delete_log_shipping_primary_database @database = N'bn_met';
GO


