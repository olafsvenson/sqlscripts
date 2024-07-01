/*
Missing Index Details from SQLQuery23.sql - co-sql-05.master (SNH\vzheltonogov (63))
The Query Processor estimates that implementing the following index could improve the query cost by 98.9485%.
*/

/*
USE [DM_STAGING]
GO
CREATE NONCLUSTERED INDEX [IX_history_type_id_owner_id_create_by_state_id_change_time_inc_id_ticket_id]
ON [otrs].[TR_TICKET_HISTORY] ([history_type_id],[owner_id],[create_by],[state_id],[change_time])
INCLUDE ([id],[ticket_id])
GO
*/
