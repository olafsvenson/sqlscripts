USE [master]
GO

/****** Object:  StoredProcedure [dbo].[SP_TrackCDCStatus]    Script Date: 14/09/2016 14:20:33 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


Create PROCEDURE [dbo].[SP_TrackCDCStatus]
@AG_Name varchar(50),
@DatabaseName sysname
as

/******************************
** Name: SP_TrackCDCStatus.sql
** Auth: Yogeshwar Phull
** Date: 23/08/2016
**************************
*******************************/

Begin
Declare @InstanceName varchar(20)=@@SERVERNAME
Declare @Role varchar(20)
Declare @AG_GroupId varchar(40)
Declare @Health varchar(40)
Declare @AO_Mode tinyint
DECLARE @Status_P1 tinyint
DECLARE @Status_P2 tinyint
DECLARE @Status_S1 tinyint
DECLARE @Status_S2 tinyint
Declare @count_P1 tinyint
Declare @count_S1 tinyint
Declare @count_S2 tinyint
Declare @CMD nvarchar(200)
Declare @Job_1 nvarchar(50)='cdc.'+@DatabaseName+'_capture'
Declare @Job_2 nvarchar(50)='cdc.'+@DatabaseName+'_cleanup'
Declare @body1 varchar(200)
Declare @body2 varchar(200)
Declare @body3 varchar(200)
Declare @subject1 varchar(100)
Set @body1='Synchrnonization state of some databases is not healthy on availability group '+@AG_Name+'. Please take necessary action'
Set @body2='Synchrnonization state of CDC enabled database '+ @DatabaseName+' is not healthy. Trace flag 1448 has been enabled to ensure continuous working of Change Data Capture. Please investigate'
Set @body3='Synchrnonization state of CDC enabled database '+ @DatabaseName+' is not healthy. It has been removed from availability group '+@AG_Name+'. Please investigate'
Set @subject1='Always ON notification - '+@InstanceName


SELECT distinct @Role=C.role_desc, @AG_GroupId=C.group_id, @AO_Mode=D.availability_mode
FROM
sys.availability_groups_cluster AS A
INNER JOIN sys.dm_hadr_availability_replica_cluster_states AS B
ON
B.group_id = A.group_id
INNER JOIN sys.dm_hadr_availability_replica_states AS C
ON
C.replica_id = B.replica_id
INNER JOIN sys.availability_replicas AS D
ON
A.group_id = D.group_id
WHERE
B.replica_server_name=@InstanceName and A.name=@AG_Name

If @Role='PRIMARY'
	Begin
		Declare @Iter int=1 
			WHILE (@Iter <= 5)
				BEGIN
					Select @Health=synchronization_health from sys.dm_hadr_availability_replica_states where role=2 and group_id=@AG_GroupId
						If @Health=2
							break
						Else
							WAITFOR DELAY '00:03:00'
							set @Iter=@Iter+1
				END

			IF @Health<>2
				BEGIN
					Declare @Count int
					Create table #temp_sync
					(database_id int, synchronization_state int)
						
						SET NOCOUNT ON
						Insert #temp_sync 
						select distinct database_id, synchronization_state from sys.dm_hadr_database_replica_states
						where synchronization_state not in (1,2)


						Select @count=count (1) from #temp_sync 
							
							IF @count>0
							Begin
								EXEC msdb.dbo.sp_send_dbmail  
									 @profile_name = 'DBA',  
									 @recipients = 'DBA@email.com',  
									 @body = @body1,  
									 @subject = @subject1 
							End
							IF exists (select * from #temp_sync where database_id=db_id(@DatabaseName))
							
								BEGIN
									IF @AO_Mode=0
										Begin
										DBCC TRACEON (1448, -1)
												EXEC msdb.dbo.sp_send_dbmail  
												  @profile_name = 'DBA',  
												  @recipients = 'DBA@email.com',  
												  @body = @body2,  
												  @subject = @subject1
										End	

									IF @AO_Mode=1
										Begin
										set @CMD = 'Alter availability group [' +@AG_Name+'] remove database '+'['+@DatabaseName+']'
										exec sp_executesql @CMD
												EXEC msdb.dbo.sp_send_dbmail  
												  @profile_name = 'DBA',  
												  @recipients = 'DBA@email.com',  
												  @body = @body3,
												  @subject = @subject1
										End
								END
					Drop table #temp_sync
				END
	
  
			ELSE
				BEGIN
					select @Status_P1 =enabled from msdb..sysjobs where name like @Job_1
					select @Status_P2 =enabled from msdb..sysjobs where name like @Job_2
						If @Status_P1=1 
							Begin
								SELECT @count_P1=count(1)
								FROM 
								msdb.dbo.sysjobactivity AS a
								INNER JOIN 
								msdb.dbo.sysjobs AS b 
								ON 
								a.job_id = b.job_id
								WHERE a.start_execution_date IS NOT NULL
								AND a.stop_execution_date IS NULL
								AND b.name = @Job_1
		
										If @count_P1<>1
											EXEC msdb.dbo.sp_start_job @Job_1 
							END

						Else
							Begin
								EXEC msdb.dbo.sp_update_job @job_name=@Job_1,@enabled = 1
								EXEC msdb.dbo.sp_start_job @Job_1
							END

						If @Status_P2<>1
								 EXEC msdb.dbo.sp_update_job @job_name=@Job_2,@enabled = 1
				END
  END

  ELSE
  
		Begin
				select @Status_S1 =enabled from msdb..sysjobs where name like @Job_1
				select @Status_S2 =enabled from msdb..sysjobs where name like @Job_2

					If @Status_S1=1 
						Begin
							SELECT @count_S1=count(1)
							FROM msdb.dbo.sysjobactivity AS a
							INNER JOIN msdb.dbo.sysjobs AS b 
							ON 
							a.job_id = b.job_id
							WHERE a.start_execution_date IS NOT NULL
							AND a.stop_execution_date IS NULL
							AND b.name = @Job_1
						End
				
				    If @count_S1=1
							EXEC msdb.dbo.sp_stop_job @Job_1
							EXEC msdb.dbo.sp_update_job @job_name=@Job_1,@enabled = 0
		

   

				If @Status_S2=1 
						Begin
							SELECT @count_S2=count(1)
							FROM msdb.dbo.sysjobactivity AS a
							INNER JOIN msdb.dbo.sysjobs AS b 
							ON
							a.job_id = b.job_id
							WHERE a.start_execution_date IS NOT NULL
							AND a.stop_execution_date IS NULL
							AND b.name = @Job_2 
						END
				If @count_S2=1
						EXEC msdb.dbo.sp_stop_job @Job_2
						EXEC msdb.dbo.sp_update_job @job_name=@Job_2,@enabled = 0
  
		END
END


GO