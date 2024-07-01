USE [GreenButton]
GO
CREATE NONCLUSTERED INDEX [IX_custom_is_actual_����_inc_������������_������_������_�����������_���_����_�����_��������_������_�����������������]
ON [stage].[�����������������.������������������������] ([is_actual],[����])
INCLUDE ([������������],[������],[������],[�����������_���_����],[�����],[��������],[������],[�����������������])
WITH (Online = ON,RESUMABLE = ON, data_compression=page,maxdop=2);
GO

-- ��������
SELECT 
   name, 
   percent_complete,
   state_desc,
   last_pause_time,
   page_count
FROM sys.index_resumable_operations;

-- PAUSE
ALTER INDEX [IX_custom_�����_is_actual����_system_state_id_inc_] ON [GreenButton].[stage].[��������.���������������]
PAUSE;
GO

-- RESUME
ALTER INDEX [IX_custom_�����_is_actual����_system_state_id_inc_] ON [GreenButton].[stage].[��������.���������������]
RESUME;
GO

-- ABORT

ALTER INDEX [IX_custom_�����������������������_id]
ON [stage].[��������.�������.�������������������]
ABORT
